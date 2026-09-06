import 'package:flutter/material.dart';

import '../../app/app_db_scope.dart';
import '../../db/app_db.dart';

Future<bool> _confirmExerciseMerge(
  BuildContext context, {
  required ExerciseIdentity canonical,
  required int duplicateCount,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Объединить упражнения?'),
          content: Text(
            'Основным станет «${canonical.canonicalName}»\n'
            'UUID: ${canonical.externalId}\n\n'
            'Все выбранные дубли ($duplicateCount) будут объединены с этим '
            'упражнением. История тренировок сохранится, а старые UUID будут '
            'привязаны к выбранному UUID.\n\n'
            'Автоматически отменить это действие нельзя. Перед крупным '
            'объединением рекомендуется создать резервную копию.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Продолжить'),
            ),
          ],
        ),
      ) ??
      false;
}

class ExerciseDuplicatesScreen extends StatefulWidget {
  const ExerciseDuplicatesScreen({super.key});

  @override
  State<ExerciseDuplicatesScreen> createState() =>
      _ExerciseDuplicatesScreenState();
}

class _ExerciseDuplicatesScreenState extends State<ExerciseDuplicatesScreen> {
  late Future<List<ExerciseDuplicateGroupVm>> _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reload();
  }

  void _reload() {
    _future = AppDbScope.of(context).getExerciseDuplicateGroups();
  }

  Future<void> _merge(
    ExerciseDuplicateGroupVm group,
    ExerciseIdentity canonical,
  ) async {
    final duplicates = group.items
        .map((item) => item.exercise.id)
        .where((id) => id != canonical.id)
        .toList(growable: false);
    if (!await _confirmExerciseMerge(
      context,
      canonical: canonical,
      duplicateCount: duplicates.length,
    )) {
      return;
    }
    if (!mounted) return;
    try {
      final result = await AppDbScope.of(context).mergeExerciseIdentities(
        canonicalIdentityId: canonical.id,
        duplicateIdentityIds: duplicates,
      );
      if (!mounted) return;
      setState(_reload);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Не удалось объединить: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Дубли упражнений')),
      body: FutureBuilder<List<ExerciseDuplicateGroupVm>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }
          final groups = snapshot.data ?? const <ExerciseDuplicateGroupVm>[];
          if (groups.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Exact-дубли не найдены. Ничего не объединялось автоматически.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              final mostUsed = group.items
                  .map((item) => item.totalUsage)
                  .reduce((a, b) => a > b ? a : b);
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  title: Text(group.items.first.exercise.canonicalName),
                  subtitle: Text('${group.items.length} вариантов'),
                  children: [
                    for (final item in group.items)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.exercise.canonicalName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                if (item.totalUsage == mostUsed)
                                  const Text('Чаще использовалось'),
                              ],
                            ),
                            const SizedBox(height: 4),
                            SelectableText(
                              item.exercise.externalId,
                              style: const TextStyle(fontFamily: 'monospace'),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Статус: ${item.exercise.status} · '
                              'базовые слоты: ${item.templateSlots} · '
                              'клиентские: ${item.clientSlots} · '
                              'результаты: ${item.workoutResults} · '
                              'bindings: ${item.bindings}',
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => _merge(group, item.exercise),
                                child: const Text('Сделать основным'),
                              ),
                            ),
                            const Divider(),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ManualExerciseMergeScreen extends StatefulWidget {
  const ManualExerciseMergeScreen({super.key});

  @override
  State<ManualExerciseMergeScreen> createState() =>
      _ManualExerciseMergeScreenState();
}

class _ManualExerciseMergeScreenState extends State<ManualExerciseMergeScreen> {
  late Future<List<ExerciseIdentity>> _future;
  int? _canonicalId;
  final Set<int> _duplicateIds = {};
  String _query = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future = AppDbScope.of(context).getExercises(includeArchived: true);
  }

  Future<void> _submit(List<ExerciseIdentity> items) async {
    final canonicalId = _canonicalId;
    if (canonicalId == null || _duplicateIds.isEmpty) return;
    final canonical = items.firstWhere((item) => item.id == canonicalId);
    if (!await _confirmExerciseMerge(
      context,
      canonical: canonical,
      duplicateCount: _duplicateIds.length,
    )) {
      return;
    }
    if (!mounted) return;
    try {
      final result = await AppDbScope.of(context).mergeExerciseIdentities(
        canonicalIdentityId: canonicalId,
        duplicateIdentityIds: _duplicateIds,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
      Navigator.pop(context, true);
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Не удалось объединить: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Объединить упражнения')),
      body: FutureBuilder<List<ExerciseIdentity>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final allItems = snapshot.data ?? const <ExerciseIdentity>[];
          final normalizedQuery = AppDb.normalizeExerciseName(_query);
          final items = allItems
              .where((item) => item.normalizedName.contains(normalizedQuery))
              .toList(growable: false);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Поиск без автоматического fuzzy-выбора',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Отметьте одно основное упражнение и дубли, которые нужно '
                  'привязать к его UUID.',
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final canonical = item.id == _canonicalId;
                    final duplicate = _duplicateIds.contains(item.id);
                    return ListTile(
                      title: Text(item.canonicalName),
                      subtitle: Text(
                        '${item.externalId}\n${item.status}',
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                      isThreeLine: true,
                      leading: Radio<int>(
                        value: item.id,
                        groupValue: _canonicalId,
                        onChanged: (value) => setState(() {
                          _canonicalId = value;
                          if (value != null) _duplicateIds.remove(value);
                        }),
                      ),
                      trailing: Checkbox(
                        value: duplicate,
                        onChanged: canonical
                            ? null
                            : (value) => setState(() {
                                if (value == true) {
                                  _duplicateIds.add(item.id);
                                } else {
                                  _duplicateIds.remove(item.id);
                                }
                              }),
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                minimum: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _canonicalId != null && _duplicateIds.isNotEmpty
                        ? () => _submit(allItems)
                        : null,
                    icon: const Icon(Icons.merge_type),
                    label: Text(
                      'Объединить выбранные (${_duplicateIds.length})',
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
