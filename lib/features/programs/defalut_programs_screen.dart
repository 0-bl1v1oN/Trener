import 'dart:async';
import 'package:flutter/material.dart';

import '../../app/app_db_scope.dart';
import '../../db/app_db.dart';

class DefaultProgramsScreen extends StatefulWidget {
  const DefaultProgramsScreen({super.key});

  @override
  State<DefaultProgramsScreen> createState() => _DefaultProgramsScreenState();
}

class _DefaultProgramsScreenState extends State<DefaultProgramsScreen> {
  bool _loaded = false;
  late Future<List<WorkoutTemplate>> _maleFuture;
  late Future<List<WorkoutTemplate>> _femaleFuture;

  static const List<String> _trialExercises = [
    'Тяга верхнего блока параллельным хватом',
    'Тяга нижнего блока самолётным хватом',
    'Жим в хамере',
    'Жим ногами',
    'Выпады на месте',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    _reload();
  }

  Future<void> _reload() async {
    final db = AppDbScope.of(context);
    setState(() {
      _maleFuture = db.getWorkoutTemplatesByGender('М');
      _femaleFuture = db.getWorkoutTemplatesByGender('Ж');
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Программа'),
          actions: [
            IconButton(
              onPressed: _reload,
              icon: const Icon(Icons.refresh),
              tooltip: 'Обновить',
            ),
          ],
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Мужчины'),
              Tab(text: 'Женщины'),
              Tab(text: 'Пробная'),
            ],
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        body: TabBarView(
          children: [
            _ProgramTemplatesTab(future: _maleFuture),
            _ProgramTemplatesTab(future: _femaleFuture),
            const _TrialProgramTab(exercises: _trialExercises),
          ],
        ),
      ),
    );
  }
}

class _ProgramTemplatesTab extends StatelessWidget {
  const _ProgramTemplatesTab({required this.future});

  final Future<List<WorkoutTemplate>> future;

  String _titleWithoutDayPrefix(String title) {
    final parts = title.split('•');
    if (parts.length > 1 && parts.first.trim().startsWith('День')) {
      return parts.sublist(1).join('•').trim();
    }
    return title.trim();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return FutureBuilder<List<WorkoutTemplate>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Ошибка: ${snap.error}'));
        }

        final list = snap.data ?? const <WorkoutTemplate>[];
        if (list.isEmpty) {
          return const Center(child: Text('Шаблоны не найдены'));
        }

        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: [
                    colors.primaryContainer.withOpacity(0.55),
                    colors.surface,
                  ],
                ),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Text(
                'Редактируйте упражнения прямо в карточке: название, суперсеты, добавление и удаление.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
            for (final t in list) ...[
              _EditableTemplateTile(
                template: t,
                title: _titleWithoutDayPrefix(t.title),
              ),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}

class _EditableTemplateTile extends StatefulWidget {
  const _EditableTemplateTile({required this.template, required this.title});

  final WorkoutTemplate template;
  final String title;

  @override
  State<_EditableTemplateTile> createState() => _EditableTemplateTileState();
}

class _EditableTemplateTileState extends State<_EditableTemplateTile> {
  late Future<List<WorkoutTemplateExercise>> _exFuture;
  final Map<int, TextEditingController> _nameCtrls = {};
  final Map<int, FocusNode> _nameFocusNodes = {};
  final Map<int, Timer> _nameSaveDebounces = {};
  final Map<int, String> _persistedExerciseNames = {};
  final Set<int> _nameSaveInFlight = <int>{};
  List<WorkoutTemplateExercise> _lastExercises = const [];

  @override
  void initState() {
    super.initState();
    _exFuture = _loadExercises();
  }

  @override
  void didUpdateWidget(covariant _EditableTemplateTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.template.id != widget.template.id) {
      _exFuture = _loadExercises();
    }
  }

  Future<List<WorkoutTemplateExercise>> _loadExercises() {
    final db = AppDbScope.of(context);
    return db.getTemplateExercisesByTemplateId(widget.template.id);
  }

  Future<void> _refreshExercises() async {
    setState(() {
      _exFuture = _loadExercises();
    });
  }

  @override
  void dispose() {
    for (final c in _nameCtrls.values) {
      c.dispose();
    }
    for (final f in _nameFocusNodes.values) {
      f.dispose();
    }
    for (final t in _nameSaveDebounces.values) {
      t.cancel();
    }
    super.dispose();
  }

  TextEditingController _nameController(WorkoutTemplateExercise e) {
    final id = e.id;
    _persistedExerciseNames.putIfAbsent(id, () => e.name);

    final controller = _nameCtrls.putIfAbsent(id, () {
      final c = TextEditingController(text: e.name);
      c.addListener(() => _scheduleExerciseNameSave(id));
      return c;
    });

    final focusNode = _nameFocusNodes.putIfAbsent(id, () {
      final f = FocusNode();
      f.addListener(() {
        if (f.hasFocus) {
          final c = _nameCtrls[id];
          if (c == null) return;
          c.selection = TextSelection(
            baseOffset: 0,
            extentOffset: c.text.length,
          );
          return;
        }

        _scheduleExerciseNameSave(id, immediate: true);

        final c = _nameCtrls[id];
        if (c == null) return;
        final trimmed = c.text.trim();
        if (trimmed.isNotEmpty) return;

        final fallback = _persistedExerciseNames[id] ?? e.name;
        if (c.text == fallback) return;
        c.value = TextEditingValue(
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
      const Duration(milliseconds: 500),
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
      final db = AppDbScope.of(context);
      await db.renameWorkoutTemplateExercise(
        templateExerciseId: templateExerciseId,
        newName: nextName,
      );
      _persistedExerciseNames[templateExerciseId] = nextName;
    } finally {
      _nameSaveInFlight.remove(templateExerciseId);
      final current = controller.text.trim();
      if (current.isNotEmpty &&
          current != _persistedExerciseNames[templateExerciseId]) {
        _scheduleExerciseNameSave(templateExerciseId);
      }
    }
  }

  Future<void> _replaceExerciseNameByGender(WorkoutTemplateExercise e) async {
    final fromController = TextEditingController(text: e.name);
    final toController = TextEditingController();

    final next = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Заменить упражнение'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: fromController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Заменяем',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: toController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'На что заменить',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, toController.text.trim()),
            child: const Text('Заменить'),
          ),
        ],
      ),
    );

    final replacement = next?.trim() ?? '';
    if (replacement.isEmpty || replacement == e.name.trim()) return;

    final db = AppDbScope.of(context);
    final changed = await db.replaceTemplateExerciseNameByGender(
      gender: widget.template.gender,
      oldName: e.name,
      newName: replacement,
    );

    if (!mounted) return;
    await _refreshExercises();
    if (!mounted) return;

    final scope = widget.template.gender == 'М' ? 'мужской' : 'женской';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Заменено: $changed (программа: $scope)')),
    );
  }

  Future<void> _toggleSuperset(WorkoutTemplateExercise e) async {
    final db = AppDbScope.of(context);
    await db.toggleTemplateSupersetWithNext(
      templateId: widget.template.id,
      orderIndex: e.orderIndex,
    );

    if (!mounted) return;
    await _refreshExercises();
  }

  Future<void> _deleteExercise(WorkoutTemplateExercise e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить упражнение?'),
        content: Text('«${e.name}» будет удалено из шаблона.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final db = AppDbScope.of(context);
    await db.deleteWorkoutTemplateExercise(e.id);

    if (!mounted) return;
    await _refreshExercises();
  }

  Future<void> _addExercise() async {
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

    final db = AppDbScope.of(context);
    await db.addWorkoutTemplateExercise(
      templateId: widget.template.id,
      name: name,
    );

    if (!mounted) return;
    await _refreshExercises();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant.withOpacity(0.7)),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '#${widget.template.idx + 1}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          subtitle: const Text('Редактируемый шаблон тренировки'),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          children: [
            FutureBuilder<List<WorkoutTemplateExercise>>(
              future: _exFuture,
              builder: (context, exSnap) {
                final loaded = exSnap.data;
                if (loaded != null) {
                  _lastExercises = loaded;
                }
                final ex = loaded ?? _lastExercises;

                return Column(
                  children: [
                    if (exSnap.connectionState == ConnectionState.waiting)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: LinearProgressIndicator(minHeight: 2),
                      ),
                    if (ex.isEmpty)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest.withOpacity(
                            0.25,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Упражнений пока нет'),
                      ),
                    for (final e in ex)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest.withOpacity(
                            0.3,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.outlineVariant),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _nameController(e),
                                    focusNode: _nameFocusNode(e.id),

                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                if (e.groupId != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colors.tertiaryContainer,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      'Суперсет',
                                      style: theme.textTheme.labelSmall,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                FilledButton.tonalIcon(
                                  onPressed: () => _toggleSuperset(e),
                                  icon: const Icon(Icons.link),
                                  label: Text(
                                    e.groupId == null
                                        ? 'Суперсет +'
                                        : 'Убрать суперсет',
                                  ),
                                ),
                                FilledButton.tonalIcon(
                                  onPressed: () =>
                                      _replaceExerciseNameByGender(e),
                                  icon: const Icon(Icons.find_replace),
                                  label: const Text('Заменить'),
                                ),
                                FilledButton.tonalIcon(
                                  onPressed: () => _deleteExercise(e),
                                  icon: const Icon(Icons.delete_outline),
                                  label: const Text('Удалить'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _addExercise,
                        icon: const Icon(Icons.add),
                        label: const Text('Добавить упражнение'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TrialProgramTab extends StatelessWidget {
  const _TrialProgramTab({required this.exercises});

  final List<String> exercises;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: [
                colors.tertiaryContainer.withOpacity(0.55),
                colors.surface,
              ],
            ),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Text(
            'Пробная тренировка оформлена в том же стиле: компактно, наглядно и без перегруза.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colors.outlineVariant.withOpacity(0.7)),
          ),
          child: Theme(
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: true,
              tilePadding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
              childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.tertiaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '#1',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Пробная тренировка',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: const Text('Быстрый сценарий на знакомство с клиентом'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              collapsedShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              children: [
                for (var i = 0; i < exercises.length; i++)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest.withOpacity(0.30),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: colors.primaryContainer,
                          child: Text(
                            '${i + 1}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(exercises[i])),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
