import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_db_scope.dart';
import '../../db/app_db.dart';
import 'exercise_merge_screen.dart';

enum ExerciseCatalogAction { refresh, duplicates, manualMerge, copyMapping }

class ExerciseCatalogController {
  _ExerciseCatalogScreenState? _state;

  void _attach(_ExerciseCatalogScreenState state) => _state = state;

  void _detach(_ExerciseCatalogScreenState state) {
    if (identical(_state, state)) _state = null;
  }

  Future<void> createExercise() async => _state?._create();

  Future<void> perform(ExerciseCatalogAction action) async {
    final state = _state;
    if (state == null) return;
    await state._performAction(action);
  }
}

class ExerciseCatalogTopActions extends StatelessWidget {
  const ExerciseCatalogTopActions({super.key, required this.controller});

  final ExerciseCatalogController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: const Key('exercise_catalog_add'),
          tooltip: 'Добавить упражнение',
          onPressed: controller.createExercise,
          icon: const Icon(Icons.add),
        ),
        PopupMenuButton<ExerciseCatalogAction>(
          key: const Key('exercise_catalog_more'),
          tooltip: 'Действия',
          icon: const Icon(Icons.more_vert),
          onSelected: controller.perform,
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: ExerciseCatalogAction.refresh,
              child: Text('Обновить'),
            ),
            PopupMenuItem(
              value: ExerciseCatalogAction.duplicates,
              child: Text('Разобрать дубли'),
            ),
            PopupMenuItem(
              value: ExerciseCatalogAction.manualMerge,
              child: Text('Объединить вручную'),
            ),
            PopupMenuItem(
              value: ExerciseCatalogAction.copyMapping,
              child: Text('Скопировать mapping'),
            ),
          ],
        ),
      ],
    );
  }
}

class ExerciseCatalogScreen extends StatefulWidget {
  const ExerciseCatalogScreen({
    super.key,
    this.embedded = false,
    this.controller,
  });

  final bool embedded;
  final ExerciseCatalogController? controller;

  @override
  State<ExerciseCatalogScreen> createState() => _ExerciseCatalogScreenState();
}

class _ExerciseCatalogScreenState extends State<ExerciseCatalogScreen> {
  final bool _showArchived = false;
  String _query = '';
  late Future<List<ExerciseIdentity>> _future;
  late final ExerciseCatalogController _localController;
  final ScrollController _scrollController = ScrollController();
  double? _pendingScrollOffset;

  @override
  void initState() {
    super.initState();
    _localController = ExerciseCatalogController().._attach(this);
    widget.controller?._attach(this);
  }

  @override
  void didUpdateWidget(covariant ExerciseCatalogScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    _localController._detach(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reload();
  }

  void _reload() {
    if (_scrollController.hasClients) {
      _pendingScrollOffset = _scrollController.offset;
    }
    _future = AppDbScope.of(context).getExercises(
      includeArchived: _showArchived,
      includeMerged: _showArchived,
    );
  }

  void _restoreScrollOffsetAfterBuild() {
    final requestedOffset = _pendingScrollOffset;
    if (requestedOffset == null) return;
    _pendingScrollOffset = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final position = _scrollController.position;
      final target = requestedOffset
          .clamp(position.minScrollExtent, position.maxScrollExtent)
          .toDouble();
      if ((_scrollController.offset - target).abs() > 0.5) {
        _scrollController.jumpTo(target);
      }
    });
  }

  Future<void> _performAction(ExerciseCatalogAction action) async {
    switch (action) {
      case ExerciseCatalogAction.refresh:
        setState(_reload);
      case ExerciseCatalogAction.duplicates:
        await _openDuplicates();
      case ExerciseCatalogAction.manualMerge:
        await _openManualMerge();
      case ExerciseCatalogAction.copyMapping:
        await _copyUuidMapping();
    }
  }

  Future<void> _openDuplicates() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const ExerciseDuplicatesScreen()),
    );
    if (mounted) setState(_reload);
  }

  Future<void> _openManualMerge() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ManualExerciseMergeScreen()),
    );
    if (mounted) setState(_reload);
  }

  Future<void> _copyUuidMapping() async {
    final mappings = await AppDbScope.of(context).getExerciseUuidAliases();
    if (!mounted) return;
    if (mappings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Соответствий UUID пока нет')),
      );
      return;
    }
    final text = const JsonEncoder.withIndent('  ').convert({
      'exercise_uuid_mapping': mappings.map((item) => item.toJson()).toList(),
    });
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Соответствия UUID скопированы')),
    );
  }

  Future<String?> _askName({
    String title = 'Новое упражнение',
    String value = '',
  }) {
    final controller = TextEditingController(text: value);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Название упражнения',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => Navigator.pop(context, controller.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  Future<void> _create() async {
    final name = await _askName();
    if (name == null) return;
    try {
      await AppDbScope.of(context).createExercise(name);
      if (mounted) setState(_reload);
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось добавить упражнение: $error')),
        );
      }
    }
  }

  Future<void> _rename(ExerciseIdentity exercise) async {
    final name = await _askName(
      title: 'Переименовать упражнение',
      value: exercise.canonicalName,
    );
    if (name == null) return;
    try {
      await AppDbScope.of(
        context,
      ).renameExercise(exerciseId: exercise.id, name: name);
      if (mounted) setState(_reload);
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  Future<bool> _confirmArchive(ExerciseIdentity exercise) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Архивировать упражнение?'),
            content: Text(
              '«${exercise.canonicalName}» исчезнет из выбора для новых '
              'слотов. Уже назначенные слоты и история тренировок сохранятся.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Отмена'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('В архив'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildBody(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Поиск упражнений',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<ExerciseIdentity>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final normalized = AppDb.normalizeExerciseName(_query);
              final items = (snapshot.data ?? const <ExerciseIdentity>[])
                  .where((item) => item.normalizedName.contains(normalized))
                  .toList(growable: false);
              if (items.isEmpty) {
                return const Center(child: Text('Упражнений не найдено'));
              }
              _restoreScrollOffsetAfterBuild();
              return ListView.separated(
                key: const PageStorageKey<String>('exercise_catalog_list'),
                controller: _scrollController,
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final archived = item.status == AppDb.archivedExerciseStatus;
                  final merged = item.mergedIntoIdentityId != null;
                  return ListTile(
                    key: ValueKey('exercise_${item.id}'),
                    title: Text(item.canonicalName),
                    subtitle: merged
                        ? Text(
                            'Объединено с identity #${item.mergedIntoIdentityId}',
                          )
                        : archived
                        ? const Text('В архиве')
                        : null,
                    trailing: merged
                        ? const Tooltip(
                            message:
                                'Объединённое упражнение нельзя восстановить отдельно',
                            child: Icon(Icons.merge_type),
                          )
                        : PopupMenuButton<String>(
                            onSelected: (action) async {
                              if (action == 'rename') await _rename(item);
                              if (action == 'archive') {
                                if (!await _confirmArchive(item)) return;
                                await AppDbScope.of(
                                  context,
                                ).archiveExercise(item.id);
                                if (mounted) setState(_reload);
                              }
                              if (action == 'restore') {
                                try {
                                  await AppDbScope.of(
                                    context,
                                  ).restoreExercise(item.id);
                                  if (mounted) setState(_reload);
                                } on Object catch (error) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('$error')),
                                    );
                                  }
                                }
                              }
                            },
                            itemBuilder: (_) => [
                              if (!archived)
                                const PopupMenuItem(
                                  value: 'rename',
                                  child: Text('Переименовать'),
                                ),
                              PopupMenuItem(
                                value: archived ? 'restore' : 'archive',
                                child: Text(
                                  archived ? 'Восстановить' : 'В архив',
                                ),
                              ),
                            ],
                          ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody(context);
    if (widget.embedded) {
      return Scaffold(body: body);
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('База упражнений'),
        actions: [ExerciseCatalogTopActions(controller: _localController)],
      ),
      body: body,
    );
  }
}
