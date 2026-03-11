import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_db.g.dart';

class Clients extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  TextColumn get gender => text().nullable()(); // 'М', 'Ж', 'Не указано'
  TextColumn get plan => text().nullable()(); // 'Пробный', '4', '8', '12'
  DateTimeColumn get planStart => dateTime().nullable()();
  DateTimeColumn get planEnd => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Appointments extends Table {
  TextColumn get id => text()(); // uuid/строка
  TextColumn get clientId => text()();
  DateTimeColumn get startAt => dateTime()(); // дата+время
  TextColumn get note => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class WorkoutTemplates extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get gender => text()(); // 'М' или 'Ж'
  IntColumn get idx => integer()(); // 0..8

  TextColumn get label => text()(); // для тренера: "Спина", "Грудь", ...
  TextColumn get title => text()(); // название тренировки (уникальное для тебя)
  TextColumn get payloadJson => text().nullable()(); // позже упражнения

  @override
  List<Set<Column>> get uniqueKeys => [
    {gender, idx},
  ];
}

class ClientProgramStates extends Table {
  TextColumn get clientId => text()();

  IntColumn get planSize => integer()(); // 4/8/12 (пробный будем считать 1)
  IntColumn get planInstance => integer().withDefault(const Constant(1))();

  IntColumn get completedInPlan => integer().withDefault(const Constant(0))();
  IntColumn get cycleStartIndex =>
      integer().withDefault(const Constant(0))(); // 0..8
  IntColumn get nextOffset =>
      integer().withDefault(const Constant(0))(); // 0..8
  // Для абонемента 4: “окно” из 8-дневной программы.
  // 0 = показываем дни 1-4, 4 = показываем дни 5-8
  IntColumn get windowStart => integer().withDefault(const Constant(0))();

  // чтобы корректно “перезапускать” абонемент при изменении дат в карточке клиента
  DateTimeColumn get planStart => dateTime().nullable()();
  DateTimeColumn get planEnd => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {clientId};
}

class ClientTemplateExerciseOverrides extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get clientId => text()();

  IntColumn get templateExerciseId => integer()();

  // группа суперсета для КОНКРЕТНОГО клиента (null = не суперсет)
  IntColumn get supersetGroup => integer().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {clientId, templateExerciseId},
  ];
}

class WorkoutSessions extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get clientId => text()();
  DateTimeColumn get performedAt => dateTime()();

  IntColumn get planInstance => integer()();

  TextColumn get gender => text()(); // 'М'/'Ж' на момент выполнения
  IntColumn get templateIdx => integer()(); // 0..8
}

class WorkoutTemplateExercises extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get templateId => integer()(); // -> WorkoutTemplates.id
  IntColumn get orderIndex => integer()(); // порядок в тренировке

  // если 2 упражнения суперсет — у них одинаковый groupId (например 1),
  // и они идут подряд по orderIndex
  IntColumn get groupId => integer().nullable()();

  TextColumn get name => text()(); // название упражнения

  @override
  List<Set<Column>> get uniqueKeys => [
    {templateId, orderIndex},
  ];
}

class WorkoutExerciseResults extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get sessionId => integer()(); // -> WorkoutSessions.id
  IntColumn get templateExerciseId =>
      integer()(); // -> WorkoutTemplateExercises.id

  RealColumn get lastWeightKg => real().nullable()();
  IntColumn get lastReps => integer().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {sessionId, templateExerciseId},
  ];
}

class WorkoutDrafts extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get clientId => text()();
  DateTimeColumn get day => dateTime()();
  IntColumn get templateIdx => integer().withDefault(const Constant(-1))();
  IntColumn get templateExerciseId => integer()();

  RealColumn get lastWeightKg => real().nullable()();
  IntColumn get lastReps => integer().nullable()();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {clientId, day, templateIdx, templateExerciseId},
  ];
}

class AppointmentWithClient {
  final Appointment appointment;
  final Client client;
  AppointmentWithClient(this.appointment, this.client);
}

class PaymentReminderWithClient {
  final Client client;
  final DateTime remindOn;
  final String? note;

  PaymentReminderWithClient({
    required this.client,
    required this.remindOn,
    this.note,
  });
}

class WorkoutDayInfo {
  final bool hasPlan;
  final bool doneToday;
  final String label;
  final String title;
  final int planSize;
  final int planInstance;
  final int completedInPlan;

  WorkoutDayInfo({
    required this.hasPlan,
    required this.doneToday,
    required this.label,
    required this.title,
    required this.planSize,
    required this.planInstance,
    required this.completedInPlan,
  });
}

class WorkoutExerciseVm {
  final int templateExerciseId;

  // нужно для "цепочки": понять template + позицию упражнения
  final int templateId;
  final int orderIndex;

  final String name;

  // результаты последнего подхода
  final double? lastWeightKg;
  final int? lastReps;

  // суперсет для конкретного клиента (null = нет)
  final int? supersetGroup;

  WorkoutExerciseVm({
    required this.templateExerciseId,
    required this.templateId,
    required this.orderIndex,
    required this.name,
    required this.lastWeightKg,
    required this.lastReps,
    required this.supersetGroup,
  });
}

class ProgramSlotVm {
  final int slotIndex; // 1..planSize
  final int absoluteIndex; // индекс в текущем экземпляре плана
  final int templateIdx; // 0..8
  final DateTime? performedAt; // null = будущая
  final int? sessionId;

  ProgramSlotVm({
    required this.slotIndex,
    required this.absoluteIndex,
    required this.templateIdx,
    this.performedAt,
    this.sessionId,
  });

  bool get isDone => sessionId != null;
}

class ProgramOverviewVm {
  final ClientProgramState st;
  final List<ProgramSlotVm> slots;

  ProgramOverviewVm({required this.st, required this.slots});
}

class ExerciseHistoryRowVm {
  final DateTime performedAt;
  final double? weightKg;
  final int? reps;

  ExerciseHistoryRowVm({required this.performedAt, this.weightKg, this.reps});
}

class PlanPricesVm {
  final int plan4;
  final int plan8;
  final int plan12;

  const PlanPricesVm({
    required this.plan4,
    required this.plan8,
    required this.plan12,
  });

  int amountForPlan(String? plan) {
    return switch (plan) {
      '4' => plan4,
      '8' => plan8,
      '12' => plan12,
      _ => 0,
    };
  }
}

class IncomeEntryVm {
  final String clientName;
  final String plan;
  final DateTime date;
  final int amount;

  const IncomeEntryVm({
    required this.clientName,
    required this.plan,
    required this.date,
    required this.amount,
  });
}

class ExpenseEntryVm {
  final int id;
  final DateTime date;
  final int amount;
  final String category;
  final String? note;

  const ExpenseEntryVm({
    required this.id,
    required this.date,
    required this.amount,
    required this.category,
    this.note,
  });
}

class IncomeMonthSummaryVm {
  final DateTime monthStart;
  final int income;
  final int expenses;

  const IncomeMonthSummaryVm({
    required this.monthStart,
    required this.income,
    required this.expenses,
  });

  int get net => income - expenses;
}

class ContestEntryVm {
  final String clientId;
  final int usedAttempts;
  final int maxAttempts;
  final String? currentPrize;
  final String? finalPrize;
  final DateTime? finalizedAt;

  const ContestEntryVm({
    required this.clientId,
    required this.usedAttempts,
    required this.maxAttempts,
    this.currentPrize,
    this.finalPrize,
    this.finalizedAt,
  });

  bool get isFinalized => (finalPrize ?? '').isNotEmpty;
  int get attemptsLeft => (maxAttempts - usedAttempts).clamp(0, maxAttempts);
}

class ContestPrizeVm {
  final int id;
  final String title;
  final double weight;
  final bool isGood;
  final int sortOrder;

  const ContestPrizeVm({
    required this.id,
    required this.title,
    required this.weight,
    required this.isGood,
    required this.sortOrder,
  });
}

class ContestWinnerVm {
  final String clientId;
  final String clientName;
  final String prize;
  final DateTime finalizedAt;
  final bool isCompleted;

  const ContestWinnerVm({
    required this.clientId,
    required this.clientName,
    required this.prize,
    required this.finalizedAt,
    required this.isCompleted,
  });
}

class ProgressSnapshotVm {
  final int snapshotId;
  final String periodKey; // мм-гггг
  final DateTime createdAt;
  final int clientsCount;

  const ProgressSnapshotVm({
    required this.snapshotId,
    required this.periodKey,
    required this.createdAt,
    required this.clientsCount,
  });
}

class ProgressSnapshotClientVm {
  final String clientId;
  final String clientName;
  final int sessionsDone;
  final List<Map<String, dynamic>> days;

  const ProgressSnapshotClientVm({
    required this.clientId,
    required this.clientName,
    required this.sessionsDone,
    required this.days,
  });
}

@DriftDatabase(
  tables: [
    Clients,
    Appointments,
    WorkoutTemplates,
    ClientProgramStates,
    WorkoutSessions,
    WorkoutTemplateExercises,
    WorkoutExerciseResults,
    WorkoutDrafts,
    ClientTemplateExerciseOverrides,
  ],
)
class AppDb extends _$AppDb {
  AppDb() : super(driftDatabase(name: 'myfitness'));

  bool _maleDefaultsPatched = false;
  bool _femaleDefaultsPatched = false;
  bool _trialDefaultsPatched = false;
  Future<void>? _templateDefaultsPatchFuture;

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await ensureIncomeTables();
      await ensureContestTables();
      await _ensureProgramDayOverridesTable();
      await _ensurePlanEndAlertOverridesTable();
      await _ensureClientPaymentRemindersTable();
      await _ensureClientExerciseNameOverridesTable();
      await _ensureClientHiddenExercisesTable();
      await _ensureClientAddedExercisesTable();
      await ensureProgressTables();
      await _seedWorkoutTemplates();
      await _seedWorkoutTemplateExercises();
    },

    onUpgrade: (m, from, to) async {
      // Продовая миграция: без удаления существующих данных клиентов.
      await _ensureProgramDayOverridesTable();
      await ensureIncomeTables();
      await ensureContestTables();
      await _ensurePlanEndAlertOverridesTable();
      await _ensureClientPaymentRemindersTable();
      await _ensureClientExerciseNameOverridesTable();
      await _ensureClientHiddenExercisesTable();
      await _ensureClientAddedExercisesTable();
      await ensureProgressTables();

      await _seedWorkoutTemplates();
      await _seedWorkoutTemplateExercises();
    },

    beforeOpen: (details) async {
      await ensureIncomeTables();
      await ensureContestTables();
      await _ensureProgramDayOverridesTable();
      await _ensurePlanEndAlertOverridesTable();
      await _ensureClientPaymentRemindersTable();
      await _ensureClientExerciseNameOverridesTable();
      await _ensureClientHiddenExercisesTable();
      await _ensureClientAddedExercisesTable();
      await ensureProgressTables();
    },
  );

  Future<void> _ensureProgramDayOverridesTable() async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS client_program_day_overrides (
        client_id TEXT NOT NULL,
        plan_instance INTEGER NOT NULL,
        absolute_index INTEGER NOT NULL,
        template_idx INTEGER NOT NULL,
        PRIMARY KEY (client_id, plan_instance, absolute_index)
      )
    ''');
  }

  Future<void> _ensurePlanEndAlertOverridesTable() async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS client_plan_end_alert_overrides (
        client_id TEXT NOT NULL PRIMARY KEY,
        alert_on INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _ensureClientPaymentRemindersTable() async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS client_payment_reminders (
        client_id TEXT NOT NULL PRIMARY KEY,
        remind_on INTEGER NOT NULL,
        note TEXT
      )
    ''');
  }

  Future<void> _ensureClientExerciseNameOverridesTable() async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS client_exercise_name_overrides (
        client_id TEXT NOT NULL,
        template_exercise_id INTEGER NOT NULL,
        custom_name TEXT NOT NULL,
        PRIMARY KEY (client_id, template_exercise_id)
      )
    ''');
  }

  Future<void> _ensureClientHiddenExercisesTable() async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS client_hidden_exercises (
        client_id TEXT NOT NULL,
        template_exercise_id INTEGER NOT NULL,
        PRIMARY KEY (client_id, template_exercise_id)
      )
    ''');
  }

  Future<void> _ensureClientAddedExercisesTable() async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS client_added_exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_id TEXT NOT NULL,
        template_id INTEGER NOT NULL,
        order_index INTEGER NOT NULL,
        name TEXT NOT NULL
      )
    ''');
  }

  Future<void> ensureProgressTables() async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS app_progress_snapshots (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        period_key TEXT NOT NULL UNIQUE,
        created_at INTEGER NOT NULL
      )
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS app_progress_snapshot_clients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        snapshot_id INTEGER NOT NULL,
        client_id TEXT NOT NULL,
        client_name TEXT NOT NULL,
        sessions_done INTEGER NOT NULL,
        days_json TEXT NOT NULL,
        UNIQUE(snapshot_id, client_id)
      )
    ''');
  }

  String _periodKeyMmYyyy(DateTime date) {
    final mm = date.month.toString().padLeft(2, '0');
    return '$mm-${date.year}';
  }

  DateTime _monthStart(DateTime date) => DateTime(date.year, date.month, 1);

  DateTime _toDateTime(dynamic value, {DateTime? fallback}) {
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) {
      return DateTime.tryParse(value) ?? (fallback ?? DateTime.now());
    }
    return fallback ?? DateTime.now();
  }

  Future<void> ensurePreviousMonthProgressSnapshot() async {
    await ensureProgressTables();

    final now = DateTime.now();
    final currentMonthStart = _monthStart(now);
    final previousMonthStart = DateTime(
      currentMonthStart.year,
      currentMonthStart.month - 1,
      1,
    );
    final previousMonthEnd = currentMonthStart;
    final periodKey = _periodKeyMmYyyy(previousMonthStart);

    final existing = await customSelect(
      'SELECT id FROM app_progress_snapshots WHERE period_key = ? LIMIT 1',
      variables: [Variable.withString(periodKey)],
    ).getSingleOrNull();

    if (existing != null) return;

    await _createProgressSnapshot(
      periodKey: periodKey,
      rangeStart: previousMonthStart,
      rangeEnd: previousMonthEnd,
    );
  }

  Future<void> _createProgressSnapshot({
    required String periodKey,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) async {
    await ensureProgressTables();

    await transaction(() async {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      await customStatement(
        'INSERT OR IGNORE INTO app_progress_snapshots (period_key, created_at) VALUES (?, ?)',
        [periodKey, nowMs],
      );

      final snapshotRow = await customSelect(
        'SELECT id FROM app_progress_snapshots WHERE period_key = ? LIMIT 1',
        variables: [Variable.withString(periodKey)],
      ).getSingle();
      final snapshotId = (snapshotRow.data['id'] as int?) ?? 0;
      if (snapshotId <= 0) return;

      final sessionsRows = await customSelect(
        '''
        SELECT s.id AS session_id,
               s.client_id AS client_id,
               COALESCE(c.name, 'Клиент') AS client_name,
               s.performed_at AS performed_at,
               s.template_idx AS template_idx,
               COALESCE(t.title, 'Тренировка') AS template_title
        FROM workout_sessions s
        LEFT JOIN clients c ON c.id = s.client_id
        LEFT JOIN workout_templates t
          ON t.gender = s.gender AND t.idx = s.template_idx
        WHERE s.performed_at >= ? AND s.performed_at < ?
        ORDER BY s.client_id ASC, s.performed_at ASC, s.id ASC
        ''',
        variables: [
          Variable.withDateTime(rangeStart),
          Variable.withDateTime(rangeEnd),
        ],
        readsFrom: {workoutSessions, clients, workoutTemplates},
      ).get();

      final byClient = <String, Map<String, dynamic>>{};
      for (final row in sessionsRows) {
        final sessionId = (row.data['session_id'] as int?) ?? 0;
        final clientId = (row.data['client_id'] as String?) ?? '';
        if (sessionId <= 0 || clientId.isEmpty) continue;

        final clientName = (row.data['client_name'] as String?) ?? 'Клиент';
        final performedAt = _toDateTime(row.data['performed_at']);
        final templateIdx = (row.data['template_idx'] as int?) ?? 0;
        final templateTitle =
            (row.data['template_title'] as String?) ?? 'Тренировка';

        final exerciseRows = await customSelect(
          '''
          SELECT COALESCE(no.custom_name, te.name) AS exercise_name,
                 r.last_weight_kg AS last_weight_kg
          FROM workout_exercise_results r
          LEFT JOIN workout_template_exercises te ON te.id = r.template_exercise_id
          LEFT JOIN client_exercise_name_overrides no
            ON no.client_id = ? AND no.template_exercise_id = r.template_exercise_id
          WHERE r.session_id = ?
          ORDER BY te.order_index ASC, r.id ASC
          ''',
          variables: [
            Variable.withString(clientId),
            Variable.withInt(sessionId),
          ],
          readsFrom: {workoutExerciseResults, workoutTemplateExercises},
        ).get();

        final exercises = exerciseRows
            .map(
              (e) => <String, dynamic>{
                'name': (e.data['exercise_name'] as String?) ?? 'Упражнение',
                'weightKg': e.data['last_weight_kg'] as double?,
              },
            )
            .toList(growable: false);

        final holder = byClient.putIfAbsent(clientId, () {
          return <String, dynamic>{
            'clientName': clientName,
            'days': <Map<String, dynamic>>[],
          };
        });

        final days = holder['days'] as List<Map<String, dynamic>>;
        days.add({
          'performedAt': performedAt.toIso8601String(),
          'templateIdx': templateIdx,
          'title': templateTitle,
          'exercises': exercises,
        });
      }

      for (final entry in byClient.entries) {
        final clientId = entry.key;
        final data = entry.value;
        final clientName = (data['clientName'] as String?) ?? 'Клиент';
        final daysRaw =
            (data['days'] as List<Map<String, dynamic>>?) ??
            <Map<String, dynamic>>[];

        final days = <Map<String, dynamic>>[];
        for (var i = 0; i < daysRaw.length; i++) {
          final item = Map<String, dynamic>.from(daysRaw[i]);
          item['dayNumber'] = i + 1;
          days.add(item);
        }

        await customStatement(
          '''
          INSERT OR REPLACE INTO app_progress_snapshot_clients
            (snapshot_id, client_id, client_name, sessions_done, days_json)
          VALUES (?, ?, ?, ?, ?)
          ''',
          [snapshotId, clientId, clientName, days.length, jsonEncode(days)],
        );
      }
    });
  }

  Future<List<ProgressSnapshotVm>> getProgressSnapshots() async {
    await ensureProgressTables();

    final rows = await customSelect('''
      SELECT s.id, s.period_key, s.created_at, COUNT(c.id) AS clients_count
      FROM app_progress_snapshots s
      LEFT JOIN app_progress_snapshot_clients c ON c.snapshot_id = s.id
      GROUP BY s.id, s.period_key, s.created_at
      ORDER BY s.period_key DESC
    ''').get();

    return rows
        .map(
          (r) => ProgressSnapshotVm(
            snapshotId: (r.data['id'] as int?) ?? 0,
            periodKey: (r.data['period_key'] as String?) ?? '',
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              (r.data['created_at'] as int?) ?? 0,
            ),
            clientsCount: (r.data['clients_count'] as int?) ?? 0,
          ),
        )
        .toList(growable: false);
  }

  Future<List<ProgressSnapshotClientVm>> getSnapshotClients(
    int snapshotId,
  ) async {
    await ensureProgressTables();

    final rows = await customSelect(
      '''
      SELECT client_id, client_name, sessions_done, days_json
      FROM app_progress_snapshot_clients
      WHERE snapshot_id = ?
      ORDER BY client_name COLLATE NOCASE ASC
      ''',
      variables: [Variable.withInt(snapshotId)],
    ).get();

    return rows
        .map((r) {
          final daysRaw = (r.data['days_json'] as String?) ?? '[]';
          final decoded = jsonDecode(daysRaw);
          final days = (decoded is List)
              ? decoded
                    .whereType<Map>()
                    .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
                    .toList(growable: false)
              : const <Map<String, dynamic>>[];

          return ProgressSnapshotClientVm(
            clientId: (r.data['client_id'] as String?) ?? '',
            clientName: (r.data['client_name'] as String?) ?? 'Клиент',
            sessionsDone: (r.data['sessions_done'] as int?) ?? 0,
            days: days,
          );
        })
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> buildProgressExportPayload(
    int snapshotId,
  ) async {
    await ensureProgressTables();

    final head = await customSelect(
      'SELECT id, period_key, created_at FROM app_progress_snapshots WHERE id = ? LIMIT 1',
      variables: [Variable.withInt(snapshotId)],
    ).getSingleOrNull();
    if (head == null) {
      throw ArgumentError('Снимок прогресса не найден');
    }

    final clients = await getSnapshotClients(snapshotId);
    return {
      'kind': 'progress_export',
      'schemaVersion': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'period': (head.data['period_key'] as String?) ?? '',
      'snapshotCreatedAt': DateTime.fromMillisecondsSinceEpoch(
        (head.data['created_at'] as int?) ?? 0,
      ).toIso8601String(),
      'clients': clients
          .map(
            (c) => {
              'clientId': c.clientId,
              'clientName': c.clientName,
              'sessionsDone': c.sessionsDone,
              'days': c.days,
            },
          )
          .toList(growable: false),
    };
  }

  Future<void> deleteProgressSnapshot(int snapshotId) async {
    await ensureProgressTables();

    await transaction(() async {
      await customStatement(
        'DELETE FROM app_progress_snapshot_clients WHERE snapshot_id = ?',
        [snapshotId],
      );
      await customStatement('DELETE FROM app_progress_snapshots WHERE id = ?', [
        snapshotId,
      ]);
    });
  }

  Future<List<({int id, int templateId, int orderIndex, String name})>>
  _getEffectiveExercisesForClientTemplate({
    required String clientId,
    required int templateId,
  }) async {
    await _ensureClientExerciseNameOverridesTable();
    await _ensureClientHiddenExercisesTable();
    await _ensureClientAddedExercisesTable();

    final baseExercises =
        await (select(workoutTemplateExercises)
              ..where((e) => e.templateId.equals(templateId))
              ..orderBy([(e) => OrderingTerm.asc(e.orderIndex)]))
            .get();

    final hiddenRows = await customSelect(
      '''
      SELECT template_exercise_id
      FROM client_hidden_exercises
      WHERE client_id = ?
      ''',
      variables: [Variable.withString(clientId)],
    ).get();
    final hiddenIds = {
      for (final r in hiddenRows) (r.data['template_exercise_id'] as int?) ?? 0,
    }..remove(0);

    final nameOverrideRows = await customSelect(
      '''
      SELECT template_exercise_id, custom_name
      FROM client_exercise_name_overrides
      WHERE client_id = ?
      ''',
      variables: [Variable.withString(clientId)],
    ).get();
    final nameOverrides = {
      for (final r in nameOverrideRows)
        (r.data['template_exercise_id'] as int?) ?? 0:
            (r.data['custom_name'] as String?) ?? '',
    }..remove(0);

    final addedRows = await customSelect(
      '''
      SELECT id, template_id, order_index, name
      FROM client_added_exercises
      WHERE client_id = ? AND template_id = ?
      ORDER BY order_index ASC, id ASC
      ''',
      variables: [Variable.withString(clientId), Variable.withInt(templateId)],
    ).get();

    final merged = <({int id, int templateId, int orderIndex, String name})>[];

    for (final e in baseExercises) {
      if (hiddenIds.contains(e.id)) continue;
      merged.add((
        id: e.id,
        templateId: e.templateId,
        orderIndex: e.orderIndex,
        name: nameOverrides[e.id] ?? e.name,
      ));
    }

    for (final r in addedRows) {
      merged.add((
        id: -((r.data['id'] as int?) ?? 0),
        templateId: (r.data['template_id'] as int?) ?? templateId,
        orderIndex: (r.data['order_index'] as int?) ?? 0,
        name: (r.data['name'] as String?) ?? 'Упражнение',
      ));
    }

    merged.sort((a, b) {
      final byOrder = a.orderIndex.compareTo(b.orderIndex);
      if (byOrder != 0) return byOrder;
      return a.id.compareTo(b.id);
    });

    return merged;
  }

  Future<Map<int, int>> _getProgramDayOverrides({
    required String clientId,
    required int planInstance,
  }) async {
    await _ensureProgramDayOverridesTable();

    final rows = await customSelect(
      'SELECT absolute_index, template_idx FROM client_program_day_overrides '
      'WHERE client_id = ? AND plan_instance = ?',
      variables: [
        Variable.withString(clientId),
        Variable.withInt(planInstance),
      ],
    ).get();

    final out = <int, int>{};
    for (final r in rows) {
      out[r.read<int>('absolute_index')] = r.read<int>('template_idx');
    }
    return out;
  }

  Future<void> _setProgramDayOverride({
    required String clientId,
    required int planInstance,
    required int absoluteIndex,
    required int templateIdx,
  }) async {
    await _ensureProgramDayOverridesTable();
    await customStatement(
      'INSERT OR REPLACE INTO client_program_day_overrides '
      '(client_id, plan_instance, absolute_index, template_idx) VALUES (?, ?, ?, ?)',
      [clientId, planInstance, absoluteIndex, templateIdx],
    );
  }

  Future<void> _deleteProgramDayOverride({
    required String clientId,
    required int planInstance,
    required int absoluteIndex,
  }) async {
    await _ensureProgramDayOverridesTable();
    await customStatement(
      'DELETE FROM client_program_day_overrides '
      'WHERE client_id = ? AND plan_instance = ? AND absolute_index = ?',
      [clientId, planInstance, absoluteIndex],
    );
  }

  Future<String> _templateLabelByIdx({
    required String gender,
    required int templateIdx,
  }) async {
    final row =
        await (select(workoutTemplates)..where(
              (t) => t.gender.equals(gender) & t.idx.equals(templateIdx),
            ))
            .getSingleOrNull();

    if (row != null) return row.label;

    if (gender == 'М') {
      const groups = ['Спина', 'Грудь', 'Ноги'];
      return groups[templateIdx % 3];
    }
    const groups = [
      'Спина',
      'Ноги',
      'Грудь',
      'Ноги',
      'Спина',
      'Ноги',
      'Грудь',
      'Ноги',
    ];
    return groups[templateIdx % groups.length];
  }

  Future<void> swapPlannedProgramDays({
    required String clientId,
    required int firstAbsoluteIndex,
    required int secondAbsoluteIndex,
  }) async {
    if (firstAbsoluteIndex == secondAbsoluteIndex) return;

    await ensureProgramStateForClient(clientId);

    final st = await (select(
      clientProgramStates,
    )..where((t) => t.clientId.equals(clientId))).getSingleOrNull();
    if (st == null || st.planSize <= 0) return;

    if (firstAbsoluteIndex < st.completedInPlan ||
        secondAbsoluteIndex < st.completedInPlan) {
      throw StateError(
        'Можно менять только запланированные (не выполненные) дни.',
      );
    }

    final c = await getClientById(clientId);
    final gender = c == null ? 'М' : _programTrackByClient(c);
    final cycleLen = _cycleLenByGender(gender);

    int defaultIdx(int absoluteIndex) =>
        _mod(st.cycleStartIndex + absoluteIndex, cycleLen);

    final overrides = await _getProgramDayOverrides(
      clientId: clientId,
      planInstance: st.planInstance,
    );

    final firstCurrent =
        overrides[firstAbsoluteIndex] ?? defaultIdx(firstAbsoluteIndex);
    final secondCurrent =
        overrides[secondAbsoluteIndex] ?? defaultIdx(secondAbsoluteIndex);

    final firstLabel = await _templateLabelByIdx(
      gender: gender,
      templateIdx: firstCurrent,
    );
    final secondLabel = await _templateLabelByIdx(
      gender: gender,
      templateIdx: secondCurrent,
    );

    if (firstLabel != secondLabel) {
      throw StateError(
        'Можно менять только одинаковые типы дней (например, Спина ↔ Спина).',
      );
    }

    final firstDefault = defaultIdx(firstAbsoluteIndex);
    final secondDefault = defaultIdx(secondAbsoluteIndex);

    if (secondCurrent == firstDefault) {
      await _deleteProgramDayOverride(
        clientId: clientId,
        planInstance: st.planInstance,
        absoluteIndex: firstAbsoluteIndex,
      );
    } else {
      await _setProgramDayOverride(
        clientId: clientId,
        planInstance: st.planInstance,
        absoluteIndex: firstAbsoluteIndex,
        templateIdx: secondCurrent,
      );
    }

    if (firstCurrent == secondDefault) {
      await _deleteProgramDayOverride(
        clientId: clientId,
        planInstance: st.planInstance,
        absoluteIndex: secondAbsoluteIndex,
      );
    } else {
      await _setProgramDayOverride(
        clientId: clientId,
        planInstance: st.planInstance,
        absoluteIndex: secondAbsoluteIndex,
        templateIdx: firstCurrent,
      );
    }
  }

  // --- Clients ---
  Future<List<Client>> getAllClients() =>
      (select(clients)..orderBy([(t) => OrderingTerm.asc(t.name)])).get();

  Future<Client?> getClientById(String id) =>
      (select(clients)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> upsertClient(ClientsCompanion data) =>
      into(clients).insertOnConflictUpdate(data);

  Future<int> deleteClientById(String id) =>
      (delete(clients)..where((t) => t.id.equals(id))).go();

  Future<void> initializeSupersetsForNewClient(String clientId) async {
    await transaction(() async {
      final existingOverrides =
          await (select(clientTemplateExerciseOverrides)
                ..where((o) => o.clientId.equals(clientId))
                ..limit(1))
              .getSingleOrNull();
      if (existingOverrides != null) return;

      final client = await getClientById(clientId);
      if (client == null) return;

      final track = _programTrackByClient(client);
      if (track != 'М' && track != 'Ж') return;

      final rows = await customSelect(
        'SELECT e.id AS exercise_id, e.group_id AS group_id '
        'FROM ${workoutTemplateExercises.actualTableName} e '
        'INNER JOIN ${workoutTemplates.actualTableName} t '
        'ON t.${workoutTemplates.id.name} = e.${workoutTemplateExercises.templateId.name} '
        'WHERE t.${workoutTemplates.gender.name} = ? '
        'AND e.${workoutTemplateExercises.groupId.name} IS NOT NULL',
        variables: [Variable.withString(track)],
        readsFrom: {workoutTemplateExercises, workoutTemplates},
      ).get();

      for (final row in rows) {
        final exerciseId = (row.data['exercise_id'] as int?) ?? 0;
        final groupId = row.data['group_id'] as int?;
        if (exerciseId <= 0 || groupId == null) continue;

        await into(clientTemplateExerciseOverrides).insertOnConflictUpdate(
          ClientTemplateExerciseOverridesCompanion.insert(
            clientId: clientId,
            templateExerciseId: exerciseId,
            supersetGroup: Value(groupId),
          ),
        );
      }
    });
  }

  // --- Appointments ---
  Stream<List<AppointmentWithClient>> watchAppointmentsForDay(DateTime day) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final joinQuery =
        select(appointments).join([
            innerJoin(clients, clients.id.equalsExp(appointments.clientId)),
          ])
          ..where(
            appointments.startAt.isBiggerOrEqualValue(dayStart) &
                appointments.startAt.isSmallerThanValue(dayEnd),
          )
          ..orderBy([OrderingTerm.asc(appointments.startAt)]);

    return joinQuery.watch().map((rows) {
      return rows.map((r) {
        final a = r.readTable(appointments);
        final c = r.readTable(clients);
        return AppointmentWithClient(a, c);
      }).toList();
    });
  }

  Stream<List<Appointment>> watchAppointmentsForClientInRange({
    required String clientId,
    required DateTime fromInclusive,
    required DateTime toExclusive,
  }) {
    final q = select(appointments)
      ..where(
        (t) =>
            t.clientId.equals(clientId) &
            t.startAt.isBiggerOrEqualValue(fromInclusive) &
            t.startAt.isSmallerThanValue(toExclusive),
      )
      ..orderBy([(t) => OrderingTerm.asc(t.startAt)]);
    return q.watch();
  }

  Future<void> addAppointment({
    required String clientId,
    required DateTime startAt,
    String? note,
  }) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    await into(appointments).insert(
      AppointmentsCompanion.insert(
        id: id,
        clientId: clientId,
        startAt: startAt,
        note: note == null ? const Value.absent() : Value(note),
      ),
    );
  }

  Future<int> deleteAppointmentById(String id) =>
      (delete(appointments)..where((t) => t.id.equals(id))).go();

  Future<void> updateAppointmentTime({
    required String id,
    required DateTime newStartAt,
  }) async {
    await (update(appointments)..where((t) => t.id.equals(id))).write(
      AppointmentsCompanion(startAt: Value(newStartAt)),
    );
  }

  Future<void> updateAppointmentNote({required String id, String? note}) async {
    await (update(appointments)..where((t) => t.id.equals(id))).write(
      AppointmentsCompanion(note: Value(note)),
    );
  }

  Future<Map<int, (double? kg, int? reps)>> getWorkoutDraftResults({
    required String clientId,
    required DateTime day,
    int? templateIdx,
    int? absoluteIndex,
  }) async {
    final dayOnly = DateTime(day.year, day.month, day.day);
    final scopeIdxes = _draftScopeIdxes(
      templateIdx: templateIdx,
      absoluteIndex: absoluteIndex,
      includeLegacy: true,
    );

    final rows =
        await (select(workoutDrafts)
              ..where(
                (t) =>
                    t.clientId.equals(clientId) &
                    t.day.equals(dayOnly) &
                    t.templateIdx.isIn(scopeIdxes),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
            .get();

    final scopePriority = <int, int>{
      for (var i = 0; i < scopeIdxes.length; i++) scopeIdxes[i]: i,
    };

    final map = <int, (double? kg, int? reps)>{};
    final bestPriorityByExercise = <int, int>{};
    for (final r in rows) {
      final exId = r.templateExerciseId;
      final priority = scopePriority[r.templateIdx] ?? 999;
      final prevPriority = bestPriorityByExercise[exId];

      if (prevPriority == null || priority < prevPriority) {
        bestPriorityByExercise[exId] = priority;
        map[exId] = (r.lastWeightKg, r.lastReps);
      }
    }
    return map;
  }

  Future<void> saveWorkoutDraftResults({
    required String clientId,
    required DateTime day,
    required Map<int, (double? kg, int? reps)> resultsByTemplateExerciseId,
    int? templateIdx,
    int? absoluteIndex,
  }) async {
    final dayOnly = DateTime(day.year, day.month, day.day);
    final scopeIdxes = _draftScopeIdxes(
      templateIdx: templateIdx,
      absoluteIndex: absoluteIndex,
      includeLegacy: true,
    );
    final primaryScopeIdx = scopeIdxes.first;

    await transaction(() async {
      await (delete(workoutDrafts)..where(
            (t) =>
                t.clientId.equals(clientId) &
                t.day.equals(dayOnly) &
                t.templateIdx.isIn(scopeIdxes),
          ))
          .go();

      final now = DateTime.now();
      for (final entry in resultsByTemplateExerciseId.entries) {
        final exId = entry.key;
        final kg = entry.value.$1;
        final reps = entry.value.$2;

        if (kg == null && reps == null) continue;

        await into(workoutDrafts).insert(
          WorkoutDraftsCompanion.insert(
            clientId: clientId,
            day: dayOnly,
            templateIdx: Value(primaryScopeIdx),
            templateExerciseId: exId,
            lastWeightKg: Value(kg),
            lastReps: Value(reps),
            updatedAt: Value(now),
          ),
        );
      }
    });
  }

  Future<void> clearWorkoutDraftResults({
    required String clientId,
    required DateTime day,
    int? templateIdx,
    int? absoluteIndex,
  }) async {
    final dayOnly = DateTime(day.year, day.month, day.day);
    final scopeIdxes = _draftScopeIdxes(
      templateIdx: templateIdx,
      absoluteIndex: absoluteIndex,
      includeLegacy: true,
    );

    await (delete(workoutDrafts)..where(
          (t) =>
              t.clientId.equals(clientId) &
              t.day.equals(dayOnly) &
              t.templateIdx.isIn(scopeIdxes),
        ))
        .go();
  }

  List<int> _draftScopeIdxes({
    int? templateIdx,
    int? absoluteIndex,
    bool includeLegacy = false,
  }) {
    final idxes = <int>{};

    if (absoluteIndex != null) {
      // Основной ключ для программного слота: только absoluteIndex.
      // Это стабильно, даже если templateIdx для того же слота потом пересчитался.
      final stableSlotIdx = (absoluteIndex + 1) * 1000;
      idxes.add(stableSlotIdx);

      if (includeLegacy) {
        // Старый формат, где в ключ добавлялся templateIdx.
        final legacyTemplatePart = templateIdx ?? -1;
        idxes.add(stableSlotIdx + legacyTemplatePart);
        idxes.add(-1);
      }
    } else {
      final baseIdx = templateIdx ?? -1;
      idxes.add(baseIdx);
      if (includeLegacy) idxes.add(-1);
    }

    return idxes.toList();
  }

  Future<bool> appointmentExists({
    required String clientId,
    required DateTime startAt,
  }) async {
    final q = select(appointments)
      ..where((t) => t.clientId.equals(clientId) & t.startAt.equals(startAt));
    return (await q.get()).isNotEmpty;
  }

  Future<List<Appointment>> getFutureAppointmentsForClient({
    required String clientId,
    required DateTime from,
  }) {
    final q = select(appointments)
      ..where(
        (t) =>
            t.clientId.equals(clientId) & t.startAt.isBiggerOrEqualValue(from),
      )
      ..orderBy([(t) => OrderingTerm.asc(t.startAt)]);
    return q.get();
  }

  Future<int> deleteFutureAppointmentsForClient({
    required String clientId,
    required DateTime from,
  }) {
    return (delete(appointments)..where(
          (t) =>
              t.clientId.equals(clientId) &
              t.startAt.isBiggerOrEqualValue(from),
        ))
        .go();
  }

  Future<void> addAppointmentIfNotExists({
    required String clientId,
    required DateTime startAt,
    String? note,
  }) async {
    final exists = await appointmentExists(
      clientId: clientId,
      startAt: startAt,
    );
    if (exists) return;
    await addAppointment(clientId: clientId, startAt: startAt, note: note);
  }

  // --- Calendar markers: count appointments per day in a range ---
  Stream<Map<DateTime, int>> watchAppointmentCountsByDay({
    required DateTime from,
    required DateTime to,
    bool? onlyTrial,
  }) {
    final variables = <Variable<Object>>[
      Variable<DateTime>(from),
      Variable<DateTime>(to),
    ];

    var wherePlan = '';
    if (onlyTrial == true) {
      wherePlan = ' AND c.${clients.plan.name} = ?';
      variables.add(const Variable<String>('Пробный'));
    } else if (onlyTrial == false) {
      wherePlan =
          ' AND (c.${clients.plan.name} IS NULL OR c.${clients.plan.name} != ?)';
      variables.add(const Variable<String>('Пробный'));
    }

    final q = customSelect(
      "SELECT date(datetime(CASE WHEN a.${appointments.startAt.name} > 20000000000 THEN a.${appointments.startAt.name} / 1000 ELSE a.${appointments.startAt.name} END, 'unixepoch', 'localtime')) AS d, COUNT(*) AS c "
      'FROM ${appointments.actualTableName} a '
      'INNER JOIN ${clients.actualTableName} c '
      'ON c.${clients.id.name} = a.${appointments.clientId.name} '
      'WHERE a.${appointments.startAt.name} >= ? AND a.${appointments.startAt.name} < ? '
      '$wherePlan '
      'GROUP BY d',
      variables: variables,
      readsFrom: {appointments, clients},
    );

    return q.watch().map((rows) {
      final map = <DateTime, int>{};
      for (final r in rows) {
        final dayStr = r.read<String>('d'); // 'YYYY-MM-DD'
        final cnt = r.read<int>('c');
        final dt = DateTime.parse(dayStr);
        final key = DateTime(dt.year, dt.month, dt.day);
        map[key] = cnt;
      }
      return map;
    });
  }

  Stream<Map<DateTime, int>> watchPlanEndCountsByDay({
    required DateTime from,
    required DateTime to,
  }) async* {
    await _ensurePlanEndAlertOverridesTable();

    final q = customSelect(
      "SELECT date(datetime(CASE WHEN COALESCE(o.alert_on, ${clients.planEnd.name}) > 20000000000 THEN COALESCE(o.alert_on, ${clients.planEnd.name}) / 1000 ELSE COALESCE(o.alert_on, ${clients.planEnd.name}) END, 'unixepoch', 'localtime')) AS d, COUNT(*) AS c "
      'FROM ${clients.actualTableName} c '
      'LEFT JOIN client_plan_end_alert_overrides o '
      'ON o.client_id = c.${clients.id.name} '
      'WHERE c.${clients.planEnd.name} IS NOT NULL '
      'AND COALESCE(o.alert_on, c.${clients.planEnd.name}) >= ? '
      'AND COALESCE(o.alert_on, c.${clients.planEnd.name}) < ? '
      "AND COALESCE(c.${clients.plan.name}, '') != 'Пробный' "
      'GROUP BY d',
      variables: [Variable<DateTime>(from), Variable<DateTime>(to)],
      readsFrom: {clients},
    );

    yield* q.watch().map((rows) {
      final map = <DateTime, int>{};
      for (final r in rows) {
        final dayStr = r.read<String>('d');
        final cnt = r.read<int>('c');
        final dt = DateTime.parse(dayStr);
        map[DateTime(dt.year, dt.month, dt.day)] = cnt;
      }
      return map;
    });
  }

  Stream<Map<DateTime, int>> watchPaymentReminderCountsByDay({
    required DateTime from,
    required DateTime to,
  }) async* {
    await _ensureClientPaymentRemindersTable();

    final q = customSelect(
      "SELECT date(datetime(CASE WHEN remind_on > 20000000000 THEN remind_on / 1000 ELSE remind_on END, 'unixepoch', 'localtime')) AS d, COUNT(*) AS c "
      'FROM client_payment_reminders '
      'WHERE remind_on >= ? AND remind_on < ? '
      'GROUP BY d',
      variables: [Variable<DateTime>(from), Variable<DateTime>(to)],
      readsFrom: {clients},
    );

    yield* q.watch().map((rows) {
      final map = <DateTime, int>{};
      for (final r in rows) {
        final dayStr = r.read<String>('d');
        final cnt = r.read<int>('c');
        final dt = DateTime.parse(dayStr);
        map[DateTime(dt.year, dt.month, dt.day)] = cnt;
      }
      return map;
    });
  }

  Stream<List<PaymentReminderWithClient>> watchClientsWithPaymentReminderForDay(
    DateTime day,
  ) async* {
    await _ensureClientPaymentRemindersTable();

    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final q = customSelect(
      'SELECT c.id AS client_id, r.remind_on AS remind_on, r.note AS note '
      'FROM client_payment_reminders r '
      'INNER JOIN ${clients.actualTableName} c '
      'ON c.${clients.id.name} = r.client_id '
      'WHERE r.remind_on >= ? AND r.remind_on < ? '
      'ORDER BY c.${clients.name.name} ASC',
      variables: [Variable<DateTime>(dayStart), Variable<DateTime>(dayEnd)],
      readsFrom: {clients},
    );

    yield* q.watch().asyncMap((rows) async {
      if (rows.isEmpty) return <PaymentReminderWithClient>[];

      final ids = rows.map((r) => r.read<String>('client_id')).toList();
      final clientsRows = await (select(
        clients,
      )..where((t) => t.id.isIn(ids))).get();
      final byId = {for (final c in clientsRows) c.id: c};

      final out = <PaymentReminderWithClient>[];
      for (final row in rows) {
        final clientId = row.read<String>('client_id');
        final client = byId[clientId];
        if (client == null) continue;
        final remindOn = row.read<DateTime>('remind_on');
        final note = row.readNullable<String>('note');
        out.add(
          PaymentReminderWithClient(
            client: client,
            remindOn: DateTime(remindOn.year, remindOn.month, remindOn.day),
            note: note,
          ),
        );
      }
      return out;
    });
  }

  Future<void> setClientPaymentReminder({
    required String clientId,
    required DateTime remindOn,
    String? note,
  }) async {
    await _ensureClientPaymentRemindersTable();
    final normalized = DateTime(remindOn.year, remindOn.month, remindOn.day);
    final cleanNote = note?.trim();

    await customUpdate(
      "INSERT OR REPLACE INTO client_payment_reminders (client_id, remind_on, note) VALUES (?, ?, NULLIF(?, ''))",
      variables: [
        Variable.withString(clientId),
        Variable<DateTime>(normalized),
        Variable.withString(cleanNote ?? ''),
      ],
      updates: {clients},
      updateKind: UpdateKind.insert,
    );
    notifyUpdates({TableUpdate.onTable(clients)});
  }

  Future<void> clearClientPaymentReminder(String clientId) async {
    await _ensureClientPaymentRemindersTable();
    await customUpdate(
      'DELETE FROM client_payment_reminders WHERE client_id = ?',
      variables: [Variable.withString(clientId)],
      updates: {clients},
      updateKind: UpdateKind.delete,
    );
    notifyUpdates({TableUpdate.onTable(clients)});
  }

  Stream<List<Client>> watchClientsWithPlanEndForDay(DateTime day) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final q = (select(clients)
      ..where(
        (t) =>
            t.planEnd.isNotNull() &
            t.planEnd.isBiggerOrEqualValue(dayStart) &
            t.planEnd.isSmallerThanValue(dayEnd) &
            t.plan.isNotNull() &
            t.plan.equals('Пробный').not(),
      )
      ..orderBy([(t) => OrderingTerm.asc(t.name)]));

    return q.watch();
  }

  Stream<List<Client>> watchClientsWithPlanAlertForDay(DateTime day) async* {
    await _ensurePlanEndAlertOverridesTable();

    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final q = customSelect(
      'SELECT c.id AS client_id '
      'FROM ${clients.actualTableName} c '
      'LEFT JOIN client_plan_end_alert_overrides o '
      'ON o.client_id = c.${clients.id.name} '
      'WHERE c.${clients.planEnd.name} IS NOT NULL '
      "AND COALESCE(c.${clients.plan.name}, '') != 'Пробный' "
      'AND COALESCE(o.alert_on, c.${clients.planEnd.name}) >= ? '
      'AND COALESCE(o.alert_on, c.${clients.planEnd.name}) < ? '
      'ORDER BY c.${clients.name.name} ASC',
      variables: [Variable<DateTime>(dayStart), Variable<DateTime>(dayEnd)],
      readsFrom: {clients},
    );

    yield* q.watch().asyncMap((rows) async {
      final ids = rows.map((r) => r.read<String>('client_id')).toList();
      if (ids.isEmpty) return <Client>[];

      final rowsById = await (select(
        clients,
      )..where((t) => t.id.isIn(ids))).get();
      final map = {for (final c in rowsById) c.id: c};
      return ids.map((id) => map[id]).whereType<Client>().toList();
    });
  }

  Future<void> postponeClientPlanEndAlert({
    required String clientId,
    required DateTime alertOn,
  }) async {
    await _ensurePlanEndAlertOverridesTable();
    final normalized = DateTime(alertOn.year, alertOn.month, alertOn.day);
    await customUpdate(
      'INSERT OR REPLACE INTO client_plan_end_alert_overrides (client_id, alert_on) VALUES (?, ?)',
      variables: [
        Variable.withString(clientId),
        Variable<DateTime>(normalized),
      ],
      updates: {clients},
      updateKind: UpdateKind.insert,
    );
    notifyUpdates({TableUpdate.onTable(clients)});
  }

  Future<void> clearClientPlanEndAlertOverride(String clientId) async {
    await _ensurePlanEndAlertOverridesTable();
    await customUpdate(
      'DELETE FROM client_plan_end_alert_overrides WHERE client_id = ?',
      variables: [Variable.withString(clientId)],
      updates: {clients},
      updateKind: UpdateKind.delete,
    );
    notifyUpdates({TableUpdate.onTable(clients)});
  }

  Future<DateTime?> getClientEffectivePlanAlertDate(Client client) async {
    if (client.planEnd == null) return null;

    await _ensurePlanEndAlertOverridesTable();
    final row = await customSelect(
      'SELECT alert_on FROM client_plan_end_alert_overrides WHERE client_id = ? LIMIT 1',
      variables: [Variable.withString(client.id)],
    ).getSingleOrNull();

    final overrideDate = row?.readNullable<DateTime>('alert_on');
    final effective = overrideDate ?? client.planEnd;
    if (effective == null) return null;
    return DateTime(effective.year, effective.month, effective.day);
  }
  // ===== Programs / Workouts =====

  int _parsePlanSize(String? plan) {
    if (plan == null) return 0;
    final p = plan.trim();
    if (p == 'Пробный') return 1;

    final n = int.tryParse(p);
    if (n == null) return 0;

    if (n == 4 || n == 8 || n == 12) return n;
    return 0;
  }

  int _groupShiftByGender(String gender) {
    // М: спина/грудь/ноги => 3, Ж: верх/низ => 2
    return gender == 'Ж' ? 2 : 3;
  }

  int _mod(int x, int n) => ((x % n) + n) % n;

  String _programTrackByClient(Client c) {
    if (c.plan == 'Пробный') return 'П';
    final g = c.gender ?? 'М';
    if (g == 'М' || g == 'Ж') return g;
    return 'М';
  }

  int _cycleLenByGender(String gender) {
    if (gender == 'П') return 1;
    return gender == 'Ж' ? 8 : 9;
  }

  DateTime _dayStart(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime _dayEnd(DateTime d) => _dayStart(d).add(const Duration(days: 1));

  Future<void> _seedWorkoutTemplates() async {
    final count = await (select(workoutTemplates).get()).then((v) => v.length);
    if (count > 0) return;

    final male = <WorkoutTemplatesCompanion>[
      WorkoutTemplatesCompanion.insert(
        gender: 'М',
        idx: 0,
        label: 'Спина',
        title: 'День 1 • Спина (середина)',
      ),
      WorkoutTemplatesCompanion.insert(
        gender: 'М',
        idx: 1,
        label: 'Грудь',
        title: 'День 2 • Грудь (верх)',
      ),
      WorkoutTemplatesCompanion.insert(
        gender: 'М',
        idx: 2,
        label: 'Ноги',
        title: 'День 3 • Ноги',
      ),
      WorkoutTemplatesCompanion.insert(
        gender: 'М',
        idx: 3,
        label: 'Спина',
        title: 'День 4 • Спина (низ)',
      ),
      WorkoutTemplatesCompanion.insert(
        gender: 'М',
        idx: 4,
        label: 'Грудь',
        title: 'День 5 • Грудь (середина)',
      ),
      WorkoutTemplatesCompanion.insert(
        gender: 'М',
        idx: 5,
        label: 'Ноги',
        title: 'День 6 • Ноги',
      ),
      WorkoutTemplatesCompanion.insert(
        gender: 'М',
        idx: 6,
        label: 'Спина',
        title: 'День 7 • Спина (верх)',
      ),
      WorkoutTemplatesCompanion.insert(
        gender: 'М',
        idx: 7,
        label: 'Грудь',
        title: 'День 8 • Грудь (низ)',
      ),
      WorkoutTemplatesCompanion.insert(
        gender: 'М',
        idx: 8,
        label: 'Ноги',
        title: 'День 9 • Ноги (переход цикла)',
      ),
    ];

    final female = _femaleTemplateDefaults();
    final trial = _trialTemplateDefaults();

    await batch((b) {
      b.insertAll(workoutTemplates, [...male, ...female, ...trial]);
    });
  }

  List<WorkoutTemplatesCompanion> _maleTemplateDefaults() {
    return <WorkoutTemplatesCompanion>[
      WorkoutTemplatesCompanion.insert(
        gender: 'М',
        idx: 0,
        label: 'Спина',
        title: 'День 1 • Спина (середина)',
      ),
      WorkoutTemplatesCompanion.insert(
        gender: 'М',
        idx: 1,
        label: 'Грудь',
        title: 'День 2 • Грудь (верх)',
      ),
      WorkoutTemplatesCompanion.insert(
        gender: 'М',
        idx: 2,
        label: 'Ноги',
        title: 'День 3 • Ноги',
      ),
      WorkoutTemplatesCompanion.insert(
        gender: 'М',
        idx: 3,
        label: 'Спина',
        title: 'День 4 • Спина (низ)',
      ),
      WorkoutTemplatesCompanion.insert(
        gender: 'М',
        idx: 4,
        label: 'Грудь',
        title: 'День 5 • Грудь (середина)',
      ),
      WorkoutTemplatesCompanion.insert(
        gender: 'М',
        idx: 5,
        label: 'Ноги',
        title: 'День 6 • Ноги',
      ),
      WorkoutTemplatesCompanion.insert(
        gender: 'М',
        idx: 6,
        label: 'Спина',
        title: 'День 7 • Спина (верх)',
      ),
      WorkoutTemplatesCompanion.insert(
        gender: 'М',
        idx: 7,
        label: 'Грудь',
        title: 'День 8 • Грудь (низ)',
      ),
      WorkoutTemplatesCompanion.insert(
        gender: 'М',
        idx: 8,
        label: 'Ноги',
        title: 'День 9 • Ноги (переход цикла)',
      ),
    ];
  }

  List<WorkoutTemplatesCompanion> _femaleTemplateDefaults() {
    return <WorkoutTemplatesCompanion>[
      WorkoutTemplatesCompanion.insert(
        gender: 'Ж',
        idx: 0,
        label: 'Спина',
        title: 'День 1 • Спина (низ)',
      ),
      WorkoutTemplatesCompanion.insert(
        gender: 'Ж',
        idx: 1,
        label: 'Ноги',
        title: 'День 2 • Ноги',
      ),
      WorkoutTemplatesCompanion.insert(
        gender: 'Ж',
        idx: 2,
        label: 'Грудь',
        title: 'День 3 • Грудь (верх)',
      ),
      WorkoutTemplatesCompanion.insert(
        gender: 'Ж',
        idx: 3,
        label: 'Ноги',
        title: 'День 4 • Ноги',
      ),
      WorkoutTemplatesCompanion.insert(
        gender: 'Ж',
        idx: 4,
        label: 'Спина',
        title: 'День 5 • Спина (верх)',
      ),
      WorkoutTemplatesCompanion.insert(
        gender: 'Ж',
        idx: 5,
        label: 'Ноги',
        title: 'День 6 • Ноги',
      ),
      WorkoutTemplatesCompanion.insert(
        gender: 'Ж',
        idx: 6,
        label: 'Грудь',
        title: 'День 7 • Грудь (середина)',
      ),
      WorkoutTemplatesCompanion.insert(
        gender: 'Ж',
        idx: 7,
        label: 'Ноги',
        title: 'День 8 • Ноги',
      ),
    ];
  }

  List<WorkoutTemplatesCompanion> _trialTemplateDefaults() {
    return <WorkoutTemplatesCompanion>[
      WorkoutTemplatesCompanion.insert(
        gender: 'П',
        idx: 0,
        label: 'Пробная',
        title: 'Пробная тренировка',
      ),
    ];
  }

  Map<int, List<(String name, int? group)>> _trialExerciseDefaults() {
    return <int, List<(String name, int? group)>>{
      0: [
        ('Тяга верхнего блока параллельным хватом', null),
        ('Тяга нижнего блока самолётным хватом', null),
        ('Жим в хамере', null),
        ('Жим ногами', null),
        ('Выпады на месте', null),
      ],
    };
  }

  Map<int, List<(String name, int? group)>> _maleExerciseDefaults() {
    return <int, List<(String name, int? group)>>{
      0: [
        ('Тяга верхнего блока параллельным хватом', null),
        ('Тяга нижнего блока параллельным хватом', null),
        ('Тяга штанги в наклоне верхним хватом', null),
        ('Молотки сидя на скамье', null),
        ('Разведение рук в тренажёре', 1),
        ('Гиперэкстензия', 1),
      ],
      1: [
        ('Жим в тренажёре на верх груди', null),
        ('Жим штанги лёжа', null),
        ('Пуловер с гантелью', null),
        ('Жим гантелей сидя на скамье', null),
        ('Разгибание рук', null),
      ],
      2: [
        ('Жим ногами', null),
        ('Приседания со штангой', null),
        ('Выпады на месте', null),
        ('Сгибание ног', 1),
        ('Разгибание ног', 1),
        ('Махи рук в стороны', 2),
        ('Икры сидя / стоя (чередовать)', 2),
      ],
      3: [
        ('Рычажная тяга обратным хватом', null),
        ('Рычажная тяга параллельным хватом', null),
        ('Тяга одной рукой стоя на коленях', null),
        ('Строгий подъём на бицепс', null),
        ('Разведение рук в тренажёре', 1),
        ('Гиперэкстензия', 1),
      ],
      4: [
        ('Жим штанги на верх груди', null),
        ('Жим в хаммере', null),
        ('Сведение рук стоя', null),
        ('Жим штанги стоя', null),
        ('Супермен', null),
      ],
      5: [
        ('Жим ногами', null),
        ('Приседания со штангой', null),
        ('Выпады на месте', null),
        ('Сгибание ног', 1),
        ('Разгибание ног', 1),
        ('Махи рук в стороны', 2),
        ('Икры сидя / стоя (чередовать)', 2),
      ],
      6: [
        ('Подтягивания в гравитоне', null),
        ('Тяга нижнего блока параллельным хватом', null),
        ('Т-образная тяга', null),
        ('Подъём гантелей на бицепс с супинацией', null),
        ('Разведение рук в тренажёре', 1),
        ('Гиперэкстензия', 1),
      ],
      7: [
        ('Брусья', null),
        ('Жим гантелей лёжа на скамье', null),
        ('Сведение рук лёжа на скамье', null),
        ('Жим гантелей сидя на скамье', null),
        ('Самурай', null),
      ],
      8: [
        ('Жим ногами', null),
        ('Приседания со штангой', null),
        ('Выпады на месте', null),
        ('Сгибание ног', 1),
        ('Разгибание ног', 1),
        ('Махи рук в стороны', 2),
        ('Икры сидя / стоя (чередовать)', 2),
      ],
    };
  }

  Map<int, List<(String name, int? group)>> _femaleExerciseDefaults() {
    return <int, List<(String name, int? group)>>{
      0: [
        ('Тяга рычажного блока обратным хватом', null),
        ('Тяга нижнего блока верхним хватом', null),
        ('Тяга гантелей лёжа на скамье', null),
        ('Сгибание на бицепс лёжа на скамье', null),
        ('Поясница', null),
      ],
      1: [
        ('Становая тяга', null),
        ('Выпады на месте', null),
        ('Кик-беки', null),
        ('Разведение в тренажёре', null),
      ],
      2: [
        ('Жим в тренажёре', null),
        ('Жим штанги лёжа', null),
        ('Пуловер', null),
        ('Плечи сидя/стоя (чередовать)', null),
        ('Разгибание рук (классика)', null),
      ],
      3: [
        ('Выпады в кроссовере', null),
        ('Приседания со степа', null),
        ('Мёртвая тяга', null),
        ('Сведение ног', null),
      ],
      4: [
        ('Подтягивания', null),
        ('Тяга нижнего блока параллельным хватом', null),
        ('Пуловер', null),
        ('Подъём рук с супинацией', null),
        ('Поясница', 1),
        ('Разведение рук', 1),
      ],
      5: [
        ('Ягодичный мостик + резинка', null),
        ('Болгарские выпады', null),
        ('Мёртвая тяга', null),
        ('Ягодичный суперсет', null),
      ],
      6: [
        ('Жим штанги под углом', null),
        ('Жим в хамере', null),
        ('Бабочка', null),
        ('Супермен', null),
        ('Плечи', null),
      ],
      7: [
        ('Жим ногами', null),
        ('Разгибание ног', 1),
        ('Стульчик', 1),
        ('Сгибание лёжа', null),
        ('Икры', 2),
        ('Разведения рук', 2),
      ],
    };
  }

  Future<void> _ensureMaleDefaultsPatched() async {
    if (_maleDefaultsPatched) return;

    final maleFirst =
        await (select(workoutTemplates)
              ..where((t) => t.gender.equals('М') & t.idx.equals(0))
              ..limit(1))
            .getSingleOrNull();

    final needsPatch =
        maleFirst == null || !maleFirst.title.startsWith('День 1 • Спина');

    if (!needsPatch) {
      _maleDefaultsPatched = true;
      return;
    }

    final templates = _maleTemplateDefaults();
    await transaction(() async {
      final existingMale = await (select(
        workoutTemplates,
      )..where((t) => t.gender.equals('М'))).get();
      final existingByIdx = {for (final t in existingMale) t.idx: t};

      for (final t in templates) {
        final idx = t.idx.value;
        final existing = existingByIdx[idx];

        if (existing == null) {
          await into(workoutTemplates).insert(t);
          continue;
        }

        await (update(
          workoutTemplates,
        )..where((x) => x.id.equals(existing.id))).write(
          WorkoutTemplatesCompanion(
            gender: Value(t.gender.value),
            idx: Value(t.idx.value),
            label: Value(t.label.value),
            title: Value(t.title.value),
          ),
        );
      }
    });

    final maleRows = await (select(
      workoutTemplates,
    )..where((t) => t.gender.equals('М'))).get();

    final maleByIdx = {for (final t in maleRows) t.idx: t};
    final exerciseDefaults = _maleExerciseDefaults();

    await transaction(() async {
      for (final entry in maleByIdx.entries) {
        final template = entry.value;
        final list = exerciseDefaults[entry.key] ?? const <(String, int?)>[];

        await (delete(
          workoutTemplateExercises,
        )..where((e) => e.templateId.equals(template.id))).go();

        for (var i = 0; i < list.length; i++) {
          final item = list[i];
          await into(workoutTemplateExercises).insert(
            WorkoutTemplateExercisesCompanion.insert(
              templateId: template.id,
              orderIndex: i,
              groupId: item.$2 == null ? const Value.absent() : Value(item.$2!),
              name: item.$1,
            ),
          );
        }
      }
    });

    _maleDefaultsPatched = true;
  }

  Future<void> _ensureFemaleDefaultsPatched() async {
    if (_femaleDefaultsPatched) return;

    final femaleFirst =
        await (select(workoutTemplates)
              ..where((t) => t.gender.equals('Ж') & t.idx.equals(0))
              ..limit(1))
            .getSingleOrNull();

    final needsPatch =
        femaleFirst == null || !femaleFirst.title.startsWith('День 1 • Спина');

    if (!needsPatch) {
      _femaleDefaultsPatched = true;
      return;
    }

    final templates = _femaleTemplateDefaults();

    await transaction(() async {
      final existingRows = await (select(
        workoutTemplates,
      )..where((t) => t.gender.equals('Ж'))).get();
      final existingByIdx = {for (final t in existingRows) t.idx: t};

      for (final t in templates) {
        final idx = t.idx.value;
        final existing = existingByIdx[idx];

        if (existing == null) {
          await into(workoutTemplates).insert(t);
          continue;
        }

        await (update(
          workoutTemplates,
        )..where((x) => x.id.equals(existing.id))).write(
          WorkoutTemplatesCompanion(
            gender: Value(t.gender.value),
            idx: Value(t.idx.value),
            label: Value(t.label.value),
            title: Value(t.title.value),
          ),
        );
      }

      // удаляем лишние старые дни (например idx=8 из старой схемы)
      for (final old in existingRows) {
        if (old.idx < templates.length) continue;
        await (delete(
          workoutTemplateExercises,
        )..where((e) => e.templateId.equals(old.id))).go();
        await (delete(
          workoutTemplates,
        )..where((x) => x.id.equals(old.id))).go();
      }
    });

    final rows = await (select(
      workoutTemplates,
    )..where((t) => t.gender.equals('Ж'))).get();
    final byIdx = {for (final t in rows) t.idx: t};
    final defaults = _femaleExerciseDefaults();

    await transaction(() async {
      for (final entry in byIdx.entries) {
        final template = entry.value;
        final list = defaults[entry.key] ?? const <(String, int?)>[];

        await (delete(
          workoutTemplateExercises,
        )..where((e) => e.templateId.equals(template.id))).go();

        for (var i = 0; i < list.length; i++) {
          final item = list[i];
          await into(workoutTemplateExercises).insert(
            WorkoutTemplateExercisesCompanion.insert(
              templateId: template.id,
              orderIndex: i,
              groupId: item.$2 == null ? const Value.absent() : Value(item.$2!),
              name: item.$1,
            ),
          );
        }
      }
    });

    _femaleDefaultsPatched = true;
  }

  Future<void> _ensureTrialDefaultsPatched() async {
    if (_trialDefaultsPatched) return;
    final existing =
        await (select(workoutTemplates)
              ..where((t) => t.gender.equals('П') & t.idx.equals(0))
              ..limit(1))
            .getSingleOrNull();

    final tpl = _trialTemplateDefaults().first;
    if (existing == null) {
      await into(workoutTemplates).insert(tpl);
    } else {
      await (update(
        workoutTemplates,
      )..where((x) => x.id.equals(existing.id))).write(
        WorkoutTemplatesCompanion(
          gender: Value(tpl.gender.value),
          idx: Value(tpl.idx.value),
          label: Value(tpl.label.value),
          title: Value(tpl.title.value),
        ),
      );
    }

    final row =
        await (select(workoutTemplates)
              ..where((t) => t.gender.equals('П') & t.idx.equals(0))
              ..limit(1))
            .getSingle();

    await (delete(
      workoutTemplateExercises,
    )..where((e) => e.templateId.equals(row.id))).go();

    final plan = _trialExerciseDefaults()[0] ?? const <(String, int?)>[];
    for (var i = 0; i < plan.length; i++) {
      final item = plan[i];
      await into(workoutTemplateExercises).insert(
        WorkoutTemplateExercisesCompanion.insert(
          templateId: row.id,
          orderIndex: i,
          name: item.$1,
          groupId: item.$2 == null ? const Value.absent() : Value(item.$2!),
        ),
      );
    }

    _trialDefaultsPatched = true;
  }

  Future<void> _ensureTemplateDefaultsPatched() async {
    final inFlight = _templateDefaultsPatchFuture;
    if (inFlight != null) {
      await inFlight;
      return;
    }

    final run = () async {
      await _ensureMaleDefaultsPatched();
      await _ensureFemaleDefaultsPatched();
      await _ensureTrialDefaultsPatched();
    }();

    _templateDefaultsPatchFuture = run;
    try {
      await run;
    } finally {
      if (identical(_templateDefaultsPatchFuture, run)) {
        _templateDefaultsPatchFuture = null;
      }
    }
  }

  Future<List<WorkoutTemplate>> getWorkoutTemplatesByGender(
    String gender,
  ) async {
    await _ensureTemplateDefaultsPatched();

    return (select(workoutTemplates)
          ..where((t) => t.gender.equals(gender))
          ..orderBy([(t) => OrderingTerm.asc(t.idx)]))
        .get();
  }

  Future<List<WorkoutTemplateExercise>> getTemplateExercisesByTemplateId(
    int templateId,
  ) {
    return (select(workoutTemplateExercises)
          ..where((e) => e.templateId.equals(templateId))
          ..orderBy([(e) => OrderingTerm.asc(e.orderIndex)]))
        .get();
  }

  Future<void> ensureProgramStateForClient(String clientId) async {
    final c = await getClientById(clientId);
    if (c == null) return;

    final planSize = _parsePlanSize(c.plan);
    if (planSize <= 0) return;

    final existing = await (select(
      clientProgramStates,
    )..where((t) => t.clientId.equals(clientId))).getSingleOrNull();

    if (existing == null) {
      await into(clientProgramStates).insert(
        ClientProgramStatesCompanion.insert(
          clientId: clientId,
          planSize: planSize,
          planInstance: const Value(1),
          completedInPlan: const Value(0),
          cycleStartIndex: const Value(0),
          nextOffset: const Value(0),
          planStart: c.planStart == null
              ? const Value.absent()
              : Value(c.planStart!),
          planEnd: c.planEnd == null ? const Value.absent() : Value(c.planEnd!),
        ),
      );
    }
  }

  Future<ClientProgramState?> getProgramStateForClient(String clientId) {
    return (select(
      clientProgramStates,
    )..where((t) => t.clientId.equals(clientId))).getSingleOrNull();
  }

  Future<void> syncProgramStateFromClient(String clientId) async {
    final c = await getClientById(clientId);
    if (c == null) return;

    final planSize = _parsePlanSize(c.plan);
    if (planSize <= 0) return;

    await ensureProgramStateForClient(clientId);

    final st = await (select(
      clientProgramStates,
    )..where((t) => t.clientId.equals(clientId))).getSingle();

    final startChanged =
        (c.planStart != null && st.planStart != c.planStart) ||
        (c.planStart == null && st.planStart != null);
    final endChanged =
        (c.planEnd != null && st.planEnd != c.planEnd) ||
        (c.planEnd == null && st.planEnd != null);

    // Если ты поменял даты абонемента — считаем это "новый абонемент"
    if (startChanged || endChanged) {
      await (update(
        clientProgramStates,
      )..where((t) => t.clientId.equals(clientId))).write(
        ClientProgramStatesCompanion(
          planSize: Value(planSize),
          planInstance: Value(st.planInstance + 1),
          completedInPlan: const Value(0),
          // nextOffset НЕ сбрасываем — чтобы продолжать цикл
          planStart: c.planStart == null
              ? const Value.absent()
              : Value(c.planStart!),
          planEnd: c.planEnd == null ? const Value.absent() : Value(c.planEnd!),
        ),
      );
    } else if (st.planSize != planSize) {
      // 4 -> 8 (продление) просто меняет лимит
      await (update(clientProgramStates)
            ..where((t) => t.clientId.equals(clientId)))
          .write(ClientProgramStatesCompanion(planSize: Value(planSize)));
    }
  }

  Future<int?> getNextPlannedTemplateIdxForClient(String clientId) async {
    final c = await getClientById(clientId);
    if (c == null) return null;

    final planSize = _parsePlanSize(c.plan);
    if (planSize <= 0) return null;

    await ensureProgramStateForClient(clientId);

    final st = await (select(
      clientProgramStates,
    )..where((t) => t.clientId.equals(clientId))).getSingle();

    final gender = _programTrackByClient(c);
    final cycleLen = _cycleLenByGender(gender);
    final defaultIdx = _mod(st.cycleStartIndex + st.nextOffset, cycleLen);

    final overrides = await _getProgramDayOverrides(
      clientId: clientId,
      planInstance: st.planInstance,
    );

    return overrides[st.completedInPlan] ?? defaultIdx;
  }

  /// Backward-compatible alias for older callers.
  ///
  /// Returns the template index for the next planned workout slot.
  Future<int?> getNextPlannedProgramSlotForClient(String clientId) {
    return getNextPlannedTemplateIdxForClient(clientId);
  }

  Future<WorkoutDayInfo> getWorkoutInfoForClientOnDay({
    required String clientId,
    required DateTime day,
  }) async {
    await _ensureTemplateDefaultsPatched();
    final c = await getClientById(clientId);
    if (c == null) {
      return WorkoutDayInfo(
        hasPlan: false,
        doneToday: false,
        label: '',
        title: '',
        planSize: 0,
        planInstance: 0,
        completedInPlan: 0,
      );
    }

    final planSize = _parsePlanSize(c.plan);
    if (planSize <= 0) {
      return WorkoutDayInfo(
        hasPlan: false,
        doneToday: false,
        label: '',
        title: '',
        planSize: 0,
        planInstance: 0,
        completedInPlan: 0,
      );
    }

    await ensureProgramStateForClient(clientId);

    final st = await (select(
      clientProgramStates,
    )..where((t) => t.clientId.equals(clientId))).getSingle();

    final ds = _dayStart(day);
    final de = _dayEnd(day);

    final done =
        await (select(workoutSessions)
              ..where(
                (t) =>
                    t.clientId.equals(clientId) &
                    t.performedAt.isBiggerOrEqualValue(ds) &
                    t.performedAt.isSmallerThanValue(de),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.performedAt)])
              ..limit(1))
            .getSingleOrNull();

    final gender = _programTrackByClient(c);

    if (done != null) {
      final t =
          await (select(workoutTemplates)..where(
                (x) =>
                    x.gender.equals(done.gender) &
                    x.idx.equals(done.templateIdx),
              ))
              .getSingle();

      return WorkoutDayInfo(
        hasPlan: true,
        doneToday: true,
        label: t.label,
        title: t.title,
        planSize: st.planSize,
        planInstance: st.planInstance,
        completedInPlan: st.completedInPlan,
      );
    }

    // Следующая по плану
    final cycleLen = _cycleLenByGender(gender);
    final realIdx = _mod(st.cycleStartIndex + st.nextOffset, cycleLen);
    final t =
        await (select(workoutTemplates)
              ..where((x) => x.gender.equals(gender) & x.idx.equals(realIdx)))
            .getSingle();

    return WorkoutDayInfo(
      hasPlan: true,
      doneToday: false,
      label: t.label,
      title: t.title,
      planSize: st.planSize,
      planInstance: st.planInstance,
      completedInPlan: st.completedInPlan,
    );
  }

  Future<void> completeWorkoutForClient({
    required String clientId,
    required DateTime when,
  }) async {
    final c = await getClientById(clientId);
    if (c == null) return;

    final planSize = _parsePlanSize(c.plan);
    if (planSize <= 0) return;

    await ensureProgramStateForClient(clientId);

    final st = await (select(
      clientProgramStates,
    )..where((t) => t.clientId.equals(clientId))).getSingle();

    final gender = _programTrackByClient(c);
    final cycleLen = _cycleLenByGender(gender);

    final realIdx = _mod(st.cycleStartIndex + st.nextOffset, cycleLen);

    await into(workoutSessions).insert(
      WorkoutSessionsCompanion.insert(
        clientId: clientId,
        performedAt: when,
        planInstance: st.planInstance,
        gender: gender,
        templateIdx: realIdx,
      ),
    );

    final newCompleted = st.completedInPlan + 1;
    final newNextOffset = _mod(st.nextOffset + 1, cycleLen);

    await (update(
      clientProgramStates,
    )..where((t) => t.clientId.equals(clientId))).write(
      ClientProgramStatesCompanion(
        completedInPlan: Value(newCompleted),
        nextOffset: Value(newNextOffset),
      ),
    );
  }

  Future<void> completeWorkoutForClientWithTemplateIdx({
    required String clientId,
    required DateTime when,
    required int templateIdx, // 0..8
  }) async {
    final c = await getClientById(clientId);
    if (c == null) return;

    final planSize = _parsePlanSize(c.plan);
    if (planSize <= 0) return;

    await ensureProgramStateForClient(clientId);

    final st = await (select(
      clientProgramStates,
    )..where((t) => t.clientId.equals(clientId))).getSingle();

    final gender = _programTrackByClient(c);

    // насколько “впереди” выбранный idx от текущего realIdx
    final cycleLen = _cycleLenByGender(gender);
    final realIdx = _mod(st.cycleStartIndex + st.nextOffset, cycleLen);
    final normalizedTemplateIdx = _mod(templateIdx, cycleLen);
    final k = _mod(normalizedTemplateIdx - realIdx, cycleLen);

    await into(workoutSessions).insert(
      WorkoutSessionsCompanion.insert(
        clientId: clientId,
        performedAt: when,
        planInstance: st.planInstance,
        gender: gender,
        templateIdx: normalizedTemplateIdx, // ✅ выбранный
      ),
    );

    final newCompleted = st.completedInPlan + 1;
    final newNextOffset = _mod(st.nextOffset + k + 1, cycleLen);

    await (update(
      clientProgramStates,
    )..where((t) => t.clientId.equals(clientId))).write(
      ClientProgramStatesCompanion(
        completedInPlan: Value(newCompleted),
        nextOffset: Value(newNextOffset),
      ),
    );
  }

  Future<void> _seedWorkoutTemplateExercises() async {
    final existing = await (select(workoutTemplateExercises).get());
    if (existing.isNotEmpty) return;

    final templates = await (select(workoutTemplates).get());

    final maleByIdx = _maleExerciseDefaults();
    final femaleByIdx = _femaleExerciseDefaults();
    final trialByIdx = _trialExerciseDefaults();

    final rows = <WorkoutTemplateExercisesCompanion>[];

    for (final t in templates) {
      final plan = switch (t.gender) {
        'М' => maleByIdx[t.idx],
        'Ж' => femaleByIdx[t.idx],
        'П' => trialByIdx[t.idx],
        _ => null,
      };

      for (var i = 0; i < (plan?.length ?? 0); i++) {
        final item = plan![i];
        rows.add(
          WorkoutTemplateExercisesCompanion.insert(
            templateId: t.id,
            orderIndex: i,
            groupId: item.$2 == null ? const Value.absent() : Value(item.$2!),
            name: item.$1,
          ),
        );
      }
    }

    await batch((b) => b.insertAll(workoutTemplateExercises, rows));
  }

  Future<bool> toggleWorkoutForClientOnDay({
    required String clientId,
    required DateTime day,
  }) async {
    final c = await getClientById(clientId);
    if (c == null) return false;

    final planSize = _parsePlanSize(c.plan);
    if (planSize <= 0) return false;

    await ensureProgramStateForClient(clientId);

    final st = await (select(
      clientProgramStates,
    )..where((t) => t.clientId.equals(clientId))).getSingle();

    final gender = _programTrackByClient(c);
    final cycleLen = _cycleLenByGender(gender);

    final ds = _dayStart(day);
    final de = _dayEnd(day);

    final existing =
        await (select(workoutSessions)
              ..where(
                (t) =>
                    t.clientId.equals(clientId) &
                    t.performedAt.isBiggerOrEqualValue(ds) &
                    t.performedAt.isSmallerThanValue(de),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.performedAt)])
              ..limit(1))
            .getSingleOrNull();

    // === 1) Если уже выполнено сегодня — ОТМЕНЯЕМ (delete + откат state)
    if (existing != null) {
      // 1) удаляем результаты этой тренировки
      await (delete(
        workoutExerciseResults,
      )..where((r) => r.sessionId.equals(existing.id))).go();

      // 2) удаляем факт тренировки
      await (delete(
        workoutSessions,
      )..where((t) => t.id.equals(existing.id))).go();

      // 3) откатываем состояние
      final newCompleted = st.completedInPlan > 0 ? st.completedInPlan - 1 : 0;
      final newNextOffset = _mod(st.nextOffset - 1, cycleLen);

      await (update(
        clientProgramStates,
      )..where((t) => t.clientId.equals(clientId))).write(
        ClientProgramStatesCompanion(
          completedInPlan: Value(newCompleted),
          nextOffset: Value(newNextOffset),
        ),
      );

      return false;
    }

    // === 2) Если не выполнено — ВЫПОЛНЯЕМ

    // отмечаем "середину дня"
    final when = DateTime(day.year, day.month, day.day, 12, 0);

    await completeWorkoutForClient(clientId: clientId, when: when);
    return true; // теперь выполнено
  }

  Future<bool> toggleWorkoutForClientOnDayWithTemplateIdx({
    required String clientId,
    required DateTime day,
    required int templateIdx,
  }) async {
    final c = await getClientById(clientId);
    if (c == null) return false;
    await ensureProgramStateForClient(clientId);

    final st = await (select(
      clientProgramStates,
    )..where((t) => t.clientId.equals(clientId))).getSingleOrNull();

    if (st == null) return false;

    final gender = _programTrackByClient(c);
    final cycleLen = _cycleLenByGender(gender);

    final ds = _dayStart(day);
    final de = _dayEnd(day);

    final existing =
        await (select(workoutSessions)
              ..where(
                (t) =>
                    t.clientId.equals(clientId) &
                    t.planInstance.equals(st.planInstance) &
                    t.templateIdx.equals(templateIdx) &
                    t.performedAt.isBiggerOrEqualValue(ds) &
                    t.performedAt.isSmallerThanValue(de),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.performedAt)])
              ..limit(1))
            .getSingleOrNull();

    if (existing != null) {
      await (delete(
        workoutExerciseResults,
      )..where((r) => r.sessionId.equals(existing.id))).go();

      await (delete(
        workoutSessions,
      )..where((t) => t.id.equals(existing.id))).go();

      final newCompleted = st.completedInPlan > 0 ? st.completedInPlan - 1 : 0;
      final newNextOffset = _mod(st.nextOffset - 1, cycleLen);

      await (update(
        clientProgramStates,
      )..where((t) => t.clientId.equals(clientId))).write(
        ClientProgramStatesCompanion(
          completedInPlan: Value(newCompleted),
          nextOffset: Value(newNextOffset),
        ),
      );

      return false;
    }

    await completeWorkoutForClientWithTemplateIdx(
      clientId: clientId,
      when: DateTime(day.year, day.month, day.day, 12, 0),
      templateIdx: templateIdx,
    );

    return true;
  }

  Future<bool> toggleWorkoutForClientAtAbsoluteIndex({
    required String clientId,
    required int absoluteIndex,
    required int templateIdx,
    required DateTime when,
  }) async {
    final c = await getClientById(clientId);
    if (c == null) return false;

    await ensureProgramStateForClient(clientId);
    final st = await (select(
      clientProgramStates,
    )..where((t) => t.clientId.equals(clientId))).getSingleOrNull();
    if (st == null) return false;

    final gender = _programTrackByClient(c);
    final cycleLen = _cycleLenByGender(gender);

    final sessions =
        await (select(workoutSessions)
              ..where(
                (t) =>
                    t.clientId.equals(clientId) &
                    t.planInstance.equals(st.planInstance),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.performedAt)]))
            .get();

    final existing = (absoluteIndex >= 0 && absoluteIndex < sessions.length)
        ? sessions[absoluteIndex]
        : null;

    if (existing != null) {
      await (delete(
        workoutExerciseResults,
      )..where((r) => r.sessionId.equals(existing.id))).go();

      await (delete(
        workoutSessions,
      )..where((t) => t.id.equals(existing.id))).go();

      final newCompleted = st.completedInPlan > 0 ? st.completedInPlan - 1 : 0;
      final newNextOffset = _mod(st.nextOffset - 1, cycleLen);

      await (update(
        clientProgramStates,
      )..where((t) => t.clientId.equals(clientId))).write(
        ClientProgramStatesCompanion(
          completedInPlan: Value(newCompleted),
          nextOffset: Value(newNextOffset),
        ),
      );

      return false;
    }

    await completeWorkoutForClientWithTemplateIdx(
      clientId: clientId,
      when: when,
      templateIdx: templateIdx,
    );

    return true;
  }

  Future<
    (WorkoutDayInfo info, int? sessionId, List<WorkoutExerciseVm> exercises)
  >
  getWorkoutDetailsForClientOnDay({
    required String clientId,
    required DateTime day,
  }) async {
    await _ensureTemplateDefaultsPatched();
    final info = await getWorkoutInfoForClientOnDay(
      clientId: clientId,
      day: day,
    );
    if (!info.hasPlan) return (info, null, <WorkoutExerciseVm>[]);

    // Если уже выполнено — найдём sessionId и подгрузим результаты
    final ds = _dayStart(day);
    final de = _dayEnd(day);

    final sess =
        await (select(workoutSessions)
              ..where(
                (t) =>
                    t.clientId.equals(clientId) &
                    t.performedAt.isBiggerOrEqualValue(ds) &
                    t.performedAt.isSmallerThanValue(de),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.performedAt)])
              ..limit(1))
            .getSingleOrNull();

    final c = await getClientById(clientId);
    String gender = c == null ? 'М' : _programTrackByClient(c);
    final cycleLen = _cycleLenByGender(gender);

    // Определяем какой templateIdx показываем:
    // - если выполнено: берём из sess
    // - иначе: берём "следующую" из state
    int templateIdx;
    if (sess != null) {
      templateIdx = sess.templateIdx;
      gender = sess.gender;
    } else {
      final st = await (select(
        clientProgramStates,
      )..where((t) => t.clientId.equals(clientId))).getSingle();
      templateIdx = _mod(st.cycleStartIndex + st.nextOffset, cycleLen);
    }

    final t =
        await (select(workoutTemplates)..where(
              (x) => x.gender.equals(gender) & x.idx.equals(templateIdx),
            ))
            .getSingle();

    final ex = await _getEffectiveExercisesForClientTemplate(
      clientId: clientId,
      templateId: t.id,
    );

    // результаты (если есть session)
    Map<int, (double? kg, int? reps)> resMap = {};

    if (sess != null) {
      final res = await (select(
        workoutExerciseResults,
      )..where((r) => r.sessionId.equals(sess.id))).get();

      resMap = {
        for (final r in res) r.templateExerciseId: (r.lastWeightKg, r.lastReps),
      };
    }
    final overrideRows = await (select(
      clientTemplateExerciseOverrides,
    )..where((o) => o.clientId.equals(clientId))).get();

    final overrideMap = {
      for (final o in overrideRows) o.templateExerciseId: o.supersetGroup,
    };

    final list = ex.map((e) {
      final rr = resMap[e.id]; // (kg, reps)
      final sg = overrideMap[e.id]; // supersetGroup (для клиента)

      return WorkoutExerciseVm(
        templateExerciseId: e.id,

        // ✅ нужно для toggle супerset со следующим
        templateId: e.templateId,
        orderIndex: e.orderIndex,

        // ✅ суперсет берём ТОЛЬКО из overrides
        supersetGroup: sg,

        name: e.name,
        lastWeightKg: rr?.$1,
        lastReps: rr?.$2,
      );
    }).toList();

    return (info, sess?.id, list);
  }

  Future<
    (WorkoutDayInfo info, int? sessionId, List<WorkoutExerciseVm> exercises)
  >
  getWorkoutDetailsForClientOnDayForcedTemplateIdx({
    required String clientId,
    required DateTime day,
    required int templateIdx,
  }) async {
    await _ensureTemplateDefaultsPatched();
    final c = await getClientById(clientId);
    if (c == null) {
      return (
        WorkoutDayInfo(
          hasPlan: false,
          doneToday: false,
          label: '',
          title: '',
          planSize: 0,
          planInstance: 0,
          completedInPlan: 0,
        ),
        null,
        <WorkoutExerciseVm>[],
      );
    }

    final gender = _programTrackByClient(c);

    final ds = _dayStart(day);
    final de = _dayEnd(day);

    final st = await (select(
      clientProgramStates,
    )..where((x) => x.clientId.equals(clientId))).getSingle();

    final sess =
        await (select(workoutSessions)
              ..where(
                (t) =>
                    t.clientId.equals(clientId) &
                    t.planInstance.equals(st.planInstance) &
                    t.templateIdx.equals(templateIdx) & // ✅ вот это ключевое
                    t.performedAt.isBiggerOrEqualValue(ds) &
                    t.performedAt.isSmallerThanValue(de),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.performedAt)])
              ..limit(1))
            .getSingleOrNull();

    // инфа по выбранному templateIdx
    final t =
        await (select(workoutTemplates)..where(
              (x) => x.gender.equals(gender) & x.idx.equals(templateIdx),
            ))
            .getSingle();

    final info = WorkoutDayInfo(
      hasPlan: true,
      doneToday: sess != null,
      label: t.label,
      title: t.title,
      planSize: st.planSize,
      planInstance: st.planInstance,
      completedInPlan: st.completedInPlan,
    );

    // берём упражнения + последние значения из истории (preview)
    final preview = await getWorkoutPreviewForClient(
      clientId: clientId,
      gender: gender,
      templateIdx: templateIdx,
    );

    // если на этот день уже есть session — поверх preview подставим результаты именно этой session
    if (sess != null) {
      final resRows = await (select(
        workoutExerciseResults,
      )..where((r) => r.sessionId.equals(sess.id))).get();

      final resMap = {
        for (final r in resRows)
          r.templateExerciseId: (r.lastWeightKg, r.lastReps),
      };

      final list = preview.map((e) {
        final rr = resMap[e.templateExerciseId];
        if (rr == null) return e;
        return WorkoutExerciseVm(
          templateExerciseId: e.templateExerciseId,
          templateId: e.templateId,
          orderIndex: e.orderIndex,
          supersetGroup: e.supersetGroup,
          name: e.name,
          lastWeightKg: rr.$1,
          lastReps: rr.$2,
        );
      }).toList();

      return (info, sess.id, list);
    }

    return (info, null, preview);
  }

  Future<
    (WorkoutDayInfo info, int? sessionId, List<WorkoutExerciseVm> exercises)
  >
  getWorkoutDetailsForClientProgramSlot({
    required String clientId,
    required int absoluteIndex,
    required int templateIdx,
  }) async {
    await _ensureTemplateDefaultsPatched();

    final c = await getClientById(clientId);
    if (c == null) {
      return (
        WorkoutDayInfo(
          hasPlan: false,
          doneToday: false,
          label: '',
          title: '',
          planSize: 0,
          planInstance: 0,
          completedInPlan: 0,
        ),
        null,
        <WorkoutExerciseVm>[],
      );
    }

    await ensureProgramStateForClient(clientId);

    final st = await (select(
      clientProgramStates,
    )..where((x) => x.clientId.equals(clientId))).getSingle();

    final gender = _programTrackByClient(c);
    final sessions =
        await (select(workoutSessions)
              ..where(
                (t) =>
                    t.clientId.equals(clientId) &
                    t.planInstance.equals(st.planInstance),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.performedAt)]))
            .get();

    final sess = (absoluteIndex >= 0 && absoluteIndex < sessions.length)
        ? sessions[absoluteIndex]
        : null;

    final overrides = await _getProgramDayOverrides(
      clientId: clientId,
      planInstance: st.planInstance,
    );

    final resolvedTemplateIdx =
        sess?.templateIdx ?? overrides[absoluteIndex] ?? templateIdx;

    final titleRow =
        await (select(workoutTemplates)..where(
              (x) =>
                  x.gender.equals(gender) & x.idx.equals(resolvedTemplateIdx),
            ))
            .getSingle();

    final info = WorkoutDayInfo(
      hasPlan: true,
      doneToday: sess != null,
      label: titleRow.label,
      title: titleRow.title,
      planSize: st.planSize,
      planInstance: st.planInstance,
      completedInPlan: st.completedInPlan,
    );

    final preview = await getWorkoutPreviewForClient(
      clientId: clientId,
      gender: gender,
      templateIdx: resolvedTemplateIdx,
    );

    if (sess == null) {
      return (info, null, preview);
    }

    final resRows = await (select(
      workoutExerciseResults,
    )..where((r) => r.sessionId.equals(sess.id))).get();

    final resMap = {
      for (final r in resRows)
        r.templateExerciseId: (r.lastWeightKg, r.lastReps),
    };

    final list = preview.map((e) {
      final rr = resMap[e.templateExerciseId];
      if (rr == null) return e;
      return WorkoutExerciseVm(
        templateExerciseId: e.templateExerciseId,
        templateId: e.templateId,
        orderIndex: e.orderIndex,
        supersetGroup: e.supersetGroup,
        name: e.name,
        lastWeightKg: rr.$1,
        lastReps: rr.$2,
      );
    }).toList();

    return (info, sess.id, list);
  }

  Future<List<WorkoutExerciseVm>> getWorkoutPreviewForClient({
    required String clientId,
    required String gender, // 'М' / 'Ж'
    required int templateIdx, // 0..8
  }) async {
    await _ensureTemplateDefaultsPatched();
    // template по (gender + idx)
    final t =
        await (select(workoutTemplates)..where(
              (x) => x.gender.equals(gender) & x.idx.equals(templateIdx),
            ))
            .getSingle();

    // упражнения шаблона (с учётом локальных правок клиента)
    final ex = await _getEffectiveExercisesForClientTemplate(
      clientId: clientId,
      templateId: t.id,
    );

    // overrides (суперсеты) для клиента
    final overrideRows = await (select(
      clientTemplateExerciseOverrides,
    )..where((o) => o.clientId.equals(clientId))).get();

    final overrideMap = {
      for (final o in overrideRows) o.templateExerciseId: o.supersetGroup,
    };

    // ✅ Берём ПОСЛЕДНИЙ результат из истории для каждого упражнения этого шаблона
    final exIds = ex.map((e) => e.id).toList();
    Map<int, (double? kg, int? reps)> lastMap = {};

    if (exIds.isNotEmpty) {
      final q =
          select(workoutExerciseResults).join([
              innerJoin(
                workoutSessions,
                workoutSessions.id.equalsExp(workoutExerciseResults.sessionId),
              ),
            ])
            ..where(
              workoutSessions.clientId.equals(clientId) &
                  workoutExerciseResults.templateExerciseId.isIn(exIds),
            )
            ..orderBy([OrderingTerm.desc(workoutSessions.performedAt)]);

      final rows = await q.get();

      // rows уже отсортированы по дате DESC — берём первый попавшийся на каждый templateExerciseId
      for (final r in rows) {
        final res = r.readTable(workoutExerciseResults);
        if (lastMap.containsKey(res.templateExerciseId)) continue;
        lastMap[res.templateExerciseId] = (res.lastWeightKg, res.lastReps);
      }
    }

    return ex.map((e) {
      final rr = lastMap[e.id]; // (kg, reps)
      final sg = overrideMap[e.id]; // supersetGroup (для клиента)

      return WorkoutExerciseVm(
        templateExerciseId: e.id,
        templateId: e.templateId,
        orderIndex: e.orderIndex,
        name: e.name,
        lastWeightKg: rr?.$1,
        lastReps: rr?.$2,
        supersetGroup: sg,
      );
    }).toList();
  }

  Future<void> saveWorkoutResultsAndMarkDone({
    required String clientId,
    required DateTime day,
    required Map<int, (double? kg, int? reps)> resultsByTemplateExerciseId,
    int? templateIdx,
    int? absoluteIndex,
  }) async {
    await transaction(() async {
      final ds = _dayStart(day);
      final de = _dayEnd(day);
      final st = await (select(
        clientProgramStates,
      )..where((t) => t.clientId.equals(clientId))).getSingleOrNull();

      final activePlanInstance = st?.planInstance;

      WorkoutSession? sess;

      if (absoluteIndex != null && activePlanInstance != null) {
        final sessions =
            await (select(workoutSessions)
                  ..where(
                    (t) =>
                        t.clientId.equals(clientId) &
                        t.planInstance.equals(activePlanInstance),
                  )
                  ..orderBy([(t) => OrderingTerm.asc(t.performedAt)]))
                .get();

        if (absoluteIndex >= 0 && absoluteIndex < sessions.length) {
          sess = sessions[absoluteIndex];
        }
      } else {
        sess =
            await (select(workoutSessions)
                  ..where(
                    (t) =>
                        t.clientId.equals(clientId) &
                        (activePlanInstance == null
                            ? const Constant(true)
                            : t.planInstance.equals(activePlanInstance)) &
                        (templateIdx == null
                            ? const Constant(true)
                            : t.templateIdx.equals(templateIdx)) &
                        t.performedAt.isBiggerOrEqualValue(ds) &
                        t.performedAt.isSmallerThanValue(de),
                  )
                  ..orderBy([(t) => OrderingTerm.desc(t.performedAt)])
                  ..limit(1))
                .getSingleOrNull();
      }

      // если нет — создаём через твою “засчитать тренировку” (она двигает программу)
      if (sess == null) {
        final now = DateTime.now();
        final when = DateTime(
          day.year,
          day.month,
          day.day,
          12,
          0,
          0,
          now.millisecond,
          now.microsecond,
        );

        if (templateIdx == null) {
          await completeWorkoutForClient(clientId: clientId, when: when);
        } else if (absoluteIndex != null) {
          await toggleWorkoutForClientAtAbsoluteIndex(
            clientId: clientId,
            absoluteIndex: absoluteIndex,
            templateIdx: templateIdx,
            when: when,
          );
        } else {
          await completeWorkoutForClientWithTemplateIdx(
            clientId: clientId,
            when: when,
            templateIdx: templateIdx,
          );
        }

        if (activePlanInstance != null && absoluteIndex != null) {
          final sessions =
              await (select(workoutSessions)
                    ..where(
                      (t) =>
                          t.clientId.equals(clientId) &
                          t.planInstance.equals(activePlanInstance),
                    )
                    ..orderBy([(t) => OrderingTerm.asc(t.performedAt)]))
                  .get();
          if (absoluteIndex >= 0 && absoluteIndex < sessions.length) {
            sess = sessions[absoluteIndex];
          }
        } else {
          sess =
              await (select(workoutSessions)
                    ..where(
                      (t) =>
                          t.clientId.equals(clientId) &
                          (activePlanInstance == null
                              ? const Constant(true)
                              : t.planInstance.equals(activePlanInstance)) &
                          (templateIdx == null
                              ? const Constant(true)
                              : t.templateIdx.equals(templateIdx)) &
                          t.performedAt.isBiggerOrEqualValue(ds) &
                          t.performedAt.isSmallerThanValue(de),
                    )
                    ..orderBy([(t) => OrderingTerm.desc(t.performedAt)])
                    ..limit(1))
                  .getSingleOrNull();
        }
      }

      if (sess == null) return;

      // upsert результатов
      for (final entry in resultsByTemplateExerciseId.entries) {
        final exId = entry.key;
        final kg = entry.value.$1;
        final reps = entry.value.$2;

        // если оба пустые — удалим (чтобы не хранить мусор)
        if (kg == null && reps == null) {
          await (delete(workoutExerciseResults)..where(
                (r) =>
                    r.sessionId.equals(sess!.id) &
                    r.templateExerciseId.equals(exId),
              ))
              .go();
          continue;
        }

        final existing =
            await (select(workoutExerciseResults)..where(
                  (r) =>
                      r.sessionId.equals(sess!.id) &
                      r.templateExerciseId.equals(exId),
                ))
                .getSingleOrNull();

        if (existing == null) {
          await into(workoutExerciseResults).insert(
            WorkoutExerciseResultsCompanion.insert(
              sessionId: sess.id,
              templateExerciseId: exId,
              lastWeightKg: kg == null ? const Value.absent() : Value(kg),
              lastReps: reps == null ? const Value.absent() : Value(reps),
            ),
          );
        } else {
          await (update(
            workoutExerciseResults,
          )..where((r) => r.id.equals(existing.id))).write(
            WorkoutExerciseResultsCompanion(
              lastWeightKg: Value(kg),
              lastReps: Value(reps),
            ),
          );
        }
      }
    });

    await clearWorkoutDraftResults(
      clientId: clientId,
      day: day,
      templateIdx: templateIdx,
      absoluteIndex: absoluteIndex,
    );
  }

  Future<void> toggleClientSupersetWithNext({
    required String clientId,
    required int templateId,
    required int templateExerciseId,
  }) async {
    await transaction(() async {
      final exercises = await _getEffectiveExercisesForClientTemplate(
        clientId: clientId,
        templateId: templateId,
      );
      if (exercises.isEmpty) return;

      final currentIndex = exercises.indexWhere(
        (exercise) => exercise.id == templateExerciseId,
      );
      if (currentIndex < 0) return;

      final current = exercises[currentIndex];

      Future<ClientTemplateExerciseOverride?> _ovFor(int effectiveExerciseId) {
        return (select(clientTemplateExerciseOverrides)..where(
              (o) =>
                  o.clientId.equals(clientId) &
                  o.templateExerciseId.equals(effectiveExerciseId),
            ))
            .getSingleOrNull();
      }

      Future<void> _setGroup(int effectiveExerciseId, int? group) async {
        final existing =
            await (select(clientTemplateExerciseOverrides)..where(
                  (o) =>
                      o.clientId.equals(clientId) &
                      o.templateExerciseId.equals(effectiveExerciseId),
                ))
                .getSingleOrNull();

        await into(clientTemplateExerciseOverrides).insertOnConflictUpdate(
          ClientTemplateExerciseOverridesCompanion(
            id: existing == null ? const Value.absent() : Value(existing.id),
            clientId: Value(clientId),
            templateExerciseId: Value(effectiveExerciseId),
            supersetGroup: Value(group),
          ),
        );
      }

      final oa = await _ovFor(current.id);
      final ga = oa?.supersetGroup;

      // ✅ Если упражнение уже в суперсете — снимаем пару (слева или справа), где совпадает group
      if (ga != null) {
        if (currentIndex + 1 < exercises.length) {
          final right = exercises[currentIndex + 1];
          final rightOv = await _ovFor(right.id);
          if (rightOv?.supersetGroup == ga) {
            await _setGroup(current.id, null);
            await _setGroup(right.id, null);
            return;
          }
        }

        if (currentIndex - 1 >= 0) {
          final left = exercises[currentIndex - 1];
          final leftOv = await _ovFor(left.id);
          if (leftOv?.supersetGroup == ga) {
            await _setGroup(left.id, null);
            await _setGroup(current.id, null);
            return;
          }
        }

        await _setGroup(current.id, null);
        return;
      }

      // Если суперсета нет — создаём пару с правым соседом в текущем списке.
      if (currentIndex + 1 >= exercises.length) return;
      final right = exercises[currentIndex + 1];

      final maxRow = await customSelect(
        'SELECT MAX(superset_group) AS m FROM client_template_exercise_overrides WHERE client_id = ?',
        variables: [Variable.withString(clientId)],
        readsFrom: {clientTemplateExerciseOverrides},
      ).getSingle();

      final nextGroup = ((maxRow.data['m'] as int?) ?? 0) + 1;

      await _setGroup(current.id, nextGroup);
      await _setGroup(right.id, nextGroup);
    });
  }

  Future<void> toggleTemplateSupersetWithNext({
    required int templateId,
    required int orderIndex,
  }) async {
    await transaction(() async {
      Future<WorkoutTemplateExercise?> _exAt(int idx) {
        return (select(workoutTemplateExercises)
              ..where(
                (e) =>
                    e.templateId.equals(templateId) & e.orderIndex.equals(idx),
              )
              ..limit(1))
            .getSingleOrNull();
      }

      Future<void> _setGroup(int exId, int? group) async {
        await (update(workoutTemplateExercises)
              ..where((e) => e.id.equals(exId)))
            .write(WorkoutTemplateExercisesCompanion(groupId: Value(group)));
      }

      final a = await _exAt(orderIndex);
      if (a == null) return;

      final ga = a.groupId;
      if (ga != null) {
        final right = await _exAt(orderIndex + 1);
        if (right?.groupId == ga) {
          await _setGroup(a.id, null);
          await _setGroup(right!.id, null);
          return;
        }

        final left = await _exAt(orderIndex - 1);
        if (left?.groupId == ga) {
          await _setGroup(a.id, null);
          await _setGroup(left!.id, null);
          return;
        }

        await _setGroup(a.id, null);
        return;
      }

      final b = await _exAt(orderIndex + 1);
      if (b == null) return;

      final maxRow = await customSelect(
        'SELECT MAX(group_id) AS m FROM ${workoutTemplateExercises.actualTableName} WHERE template_id = ?',
        variables: [Variable.withInt(templateId)],
        readsFrom: {workoutTemplateExercises},
      ).getSingle();

      final nextGroup = ((maxRow.data['m'] as int?) ?? 0) + 1;

      await _setGroup(a.id, nextGroup);
      await _setGroup(b.id, nextGroup);
    });
  }

  Future<int> replaceTemplateExerciseNameByGender({
    required String gender,
    required String oldName,
    required String newName,
  }) async {
    final from = oldName.trim();
    final to = newName.trim();
    if (from.isEmpty || to.isEmpty || from == to) return 0;

    return customUpdate(
      'UPDATE ${workoutTemplateExercises.actualTableName} '
      'SET ${workoutTemplateExercises.name.name} = ? '
      'WHERE ${workoutTemplateExercises.name.name} = ? '
      'AND ${workoutTemplateExercises.templateId.name} IN ('
      'SELECT ${workoutTemplates.id.name} '
      'FROM ${workoutTemplates.actualTableName} '
      'WHERE ${workoutTemplates.gender.name} = ?'
      ')',
      variables: [
        Variable.withString(to),
        Variable.withString(from),
        Variable.withString(gender),
      ],
      updates: {workoutTemplateExercises, workoutTemplates},
    );
  }

  Future<void> renameWorkoutTemplateExercise({
    required int templateExerciseId,
    required String newName,
  }) async {
    final normalized = newName.trim();
    if (normalized.isEmpty) return;

    await (update(workoutTemplateExercises)
          ..where((e) => e.id.equals(templateExerciseId)))
        .write(WorkoutTemplateExercisesCompanion(name: Value(normalized)));
  }

  Future<void> renameWorkoutExerciseForClient({
    required String clientId,
    required int templateExerciseId,
    required String newName,
  }) async {
    final normalized = newName.trim();
    if (normalized.isEmpty) return;

    await _ensureClientExerciseNameOverridesTable();
    await _ensureClientAddedExercisesTable();

    if (templateExerciseId < 0) {
      final addedId = -templateExerciseId;
      await customStatement(
        'UPDATE client_added_exercises SET name = ? WHERE id = ? AND client_id = ?',
        [normalized, addedId, clientId],
      );
      return;
    }

    final base =
        await (select(workoutTemplateExercises)
              ..where((e) => e.id.equals(templateExerciseId))
              ..limit(1))
            .getSingleOrNull();
    if (base == null) return;

    if (base.name.trim() == normalized) {
      await customStatement(
        'DELETE FROM client_exercise_name_overrides WHERE client_id = ? AND template_exercise_id = ?',
        [clientId, templateExerciseId],
      );
      return;
    }

    await customStatement(
      '''
      INSERT INTO client_exercise_name_overrides (client_id, template_exercise_id, custom_name)
      VALUES (?, ?, ?)
      ON CONFLICT(client_id, template_exercise_id)
      DO UPDATE SET custom_name = excluded.custom_name
      ''',
      [clientId, templateExerciseId, normalized],
    );
  }

  Future<void> addWorkoutExerciseForClient({
    required String clientId,
    required int templateId,
    required String name,
  }) async {
    final normalized = name.trim();
    if (normalized.isEmpty) return;

    await _ensureClientAddedExercisesTable();

    final baseMax = await customSelect(
      'SELECT MAX(order_index) AS m FROM ${workoutTemplateExercises.actualTableName} WHERE template_id = ?',
      variables: [Variable.withInt(templateId)],
      readsFrom: {workoutTemplateExercises},
    ).getSingle();

    final addedMax = await customSelect(
      'SELECT MAX(order_index) AS m FROM client_added_exercises WHERE client_id = ? AND template_id = ?',
      variables: [Variable.withString(clientId), Variable.withInt(templateId)],
    ).getSingle();

    final maxOrder = [
      (baseMax.data['m'] as int?) ?? -1,
      (addedMax.data['m'] as int?) ?? -1,
    ].reduce((a, b) => a > b ? a : b);

    await customStatement(
      'INSERT INTO client_added_exercises (client_id, template_id, order_index, name) VALUES (?, ?, ?, ?)',
      [clientId, templateId, maxOrder + 1, normalized],
    );
  }

  Future<void> deleteWorkoutExerciseForClient({
    required String clientId,
    required int templateExerciseId,
  }) async {
    await _ensureClientAddedExercisesTable();
    await _ensureClientHiddenExercisesTable();
    await _ensureClientExerciseNameOverridesTable();

    if (templateExerciseId < 0) {
      final addedId = -templateExerciseId;
      await customStatement(
        'DELETE FROM client_added_exercises WHERE id = ? AND client_id = ?',
        [addedId, clientId],
      );
      await customStatement(
        'DELETE FROM client_template_exercise_overrides WHERE client_id = ? AND template_exercise_id = ?',
        [clientId, templateExerciseId],
      );
      await customStatement(
        'DELETE FROM client_exercise_name_overrides WHERE client_id = ? AND template_exercise_id = ?',
        [clientId, templateExerciseId],
      );
      return;
    }

    final base =
        await (select(workoutTemplateExercises)
              ..where((e) => e.id.equals(templateExerciseId))
              ..limit(1))
            .getSingleOrNull();
    if (base == null) return;

    await customStatement(
      '''
      INSERT INTO client_hidden_exercises (client_id, template_exercise_id)
      VALUES (?, ?)
      ON CONFLICT(client_id, template_exercise_id)
      DO NOTHING
      ''',
      [clientId, templateExerciseId],
    );

    await customStatement(
      'DELETE FROM client_template_exercise_overrides WHERE client_id = ? AND template_exercise_id = ?',
      [clientId, templateExerciseId],
    );
    await customStatement(
      'DELETE FROM client_exercise_name_overrides WHERE client_id = ? AND template_exercise_id = ?',
      [clientId, templateExerciseId],
    );
  }

  Future<int?> getTemplateIdForClientTemplateIdx({
    required String clientId,
    required int templateIdx,
  }) async {
    final c = await getClientById(clientId);
    if (c == null) return null;

    final gender = _programTrackByClient(c);
    final t =
        await (select(workoutTemplates)..where(
              (x) => x.gender.equals(gender) & x.idx.equals(templateIdx),
            ))
            .getSingleOrNull();

    return t?.id;
  }

  Future<void> addWorkoutTemplateExercise({
    required int templateId,
    required String name,
  }) async {
    final normalized = name.trim();
    if (normalized.isEmpty) return;

    final last =
        await (select(workoutTemplateExercises)
              ..where((e) => e.templateId.equals(templateId))
              ..orderBy([(e) => OrderingTerm.desc(e.orderIndex)])
              ..limit(1))
            .getSingleOrNull();

    final nextOrder = (last?.orderIndex ?? -1) + 1;

    await into(workoutTemplateExercises).insert(
      WorkoutTemplateExercisesCompanion.insert(
        templateId: templateId,
        orderIndex: nextOrder,
        name: normalized,
      ),
    );
  }

  Future<void> deleteWorkoutTemplateExercise(int templateExerciseId) async {
    await transaction(() async {
      final row = await (select(
        workoutTemplateExercises,
      )..where((e) => e.id.equals(templateExerciseId))).getSingleOrNull();
      if (row == null) return;

      await (delete(
        clientTemplateExerciseOverrides,
      )..where((o) => o.templateExerciseId.equals(templateExerciseId))).go();

      await (delete(
        workoutExerciseResults,
      )..where((r) => r.templateExerciseId.equals(templateExerciseId))).go();

      await (delete(
        workoutTemplateExercises,
      )..where((e) => e.id.equals(templateExerciseId))).go();

      await customStatement(
        'UPDATE ${workoutTemplateExercises.actualTableName} '
        'SET ${workoutTemplateExercises.orderIndex.name} = ${workoutTemplateExercises.orderIndex.name} - 1 '
        'WHERE ${workoutTemplateExercises.templateId.name} = ? '
        'AND ${workoutTemplateExercises.orderIndex.name} > ?',
        [row.templateId, row.orderIndex],
      );
    });
  }

  Future<List<ProgramSlotVm>> getUpcomingPlannedSlots({
    required String clientId,
    required int fromAbsoluteIndexExclusive,
    required int count,
  }) async {
    await _ensureTemplateDefaultsPatched();
    await ensureProgramStateForClient(clientId);

    final c = await getClientById(clientId);
    final gender = c == null ? 'М' : _programTrackByClient(c);
    final cycleLen = _cycleLenByGender(gender);

    final st = await (select(
      clientProgramStates,
    )..where((t) => t.clientId.equals(clientId))).getSingleOrNull();

    if (st == null || st.planSize <= 0 || count <= 0) {
      return const <ProgramSlotVm>[];
    }

    final overrides = await _getProgramDayOverrides(
      clientId: clientId,
      planInstance: st.planInstance,
    );

    final slots = <ProgramSlotVm>[];
    for (var i = 1; i <= count; i++) {
      final absoluteIndex = fromAbsoluteIndexExclusive + i;
      if (absoluteIndex < st.completedInPlan) continue;

      final defaultIdx = _mod(st.cycleStartIndex + absoluteIndex, cycleLen);
      final templateIdx = overrides[absoluteIndex] ?? defaultIdx;

      slots.add(
        ProgramSlotVm(
          slotIndex: absoluteIndex + 1,
          absoluteIndex: absoluteIndex,
          templateIdx: templateIdx,
        ),
      );
    }

    return slots;
  }

  Future<ProgramOverviewVm> getProgramOverview(String clientId) async {
    await _ensureTemplateDefaultsPatched();
    await ensureProgramStateForClient(clientId);

    final c = await getClientById(clientId);
    String gender = c == null ? 'М' : _programTrackByClient(c);
    final cycleLen = _cycleLenByGender(gender);

    final st = await (select(
      clientProgramStates,
    )..where((t) => t.clientId.equals(clientId))).getSingleOrNull();

    if (st == null || st.planSize <= 0) {
      return ProgramOverviewVm(
        st: ClientProgramState(
          clientId: clientId,
          planSize: 0,
          planInstance: 0,
          completedInPlan: 0,
          cycleStartIndex: 0,
          nextOffset: 0,
          windowStart: 0,
        ),
        slots: const <ProgramSlotVm>[],
      );
    }

    final sessions =
        await (select(workoutSessions)
              ..where(
                (t) =>
                    t.clientId.equals(clientId) &
                    t.planInstance.equals(st.planInstance),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.performedAt)]))
            .get();
    final planSize = st.planSize;
    final completed = st.completedInPlan;
    final bundleStart = (completed ~/ planSize) * planSize;
    final completedInBundle = completed - bundleStart;
    final bundleSessions = sessions.skip(bundleStart).take(planSize).toList();
    final overrides = await _getProgramDayOverrides(
      clientId: clientId,
      planInstance: st.planInstance,
    );

    final slots = <ProgramSlotVm>[];

    for (var k = 0; k < planSize; k++) {
      final absoluteIndex = bundleStart + k;
      final defaultIdx = _mod(st.cycleStartIndex + absoluteIndex, cycleLen);
      final hasSession = k < completedInBundle && k < bundleSessions.length;
      final s = hasSession ? bundleSessions[k] : null;
      final plannedIdx = overrides[absoluteIndex] ?? defaultIdx;

      slots.add(
        ProgramSlotVm(
          slotIndex: k + 1,
          absoluteIndex: absoluteIndex,
          templateIdx: s?.templateIdx ?? plannedIdx,
          performedAt: s?.performedAt,
          sessionId: s?.id,
        ),
      );
    }

    return ProgramOverviewVm(st: st, slots: slots);
  }

  Future<void> shiftClientProgramWindow({
    required String clientId,
    required int delta, // +4 или -4
  }) async {
    await ensureProgramStateForClient(clientId);

    final st = await (select(
      clientProgramStates,
    )..where((t) => t.clientId.equals(clientId))).getSingleOrNull();

    if (st == null || st.planSize != 4) return;

    int mod8(int x) => ((x % 8) + 8) % 8;
    final newStart = mod8(st.windowStart + delta);

    await (update(clientProgramStates)
          ..where((t) => t.clientId.equals(clientId)))
        .write(ClientProgramStatesCompanion(windowStart: Value(newStart)));
  }

  Future<void> shiftClientProgramDays({
    required String clientId,
    required int delta,
  }) async {
    await ensureProgramStateForClient(clientId);

    final st = await (select(
      clientProgramStates,
    )..where((t) => t.clientId.equals(clientId))).getSingleOrNull();

    if (st == null) return;

    final c = await getClientById(clientId);
    final gender = c == null ? 'М' : _programTrackByClient(c);

    final cycleLen = _cycleLenByGender(gender);
    final newStart = _mod(st.cycleStartIndex + delta, cycleLen);

    final overrides = await _getProgramDayOverrides(
      clientId: clientId,
      planInstance: st.planInstance,
    );

    for (final entry in overrides.entries) {
      final shiftedIdx = _mod(entry.value + delta, cycleLen);
      await _setProgramDayOverride(
        clientId: clientId,
        planInstance: st.planInstance,
        absoluteIndex: entry.key,
        templateIdx: shiftedIdx,
      );
    }

    await (update(clientProgramStates)
          ..where((t) => t.clientId.equals(clientId)))
        .write(ClientProgramStatesCompanion(cycleStartIndex: Value(newStart)));
  }

  Future<void> ensureIncomeTables() async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS app_plan_prices (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        plan4 INTEGER NOT NULL,
        plan8 INTEGER NOT NULL,
        plan12 INTEGER NOT NULL
      )
    ''');

    await customStatement('''
      INSERT OR IGNORE INTO app_plan_prices (id, plan4, plan8, plan12)
      VALUES (1, 1800, 2900, 3500)
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS app_expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        happened_at INTEGER NOT NULL,
        amount INTEGER NOT NULL CHECK(amount >= 0),
        category TEXT NOT NULL DEFAULT 'Расход',
        note TEXT
      )
    ''');

    final happenedAtTypeRows = await customSelect(
      "PRAGMA table_info('app_expenses')",
    ).get();

    String? happenedAtType;
    for (final row in happenedAtTypeRows) {
      if (row.data['name'] == 'happened_at') {
        happenedAtType = (row.data['type'] as String?)?.toUpperCase() ?? '';
        break;
      }
    }

    if (happenedAtType != 'INTEGER') {
      await transaction(() async {
        await customStatement('''
          CREATE TABLE IF NOT EXISTS app_expenses_new (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            happened_at INTEGER NOT NULL,
            amount INTEGER NOT NULL CHECK(amount >= 0),
            category TEXT NOT NULL DEFAULT 'Расход',
            note TEXT
          )
        ''');

        await customStatement('''
          INSERT INTO app_expenses_new (id, happened_at, amount, category, note)
          SELECT
            id,
            CASE
              WHEN typeof(happened_at) = 'integer' THEN happened_at
              WHEN typeof(happened_at) = 'real' THEN CAST(happened_at AS INTEGER)
              WHEN typeof(happened_at) = 'text' THEN CAST(strftime('%s', happened_at) AS INTEGER) * 1000
              ELSE CAST(strftime('%s', 'now') AS INTEGER) * 1000
            END,
            amount,
            COALESCE(NULLIF(TRIM(category), ''), 'Расход'),
            note
          FROM app_expenses
        ''');

        await customStatement('DROP TABLE app_expenses');
        await customStatement(
          'ALTER TABLE app_expenses_new RENAME TO app_expenses',
        );
      });
    }
  }

  Future<PlanPricesVm> getPlanPrices() async {
    await ensureIncomeTables();

    final row = await customSelect(
      'SELECT plan4, plan8, plan12 FROM app_plan_prices WHERE id = 1',
    ).getSingle();

    return PlanPricesVm(
      plan4: (row.data['plan4'] as int?) ?? 1800,
      plan8: (row.data['plan8'] as int?) ?? 2900,
      plan12: (row.data['plan12'] as int?) ?? 3500,
    );
  }

  Future<void> savePlanPrices(PlanPricesVm prices) async {
    await ensureIncomeTables();

    await customStatement(
      'UPDATE app_plan_prices SET plan4 = ?, plan8 = ?, plan12 = ? WHERE id = 1',
      [prices.plan4, prices.plan8, prices.plan12],
    );
  }

  (DateTime start, DateTime end) _monthBounds(DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    return (start, end);
  }

  Future<List<IncomeEntryVm>> getIncomeEntriesForMonth(DateTime month) async {
    await ensureIncomeTables();
    final prices = await getPlanPrices();
    final bounds = _monthBounds(month);

    final rows = await customSelect(
      '''
      SELECT name, plan, plan_start
      FROM clients
      WHERE plan IN ('4', '8', '12')
        AND plan_start >= ?
        AND plan_start < ?
      ORDER BY plan_start DESC
      ''',
      variables: [
        Variable.withDateTime(bounds.$1),
        Variable.withDateTime(bounds.$2),
      ],
      readsFrom: {clients},
    ).get();

    return rows
        .map((r) {
          final plan = (r.data['plan'] as String?) ?? '';
          return IncomeEntryVm(
            clientName: (r.data['name'] as String?) ?? 'Клиент',
            plan: plan,
            date: r.read<DateTime>('plan_start'),
            amount: prices.amountForPlan(plan),
          );
        })
        .toList(growable: false);
  }

  Future<List<ExpenseEntryVm>> getExpenseEntriesForMonth(DateTime month) async {
    await ensureIncomeTables();
    final bounds = _monthBounds(month);

    final rows = await customSelect(
      '''
      SELECT id, happened_at, amount, category, note
      FROM app_expenses
      WHERE happened_at >= ?
        AND happened_at < ?
      ORDER BY happened_at DESC, id DESC
      ''',
      variables: [
        Variable.withInt(bounds.$1.millisecondsSinceEpoch),
        Variable.withInt(bounds.$2.millisecondsSinceEpoch),
      ],
    ).get();

    return rows
        .map(
          (r) => ExpenseEntryVm(
            id: -((r.data['id'] as int?) ?? 0),
            date: DateTime.fromMillisecondsSinceEpoch(
              (r.data['happened_at'] as int?) ?? 0,
            ),
            amount: (r.data['amount'] as int?) ?? 0,
            category: (r.data['category'] as String?) ?? 'Расход',
            note: r.data['note'] as String?,
          ),
        )
        .toList(growable: false);
  }

  Future<void> addExpense({
    required DateTime date,
    required int amount,
    required String category,
    String? note,
  }) async {
    await ensureIncomeTables();
    await customStatement(
      'INSERT INTO app_expenses (happened_at, amount, category, note) VALUES (?, ?, ?, ?)',
      [
        date.millisecondsSinceEpoch,
        amount,
        category.trim().isEmpty ? 'Расход' : category.trim(),
        note?.trim().isEmpty == true ? null : note?.trim(),
      ],
    );
  }

  Future<void> deleteExpense(int id) async {
    await ensureIncomeTables();
    await customStatement('DELETE FROM app_expenses WHERE id = ?', [id]);
  }

  Future<List<IncomeMonthSummaryVm>> getIncomeArchive({int limit = 12}) async {
    await ensureIncomeTables();
    final prices = await getPlanPrices();

    final rows = await customSelect(
      '''
      SELECT month_key,
             SUM(income_amount) AS income,
             SUM(expense_amount) AS expenses
      FROM (
        SELECT CASE
                 WHEN typeof(plan_start) = 'integer' AND plan_start > 20000000000
                   THEN strftime('%Y-%m', plan_start / 1000, 'unixepoch', 'localtime')
                 WHEN typeof(plan_start) = 'integer'
                   THEN strftime('%Y-%m', plan_start, 'unixepoch', 'localtime')
                 WHEN typeof(plan_start) = 'real' AND plan_start > 20000000000
                   THEN strftime('%Y-%m', CAST(plan_start AS INTEGER) / 1000, 'unixepoch', 'localtime')
                 WHEN typeof(plan_start) = 'real'
                   THEN strftime('%Y-%m', CAST(plan_start AS INTEGER), 'unixepoch', 'localtime')
                 ELSE strftime('%Y-%m', plan_start)
               END AS month_key,
               CASE plan
                 WHEN '4' THEN ?
                 WHEN '8' THEN ?
                 WHEN '12' THEN ?
                 ELSE 0
               END AS income_amount,
               0 AS expense_amount
        FROM clients
        WHERE plan IN ('4', '8', '12')
          AND plan_start IS NOT NULL

        UNION ALL

        SELECT CASE
                 WHEN typeof(happened_at) = 'integer' AND happened_at > 20000000000
                   THEN strftime('%Y-%m', happened_at / 1000, 'unixepoch', 'localtime')
                 WHEN typeof(happened_at) = 'integer'
                   THEN strftime('%Y-%m', happened_at, 'unixepoch', 'localtime')
                 WHEN typeof(happened_at) = 'real' AND happened_at > 20000000000
                   THEN strftime('%Y-%m', CAST(happened_at AS INTEGER) / 1000, 'unixepoch', 'localtime')
                 WHEN typeof(happened_at) = 'real'
                   THEN strftime('%Y-%m', CAST(happened_at AS INTEGER), 'unixepoch', 'localtime')
                 ELSE strftime('%Y-%m', happened_at)
               END AS month_key,
               0 AS income_amount,
               amount AS expense_amount
        FROM app_expenses
      ) t
      WHERE month_key IS NOT NULL
      GROUP BY month_key
      ORDER BY month_key DESC
      LIMIT ?
      ''',
      variables: [
        Variable.withInt(prices.plan4),
        Variable.withInt(prices.plan8),
        Variable.withInt(prices.plan12),
        Variable.withInt(limit),
      ],
      readsFrom: {clients},
    ).get();

    return rows
        .map((r) {
          final monthKey = (r.data['month_key'] as String?) ?? '';
          final parts = monthKey.split('-');
          final year = parts.isNotEmpty
              ? int.tryParse(parts[0]) ?? DateTime.now().year
              : DateTime.now().year;
          final month = parts.length > 1
              ? int.tryParse(parts[1]) ?? DateTime.now().month
              : DateTime.now().month;

          return IncomeMonthSummaryVm(
            monthStart: DateTime(year, month, 1),
            income: (r.data['income'] as int?) ?? 0,
            expenses: (r.data['expenses'] as int?) ?? 0,
          );
        })
        .toList(growable: false);
  }

  Future<void> ensureContestTables() async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS app_contest_entries (
        event_key TEXT NOT NULL,
        client_id TEXT NOT NULL,
        used_attempts INTEGER NOT NULL DEFAULT 0,
        max_attempts INTEGER NOT NULL DEFAULT 1,
        current_prize TEXT,
        final_prize TEXT,
        finalized_at INTEGER,
        PRIMARY KEY (event_key, client_id)
      )
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS app_contest_prizes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_key TEXT NOT NULL,
        title TEXT NOT NULL,
        weight REAL NOT NULL,
        is_good INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS app_contest_winner_status (
        event_key TEXT NOT NULL,
        client_id TEXT NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0,
        completed_at INTEGER,
        PRIMARY KEY (event_key, client_id)
      )
    ''');
  }

  Future<List<ContestPrizeVm>> getContestPrizes({
    required String eventKey,
  }) async {
    await ensureContestTables();

    final rows = await customSelect(
      '''
      SELECT id, title, weight, is_good, sort_order
      FROM app_contest_prizes
      WHERE event_key = ?
      ORDER BY sort_order ASC, id ASC
      ''',
      variables: [Variable.withString(eventKey)],
    ).get();

    return rows
        .map(
          (r) => ContestPrizeVm(
            id: -((r.data['id'] as int?) ?? 0),
            title: (r.data['title'] as String?) ?? 'Приз',
            weight:
                (r.data['weight'] as double?) ??
                ((r.data['weight'] as num?)?.toDouble() ?? 0),
            isGood: ((r.data['is_good'] as int?) ?? 0) == 1,
            sortOrder: (r.data['sort_order'] as int?) ?? 0,
          ),
        )
        .toList(growable: false);
  }

  Future<void> replaceContestPrizes({
    required String eventKey,
    required List<ContestPrizeVm> prizes,
  }) async {
    await ensureContestTables();

    await transaction(() async {
      await customStatement(
        'DELETE FROM app_contest_prizes WHERE event_key = ?',
        [eventKey],
      );

      for (var i = 0; i < prizes.length; i++) {
        final p = prizes[i];
        await customStatement(
          '''
          INSERT INTO app_contest_prizes (event_key, title, weight, is_good, sort_order)
          VALUES (?, ?, ?, ?, ?)
          ''',
          [eventKey, p.title, p.weight, p.isGood ? 1 : 0, i],
        );
      }
    });
  }

  Future<void> upsertContestPrize({
    required String eventKey,
    int? id,
    required String title,
    required double weight,
    required bool isGood,
    required int sortOrder,
  }) async {
    await ensureContestTables();

    if (id == null || id <= 0) {
      await customStatement(
        '''
        INSERT INTO app_contest_prizes (event_key, title, weight, is_good, sort_order)
        VALUES (?, ?, ?, ?, ?)
        ''',
        [eventKey, title, weight, isGood ? 1 : 0, sortOrder],
      );
      return;
    }

    await customStatement(
      '''
      UPDATE app_contest_prizes
      SET title = ?, weight = ?, is_good = ?, sort_order = ?
      WHERE id = ? AND event_key = ?
      ''',
      [title, weight, isGood ? 1 : 0, sortOrder, id, eventKey],
    );
  }

  Future<void> deleteContestPrize({
    required String eventKey,
    required int id,
  }) async {
    await ensureContestTables();
    await customStatement(
      'DELETE FROM app_contest_prizes WHERE event_key = ? AND id = ?',
      [eventKey, id],
    );
  }

  Future<void> resetContestParticipant({
    required String eventKey,
    required String clientId,
  }) async {
    await ensureContestTables();
    await customStatement(
      'DELETE FROM app_contest_entries WHERE event_key = ? AND client_id = ?',
      [eventKey, clientId],
    );
    await customStatement(
      'DELETE FROM app_contest_winner_status WHERE event_key = ? AND client_id = ?',
      [eventKey, clientId],
    );
  }

  Future<ContestEntryVm?> getContestEntry({
    required String eventKey,
    required String clientId,
  }) async {
    await ensureContestTables();

    final rows = await customSelect(
      '''
      SELECT client_id, used_attempts, max_attempts, current_prize, final_prize, finalized_at
      FROM app_contest_entries
      WHERE event_key = ? AND client_id = ?
      LIMIT 1
      ''',
      variables: [Variable.withString(eventKey), Variable.withString(clientId)],
      readsFrom: {clients},
    ).get();

    if (rows.isEmpty) return null;
    final row = rows.first;
    final finalizedAtMs = row.data['finalized_at'] as int?;

    return ContestEntryVm(
      clientId: (row.data['client_id'] as String?) ?? clientId,
      usedAttempts: (row.data['used_attempts'] as int?) ?? 0,
      maxAttempts: (row.data['max_attempts'] as int?) ?? 1,
      currentPrize: row.data['current_prize'] as String?,
      finalPrize: row.data['final_prize'] as String?,
      finalizedAt: finalizedAtMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(finalizedAtMs),
    );
  }

  Future<ContestEntryVm> recordContestSpin({
    required String eventKey,
    required String clientId,
    required int maxAttempts,
    required String prize,
  }) async {
    await ensureContestTables();

    await customStatement(
      '''
      INSERT INTO app_contest_entries (event_key, client_id, used_attempts, max_attempts, current_prize)
      VALUES (?, ?, 1, ?, ?)
      ON CONFLICT(event_key, client_id)
      DO UPDATE SET
        used_attempts = used_attempts + 1,
        max_attempts = excluded.max_attempts,
        current_prize = excluded.current_prize
      ''',
      [eventKey, clientId, maxAttempts, prize],
    );

    return (await getContestEntry(eventKey: eventKey, clientId: clientId))!;
  }

  Future<ContestEntryVm> addContestExtraAttempts({
    required String eventKey,
    required String clientId,
    required int delta,
  }) async {
    await ensureContestTables();

    await customStatement(
      '''
      UPDATE app_contest_entries
      SET max_attempts = max_attempts + ?
      WHERE event_key = ? AND client_id = ?
      ''',
      [delta, eventKey, clientId],
    );

    return (await getContestEntry(eventKey: eventKey, clientId: clientId))!;
  }

  Future<ContestEntryVm> finalizeContestPrize({
    required String eventKey,
    required String clientId,
  }) async {
    await ensureContestTables();

    final now = DateTime.now().millisecondsSinceEpoch;
    await customStatement(
      '''
      UPDATE app_contest_entries
      SET final_prize = current_prize,
          finalized_at = ?
      WHERE event_key = ?
        AND client_id = ?
        AND current_prize IS NOT NULL
      ''',
      [now, eventKey, clientId],
    );

    return (await getContestEntry(eventKey: eventKey, clientId: clientId))!;
  }

  Future<void> setContestWinnerCompleted({
    required String eventKey,
    required String clientId,
    required bool isCompleted,
  }) async {
    await ensureContestTables();

    if (!isCompleted) {
      await customStatement(
        'DELETE FROM app_contest_winner_status WHERE event_key = ? AND client_id = ?',
        [eventKey, clientId],
      );
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    await customStatement(
      '''
      INSERT INTO app_contest_winner_status (event_key, client_id, is_completed, completed_at)
      VALUES (?, ?, 1, ?)
      ON CONFLICT(event_key, client_id)
      DO UPDATE SET is_completed = 1, completed_at = excluded.completed_at
      ''',
      [eventKey, clientId, now],
    );
  }

  Future<List<ContestWinnerVm>> getContestWinners({
    required String eventKey,
  }) async {
    await ensureContestTables();

    final rows = await customSelect(
      '''
      SELECT e.client_id, c.name, e.final_prize, e.finalized_at,
             COALESCE(s.is_completed, 0) AS is_completed
      FROM app_contest_entries e
      LEFT JOIN clients c ON c.id = e.client_id
      LEFT JOIN app_contest_winner_status s
        ON s.event_key = e.event_key AND s.client_id = e.client_id
      WHERE e.event_key = ?
        AND e.final_prize IS NOT NULL
      ORDER BY COALESCE(s.is_completed, 0) ASC, e.finalized_at DESC
      ''',
      variables: [Variable.withString(eventKey)],
      readsFrom: {clients},
    ).get();

    return rows
        .map(
          (r) => ContestWinnerVm(
            clientId: (r.data['client_id'] as String?) ?? '',
            clientName: (r.data['name'] as String?) ?? 'Клиент',
            prize: (r.data['final_prize'] as String?) ?? 'Приз',
            finalizedAt: DateTime.fromMillisecondsSinceEpoch(
              (r.data['finalized_at'] as int?) ?? 0,
            ),
            isCompleted: ((r.data['is_completed'] as int?) ?? 0) == 1,
          ),
        )
        .toList(growable: false);
  }

  String _quoteIdent(String ident) => '"${ident.replaceAll('"', '""')}"';

  String _sqlLiteral(Object? value) {
    if (value == null) return 'NULL';
    if (value is num) return value.toString();
    if (value is bool) return value ? '1' : '0';
    final text = value is String ? value : jsonEncode(value);
    return "'${text.replaceAll("'", "''")}'";
  }

  Future<Map<String, dynamic>> buildBackupPayload() async {
    await ensureIncomeTables();
    await ensureContestTables();

    final tables = await customSelect(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name",
    ).get();

    final payload = <String, dynamic>{
      'schemaVersion': schemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'tables': <String, dynamic>{},
    };

    final tablesMap = payload['tables'] as Map<String, dynamic>;

    for (final row in tables) {
      final tableName = (row.data['name'] as String?) ?? '';
      if (tableName.isEmpty) continue;

      final dataRows = await customSelect(
        'SELECT * FROM ${_quoteIdent(tableName)}',
      ).get();

      tablesMap[tableName] = dataRows
          .map((e) => e.data)
          .toList(growable: false);
    }

    return payload;
  }

  Future<void> _ensureAuxTableForBackup(String tableName) async {
    switch (tableName) {
      case 'app_plan_prices':
      case 'app_expenses':
        await ensureIncomeTables();
        return;
      case 'app_contest_entries':
      case 'app_contest_prizes':
      case 'app_contest_winner_status':
        await ensureContestTables();
        return;
      case 'client_program_day_overrides':
        await _ensureProgramDayOverridesTable();
        return;
      case 'client_plan_end_alert_overrides':
        await _ensurePlanEndAlertOverridesTable();
        return;
      case 'client_payment_reminders':
        await _ensureClientPaymentRemindersTable();
        return;
      case 'client_exercise_name_overrides':
        await _ensureClientExerciseNameOverridesTable();
        return;
      case 'client_hidden_exercises':
        await _ensureClientHiddenExercisesTable();
        return;
      case 'client_added_exercises':
        await _ensureClientAddedExercisesTable();
        return;
      case 'app_progress_snapshots':
      case 'app_progress_snapshot_clients':
        await ensureProgressTables();
        return;
      default:
        return;
    }
  }

  Future<void> exportBackupToFile(String filePath) async {
    final payload = await buildBackupPayload();
    final json = const JsonEncoder.withIndent('  ').convert(payload);
    await File(filePath).writeAsString(json);
  }

  Future<bool> _tableExists(String tableName) async {
    final rows = await customSelect(
      "SELECT 1 FROM sqlite_master WHERE type='table' AND name = ? LIMIT 1",
      variables: [Variable.withString(tableName)],
    ).get();
    return rows.isNotEmpty;
  }

  bool _isMissingTableInsertError(Object error, String tableName) {
    final message = error.toString().toLowerCase();
    return message.contains('no such table: $tableName'.toLowerCase());
  }

  Future<void> importBackupPayload(Map<String, dynamic> payload) async {
    await ensureIncomeTables();
    await ensureContestTables();

    final rawTables = payload['tables'];
    if (rawTables is! Map<String, dynamic>) {
      throw const FormatException(
        'Некорректный формат резервной копии: нет tables',
      );
    }
    for (final tableName in rawTables.keys) {
      await _ensureAuxTableForBackup(tableName);
    }

    await transaction(() async {
      await customStatement('PRAGMA foreign_keys = OFF');

      try {
        final existingTables = await customSelect(
          "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name",
        ).get();

        for (final row in existingTables) {
          final tableName = (row.data['name'] as String?) ?? '';
          if (tableName.isEmpty) continue;
          await customStatement('DELETE FROM ${_quoteIdent(tableName)}');
        }
        final sortedNames = rawTables.keys.toList()..sort();
        for (final tableName in sortedNames) {
          await _ensureAuxTableForBackup(tableName);
          if (!await _tableExists(tableName)) {
            continue;
          }
          final rows = rawTables[tableName];
          if (rows is! List) continue;

          var skipTable = false;
          for (final rawRow in rows) {
            if (skipTable) break;
            if (rawRow is! Map) continue;

            final row = rawRow.map((key, value) => MapEntry('$key', value));
            if (row.isEmpty) continue;

            final columns = row.keys.map(_quoteIdent).join(', ');
            final values = row.values.map(_sqlLiteral).join(', ');

            try {
              await customStatement(
                'INSERT OR REPLACE INTO ${_quoteIdent(tableName)} ($columns) VALUES ($values)',
              );
            } catch (error) {
              if (_isMissingTableInsertError(error, tableName)) {
                skipTable = true;
                continue;
              }
              rethrow;
            }
          }
        }
      } finally {
        await customStatement('PRAGMA foreign_keys = ON');
      }
    });
  }

  Future<void> importBackupFromFile(String filePath) async {
    final content = await File(filePath).readAsString();
    final dynamic decoded = jsonDecode(content);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Некорректный формат резервной копии');
    }
    await importBackupPayload(decoded);
  }
}
