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

class AppointmentWithClient {
  final Appointment appointment;
  final Client client;
  AppointmentWithClient(this.appointment, this.client);
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
  final int templateIdx; // 0..8
  final DateTime? performedAt; // null = будущая
  final int? sessionId;

  ProgramSlotVm({
    required this.slotIndex,
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

@DriftDatabase(
  tables: [
    Clients,
    Appointments,
    WorkoutTemplates,
    ClientProgramStates,
    WorkoutSessions,
    WorkoutTemplateExercises,
    WorkoutExerciseResults,
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
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _seedWorkoutTemplates();
      await _seedWorkoutTemplateExercises();
    },

    onUpgrade: (m, from, to) async {
      // Dev-режим: пересоздание таблиц
      await m.deleteTable(workoutExerciseResults.actualTableName);
      await m.deleteTable(workoutTemplateExercises.actualTableName);
      await m.deleteTable(workoutSessions.actualTableName);
      await m.deleteTable(clientProgramStates.actualTableName);
      await m.deleteTable(workoutTemplates.actualTableName);
      await m.deleteTable(appointments.actualTableName);
      await m.deleteTable(clients.actualTableName);
      await m.deleteTable(clientTemplateExerciseOverrides.actualTableName);

      await m.createTable(clients);
      await m.createTable(appointments);
      await m.createTable(workoutTemplates);
      await m.createTable(clientProgramStates);
      await m.createTable(workoutSessions);
      await m.createTable(workoutTemplateExercises);
      await m.createTable(workoutExerciseResults);
      await m.createTable(clientTemplateExerciseOverrides);

      await _seedWorkoutTemplates();
      await _seedWorkoutTemplateExercises();
    },
  );

  // --- Clients ---
  Future<List<Client>> getAllClients() =>
      (select(clients)..orderBy([(t) => OrderingTerm.asc(t.name)])).get();

  Future<Client?> getClientById(String id) =>
      (select(clients)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> upsertClient(ClientsCompanion data) =>
      into(clients).insertOnConflictUpdate(data);

  Future<int> deleteClientById(String id) =>
      (delete(clients)..where((t) => t.id.equals(id))).go();

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

  Future<bool> appointmentExists({
    required String clientId,
    required DateTime startAt,
  }) async {
    final q = select(appointments)
      ..where((t) => t.clientId.equals(clientId) & t.startAt.equals(startAt));
    return (await q.get()).isNotEmpty;
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
  }) {
    final q = customSelect(
      "SELECT date(datetime(CASE WHEN ${clients.planEnd.name} > 20000000000 THEN ${clients.planEnd.name} / 1000 ELSE ${clients.planEnd.name} END, 'unixepoch', 'localtime')) AS d, COUNT(*) AS c "
      'FROM ${clients.actualTableName} '
      'WHERE ${clients.planEnd.name} IS NOT NULL '
      'AND ${clients.planEnd.name} >= ? AND ${clients.planEnd.name} < ? '
      "AND COALESCE(${clients.plan.name}, '') != 'Пробный' "
      'GROUP BY d',
      variables: [Variable<DateTime>(from), Variable<DateTime>(to)],
      readsFrom: {clients},
    );

    return q.watch().map((rows) {
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

    final ex =
        await (select(workoutTemplateExercises)
              ..where((e) => e.templateId.equals(t.id))
              ..orderBy([(e) => OrderingTerm.asc(e.orderIndex)]))
            .get();

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

    // упражнения шаблона
    final ex =
        await (select(workoutTemplateExercises)
              ..where((e) => e.templateId.equals(t.id))
              ..orderBy([(e) => OrderingTerm.asc(e.orderIndex)]))
            .get();

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
  }) async {
    await transaction(() async {
      final ds = _dayStart(day);
      final de = _dayEnd(day);
      final st = await (select(
        clientProgramStates,
      )..where((t) => t.clientId.equals(clientId))).getSingleOrNull();

      final activePlanInstance = st?.planInstance;

      // есть ли уже session на этот день?
      var sess =
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

      // если нет — создаём через твою “засчитать тренировку” (она двигает программу)
      if (sess == null) {
        final when = DateTime(day.year, day.month, day.day, 12, 0);

        if (templateIdx == null) {
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
        } else {
          await completeWorkoutForClientWithTemplateIdx(
            clientId: clientId,
            when: when,
            templateIdx: templateIdx,
          );
        }

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
  }

  Future<void> toggleClientSupersetWithNext({
    required String clientId,
    required int templateId,
    required int orderIndex,
  }) async {
    await transaction(() async {
      Future<WorkoutTemplateExercise?> _exAt(int idx) {
        return (select(workoutTemplateExercises)..where(
              (e) => e.templateId.equals(templateId) & e.orderIndex.equals(idx),
            ))
            .getSingleOrNull();
      }

      Future<ClientTemplateExerciseOverride?> _ovFor(int templateExerciseId) {
        return (select(clientTemplateExerciseOverrides)..where(
              (o) =>
                  o.clientId.equals(clientId) &
                  o.templateExerciseId.equals(templateExerciseId),
            ))
            .getSingleOrNull();
      }

      Future<void> _setGroup(int templateExerciseId, int? group) async {
        final existing =
            await (select(clientTemplateExerciseOverrides)..where(
                  (o) =>
                      o.clientId.equals(clientId) &
                      o.templateExerciseId.equals(templateExerciseId),
                ))
                .getSingleOrNull();

        await into(clientTemplateExerciseOverrides).insertOnConflictUpdate(
          ClientTemplateExerciseOverridesCompanion(
            id: existing == null ? const Value.absent() : Value(existing.id),
            clientId: Value(clientId),
            templateExerciseId: Value(templateExerciseId),
            supersetGroup: Value(group),
          ),
        );
      }

      final a = await _exAt(orderIndex);
      if (a == null) return;

      final oa = await _ovFor(a.id);
      final ga = oa?.supersetGroup;

      // ✅ Если упражнение уже в суперсете — снимаем пару (слева или справа), где совпадает group
      if (ga != null) {
        // пробуем справа
        final b = await _exAt(orderIndex + 1);
        if (b != null) {
          final ob = await _ovFor(b.id);
          if (ob?.supersetGroup == ga) {
            await _setGroup(a.id, null);
            await _setGroup(b.id, null);
            return;
          }
        }

        // пробуем слева
        final p = await _exAt(orderIndex - 1);
        if (p != null) {
          final op = await _ovFor(p.id);
          if (op?.supersetGroup == ga) {
            await _setGroup(p.id, null);
            await _setGroup(a.id, null);
            return;
          }
        }

        // если состояние сломано — чистим хотя бы текущий
        await _setGroup(a.id, null);
        return;
      }

      // ✅ Если суперсета нет — создаём с правым соседом
      final b = await _exAt(orderIndex + 1);
      if (b == null) return;

      final maxRow = await customSelect(
        'SELECT MAX(superset_group) AS m FROM client_template_exercise_overrides WHERE client_id = ?',
        variables: [Variable.withString(clientId)],
        readsFrom: {clientTemplateExerciseOverrides},
      ).getSingle();

      final nextGroup = ((maxRow.data['m'] as int?) ?? 0) + 1;

      await _setGroup(a.id, nextGroup);
      await _setGroup(b.id, nextGroup);
    });
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

    final slots = <ProgramSlotVm>[];

    for (var k = 0; k < planSize; k++) {
      final absoluteIndex =
          bundleStart + (st.planSize == 4 ? st.windowStart : 0) + k;
      final idx = _mod(st.cycleStartIndex + absoluteIndex, cycleLen);
      final hasSession =
          k < completedInBundle && absoluteIndex < sessions.length;
      final s = hasSession ? sessions[absoluteIndex] : null;

      slots.add(
        ProgramSlotVm(
          slotIndex: k + 1,
          templateIdx: s?.templateIdx ?? idx,
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
        happened_at TEXT NOT NULL,
        amount INTEGER NOT NULL CHECK(amount >= 0),
        category TEXT NOT NULL DEFAULT 'Расход',
        note TEXT
      )
    ''');
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
        Variable.withDateTime(bounds.$1),
        Variable.withDateTime(bounds.$2),
      ],
    ).get();

    return rows
        .map(
          (r) => ExpenseEntryVm(
            id: (r.data['id'] as int?) ?? 0,
            date: r.read<DateTime>('happened_at'),
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
        date,
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
        SELECT strftime('%Y-%m', plan_start) AS month_key,
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

        SELECT strftime('%Y-%m', happened_at) AS month_key,
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
}
