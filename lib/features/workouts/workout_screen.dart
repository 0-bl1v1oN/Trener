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

class _WorkoutScreenData {
  final WorkoutDayInfo info;
  final List<WorkoutExerciseVm> exercises;

  const _WorkoutScreenData({required this.info, required this.exercises});
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

  Future<void> _renameExercise(WorkoutExerciseVm e) async {
    final ctrl = TextEditingController(text: e.name);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Название упражнения'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Введите новое название',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (result == null || result.trim().isEmpty) return;

    await db.renameWorkoutTemplateExercise(
      templateExerciseId: e.templateExerciseId,
      newName: result,
    );
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _toggleSupersetForExercise(WorkoutExerciseVm e) async {
    await db.toggleClientSupersetWithNext(
      clientId: widget.clientId,
      templateId: e.templateId,
      orderIndex: e.orderIndex,
    );
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _saveDraft({
    required Map<int, (double? kg, int? reps)> results,
  }) async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      await db.saveWorkoutDraftResults(
        clientId: widget.clientId,
        day: widget.day,
        resultsByTemplateExerciseId: results,
        templateIdx: widget.templateIdx,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Черновик сохранён')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _markDone({
    required Map<int, (double? kg, int? reps)> results,
  }) async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      await db.saveWorkoutResultsAndMarkDone(
        clientId: widget.clientId,
        day: widget.day,
        resultsByTemplateExerciseId: results,
        templateIdx: widget.templateIdx,
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
      Navigator.of(context).pop(true);
      return;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<_WorkoutScreenData> _loadScreenData() async {
    final data = widget.templateIdx == null
        ? await db.getWorkoutDetailsForClientOnDay(
            clientId: widget.clientId,
            day: widget.day,
          )
        : await db.getWorkoutDetailsForClientOnDayForcedTemplateIdx(
            clientId: widget.clientId,
            day: widget.day,
            templateIdx: widget.templateIdx!,
          );

    final drafts = await db.getWorkoutDraftResults(
      clientId: widget.clientId,
      day: widget.day,
      templateIdx: widget.templateIdx,
    );

    final exercises = data.$3.map((e) {
      final d = drafts[e.templateExerciseId];
      if (d == null) return e;
      return WorkoutExerciseVm(
        templateExerciseId: e.templateExerciseId,
        templateId: e.templateId,
        orderIndex: e.orderIndex,
        name: e.name,
        lastWeightKg: d.$1,
        lastReps: d.$2,
        supersetGroup: e.supersetGroup,
      );
    }).toList();

    return _WorkoutScreenData(info: data.$1, exercises: exercises);
  }

  @override
  Widget build(BuildContext context) {
    final dayLabel = DateFormat('d MMMM y', 'ru_RU').format(widget.day);

    return Scaffold(
      appBar: AppBar(title: Text('Тренировка • $dayLabel')),
      body: FutureBuilder<_WorkoutScreenData>(
        future: _loadScreenData(),

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

          final data = snap.data!;
          final info = data.info;
          final exercises = data.exercises;

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
                onSaveDraft: () => _saveDraft(results: buildResults()),
                onMarkDone: () => _markDone(results: buildResults()),
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
        out.add(
          _SuperSetCard(
            title: 'Суперсет',
            a: _exerciseRow(ex, i),
            b: _exerciseRow(ex, i + 1),
          ),
        );

        i += 2;
        continue;
      }

      out.add(_ExerciseCard(child: _exerciseRow(ex, i)));
      i += 1;
    }

    return out;
  }

  Widget _exerciseRow(List<WorkoutExerciseVm> ex, int index) {
    final e = ex[index];
    final hasNext = index + 1 < ex.length;
    final linkedWithNext =
        hasNext &&
        e.supersetGroup != null &&
        ex[index + 1].supersetGroup == e.supersetGroup;

    final kgC = _kgController(e.templateExerciseId, e.lastWeightKg);
    final repsC = _repsController(e.templateExerciseId, e.lastReps);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.name, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.edit, size: 16),
                        label: const Text('Переименовать'),
                        onPressed: () => _renameExercise(e),
                      ),
                      if (hasNext)
                        ActionChip(
                          avatar: Icon(
                            linkedWithNext ? Icons.link_off : Icons.link,
                            size: 16,
                          ),
                          label: Text(
                            linkedWithNext
                                ? 'Убрать суперсет'
                                : 'Сделать суперсет',
                          ),
                          onPressed: () => _toggleSupersetForExercise(e),
                        ),
                    ],
                  ),
                ],
              ),
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

    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colors.primary.withOpacity(0.16),
              colors.secondary.withOpacity(0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.primary.withOpacity(0.22)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                done ? Icons.check_circle : Icons.fitness_center,
                color: colors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    done ? '✅ Выполнено' : 'В процессе',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final bool saving;
  final bool done;
  final VoidCallback onSaveDraft;
  final VoidCallback onMarkDone;
  final VoidCallback onCancel;

  const _BottomBar({
    required this.saving,
    required this.done,
    required this.onSaveDraft,
    required this.onMarkDone,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (done) ...[
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: saving ? null : onCancel,
                  icon: const Icon(Icons.undo),
                  label: const Text('Отменить тренировку'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.error,
                    side: BorderSide(color: colors.error.withOpacity(0.6)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: saving ? null : onSaveDraft,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Сохранить'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: saving ? null : onMarkDone,
                      icon: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(done ? Icons.check : Icons.task_alt),
                      label: Text(done ? 'Готово' : 'Отметить выполнено'),
                    ),
                  ),
                ),
              ],
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
    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colors.surface,
      margin: const EdgeInsets.only(bottom: 10),
      shadowColor: colors.primary.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.outlineVariant.withOpacity(0.6)),
      ),
      child: Padding(padding: const EdgeInsets.all(14), child: child),
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
    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colors.primary.withOpacity(0.04),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.primary.withOpacity(0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt, size: 16, color: colors.primary),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Упражнение A',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 6),
            a,
            const Divider(height: 24),
            Text(
              'Упражнение B',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 6),
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
