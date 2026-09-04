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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _audit = AppDbScope.of(context).analyzeLegacyExerciseBindings();
  }

  void _reload() => setState(() {
    _audit = AppDbScope.of(context).analyzeLegacyExerciseBindings();
  });

  Future<({Set<int> resultIds, bool currentSlot})?> _chooseScope(
    LegacyExerciseBindingCandidateVm candidate,
  ) async {
    final selected = <int>{};
    var currentSlot = false;
    return showDialog<({Set<int> resultIds, bool currentSlot})>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Что исправить?'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Выберите только те historical results, которые точно '
                    'относятся к одному упражнению.',
                  ),
                  const SizedBox(height: 8),
                  for (final group in candidate.snapshotGroups)
                    CheckboxListTile(
                      key: ValueKey(
                        'legacy_snapshot_${candidate.clientId}_'
                        '${candidate.templateExerciseId}_${group.name}',
                      ),
                      contentPadding: EdgeInsets.zero,
                      value: group.resultIds.every(selected.contains),
                      title: Text(group.name),
                      subtitle: Text('Результатов: ${group.resultCount}'),
                      onChanged: (checked) => setDialogState(() {
                        if (checked ?? false) {
                          selected.addAll(group.resultIds);
                        } else {
                          selected.removeAll(group.resultIds);
                        }
                      }),
                    ),
                  const Divider(),
                  CheckboxListTile(
                    key: const Key('legacy_reassign_current_slot'),
                    contentPadding: EdgeInsets.zero,
                    value: currentSlot,
                    title: const Text('Перепривязать текущий slot'),
                    subtitle: const Text(
                      'Текстовый legacy override будет удалён',
                    ),
                    onChanged: (value) =>
                        setDialogState(() => currentSlot = value ?? false),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: selected.isEmpty && !currentSlot
                  ? null
                  : () => Navigator.pop(dialogContext, (
                      resultIds: Set<int>.of(selected),
                      currentSlot: currentSlot,
                    )),
              child: const Text('Выбрать упражнение'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _correct(LegacyExerciseBindingCandidateVm candidate) async {
    final scope = await _chooseScope(candidate);
    if (scope == null || !mounted) return;
    final db = AppDbScope.of(context);
    final target = await showExerciseSelector(
      context,
      database: db,
      allowCreate: false,
    );
    if (target == null || !mounted) return;

    try {
      final preview = await db.previewLegacyExerciseCorrection(
        clientId: candidate.clientId,
        templateExerciseId: candidate.templateExerciseId,
        historicalResultIds: scope.resultIds,
        targetExerciseIdentityId: target.id,
        reassignCurrentSlot: scope.currentSlot,
      );
      if (!mounted) return;
      final confirmed =
          await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Исправить legacy-привязку?'),
              content: SelectableText(
                'Будет изменено:\n'
                '• historical results: ${preview.historicalResults}\n'
                '• current slots: ${preview.currentSlots}\n\n'
                'В очередь будут поставлены тренировки: '
                '${preview.affectedSessions}\n\n'
                'Названия в истории изменены не будут.\n'
                'UUID будет заменён на:\n'
                '${preview.targetName}\n${preview.targetExternalId}',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Отмена'),
                ),
                FilledButton(
                  key: const Key('legacy_confirm_fix'),
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Исправить'),
                ),
              ],
            ),
          ) ??
          false;
      if (!confirmed) return;

      final result = await db.reassignLegacyExerciseData(
        clientId: candidate.clientId,
        templateExerciseId: candidate.templateExerciseId,
        historicalResultIds: scope.resultIds,
        targetExerciseIdentityId: target.id,
        reassignCurrentSlot: scope.currentSlot,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Исправлено results: ${result.changedHistoricalResults}, '
            'slots: ${result.changedCurrentSlots}. '
            'В очередь добавлено: ${result.requeuedWorkoutSessions}. '
            'Запустите синхронизацию вручную.',
          ),
        ),
      );
      _reload();
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Не удалось исправить: $error')));
    }
  }

  Widget _candidateCard(LegacyExerciseBindingCandidateVm candidate) {
    final colors = Theme.of(context).colorScheme;
    final kind = candidate.hasMixedIdentityHistory
        ? 'Mixed history — только точечная перепривязка'
        : candidate.isCleanCandidate
        ? 'Чистый кандидат на перепривязку'
        : 'Требуется ручная проверка';
    return Card(
      child: ExpansionTile(
        key: ValueKey(
          'legacy_candidate_${candidate.clientId}_'
          '${candidate.templateExerciseId}',
        ),
        title: Text(candidate.clientName),
        subtitle: Text('${candidate.programSlot}\n$kind'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Отображаемое имя: ${candidate.displayName}'),
          const SizedBox(height: 6),
          Text('Текущая identity: ${candidate.currentIdentityName}'),
          SelectableText(
            candidate.currentIdentityExternalId,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 8),
          Text('Historical results: ${candidate.historicalResultCount}'),
          if (candidate.snapshotGroups.isEmpty)
            const Text('Snapshots отсутствуют')
          else
            for (final group in candidate.snapshotGroups)
              Text('• ${group.name}: ${group.resultCount}'),
          if (candidate.hasMixedIdentityHistory) ...[
            const SizedBox(height: 8),
            Text(
              'Все snapshots этой identity: '
              '${candidate.identitySnapshotNames.join(', ')}',
              style: TextStyle(color: colors.error),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              key: ValueKey(
                'legacy_correct_${candidate.clientId}_'
                '${candidate.templateExerciseId}',
              ),
              onPressed: () => _correct(candidate),
              icon: const Icon(Icons.link),
              label: const Text('Исправить точечно'),
            ),
          ),
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
                'Здесь показаны legacy name overrides, имя которых не '
                'совпадает с текущим catalog exercise. Совпадение не '
                'исправляется автоматически.',
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
              if (audit.candidates.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 32),
                  child: Center(child: Text('Legacy-кандидаты не найдены')),
                )
              else
                for (final candidate in audit.candidates)
                  _candidateCard(candidate),
            ],
          );
        },
      ),
    );
  }
}
