import 'package:flutter/material.dart';

import '../../app/app_db_scope.dart';
import '../../db/app_db.dart';
import '../exercises/exercise_selector_sheet.dart';

class LegacyExerciseBindingsScreen extends StatefulWidget {
  const LegacyExerciseBindingsScreen({super.key});

  @override
  State<LegacyExerciseBindingsScreen> createState() =>
      _LegacyExerciseBindingsScreenState();
}

class _LegacyExerciseBindingsScreenState
    extends State<LegacyExerciseBindingsScreen> {
  late Future<LegacyExerciseBindingsAuditVm> _audit;
  final Set<String> _selectedGroups = {};
  final Map<String, ExerciseIdentity> _selectedTargets = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _audit = AppDbScope.of(context).analyzeLegacyExerciseBindings();
  }

  void _reload() => setState(() {
    _selectedGroups.clear();
    _selectedTargets.clear();
    _audit = AppDbScope.of(context).analyzeLegacyExerciseBindings();
  });

  ExerciseIdentity? _targetFor(LegacyExerciseBindingGroupVm group) =>
      _selectedTargets[group.normalizedName] ?? group.exactCatalogMatch;

  void _suggestExactMatches(LegacyExerciseBindingsAuditVm audit) {
    setState(() {
      _selectedGroups.clear();
      for (final group in audit.groups) {
        final match = group.exactCatalogMatch;
        if (match == null) continue;
        _selectedTargets[group.normalizedName] = match;
        _selectedGroups.add(group.normalizedName);
      }
    });
  }

  Future<void> _chooseTarget(LegacyExerciseBindingGroupVm group) async {
    final selected = await showExerciseSelector(
      context,
      database: AppDbScope.of(context),
      allowCreate: false,
    );
    if (selected == null || !mounted) return;
    setState(() {
      _selectedTargets[group.normalizedName] = selected;
      _selectedGroups.add(group.normalizedName);
    });
  }

  List<LegacyExerciseBulkCorrectionRequest> _requestsFor(
    LegacyExerciseBindingsAuditVm audit,
  ) {
    return [
      for (final group in audit.groups)
        if (_selectedGroups.contains(group.normalizedName))
          if (_targetFor(group) case final target?)
            LegacyExerciseBulkCorrectionRequest(
              normalizedLegacyName: group.normalizedName,
              targetExerciseIdentityId: target.id,
            ),
    ];
  }

  Future<void> _applySelected(LegacyExerciseBindingsAuditVm audit) async {
    final requests = _requestsFor(audit);
    if (requests.isEmpty) return;
    final db = AppDbScope.of(context);
    try {
      final preview = await db.previewLegacyExerciseBulkCorrection(requests);
      if (!mounted) return;
      final targetLines = preview.targets
          .map(
            (item) =>
                '• ${item.legacyName} → ${item.targetName}\n  '
                '${item.targetExternalId}',
          )
          .join('\n');
      final confirmed =
          await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Исправить подтверждённые группы?'),
              content: SingleChildScrollView(
                child: SelectableText(
                  'Будет изменено:\n'
                  '• групп: ${preview.groups}\n'
                  '• historical results: ${preview.historicalResults}\n'
                  '• current slots: ${preview.currentSlots}\n'
                  '• тренировок в очередь: ${preview.affectedSessions}\n\n'
                  'Названия, веса, повторы, sessions и даты в истории '
                  'изменены не будут.\n\n$targetLines',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Отмена'),
                ),
                FilledButton(
                  key: const Key('legacy_bulk_confirm'),
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Исправить'),
                ),
              ],
            ),
          ) ??
          false;
      if (!confirmed) return;

      final result = await db.reassignLegacyExerciseGroups(requests);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Исправлено групп: ${result.groups}, results: '
            '${result.changedHistoricalResults}, slots: '
            '${result.changedCurrentSlots}. В очередь добавлено: '
            '${result.requeuedWorkoutSessions}. '
            'Запустите синхронизацию вручную.',
          ),
        ),
      );
      _reload();
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось исправить группы: $error')),
      );
    }
  }

  Widget _candidateDetails(LegacyExerciseBindingCandidateVm candidate) {
    final colors = Theme.of(context).colorScheme;
    final snapshots = candidate.snapshotGroups
        .map((item) => '${item.name} (${item.resultCount})')
        .join(', ');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${candidate.clientName} • ${candidate.programSlot}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text('Текущая identity: ${candidate.currentIdentityName}'),
          SelectableText(
            candidate.currentIdentityExternalId,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 4),
          Text('Snapshots: $snapshots'),
          if (candidate.hasMixedIdentityHistory)
            Text(
              'Mixed history: изменятся только snapshots с точным именем '
              'группы.',
              style: TextStyle(color: colors.error),
            ),
        ],
      ),
    );
  }

  Widget _groupCard(LegacyExerciseBindingGroupVm group) {
    final colors = Theme.of(context).colorScheme;
    final target = _targetFor(group);
    final selected = _selectedGroups.contains(group.normalizedName);
    return Card(
      child: ExpansionTile(
        key: ValueKey('legacy_group_${group.normalizedName}'),
        leading: Checkbox(
          key: ValueKey('legacy_group_check_${group.normalizedName}'),
          value: selected,
          onChanged: target == null
              ? null
              : (value) => setState(() {
                  if (value ?? false) {
                    _selectedGroups.add(group.normalizedName);
                  } else {
                    _selectedGroups.remove(group.normalizedName);
                  }
                }),
        ),
        title: Text(group.displayName),
        subtitle: Text(
          '${group.clientCount} клиентов • ${group.slotCount} slots • '
          '${group.historicalResultCount} historical results',
        ),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: target == null
                      ? Text(
                          'Точного единственного совпадения нет',
                          style: TextStyle(color: colors.onSurfaceVariant),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.exactCatalogMatch?.id == target.id &&
                                      !_selectedTargets.containsKey(
                                        group.normalizedName,
                                      )
                                  ? 'Предложено точное совпадение'
                                  : 'Выбранное упражнение',
                              style: TextStyle(color: colors.onSurfaceVariant),
                            ),
                            Text(
                              target.canonicalName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SelectableText(
                              target.externalId,
                              style: const TextStyle(fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                ),
                TextButton(
                  key: ValueKey('legacy_group_target_${group.normalizedName}'),
                  onPressed: () => _chooseTarget(group),
                  child: Text(target == null ? 'Выбрать' : 'Изменить'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          for (final candidate in group.candidates)
            _candidateDetails(candidate),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Legacy-привязки'),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<LegacyExerciseBindingsAuditVm>(
        future: _audit,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка анализа: ${snapshot.error}'));
          }
          final audit = snapshot.requireData;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Проблемы сгруппированы по отображаемому имени. '
                'Автоматически предлагаются только единственные точные '
                'ACTIVE-совпадения; исправление всегда требует подтверждения.',
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    key: const Key('legacy_suggest_exact'),
                    onPressed:
                        audit.groups.any(
                          (group) => group.exactCatalogMatch != null,
                        )
                        ? () => _suggestExactMatches(audit)
                        : null,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Предложить точные совпадения'),
                  ),
                  FilledButton.icon(
                    key: const Key('legacy_apply_selected'),
                    onPressed: _selectedGroups.isEmpty
                        ? null
                        : () => _applySelected(audit),
                    icon: const Icon(Icons.link),
                    label: Text(
                      'Исправить подтверждённые группы '
                      '(${_selectedGroups.length})',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                key: const Key('legacy_orphan_bindings'),
                child: ListTile(
                  title: const Text('Orphan bindings'),
                  subtitle: const Text(
                    'Только диагностика. Автоматическое удаление отключено.',
                  ),
                  trailing: Text('${audit.orphanBindings}'),
                ),
              ),
              const SizedBox(height: 8),
              if (audit.groups.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 32),
                  child: Center(child: Text('Legacy-кандидаты не найдены')),
                )
              else
                for (final group in audit.groups) _groupCard(group),
            ],
          );
        },
      ),
    );
  }
}
