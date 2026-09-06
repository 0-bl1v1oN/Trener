part of 'app_db.dart';

class ExerciseDeletionResult {
  const ExerciseDeletionResult(this.deletedIds, this.blocked);
  final List<int> deletedIds;
  final Map<int, Map<String, int>> blocked;
  String get message => blocked.isEmpty
      ? 'Удалено упражнений: ${deletedIds.length}'
      : 'Удалено: ${deletedIds.length}. Сохранены записи с зависимостями: $blocked';
}

extension ExerciseIdentityLifecycle on AppDb {
  Future<void> _activateCurrentExercise(int id) async {
    await (update(exerciseIdentities)..where(
          (r) =>
              r.id.equals(id) &
              r.status.equals(AppDb.archivedExerciseStatus) &
              r.mergedIntoIdentityId.isNull(),
        ))
        .write(
          ExerciseIdentitiesCompanion(
            status: const Value(AppDb.activeExerciseStatus),
            archivedAt: const Value(null),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  /// Includes retained bindings, incoming aliases/merges and saved queue JSON.
  /// An outgoing UUID alias is independent of the deleted local row.
  Future<Map<String, int>> exerciseIdentityReferences(int id) async {
    await _ensureClientAddedExercisesTable();
    final identity = await getExerciseById(id);
    if (identity == null) return {};
    final refs = <String, int>{};
    const columns = {
      'workout_exercise_results': 'exercise_identity_id',
      'workout_template_exercises': 'exercise_identity_id',
      'client_added_exercises': 'exercise_identity_id',
      'client_template_exercise_overrides': 'exercise_identity_id',
      'exercise_identity_bindings': 'identity_id',
      'exercise_identity_aliases': 'canonical_identity_id',
      'exercise_identities': 'merged_into_identity_id',
    };
    for (final entry in columns.entries) {
      final row = await customSelect(
        'SELECT COUNT(*) AS n FROM ${entry.key} WHERE ${entry.value} = ?',
        variables: [Variable.withInt(id)],
      ).getSingle();
      if (row.read<int>('n') > 0) refs[entry.key] = row.read<int>('n');
    }
    final queued = await customSelect(
      'SELECT COUNT(*) AS n FROM sync_queue WHERE payload LIKE ?',
      variables: [Variable.withString('%${identity.externalId}%')],
    ).getSingle();
    if (queued.read<int>('n') > 0) refs['sync_queue'] = queued.read<int>('n');
    return refs;
  }

  Future<bool> canHardDeleteExerciseIdentity(int id) async =>
      (await exerciseIdentityReferences(id)).isEmpty;

  Future<bool> hardDeleteExerciseIdentityIfUnused(int id) =>
      transaction(() async {
        if (!await canHardDeleteExerciseIdentity(id)) return false;
        await (delete(exerciseIdentities)..where((r) => r.id.equals(id))).go();
        return true;
      });

  Future<void> _refreshReassignedWorkoutQueue(
    Set<int> sessions,
    Set<String> oldUuids,
  ) async {
    // Refresh only affected history and queued workouts that still carry an old UUID.
    // Upsert replaces an in-flight payload safely: conditional completion cannot
    // remove the newer task. No automatic HTTP trigger is issued here.
    for (final uuid in oldUuids) {
      final tasks = await (select(
        syncQueue,
      )..where((q) => q.payload.contains(uuid))).get();
      for (final task in tasks) {
        if (task.entityType != SyncEntityTypes.workout) continue;
        final session =
            await (select(workoutSessions)
                  ..where((w) => w.externalId.equals(task.entityExternalId)))
                .getSingleOrNull();
        if (session != null) sessions.add(session.id);
      }
    }
    for (final id in sessions) {
      final session = await (select(
        workoutSessions,
      )..where((r) => r.id.equals(id))).getSingleOrNull();
      if (session == null ||
          session.gender == 'П' ||
          session.externalId == null) {
        continue;
      }
      await _enqueueWorkoutSyncSafely(
        session.externalId,
        triggerAutoSync: false,
      );
    }
  }

  Future<bool> _isDeletedDefault(String name) async =>
      await (select(appSettings)..where(
            (s) => s.settingKey.equals(
              'deleted_exercise_default:${AppDb.normalizeExerciseName(name)}',
            ),
          ))
          .getSingleOrNull() !=
      null;

  Future<ExerciseDeletionResult> deleteExerciseIdentity(
    int id, {
    int? canonicalIdentityId,
  }) => transaction(() async {
    if (canonicalIdentityId != null) {
      return mergeExerciseIdentities(
        canonicalIdentityId: canonicalIdentityId,
        duplicateIdentityIds: [id],
      );
    }
    final exercise = await getExerciseById(id);
    if (exercise == null) return const ExerciseDeletionResult([], {});
    final refs = await exerciseIdentityReferences(id);
    const protected = {
      'workout_exercise_results',
      'exercise_identity_aliases',
      'exercise_identities',
      'sync_queue',
    };
    final blocked = Map<String, int>.fromEntries(
      refs.entries.where((r) => protected.contains(r.key)),
    );
    if (blocked.isNotEmpty) return ExerciseDeletionResult([], {id: blocked});

    await _ensureClientExerciseNameOverridesTable();
    await _ensureClientHiddenExercisesTable();
    final templates = await (select(
      workoutTemplateExercises,
    )..where((r) => r.exerciseIdentityId.equals(id))).get();
    final added = await customSelect(
      'SELECT id, client_id FROM client_added_exercises WHERE exercise_identity_id = ?',
      variables: [Variable.withInt(id)],
    ).get();
    for (final slot in templates) {
      final differentOverrides =
          await (select(clientTemplateExerciseOverrides)..where(
                (r) =>
                    r.templateExerciseId.equals(slot.id) &
                    r.exerciseIdentityId.isNotNull() &
                    r.exerciseIdentityId.equals(id).not(),
              ))
              .get();
      final differentBindings =
          await (select(exerciseIdentityBindings)..where(
                (b) =>
                    b.sourceType.equals(AppDb._templateExerciseSource) &
                    b.sourceId.equals(slot.id) &
                    b.identityId.equals(id).not() &
                    b.isCurrent.equals(true),
              ))
              .get();
      if (differentOverrides.isNotEmpty || differentBindings.isNotEmpty) {
        return ExerciseDeletionResult([], {
          id: {
            'current_slot_other_exercises':
                differentOverrides.length + differentBindings.length,
          },
        });
      }
    }
    for (final slot in templates) {
      // Persist user deletion so trial/default repair cannot recreate the exercise.
      await into(appSettings).insertOnConflictUpdate(
        AppSettingsCompanion.insert(
          settingKey:
              'deleted_exercise_default:${AppDb.normalizeExerciseName(slot.name)}',
          settingValue: '1',
        ),
      );
      await _clearDeletedSlotReferences(slot.id);
      await (delete(
        workoutTemplateExercises,
      )..where((r) => r.id.equals(slot.id))).go();
    }
    for (final slot in added) {
      await _clearDeletedSlotReferences(
        -slot.read<int>('id'),
        clientId: slot.read<String>('client_id'),
      );
      await customStatement('DELETE FROM client_added_exercises WHERE id = ?', [
        slot.read<int>('id'),
      ]);
    }
    final overrides = await (select(
      clientTemplateExerciseOverrides,
    )..where((r) => r.exerciseIdentityId.equals(id))).get();
    for (final override in overrides) {
      await customStatement(
        'DELETE FROM client_exercise_name_overrides WHERE client_id = ? AND template_exercise_id = ?',
        [override.clientId, override.templateExerciseId],
      );
    }
    await (update(
      clientTemplateExerciseOverrides,
    )..where((r) => r.exerciseIdentityId.equals(id))).write(
      const ClientTemplateExerciseOverridesCompanion(
        exerciseIdentityId: Value(null),
      ),
    );
    await (delete(
      exerciseIdentityBindings,
    )..where((r) => r.identityId.equals(id))).go();
    if (!await hardDeleteExerciseIdentityIfUnused(id)) {
      throw StateError('Остались зависимости упражнения; удаление отменено');
    }
    return ExerciseDeletionResult([id], {});
  });

  Future<void> _clearDeletedSlotReferences(
    int slotId, {
    String? clientId,
  }) async {
    for (final table in [
      'client_template_exercise_overrides',
      'client_exercise_name_overrides',
      'client_hidden_exercises',
      'workout_drafts',
    ]) {
      await customStatement(
        'DELETE FROM $table WHERE template_exercise_id = ?${clientId == null ? '' : ' AND client_id = ?'}',
        [slotId, if (clientId != null) clientId],
      );
    }
    await (delete(exerciseIdentityBindings)..where(
          (b) =>
              b.sourceType.equals(
                slotId < 0
                    ? AppDb._clientAddedExerciseSource
                    : AppDb._templateExerciseSource,
              ) &
              b.sourceId.equals(slotId.abs()) &
              (clientId == null
                  ? const Constant(true)
                  : b.clientId.equals(clientId)),
        ))
        .go();
  }

  Future<void> _repairArchivedBindingDuplicates() async {
    await _ensureClientAddedExercisesTable();
    const known = {
      637: '2eff57c9-a44a-4f00-927a-9b826412911c',
      638: '9be960ad-86e3-4013-bdce-73f8848f3908',
      639: 'ece27192-46d2-4592-900c-b97f34aaf8e1',
      640: 'f5ebe491-144c-464a-9c1d-b4073a159828',
      641: '6125e19d-10be-488d-bb9f-b581fb13b54e',
      642: '4989850a-e34f-4741-bdc0-15396ecbdc09',
      643: 'cd68b728-44f6-4f78-b581-9075409bb4e0',
      644: '61c107cd-7d9f-45ff-a3b4-46d4b3014fd9',
      645: '641a04e2-4008-46cd-984c-2ec7b38510bc',
      646: 'be272170-972b-4783-b550-93550e2c2588',
      647: 'f8015e43-411c-4ed9-8f0e-b0fa2b259eda',
      648: '7beb9bf8-8b0e-4755-bb5c-58c7cfbf6576',
      649: 'b9331b0d-39f7-4c00-a747-30b59e818752',
      650: 'f0d74e59-9a5b-4a61-a167-5dc9e2ab8fd5',
    };
    for (final pair in known.entries) {
      final duplicate = await getExerciseById(pair.key);
      if (duplicate == null ||
          duplicate.externalId != pair.value ||
          duplicate.mergedIntoIdentityId != null) {
        continue;
      }
      final refs = await exerciseIdentityReferences(duplicate.id);
      if (refs.keys.any((key) => key != 'exercise_identity_bindings')) continue;
      final bindings = await (select(
        exerciseIdentityBindings,
      )..where((b) => b.identityId.equals(duplicate.id))).get();
      if (bindings.isEmpty) continue;
      final targets = <int>{};
      var valid = true;
      for (final binding in bindings) {
        final table = binding.sourceType == AppDb._templateExerciseSource
            ? 'workout_template_exercises'
            : binding.sourceType == AppDb._clientAddedExerciseSource
            ? 'client_added_exercises'
            : null;
        if (table == null) {
          valid = false;
          break;
        }
        final slot = await customSelect(
          'SELECT exercise_identity_id, name FROM $table WHERE id = ?${table == 'client_added_exercises' ? ' AND client_id = ?' : ''}',
          variables: [
            Variable.withInt(binding.sourceId),
            if (table == 'client_added_exercises')
              Variable.withString(binding.clientId ?? ''),
          ],
        ).getSingleOrNull();
        final targetId = slot?.readNullable<int>('exercise_identity_id');
        final target = targetId == null
            ? null
            : await getExerciseById(targetId);
        if (target == null ||
            target.id == duplicate.id ||
            target.mergedIntoIdentityId != null ||
            target.normalizedName != duplicate.normalizedName ||
            AppDb.normalizeExerciseName(slot!.read<String>('name')) !=
                target.normalizedName) {
          valid = false;
          break;
        }
        targets.add(target.id);
      }
      if (!valid || targets.length != 1) continue;
      await _activateCurrentExercise(targets.single);
      await mergeExerciseIdentities(
        canonicalIdentityId: targets.single,
        duplicateIdentityIds: [duplicate.id],
      );
    }
  }
}
