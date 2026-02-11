import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/app_db_scope.dart';
import '../../db/app_db.dart';

class WorkoutScreen extends StatefulWidget {
  final String clientId;
  final DateTime day;
  final int?
  templateIdx; // ✅ выбранная тренировка 0..8 (если null — обычная логика)

  const WorkoutScreen({
    super.key,
    required this.clientId,
    required this.day,
    this.templateIdx,
  });

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  late AppDb db;

  // локальные значения ввода по templateExerciseId
  final Map<int, TextEditingController> _kgCtrls = {};
  final Map<int, TextEditingController> _repsCtrls = {};

  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    db = AppDbScope.of(context);
  }

  @override
  void dispose() {
    for (final c in _kgCtrls.values) {
      c.dispose();
    }
    for (final c in _repsCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _kgController(int exId, double? initial) {
    return _kgCtrls.putIfAbsent(exId, () {
      final t = TextEditingController(
        text: initial == null ? '' : _fmtKg(initial),
      );
      return t;
    });
  }

  TextEditingController _repsController(int exId, int? initial) {
    return _repsCtrls.putIfAbsent(exId, () {
      final t = TextEditingController(
        text: initial == null ? '' : initial.toString(),
      );
      return t;
    });
  }

  String _fmtKg(double v) {
    // чтобы 50.0 показывалось как 50
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toString();
  }

  double? _parseKg(String s) {
    final t = s.trim().replaceAll(',', '.');
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  int? _parseInt(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t);
  }

  Future<void> _save({
    required Map<int, (double? kg, int? reps)> results,
  }) async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      await db.saveWorkoutResultsAndMarkDone(
        clientId: widget.clientId,
        day: widget.day,
        resultsByTemplateExerciseId: results,
        templateIdx: widget.templateIdx, // ✅ ключевой параметр
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
      return;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _cancelWorkout() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      if (widget.templateIdx != null) {
        await db.toggleWorkoutForClientOnDayWithTemplateIdx(
          clientId: widget.clientId,
          day: widget.day,
          templateIdx: widget.templateIdx!,
        );
      } else {
        await db.toggleWorkoutForClientOnDay(
          clientId: widget.clientId,
          day: widget.day,
        );
      }

      if (!mounted) return;
      setState(() {});
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dayLabel = DateFormat('d MMMM y', 'ru_RU').format(widget.day);

    return Scaffold(
      appBar: AppBar(title: Text('Тренировка • $dayLabel')),
      body: FutureBuilder(
        future: (widget.templateIdx == null)
            ? db.getWorkoutDetailsForClientOnDay(
                clientId: widget.clientId,
                day: widget.day,
              )
            : db.getWorkoutDetailsForClientOnDayForcedTemplateIdx(
                clientId: widget.clientId,
                day: widget.day,
                templateIdx: widget.templateIdx!,
              ),

        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            // покажем ошибку прямо на экране, иначе будет вечная загрузка
            return Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Text(
                  'Ошибка загрузки тренировки:\n\n${snap.error}\n\n${snap.stackTrace ?? ''}',
                ),
              ),
            );
          }

          if (!snap.hasData) {
            return const Center(child: Text('Нет данных'));
          }

          final (info, _, exercises) = snap.data!;

          if (!info.hasPlan) {
            return const Center(
              child: Text('У клиента нет программы/абонемента'),
            );
          }

          final header = _Header(info: info);

          if (exercises.isEmpty) {
            return Column(
              children: [
                header,
                const Divider(height: 1),
                const Expanded(
                  child: Center(child: Text('Нет упражнений в шаблоне')),
                ),
              ],
            );
          }

          // Собираем results для сохранения из контроллеров
          Map<int, (double? kg, int? reps)> buildResults() {
            final map = <int, (double? kg, int? reps)>{};
            for (final e in exercises) {
              final kg = _parseKg(_kgCtrls[e.templateExerciseId]?.text ?? '');
              final reps = _parseInt(
                _repsCtrls[e.templateExerciseId]?.text ?? '',
              );
              map[e.templateExerciseId] = (kg, reps);
            }
            return map;
          }

          return Column(
            children: [
              header,
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                  children: _buildExerciseWidgets(exercises),
                ),
              ),
              _BottomBar(
                saving: _saving,
                done: info.doneToday,
                onSave: () => _save(results: buildResults()),
                onCancel: _cancelWorkout,
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildExerciseWidgets(List<WorkoutExerciseVm> ex) {
    final out = <Widget>[];

    int i = 0;
    while (i < ex.length) {
      final cur = ex[i];

      // Суперсет = groupId не null и следующий тоже такой же groupId
      if (cur.supersetGroup != null &&
          i + 1 < ex.length &&
          ex[i + 1].supersetGroup == cur.supersetGroup) {
        final a = ex[i];
        final b = ex[i + 1];

        out.add(
          _SuperSetCard(
            title: 'Суперсет',
            a: _exerciseRow(a),
            b: _exerciseRow(b),
          ),
        );

        i += 2;
        continue;
      }

      out.add(_ExerciseCard(child: _exerciseRow(cur)));
      i += 1;
    }

    return out;
  }

  Widget _exerciseRow(WorkoutExerciseVm e) {
    final kgC = _kgController(e.templateExerciseId, e.lastWeightKg);
    final repsC = _repsController(e.templateExerciseId, e.lastReps);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                e.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              tooltip: e.supersetGroup == null
                  ? 'Сделать суперсет'
                  : 'Убрать суперсет',
              icon: Icon(e.supersetGroup == null ? Icons.link_off : Icons.link),
              onPressed: () async {
                await db.toggleClientSupersetWithNext(
                  clientId: widget.clientId,
                  templateId: e.templateId,
                  orderIndex: e.orderIndex,
                );
                if (!mounted) return;
                setState(() {});
              },
            ),
          ],
        ),

        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: kgC,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'кг (последний подход)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: repsC,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'повторы',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final WorkoutDayInfo info;
  const _Header({required this.info});

  @override
  Widget build(BuildContext context) {
    final title = '${info.label} — ${info.title}';
    final done = info.doneToday;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  done ? '✅ Выполнено' : 'Сегодня',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 6),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final bool saving;
  final bool done;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _BottomBar({
    required this.saving,
    required this.done,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            if (done) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: saving ? null : onCancel,
                  child: const Text('Отменить тренировку'),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: saving ? null : onSave,
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Сохранить и отметить выполнено'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final Widget child;

  const _ExerciseCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: const EdgeInsets.all(12), child: child),
    );
  }
}

class _SuperSetCard extends StatelessWidget {
  final String title;
  final Widget a;
  final Widget b;

  const _SuperSetCard({required this.title, required this.a, required this.b});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.link),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 10),
            a,
            const Divider(height: 24),
            b,
            const SizedBox(height: 6),
            Text(
              'Отдых после суперсета',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}
