import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myfitness/db/app_db.dart';
import 'package:myfitness/features/workouts/exercise_change_flow.dart';

void main() {
  group('exercise change flow', () {
    test('same exercise keeps UUID and historical identity', () async {
      final fixture = await _createExerciseFixture('same-client');
      addTearDown(fixture.db.close);

      await _saveResult(fixture, DateTime(2026, 8, 1), 50, 10);
      final uuidBefore = await fixture.db.getExerciseExternalId(
        clientId: fixture.clientId,
        templateExerciseId: fixture.exercise.id,
      );
      final resultBefore = await fixture.db
          .select(fixture.db.workoutExerciseResults)
          .getSingle();

      await applyClientExerciseNameChange(
        db: fixture.db,
        clientId: fixture.clientId,
        templateExerciseId: fixture.exercise.id,
        newName: 'Жим ногами в тренажёре',
        kind: ExerciseChangeKind.sameExercise,
      );

      final uuidAfter = await fixture.db.getExerciseExternalId(
        clientId: fixture.clientId,
        templateExerciseId: fixture.exercise.id,
      );
      final resultAfter = await fixture.db
          .select(fixture.db.workoutExerciseResults)
          .getSingle();
      expect(uuidAfter, uuidBefore);
      expect(resultAfter.exerciseIdentityId, resultBefore.exerciseIdentityId);
      expect(await _effectiveExerciseName(fixture), 'Жим ногами в тренажёре');
    });

    test(
      'new exercise gets a new UUID while old result stays intact',
      () async {
        final fixture = await _createExerciseFixture('replace-client');
        addTearDown(fixture.db.close);

        final oldName = fixture.exercise.name;
        await _saveResult(fixture, DateTime(2026, 8, 1), 70, 8);
        final oldResult = await fixture.db
            .select(fixture.db.workoutExerciseResults)
            .getSingle();
        final oldIdentity =
            await (fixture.db.select(
                  fixture.db.exerciseIdentities,
                )..where((row) => row.id.equals(oldResult.exerciseIdentityId!)))
                .getSingle();

        await applyClientExerciseNameChange(
          db: fixture.db,
          clientId: fixture.clientId,
          templateExerciseId: fixture.exercise.id,
          newName: 'Присед со штангой',
          kind: ExerciseChangeKind.newExercise,
        );

        final newUuid = await fixture.db.getExerciseExternalId(
          clientId: fixture.clientId,
          templateExerciseId: fixture.exercise.id,
        );
        expect(newUuid, isNot(oldIdentity.externalId));
        expect(oldResult.exerciseNameSnapshot, oldName);

        await _saveResult(fixture, DateTime(2026, 8, 2), 80, 6);
        final results = await (fixture.db.select(
          fixture.db.workoutExerciseResults,
        )..orderBy([(row) => OrderingTerm.asc(row.id)])).get();
        expect(results, hasLength(2));
        expect(results.first.exerciseIdentityId, oldResult.exerciseIdentityId);
        expect(results.first.exerciseNameSnapshot, oldName);
        expect(
          results.last.exerciseIdentityId,
          isNot(oldResult.exerciseIdentityId),
        );
        expect(results.last.exerciseNameSnapshot, 'Присед со штангой');

        final newIdentity =
            await (fixture.db.select(fixture.db.exerciseIdentities)..where(
                  (row) => row.id.equals(results.last.exerciseIdentityId!),
                ))
                .getSingle();
        expect(newIdentity.externalId, newUuid);
      },
    );

    test('cancel changes neither name nor UUID', () async {
      final fixture = await _createExerciseFixture('cancel-client');
      addTearDown(fixture.db.close);
      final uuidBefore = await fixture.db.getExerciseExternalId(
        clientId: fixture.clientId,
        templateExerciseId: fixture.exercise.id,
      );

      await applyClientExerciseNameChange(
        db: fixture.db,
        clientId: fixture.clientId,
        templateExerciseId: fixture.exercise.id,
        newName: 'Не должно сохраниться',
        kind: null,
      );

      expect(await _effectiveExerciseName(fixture), fixture.exercise.name);
      expect(
        await fixture.db.getExerciseExternalId(
          clientId: fixture.clientId,
          templateExerciseId: fixture.exercise.id,
        ),
        uuidBefore,
      );
    });

    test('template editor can replace the global exercise identity', () async {
      final fixture = await _createExerciseFixture('template-client');
      addTearDown(fixture.db.close);
      final uuidBefore = await fixture.db.getExerciseExternalId(
        clientId: fixture.clientId,
        templateExerciseId: fixture.exercise.id,
      );

      await applyTemplateExerciseNameChange(
        db: fixture.db,
        templateExerciseId: fixture.exercise.id,
        newName: 'Новое упражнение шаблона',
        kind: ExerciseChangeKind.newExercise,
      );

      final uuidAfter = await fixture.db.getExerciseExternalId(
        clientId: fixture.clientId,
        templateExerciseId: fixture.exercise.id,
      );
      expect(uuidAfter, isNot(uuidBefore));
      final exercise = await (fixture.db.select(
        fixture.db.workoutTemplateExercises,
      )..where((row) => row.id.equals(fixture.exercise.id))).getSingle();
      expect(exercise.name, 'Новое упражнение шаблона');
    });
  });

  testWidgets('exercise dialog returns both choices and cancel', (
    tester,
  ) async {
    ExerciseChangeKind? result;
    var completed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                result = await showExerciseChangeDialog(context);
                completed = true;
              },
              child: const Text('Изменить'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Изменить'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('То же упражнение'));
    await tester.pumpAndSettle();
    expect(result, ExerciseChangeKind.sameExercise);

    completed = false;
    await tester.tap(find.text('Изменить'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Новое упражнение'));
    await tester.pumpAndSettle();
    expect(result, ExerciseChangeKind.newExercise);

    result = ExerciseChangeKind.sameExercise;
    completed = false;
    await tester.tap(find.text('Изменить'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();
    expect(completed, isTrue);
    expect(result, isNull);
  });

  test(
    'archive filters active clients and preserves all linked data',
    () async {
      final fixture = await _createExerciseFixture('archive-client');
      var sourceOpen = true;
      addTearDown(() async {
        if (sourceOpen) await fixture.db.close();
      });
      final day = DateTime(2026, 8, 3, 12);
      await _saveResult(fixture, day, 45, 12);
      await fixture.db.addAppointment(
        clientId: fixture.clientId,
        startAt: day.add(const Duration(hours: 2)),
        note: 'Историческая запись',
      );
      final uuidBefore = (await fixture.db.getClientById(
        fixture.clientId,
      ))!.externalId;

      expect(await fixture.db.getAllClients(), hasLength(1));
      expect(await fixture.db.getArchivedClients(), isEmpty);
      await fixture.db.archiveClient(fixture.clientId);

      expect(await fixture.db.getAllClients(), isEmpty);
      expect(
        (await fixture.db.getArchivedClients()).single.id,
        fixture.clientId,
      );
      final archived = (await fixture.db.getClientById(fixture.clientId))!;
      expect(archived.status, AppDb.archivedClientStatus);
      expect(archived.externalId, uuidBefore);
      expect(
        await fixture.db.select(fixture.db.workoutSessions).get(),
        hasLength(1),
      );
      expect(
        await fixture.db.select(fixture.db.workoutExerciseResults).get(),
        hasLength(1),
      );
      expect(
        await fixture.db.select(fixture.db.appointments).get(),
        hasLength(1),
      );
      final historicalAppointments = await fixture.db
          .watchAppointmentsForDay(day)
          .first;
      expect(historicalAppointments.single.client.id, fixture.clientId);

      final backup = await fixture.db.buildBackupPayload();
      await fixture.db.restoreClient(fixture.clientId);
      expect((await fixture.db.getAllClients()).single.id, fixture.clientId);
      expect(await fixture.db.getArchivedClients(), isEmpty);
      expect(
        (await fixture.db.getClientById(fixture.clientId))!.externalId,
        uuidBefore,
      );
      await fixture.db.close();
      sourceOpen = false;

      final restored = AppDb.forTesting(NativeDatabase.memory());
      addTearDown(restored.close);
      await restored.importBackupPayload(backup);
      expect(await restored.getAllClients(), isEmpty);
      expect(
        (await restored.getArchivedClients()).single.externalId,
        uuidBefore,
      );
      expect(
        await restored.select(restored.workoutSessions).get(),
        hasLength(1),
      );
      expect(
        await restored.select(restored.workoutExerciseResults).get(),
        hasLength(1),
      );
      expect(await restored.select(restored.appointments).get(), hasLength(1));
    },
  );
}

class _ExerciseFixture {
  const _ExerciseFixture({
    required this.db,
    required this.clientId,
    required this.template,
    required this.exercise,
  });

  final AppDb db;
  final String clientId;
  final WorkoutTemplate template;
  final WorkoutTemplateExercise exercise;
}

Future<_ExerciseFixture> _createExerciseFixture(String clientId) async {
  final db = AppDb.forTesting(NativeDatabase.memory());
  await db.upsertClient(
    ClientsCompanion.insert(
      id: clientId,
      name: 'Тестовый клиент',
      gender: const Value('М'),
      plan: const Value('4'),
    ),
  );
  final template = await (db.select(
    db.workoutTemplates,
  )..where((row) => row.gender.equals('М') & row.idx.equals(0))).getSingle();
  final exercise =
      await (db.select(db.workoutTemplateExercises)
            ..where((row) => row.templateId.equals(template.id))
            ..orderBy([(row) => OrderingTerm.asc(row.orderIndex)])
            ..limit(1))
          .getSingle();
  return _ExerciseFixture(
    db: db,
    clientId: clientId,
    template: template,
    exercise: exercise,
  );
}

Future<void> _saveResult(
  _ExerciseFixture fixture,
  DateTime day,
  double weight,
  int reps,
) async {
  await fixture.db.completeWorkoutForClientWithTemplateIdx(
    clientId: fixture.clientId,
    when: DateTime(day.year, day.month, day.day, 12),
    templateIdx: fixture.template.idx,
  );
  await fixture.db.saveWorkoutResultsAndMarkDone(
    clientId: fixture.clientId,
    day: day,
    templateIdx: fixture.template.idx,
    resultsByTemplateExerciseId: {fixture.exercise.id: (weight, reps)},
  );
}

Future<String?> _effectiveExerciseName(_ExerciseFixture fixture) async {
  final row = await fixture.db
      .customSelect(
        '''
    SELECT COALESCE(o.custom_name, e.name) AS effective_name
    FROM workout_template_exercises e
    LEFT JOIN client_exercise_name_overrides o
      ON o.client_id = ? AND o.template_exercise_id = e.id
    WHERE e.id = ?
    ''',
        variables: [
          Variable.withString(fixture.clientId),
          Variable.withInt(fixture.exercise.id),
        ],
      )
      .getSingle();
  return row.readNullable<String>('effective_name');
}
