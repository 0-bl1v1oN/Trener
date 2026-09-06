import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myfitness/db/app_db.dart';

Future<int> count(AppDb db, String table) async =>
    (await db.customSelect('SELECT COUNT(*) n FROM $table').getSingle())
        .read<int>('n');
Future<int> orphans(AppDb db) async =>
    (await db
            .customSelect(
              "SELECT COUNT(*) n FROM exercise_identity_bindings b WHERE (source_type = 'TEMPLATE' AND NOT EXISTS (SELECT 1 FROM workout_template_exercises s WHERE s.id = b.source_id)) OR (source_type = 'CLIENT_ADDED' AND NOT EXISTS (SELECT 1 FROM client_added_exercises s WHERE s.id = b.source_id AND s.client_id = b.client_id))",
            )
            .getSingle())
        .read<int>('n');
Future<int> slot(AppDb db, ExerciseIdentity identity, {String? name}) async {
  final template = (await db.getWorkoutTemplatesByGender('М')).first;
  return db
      .into(db.workoutTemplateExercises)
      .insert(
        WorkoutTemplateExercisesCompanion.insert(
          templateId: template.id,
          orderIndex: 1000 + identity.id,
          name: name ?? identity.canonicalName,
          exerciseIdentityId: Value(identity.id),
        ),
      );
}

void main() {
  test(
    'archived direct reactivates; merged direct canonicalizes; no new UUID',
    () async {
      final db = AppDb.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final old = await db.createExercise('Lifecycle source');
      final target = await db.createExercise('Lifecycle target');
      final sid = await slot(db, old);
      await db.archiveExercise(old.id);
      final before = await count(db, 'exercise_identities');
      await db.ensureExternalIdentities();
      expect(
        (await db.getExerciseById(old.id))!.status,
        AppDb.activeExerciseStatus,
      );
      await db.customStatement(
        'UPDATE exercise_identities SET merged_into_identity_id = ?, status = ? WHERE id = ?',
        [target.id, 'ARCHIVED', old.id],
      );
      await db.ensureExternalIdentities();
      expect(
        (await (db.select(
          db.workoutTemplateExercises,
        )..where((s) => s.id.equals(sid))).getSingle()).exerciseIdentityId,
        target.id,
      );
      await db.ensureExternalIdentities();
      expect(await count(db, 'exercise_identities'), before);
    },
  );

  test(
    'hard delete unused and current-only references; default stays deleted after reopen',
    () async {
      final temp = await Directory.systemTemp.createTemp('identity-delete-');
      final file = File('${temp.path}/test.sqlite');
      var db = AppDb.forTesting(NativeDatabase(file));
      addTearDown(() async {
        await db.close();
        await temp.delete(recursive: true);
      });
      final unused = await db.createExercise('Delete unused');
      expect(await db.canHardDeleteExerciseIdentity(unused.id), isTrue);
      expect(await db.hardDeleteExerciseIdentityIfUnused(unused.id), isTrue);
      await db.getWorkoutTemplatesByGender('П');
      final trial = await db
          .customSelect(
            "SELECT e.id, e.exercise_identity_id FROM workout_template_exercises e JOIN workout_templates t ON t.id = e.template_id WHERE t.gender = 'П' ORDER BY e.order_index LIMIT 1",
          )
          .getSingle();
      final id = trial.read<int>('exercise_identity_id');
      final exercise = (await db.getExerciseById(id))!;
      expect((await db.deleteExerciseIdentity(id)).deletedIds, [id]);
      final before = await count(db, 'exercise_identities');
      await db.close();
      for (var i = 0; i < 2; i++) {
        db = AppDb.forTesting(NativeDatabase(file));
        await db.getWorkoutTemplatesByGender('П');
        expect(await count(db, 'exercise_identities'), before);
        expect(await db.getExerciseById(id), isNull);
        expect(
          await (db.select(
                db.exerciseIdentities,
              )..where((e) => e.normalizedName.equals(exercise.normalizedName)))
              .get(),
          isEmpty,
        );
        if (i == 0) await db.close();
      }
    },
  );

  test(
    'history blocks deletion without target; repoint preserves snapshot and alias',
    () async {
      final db = AppDb.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final old = await db.createExercise('Delete history');
      final target = await db.createExercise('History target');
      final sid = await slot(db, old);
      await db
          .into(db.clients)
          .insert(
            ClientsCompanion.insert(
              id: 'lifecycle',
              name: 'Test',
              externalId: const Value('10000000-0000-4000-8000-000000000001'),
            ),
          );
      final session = await db
          .into(db.workoutSessions)
          .insert(
            WorkoutSessionsCompanion.insert(
              clientId: 'lifecycle',
              performedAt: DateTime(2026, 9, 1),
              planInstance: 1,
              gender: 'М',
              templateIdx: 0,
              externalId: const Value('10000000-0000-4000-8000-000000000002'),
            ),
          );
      await db
          .into(db.workoutExerciseResults)
          .insert(
            WorkoutExerciseResultsCompanion.insert(
              sessionId: session,
              templateExerciseId: sid,
              exerciseIdentityId: Value(old.id),
              exerciseNameSnapshot: const Value('Historical unchanged'),
              lastWeightKg: const Value(12),
              lastReps: const Value(8),
            ),
          );
      expect(
        (await db.deleteExerciseIdentity(old.id)).blocked,
        contains(old.id),
      );
      expect(await db.getExerciseById(old.id), isNotNull);
      final result = await db.deleteExerciseIdentity(
        old.id,
        canonicalIdentityId: target.id,
      );
      expect(result.deletedIds, [old.id]);
      final history = await db.select(db.workoutExerciseResults).getSingle();
      expect(history.exerciseIdentityId, target.id);
      expect(history.exerciseNameSnapshot, 'Historical unchanged');
      expect(history.lastWeightKg, 12);
      expect(history.lastReps, 8);
      expect(
        await db.resolveCanonicalExerciseUuid(old.externalId),
        target.externalId,
      );
      expect(await db.canHardDeleteExerciseIdentity(target.id), isFalse);
    },
  );

  final backupPath = Platform.environment['TRENER_AUDIT_BACKUP'];
  test(
    'fresh phone backup repairs 637-650, preserves history, cold opens and restore',
    () async {
      final backup =
          jsonDecode(await File(backupPath!).readAsString())
              as Map<String, dynamic>;
      final tables = backup['tables'] as Map<String, dynamic>;
      final temp = await Directory.systemTemp.createTemp('identity-phone-');
      final file = File('${temp.path}/test.sqlite');
      var db = AppDb.forTesting(NativeDatabase(file));
      addTearDown(() async {
        await db.close();
        await temp.delete(recursive: true);
      });
      await db.importBackupPayload(backup);
      final beforeHistory =
          (tables['workout_exercise_results'] as List).cast<Map>().toList()
            ..sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));
      final restored = await db.buildBackupPayload(
        appVersion: 'test',
        buildNumber: 'test',
      );
      final afterHistory =
          ((restored['tables'] as Map)['workout_exercise_results'] as List)
              .cast<Map>()
              .toList()
            ..sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));
      expect(afterHistory, beforeHistory);
      const targets = [
        246,
        317,
        318,
        319,
        345,
        357,
        375,
        367,
        368,
        392,
        403,
        414,
        312,
        452,
      ];
      for (var i = 0; i < 14; i++) {
        final old = (tables['exercise_identities'] as List)
            .cast<Map>()
            .singleWhere((e) => e['id'] == 637 + i);
        expect(await db.getExerciseById(637 + i), isNull);
        final target = (await db.getExerciseById(targets[i]))!;
        expect(target.status, AppDb.activeExerciseStatus);
        expect(
          await db.resolveCanonicalExerciseUuid(old['external_id'] as String),
          target.externalId,
        );
      }
      final beforeCount = await count(db, 'exercise_identities');
      final beforeOrphans = await orphans(db);
      for (var i = 0; i < 2; i++) {
        await db.close();
        db = AppDb.forTesting(NativeDatabase(file));
        await db.getWorkoutTemplatesByGender('П');
        expect(await count(db, 'exercise_identities'), beforeCount);
        expect(await orphans(db), beforeOrphans);
      }
      final duplicateGroups = await db
          .customSelect(
            "SELECT normalized_name, COUNT(*) n FROM exercise_identities WHERE status='ACTIVE' AND merged_into_identity_id IS NULL GROUP BY normalized_name HAVING COUNT(*) > 1",
          )
          .get();
      expect(duplicateGroups, isEmpty);
      await db.importBackupPayload(restored);
      expect(await count(db, 'exercise_identities'), beforeCount);
    },
    skip: backupPath == null
        ? 'Set TRENER_AUDIT_BACKUP to audit an external backup read-only'
        : false,
  );
}
