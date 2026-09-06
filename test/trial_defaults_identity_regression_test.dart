import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myfitness/db/app_db.dart';

const _knownTrialMerges =
    <
      ({
        int oldId,
        String oldUuid,
        int canonicalId,
        String canonicalUuid,
        String name,
        int bindingId,
        int sourceId,
      })
    >[
      (
        oldId: 627,
        oldUuid: '17fd2bca-2395-4d46-b679-7a5c350ecd41',
        canonicalId: 230,
        canonicalUuid: 'ca91d5b0-5a80-43ca-91f6-7b591086bbdd',
        name: 'Тяга верхнего блока параллельным хватом',
        bindingId: 654,
        sourceId: 2973,
      ),
      (
        oldId: 628,
        oldUuid: 'fc282a77-8268-4365-b49a-7ee3d52a8479',
        canonicalId: 558,
        canonicalUuid: '71276424-4268-4598-b30b-4b2f52dc2254',
        name: 'Тяга нижнего блока самолётным хватом',
        bindingId: 655,
        sourceId: 2974,
      ),
      (
        oldId: 629,
        oldUuid: '459b73bf-700e-490a-9e62-76412bccb8a7',
        canonicalId: 310,
        canonicalUuid: '7a3a762d-0dcf-4e12-8315-412a882f798d',
        name: 'Жим в хамере',
        bindingId: 656,
        sourceId: 2975,
      ),
      (
        oldId: 630,
        oldUuid: 'a2eb226e-c4a1-4b8f-94f2-c6102443ed52',
        canonicalId: 314,
        canonicalUuid: '7ef69ad0-3588-4a50-935e-6d4c11431fa0',
        name: 'Жим ногами',
        bindingId: 657,
        sourceId: 2976,
      ),
      (
        oldId: 631,
        oldUuid: '19b9b93b-50e5-488b-ba23-79debc1d1b96',
        canonicalId: 596,
        canonicalUuid: '966607d2-84a0-4d63-a66a-65f66e655695',
        name: 'Выпады на месте',
        bindingId: 658,
        sourceId: 2977,
      ),
    ];

void main() {
  test(
    'cold opens and repeated program loads keep trial slots stable',
    () async {
      final temp = await Directory.systemTemp.createTemp(
        'trener-trial-stable-',
      );
      addTearDown(() => temp.delete(recursive: true));
      final file = File('${temp.path}${Platform.pathSeparator}app.sqlite');

      var db = AppDb.forTesting(NativeDatabase(file));
      await db.getWorkoutTemplatesByGender('М');
      final initialSlotIds = await _trialSlotIds(db);
      final initialIdentityCount = await _count(db, 'exercise_identities');
      final initialOrphans = await _orphanTemplateBindings(db);
      expect(initialSlotIds, hasLength(5));
      await db.getWorkoutTemplatesByGender('Ж');
      await db.getWorkoutTemplatesByGender('М');
      expect(await _trialSlotIds(db), initialSlotIds);
      await db.close();

      for (var reopen = 0; reopen < 2; reopen++) {
        db = AppDb.forTesting(NativeDatabase(file));
        expect(await _count(db, 'exercise_identities'), initialIdentityCount);
        await db.getWorkoutTemplatesByGender('М');
        await db.getWorkoutTemplatesByGender('Ж');
        expect(await _trialSlotIds(db), initialSlotIds);
        expect(await _count(db, 'exercise_identities'), initialIdentityCount);
        expect(await _orphanTemplateBindings(db), initialOrphans);
        await db.close();
      }
    },
  );

  test('a removed surplus trial slot leaves no orphan binding', () async {
    final temp = await Directory.systemTemp.createTemp('trener-trial-extra-');
    addTearDown(() => temp.delete(recursive: true));
    final file = File('${temp.path}${Platform.pathSeparator}app.sqlite');
    var db = AppDb.forTesting(NativeDatabase(file));
    await db.getWorkoutTemplatesByGender('М');
    final trialTemplate = await (db.select(
      db.workoutTemplates,
    )..where((row) => row.gender.equals('П') & row.idx.equals(0))).getSingle();
    final exercise = (await db.getActiveExercises()).first;
    final extraSlotId = await db
        .into(db.workoutTemplateExercises)
        .insert(
          WorkoutTemplateExercisesCompanion.insert(
            templateId: trialTemplate.id,
            orderIndex: 5,
            name: exercise.canonicalName,
            exerciseIdentityId: Value(exercise.id),
          ),
        );
    await db.ensureExternalIdentities();
    expect(await _bindingIdentity(db, extraSlotId), exercise.id);
    await db.close();

    db = AppDb.forTesting(NativeDatabase(file));
    await db.getWorkoutTemplatesByGender('М');
    expect(
      await (db.select(
        db.workoutTemplateExercises,
      )..where((row) => row.id.equals(extraSlotId))).getSingleOrNull(),
      isNull,
    );
    expect(
      await (db.select(db.exerciseIdentityBindings)..where(
            (row) =>
                row.sourceType.equals('TEMPLATE') &
                row.sourceId.equals(extraSlotId),
          ))
          .get(),
      isEmpty,
    );
    await db.close();
  });

  test(
    'binding resolver prefers direct identity then unique exact name',
    () async {
      final db = AppDb.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final templateId = await db
          .into(db.workoutTemplates)
          .insert(
            WorkoutTemplatesCompanion.insert(
              gender: 'X',
              idx: 100,
              label: 'Test',
              title: 'Test',
            ),
          );

      final direct = (await db.getActiveExercises()).first;
      final directSlot = await db
          .into(db.workoutTemplateExercises)
          .insert(
            WorkoutTemplateExercisesCompanion.insert(
              templateId: templateId,
              orderIndex: 0,
              name: direct.canonicalName,
              exerciseIdentityId: Value(direct.id),
            ),
          );
      final beforeDirect = await _count(db, 'exercise_identities');
      await db.ensureExternalIdentities();
      expect(await _bindingIdentity(db, directSlot), direct.id);
      expect(await _count(db, 'exercise_identities'), beforeDirect);

      final exact = await db.createExercise('Точный тестовый жим');
      final exactSlot = await db
          .into(db.workoutTemplateExercises)
          .insert(
            WorkoutTemplateExercisesCompanion.insert(
              templateId: templateId,
              orderIndex: 1,
              name: '  ТОЧНЫЙ   ТЕСТОВЫЙ ЖИМ ',
            ),
          );
      final beforeExact = await _count(db, 'exercise_identities');
      await db.ensureExternalIdentities();
      expect(await _bindingIdentity(db, exactSlot), exact.id);
      expect(await _count(db, 'exercise_identities'), beforeExact);
    },
  );

  test(
    'ambiguous exact names are not bound to an arbitrary identity',
    () async {
      final db = AppDb.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      const normalized = 'неоднозначное тестовое упражнение';
      final first = await db
          .into(db.exerciseIdentities)
          .insert(
            ExerciseIdentitiesCompanion.insert(
              externalId: '81000000-0000-4000-8000-000000000001',
              canonicalName: const Value('Неоднозначное тестовое упражнение'),
              normalizedName: const Value(normalized),
            ),
          );
      final second = await db
          .into(db.exerciseIdentities)
          .insert(
            ExerciseIdentitiesCompanion.insert(
              externalId: '81000000-0000-4000-8000-000000000002',
              canonicalName: const Value('Неоднозначное тестовое упражнение'),
              normalizedName: const Value(normalized),
            ),
          );
      final templateId = await db
          .into(db.workoutTemplates)
          .insert(
            WorkoutTemplatesCompanion.insert(
              gender: 'X',
              idx: 101,
              label: 'Ambiguous',
              title: 'Ambiguous',
            ),
          );
      final slotId = await db
          .into(db.workoutTemplateExercises)
          .insert(
            WorkoutTemplateExercisesCompanion.insert(
              templateId: templateId,
              orderIndex: 0,
              name: 'Неоднозначное тестовое упражнение',
            ),
          );

      await db.ensureExternalIdentities();
      final resolved = await _bindingIdentity(db, slotId);
      expect(resolved, isNot(anyOf(first, second)));
    },
  );

  test(
    'restore with direct trial identities creates no duplicate wave',
    () async {
      final source = AppDb.forTesting(NativeDatabase.memory());
      await source.getWorkoutTemplatesByGender('М');
      final originalIds = await _trialSlotIds(source);
      final backup = await source.buildBackupPayload(
        appVersion: '1.15.7',
        buildNumber: '114',
      );
      backup['schemaVersion'] = 19;
      final tables = backup['tables'] as Map<String, dynamic>;
      final bindings = tables['exercise_identity_bindings'] as List<dynamic>;
      tables['exercise_identity_bindings'] = bindings
          .where(
            (row) =>
                row is! Map<String, dynamic> ||
                row['source_type'] != 'TEMPLATE' ||
                !originalIds.contains(row['source_id']),
          )
          .toList();
      final identityCount =
          (tables['exercise_identities'] as List<dynamic>).length;
      await source.close();

      final restored = AppDb.forTesting(NativeDatabase.memory());
      addTearDown(restored.close);
      await restored.importBackupPayload(backup);
      expect(await _count(restored, 'exercise_identities'), identityCount);
      await restored.getWorkoutTemplatesByGender('М');
      await restored.getWorkoutTemplatesByGender('Ж');
      expect(await _trialSlotIds(restored), originalIds);
      expect(await _count(restored, 'exercise_identities'), identityCount);
      await restored.importBackupPayload(backup);
      expect(await _trialSlotIds(restored), originalIds);
      expect(await _count(restored, 'exercise_identities'), identityCount);
    },
  );

  test(
    'schema 19 merges five known duplicates and cleans orphan bindings',
    () async {
      final temp = await Directory.systemTemp.createTemp('trener-trial-merge-');
      addTearDown(() => temp.delete(recursive: true));
      final file = File('${temp.path}${Platform.pathSeparator}app.sqlite');
      var db = AppDb.forTesting(NativeDatabase(file));
      final historicalResultId = await _seedKnownDuplicateFixture(db);
      final historicalBefore = await (db.select(
        db.workoutExerciseResults,
      )..where((row) => row.id.equals(historicalResultId))).getSingle();
      await db.customStatement('PRAGMA user_version = 19');
      await db.close();

      db = AppDb.forTesting(NativeDatabase(file));
      for (final pair in _knownTrialMerges) {
        final old = await (db.select(
          db.exerciseIdentities,
        )..where((row) => row.id.equals(pair.oldId))).getSingle();
        expect(old.status, AppDb.archivedExerciseStatus);
        expect(old.mergedIntoIdentityId, pair.canonicalId);
        expect(
          await db.resolveCanonicalExerciseUuid(pair.oldUuid),
          pair.canonicalUuid,
        );
        expect(
          await (db.select(
            db.exerciseIdentityBindings,
          )..where((row) => row.id.equals(pair.bindingId))).getSingleOrNull(),
          isNull,
        );
      }
      expect(
        await (db.select(
          db.workoutExerciseResults,
        )..where((row) => row.id.equals(historicalResultId))).getSingle(),
        historicalBefore,
      );
      await db.close();

      db = AppDb.forTesting(NativeDatabase(file));
      for (final pair in _knownTrialMerges) {
        expect(
          await db.resolveCanonicalExerciseUuid(pair.oldUuid),
          pair.canonicalUuid,
        );
      }
      await db.close();
    },
  );
}

Future<List<int>> _trialSlotIds(AppDb db) async {
  final rows = await db.customSelect('''
    SELECT e.id
    FROM workout_template_exercises e
    INNER JOIN workout_templates t ON t.id = e.template_id
    WHERE t.gender = 'П' AND t.idx = 0
    ORDER BY e.order_index
    ''').get();
  return [for (final row in rows) row.read<int>('id')];
}

Future<int> _bindingIdentity(AppDb db, int sourceId) async {
  final binding =
      await (db.select(db.exerciseIdentityBindings)..where(
            (row) =>
                row.clientId.isNull() &
                row.sourceType.equals('TEMPLATE') &
                row.sourceId.equals(sourceId) &
                row.isCurrent.equals(true),
          ))
          .getSingle();
  return binding.identityId;
}

Future<int> _count(AppDb db, String table) async {
  final row = await db
      .customSelect('SELECT COUNT(*) AS amount FROM $table')
      .getSingle();
  return row.read<int>('amount');
}

Future<int> _orphanTemplateBindings(AppDb db) async {
  final row = await db.customSelect('''
    SELECT COUNT(*) AS amount
    FROM exercise_identity_bindings b
    WHERE b.source_type = 'TEMPLATE'
      AND NOT EXISTS (
        SELECT 1 FROM workout_template_exercises e WHERE e.id = b.source_id
      )
    ''').getSingle();
  return row.read<int>('amount');
}

Future<int> _seedKnownDuplicateFixture(AppDb db) async {
  final defaultIdentity = (await db.getActiveExercises()).first;
  await db
      .into(db.clients)
      .insert(
        ClientsCompanion.insert(
          id: 'trial-fix-history-client',
          externalId: const Value('82000000-0000-4000-8000-000000000001'),
          name: 'History',
          gender: const Value('М'),
        ),
      );
  final sessionId = await db
      .into(db.workoutSessions)
      .insert(
        WorkoutSessionsCompanion.insert(
          externalId: const Value('82000000-0000-4000-8000-000000000002'),
          clientId: 'trial-fix-history-client',
          performedAt: DateTime(2026, 9, 1, 12),
          planInstance: 1,
          gender: 'М',
          templateIdx: 0,
        ),
      );
  final historicalResultId = await db
      .into(db.workoutExerciseResults)
      .insert(
        WorkoutExerciseResultsCompanion.insert(
          sessionId: sessionId,
          templateExerciseId: 1,
          exerciseIdentityId: Value(defaultIdentity.id),
          exerciseNameSnapshot: const Value('Исторический snapshot'),
          lastWeightKg: const Value(25),
          lastReps: const Value(8),
        ),
      );

  for (final pair in _knownTrialMerges) {
    await db
        .into(db.exerciseIdentities)
        .insert(
          ExerciseIdentitiesCompanion.insert(
            id: Value(pair.canonicalId),
            externalId: pair.canonicalUuid,
            canonicalName: Value(pair.name),
            normalizedName: Value(AppDb.normalizeExerciseName(pair.name)),
          ),
        );
    await db
        .into(db.exerciseIdentities)
        .insert(
          ExerciseIdentitiesCompanion.insert(
            id: Value(pair.oldId),
            externalId: pair.oldUuid,
            canonicalName: Value(pair.name),
            normalizedName: Value(AppDb.normalizeExerciseName(pair.name)),
          ),
        );
    await db
        .into(db.exerciseIdentityBindings)
        .insert(
          ExerciseIdentityBindingsCompanion.insert(
            id: Value(pair.bindingId),
            sourceType: 'TEMPLATE',
            sourceId: pair.sourceId,
            identityId: pair.oldId,
          ),
        );
  }
  return historicalResultId;
}
