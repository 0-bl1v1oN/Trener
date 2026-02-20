import 'package:flutter/material.dart';

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
  final String clientName;

  const _WorkoutScreenData({
    required this.info,
    required this.exercises,
    required this.clientName,
  });
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

  Future<void> _addExercise(int templateId) async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Новое упражнение'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Название упражнения',
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
            child: const Text('Добавить'),
          ),
        ],
      ),
    );

    if (name == null || name.trim().isEmpty) return;

    await db.addWorkoutTemplateExercise(templateId: templateId, name: name);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _deleteExercise(WorkoutExerciseVm e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить упражнение?'),
        content: Text(
          'Упражнение "${e.name}" будет удалено из этого дня программы.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await db.deleteWorkoutTemplateExercise(e.templateExerciseId);
    if (!mounted) return;
    setState(() {});
  }

  Future<_WorkoutScreenData> _loadScreenData() async {
    final client = await db.getClientById(widget.clientId);

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

    return _WorkoutScreenData(
      info: data.$1,
      exercises: exercises,
      clientName: client?.name ?? 'Тренировка',
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenFuture = _loadScreenData();

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<_WorkoutScreenData>(
          future: screenFuture,
          builder: (context, snap) => Text(
            snap.data?.clientName ?? 'Тренировка',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      body: FutureBuilder<_WorkoutScreenData>(
        future: screenFuture,

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
                  children: [
                    _EditorToolbar(
                      onAdd: exercises.isEmpty
                          ? null
                          : () => _addExercise(exercises.first.templateId),
                    ),
                    ..._buildExerciseWidgets(exercises),
                  ],
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

    final colors = Theme.of(context).colorScheme;
    final kgC = _kgController(e.templateExerciseId, e.lastWeightKg);
    final repsC = _repsController(e.templateExerciseId, e.lastReps);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Упр. ${index + 1}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (linkedWithNext) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.tertiary.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Суперсет',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.tertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          e.name,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            height: 1.25,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: () => _renameExercise(e),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Название'),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: hasNext
                  ? FilledButton.tonalIcon(
                      onPressed: () => _toggleSupersetForExercise(e),
                      icon: Icon(
                        linkedWithNext ? Icons.link_off : Icons.link,
                        size: 16,
                      ),
                      label: Text(linkedWithNext ? 'Убрать сет' : 'Суперсет'),
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 40,
              child: IconButton.filledTonal(
                tooltip: 'Удалить упражнение',
                onPressed: ex.length <= 1 ? null : () => _deleteExercise(e),
                icon: const Icon(Icons.delete_outline),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: kgC,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.fitness_center, size: 18),
                  labelText: 'Вес, кг',
                  filled: true,
                  fillColor: colors.surfaceContainerHighest.withOpacity(0.35),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colors.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: colors.outlineVariant.withOpacity(0.65),
                    ),
                  ),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: repsC,
                keyboardType: TextInputType.number,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.repeat, size: 18),
                  labelText: 'Повторы',
                  filled: true,
                  fillColor: colors.surfaceContainerHighest.withOpacity(0.35),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colors.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: colors.outlineVariant.withOpacity(0.65),
                    ),
                  ),
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

class _EditorToolbar extends StatelessWidget {
  final VoidCallback? onAdd;

  const _EditorToolbar({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.tune, size: 18, color: colors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Редактор дня',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.primary,
              ),
            ),
          ),
          FilledButton.tonalIcon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Добавить упражнение'),
          ),
        ],
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

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.outlineVariant.withOpacity(0.45)),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colors.surface, colors.primary.withOpacity(0.02)],
          ),
        ),
        child: Padding(padding: const EdgeInsets.all(14), child: child),
      ),
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
      color: colors.primary.withOpacity(0.05),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.primary.withOpacity(0.28)),
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
