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
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Мужчины'),
              Tab(text: 'Женщины'),
              Tab(text: 'Пробная'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ProgramTemplatesTab(future: _maleFuture, onChanged: _reload),
            _ProgramTemplatesTab(future: _femaleFuture, onChanged: _reload),
            const _TrialProgramTab(exercises: _trialExercises),
          ],
        ),
      ),
    );
  }
}

class _ProgramTemplatesTab extends StatelessWidget {
  const _ProgramTemplatesTab({required this.future, required this.onChanged});

  final Future<List<WorkoutTemplate>> future;
  final Future<void> Function() onChanged;

  String _titleWithoutDayPrefix(String title) {
    final parts = title.split('•');
    if (parts.length > 1 && parts.first.trim().startsWith('День')) {
      return parts.sublist(1).join('•').trim();
    }
    return title.trim();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

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

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final t = list[i];
            return _EditableTemplateTile(
              template: t,
              title: _titleWithoutDayPrefix(t.title),
              onChanged: onChanged,
            );
          },
        );
      },
    );
  }
}

class _EditableTemplateTile extends StatefulWidget {
  const _EditableTemplateTile({
    required this.template,
    required this.title,
    required this.onChanged,
  });

  final WorkoutTemplate template;
  final String title;
  final Future<void> Function() onChanged;

  @override
  State<_EditableTemplateTile> createState() => _EditableTemplateTileState();
}

class _EditableTemplateTileState extends State<_EditableTemplateTile> {
  late Future<List<WorkoutTemplateExercise>> _exFuture;

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

  Future<void> _renameExercise(WorkoutTemplateExercise e) async {
    final ctrl = TextEditingController(text: e.name);
    final next = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Переименовать упражнение'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Новое название',
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

    if (next == null || next.trim().isEmpty) return;

    final db = AppDbScope.of(context);
    await db.renameWorkoutTemplateExercise(
      templateExerciseId: e.id,
      newName: next,
    );

    if (!mounted) return;
    await _refreshExercises();
    await widget.onChanged();
  }

  Future<void> _toggleSuperset(WorkoutTemplateExercise e) async {
    final db = AppDbScope.of(context);
    await db.toggleTemplateSupersetWithNext(
      templateId: widget.template.id,
      orderIndex: e.orderIndex,
    );

    if (!mounted) return;
    await _refreshExercises();
    await widget.onChanged();
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
    await widget.onChanged();
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
    await widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant.withOpacity(0.7)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(14, 6, 10, 6),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          title: Text(widget.title),
          subtitle: Text('Тренировка ${widget.template.idx + 1}'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          children: [
            FutureBuilder<List<WorkoutTemplateExercise>>(
              future: _exFuture,
              builder: (context, exSnap) {
                if (exSnap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final ex = exSnap.data ?? const <WorkoutTemplateExercise>[];

                return Column(
                  children: [
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
                                  child: Text(
                                    e.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
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
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelSmall,
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
                                  onPressed: () => _renameExercise(e),
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Название'),
                                ),
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
    final colors = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colors.outlineVariant.withOpacity(0.7)),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: true,
              tilePadding: const EdgeInsets.fromLTRB(14, 6, 10, 6),
              childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              title: const Text('Пробная тренировка'),
              subtitle: const Text('Тренировка 1'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              collapsedShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              children: [
                for (final e in exercises)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(e),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
