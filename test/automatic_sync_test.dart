import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myfitness/db/app_db.dart';
import 'package:myfitness/sync/schedule_sync_payload.dart';
import 'package:myfitness/sync/sync_models.dart';
import 'package:myfitness/sync/sync_service.dart';
import 'package:myfitness/sync/sync_transport.dart';
import 'package:myfitness/sync/workout_sync_payload.dart';

void main() {
  group('automatic sync trigger', () {
    test('completed workout starts sync without blocking local save', () async {
      final fixture = await _createFixture();
      addTearDown(fixture.db.close);
      final transport = _ControlledTransport(1);
      final service = SyncService(db: fixture.db, transport: transport);
      fixture.db.configureAutomaticSyncTrigger(service.triggerAutomatic);

      await _saveCompletedResult(fixture, weight: 40, reps: 10);
      await transport.started[0].future;

      expect(
        await fixture.db.select(fixture.db.workoutSessions).get(),
        hasLength(1),
      );
      final inFlightTasks = await fixture.db.select(fixture.db.syncQueue).get();
      expect(inFlightTasks, hasLength(1));
      expect(inFlightTasks.single.status, SyncQueueStatuses.processing);
      expect(transport.completedRequests, 0);

      final joinedRun = service.syncPending();
      transport.responses[0].complete(
        const SyncTransportResult.success(httpStatus: 201),
      );
      final result = await joinedRun;

      expect(result.succeeded, 1);
      expect(await fixture.db.getPendingSyncTaskCount(), 0);
    });

    test('trial workout is saved locally but is not queued or sent', () async {
      final fixture = await _createTrialFixture();
      addTearDown(fixture.db.close);
      final transport = _RecordingTransport();
      final service = SyncService(db: fixture.db, transport: transport);
      fixture.db.configureAutomaticSyncTrigger(service.triggerAutomatic);

      await _saveCompletedResult(fixture, weight: 25, reps: 12);
      await _drainMicrotasks();

      expect(
        await fixture.db.select(fixture.db.workoutSessions).get(),
        hasLength(1),
      );
      expect(await fixture.db.select(fixture.db.syncQueue).get(), isEmpty);
      expect(transport.calls, isEmpty);
    });

    test('network failure keeps the workout and pending task', () async {
      final fixture = await _createFixture();
      addTearDown(fixture.db.close);
      final transport = _ControlledTransport(1);
      final service = SyncService(db: fixture.db, transport: transport);
      fixture.db.configureAutomaticSyncTrigger(service.triggerAutomatic);

      await _saveCompletedResult(fixture, weight: 40, reps: 10);
      await transport.started[0].future;
      final joinedRun = service.syncPending();
      transport.responses[0].complete(
        const SyncTransportResult.failure(
          message: 'offline',
          failureKind: SyncFailureKind.transient,
        ),
      );
      final result = await joinedRun;

      expect(result.stopReason, SyncRunStopReason.transientFailure);
      expect(result.succeeded, 0);
      expect(
        await fixture.db.select(fixture.db.workoutSessions).get(),
        hasLength(1),
      );
      final tasks = await fixture.db.select(fixture.db.syncQueue).get();
      expect(tasks, hasLength(1));
      expect(tasks.single.status, SyncQueueStatuses.pending);
      expect(tasks.single.attempts, 1);
    });

    test(
      'disabled transport leaves automatically queued work untouched',
      () async {
        final fixture = await _createFixture();
        addTearDown(fixture.db.close);
        final service = SyncService(
          db: fixture.db,
          transport: const DisabledSyncTransport(),
        );
        fixture.db.configureAutomaticSyncTrigger(service.triggerAutomatic);

        await _saveCompletedResult(fixture, weight: 40, reps: 10);
        await _drainMicrotasks();

        final tasks = await fixture.db.select(fixture.db.syncQueue).get();
        expect(tasks, hasLength(1));
        expect(tasks.single.status, SyncQueueStatuses.pending);
        expect(tasks.single.attempts, 0);
      },
    );

    test(
      'schedule add, move and delete each trigger current snapshot',
      () async {
        final fixture = await _createFixture();
        addTearDown(fixture.db.close);
        final transport = _ControlledTransport(3);
        final service = SyncService(db: fixture.db, transport: transport);
        fixture.db.configureAutomaticSyncTrigger(service.triggerAutomatic);
        final range = clientAppointmentsWeekRange(DateTime.now());
        final initial = range.fromInclusive.add(const Duration(hours: 11));

        await fixture.db.addAppointment(
          clientId: fixture.client.id,
          startAt: initial,
        );
        await transport.started[0].future;
        var joinedRun = service.syncPending();
        transport.responses[0].complete(
          const SyncTransportResult.success(httpStatus: 201),
        );
        await joinedRun;
        final appointment = await fixture.db
            .select(fixture.db.appointments)
            .getSingle();

        await fixture.db.updateAppointmentTime(
          id: appointment.id,
          newStartAt: initial.add(const Duration(hours: 2)),
        );
        await transport.started[1].future;
        joinedRun = service.syncPending();
        transport.responses[1].complete(
          const SyncTransportResult.success(httpStatus: 201),
        );
        await joinedRun;

        await fixture.db.deleteAppointmentById(appointment.id);
        await transport.started[2].future;
        joinedRun = service.syncPending();
        transport.responses[2].complete(
          const SyncTransportResult.success(httpStatus: 201),
        );
        await joinedRun;

        expect(transport.calls, ['schedule', 'schedule', 'schedule']);
        expect(_appointmentTimes(transport.schedulePayloads[0]), ['11:00']);
        expect(_appointmentTimes(transport.schedulePayloads[1]), ['13:00']);
        expect(_appointmentTimes(transport.schedulePayloads[2]), isEmpty);
        expect(await fixture.db.getPendingSyncTaskCount(), 0);
      },
    );

    test(
      'rapid schedule edits dedupe and refresh payload during send',
      () async {
        final fixture = await _createFixture();
        addTearDown(fixture.db.close);
        final transport = _ControlledTransport(2);
        final service = SyncService(db: fixture.db, transport: transport);
        fixture.db.configureAutomaticSyncTrigger(service.triggerAutomatic);
        final range = clientAppointmentsWeekRange(DateTime.now());
        final initial = range.fromInclusive.add(const Duration(hours: 10));

        await fixture.db.addAppointment(
          clientId: fixture.client.id,
          startAt: initial,
        );
        await transport.started[0].future;
        final appointment = await fixture.db
            .select(fixture.db.appointments)
            .getSingle();

        await fixture.db.updateAppointmentTime(
          id: appointment.id,
          newStartAt: initial.add(const Duration(hours: 1)),
        );
        await fixture.db.updateAppointmentTime(
          id: appointment.id,
          newStartAt: initial.add(const Duration(hours: 3)),
        );
        final joinedRun = service.syncPending();
        await _drainMicrotasks();

        expect(transport.calls, hasLength(1));
        expect(
          await fixture.db.select(fixture.db.syncQueue).get(),
          hasLength(1),
        );

        transport.responses[0].complete(
          const SyncTransportResult.success(httpStatus: 201),
        );
        await transport.started[1].future;
        expect(_appointmentTimes(transport.schedulePayloads[1]), ['13:00']);
        transport.responses[1].complete(
          const SyncTransportResult.success(httpStatus: 201),
        );
        await joinedRun;

        expect(transport.calls, ['schedule', 'schedule']);
        expect(await fixture.db.getPendingSyncTaskCount(), 0);
      },
    );

    test(
      'auto and manual requests share one strictly sequential runner',
      () async {
        final fixture = await _createFixture();
        addTearDown(fixture.db.close);
        final transport = _ControlledTransport(2);
        final service = SyncService(db: fixture.db, transport: transport);
        fixture.db.configureAutomaticSyncTrigger(service.triggerAutomatic);

        await _saveCompletedResult(fixture, weight: 40, reps: 10);
        await transport.started[0].future;
        final range = clientAppointmentsWeekRange(DateTime.now());
        await fixture.db.addAppointment(
          clientId: fixture.client.id,
          startAt: range.fromInclusive.add(const Duration(hours: 15)),
        );
        final manualProgress = <SyncProgress>[];
        final manualRun = service.syncPending(onProgress: manualProgress.add);
        await _drainMicrotasks();

        expect(transport.calls, hasLength(1));
        expect(manualProgress, isNotEmpty);
        expect(manualProgress.last.sent, 0);
        transport.responses[0].complete(
          const SyncTransportResult.success(httpStatus: 201),
        );
        await transport.started[1].future;
        expect(transport.completedRequests, 1);
        transport.responses[1].complete(
          const SyncTransportResult.success(httpStatus: 201),
        );
        final result = await manualRun;

        expect(result.succeeded, 2);
        expect(transport.calls, ['workout', 'schedule']);
        expect(manualProgress.last.sent, 2);
        expect(manualProgress.last.total, 2);
        expect(await fixture.db.getPendingSyncTaskCount(), 0);
      },
    );

    test(
      'queue rebuild never starts HTTP and manual run still sends it',
      () async {
        final database = AppDb.forTesting(NativeDatabase.memory());
        addTearDown(database.close);
        const historySize = 12;
        for (var index = 0; index < historySize; index++) {
          final fixture = await _createFixture(
            db: database,
            day: DateTime(2026, 8, 1 + index),
          );
          await _saveCompletedResult(
            fixture,
            weight: (40 + index).toDouble(),
            reps: 10,
          );
        }
        final transport = _RecordingTransport();
        final service = SyncService(db: database, transport: transport);
        database.configureAutomaticSyncTrigger(service.triggerAutomatic);

        final preview = await database.analyzeWorkoutSyncQueueRebuild();
        final rebuilt = await database.rebuildWorkoutSyncQueue(preview);
        await _drainMicrotasks();

        expect(rebuilt.createdTasks, historySize);
        expect(transport.calls, isEmpty);
        expect(await database.getPendingSyncTaskCount(), historySize);

        final result = await service.syncPending();

        expect(result.succeeded, historySize);
        expect(transport.calls, everyElement('workout'));
        expect(transport.calls, hasLength(historySize));
        expect(await database.getPendingSyncTaskCount(), 0);
      },
    );
  });
}

class _SyncFixture {
  const _SyncFixture({
    required this.db,
    required this.client,
    required this.template,
    required this.exercise,
    required this.day,
  });

  final AppDb db;
  final Client client;
  final WorkoutTemplate template;
  final WorkoutTemplateExercise exercise;
  final DateTime day;
}

Future<_SyncFixture> _createFixture({AppDb? db, DateTime? day}) async {
  final database = db ?? AppDb.forTesting(NativeDatabase.memory());
  final clientId = 'auto-client-${DateTime.now().microsecondsSinceEpoch}';
  await database.upsertClient(
    ClientsCompanion.insert(
      id: clientId,
      name: 'Клиент автосинхронизации',
      gender: const Value('М'),
      plan: const Value('4'),
      planStart: Value(DateTime(2026, 8, 17)),
      planEnd: Value(DateTime(2026, 9, 14)),
    ),
  );
  await database.ensureProgramStateForClient(clientId);
  final client = (await database.getClientById(clientId))!;
  final template = await (database.select(
    database.workoutTemplates,
  )..where((row) => row.gender.equals('М') & row.idx.equals(0))).getSingle();
  final exercise =
      await (database.select(database.workoutTemplateExercises)
            ..where((row) => row.templateId.equals(template.id))
            ..orderBy([(row) => OrderingTerm.asc(row.orderIndex)])
            ..limit(1))
          .getSingle();
  return _SyncFixture(
    db: database,
    client: client,
    template: template,
    exercise: exercise,
    day: day ?? DateTime(2026, 8, 5, 12),
  );
}

Future<_SyncFixture> _createTrialFixture() async {
  final database = AppDb.forTesting(NativeDatabase.memory());
  const clientId = 'auto-trial-client';
  await database.upsertClient(
    ClientsCompanion.insert(
      id: clientId,
      name: 'Пробный клиент',
      gender: const Value('М'),
      plan: const Value('Пробный'),
    ),
  );
  await database.ensureProgramStateForClient(clientId);
  final client = (await database.getClientById(clientId))!;
  final template = await (database.select(
    database.workoutTemplates,
  )..where((row) => row.gender.equals('П') & row.idx.equals(0))).getSingle();
  final exercise =
      await (database.select(database.workoutTemplateExercises)
            ..where((row) => row.templateId.equals(template.id))
            ..orderBy([(row) => OrderingTerm.asc(row.orderIndex)])
            ..limit(1))
          .getSingle();
  return _SyncFixture(
    db: database,
    client: client,
    template: template,
    exercise: exercise,
    day: DateTime(2026, 9, 1, 12),
  );
}

Future<void> _saveCompletedResult(
  _SyncFixture fixture, {
  required double weight,
  required int reps,
}) {
  return fixture.db.saveWorkoutResultsAndMarkDone(
    clientId: fixture.client.id,
    day: fixture.day,
    templateIdx: fixture.template.idx,
    resultsByTemplateExerciseId: {fixture.exercise.id: (weight, reps)},
  );
}

List<String> _appointmentTimes(ScheduleSyncPayload payload) {
  return payload.appointments.map((appointment) => appointment.time).toList();
}

Future<void> _drainMicrotasks() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

class _RecordingTransport implements SyncTransport {
  final List<String> calls = <String>[];

  @override
  bool get isConfigured => true;

  @override
  Future<SyncTransportResult> sendSchedule(ScheduleSyncPayload payload) async {
    calls.add('schedule');
    return const SyncTransportResult.success(httpStatus: 201);
  }

  @override
  Future<SyncTransportResult> sendWorkout(WorkoutSyncPayload payload) async {
    calls.add('workout');
    return const SyncTransportResult.success(httpStatus: 201);
  }
}

class _ControlledTransport implements SyncTransport {
  _ControlledTransport(int responseCount)
    : responses = List.generate(
        responseCount,
        (_) => Completer<SyncTransportResult>(),
      ),
      started = List.generate(responseCount, (_) => Completer<void>());

  final List<Completer<SyncTransportResult>> responses;
  final List<Completer<void>> started;
  final List<String> calls = <String>[];
  final List<WorkoutSyncPayload> workoutPayloads = <WorkoutSyncPayload>[];
  final List<ScheduleSyncPayload> schedulePayloads = <ScheduleSyncPayload>[];
  var completedRequests = 0;

  @override
  bool get isConfigured => true;

  @override
  Future<SyncTransportResult> sendSchedule(ScheduleSyncPayload payload) async {
    final index = calls.length;
    calls.add('schedule');
    schedulePayloads.add(payload);
    started[index].complete();
    final result = await responses[index].future;
    completedRequests += 1;
    return result;
  }

  @override
  Future<SyncTransportResult> sendWorkout(WorkoutSyncPayload payload) async {
    final index = calls.length;
    calls.add('workout');
    workoutPayloads.add(payload);
    started[index].complete();
    final result = await responses[index].future;
    completedRequests += 1;
    return result;
  }
}
