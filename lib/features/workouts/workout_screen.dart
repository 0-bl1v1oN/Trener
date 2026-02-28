import 'dart:async';
import 'package:flutter/material.dart';

import '../../app/app_db_scope.dart';
import '../../db/app_db.dart';

class WorkoutScreen extends StatefulWidget {
  final String clientId;
  final DateTime day;
  final int?
  templateIdx; // ✅ выбранная тренировка 0..8 (если null — обычная логика)
  final String? displayTitle;
  final int? absoluteIndex;

  const WorkoutScreen({
    super.key,
    required this.clientId,
    required this.day,
    this.templateIdx,
    this.displayTitle,
    this.absoluteIndex,
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
  final Map<int, TextEditingController> _nameCtrls = {};
  final Map<int, FocusNode> _nameFocusNodes = {};
  final Map<int, Timer> _nameSaveDebounces = {};
  final Map<int, String> _persistedExerciseNames = {};
  final Set<int> _nameSaveInFlight = <int>{};

  bool _saving = false;
  Timer? _draftAutosaveDebounce;
  bool _draftAutosaveInFlight = false;
  List<WorkoutExerciseVm> _latestExercises = const [];

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
    for (final c in _nameCtrls.values) {
      c.dispose();
    }
    for (final f in _nameFocusNodes.values) {
      f.dispose();
    }
    for (final t in _nameSaveDebounces.values) {
      t.cancel();
    }
    _draftAutosaveDebounce?.cancel();
    super.dispose();
  }

  TextEditingController _kgController(int exId, double? initial) {
    return _kgCtrls.putIfAbsent(exId, () {
      final t = TextEditingController(
        text: initial == null ? '' : _fmtKg(initial),
      );
      t.addListener(_scheduleDraftAutosave);
      return t;
    });
  }

  TextEditingController _repsController(int exId, int? initial) {
    return _repsCtrls.putIfAbsent(exId, () {
      final t = TextEditingController(
        text: initial == null ? '' : initial.toString(),
      );
      t.addListener(_scheduleDraftAutosave);
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

  ({
    Map<int, (double? kg, int? reps)> results,
    List<String> invalidExerciseNames,
  })
  _collectCurrentResults(List<WorkoutExerciseVm> exercises) {
    final map = <int, (double? kg, int? reps)>{};
    final invalid = <String>[];

    for (final e in exercises) {
      final kgRaw = _kgController(e.templateExerciseId, e.lastWeightKg).text;
      final repsRaw = _repsController(e.templateExerciseId, e.lastReps).text;

      final kg = _parseKg(kgRaw);
      final reps = _parseInt(repsRaw);

      final kgInvalid = kgRaw.trim().isNotEmpty && kg == null;
      final repsInvalid = repsRaw.trim().isNotEmpty && reps == null;

      if (kgInvalid || repsInvalid) {
        invalid.add(e.name);
        continue;
      }
      map[e.templateExerciseId] = (kg, reps);
    }

    return (results: map, invalidExerciseNames: invalid);
  }

  Map<int, (double? kg, int? reps)>? _buildResultsOrShowError(
    List<WorkoutExerciseVm> exercises,
  ) {
    final collected = _collectCurrentResults(exercises);
    if (collected.invalidExerciseNames.isEmpty) {
      return collected.results;
    }

    final preview = collected.invalidExerciseNames.take(2).join(', ');
    final suffix = collected.invalidExerciseNames.length > 2 ? '…' : '';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Проверьте формат чисел в упражнениях: $preview$suffix'),
      ),
    );
    return null;
  }

  TextEditingController _nameController(WorkoutExerciseVm e) {
    final id = e.templateExerciseId;
    _persistedExerciseNames.putIfAbsent(id, () => e.name);

    final controller = _nameCtrls.putIfAbsent(id, () {
      final c = TextEditingController(text: e.name);
      c.addListener(() => _scheduleExerciseNameSave(id));
      return c;
    });

    final focusNode = _nameFocusNodes.putIfAbsent(id, () {
      final f = FocusNode();
      f.addListener(() {
        if (f.hasFocus) return;
        _scheduleExerciseNameSave(id, immediate: true);

        final trimmed = controller.text.trim();
        if (trimmed.isNotEmpty) return;

        final fallback = _persistedExerciseNames[id] ?? e.name;
        if (controller.text == fallback) return;
        controller.value = TextEditingValue(
          text: fallback,
          selection: TextSelection.collapsed(offset: fallback.length),
        );
      });
      return f;
    });

    if (!focusNode.hasFocus && controller.text != e.name) {
      controller.value = TextEditingValue(
        text: e.name,
        selection: TextSelection.collapsed(offset: e.name.length),
      );
      _persistedExerciseNames[id] = e.name;
    }

    return controller;
  }

  FocusNode _nameFocusNode(int templateExerciseId) {
    return _nameFocusNodes.putIfAbsent(templateExerciseId, FocusNode.new);
  }

  void _scheduleExerciseNameSave(
    int templateExerciseId, {
    bool immediate = false,
  }) {
    _nameSaveDebounces[templateExerciseId]?.cancel();

    if (immediate) {
      _saveExerciseName(templateExerciseId);
      return;
    }

    _nameSaveDebounces[templateExerciseId] = Timer(
      const Duration(milliseconds: 550),
      () => _saveExerciseName(templateExerciseId),
    );
  }

  Future<void> _saveExerciseName(int templateExerciseId) async {
    if (!mounted) return;
    final controller = _nameCtrls[templateExerciseId];
    if (controller == null) return;

    final nextName = controller.text.trim();
    if (nextName.isEmpty) return;

    final savedName = _persistedExerciseNames[templateExerciseId];
    if (nextName == savedName) return;

    if (_nameSaveInFlight.contains(templateExerciseId)) return;

    _nameSaveInFlight.add(templateExerciseId);
    try {
      await db.renameWorkoutExerciseForClient(
        clientId: widget.clientId,
        templateExerciseId: templateExerciseId,
        newName: nextName,
      );
      _persistedExerciseNames[templateExerciseId] = nextName;
      _scheduleDraftAutosave();
    } finally {
      _nameSaveInFlight.remove(templateExerciseId);
      final current = controller.text.trim();
      if (current.isNotEmpty &&
          current != _persistedExerciseNames[templateExerciseId]) {
        _scheduleExerciseNameSave(templateExerciseId);
      }
    }
  }

  Future<void> _toggleSupersetForExercise(WorkoutExerciseVm e) async {
    await db.toggleClientSupersetWithNext(
      clientId: widget.clientId,
      templateId: e.templateId,
      orderIndex: e.orderIndex,
    );
    if (!mounted) return;
    setState(() {});
    _scheduleDraftAutosave();
  }

  void _scheduleDraftAutosave() {
    if (!mounted) return;
    _draftAutosaveDebounce?.cancel();
    _draftAutosaveDebounce = Timer(const Duration(milliseconds: 650), () {
      _autosaveDraftSilently();
    });
  }

  Future<void> _autosaveDraftSilently() async {
    if (!mounted ||
        _latestExercises.isEmpty ||
        _draftAutosaveInFlight ||
        _saving) {
      return;
    }

    final collected = _collectCurrentResults(_latestExercises);
    if (collected.invalidExerciseNames.isNotEmpty) return;

    _draftAutosaveInFlight = true;
    try {
      await db.saveWorkoutDraftResults(
        clientId: widget.clientId,
        day: widget.day,
        resultsByTemplateExerciseId: collected.results,
        templateIdx: widget.templateIdx,
        absoluteIndex: widget.absoluteIndex,
      );
    } finally {
      _draftAutosaveInFlight = false;
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
        absoluteIndex: widget.absoluteIndex,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
      return;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сохранения тренировки: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _cancelWorkout({
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
        absoluteIndex: widget.absoluteIndex,
      );
      if (widget.templateIdx != null && widget.absoluteIndex != null) {
        await db.toggleWorkoutForClientAtAbsoluteIndex(
          clientId: widget.clientId,
          absoluteIndex: widget.absoluteIndex!,
          templateIdx: widget.templateIdx!,
          when: DateTime(
            widget.day.year,
            widget.day.month,
            widget.day.day,
            12,
            0,
          ),
        );
      } else if (widget.templateIdx != null) {
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при отмене тренировки: $e')),
      );
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

    await db.addWorkoutExerciseForClient(
      clientId: widget.clientId,
      templateId: templateId,
      name: name,
    );
    if (!mounted) return;
    setState(() {});
    _scheduleDraftAutosave();
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

    await db.deleteWorkoutExerciseForClient(
      clientId: widget.clientId,
      templateExerciseId: e.templateExerciseId,
    );
    if (!mounted) return;
    setState(() {});
    _scheduleDraftAutosave();
  }

  Future<_WorkoutScreenData> _loadScreenData() async {
    final client = await db.getClientById(widget.clientId);

    final data = widget.templateIdx == null
        ? await db.getWorkoutDetailsForClientOnDay(
            clientId: widget.clientId,
            day: widget.day,
          )
        : (widget.absoluteIndex != null
              ? await db.getWorkoutDetailsForClientProgramSlot(
                  clientId: widget.clientId,
                  absoluteIndex: widget.absoluteIndex!,
                  templateIdx: widget.templateIdx!,
                )
              : await db.getWorkoutDetailsForClientOnDayForcedTemplateIdx(
                  clientId: widget.clientId,
                  day: widget.day,
                  templateIdx: widget.templateIdx!,
                ));

    final drafts = await db.getWorkoutDraftResults(
      clientId: widget.clientId,
      day: widget.day,
      templateIdx: widget.templateIdx,
      absoluteIndex: widget.absoluteIndex,
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
          _latestExercises = exercises;

          if (!info.hasPlan) {
            return const Center(
              child: Text('У клиента нет программы/абонемента'),
            );
          }

          final header = _Header(info: info, displayTitle: widget.displayTitle);

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
          Map<int, (double? kg, int? reps)>? buildResults() {
            return _buildResultsOrShowError(exercises);
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
                onMarkDone: () {
                  final results = buildResults();
                  if (results == null) return;
                  _markDone(results: results);
                },
                onCancel: () {
                  final results = buildResults();
                  if (results == null) return;
                  _cancelWorkout(results: results);
                },
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
        TextField(
          controller: _nameController(e),
          focusNode: _nameFocusNode(e.templateExerciseId),
          textInputAction: TextInputAction.next,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            height: 1.25,
            letterSpacing: 0.1,
          ),
          decoration: InputDecoration(
            prefixIcon: const _WorkoutAssetIcon(
              'exercise_title_edit',
              size: 18,
            ),
            labelText: 'Название',
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
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: hasNext
                  ? FilledButton.tonalIcon(
                      onPressed: () => _toggleSupersetForExercise(e),
                      icon: const _WorkoutAssetIcon('superset', size: 16),
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
                icon: const _WorkoutAssetIcon('delete', size: 18),
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
                  prefixIcon: const _WorkoutAssetIcon('weight', size: 18),
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
                  prefixIcon: const _WorkoutAssetIcon('reps', size: 18),
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
  final String? displayTitle;
  const _Header({required this.info, this.displayTitle});

  @override
  Widget build(BuildContext context) {
    final title = displayTitle ?? '${info.label} — ${info.title}';
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
              child: _WorkoutAssetIcon(
                done ? 'mark_done' : 'day_header',
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
  final VoidCallback onMarkDone;
  final VoidCallback onCancel;

  const _BottomBar({
    required this.saving,
    required this.done,
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
            if (done)
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
              )
            else
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: saving ? null : onMarkDone,
                  icon: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const _WorkoutAssetIcon('mark_done', size: 18),
                  label: const Text('Отметить выполнено'),
                ),
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
          const _WorkoutAssetIcon('day_editor', size: 18),
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
                  const _WorkoutAssetIcon('superset', size: 16),
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
