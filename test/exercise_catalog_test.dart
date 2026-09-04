import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myfitness/db/app_db.dart';

void main() {
  Future<AppDb> openDb() async {
    final db = AppDb.forTesting(NativeDatabase.memory());
    await db.getActiveExercises();
    addTearDown(db.close);
    return db;
  }

  test('catalog creates one UUID for normalized duplicate names', () async {
    final db = await openDb();

    final first = await db.createExercise('  Гиперэкстензия  ');
    final second = await db.createExercise('ГИПЕРЭКСТЕНЗИЯ');

    expect(second.id, first.id);
    expect(second.externalId, first.externalId);
    expect(first.normalizedName, 'гиперэкстензия');
  });

  test('rename, archive and restore preserve catalog UUID', () async {
    final db = await openDb();
    final exercise = await db.createExercise('Тяга для каталога');

    await db.renameExercise(
      exerciseId: exercise.id,
      name: 'Тяга каталога новая',
    );
    final renamed = (await db.getExerciseById(exercise.id))!;
    expect(renamed.externalId, exercise.externalId);
    expect(renamed.canonicalName, 'Тяга каталога новая');

    await db.archiveExercise(exercise.id);
    expect(
      (await db.getExerciseById(exercise.id))!.externalId,
      exercise.externalId,
    );
    expect(await db.searchExercises('Тяга каталога новая'), isEmpty);

    await db.restoreExercise(exercise.id);
    final restored = (await db.getExerciseById(exercise.id))!;
    expect(restored.externalId, exercise.externalId);
    expect(restored.status, AppDb.activeExerciseStatus);
  });

  test('active catalog rejects normalized name conflicts', () async {
    final db = await openDb();
    final first = await db.createExercise('Уникальное упражнение A');
    final second = await db.createExercise('Уникальное упражнение B');

    await expectLater(
      db.renameExercise(
        exerciseId: second.id,
        name: ' уникальное  УПРАЖНЕНИЕ a ',
      ),
      throwsStateError,
    );
    expect((await db.getExerciseById(first.id))!.externalId, first.externalId);
  });

  test(
    'legacy duplicate catalog rows stay separate and orphan gets a name',
    () async {
      final db = await openDb();
      final firstId = await db
          .into(db.exerciseIdentities)
          .insert(
            ExerciseIdentitiesCompanion.insert(
              externalId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
              canonicalName: const Value('Гиперэкстензия'),
              normalizedName: const Value('гиперэкстензия'),
            ),
          );
      final secondId = await db
          .into(db.exerciseIdentities)
          .insert(
            ExerciseIdentitiesCompanion.insert(
              externalId: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
              canonicalName: const Value('Гиперэкстензия'),
              normalizedName: const Value('гиперэкстензия'),
            ),
          );
      final orphanId = await db
          .into(db.exerciseIdentities)
          .insert(
            ExerciseIdentitiesCompanion.insert(
              externalId: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
            ),
          );

      await db.ensureExternalIdentities();

      expect(
        (await db.getExerciseById(firstId))!.externalId,
        'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      );
      expect(
        (await db.getExerciseById(secondId))!.externalId,
        'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
      );
      expect(
        (await db.getExerciseById(orphanId))!.canonicalName,
        contains('Неизвестное упражнение'),
      );
    },
  );

  test(
    'template and client-added slots reuse selected catalog identity',
    () async {
      final db = await openDb();
      final selected = await db.createExercise('Каталожное упражнение');
      final templates = await db.getWorkoutTemplatesByGender('М');
      final template = templates.first;

      await db.addWorkoutTemplateExercise(
        templateId: template.id,
        exerciseIdentityId: selected.id,
      );
      await db.addWorkoutTemplateExercise(
        templateId: template.id,
        exerciseIdentityId: selected.id,
      );
      final slots =
          await (db.select(db.workoutTemplateExercises)..where(
                (row) =>
                    row.templateId.equals(template.id) &
                    row.name.equals(selected.canonicalName),
              ))
              .get();
      expect(slots, hasLength(2));
      expect(slots.map((row) => row.exerciseIdentityId).toSet(), {selected.id});

      await db
          .into(db.clients)
          .insert(
            ClientsCompanion.insert(
              id: 'catalog-client',
              name: 'Клиент каталога',
              externalId: const Value('11111111-1111-4111-8111-111111111111'),
            ),
          );
      await db.addWorkoutExerciseForClient(
        clientId: 'catalog-client',
        templateId: template.id,
        exerciseIdentityId: selected.id,
      );
      final added = await db.customSelect('''
      SELECT exercise_identity_id FROM client_added_exercises
      WHERE client_id = 'catalog-client'
    ''').getSingle();
      expect(added.read<int>('exercise_identity_id'), selected.id);
    },
  );

  test(
    'renaming or archiving a catalog exercise does not rewrite historical results',
    () async {
      final db = await openDb();
      final exercise = await db.createExercise('Историческое упражнение');
      final resultId = await db
          .into(db.workoutExerciseResults)
          .insert(
            WorkoutExerciseResultsCompanion.insert(
              sessionId: 99,
              templateExerciseId: 99,
              exerciseIdentityId: Value(exercise.id),
              exerciseNameSnapshot: const Value('Историческое упражнение'),
            ),
          );

      await db.renameExercise(
        exerciseId: exercise.id,
        name: 'Новое имя в каталоге',
      );
      await db.archiveExercise(exercise.id);

      final result = await (db.select(
        db.workoutExerciseResults,
      )..where((row) => row.id.equals(resultId))).getSingle();
      expect(result.exerciseIdentityId, exercise.id);
      expect(result.exerciseNameSnapshot, 'Историческое упражнение');
    },
  );

  test(
    'deleting a program slot does not delete historical workout results',
    () async {
      final db = await openDb();
      final template = (await db.getWorkoutTemplatesByGender('М')).first;
      final slot =
          (await (db.select(db.workoutTemplateExercises)
                ..where((row) => row.templateId.equals(template.id))
                ..limit(1))
              .getSingle());
      await db
          .into(db.clients)
          .insert(
            ClientsCompanion.insert(
              id: 'history-client',
              name: 'История',
              externalId: const Value('22222222-2222-4222-8222-222222222222'),
            ),
          );
      final sessionId = await db
          .into(db.workoutSessions)
          .insert(
            WorkoutSessionsCompanion.insert(
              clientId: 'history-client',
              performedAt: DateTime(2026, 9, 1),
              planInstance: 1,
              gender: 'М',
              templateIdx: template.idx,
              externalId: const Value('33333333-3333-4333-8333-333333333333'),
            ),
          );
      await db
          .into(db.workoutExerciseResults)
          .insert(
            WorkoutExerciseResultsCompanion.insert(
              sessionId: sessionId,
              templateExerciseId: slot.id,
              exerciseIdentityId: Value(slot.exerciseIdentityId),
              exerciseNameSnapshot: Value(slot.name),
            ),
          );

      await db.deleteWorkoutTemplateExercise(slot.id);

      expect(
        await (db.select(
          db.workoutExerciseResults,
        )..where((row) => row.sessionId.equals(sessionId))).get(),
        hasLength(1),
      );
    },
  );

  test('backup round-trip keeps catalog fields and UUID', () async {
    final db = await openDb();
    final exercise = await db.createExercise('Для backup');
    await db.archiveExercise(exercise.id);
    final backup = await db.buildBackupPayload(
      appVersion: '1.11.0',
      buildNumber: '103',
    );

    final restored = AppDb.forTesting(NativeDatabase.memory());
    addTearDown(restored.close);
    await restored.importBackupPayload(backup);
    final copied = await restored.getExerciseById(exercise.id);

    expect(copied!.externalId, exercise.externalId);
    expect(copied.canonicalName, 'Для backup');
    expect(copied.status, AppDb.archivedExerciseStatus);
  });
}
