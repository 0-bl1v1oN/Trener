import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:uuid/uuid.dart';

import '../sync/sync_models.dart';
import '../sync/sync_client_payload.dart';
import '../sync/schedule_sync_payload.dart';
import '../sync/workout_sync_payload.dart';

part 'app_db.g.dart';

class Clients extends Table {
  TextColumn get id => text()();
  TextColumn get externalId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get status => text().withDefault(const Constant('ACTIVE'))();

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
  // Явная клиентская замена базового slot на упражнение из каталога.
  IntColumn get exerciseIdentityId => integer().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {clientId, templateExerciseId},
  ];
}

class WorkoutSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get externalId => text().nullable()();

  TextColumn get clientId => text()();
  DateTimeColumn get performedAt => dateTime()();

  IntColumn get planInstance => integer()();
  IntColumn get absoluteIndex => integer().nullable()();

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
  // Новый источник истины для новых и отредактированных slot.
  // nullable только для совместимости с legacy backup до backfill.
  IntColumn get exerciseIdentityId => integer().nullable()();

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
  IntColumn get exerciseIdentityId => integer().nullable()();
  TextColumn get exerciseNameSnapshot => text().nullable()();

  RealColumn get lastWeightKg => real().nullable()();
  IntColumn get lastReps => integer().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {sessionId, templateExerciseId},
  ];
}

class ExerciseIdentities extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get externalId => text()();
  TextColumn get canonicalName => text().withDefault(const Constant(''))();
  TextColumn get normalizedName => text().withDefault(const Constant(''))();
  TextColumn get status => text().withDefault(const Constant('ACTIVE'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get archivedAt => dateTime().nullable()();
  // Non-null only for a legacy identity merged into another catalog row.
  IntColumn get mergedIntoIdentityId => integer().nullable()();
}

class ExerciseIdentityAliases extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get oldExternalId => text()();
  IntColumn get canonicalIdentityId => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {oldExternalId},
  ];
}

class ExerciseIdentityBindings extends Table {
  IntColumn get id => integer().autoIncrement()();

  // null = общая привязка базового template exercise.
  // Для CLIENT_ADDED и будущей клиентской замены template exercise хранится id клиента.
  TextColumn get clientId => text().nullable()();
  TextColumn get sourceType => text()(); // TEMPLATE / CLIENT_ADDED
  IntColumn get sourceId =>
      integer()(); // всегда положительный локальный id источника
  IntColumn get identityId => integer()(); // -> ExerciseIdentities.id

  BoolColumn get isCurrent => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get retiredAt => dateTime().nullable()();
}

class AppSettings extends Table {
  TextColumn get settingKey => text()();
  TextColumn get settingValue => text()();

  @override
  Set<Column> get primaryKey => {settingKey};
}

@DataClassName('SyncQueueEntry')
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text()();
  TextColumn get entityExternalId => text()();
  TextColumn get operation => text()();
  TextColumn get payload => text()();
  TextColumn get status =>
      text().withDefault(const Constant(SyncQueueStatuses.pending))();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {entityType, entityExternalId, operation},
  ];
}

@DataClassName('SyncLogEntry')
class SyncLog extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  TextColumn get entityType => text()();
  TextColumn get entityExternalId => text()();
  TextColumn get result => text()();
  IntColumn get httpStatus => integer().nullable()();
  TextColumn get message => text().nullable()();
  IntColumn get attemptNumber => integer()();
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

class ClientAppointmentsWeekRange {
  const ClientAppointmentsWeekRange({
    required this.fromInclusive,
    required this.toExclusive,
  });

  final DateTime fromInclusive;
  final DateTime toExclusive;
}

ClientAppointmentsWeekRange clientAppointmentsWeekRange(DateTime now) {
  final day = DateTime(now.year, now.month, now.day);
  final monday = day.weekday == DateTime.sunday
      ? day.add(const Duration(days: 1))
      : day.subtract(Duration(days: day.weekday - DateTime.monday));
  return ClientAppointmentsWeekRange(
    fromInclusive: monday,
    toExclusive: DateTime(monday.year, monday.month, monday.day + 6),
  );
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

class PendingWorkoutSyncClientVm {
  const PendingWorkoutSyncClientVm({
    required this.clientId,
    required this.name,
    required this.pendingWorkoutCount,
  });

  final String clientId;
  final String name;
  final int pendingWorkoutCount;
}

class PendingWorkoutSyncTaskVm {
  const PendingWorkoutSyncTaskVm({
    required this.taskId,
    required this.workoutExternalId,
    required this.performedAt,
    required this.dayLabel,
    required this.dayTitle,
    required this.exerciseCount,
  });

  final int taskId;
  final String workoutExternalId;
  final DateTime performedAt;
  final String? dayLabel;
  final String? dayTitle;
  final int exerciseCount;

  String? get displayName {
    final title = dayTitle?.trim() ?? '';
    if (title.isNotEmpty) return title;
    final label = dayLabel?.trim() ?? '';
    return label.isEmpty ? null : label;
  }
}

class WorkoutSyncQueueConflictSession {
  const WorkoutSyncQueueConflictSession({
    required this.sessionId,
    required this.workoutExternalId,
    required this.performedAt,
  });

  final int sessionId;
  final String workoutExternalId;
  final DateTime performedAt;
}

class WorkoutSyncQueueConflict {
  const WorkoutSyncQueueConflict({
    required this.clientId,
    required this.clientName,
    required this.calendarDate,
    required this.templateIdx,
    required this.planInstance,
    required this.sessions,
  });

  final String clientId;
  final String clientName;
  final DateTime calendarDate;
  final int templateIdx;
  final int planInstance;
  final List<WorkoutSyncQueueConflictSession> sessions;
}

class WorkoutSyncQueueRebuildPreview {
  const WorkoutSyncQueueRebuildPreview._({
    required this.totalSessions,
    required this.emptySessions,
    required this.missingClients,
    required this.missingWorkoutExternalIds,
    required this.payloadErrors,
    required this.conflicts,
    required List<_PreparedWorkoutSyncTask> tasks,
  }) : _tasks = tasks;

  final int totalSessions;
  final int emptySessions;
  final int missingClients;
  final int missingWorkoutExternalIds;
  final int payloadErrors;
  final List<WorkoutSyncQueueConflict> conflicts;
  final List<_PreparedWorkoutSyncTask> _tasks;

  int get tasksToCreate => _tasks.length;
  int get conflictSessions =>
      conflicts.fold(0, (total, conflict) => total + conflict.sessions.length);
}

class WorkoutSyncQueueRebuildResult {
  const WorkoutSyncQueueRebuildResult({
    required this.createdTasks,
    required this.emptySessions,
    required this.missingClients,
    required this.missingWorkoutExternalIds,
    required this.conflictSessions,
    required this.payloadErrors,
  });

  final int createdTasks;
  final int emptySessions;
  final int missingClients;
  final int missingWorkoutExternalIds;
  final int conflictSessions;
  final int payloadErrors;
}

class _PreparedWorkoutSyncTask {
  const _PreparedWorkoutSyncTask({
    required this.workoutExternalId,
    required this.payload,
    required this.performedAt,
  });

  final String workoutExternalId;
  final String payload;
  final DateTime performedAt;
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

class StaleProgramSlotException implements Exception {
  final String clientId;
  final int requestedPlanInstance;
  final int activePlanInstance;

  const StaleProgramSlotException({
    required this.clientId,
    required this.requestedPlanInstance,
    required this.activePlanInstance,
  });

  @override
  String toString() =>
      'Слот относится к абонементу $requestedPlanInstance, '
      'активен абонемент $activePlanInstance. Обновите экран.';
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

class ExerciseIdentityUsageVm {
  const ExerciseIdentityUsageVm({
    required this.exercise,
    required this.templateSlots,
    required this.clientSlots,
    required this.bindings,
    required this.workoutResults,
  });

  final ExerciseIdentity exercise;
  final int templateSlots;
  final int clientSlots;
  final int bindings;
  final int workoutResults;

  int get totalUsage => templateSlots + clientSlots + bindings + workoutResults;
}

class ExerciseDuplicateGroupVm {
  const ExerciseDuplicateGroupVm({
    required this.normalizedName,
    required this.items,
  });

  final String normalizedName;
  final List<ExerciseIdentityUsageVm> items;
}

class ExerciseUuidAliasVm {
  const ExerciseUuidAliasVm({
    required this.oldExternalId,
    required this.canonicalExternalId,
  });

  final String oldExternalId;
  final String canonicalExternalId;

  Map<String, String> toJson() => {
    'old_exercise_id': oldExternalId,
    'canonical_exercise_id': canonicalExternalId,
  };
}

class LegacyExerciseSnapshotGroupVm {
  const LegacyExerciseSnapshotGroupVm({
    required this.name,
    required this.resultIds,
  });

  final String name;
  final List<int> resultIds;

  int get resultCount => resultIds.length;
}

class LegacyExerciseBindingCandidateVm {
  const LegacyExerciseBindingCandidateVm({
    required this.clientId,
    required this.clientName,
    required this.templateExerciseId,
    required this.programSlot,
    required this.displayName,
    required this.currentIdentityId,
    required this.currentIdentityName,
    required this.currentIdentityExternalId,
    required this.snapshotGroups,
    required this.identitySnapshotNames,
  });

  final String clientId;
  final String clientName;
  final int templateExerciseId;
  final String programSlot;
  final String displayName;
  final int currentIdentityId;
  final String currentIdentityName;
  final String currentIdentityExternalId;
  final List<LegacyExerciseSnapshotGroupVm> snapshotGroups;
  final List<String> identitySnapshotNames;

  int get historicalResultCount =>
      snapshotGroups.fold(0, (total, group) => total + group.resultCount);

  bool get hasMixedIdentityHistory {
    final names = identitySnapshotNames
        .map(AppDb.normalizeExerciseName)
        .where((name) => name.isNotEmpty)
        .toSet();
    return names.length > 1;
  }

  bool get isCleanCandidate {
    if (hasMixedIdentityHistory || snapshotGroups.isEmpty) return false;
    final display = AppDb.normalizeExerciseName(displayName);
    final snapshots = snapshotGroups
        .map((group) => AppDb.normalizeExerciseName(group.name))
        .where((name) => name.isNotEmpty)
        .toSet();
    return snapshots.length == 1 && snapshots.single == display;
  }
}

class LegacyExerciseBindingsAuditVm {
  const LegacyExerciseBindingsAuditVm({
    required this.candidates,
    required this.groups,
    required this.orphanBindings,
  });

  final List<LegacyExerciseBindingCandidateVm> candidates;
  final List<LegacyExerciseBindingGroupVm> groups;
  final int orphanBindings;
}

class LegacyExerciseBindingGroupVm {
  const LegacyExerciseBindingGroupVm({
    required this.displayName,
    required this.normalizedName,
    required this.candidates,
    required this.exactCatalogMatch,
  });

  final String displayName;
  final String normalizedName;
  final List<LegacyExerciseBindingCandidateVm> candidates;
  final ExerciseIdentity? exactCatalogMatch;

  int get clientCount => candidates.map((item) => item.clientId).toSet().length;
  int get slotCount => candidates.length;
  int get historicalResultCount => candidates.fold(0, (total, candidate) {
    return total +
        candidate.snapshotGroups
            .where(
              (snapshot) =>
                  AppDb.normalizeExerciseName(snapshot.name) == normalizedName,
            )
            .fold(0, (count, snapshot) => count + snapshot.resultCount);
  });
}

class LegacyExerciseBulkCorrectionRequest {
  const LegacyExerciseBulkCorrectionRequest({
    required this.normalizedLegacyName,
    required this.targetExerciseIdentityId,
  });

  final String normalizedLegacyName;
  final int targetExerciseIdentityId;
}

class LegacyExerciseBulkTargetVm {
  const LegacyExerciseBulkTargetVm({
    required this.legacyName,
    required this.targetName,
    required this.targetExternalId,
  });

  final String legacyName;
  final String targetName;
  final String targetExternalId;
}

class LegacyExerciseBulkCorrectionPreview {
  const LegacyExerciseBulkCorrectionPreview({
    required this.groups,
    required this.historicalResults,
    required this.currentSlots,
    required this.affectedSessions,
    required this.targets,
  });

  final int groups;
  final int historicalResults;
  final int currentSlots;
  final int affectedSessions;
  final List<LegacyExerciseBulkTargetVm> targets;
}

class LegacyExerciseBulkCorrectionResult {
  const LegacyExerciseBulkCorrectionResult({
    required this.groups,
    required this.changedHistoricalResults,
    required this.changedCurrentSlots,
    required this.requeuedWorkoutSessions,
  });

  final int groups;
  final int changedHistoricalResults;
  final int changedCurrentSlots;
  final int requeuedWorkoutSessions;
}

class _LegacyExerciseSlotTarget {
  const _LegacyExerciseSlotTarget({
    required this.clientId,
    required this.templateExerciseId,
    required this.targetIdentityId,
  });

  final String clientId;
  final int templateExerciseId;
  final int targetIdentityId;
}

class _LegacyExerciseBulkPlan {
  const _LegacyExerciseBulkPlan({
    required this.groupCount,
    required this.resultTargets,
    required this.slotTargets,
    required this.workoutExternalIds,
    required this.targets,
  });

  final int groupCount;
  final Map<int, int> resultTargets;
  final List<_LegacyExerciseSlotTarget> slotTargets;
  final Set<String> workoutExternalIds;
  final List<LegacyExerciseBulkTargetVm> targets;
}

class LegacyExerciseCorrectionPreview {
  const LegacyExerciseCorrectionPreview({
    required this.historicalResults,
    required this.currentSlots,
    required this.affectedSessions,
    required this.targetIdentityId,
    required this.targetName,
    required this.targetExternalId,
  });

  final int historicalResults;
  final int currentSlots;
  final int affectedSessions;
  final int targetIdentityId;
  final String targetName;
  final String targetExternalId;
}

class LegacyExerciseCorrectionResult {
  const LegacyExerciseCorrectionResult({
    required this.changedHistoricalResults,
    required this.changedCurrentSlots,
    required this.requeuedWorkoutSessions,
  });

  final int changedHistoricalResults;
  final int changedCurrentSlots;
  final int requeuedWorkoutSessions;
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
    ExerciseIdentities,
    ExerciseIdentityAliases,
    ExerciseIdentityBindings,
    AppSettings,
    SyncQueue,
    SyncLog,
  ],
)
class AppDb extends _$AppDb {
  AppDb() : super(driftDatabase(name: 'myfitness'));
  AppDb.forTesting(super.e);

  static const Uuid _uuid = Uuid();
  static const String activeClientStatus = 'ACTIVE';
  static const String archivedClientStatus = 'ARCHIVED';
  static const String _trainerUuidSettingKey = 'trainer_uuid';
  static const String _templateExerciseSource = 'TEMPLATE';
  static const String _clientAddedExerciseSource = 'CLIENT_ADDED';
  static const String activeExerciseStatus = 'ACTIVE';
  static const String archivedExerciseStatus = 'ARCHIVED';
  static const int _confirmedHammerResultId = 2158;
  static const int _confirmedHammerSessionId = 669;
  static const int _confirmedHammerOldIdentityId = 324;
  static const int _confirmedHammerCanonicalIdentityId = 348;
  static const String _confirmedHammerWorkoutExternalId =
      '99d787bd-d229-4d3c-aabe-2986b2a4ca48';
  static const String _confirmedHammerOldIdentityExternalId =
      '9cf98acc-49e1-4271-b4d1-a351f6a8efd7';
  static const String _confirmedHammerCanonicalIdentityExternalId =
      '44998917-34b1-42e1-bfca-3ff98f50d178';
  static const String _confirmedHammerSnapshot = 'молоточки';
  static const _knownEmptyExerciseDuplicateMerges =
      <({String oldExternalId, String canonicalExternalId})>[
        (
          oldExternalId: '0e6d41b3-8e85-430b-b2fa-e74145517065',
          canonicalExternalId: 'ca91d5b0-5a80-43ca-91f6-7b591086bbdd',
        ),
        (
          oldExternalId: 'a5e82f98-6165-4843-b572-8b2b9417765a',
          canonicalExternalId: '7ef69ad0-3588-4a50-935e-6d4c11431fa0',
        ),
        (
          oldExternalId: 'c416f9e9-be64-4fe7-ae16-1d3de9d4c0c0',
          canonicalExternalId: '81b869d0-2881-4ca5-8990-986ace32a00c',
        ),
        (
          oldExternalId: 'ff9c9b6e-5f77-48a5-9118-e3ed758fb23c',
          canonicalExternalId: '966607d2-84a0-4d63-a66a-65f66e655695',
        ),
      ];

  bool _maleDefaultsPatched = false;
  bool _femaleDefaultsPatched = false;
  bool _trialDefaultsPatched = false;
  Future<void>? _templateDefaultsPatchFuture;
  void Function()? _automaticSyncTrigger;

  void configureAutomaticSyncTrigger(void Function()? trigger) {
    _automaticSyncTrigger = trigger;
  }

  void _triggerAutomaticSync() {
    try {
      _automaticSyncTrigger?.call();
    } catch (_) {
      // Auto-sync is best-effort and must not affect the local mutation.
    }
  }

  @override
  int get schemaVersion => 15;

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
      await _ensureExternalIdentityIndexes();
      await _ensureWorkoutSlotIdentityIndex();
      await _ensureSyncIndexes();
      await _seedWorkoutTemplates();
      await _seedWorkoutTemplateExercises();
      await _backfillExternalIdentities();
      await _ensureTrainerUuid();
      await cleanupSyncLogs();
    },

    onUpgrade: (m, from, to) async {
      Future<bool> hasColumn(String table, String column) async {
        final rows = await customSelect('PRAGMA table_info($table)').get();
        return rows.any((row) => row.read<String>('name') == column);
      }

      Future<void> addColumnIfMissing(
        TableInfo table,
        GeneratedColumn column,
      ) async {
        if (!await hasColumn(table.actualTableName, column.$name)) {
          await m.addColumn(table, column);
        }
      }

      // Продовая миграция: без удаления существующих данных клиентов.
      if (from < 8) {
        await m.addColumn(clients, clients.externalId);
        await m.addColumn(clients, clients.status);
        await m.addColumn(workoutSessions, workoutSessions.externalId);
        await m.addColumn(
          workoutExerciseResults,
          workoutExerciseResults.exerciseIdentityId,
        );
        await m.addColumn(
          workoutExerciseResults,
          workoutExerciseResults.exerciseNameSnapshot,
        );
        await m.createTable(exerciseIdentities);
        await m.createTable(exerciseIdentityBindings);
      }
      if (from < 9) {
        await m.createTable(syncQueue);
        await m.createTable(syncLog);
      }
      if (from < 10) {
        await m.createTable(appSettings);
      }
      if (from < 11) {
        await m.addColumn(workoutSessions, workoutSessions.absoluteIndex);
      }
      if (from < 12) {
        await addColumnIfMissing(
          clientTemplateExerciseOverrides,
          clientTemplateExerciseOverrides.exerciseIdentityId,
        );
        await addColumnIfMissing(
          workoutTemplateExercises,
          workoutTemplateExercises.exerciseIdentityId,
        );
        // From v7 and older this table is created above with its current
        // definition, therefore its catalog columns already exist.
        if (from >= 8) {
          await addColumnIfMissing(
            exerciseIdentities,
            exerciseIdentities.canonicalName,
          );
          await addColumnIfMissing(
            exerciseIdentities,
            exerciseIdentities.normalizedName,
          );
          await addColumnIfMissing(
            exerciseIdentities,
            exerciseIdentities.status,
          );
          await addColumnIfMissing(
            exerciseIdentities,
            exerciseIdentities.updatedAt,
          );
          await addColumnIfMissing(
            exerciseIdentities,
            exerciseIdentities.archivedAt,
          );
        }
      }
      if (from < 13) {
        await addColumnIfMissing(
          exerciseIdentities,
          exerciseIdentities.mergedIntoIdentityId,
        );
        if (!await _tableExists(exerciseIdentityAliases.actualTableName)) {
          await m.createTable(exerciseIdentityAliases);
        }
      }

      await _ensureProgramDayOverridesTable();
      await ensureIncomeTables();
      await ensureContestTables();
      await _ensurePlanEndAlertOverridesTable();
      await _ensureClientPaymentRemindersTable();
      await _ensureClientExerciseNameOverridesTable();
      await _ensureClientHiddenExercisesTable();
      await _ensureClientAddedExercisesTable();
      await ensureProgressTables();
      await _ensureExternalIdentityIndexes();
      await _ensureWorkoutSlotIdentityIndex();
      await _ensureSyncIndexes();

      await _seedWorkoutTemplates();
      await _seedWorkoutTemplateExercises();
      await _backfillExternalIdentities();
      if (from < 14) {
        await _mergeKnownEmptyExerciseDuplicates();
      }
      if (from < 15) {
        await _applyConfirmedHammerResultDataFix();
      }
      await _ensureTrainerUuid();
      if (from < 9) {
        await _enqueueAllExistingWorkoutSessionsForSync();
      }
      await cleanupSyncLogs();
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
      await _ensureExternalIdentityIndexes();
      await _ensureWorkoutSlotIdentityIndex();
      await _ensureSyncIndexes();
      await _backfillExternalIdentities();
      await _ensureTrainerUuid();
      await cleanupSyncLogs();
    },
  );

  String _newUuid() => _uuid.v4();

  /// Stable key used by the catalog. Dart's standard library has no Unicode
  /// normalization API, so this deliberately keeps the rule dependency-free:
  /// trim, lowercase and collapse Unicode whitespace.
  static String normalizeExerciseName(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _displayExerciseName(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ');

  Future<String> _ensureTrainerUuid() async {
    final existing =
        await (select(appSettings)
              ..where((row) => row.settingKey.equals(_trainerUuidSettingKey))
              ..limit(1))
            .getSingleOrNull();
    if (existing != null) {
      final value = existing.settingValue.trim();
      if (!_isUuidV4(value)) {
        throw StateError('В локальной БД хранится некорректный UUID тренера');
      }
      return value;
    }

    final generated = _newUuid();
    await into(appSettings).insert(
      AppSettingsCompanion.insert(
        settingKey: _trainerUuidSettingKey,
        settingValue: generated,
      ),
      mode: InsertMode.insertOrIgnore,
    );
    final stored =
        await (select(appSettings)
              ..where((row) => row.settingKey.equals(_trainerUuidSettingKey))
              ..limit(1))
            .getSingle();
    final value = stored.settingValue.trim();
    if (!_isUuidV4(value)) {
      throw StateError('Не удалось сохранить UUID тренера');
    }
    return value;
  }

  Future<String> getTrainerUuid() => transaction(_ensureTrainerUuid);

  Future<void> ensureExternalIdentities() => _backfillExternalIdentities();

  Future<void> _ensureExternalIdentityIndexes() async {
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS clients_external_id_unique
      ON clients (external_id)
      WHERE external_id IS NOT NULL AND TRIM(external_id) != ''
    ''');
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS workout_sessions_external_id_unique
      ON workout_sessions (external_id)
      WHERE external_id IS NOT NULL AND TRIM(external_id) != ''
    ''');
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS exercise_identities_external_id_unique
      ON exercise_identities (external_id)
    ''');
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS exercise_identity_bindings_global_current_unique
      ON exercise_identity_bindings (source_type, source_id)
      WHERE client_id IS NULL AND is_current = 1
    ''');
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS exercise_identity_bindings_client_current_unique
      ON exercise_identity_bindings (client_id, source_type, source_id)
      WHERE client_id IS NOT NULL AND is_current = 1
    ''');
  }

  Future<void> _ensureWorkoutSlotIdentityIndex() async {
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS workout_sessions_program_slot_unique
      ON workout_sessions (client_id, plan_instance, absolute_index)
      WHERE absolute_index IS NOT NULL
    ''');
  }

  Future<void> _ensureSyncIndexes() async {
    await customStatement('''
      CREATE INDEX IF NOT EXISTS sync_queue_status_created_at_idx
      ON sync_queue (status, created_at)
    ''');
    await customStatement('''
      CREATE INDEX IF NOT EXISTS sync_log_timestamp_idx
      ON sync_log (timestamp)
    ''');
  }

  Future<String> _newUniqueUuidForTable(String tableName) async {
    const allowedTables = {
      'clients',
      'workout_sessions',
      'exercise_identities',
    };
    if (!allowedTables.contains(tableName)) {
      throw ArgumentError.value(tableName, 'tableName');
    }

    for (var attempt = 0; attempt < 20; attempt++) {
      final candidate = _newUuid();
      final existing = await customSelect(
        'SELECT 1 FROM $tableName WHERE external_id = ? LIMIT 1',
        variables: [Variable.withString(candidate)],
      ).getSingleOrNull();
      if (existing == null) return candidate;
    }
    throw StateError('Не удалось создать уникальный UUID для $tableName');
  }

  Future<int> _createExerciseIdentity({String? canonicalName}) async {
    final externalId = await _newUniqueUuidForTable('exercise_identities');
    final name = canonicalName == null
        ? ''
        : _displayExerciseName(canonicalName);
    return into(exerciseIdentities).insert(
      ExerciseIdentitiesCompanion.insert(
        externalId: externalId,
        canonicalName: Value(name),
        normalizedName: Value(name.isEmpty ? '' : normalizeExerciseName(name)),
      ),
    );
  }

  Future<List<ExerciseIdentity>> getActiveExercises() {
    return (select(exerciseIdentities)
          ..where(
            (row) =>
                row.status.equals(activeExerciseStatus) &
                row.mergedIntoIdentityId.isNull(),
          )
          ..orderBy([(row) => OrderingTerm.asc(row.canonicalName)]))
        .get();
  }

  Future<List<ExerciseIdentity>> getExercises({
    bool includeArchived = false,
    bool includeMerged = false,
  }) {
    return (select(exerciseIdentities)
          ..where(
            (row) =>
                (includeArchived
                    ? const Constant(true)
                    : row.status.equals(activeExerciseStatus)) &
                (includeMerged
                    ? const Constant(true)
                    : row.mergedIntoIdentityId.isNull()),
          )
          ..orderBy([(row) => OrderingTerm.asc(row.canonicalName)]))
        .get();
  }

  Future<List<ExerciseIdentity>> searchExercises(String query) async {
    final normalized = normalizeExerciseName(query);
    final rows = await getActiveExercises();
    if (normalized.isEmpty) return rows;
    return rows
        .where((row) => row.normalizedName.contains(normalized))
        .toList(growable: false);
  }

  Future<ExerciseIdentity?> getExerciseById(int id) {
    return (select(
      exerciseIdentities,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
  }

  Future<ExerciseIdentity> createExercise(String name) {
    final displayName = _displayExerciseName(name);
    final normalized = normalizeExerciseName(displayName);
    if (normalized.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Название упражнения пустое');
    }
    return transaction(() async {
      final existing =
          await (select(exerciseIdentities)
                ..where(
                  (row) =>
                      row.status.equals(activeExerciseStatus) &
                      row.normalizedName.equals(normalized),
                )
                ..orderBy([(row) => OrderingTerm.asc(row.id)])
                ..limit(1))
              .getSingleOrNull();
      if (existing != null) return existing;

      final id = await _createExerciseIdentity(canonicalName: displayName);
      return (select(
        exerciseIdentities,
      )..where((row) => row.id.equals(id))).getSingle();
    });
  }

  Future<void> renameExercise({required int exerciseId, required String name}) {
    final displayName = _displayExerciseName(name);
    final normalized = normalizeExerciseName(displayName);
    if (normalized.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Название упражнения пустое');
    }
    return transaction(() async {
      final exercise = await getExerciseById(exerciseId);
      if (exercise == null) throw StateError('Упражнение не найдено');
      if (exercise.mergedIntoIdentityId != null) {
        throw StateError('Объединённое упражнение нельзя переименовать');
      }
      final conflict =
          await (select(exerciseIdentities)
                ..where(
                  (row) =>
                      row.id.equals(exerciseId).not() &
                      row.status.equals(activeExerciseStatus) &
                      row.normalizedName.equals(normalized),
                )
                ..limit(1))
              .getSingleOrNull();
      if (conflict != null) {
        throw StateError('Упражнение с таким названием уже есть в базе');
      }
      await (update(
        exerciseIdentities,
      )..where((row) => row.id.equals(exerciseId))).write(
        ExerciseIdentitiesCompanion(
          canonicalName: Value(displayName),
          normalizedName: Value(normalized),
          updatedAt: Value(DateTime.now()),
        ),
      );
      // Program slots are a live reference to the catalog. Historical workout
      // results keep their own snapshot and are deliberately not touched here.
      await customStatement(
        'UPDATE workout_template_exercises '
        'SET name = ? WHERE exercise_identity_id = ?',
        [displayName, exerciseId],
      );
      await customStatement(
        'UPDATE client_added_exercises '
        'SET name = ? WHERE exercise_identity_id = ?',
        [displayName, exerciseId],
      );
    });
  }

  Future<void> archiveExercise(int exerciseId) async {
    final exercise = await getExerciseById(exerciseId);
    if (exercise == null) throw StateError('Упражнение не найдено');
    if (exercise.mergedIntoIdentityId != null) {
      throw StateError('Объединённое упражнение уже недоступно');
    }
    await (update(
      exerciseIdentities,
    )..where((row) => row.id.equals(exerciseId))).write(
      ExerciseIdentitiesCompanion(
        status: const Value(archivedExerciseStatus),
        archivedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> restoreExercise(int exerciseId) async {
    await transaction(() async {
      final exercise = await getExerciseById(exerciseId);
      if (exercise == null) throw StateError('Упражнение не найдено');
      if (exercise.mergedIntoIdentityId != null) {
        throw StateError(
          'Объединённое упражнение нельзя восстановить отдельно',
        );
      }
      final conflict =
          await (select(exerciseIdentities)
                ..where(
                  (row) =>
                      row.id.equals(exerciseId).not() &
                      row.status.equals(activeExerciseStatus) &
                      row.normalizedName.equals(exercise.normalizedName),
                )
                ..limit(1))
              .getSingleOrNull();
      if (conflict != null) {
        throw StateError('Активное упражнение с таким названием уже есть');
      }
      await (update(
        exerciseIdentities,
      )..where((row) => row.id.equals(exerciseId))).write(
        ExerciseIdentitiesCompanion(
          status: const Value(activeExerciseStatus),
          archivedAt: const Value(null),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  Future<ExerciseIdentityUsageVm> getExerciseIdentityUsage(
    int identityId,
  ) async {
    await _ensureClientAddedExercisesTable();
    final exercise = await getExerciseById(identityId);
    if (exercise == null) throw StateError('Упражнение не найдено');
    final row = await customSelect(
      '''
      SELECT
        (SELECT COUNT(*) FROM workout_template_exercises
          WHERE exercise_identity_id = ?) AS template_slots,
        ((SELECT COUNT(*) FROM client_added_exercises
          WHERE exercise_identity_id = ?) +
         (SELECT COUNT(*) FROM client_template_exercise_overrides
          WHERE exercise_identity_id = ?)) AS client_slots,
        (SELECT COUNT(*) FROM exercise_identity_bindings
          WHERE identity_id = ?) AS bindings_count,
        (SELECT COUNT(*) FROM workout_exercise_results
          WHERE exercise_identity_id = ?) AS workout_results
      ''',
      variables: List.generate(5, (_) => Variable.withInt(identityId)),
      readsFrom: {
        workoutTemplateExercises,
        clientTemplateExerciseOverrides,
        exerciseIdentityBindings,
        workoutExerciseResults,
      },
    ).getSingle();
    return ExerciseIdentityUsageVm(
      exercise: exercise,
      templateSlots: row.read<int>('template_slots'),
      clientSlots: row.read<int>('client_slots'),
      bindings: row.read<int>('bindings_count'),
      workoutResults: row.read<int>('workout_results'),
    );
  }

  Future<List<ExerciseDuplicateGroupVm>> getExerciseDuplicateGroups() async {
    final identities =
        await (select(exerciseIdentities)
              ..where(
                (row) =>
                    row.mergedIntoIdentityId.isNull() &
                    row.normalizedName.equals('').not(),
              )
              ..orderBy([(row) => OrderingTerm.asc(row.canonicalName)]))
            .get();
    final grouped = <String, List<ExerciseIdentity>>{};
    for (final identity in identities) {
      grouped.putIfAbsent(identity.normalizedName, () => []).add(identity);
    }

    final result = <ExerciseDuplicateGroupVm>[];
    for (final entry in grouped.entries) {
      if (entry.value.length < 2) continue;
      final items = <ExerciseIdentityUsageVm>[];
      for (final identity in entry.value) {
        items.add(await getExerciseIdentityUsage(identity.id));
      }
      result.add(
        ExerciseDuplicateGroupVm(normalizedName: entry.key, items: items),
      );
    }
    result.sort(
      (a, b) => a.items.first.exercise.canonicalName.compareTo(
        b.items.first.exercise.canonicalName,
      ),
    );
    return result;
  }

  Future<int> _resolveCanonicalExerciseIdentityId(int identityId) async {
    var currentId = identityId;
    final visited = <int>{};
    while (true) {
      if (!visited.add(currentId)) {
        throw StateError('Обнаружен цикл соответствий UUID упражнений');
      }
      final identity = await getExerciseById(currentId);
      if (identity == null) {
        throw StateError('Упражнение $currentId не найдено');
      }
      final nextId = identity.mergedIntoIdentityId;
      if (nextId == null) return currentId;
      currentId = nextId;
    }
  }

  Future<String?> resolveCanonicalExerciseUuid(String externalId) async {
    final normalizedUuid = externalId.trim().toLowerCase();
    if (!_isUuidV4(normalizedUuid)) return null;
    final direct =
        await (select(exerciseIdentities)
              ..where((row) => row.externalId.lower().equals(normalizedUuid))
              ..limit(1))
            .getSingleOrNull();
    int? identityId = direct?.id;
    if (identityId == null) {
      final alias =
          await (select(exerciseIdentityAliases)
                ..where(
                  (row) => row.oldExternalId.lower().equals(normalizedUuid),
                )
                ..limit(1))
              .getSingleOrNull();
      identityId = alias?.canonicalIdentityId;
    }
    if (identityId == null) return null;
    final canonicalId = await _resolveCanonicalExerciseIdentityId(identityId);
    return (await getExerciseById(canonicalId))!.externalId;
  }

  Future<int?> _readCurrentExerciseIdentityId({
    required String clientId,
    required int templateExerciseId,
  }) async {
    final clientOverride =
        await (select(clientTemplateExerciseOverrides)
              ..where(
                (row) =>
                    row.clientId.equals(clientId) &
                    row.templateExerciseId.equals(templateExerciseId),
              )
              ..limit(1))
            .getSingleOrNull();
    if (clientOverride?.exerciseIdentityId case final identityId?) {
      return identityId;
    }

    final clientBinding = await _findCurrentExerciseBinding(
      clientId: clientId,
      sourceType: _templateExerciseSource,
      sourceId: templateExerciseId,
    );
    if (clientBinding != null) return clientBinding;

    final template =
        await (select(workoutTemplateExercises)
              ..where((row) => row.id.equals(templateExerciseId))
              ..limit(1))
            .getSingleOrNull();
    if (template?.exerciseIdentityId case final identityId?) {
      return identityId;
    }
    return _findCurrentExerciseBinding(
      sourceType: _templateExerciseSource,
      sourceId: templateExerciseId,
    );
  }

  Future<LegacyExerciseBindingsAuditVm> analyzeLegacyExerciseBindings() async {
    await _ensureClientExerciseNameOverridesTable();
    final overrides = await customSelect(
      '''
      SELECT o.client_id, o.template_exercise_id, o.custom_name,
             c.name AS client_name, e.order_index,
             t.label AS template_label, t.title AS template_title
      FROM client_exercise_name_overrides o
      LEFT JOIN clients c ON c.id = o.client_id
      LEFT JOIN workout_template_exercises e
        ON e.id = o.template_exercise_id
      LEFT JOIN workout_templates t ON t.id = e.template_id
      ORDER BY c.name COLLATE NOCASE, t.idx, e.order_index, o.template_exercise_id
      ''',
      readsFrom: {clients, workoutTemplateExercises, workoutTemplates},
    ).get();

    final candidates = <LegacyExerciseBindingCandidateVm>[];
    for (final row in overrides) {
      final clientId = row.read<String>('client_id');
      final templateExerciseId = row.read<int>('template_exercise_id');
      final displayName = row.read<String>('custom_name').trim();
      final currentId = await _readCurrentExerciseIdentityId(
        clientId: clientId,
        templateExerciseId: templateExerciseId,
      );
      if (currentId == null) continue;
      final canonicalId = await _resolveCanonicalExerciseIdentityId(currentId);
      final identity = await getExerciseById(canonicalId);
      if (identity == null ||
          normalizeExerciseName(displayName) ==
              normalizeExerciseName(identity.canonicalName)) {
        continue;
      }

      final resultRows = await customSelect(
        '''
        SELECT r.id, r.exercise_name_snapshot
        FROM workout_exercise_results r
        INNER JOIN workout_sessions s ON s.id = r.session_id
        WHERE s.client_id = ? AND r.template_exercise_id = ?
        ORDER BY r.id
        ''',
        variables: [
          Variable.withString(clientId),
          Variable.withInt(templateExerciseId),
        ],
        readsFrom: {workoutExerciseResults, workoutSessions},
      ).get();
      final grouped = <String, ({String name, List<int> ids})>{};
      for (final result in resultRows) {
        final snapshot = result
            .readNullable<String>('exercise_name_snapshot')
            ?.trim();
        final normalized = normalizeExerciseName(snapshot ?? '');
        final groupKey = normalized.isEmpty
            ? '__missing_snapshot__'
            : normalized;
        final group = grouped.putIfAbsent(
          groupKey,
          () => (
            name: snapshot?.isNotEmpty == true ? snapshot! : 'Без snapshot',
            ids: <int>[],
          ),
        );
        group.ids.add(result.read<int>('id'));
      }

      final identitySnapshotRows = await customSelect(
        '''
        SELECT DISTINCT exercise_name_snapshot
        FROM workout_exercise_results
        WHERE exercise_identity_id = ?
          AND exercise_name_snapshot IS NOT NULL
          AND TRIM(exercise_name_snapshot) != ''
        ORDER BY exercise_name_snapshot COLLATE NOCASE
        ''',
        variables: [Variable.withInt(canonicalId)],
        readsFrom: {workoutExerciseResults},
      ).get();
      final label = row.readNullable<String>('template_label')?.trim() ?? '';
      final title = row.readNullable<String>('template_title')?.trim() ?? '';
      final order = row.readNullable<int>('order_index');
      final slotParts = <String>[
        if (title.isNotEmpty) title else if (label.isNotEmpty) label,
        if (order != null) 'упражнение ${order + 1}',
      ];
      candidates.add(
        LegacyExerciseBindingCandidateVm(
          clientId: clientId,
          clientName:
              row.readNullable<String>('client_name')?.trim().isNotEmpty == true
              ? row.read<String>('client_name').trim()
              : clientId,
          templateExerciseId: templateExerciseId,
          programSlot: slotParts.isEmpty
              ? 'slot #$templateExerciseId'
              : slotParts.join(' • '),
          displayName: displayName,
          currentIdentityId: canonicalId,
          currentIdentityName: identity.canonicalName,
          currentIdentityExternalId: identity.externalId,
          snapshotGroups: [
            for (final group in grouped.values)
              LegacyExerciseSnapshotGroupVm(
                name: group.name,
                resultIds: List.unmodifiable(group.ids),
              ),
          ],
          identitySnapshotNames: [
            for (final item in identitySnapshotRows)
              item.read<String>('exercise_name_snapshot'),
          ],
        ),
      );
    }

    final orphanRow = await customSelect(
      '''
      SELECT COUNT(*) AS amount
      FROM exercise_identity_bindings b
      WHERE (b.source_type = 'TEMPLATE' AND NOT EXISTS (
               SELECT 1 FROM workout_template_exercises e WHERE e.id = b.source_id
             ))
         OR (b.source_type = 'CLIENT_ADDED' AND NOT EXISTS (
               SELECT 1 FROM client_added_exercises a
               WHERE a.id = b.source_id AND a.client_id = b.client_id
             ))
         OR b.source_type NOT IN ('TEMPLATE', 'CLIENT_ADDED')
      ''',
      readsFrom: {exerciseIdentityBindings, workoutTemplateExercises},
    ).getSingle();
    final candidatesByName = <String, List<LegacyExerciseBindingCandidateVm>>{};
    for (final candidate in candidates) {
      final normalized = normalizeExerciseName(candidate.displayName);
      if (normalized.isEmpty) continue;
      candidatesByName.putIfAbsent(normalized, () => []).add(candidate);
    }
    final activeByName = <String, List<ExerciseIdentity>>{};
    for (final exercise in await getActiveExercises()) {
      final normalized = normalizeExerciseName(exercise.canonicalName);
      activeByName.putIfAbsent(normalized, () => []).add(exercise);
    }
    final groups = <LegacyExerciseBindingGroupVm>[];
    for (final entry in candidatesByName.entries) {
      final matches = activeByName[entry.key] ?? const <ExerciseIdentity>[];
      groups.add(
        LegacyExerciseBindingGroupVm(
          displayName: entry.value.first.displayName,
          normalizedName: entry.key,
          candidates: List.unmodifiable(entry.value),
          exactCatalogMatch: matches.length == 1 ? matches.single : null,
        ),
      );
    }
    groups.sort(
      (left, right) => left.displayName.toLowerCase().compareTo(
        right.displayName.toLowerCase(),
      ),
    );
    return LegacyExerciseBindingsAuditVm(
      candidates: List.unmodifiable(candidates),
      groups: List.unmodifiable(groups),
      orphanBindings: orphanRow.read<int>('amount'),
    );
  }

  Future<LegacyExerciseCorrectionPreview> previewLegacyExerciseCorrection({
    required String clientId,
    required int templateExerciseId,
    required Iterable<int> historicalResultIds,
    required int targetExerciseIdentityId,
    required bool reassignCurrentSlot,
  }) async {
    final targetId = await _resolveCanonicalExerciseIdentityId(
      targetExerciseIdentityId,
    );
    final target = await getExerciseById(targetId);
    if (target == null ||
        target.status != activeExerciseStatus ||
        target.mergedIntoIdentityId != null ||
        !_isUuidV4(target.externalId)) {
      throw StateError('Выберите активное canonical упражнение');
    }

    final ids = historicalResultIds.where((id) => id > 0).toSet();
    final selectedRows = ids.isEmpty
        ? const <QueryRow>[]
        : await customSelect(
            '''
            SELECT r.id, r.session_id, r.exercise_identity_id,
                   s.client_id, s.external_id, s.gender
            FROM workout_exercise_results r
            INNER JOIN workout_sessions s ON s.id = r.session_id
            WHERE r.id IN (${List.filled(ids.length, '?').join(', ')})
            ''',
            variables: [for (final id in ids) Variable.withInt(id)],
            readsFrom: {workoutExerciseResults, workoutSessions},
          ).get();
    if (selectedRows.length != ids.length ||
        selectedRows.any(
          (row) =>
              row.read<String>('client_id') != clientId ||
              row.read<int>('id') <= 0,
        )) {
      throw StateError('Выбранные historical results больше не существуют');
    }
    final scopedRows = ids.isEmpty
        ? const <QueryRow>[]
        : await customSelect(
            '''
            SELECT r.id
            FROM workout_exercise_results r
            WHERE r.id IN (${List.filled(ids.length, '?').join(', ')})
              AND r.template_exercise_id = ?
            ''',
            variables: [
              for (final id in ids) Variable.withInt(id),
              Variable.withInt(templateExerciseId),
            ],
            readsFrom: {workoutExerciseResults},
          ).get();
    if (scopedRows.length != ids.length) {
      throw StateError('Выбранные results относятся к другому program slot');
    }
    final changedRows = selectedRows
        .where(
          (row) => row.readNullable<int>('exercise_identity_id') != targetId,
        )
        .toList(growable: false);

    var currentSlots = 0;
    if (reassignCurrentSlot) {
      final source =
          await (select(workoutTemplateExercises)
                ..where((row) => row.id.equals(templateExerciseId))
                ..limit(1))
              .getSingleOrNull();
      if (source == null) throw StateError('Текущий program slot не найден');
      currentSlots = 1;
    }
    if (changedRows.isEmpty && currentSlots == 0) {
      throw StateError('Не выбраны данные для исправления');
    }
    final sessions = <int>{};
    for (final row in changedRows) {
      final uuid = row.readNullable<String>('external_id')?.trim() ?? '';
      if (row.read<String>('gender') != 'П' && uuid.isNotEmpty) {
        sessions.add(row.read<int>('session_id'));
      }
    }
    return LegacyExerciseCorrectionPreview(
      historicalResults: changedRows.length,
      currentSlots: currentSlots,
      affectedSessions: sessions.length,
      targetIdentityId: targetId,
      targetName: target.canonicalName,
      targetExternalId: target.externalId,
    );
  }

  Future<_LegacyExerciseBulkPlan> _prepareLegacyExerciseBulkCorrection(
    Iterable<LegacyExerciseBulkCorrectionRequest> requests,
  ) async {
    final requestList = requests.toList(growable: false);
    if (requestList.isEmpty) {
      throw ArgumentError('Не выбраны legacy-группы');
    }
    final audit = await analyzeLegacyExerciseBindings();
    final groupsByName = {
      for (final group in audit.groups) group.normalizedName: group,
    };
    final requestedNames = <String>{};
    final proposedResultTargets = <int, int>{};
    final slotTargetsByKey = <String, _LegacyExerciseSlotTarget>{};
    final targets = <LegacyExerciseBulkTargetVm>[];

    for (final request in requestList) {
      final normalizedName = normalizeExerciseName(
        request.normalizedLegacyName,
      );
      if (normalizedName.isEmpty || !requestedNames.add(normalizedName)) {
        throw StateError('Legacy-группа выбрана повторно или имеет пустое имя');
      }
      final group = groupsByName[normalizedName];
      if (group == null) {
        throw StateError('Legacy-группа изменилась. Обновите диагностику');
      }
      final targetId = await _resolveCanonicalExerciseIdentityId(
        request.targetExerciseIdentityId,
      );
      final target = await getExerciseById(targetId);
      if (target == null ||
          target.status != activeExerciseStatus ||
          target.mergedIntoIdentityId != null ||
          !_isUuidV4(target.externalId)) {
        throw StateError('Выберите активное canonical упражнение');
      }
      targets.add(
        LegacyExerciseBulkTargetVm(
          legacyName: group.displayName,
          targetName: target.canonicalName,
          targetExternalId: target.externalId,
        ),
      );

      for (final candidate in group.candidates) {
        for (final snapshot in candidate.snapshotGroups) {
          if (normalizeExerciseName(snapshot.name) != normalizedName) continue;
          for (final resultId in snapshot.resultIds) {
            final previous = proposedResultTargets[resultId];
            if (previous != null && previous != targetId) {
              throw StateError('Один historical result выбран в двух группах');
            }
            proposedResultTargets[resultId] = targetId;
          }
        }
        final slotKey =
            '${candidate.clientId}\u0000${candidate.templateExerciseId}';
        final previousSlot = slotTargetsByKey[slotKey];
        if (previousSlot != null && previousSlot.targetIdentityId != targetId) {
          throw StateError('Один current slot выбран в двух группах');
        }
        slotTargetsByKey[slotKey] = _LegacyExerciseSlotTarget(
          clientId: candidate.clientId,
          templateExerciseId: candidate.templateExerciseId,
          targetIdentityId: targetId,
        );
      }
    }

    final resultIds = proposedResultTargets.keys.toSet();
    final rows = resultIds.isEmpty
        ? const <QueryRow>[]
        : await customSelect(
            '''
            SELECT r.id, r.exercise_identity_id, s.external_id, s.gender
            FROM workout_exercise_results r
            INNER JOIN workout_sessions s ON s.id = r.session_id
            WHERE r.id IN (${List.filled(resultIds.length, '?').join(', ')})
            ''',
            variables: [for (final id in resultIds) Variable.withInt(id)],
            readsFrom: {workoutExerciseResults, workoutSessions},
          ).get();
    if (rows.length != resultIds.length) {
      throw StateError('Historical results изменились. Обновите диагностику');
    }
    final resultTargets = <int, int>{};
    final workoutExternalIds = <String>{};
    for (final row in rows) {
      final resultId = row.read<int>('id');
      final targetId = proposedResultTargets[resultId]!;
      if (row.readNullable<int>('exercise_identity_id') == targetId) continue;
      resultTargets[resultId] = targetId;
      final externalId = row.readNullable<String>('external_id')?.trim() ?? '';
      if (row.read<String>('gender') != 'П' && externalId.isNotEmpty) {
        workoutExternalIds.add(externalId);
      }
    }
    return _LegacyExerciseBulkPlan(
      groupCount: requestList.length,
      resultTargets: Map.unmodifiable(resultTargets),
      slotTargets: List.unmodifiable(slotTargetsByKey.values),
      workoutExternalIds: Set.unmodifiable(workoutExternalIds),
      targets: List.unmodifiable(targets),
    );
  }

  Future<LegacyExerciseBulkCorrectionPreview>
  previewLegacyExerciseBulkCorrection(
    Iterable<LegacyExerciseBulkCorrectionRequest> requests,
  ) async {
    final plan = await _prepareLegacyExerciseBulkCorrection(requests);
    return LegacyExerciseBulkCorrectionPreview(
      groups: plan.groupCount,
      historicalResults: plan.resultTargets.length,
      currentSlots: plan.slotTargets.length,
      affectedSessions: plan.workoutExternalIds.length,
      targets: plan.targets,
    );
  }

  Future<LegacyExerciseBulkCorrectionResult> reassignLegacyExerciseGroups(
    Iterable<LegacyExerciseBulkCorrectionRequest> requests,
  ) {
    return transaction(() async {
      final plan = await _prepareLegacyExerciseBulkCorrection(requests);
      var changedResults = 0;
      final resultIdsByTarget = <int, Set<int>>{};
      for (final entry in plan.resultTargets.entries) {
        resultIdsByTarget
            .putIfAbsent(entry.value, () => <int>{})
            .add(entry.key);
      }
      for (final entry in resultIdsByTarget.entries) {
        changedResults +=
            await (update(
              workoutExerciseResults,
            )..where((row) => row.id.isIn(entry.value))).write(
              WorkoutExerciseResultsCompanion(
                exerciseIdentityId: Value(entry.key),
              ),
            );
      }

      for (final slot in plan.slotTargets) {
        await setExerciseForClientSlot(
          clientId: slot.clientId,
          templateExerciseId: slot.templateExerciseId,
          exerciseIdentityId: slot.targetIdentityId,
        );
        await customStatement(
          'DELETE FROM client_exercise_name_overrides '
          'WHERE client_id = ? AND template_exercise_id = ?',
          [slot.clientId, slot.templateExerciseId],
        );
      }

      for (final externalId in plan.workoutExternalIds) {
        await enqueueWorkoutSync(externalId, triggerAutoSync: false);
      }
      return LegacyExerciseBulkCorrectionResult(
        groups: plan.groupCount,
        changedHistoricalResults: changedResults,
        changedCurrentSlots: plan.slotTargets.length,
        requeuedWorkoutSessions: plan.workoutExternalIds.length,
      );
    });
  }

  Future<LegacyExerciseCorrectionResult> reassignLegacyExerciseData({
    required String clientId,
    required int templateExerciseId,
    required Iterable<int> historicalResultIds,
    required int targetExerciseIdentityId,
    required bool reassignCurrentSlot,
  }) {
    return transaction(() async {
      final ids = historicalResultIds.where((id) => id > 0).toSet();
      final preview = await previewLegacyExerciseCorrection(
        clientId: clientId,
        templateExerciseId: templateExerciseId,
        historicalResultIds: ids,
        targetExerciseIdentityId: targetExerciseIdentityId,
        reassignCurrentSlot: reassignCurrentSlot,
      );
      final sessionRows = ids.isEmpty
          ? const <QueryRow>[]
          : await customSelect(
              '''
              SELECT DISTINCT s.external_id, s.gender
              FROM workout_exercise_results r
              INNER JOIN workout_sessions s ON s.id = r.session_id
              WHERE r.id IN (${List.filled(ids.length, '?').join(', ')})
                AND (r.exercise_identity_id IS NULL OR r.exercise_identity_id != ?)
              ''',
              variables: [
                for (final id in ids) Variable.withInt(id),
                Variable.withInt(preview.targetIdentityId),
              ],
              readsFrom: {workoutExerciseResults, workoutSessions},
            ).get();
      final changedResults = ids.isEmpty
          ? 0
          : await (update(workoutExerciseResults)..where(
                  (row) =>
                      row.id.isIn(ids) &
                      (row.exerciseIdentityId.isNull() |
                          row.exerciseIdentityId
                              .equals(preview.targetIdentityId)
                              .not()),
                ))
                .write(
                  WorkoutExerciseResultsCompanion(
                    exerciseIdentityId: Value(preview.targetIdentityId),
                  ),
                );

      var changedSlots = 0;
      if (reassignCurrentSlot) {
        await setExerciseForClientSlot(
          clientId: clientId,
          templateExerciseId: templateExerciseId,
          exerciseIdentityId: preview.targetIdentityId,
        );
        await customStatement(
          'DELETE FROM client_exercise_name_overrides '
          'WHERE client_id = ? AND template_exercise_id = ?',
          [clientId, templateExerciseId],
        );
        changedSlots = 1;
      }

      var requeued = 0;
      for (final row in sessionRows) {
        final uuid = row.readNullable<String>('external_id')?.trim() ?? '';
        if (row.read<String>('gender') == 'П' || uuid.isEmpty) continue;
        await enqueueWorkoutSync(uuid, triggerAutoSync: false);
        requeued++;
      }
      return LegacyExerciseCorrectionResult(
        changedHistoricalResults: changedResults,
        changedCurrentSlots: changedSlots,
        requeuedWorkoutSessions: requeued,
      );
    });
  }

  Future<List<ExerciseUuidAliasVm>> getExerciseUuidAliases() async {
    final aliases = await (select(
      exerciseIdentityAliases,
    )..orderBy([(row) => OrderingTerm.asc(row.oldExternalId)])).get();
    final result = <ExerciseUuidAliasVm>[];
    for (final alias in aliases) {
      final canonicalId = await _resolveCanonicalExerciseIdentityId(
        alias.canonicalIdentityId,
      );
      final canonical = await getExerciseById(canonicalId);
      if (canonical == null) {
        throw StateError('Canonical identity для alias не найдена');
      }
      result.add(
        ExerciseUuidAliasVm(
          oldExternalId: alias.oldExternalId,
          canonicalExternalId: canonical.externalId,
        ),
      );
    }
    return result;
  }

  Future<void> mergeExerciseIdentities({
    required int canonicalIdentityId,
    required Iterable<int> duplicateIdentityIds,
  }) {
    return transaction(() async {
      await _ensureClientAddedExercisesTable();
      final duplicateIds = duplicateIdentityIds.toSet();
      if (duplicateIds.isEmpty) {
        throw ArgumentError('Не выбраны упражнения для объединения');
      }
      if (duplicateIds.remove(canonicalIdentityId)) {
        throw ArgumentError('Нельзя объединить упражнение с самим собой');
      }

      final canonical = await getExerciseById(canonicalIdentityId);
      if (canonical == null) {
        throw StateError('Основное упражнение не найдено');
      }
      if (!_isUuidV4(canonical.externalId)) {
        throw StateError('Некорректный UUID основного упражнения');
      }
      if (canonical.mergedIntoIdentityId != null) {
        throw StateError('Основным нельзя выбрать уже объединённое упражнение');
      }

      final duplicates = <ExerciseIdentity>[];
      for (final duplicateId in duplicateIds) {
        final duplicate = await getExerciseById(duplicateId);
        if (duplicate == null) {
          throw StateError('Объединяемое упражнение $duplicateId не найдено');
        }
        if (!_isUuidV4(duplicate.externalId)) {
          throw StateError(
            'Некорректный UUID объединяемого упражнения $duplicateId',
          );
        }
        if (duplicate.mergedIntoIdentityId != null) {
          throw StateError('Упражнение уже было объединено');
        }
        final existingAlias =
            await (select(exerciseIdentityAliases)
                  ..where(
                    (row) => row.oldExternalId.equals(duplicate.externalId),
                  )
                  ..limit(1))
                .getSingleOrNull();
        if (existingAlias != null) {
          throw StateError('UUID упражнения уже зарегистрирован как alias');
        }
        duplicates.add(duplicate);
      }

      final now = DateTime.now();
      for (final duplicate in duplicates) {
        await customStatement(
          'UPDATE workout_template_exercises '
          'SET exercise_identity_id = ?, name = ? '
          'WHERE exercise_identity_id = ?',
          [canonical.id, canonical.canonicalName, duplicate.id],
        );
        await customStatement(
          'UPDATE client_added_exercises '
          'SET exercise_identity_id = ?, name = ? '
          'WHERE exercise_identity_id = ?',
          [canonical.id, canonical.canonicalName, duplicate.id],
        );
        await (update(
          clientTemplateExerciseOverrides,
        )..where((row) => row.exerciseIdentityId.equals(duplicate.id))).write(
          ClientTemplateExerciseOverridesCompanion(
            exerciseIdentityId: Value(canonical.id),
          ),
        );
        await (update(
          exerciseIdentityBindings,
        )..where((row) => row.identityId.equals(duplicate.id))).write(
          ExerciseIdentityBindingsCompanion(identityId: Value(canonical.id)),
        );
        await (update(
          workoutExerciseResults,
        )..where((row) => row.exerciseIdentityId.equals(duplicate.id))).write(
          WorkoutExerciseResultsCompanion(
            exerciseIdentityId: Value(canonical.id),
          ),
        );
        await (update(
          exerciseIdentityAliases,
        )..where((row) => row.canonicalIdentityId.equals(duplicate.id))).write(
          ExerciseIdentityAliasesCompanion(
            canonicalIdentityId: Value(canonical.id),
          ),
        );
        await into(exerciseIdentityAliases).insert(
          ExerciseIdentityAliasesCompanion.insert(
            oldExternalId: duplicate.externalId,
            canonicalIdentityId: canonical.id,
          ),
        );
        await (update(
          exerciseIdentities,
        )..where((row) => row.mergedIntoIdentityId.equals(duplicate.id))).write(
          ExerciseIdentitiesCompanion(
            mergedIntoIdentityId: Value(canonical.id),
            updatedAt: Value(now),
          ),
        );
        await (update(
          exerciseIdentities,
        )..where((row) => row.id.equals(duplicate.id))).write(
          ExerciseIdentitiesCompanion(
            status: const Value(archivedExerciseStatus),
            mergedIntoIdentityId: Value(canonical.id),
            archivedAt: Value(now),
            updatedAt: Value(now),
          ),
        );
      }

      await (update(
        exerciseIdentities,
      )..where((row) => row.id.equals(canonical.id))).write(
        ExerciseIdentitiesCompanion(
          status: const Value(activeExerciseStatus),
          mergedIntoIdentityId: const Value(null),
          archivedAt: const Value(null),
          updatedAt: Value(now),
        ),
      );
    });
  }

  Future<void> _mergeKnownEmptyExerciseDuplicates() async {
    final merges = <({int oldId, int canonicalId})>[];
    for (final pair in _knownEmptyExerciseDuplicateMerges) {
      final oldIdentity =
          await (select(exerciseIdentities)
                ..where((row) => row.externalId.equals(pair.oldExternalId))
                ..limit(1))
              .getSingleOrNull();
      final canonicalIdentity =
          await (select(exerciseIdentities)
                ..where(
                  (row) => row.externalId.equals(pair.canonicalExternalId),
                )
                ..limit(1))
              .getSingleOrNull();

      // These UUIDs belong to one known production dataset. Other installs
      // normally don't contain either row, so the repair is intentionally a
      // no-op unless the complete pair is present.
      if (oldIdentity == null || canonicalIdentity == null) continue;

      if (oldIdentity.mergedIntoIdentityId != null) {
        final finalId = await _resolveCanonicalExerciseIdentityId(
          oldIdentity.id,
        );
        if (finalId == canonicalIdentity.id) continue;
        continue;
      }

      if (oldIdentity.id == canonicalIdentity.id ||
          oldIdentity.status != activeExerciseStatus ||
          canonicalIdentity.status != activeExerciseStatus ||
          canonicalIdentity.mergedIntoIdentityId != null ||
          normalizeExerciseName(oldIdentity.canonicalName) !=
              normalizeExerciseName(canonicalIdentity.canonicalName)) {
        continue;
      }

      final countExpression = workoutExerciseResults.id.count();
      final oldResultCount =
          await (selectOnly(workoutExerciseResults)
                ..addColumns([countExpression])
                ..where(
                  workoutExerciseResults.exerciseIdentityId.equals(
                    oldIdentity.id,
                  ),
                ))
              .map((row) => row.read(countExpression) ?? 0)
              .getSingle();
      if (oldResultCount != 0) continue;

      final childMerge =
          await (select(exerciseIdentities)
                ..where(
                  (row) => row.mergedIntoIdentityId.equals(oldIdentity.id),
                )
                ..limit(1))
              .getSingleOrNull();
      final incomingAlias =
          await (select(exerciseIdentityAliases)
                ..where((row) => row.canonicalIdentityId.equals(oldIdentity.id))
                ..limit(1))
              .getSingleOrNull();
      final existingOldAlias =
          await (select(exerciseIdentityAliases)
                ..where(
                  (row) => row.oldExternalId.equals(oldIdentity.externalId),
                )
                ..limit(1))
              .getSingleOrNull();
      if (childMerge != null ||
          incomingAlias != null ||
          existingOldAlias != null) {
        continue;
      }

      merges.add((oldId: oldIdentity.id, canonicalId: canonicalIdentity.id));
    }

    for (final merge in merges) {
      await mergeExerciseIdentities(
        canonicalIdentityId: merge.canonicalId,
        duplicateIdentityIds: [merge.oldId],
      );
    }
  }

  Future<bool> _applyConfirmedHammerResultDataFix() async {
    final result =
        await (select(workoutExerciseResults)
              ..where((row) => row.id.equals(_confirmedHammerResultId))
              ..limit(1))
            .getSingleOrNull();
    if (result == null) return false;

    // The already-correct state is deliberately a no-op. Any other deviation
    // from the confirmed production row is treated as a different dataset and
    // must not be guessed at by this narrowly scoped repair.
    if (result.exerciseIdentityId == _confirmedHammerCanonicalIdentityId &&
        result.exerciseNameSnapshot == _confirmedHammerSnapshot) {
      return false;
    }
    if (result.sessionId != _confirmedHammerSessionId ||
        result.templateExerciseId != -21 ||
        result.exerciseIdentityId != _confirmedHammerOldIdentityId ||
        result.exerciseNameSnapshot != null ||
        result.lastWeightKg != 9.0 ||
        result.lastReps != 10) {
      return false;
    }

    final session =
        await (select(workoutSessions)
              ..where((row) => row.id.equals(_confirmedHammerSessionId))
              ..limit(1))
            .getSingleOrNull();
    if (session == null ||
        session.externalId?.trim() != _confirmedHammerWorkoutExternalId ||
        session.clientId != '1772001915174699' ||
        session.performedAt.millisecondsSinceEpoch ~/ 1000 != 1774429200 ||
        session.gender != 'М' ||
        session.templateIdx != 6) {
      return false;
    }

    final client = await getClientById(session.clientId);
    final oldIdentity = await getExerciseById(_confirmedHammerOldIdentityId);
    final canonicalIdentity = await getExerciseById(
      _confirmedHammerCanonicalIdentityId,
    );
    if (client?.name != 'Павел' ||
        oldIdentity?.externalId != _confirmedHammerOldIdentityExternalId ||
        oldIdentity?.status != archivedExerciseStatus ||
        oldIdentity?.mergedIntoIdentityId != null ||
        canonicalIdentity?.externalId !=
            _confirmedHammerCanonicalIdentityExternalId ||
        canonicalIdentity?.canonicalName != 'Молотки сидя' ||
        canonicalIdentity?.status != activeExerciseStatus ||
        canonicalIdentity?.mergedIntoIdentityId != null) {
      return false;
    }

    final changed =
        await (update(workoutExerciseResults)..where(
              (row) =>
                  row.id.equals(_confirmedHammerResultId) &
                  row.sessionId.equals(_confirmedHammerSessionId) &
                  row.templateExerciseId.equals(-21) &
                  row.exerciseIdentityId.equals(_confirmedHammerOldIdentityId) &
                  row.exerciseNameSnapshot.isNull() &
                  row.lastWeightKg.equals(9.0) &
                  row.lastReps.equals(10),
            ))
            .write(
              const WorkoutExerciseResultsCompanion(
                exerciseIdentityId: Value(_confirmedHammerCanonicalIdentityId),
                exerciseNameSnapshot: Value(_confirmedHammerSnapshot),
              ),
            );
    if (changed != 1) return false;

    await enqueueWorkoutSync(
      _confirmedHammerWorkoutExternalId,
      triggerAutoSync: false,
    );
    return true;
  }

  Future<int?> _findCurrentExerciseBinding({
    required String sourceType,
    required int sourceId,
    String? clientId,
  }) async {
    final row = await customSelect(
      clientId == null
          ? '''
            SELECT identity_id
            FROM exercise_identity_bindings
            WHERE client_id IS NULL
              AND source_type = ?
              AND source_id = ?
              AND is_current = 1
            LIMIT 1
          '''
          : '''
            SELECT identity_id
            FROM exercise_identity_bindings
            WHERE client_id = ?
              AND source_type = ?
              AND source_id = ?
              AND is_current = 1
            LIMIT 1
          ''',
      variables: clientId == null
          ? [Variable.withString(sourceType), Variable.withInt(sourceId)]
          : [
              Variable.withString(clientId),
              Variable.withString(sourceType),
              Variable.withInt(sourceId),
            ],
    ).getSingleOrNull();
    return row?.read<int>('identity_id');
  }

  Future<int> _ensureExerciseBinding({
    required String sourceType,
    required int sourceId,
    String? clientId,
  }) async {
    final existing = await _findCurrentExerciseBinding(
      sourceType: sourceType,
      sourceId: sourceId,
      clientId: clientId,
    );
    if (existing != null) return existing;

    final identityId = await _createExerciseIdentity();
    await into(exerciseIdentityBindings).insert(
      ExerciseIdentityBindingsCompanion.insert(
        clientId: Value(clientId),
        sourceType: sourceType,
        sourceId: sourceId,
        identityId: identityId,
      ),
    );
    return identityId;
  }

  Future<void> _bindExerciseIdentity({
    required String sourceType,
    required int sourceId,
    required int identityId,
    String? clientId,
  }) async {
    final current = await _findCurrentExerciseBinding(
      sourceType: sourceType,
      sourceId: sourceId,
      clientId: clientId,
    );
    if (current == identityId) return;
    if (current != null) {
      final clientPredicate = clientId == null
          ? 'client_id IS NULL'
          : 'client_id = ?';
      await customUpdate(
        '''
        UPDATE exercise_identity_bindings
        SET is_current = 0, retired_at = ?
        WHERE $clientPredicate
          AND source_type = ? AND source_id = ? AND is_current = 1
      ''',
        variables: [
          Variable<DateTime>(DateTime.now()),
          if (clientId != null) Variable.withString(clientId),
          Variable.withString(sourceType),
          Variable.withInt(sourceId),
        ],
        updates: {exerciseIdentityBindings},
      );
    }
    await into(exerciseIdentityBindings).insert(
      ExerciseIdentityBindingsCompanion.insert(
        clientId: Value(clientId),
        sourceType: sourceType,
        sourceId: sourceId,
        identityId: identityId,
      ),
    );
  }

  Future<int> _resolveExerciseIdentity({
    required String clientId,
    required int templateExerciseId,
  }) async {
    if (templateExerciseId < 0) {
      final added = await customSelect(
        '''
        SELECT exercise_identity_id FROM client_added_exercises
        WHERE id = ? AND client_id = ? LIMIT 1
      ''',
        variables: [
          Variable.withInt(-templateExerciseId),
          Variable.withString(clientId),
        ],
      ).getSingleOrNull();
      final directIdentity = added?.readNullable<int>('exercise_identity_id');
      if (directIdentity != null) return directIdentity;
      return _ensureExerciseBinding(
        clientId: clientId,
        sourceType: _clientAddedExerciseSource,
        sourceId: -templateExerciseId,
      );
    }

    final clientOverride =
        await (select(clientTemplateExerciseOverrides)
              ..where(
                (row) =>
                    row.clientId.equals(clientId) &
                    row.templateExerciseId.equals(templateExerciseId),
              )
              ..limit(1))
            .getSingleOrNull();
    if (clientOverride?.exerciseIdentityId case final directIdentity?) {
      return directIdentity;
    }

    // Legacy client binding keeps priority until the slot is edited through
    // the catalog selector.
    final clientSpecific = await _findCurrentExerciseBinding(
      clientId: clientId,
      sourceType: _templateExerciseSource,
      sourceId: templateExerciseId,
    );
    if (clientSpecific != null) return clientSpecific;

    final template =
        await (select(workoutTemplateExercises)
              ..where((row) => row.id.equals(templateExerciseId))
              ..limit(1))
            .getSingleOrNull();
    if (template?.exerciseIdentityId case final directIdentity?) {
      return directIdentity;
    }

    return _ensureExerciseBinding(
      sourceType: _templateExerciseSource,
      sourceId: templateExerciseId,
    );
  }

  Future<String?> _resolveExerciseDisplayName({
    required String clientId,
    required int templateExerciseId,
  }) async {
    if (templateExerciseId < 0) {
      final row = await customSelect(
        '''
        SELECT name, exercise_identity_id FROM client_added_exercises
        WHERE id = ? AND client_id = ?
        LIMIT 1
        ''',
        variables: [
          Variable.withInt(-templateExerciseId),
          Variable.withString(clientId),
        ],
      ).getSingleOrNull();
      final identityId = row?.readNullable<int>('exercise_identity_id');
      if (identityId != null) {
        return (await getExerciseById(identityId))?.canonicalName;
      }
      return row?.readNullable<String>('name');
    }

    final clientOverride =
        await (select(clientTemplateExerciseOverrides)
              ..where(
                (row) =>
                    row.clientId.equals(clientId) &
                    row.templateExerciseId.equals(templateExerciseId),
              )
              ..limit(1))
            .getSingleOrNull();
    if (clientOverride?.exerciseIdentityId case final identityId?) {
      return (await getExerciseById(identityId))?.canonicalName;
    }

    final template =
        await (select(workoutTemplateExercises)
              ..where((row) => row.id.equals(templateExerciseId))
              ..limit(1))
            .getSingleOrNull();
    if (template?.exerciseIdentityId case final identityId?) {
      return (await getExerciseById(identityId))?.canonicalName;
    }

    final row = await customSelect(
      '''
      SELECT COALESCE(o.custom_name, e.name) AS effective_name
      FROM workout_template_exercises e
      LEFT JOIN client_exercise_name_overrides o
        ON o.client_id = ? AND o.template_exercise_id = e.id
      WHERE e.id = ?
      LIMIT 1
      ''',
      variables: [
        Variable.withString(clientId),
        Variable.withInt(templateExerciseId),
      ],
    ).getSingleOrNull();
    return row?.readNullable<String>('effective_name');
  }

  Future<String> getExerciseExternalId({
    required String clientId,
    required int templateExerciseId,
  }) async {
    final identityId = await _resolveExerciseIdentity(
      clientId: clientId,
      templateExerciseId: templateExerciseId,
    );
    final row = await (select(
      exerciseIdentities,
    )..where((t) => t.id.equals(identityId))).getSingle();
    return row.externalId;
  }

  /// Создаёт новую логическую identity для существующего программного места.
  /// UI следующего этапа вызовет этот метод только для варианта
  /// «Новое упражнение». Обычное переименование его не вызывает.
  Future<String> replaceExerciseIdentityForClient({
    required String clientId,
    required int templateExerciseId,
  }) async {
    final sourceType = templateExerciseId < 0
        ? _clientAddedExerciseSource
        : _templateExerciseSource;
    return transaction(() async {
      final uuid = await _replaceExerciseIdentityBinding(
        clientId: clientId,
        sourceType: sourceType,
        sourceId: templateExerciseId.abs(),
      );
      final identityId = await _findCurrentExerciseBinding(
        clientId: clientId,
        sourceType: sourceType,
        sourceId: templateExerciseId.abs(),
      );
      if (identityId != null) {
        if (templateExerciseId < 0) {
          await customStatement(
            'UPDATE client_added_exercises SET exercise_identity_id = ? WHERE id = ? AND client_id = ?',
            [identityId, -templateExerciseId, clientId],
          );
        } else {
          final existing =
              await (select(clientTemplateExerciseOverrides)..where(
                    (row) =>
                        row.clientId.equals(clientId) &
                        row.templateExerciseId.equals(templateExerciseId),
                  ))
                  .getSingleOrNull();
          await into(clientTemplateExerciseOverrides).insertOnConflictUpdate(
            ClientTemplateExerciseOverridesCompanion(
              id: existing == null ? const Value.absent() : Value(existing.id),
              clientId: Value(clientId),
              templateExerciseId: Value(templateExerciseId),
              supersetGroup: Value(existing?.supersetGroup),
              exerciseIdentityId: Value(identityId),
            ),
          );
        }
      }
      return uuid;
    });
  }

  /// Меняет общую identity базового упражнения в редакторе шаблонов.
  Future<String> replaceTemplateExerciseIdentity({
    required int templateExerciseId,
  }) {
    return transaction(() async {
      final uuid = await _replaceExerciseIdentityBinding(
        sourceType: _templateExerciseSource,
        sourceId: templateExerciseId,
      );
      final identityId = await _findCurrentExerciseBinding(
        sourceType: _templateExerciseSource,
        sourceId: templateExerciseId,
      );
      if (identityId != null) {
        await (update(
          workoutTemplateExercises,
        )..where((row) => row.id.equals(templateExerciseId))).write(
          WorkoutTemplateExercisesCompanion(
            exerciseIdentityId: Value(identityId),
          ),
        );
      }
      return uuid;
    });
  }

  Future<String> _replaceExerciseIdentityBinding({
    required String sourceType,
    required int sourceId,
    String? clientId,
  }) async {
    final now = DateTime.now();
    final clientPredicate = clientId == null
        ? 'client_id IS NULL'
        : 'client_id = ?';
    final variables = <Variable<Object>>[
      Variable<DateTime>(now),
      if (clientId != null) Variable.withString(clientId),
      Variable.withString(sourceType),
      Variable.withInt(sourceId),
    ];

    await customUpdate(
      '''
      UPDATE exercise_identity_bindings
      SET is_current = 0, retired_at = ?
      WHERE $clientPredicate
        AND source_type = ?
        AND source_id = ?
        AND is_current = 1
      ''',
      variables: variables,
      updates: {exerciseIdentityBindings},
    );

    final identityId = await _createExerciseIdentity();
    await into(exerciseIdentityBindings).insert(
      ExerciseIdentityBindingsCompanion.insert(
        clientId: Value(clientId),
        sourceType: sourceType,
        sourceId: sourceId,
        identityId: identityId,
      ),
    );
    final identity = await (select(
      exerciseIdentities,
    )..where((t) => t.id.equals(identityId))).getSingle();
    return identity.externalId;
  }

  Future<void> _backfillExternalIdentities() async {
    await transaction(() async {
      await customStatement(
        "UPDATE clients SET status = 'ACTIVE' "
        "WHERE status IS NULL OR TRIM(status) = ''",
      );

      final clientsWithoutUuid = await customSelect(
        "SELECT id FROM clients WHERE external_id IS NULL OR TRIM(external_id) = ''",
      ).get();
      for (final row in clientsWithoutUuid) {
        await customStatement(
          'UPDATE clients SET external_id = ? WHERE id = ?',
          [await _newUniqueUuidForTable('clients'), row.read<String>('id')],
        );
      }

      final sessionsWithoutUuid = await customSelect(
        "SELECT id FROM workout_sessions WHERE external_id IS NULL OR TRIM(external_id) = ''",
      ).get();
      for (final row in sessionsWithoutUuid) {
        await customStatement(
          'UPDATE workout_sessions SET external_id = ? WHERE id = ?',
          [
            await _newUniqueUuidForTable('workout_sessions'),
            row.read<int>('id'),
          ],
        );
      }

      final templateRows = await customSelect(
        'SELECT id FROM workout_template_exercises ORDER BY id',
      ).get();
      for (final row in templateRows) {
        await _ensureExerciseBinding(
          sourceType: _templateExerciseSource,
          sourceId: row.read<int>('id'),
        );
      }

      await _ensureClientAddedExercisesTable();
      final addedRows = await customSelect(
        'SELECT id, client_id FROM client_added_exercises ORDER BY id',
      ).get();
      for (final row in addedRows) {
        await _ensureExerciseBinding(
          clientId: row.read<String>('client_id'),
          sourceType: _clientAddedExerciseSource,
          sourceId: row.read<int>('id'),
        );
      }

      // v12: materialize the catalog link for legacy slots. Existing
      // client-specific bindings remain represented by the client override,
      // so no historical identity is merged or replaced here.
      await customStatement('''
        UPDATE workout_template_exercises
        SET exercise_identity_id = (
          SELECT b.identity_id
          FROM exercise_identity_bindings b
          WHERE b.client_id IS NULL
            AND b.source_type = 'TEMPLATE'
            AND b.source_id = workout_template_exercises.id
            AND b.is_current = 1
          LIMIT 1
        )
        WHERE exercise_identity_id IS NULL
           OR NOT EXISTS (
             SELECT 1 FROM exercise_identities i
             WHERE i.id = workout_template_exercises.exercise_identity_id
           )
      ''');
      await customStatement('''
        UPDATE client_added_exercises
        SET exercise_identity_id = (
          SELECT b.identity_id
          FROM exercise_identity_bindings b
          WHERE b.client_id = client_added_exercises.client_id
            AND b.source_type = 'CLIENT_ADDED'
            AND b.source_id = client_added_exercises.id
            AND b.is_current = 1
          LIMIT 1
        )
        WHERE exercise_identity_id IS NULL
           OR NOT EXISTS (
             SELECT 1 FROM exercise_identities i
             WHERE i.id = client_added_exercises.exercise_identity_id
           )
      ''');
      await customStatement('''
        UPDATE client_template_exercise_overrides
        SET exercise_identity_id = (
          SELECT b.identity_id
          FROM exercise_identity_bindings b
          WHERE b.client_id = client_template_exercise_overrides.client_id
            AND b.source_type = 'TEMPLATE'
            AND b.source_id = client_template_exercise_overrides.template_exercise_id
            AND b.is_current = 1
          LIMIT 1
        )
        WHERE exercise_identity_id IS NULL
           OR NOT EXISTS (
             SELECT 1 FROM exercise_identities i
             WHERE i.id = client_template_exercise_overrides.exercise_identity_id
           )
      ''');
      await _backfillExerciseCatalogMetadata();

      final resultRows = await customSelect('''
        SELECT r.id AS result_id,
               r.template_exercise_id AS template_exercise_id,
               r.exercise_identity_id AS exercise_identity_id,
               r.exercise_name_snapshot AS exercise_name_snapshot,
               s.client_id AS client_id
        FROM workout_exercise_results r
        LEFT JOIN workout_sessions s ON s.id = r.session_id
        WHERE r.exercise_identity_id IS NULL
           OR r.exercise_name_snapshot IS NULL
        ORDER BY r.id
      ''').get();

      for (final row in resultRows) {
        final resultId = row.read<int>('result_id');
        final sourceId = row.read<int>('template_exercise_id');
        final clientId = row.readNullable<String>('client_id');
        final existingIdentityId = row.readNullable<int>(
          'exercise_identity_id',
        );
        final existingName = row.readNullable<String>('exercise_name_snapshot');

        final identityId =
            existingIdentityId ??
            (clientId == null
                ? await _createExerciseIdentity()
                : await _resolveExerciseIdentity(
                    clientId: clientId,
                    templateExerciseId: sourceId,
                  ));
        final exerciseName =
            existingName ??
            (clientId == null
                ? null
                : await _resolveExerciseDisplayName(
                    clientId: clientId,
                    templateExerciseId: sourceId,
                  ));
        await customStatement(
          'UPDATE workout_exercise_results '
          'SET exercise_identity_id = ?, exercise_name_snapshot = ? '
          'WHERE id = ?',
          [identityId, exerciseName, resultId],
        );
      }

      await _validateExternalIdentityState();
    });
  }

  Future<void> _backfillExerciseCatalogMetadata() async {
    final identities = await select(exerciseIdentities).get();
    for (final identity in identities) {
      final existingName = _displayExerciseName(identity.canonicalName);
      final existingNormalized = normalizeExerciseName(existingName);
      final needsName = existingName.isEmpty;
      final needsNormalized = identity.normalizedName != existingNormalized;
      final invalidStatus =
          identity.status != activeExerciseStatus &&
          identity.status != archivedExerciseStatus;
      if (!needsName && !needsNormalized && !invalidStatus) continue;

      String? sourceName;
      final binding = await customSelect(
        '''
        SELECT client_id, source_type, source_id
        FROM exercise_identity_bindings
        WHERE identity_id = ? AND is_current = 1
        ORDER BY CASE WHEN client_id IS NULL THEN 0 ELSE 1 END, id
        LIMIT 1
      ''',
        variables: [Variable.withInt(identity.id)],
      ).getSingleOrNull();
      if (binding != null) {
        final sourceType = binding.read<String>('source_type');
        final sourceId = binding.read<int>('source_id');
        final clientId = binding.readNullable<String>('client_id');
        if (sourceType == _templateExerciseSource) {
          final row = await customSelect(
            '''
            SELECT COALESCE(o.custom_name, e.name) AS name
            FROM workout_template_exercises e
            LEFT JOIN client_exercise_name_overrides o
              ON o.client_id = ? AND o.template_exercise_id = e.id
            WHERE e.id = ?
            LIMIT 1
          ''',
            variables: [
              Variable.withString(clientId ?? ''),
              Variable.withInt(sourceId),
            ],
          ).getSingleOrNull();
          sourceName = row?.readNullable<String>('name');
        } else if (sourceType == _clientAddedExerciseSource) {
          final row = await customSelect(
            'SELECT name FROM client_added_exercises WHERE id = ? LIMIT 1',
            variables: [Variable.withInt(sourceId)],
          ).getSingleOrNull();
          sourceName = row?.readNullable<String>('name');
        }
      }
      sourceName ??= (await customSelect(
        '''
        SELECT exercise_name_snapshot
        FROM workout_exercise_results
        WHERE exercise_identity_id = ?
          AND exercise_name_snapshot IS NOT NULL
          AND TRIM(exercise_name_snapshot) != ''
        ORDER BY id DESC
        LIMIT 1
      ''',
        variables: [Variable.withInt(identity.id)],
      ).getSingleOrNull())?.readNullable<String>('exercise_name_snapshot');
      final resolvedName = _displayExerciseName(
        sourceName ?? 'Неизвестное упражнение ${identity.id}',
      );
      await (update(
        exerciseIdentities,
      )..where((row) => row.id.equals(identity.id))).write(
        ExerciseIdentitiesCompanion(
          canonicalName: Value(needsName ? resolvedName : existingName),
          normalizedName: Value(
            normalizeExerciseName(needsName ? resolvedName : existingName),
          ),
          status: Value(invalidStatus ? activeExerciseStatus : identity.status),
        ),
      );
    }
  }

  Future<void> _validateExternalIdentityState() async {
    Future<int> scalarCount(String sql) async {
      final row = await customSelect(sql).getSingle();
      return row.read<int>('c');
    }

    final missingClients = await scalarCount(
      "SELECT COUNT(*) AS c FROM clients WHERE external_id IS NULL OR TRIM(external_id) = ''",
    );
    final duplicateClients = await scalarCount('''
      SELECT COUNT(*) AS c FROM (
        SELECT external_id FROM clients GROUP BY external_id HAVING COUNT(*) > 1
      )
    ''');
    final invalidStatuses = await scalarCount('''
      SELECT COUNT(*) AS c FROM clients
      WHERE status NOT IN ('ACTIVE', 'ARCHIVED')
    ''');
    final missingSessions = await scalarCount(
      "SELECT COUNT(*) AS c FROM workout_sessions WHERE external_id IS NULL OR TRIM(external_id) = ''",
    );
    final duplicateSessions = await scalarCount('''
      SELECT COUNT(*) AS c FROM (
        SELECT external_id FROM workout_sessions GROUP BY external_id HAVING COUNT(*) > 1
      )
    ''');
    final missingResultIdentities = await scalarCount('''
      SELECT COUNT(*) AS c FROM workout_exercise_results
      WHERE exercise_identity_id IS NULL
    ''');
    final danglingResultIdentities = await scalarCount('''
      SELECT COUNT(*) AS c
      FROM workout_exercise_results r
      LEFT JOIN exercise_identities i ON i.id = r.exercise_identity_id
      WHERE r.exercise_identity_id IS NOT NULL AND i.id IS NULL
    ''');
    final danglingBindings = await scalarCount('''
      SELECT COUNT(*) AS c
      FROM exercise_identity_bindings b
      LEFT JOIN exercise_identities i ON i.id = b.identity_id
      WHERE i.id IS NULL
    ''');

    if (missingClients != 0 ||
        duplicateClients != 0 ||
        invalidStatuses != 0 ||
        missingSessions != 0 ||
        duplicateSessions != 0 ||
        missingResultIdentities != 0 ||
        danglingResultIdentities != 0 ||
        danglingBindings != 0) {
      throw StateError(
        'Проверка внешних идентификаторов не пройдена: '
        'clientsMissing=$missingClients, clientsDuplicate=$duplicateClients, '
        'invalidStatuses=$invalidStatuses, sessionsMissing=$missingSessions, '
        'sessionsDuplicate=$duplicateSessions, '
        'resultIdentitiesMissing=$missingResultIdentities, '
        'resultIdentitiesDangling=$danglingResultIdentities, '
        'bindingsDangling=$danglingBindings',
      );
    }
  }

  // --- Offline-first sync infrastructure ---
  Future<SyncClientPayload> _buildSyncClientPayload(Client client) async {
    final clientExternalId = client.externalId?.trim() ?? '';
    if (clientExternalId.isEmpty) {
      throw StateError('У клиента отсутствует внешний UUID');
    }
    final programState = await getProgramStateForClient(client.id);
    final parsedPlanSize = _parsePlanSize(client.plan);
    final subscriptionSize = const {4, 8, 12}.contains(parsedPlanSize)
        ? parsedPlanSize
        : null;
    final remainingSessions = subscriptionSize == null || programState == null
        ? null
        : _remainingSessions(
            planSize: subscriptionSize,
            completedInPlan: programState.completedInPlan,
          );
    return SyncClientPayload(
      clientExternalId: clientExternalId,
      name: client.name,
      gender: switch (client.gender?.trim()) {
        'М' => 'male',
        'Ж' => 'female',
        _ => null,
      },
      subscriptionSize: subscriptionSize,
      subscriptionStart: client.planStart == null
          ? null
          : syncDateOnly(client.planStart!),
      subscriptionEnd: client.planEnd == null
          ? null
          : syncDateOnly(client.planEnd!),
      remainingSessions: remainingSessions,
    );
  }

  bool _isTrialWorkoutSession(WorkoutSession session) => session.gender == 'П';

  Future<WorkoutSyncPayload?> buildWorkoutSyncPayload(
    String workoutExternalId,
  ) async {
    final normalizedId = workoutExternalId.trim();
    if (normalizedId.isEmpty) return null;

    final session =
        await (select(workoutSessions)
              ..where((row) => row.externalId.equals(normalizedId))
              ..limit(1))
            .getSingleOrNull();
    if (session == null) return null;
    if (_isTrialWorkoutSession(session)) return null;

    final client = await getClientById(session.clientId);
    if (client == null) {
      throw StateError('У тренировки отсутствует клиент');
    }
    final syncClient = await _buildSyncClientPayload(client);

    final template =
        await (select(workoutTemplates)
              ..where(
                (row) =>
                    row.gender.equals(session.gender) &
                    row.idx.equals(session.templateIdx),
              )
              ..limit(1))
            .getSingleOrNull();
    final results =
        await (select(workoutExerciseResults)
              ..where((row) => row.sessionId.equals(session.id))
              ..orderBy([(row) => OrderingTerm.asc(row.id)]))
            .get();

    final exercises = <WorkoutSyncExerciseSource>[];
    for (final result in results) {
      final identityId = result.exerciseIdentityId;
      final historicalName = result.exerciseNameSnapshot?.trim() ?? '';
      if (identityId == null || historicalName.isEmpty) {
        throw StateError(
          'У результата ${result.id} отсутствует историческая identity',
        );
      }
      final canonicalIdentityId = await _resolveCanonicalExerciseIdentityId(
        identityId,
      );
      final identity =
          await (select(exerciseIdentities)
                ..where((row) => row.id.equals(canonicalIdentityId))
                ..limit(1))
              .getSingleOrNull();
      final exerciseExternalId = identity?.externalId.trim() ?? '';
      if (exerciseExternalId.isEmpty) {
        throw StateError(
          'У результата ${result.id} отсутствует внешний UUID упражнения',
        );
      }
      exercises.add(
        WorkoutSyncExerciseSource(
          exerciseExternalId: exerciseExternalId,
          name: historicalName,
          weightKg: result.lastWeightKg,
          reps: result.lastReps,
        ),
      );
    }

    return WorkoutSyncPayload.fromSource(
      WorkoutSyncSource(
        client: syncClient,
        workoutExternalId: normalizedId,
        performedAt: session.performedAt,
        workoutName: template == null
            ? null
            : (template.title.trim().isNotEmpty
                  ? template.title.trim()
                  : (template.label.trim().isEmpty
                        ? null
                        : template.label.trim())),
        exercises: exercises,
      ),
    );
  }

  Future<ScheduleSyncPayload?> buildScheduleSyncPayload(
    String clientExternalId,
  ) async {
    final normalizedId = clientExternalId.trim();
    if (normalizedId.isEmpty) return null;
    final client =
        await (select(clients)
              ..where((row) => row.externalId.equals(normalizedId))
              ..limit(1))
            .getSingleOrNull();
    if (client == null) return null;
    final syncClient = await _buildSyncClientPayload(client);

    final range = clientAppointmentsWeekRange(DateTime.now());
    final appointments = await getAppointmentsForClientInRange(
      clientId: client.id,
      fromInclusive: range.fromInclusive,
      toExclusive: range.toExclusive,
    );
    return ScheduleSyncPayload.fromRange(
      client: syncClient,
      fromInclusive: range.fromInclusive,
      toExclusive: range.toExclusive,
      appointmentStarts: [for (final item in appointments) item.startAt],
    );
  }

  Future<WorkoutSyncQueueRebuildPreview>
  analyzeWorkoutSyncQueueRebuild() async {
    final sessions =
        await (select(workoutSessions)..orderBy([
              (row) => OrderingTerm.asc(row.performedAt),
              (row) => OrderingTerm.asc(row.id),
            ]))
            .get();
    final clientRows = await select(clients).get();
    final clientsById = {for (final client in clientRows) client.id: client};
    final resultCountRows = await customSelect(
      '''
      SELECT session_id, COUNT(*) AS result_count
      FROM workout_exercise_results
      GROUP BY session_id
      ''',
      readsFrom: {workoutExerciseResults},
    ).get();
    final resultCounts = {
      for (final row in resultCountRows)
        row.read<int>('session_id'): row.read<int>('result_count'),
    };

    var emptySessions = 0;
    var missingClients = 0;
    var missingWorkoutExternalIds = 0;
    var payloadErrors = 0;
    final nonEmptySessions = <WorkoutSession>[];

    for (final session in sessions) {
      if (_isTrialWorkoutSession(session)) continue;
      if ((resultCounts[session.id] ?? 0) == 0) {
        emptySessions++;
        continue;
      }
      nonEmptySessions.add(session);
    }

    final conflictGroups =
        <(String, int, int, int, int, int), List<WorkoutSession>>{};
    for (final session in nonEmptySessions) {
      final localDate = session.performedAt.toLocal();
      final key = (
        session.clientId,
        localDate.year,
        localDate.month,
        localDate.day,
        session.templateIdx,
        session.planInstance,
      );
      conflictGroups.putIfAbsent(key, () => []).add(session);
    }

    final conflictSessionIds = <int>{};
    final conflicts = <WorkoutSyncQueueConflict>[];
    for (final entry in conflictGroups.entries) {
      if (entry.value.length < 2) continue;
      final first = entry.value.first;
      final sessionsInConflict = [
        for (final session in entry.value)
          WorkoutSyncQueueConflictSession(
            sessionId: session.id,
            workoutExternalId: session.externalId?.trim() ?? '',
            performedAt: session.performedAt,
          ),
      ];
      conflictSessionIds.addAll(
        sessionsInConflict.map((session) => session.sessionId),
      );
      conflicts.add(
        WorkoutSyncQueueConflict(
          clientId: first.clientId,
          clientName: clientsById[first.clientId]?.name ?? 'Удалённый клиент',
          calendarDate: DateTime(entry.key.$2, entry.key.$3, entry.key.$4),
          templateIdx: first.templateIdx,
          planInstance: first.planInstance,
          sessions: List.unmodifiable(sessionsInConflict),
        ),
      );
    }

    final preparedByWorkoutUuid = <String, _PreparedWorkoutSyncTask>{};
    for (final session in nonEmptySessions) {
      final client = clientsById[session.clientId];
      if (client == null) {
        missingClients++;
        continue;
      }
      if ((session.externalId?.trim() ?? '').isEmpty) {
        missingWorkoutExternalIds++;
        continue;
      }
      if (conflictSessionIds.contains(session.id)) continue;
      final workoutExternalId = session.externalId!.trim();
      try {
        final payload = await buildWorkoutSyncPayload(workoutExternalId);
        if (payload == null) {
          payloadErrors++;
          continue;
        }
        preparedByWorkoutUuid.putIfAbsent(
          workoutExternalId,
          () => _PreparedWorkoutSyncTask(
            workoutExternalId: workoutExternalId,
            payload: payload.encode(),
            performedAt: session.performedAt,
          ),
        );
      } on StateError {
        payloadErrors++;
      } on FormatException {
        payloadErrors++;
      }
    }

    final tasks = preparedByWorkoutUuid.values.toList()
      ..sort((a, b) {
        final byDate = a.performedAt.compareTo(b.performedAt);
        return byDate != 0
            ? byDate
            : a.workoutExternalId.compareTo(b.workoutExternalId);
      });
    conflicts.sort((a, b) {
      final byDate = a.calendarDate.compareTo(b.calendarDate);
      return byDate != 0 ? byDate : a.clientName.compareTo(b.clientName);
    });

    return WorkoutSyncQueueRebuildPreview._(
      totalSessions: sessions.length,
      emptySessions: emptySessions,
      missingClients: missingClients,
      missingWorkoutExternalIds: missingWorkoutExternalIds,
      payloadErrors: payloadErrors,
      conflicts: List.unmodifiable(conflicts),
      tasks: List.unmodifiable(tasks),
    );
  }

  Future<WorkoutSyncQueueRebuildResult> rebuildWorkoutSyncQueue(
    WorkoutSyncQueueRebuildPreview preview,
  ) {
    // Rebuild only prepares a pending snapshot for an explicit manual run. It
    // intentionally bypasses enqueue helpers, so it never starts HTTP sync.
    return transaction(() async {
      await (delete(
        syncQueue,
      )..where((row) => row.entityType.equals(SyncEntityTypes.workout))).go();

      final rebuiltAt = DateTime.now();
      for (final task in preview._tasks) {
        await into(syncQueue).insert(
          SyncQueueCompanion.insert(
            entityType: SyncEntityTypes.workout,
            entityExternalId: task.workoutExternalId,
            operation: SyncOperations.workoutUpsert,
            payload: task.payload,
            status: const Value(SyncQueueStatuses.pending),
            attempts: const Value(0),
            createdAt: Value(task.performedAt),
            updatedAt: Value(rebuiltAt),
            lastAttemptAt: const Value(null),
            nextAttemptAt: const Value(null),
            lastError: const Value(null),
          ),
        );
      }

      return WorkoutSyncQueueRebuildResult(
        createdTasks: preview.tasksToCreate,
        emptySessions: preview.emptySessions,
        missingClients: preview.missingClients,
        missingWorkoutExternalIds: preview.missingWorkoutExternalIds,
        conflictSessions: preview.conflictSessions,
        payloadErrors: preview.payloadErrors,
      );
    });
  }

  Future<SyncQueueEntry> enqueueWorkoutSync(
    String workoutExternalId, {
    bool triggerAutoSync = true,
  }) async {
    final payload = await buildWorkoutSyncPayload(workoutExternalId);
    if (payload == null) {
      throw StateError('Завершённая тренировка не найдена');
    }
    final task = await upsertSyncQueueTask(
      entityType: SyncEntityTypes.workout,
      entityExternalId: payload.workoutExternalId,
      operation: SyncOperations.workoutUpsert,
      payload: payload.encode(),
    );
    if (triggerAutoSync) _triggerAutomaticSync();
    return task;
  }

  Future<int> deleteQueuedTrialWorkoutSyncTasks() {
    return customUpdate(
      '''
      DELETE FROM sync_queue
      WHERE entity_type = ?
        AND operation = ?
        AND EXISTS (
          SELECT 1
          FROM workout_sessions w
          WHERE w.external_id = sync_queue.entity_external_id
            AND w.gender = 'П'
        )
      ''',
      variables: [
        Variable.withString(SyncEntityTypes.workout),
        Variable.withString(SyncOperations.workoutUpsert),
      ],
      updates: {syncQueue},
      updateKind: UpdateKind.delete,
    );
  }

  Future<SyncQueueEntry> enqueueScheduleSync(
    String clientExternalId, {
    bool triggerAutoSync = true,
  }) async {
    final payload = await buildScheduleSyncPayload(clientExternalId);
    if (payload == null) {
      throw StateError('Клиент для синхронизации расписания не найден');
    }
    final task = await upsertSyncQueueTask(
      entityType: SyncEntityTypes.client,
      entityExternalId: payload.clientExternalId,
      operation: SyncOperations.scheduleUpsert,
      payload: payload.encode(),
    );
    if (triggerAutoSync) _triggerAutomaticSync();
    return task;
  }

  Future<SyncQueueEntry> upsertSyncQueueTask({
    required String entityType,
    required String entityExternalId,
    required String operation,
    required String payload,
  }) {
    return transaction(() async {
      final now = DateTime.now();
      final existing =
          await (select(syncQueue)
                ..where(
                  (row) =>
                      row.entityType.equals(entityType) &
                      row.entityExternalId.equals(entityExternalId) &
                      row.operation.equals(operation),
                )
                ..limit(1))
              .getSingleOrNull();

      if (existing == null) {
        final id = await into(syncQueue).insert(
          SyncQueueCompanion.insert(
            entityType: entityType,
            entityExternalId: entityExternalId,
            operation: operation,
            payload: payload,
            updatedAt: Value(now),
          ),
        );
        return (select(
          syncQueue,
        )..where((row) => row.id.equals(id))).getSingle();
      }

      await (update(
        syncQueue,
      )..where((row) => row.id.equals(existing.id))).write(
        SyncQueueCompanion(
          payload: Value(payload),
          status: const Value(SyncQueueStatuses.pending),
          updatedAt: Value(now),
          nextAttemptAt: const Value(null),
          lastError: const Value(null),
        ),
      );
      return (select(
        syncQueue,
      )..where((row) => row.id.equals(existing.id))).getSingle();
    });
  }

  Future<bool> _enqueueWorkoutSyncSafely(
    String? workoutExternalId, {
    bool triggerAutoSync = true,
  }) async {
    if (workoutExternalId == null || workoutExternalId.trim().isEmpty) {
      return false;
    }
    try {
      await enqueueWorkoutSync(
        workoutExternalId,
        triggerAutoSync: triggerAutoSync,
      );
      return true;
    } catch (_) {
      // Локальная тренировка уже зафиксирована. Ошибка инфраструктуры sync
      // не должна отменять или скрывать её от пользователя.
      return false;
    }
  }

  Future<void> _enqueueScheduleForClientSafely(String clientId) async {
    try {
      final client =
          await (select(clients)
                ..where((row) => row.id.equals(clientId))
                ..limit(1))
              .getSingleOrNull();
      final clientExternalId = client?.externalId?.trim();
      if (clientExternalId == null || clientExternalId.isEmpty) return;
      await enqueueScheduleSync(clientExternalId);
    } catch (_) {
      // Календарь остаётся offline-first: сбой sync-инфраструктуры не должен
      // отменять уже выполненное локальное изменение расписания.
    }
  }

  Future<void> _enqueueAllExistingWorkoutSessionsForSync() async {
    final sessions =
        await (select(workoutSessions)
              ..where(
                (row) =>
                    row.externalId.isNotNull() & row.gender.equals('П').not(),
              )
              ..orderBy([(row) => OrderingTerm.asc(row.id)]))
            .get();
    for (final session in sessions) {
      await _enqueueWorkoutSyncSafely(
        session.externalId,
        triggerAutoSync: false,
      );
    }
  }

  Future<List<SyncQueueEntry>> getPendingSyncTasks() async {
    final now = DateTime.now();
    return (select(syncQueue)
          ..where(
            (row) =>
                (row.status.equals(SyncQueueStatuses.pending) |
                    row.status.equals(SyncQueueStatuses.failed)) &
                (row.nextAttemptAt.isNull() |
                    row.nextAttemptAt.isSmallerOrEqualValue(now)),
          )
          ..orderBy([(row) => OrderingTerm.asc(row.createdAt)]))
        .get();
  }

  Future<SyncQueueEntry?> getNextPendingSyncTask() async {
    final now = DateTime.now();
    final query =
        select(syncQueue).join([
            leftOuterJoin(
              workoutSessions,
              workoutSessions.externalId.equalsExp(syncQueue.entityExternalId),
            ),
          ])
          ..where(
            (syncQueue.status.equals(SyncQueueStatuses.pending) |
                    syncQueue.status.equals(SyncQueueStatuses.failed)) &
                (syncQueue.nextAttemptAt.isNull() |
                    syncQueue.nextAttemptAt.isSmallerOrEqualValue(now)),
          )
          ..orderBy([
            OrderingTerm.asc(workoutSessions.performedAt),
            OrderingTerm.asc(syncQueue.createdAt),
          ])
          ..limit(1);
    final row = await query.getSingleOrNull();
    return row?.readTable(syncQueue);
  }

  Future<int> getPendingSyncTaskCount() async {
    final row = await customSelect(
      "SELECT COUNT(*) AS c FROM sync_queue WHERE status IN ('PENDING', 'FAILED')",
      readsFrom: {syncQueue},
    ).getSingle();
    return row.read<int>('c');
  }

  Future<List<PendingWorkoutSyncClientVm>>
  getPendingWorkoutSyncClients() async {
    final rows = await customSelect(
      '''
      SELECT c.id AS client_id, c.name AS client_name, COUNT(q.id) AS task_count
      FROM sync_queue q
      INNER JOIN workout_sessions w ON w.external_id = q.entity_external_id
      INNER JOIN clients c ON c.id = w.client_id
      WHERE q.entity_type = ?
        AND q.operation = ?
        AND q.status IN (?, ?)
      GROUP BY c.id, c.name
      ORDER BY c.name COLLATE NOCASE ASC
      ''',
      variables: [
        Variable.withString(SyncEntityTypes.workout),
        Variable.withString(SyncOperations.workoutUpsert),
        Variable.withString(SyncQueueStatuses.pending),
        Variable.withString(SyncQueueStatuses.failed),
      ],
      readsFrom: {syncQueue, workoutSessions, clients},
    ).get();
    return [
      for (final row in rows)
        PendingWorkoutSyncClientVm(
          clientId: row.read<String>('client_id'),
          name: row.read<String>('client_name'),
          pendingWorkoutCount: row.read<int>('task_count'),
        ),
    ];
  }

  Future<List<PendingWorkoutSyncTaskVm>> getPendingWorkoutSyncTasksForClient(
    String clientId,
  ) async {
    final rows = await customSelect(
      '''
      SELECT q.id AS task_id,
             q.entity_external_id AS workout_external_id,
             w.performed_at AS performed_at,
             t.label AS day_label,
             t.title AS day_title,
             COUNT(r.id) AS exercise_count
      FROM sync_queue q
      INNER JOIN workout_sessions w ON w.external_id = q.entity_external_id
      LEFT JOIN workout_templates t
        ON t.gender = w.gender AND t.idx = w.template_idx
      LEFT JOIN workout_exercise_results r ON r.session_id = w.id
      WHERE q.entity_type = ?
        AND q.operation = ?
        AND q.status IN (?, ?)
        AND w.client_id = ?
      GROUP BY q.id, q.entity_external_id, w.performed_at, t.label, t.title
      ORDER BY w.performed_at DESC, q.id DESC
      ''',
      variables: [
        Variable.withString(SyncEntityTypes.workout),
        Variable.withString(SyncOperations.workoutUpsert),
        Variable.withString(SyncQueueStatuses.pending),
        Variable.withString(SyncQueueStatuses.failed),
        Variable.withString(clientId),
      ],
      readsFrom: {
        syncQueue,
        workoutSessions,
        workoutTemplates,
        workoutExerciseResults,
      },
    ).get();
    return [
      for (final row in rows)
        PendingWorkoutSyncTaskVm(
          taskId: row.read<int>('task_id'),
          workoutExternalId: row.read<String>('workout_external_id'),
          performedAt: row.read<DateTime>('performed_at'),
          dayLabel: row.readNullable<String>('day_label'),
          dayTitle: row.readNullable<String>('day_title'),
          exerciseCount: row.read<int>('exercise_count'),
        ),
    ];
  }

  Future<SyncQueueEntry?> getPendingWorkoutSyncTask(int taskId) async {
    await deleteQueuedTrialWorkoutSyncTasks();
    return (select(syncQueue)
          ..where(
            (row) =>
                row.id.equals(taskId) &
                row.entityType.equals(SyncEntityTypes.workout) &
                row.operation.equals(SyncOperations.workoutUpsert) &
                (row.status.equals(SyncQueueStatuses.pending) |
                    row.status.equals(SyncQueueStatuses.failed)),
          )
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> recoverInterruptedSyncTasks() async {
    await (update(
      syncQueue,
    )..where((row) => row.status.equals(SyncQueueStatuses.processing))).write(
      SyncQueueCompanion(
        status: const Value(SyncQueueStatuses.pending),
        updatedAt: Value(DateTime.now()),
        lastError: const Value('Предыдущая попытка была прервана'),
      ),
    );
    await deleteQueuedTrialWorkoutSyncTasks();
  }

  Future<SyncQueueEntry?> beginSyncAttempt(int id) {
    return transaction(() async {
      final entry =
          await (select(syncQueue)
                ..where((row) => row.id.equals(id))
                ..limit(1))
              .getSingleOrNull();
      if (entry == null) return null;
      final now = DateTime.now();
      await (update(syncQueue)..where((row) => row.id.equals(id))).write(
        SyncQueueCompanion(
          status: const Value(SyncQueueStatuses.processing),
          attempts: Value(entry.attempts + 1),
          updatedAt: Value(now),
          lastAttemptAt: Value(now),
          lastError: const Value(null),
        ),
      );
      return (select(syncQueue)..where((row) => row.id.equals(id))).getSingle();
    });
  }

  Future<void> markSyncTaskForRetry(int id, String message) async {
    final shortMessage = message.trim();
    await (update(syncQueue)..where((row) => row.id.equals(id))).write(
      SyncQueueCompanion(
        status: const Value(SyncQueueStatuses.pending),
        updatedAt: Value(DateTime.now()),
        lastError: Value(
          shortMessage.length <= 500
              ? shortMessage
              : shortMessage.substring(0, 500),
        ),
      ),
    );
  }

  Future<void> markSyncTaskAsPermanentFailure(int id, String message) async {
    final shortMessage = message.trim();
    await (update(syncQueue)..where((row) => row.id.equals(id))).write(
      SyncQueueCompanion(
        status: const Value(SyncQueueStatuses.failed),
        updatedAt: Value(DateTime.now()),
        lastError: Value(
          shortMessage.length <= 500
              ? shortMessage
              : shortMessage.substring(0, 500),
        ),
      ),
    );
  }

  Future<bool> deleteSyncTaskAfterSuccess({
    required int id,
    required String sentPayload,
  }) async {
    final deleted =
        await (delete(syncQueue)..where(
              (row) => row.id.equals(id) & row.payload.equals(sentPayload),
            ))
            .go();
    return deleted > 0;
  }

  Future<void> deleteWorkoutSyncTask(String? workoutExternalId) async {
    if (workoutExternalId == null || workoutExternalId.trim().isEmpty) return;
    await (delete(syncQueue)..where(
          (row) =>
              row.entityType.equals(SyncEntityTypes.workout) &
              row.entityExternalId.equals(workoutExternalId) &
              row.operation.equals(SyncOperations.workoutUpsert),
        ))
        .go();
  }

  Future<void> addSyncLog({
    required String entityType,
    required String entityExternalId,
    required String result,
    required int attemptNumber,
    int? httpStatus,
    String? message,
    DateTime? timestamp,
  }) async {
    final normalizedMessage = message?.trim();
    final shortMessage = normalizedMessage == null
        ? null
        : (normalizedMessage.length <= 500
              ? normalizedMessage
              : normalizedMessage.substring(0, 500));
    await into(syncLog).insert(
      SyncLogCompanion.insert(
        timestamp: Value(timestamp ?? DateTime.now()),
        entityType: entityType,
        entityExternalId: entityExternalId,
        result: result,
        httpStatus: Value(httpStatus),
        message: Value(shortMessage),
        attemptNumber: attemptNumber,
      ),
    );
  }

  Future<List<SyncLogEntry>> getRecentSyncLogs({int limit = 50}) {
    return (select(syncLog)
          ..orderBy([(row) => OrderingTerm.desc(row.timestamp)])
          ..limit(limit))
        .get();
  }

  Future<DateTime?> getLastSuccessfulSyncAt() async {
    final row =
        await (select(syncLog)
              ..where((entry) => entry.result.equals(SyncLogResults.success))
              ..orderBy([(entry) => OrderingTerm.desc(entry.timestamp)])
              ..limit(1))
            .getSingleOrNull();
    return row?.timestamp;
  }

  Future<int> cleanupSyncLogs({DateTime? now}) {
    final cutoff = (now ?? DateTime.now()).subtract(const Duration(days: 7));
    return (delete(
      syncLog,
    )..where((entry) => entry.timestamp.isSmallerThanValue(cutoff))).go();
  }

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
        name TEXT NOT NULL,
        exercise_identity_id INTEGER
      )
    ''');
    final columns = await customSelect(
      'PRAGMA table_info(client_added_exercises)',
    ).get();
    final hasIdentity = columns.any(
      (row) => row.read<String>('name') == 'exercise_identity_id',
    );
    if (!hasIdentity) {
      await customStatement(
        'ALTER TABLE client_added_exercises ADD COLUMN exercise_identity_id INTEGER',
      );
    }
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

    final catalog = {
      for (final identity in await select(exerciseIdentities).get())
        identity.id: identity,
    };
    final clientIdentityOverrides = {
      for (final override in await (select(
        clientTemplateExerciseOverrides,
      )..where((row) => row.clientId.equals(clientId))).get())
        override.templateExerciseId: override.exerciseIdentityId,
    };

    final addedRows = await customSelect(
      '''
        SELECT id, template_id, order_index, name, exercise_identity_id
      FROM client_added_exercises
      WHERE client_id = ? AND template_id = ?
      ORDER BY order_index ASC, id ASC
      ''',
      variables: [Variable.withString(clientId), Variable.withInt(templateId)],
    ).get();

    final merged = <({int id, int templateId, int orderIndex, String name})>[];

    for (final e in baseExercises) {
      if (hiddenIds.contains(e.id)) continue;
      final identityId = clientIdentityOverrides[e.id] ?? e.exerciseIdentityId;
      final catalogName = identityId == null
          ? null
          : catalog[identityId]?.canonicalName;
      merged.add((
        id: e.id,
        templateId: e.templateId,
        orderIndex: e.orderIndex,
        name: catalogName?.trim().isNotEmpty == true
            ? catalogName!
            : (nameOverrides[e.id] ?? e.name),
      ));
    }

    for (final r in addedRows) {
      final identityId = r.data['exercise_identity_id'] as int?;
      final catalogName = identityId == null
          ? null
          : catalog[identityId]?.canonicalName;
      merged.add((
        id: -((r.data['id'] as int?) ?? 0),
        templateId: (r.data['template_id'] as int?) ?? templateId,
        orderIndex: (r.data['order_index'] as int?) ?? 0,
        name: catalogName?.trim().isNotEmpty == true
            ? catalogName!
            : ((r.data['name'] as String?) ?? 'Упражнение'),
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
      getClientsByStatus(activeClientStatus);

  Future<List<Client>> getArchivedClients() =>
      getClientsByStatus(archivedClientStatus);

  Future<List<Client>> getClientsByStatus(String status) {
    if (status != activeClientStatus && status != archivedClientStatus) {
      throw ArgumentError.value(
        status,
        'status',
        'Недопустимый статус клиента',
      );
    }
    return (select(clients)
          ..where((t) => t.status.equals(status))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  Future<Client?> getClientById(String id) =>
      (select(clients)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> upsertClient(ClientsCompanion data) async {
    if (!data.id.present) {
      throw ArgumentError('Для сохранения клиента обязателен локальный id');
    }

    final localId = data.id.value;
    final existing = await getClientById(localId);
    final requestedExternalId = data.externalId.present
        ? data.externalId.value?.trim()
        : null;
    if (existing?.externalId != null &&
        requestedExternalId != null &&
        requestedExternalId.isNotEmpty &&
        requestedExternalId != existing!.externalId) {
      throw StateError('UUID существующего клиента нельзя изменять');
    }
    final externalId =
        existing?.externalId ??
        ((requestedExternalId?.isNotEmpty ?? false)
            ? requestedExternalId!
            : await _newUniqueUuidForTable('clients'));

    final requestedStatus = data.status.present ? data.status.value : null;
    final status = requestedStatus ?? existing?.status ?? activeClientStatus;
    if (status != activeClientStatus && status != archivedClientStatus) {
      throw ArgumentError.value(
        status,
        'status',
        'Недопустимый статус клиента',
      );
    }

    await into(clients).insertOnConflictUpdate(
      data.copyWith(externalId: Value(externalId), status: Value(status)),
    );
  }

  Future<int> deleteClientById(String id) =>
      (delete(clients)..where((t) => t.id.equals(id))).go();

  Future<void> archiveClient(String id) =>
      _setClientStatus(id, archivedClientStatus);

  Future<void> restoreClient(String id) =>
      _setClientStatus(id, activeClientStatus);

  Future<void> _setClientStatus(String id, String status) async {
    await (update(clients)..where((t) => t.id.equals(id))).write(
      ClientsCompanion(status: Value(status)),
    );
  }

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

  Future<List<Appointment>> getAppointmentsForClientInRange({
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
    return q.get();
  }

  Future<List<Appointment>> getAppointmentsForClientOnDay({
    required String clientId,
    required DateTime day,
  }) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    return (select(appointments)
          ..where(
            (t) =>
                t.clientId.equals(clientId) &
                t.startAt.isBiggerOrEqualValue(dayStart) &
                t.startAt.isSmallerThanValue(dayEnd),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.startAt)]))
        .get();
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
    await _enqueueScheduleForClientSafely(clientId);
  }

  Future<int> deleteAppointmentById(String id) async {
    final appointment = await (select(
      appointments,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    final deleted = await (delete(
      appointments,
    )..where((t) => t.id.equals(id))).go();
    if (deleted > 0 && appointment != null) {
      await _enqueueScheduleForClientSafely(appointment.clientId);
    }
    return deleted;
  }

  Future<void> updateAppointmentTime({
    required String id,
    required DateTime newStartAt,
  }) async {
    final appointment = await (select(
      appointments,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    final updated = await (update(appointments)..where((t) => t.id.equals(id)))
        .write(AppointmentsCompanion(startAt: Value(newStartAt)));
    if (updated > 0 && appointment != null) {
      await _enqueueScheduleForClientSafely(appointment.clientId);
    }
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
  }) async {
    final deleted =
        await (delete(appointments)..where(
              (t) =>
                  t.clientId.equals(clientId) &
                  t.startAt.isBiggerOrEqualValue(from),
            ))
            .go();
    if (deleted > 0) {
      await _enqueueScheduleForClientSafely(clientId);
    }
    return deleted;
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
      "AND c.${clients.status.name} = 'ACTIVE' "
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
      "SELECT date(datetime(CASE WHEN r.remind_on > 20000000000 THEN r.remind_on / 1000 ELSE r.remind_on END, 'unixepoch', 'localtime')) AS d, COUNT(*) AS c "
      'FROM client_payment_reminders r '
      'INNER JOIN ${clients.actualTableName} c '
      'ON c.${clients.id.name} = r.client_id '
      'WHERE r.remind_on >= ? AND r.remind_on < ? '
      "AND c.${clients.status.name} = 'ACTIVE' "
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
      "AND c.${clients.status.name} = 'ACTIVE' "
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
            t.status.equals(activeClientStatus) &
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
      "AND c.${clients.status.name} = 'ACTIVE' "
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

  int _remainingSessions({
    required int planSize,
    required int completedInPlan,
  }) {
    if (planSize <= 0) return 0;
    final completedInBundle = completedInPlan % planSize;
    if (completedInBundle == 0 && completedInPlan > 0) return 0;
    return planSize - completedInBundle;
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
          final exercise = await createExercise(item.$1);
          await into(workoutTemplateExercises).insert(
            WorkoutTemplateExercisesCompanion.insert(
              templateId: template.id,
              orderIndex: i,
              groupId: item.$2 == null ? const Value.absent() : Value(item.$2!),
              name: exercise.canonicalName,
              exerciseIdentityId: Value(exercise.id),
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
          final exercise = await createExercise(item.$1);
          await into(workoutTemplateExercises).insert(
            WorkoutTemplateExercisesCompanion.insert(
              templateId: template.id,
              orderIndex: i,
              groupId: item.$2 == null ? const Value.absent() : Value(item.$2!),
              name: exercise.canonicalName,
              exerciseIdentityId: Value(exercise.id),
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
      final exercise = await createExercise(item.$1);
      await into(workoutTemplateExercises).insert(
        WorkoutTemplateExercisesCompanion.insert(
          templateId: row.id,
          orderIndex: i,
          name: exercise.canonicalName,
          exerciseIdentityId: Value(exercise.id),
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

    // Ручное редактирование дат только синхронизирует state с клиентом.
    // Явный "перезапуск" абонемента делаем отдельной функцией
    // restartClientPlanProgress().
    if (startChanged || endChanged || st.planSize != planSize) {
      await (update(
        clientProgramStates,
      )..where((t) => t.clientId.equals(clientId))).write(
        ClientProgramStatesCompanion(
          planSize: Value(planSize),
          planStart: c.planStart == null
              ? const Value.absent()
              : Value(c.planStart!),
          planEnd: c.planEnd == null ? const Value.absent() : Value(c.planEnd!),
        ),
      );
    }
  }

  /// Явно запускает новый экземпляр абонемента для клиента.
  ///
  /// Используем это только для осознанного продления абонемента
  /// (например, кнопкой `+28` в алерте), а не для ручного редактирования дат
  /// в карточке клиента.
  Future<void> restartClientPlanProgress(String clientId) async {
    final c = await getClientById(clientId);
    if (c == null) return;

    final planSize = _parsePlanSize(c.plan);
    if (planSize <= 0) return;

    await ensureProgramStateForClient(clientId);

    final st = await (select(
      clientProgramStates,
    )..where((t) => t.clientId.equals(clientId))).getSingleOrNull();

    if (st == null) return;

    await (update(
      clientProgramStates,
    )..where((t) => t.clientId.equals(clientId))).write(
      ClientProgramStatesCompanion(
        planSize: Value(planSize),
        planInstance: Value(st.planInstance + 1),
        completedInPlan: const Value(0),
        cycleStartIndex: const Value(0),
        nextOffset: const Value(0),
        windowStart: const Value(0),
        planStart: c.planStart == null
            ? const Value.absent()
            : Value(c.planStart!),
        planEnd: c.planEnd == null ? const Value.absent() : Value(c.planEnd!),
      ),
    );
  }

  /// Продлевает абонемент, выдаёт новый пакет занятий, но сохраняет
  /// текущую последовательность тренировочных дней (без дополнительного
  /// сдвига программы).
  Future<void> renewClientPlanKeepingProgramDay({
    required String clientId,
    required DateTime startDate,
    int days = 28,
  }) async {
    final c = await getClientById(clientId);
    if (c == null) return;

    final planSize = _parsePlanSize(c.plan);
    if (planSize <= 0) return;

    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = start.add(Duration(days: days));

    await upsertClient(
      ClientsCompanion(
        id: Value(c.id),
        name: Value(c.name),
        gender: Value(c.gender),
        plan: Value(c.plan),
        planStart: Value(start),
        planEnd: Value(end),
      ),
    );

    await ensureProgramStateForClient(clientId);
    final st = await (select(
      clientProgramStates,
    )..where((t) => t.clientId.equals(clientId))).getSingleOrNull();
    if (st == null) return;

    final gender = _programTrackByClient(c);
    final cycleLen = _cycleLenByGender(gender);
    final nextTemplateAsCycleStart = _mod(
      st.cycleStartIndex + st.nextOffset,
      cycleLen,
    );

    await (update(
      clientProgramStates,
    )..where((t) => t.clientId.equals(clientId))).write(
      ClientProgramStatesCompanion(
        planSize: Value(planSize),
        planInstance: Value(st.planInstance + 1),
        // Новый пакет должен начинаться с 0 выполненных занятий,
        // но первый день обязан остаться тем, который уже был "следующим"
        // до продления (без дополнительного сдвига программы).
        cycleStartIndex: Value(nextTemplateAsCycleStart),
        nextOffset: const Value(0),
        completedInPlan: const Value(0),
        planStart: Value(start),
        planEnd: Value(end),
      ),
    );
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

  Future<WorkoutSession?> getWorkoutSessionForProgramSlot({
    required String clientId,
    required int planInstance,
    required int absoluteIndex,
  }) {
    return (select(workoutSessions)..where(
          (row) =>
              row.clientId.equals(clientId) &
              row.planInstance.equals(planInstance) &
              row.absoluteIndex.equals(absoluteIndex),
        ))
        .getSingleOrNull();
  }

  Future<WorkoutSession?> _getLegacyWorkoutSessionForProgramSlot({
    required String clientId,
    required int planInstance,
    required int absoluteIndex,
  }) async {
    if (absoluteIndex < 0) return null;
    final legacySessions =
        await (select(workoutSessions)
              ..where(
                (row) =>
                    row.clientId.equals(clientId) &
                    row.planInstance.equals(planInstance) &
                    row.absoluteIndex.isNull(),
              )
              ..orderBy([
                (row) => OrderingTerm.asc(row.performedAt),
                (row) => OrderingTerm.asc(row.id),
              ]))
            .get();
    return absoluteIndex < legacySessions.length
        ? legacySessions[absoluteIndex]
        : null;
  }

  Future<void> _writeWorkoutResultsForSession({
    required WorkoutSession session,
    required String clientId,
    required Map<int, (double? kg, int? reps)> results,
  }) async {
    for (final entry in results.entries) {
      final exerciseId = entry.key;
      final kg = entry.value.$1;
      final reps = entry.value.$2;

      if (kg == null && reps == null) {
        await (delete(workoutExerciseResults)..where(
              (row) =>
                  row.sessionId.equals(session.id) &
                  row.templateExerciseId.equals(exerciseId),
            ))
            .go();
        continue;
      }

      final existing =
          await (select(workoutExerciseResults)..where(
                (row) =>
                    row.sessionId.equals(session.id) &
                    row.templateExerciseId.equals(exerciseId),
              ))
              .getSingleOrNull();
      if (existing == null) {
        final identityId = await _resolveExerciseIdentity(
          clientId: clientId,
          templateExerciseId: exerciseId,
        );
        final exerciseName = await _resolveExerciseDisplayName(
          clientId: clientId,
          templateExerciseId: exerciseId,
        );
        await into(workoutExerciseResults).insert(
          WorkoutExerciseResultsCompanion.insert(
            sessionId: session.id,
            templateExerciseId: exerciseId,
            exerciseIdentityId: Value(identityId),
            exerciseNameSnapshot: Value(exerciseName),
            lastWeightKg: Value(kg),
            lastReps: Value(reps),
          ),
        );
      } else {
        final identityId =
            existing.exerciseIdentityId ??
            await _resolveExerciseIdentity(
              clientId: clientId,
              templateExerciseId: exerciseId,
            );
        await (update(
          workoutExerciseResults,
        )..where((row) => row.id.equals(existing.id))).write(
          WorkoutExerciseResultsCompanion(
            exerciseIdentityId: Value(identityId),
            lastWeightKg: Value(kg),
            lastReps: Value(reps),
          ),
        );
      }
    }
  }

  Future<WorkoutSession> saveCompletedProgramSlot({
    required String clientId,
    required int planInstance,
    required int absoluteIndex,
    required DateTime performedAt,
    required int templateIdx,
    required Map<int, (double? kg, int? reps)> results,
    bool enqueueForSync = true,
  }) async {
    if (absoluteIndex < 0) {
      throw ArgumentError.value(absoluteIndex, 'absoluteIndex');
    }

    late WorkoutSession savedSession;
    var queuedForAutomaticSync = false;
    await transaction(() async {
      final client = await getClientById(clientId);
      if (client == null || _parsePlanSize(client.plan) <= 0) {
        throw StateError('У клиента нет активной программы');
      }
      await ensureProgramStateForClient(clientId);
      final state = await (select(
        clientProgramStates,
      )..where((row) => row.clientId.equals(clientId))).getSingle();

      var session = await getWorkoutSessionForProgramSlot(
        clientId: clientId,
        planInstance: planInstance,
        absoluteIndex: absoluteIndex,
      );
      if (session == null && state.planInstance != planInstance) {
        throw StaleProgramSlotException(
          clientId: clientId,
          requestedPlanInstance: planInstance,
          activePlanInstance: state.planInstance,
        );
      }

      final gender = _programTrackByClient(client);
      final cycleLength = _cycleLenByGender(gender);
      final normalizedTemplateIdx = _mod(templateIdx, cycleLength);
      var created = false;

      if (session == null) {
        final candidateExternalId = await _newUniqueUuidForTable(
          'workout_sessions',
        );
        await into(workoutSessions).insert(
          WorkoutSessionsCompanion.insert(
            externalId: Value(candidateExternalId),
            clientId: clientId,
            performedAt: performedAt,
            planInstance: planInstance,
            absoluteIndex: Value(absoluteIndex),
            gender: gender,
            templateIdx: normalizedTemplateIdx,
          ),
          mode: InsertMode.insertOrIgnore,
        );
        session = await getWorkoutSessionForProgramSlot(
          clientId: clientId,
          planInstance: planInstance,
          absoluteIndex: absoluteIndex,
        );
        if (session == null) {
          throw StateError('Не удалось сохранить слот тренировки');
        }
        created = session.externalId == candidateExternalId;
      }

      final persistedSession = session;

      await (update(
        workoutSessions,
      )..where((row) => row.id.equals(persistedSession.id))).write(
        WorkoutSessionsCompanion(
          performedAt: Value(performedAt),
          gender: Value(gender),
          templateIdx: Value(normalizedTemplateIdx),
        ),
      );
      savedSession = await (select(
        workoutSessions,
      )..where((row) => row.id.equals(persistedSession.id))).getSingle();

      await _writeWorkoutResultsForSession(
        session: savedSession,
        clientId: clientId,
        results: results,
      );

      if (created && absoluteIndex >= state.completedInPlan) {
        final currentTemplateIdx = _mod(
          state.cycleStartIndex + state.nextOffset,
          cycleLength,
        );
        final skippedTemplates = _mod(
          normalizedTemplateIdx - currentTemplateIdx,
          cycleLength,
        );
        await (update(
          clientProgramStates,
        )..where((row) => row.clientId.equals(clientId))).write(
          ClientProgramStatesCompanion(
            completedInPlan: Value(state.completedInPlan + 1),
            nextOffset: Value(
              _mod(state.nextOffset + skippedTemplates + 1, cycleLength),
            ),
          ),
        );
      }

      if (enqueueForSync && !_isTrialWorkoutSession(savedSession)) {
        queuedForAutomaticSync = await _enqueueWorkoutSyncSafely(
          savedSession.externalId,
          triggerAutoSync: false,
        );
      }
    });
    if (queuedForAutomaticSync) _triggerAutomaticSync();
    return savedSession;
  }

  Future<void> completeWorkoutForClient({
    required String clientId,
    required DateTime when,
    bool enqueueForSync = true,
  }) async {
    await ensureProgramStateForClient(clientId);
    final state = await getProgramStateForClient(clientId);
    final client = await getClientById(clientId);
    if (state == null || client == null) return;
    final gender = _programTrackByClient(client);
    final templateIdx = _mod(
      state.cycleStartIndex + state.nextOffset,
      _cycleLenByGender(gender),
    );
    await saveCompletedProgramSlot(
      clientId: clientId,
      planInstance: state.planInstance,
      absoluteIndex: state.completedInPlan,
      performedAt: when,
      templateIdx: templateIdx,
      results: const {},
      enqueueForSync: enqueueForSync,
    );
  }

  Future<void> completeWorkoutForClientWithTemplateIdx({
    required String clientId,
    required DateTime when,
    required int templateIdx,
    bool enqueueForSync = true,
  }) async {
    await ensureProgramStateForClient(clientId);
    final state = await getProgramStateForClient(clientId);
    if (state == null) return;
    await saveCompletedProgramSlot(
      clientId: clientId,
      planInstance: state.planInstance,
      absoluteIndex: state.completedInPlan,
      performedAt: when,
      templateIdx: templateIdx,
      results: const {},
      enqueueForSync: enqueueForSync,
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
      await deleteWorkoutSyncTask(existing.externalId);
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
      await deleteWorkoutSyncTask(existing.externalId);
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
    required int planInstance,
    required int absoluteIndex,
    required int templateIdx,
    required DateTime when,
    int? sessionId,
    bool enqueueForSync = true,
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

    WorkoutSession? existing;
    if (sessionId != null) {
      existing =
          await (select(workoutSessions)..where(
                (row) =>
                    row.id.equals(sessionId) & row.clientId.equals(clientId),
              ))
              .getSingleOrNull();
    }
    existing ??= await getWorkoutSessionForProgramSlot(
      clientId: clientId,
      planInstance: planInstance,
      absoluteIndex: absoluteIndex,
    );
    existing ??= await _getLegacyWorkoutSessionForProgramSlot(
      clientId: clientId,
      planInstance: planInstance,
      absoluteIndex: absoluteIndex,
    );

    if (existing != null) {
      final sessionToDelete = existing;
      await deleteWorkoutSyncTask(sessionToDelete.externalId);
      await (delete(
        workoutExerciseResults,
      )..where((r) => r.sessionId.equals(sessionToDelete.id))).go();

      await (delete(
        workoutSessions,
      )..where((t) => t.id.equals(sessionToDelete.id))).go();

      if (st.planInstance == planInstance &&
          absoluteIndex == st.completedInPlan - 1) {
        await (update(
          clientProgramStates,
        )..where((t) => t.clientId.equals(clientId))).write(
          ClientProgramStatesCompanion(
            completedInPlan: Value(st.completedInPlan - 1),
            nextOffset: Value(_mod(st.nextOffset - 1, cycleLen)),
          ),
        );
      }

      return false;
    }

    await saveCompletedProgramSlot(
      clientId: clientId,
      planInstance: planInstance,
      absoluteIndex: absoluteIndex,
      performedAt: when,
      templateIdx: templateIdx,
      results: const {},
      enqueueForSync: enqueueForSync,
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
    required int planInstance,
    required int absoluteIndex,
    required int templateIdx,
    int? sessionId,
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
    WorkoutSession? sess;
    if (sessionId != null) {
      sess =
          await (select(workoutSessions)..where(
                (row) =>
                    row.id.equals(sessionId) & row.clientId.equals(clientId),
              ))
              .getSingleOrNull();
    }
    sess ??= await getWorkoutSessionForProgramSlot(
      clientId: clientId,
      planInstance: planInstance,
      absoluteIndex: absoluteIndex,
    );
    sess ??= await _getLegacyWorkoutSessionForProgramSlot(
      clientId: clientId,
      planInstance: planInstance,
      absoluteIndex: absoluteIndex,
    );

    final overrides = await _getProgramDayOverrides(
      clientId: clientId,
      planInstance: planInstance,
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

    final resolvedSession = sess;

    final resRows = await (select(
      workoutExerciseResults,
    )..where((r) => r.sessionId.equals(resolvedSession.id))).get();

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
    int? planInstance,
    int? absoluteIndex,
    int? sessionId,
  }) async {
    WorkoutSession? selectedSession;
    if (sessionId != null) {
      selectedSession =
          await (select(workoutSessions)..where(
                (row) =>
                    row.id.equals(sessionId) & row.clientId.equals(clientId),
              ))
              .getSingleOrNull();
    }

    final now = DateTime.now();
    final performedAt = DateTime(
      day.year,
      day.month,
      day.day,
      12,
      0,
      0,
      now.millisecond,
      now.microsecond,
    );

    if (selectedSession?.absoluteIndex != null) {
      await saveCompletedProgramSlot(
        clientId: clientId,
        planInstance: selectedSession!.planInstance,
        absoluteIndex: selectedSession.absoluteIndex!,
        performedAt: performedAt,
        templateIdx: templateIdx ?? selectedSession.templateIdx,
        results: resultsByTemplateExerciseId,
      );
    } else if (selectedSession != null) {
      await transaction(() async {
        await _writeWorkoutResultsForSession(
          session: selectedSession!,
          clientId: clientId,
          results: resultsByTemplateExerciseId,
        );
      });
      await _enqueueWorkoutSyncSafely(selectedSession.externalId);
    } else if (planInstance != null && absoluteIndex != null) {
      await saveCompletedProgramSlot(
        clientId: clientId,
        planInstance: planInstance,
        absoluteIndex: absoluteIndex,
        performedAt: performedAt,
        templateIdx:
            templateIdx ??
            (throw ArgumentError('templateIdx обязателен для program slot')),
        results: resultsByTemplateExerciseId,
      );
    } else {
      final state = await getProgramStateForClient(clientId);
      final ds = _dayStart(day);
      final de = _dayEnd(day);
      final legacySession =
          await (select(workoutSessions)
                ..where(
                  (row) =>
                      row.clientId.equals(clientId) &
                      (state == null
                          ? const Constant(true)
                          : row.planInstance.equals(state.planInstance)) &
                      (templateIdx == null
                          ? const Constant(true)
                          : row.templateIdx.equals(templateIdx)) &
                      row.performedAt.isBiggerOrEqualValue(ds) &
                      row.performedAt.isSmallerThanValue(de),
                )
                ..orderBy([
                  (row) => OrderingTerm.desc(row.performedAt),
                  (row) => OrderingTerm.desc(row.id),
                ])
                ..limit(1))
              .getSingleOrNull();

      if (legacySession != null) {
        await transaction(() async {
          await _writeWorkoutResultsForSession(
            session: legacySession,
            clientId: clientId,
            results: resultsByTemplateExerciseId,
          );
        });
        await _enqueueWorkoutSyncSafely(legacySession.externalId);
      } else {
        if (state == null) {
          await ensureProgramStateForClient(clientId);
        }
        final activeState = await getProgramStateForClient(clientId);
        final client = await getClientById(clientId);
        if (activeState == null || client == null) return;
        final gender = _programTrackByClient(client);
        final resolvedTemplateIdx =
            templateIdx ??
            _mod(
              activeState.cycleStartIndex + activeState.nextOffset,
              _cycleLenByGender(gender),
            );
        await saveCompletedProgramSlot(
          clientId: clientId,
          planInstance: activeState.planInstance,
          absoluteIndex: activeState.completedInPlan,
          performedAt: performedAt,
          templateIdx: resolvedTemplateIdx,
          results: resultsByTemplateExerciseId,
        );
      }
    }

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

  Future<int> replaceTemplateExerciseIdentitiesByGenderName({
    required String gender,
    required String exerciseName,
  }) async {
    final normalized = exerciseName.trim();
    if (normalized.isEmpty) return 0;

    return transaction(() async {
      final rows = await customSelect(
        'SELECT e.${workoutTemplateExercises.id.name} AS exercise_id '
        'FROM ${workoutTemplateExercises.actualTableName} e '
        'INNER JOIN ${workoutTemplates.actualTableName} t '
        'ON t.${workoutTemplates.id.name} = e.${workoutTemplateExercises.templateId.name} '
        'WHERE e.${workoutTemplateExercises.name.name} = ? '
        'AND t.${workoutTemplates.gender.name} = ?',
        variables: [
          Variable.withString(normalized),
          Variable.withString(gender),
        ],
        readsFrom: {workoutTemplateExercises, workoutTemplates},
      ).get();

      for (final row in rows) {
        await _replaceExerciseIdentityBinding(
          sourceType: _templateExerciseSource,
          sourceId: row.read<int>('exercise_id'),
        );
      }
      return rows.length;
    });
  }

  Future<void> renameWorkoutTemplateExercise({
    required int templateExerciseId,
    required String newName,
  }) async {
    final normalized = newName.trim();
    if (normalized.isEmpty) return;

    final slot =
        await (select(workoutTemplateExercises)
              ..where((e) => e.id.equals(templateExerciseId))
              ..limit(1))
            .getSingleOrNull();
    if (slot?.exerciseIdentityId case final identityId?) {
      await renameExercise(exerciseId: identityId, name: normalized);
    }

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
      final added = await customSelect(
        'SELECT exercise_identity_id FROM client_added_exercises WHERE id = ? AND client_id = ? LIMIT 1',
        variables: [Variable.withInt(addedId), Variable.withString(clientId)],
      ).getSingleOrNull();
      final identityId = added?.readNullable<int>('exercise_identity_id');
      if (identityId != null) {
        await renameExercise(exerciseId: identityId, name: normalized);
      }
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

    final override =
        await (select(clientTemplateExerciseOverrides)
              ..where(
                (row) =>
                    row.clientId.equals(clientId) &
                    row.templateExerciseId.equals(templateExerciseId),
              )
              ..limit(1))
            .getSingleOrNull();
    final identityId = override?.exerciseIdentityId ?? base.exerciseIdentityId;
    if (identityId != null) {
      await renameExercise(exerciseId: identityId, name: normalized);
    }

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
    int? exerciseIdentityId,
    String? name,
    int? insertAfterOrderIndex,
  }) async {
    final selectedIdentity = exerciseIdentityId == null
        ? await createExercise(name ?? '')
        : await getExerciseById(exerciseIdentityId);
    if (selectedIdentity == null) throw StateError('Упражнение не найдено');
    final displayName = selectedIdentity.canonicalName;

    await _ensureClientAddedExercisesTable();

    if (insertAfterOrderIndex != null) {
      final insertOrder = insertAfterOrderIndex + 1;

      await customStatement(
        '''
        UPDATE client_added_exercises
        SET order_index = order_index + 1
        WHERE client_id = ? AND template_id = ? AND order_index >= ?
        ''',
        [clientId, templateId, insertOrder],
      );

      final addedId = await customInsert(
        'INSERT INTO client_added_exercises (client_id, template_id, order_index, name, exercise_identity_id) VALUES (?, ?, ?, ?, ?)',
        variables: [
          Variable.withString(clientId),
          Variable.withInt(templateId),
          Variable.withInt(insertOrder),
          Variable.withString(displayName),
          Variable.withInt(selectedIdentity.id),
        ],
      );
      await _bindExerciseIdentity(
        clientId: clientId,
        sourceType: _clientAddedExerciseSource,
        sourceId: addedId,
        identityId: selectedIdentity.id,
      );
      return;
    }

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

    final addedId = await customInsert(
      'INSERT INTO client_added_exercises (client_id, template_id, order_index, name, exercise_identity_id) VALUES (?, ?, ?, ?, ?)',
      variables: [
        Variable.withString(clientId),
        Variable.withInt(templateId),
        Variable.withInt(maxOrder + 1),
        Variable.withString(displayName),
        Variable.withInt(selectedIdentity.id),
      ],
    );
    await _bindExerciseIdentity(
      clientId: clientId,
      sourceType: _clientAddedExerciseSource,
      sourceId: addedId,
      identityId: selectedIdentity.id,
    );
  }

  Future<void> setExerciseForClientSlot({
    required String clientId,
    required int templateExerciseId,
    required int exerciseIdentityId,
  }) async {
    final exercise = await getExerciseById(exerciseIdentityId);
    if (exercise == null) throw StateError('Упражнение не найдено');
    if (templateExerciseId < 0) {
      await _ensureClientAddedExercisesTable();
      await customStatement(
        'UPDATE client_added_exercises SET exercise_identity_id = ?, name = ? WHERE id = ? AND client_id = ?',
        [
          exerciseIdentityId,
          exercise.canonicalName,
          -templateExerciseId,
          clientId,
        ],
      );
      await _bindExerciseIdentity(
        clientId: clientId,
        sourceType: _clientAddedExerciseSource,
        sourceId: -templateExerciseId,
        identityId: exerciseIdentityId,
      );
      return;
    }

    final existing =
        await (select(clientTemplateExerciseOverrides)..where(
              (row) =>
                  row.clientId.equals(clientId) &
                  row.templateExerciseId.equals(templateExerciseId),
            ))
            .getSingleOrNull();
    await into(clientTemplateExerciseOverrides).insertOnConflictUpdate(
      ClientTemplateExerciseOverridesCompanion(
        id: existing == null ? const Value.absent() : Value(existing.id),
        clientId: Value(clientId),
        templateExerciseId: Value(templateExerciseId),
        supersetGroup: Value(existing?.supersetGroup),
        exerciseIdentityId: Value(exerciseIdentityId),
      ),
    );
  }

  Future<void> setExerciseForTemplateSlot({
    required int templateExerciseId,
    required int exerciseIdentityId,
  }) async {
    final exercise = await getExerciseById(exerciseIdentityId);
    if (exercise == null) throw StateError('Упражнение не найдено');
    await (update(
      workoutTemplateExercises,
    )..where((row) => row.id.equals(templateExerciseId))).write(
      WorkoutTemplateExercisesCompanion(
        exerciseIdentityId: Value(exerciseIdentityId),
        name: Value(exercise.canonicalName),
      ),
    );
    await _bindExerciseIdentity(
      sourceType: _templateExerciseSource,
      sourceId: templateExerciseId,
      identityId: exerciseIdentityId,
    );
  }

  Future<int> replaceTemplateExerciseSlotsByGenderName({
    required String gender,
    required String oldName,
    required int exerciseIdentityId,
  }) async {
    final rows = await customSelect(
      '''
      SELECT e.id
      FROM workout_template_exercises e
      INNER JOIN workout_templates t ON t.id = e.template_id
      WHERE t.gender = ? AND e.name = ?
    ''',
      variables: [
        Variable.withString(gender),
        Variable.withString(oldName.trim()),
      ],
    ).get();
    for (final row in rows) {
      await setExerciseForTemplateSlot(
        templateExerciseId: row.read<int>('id'),
        exerciseIdentityId: exerciseIdentityId,
      );
    }
    return rows.length;
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
    int? exerciseIdentityId,
    String? name,
  }) async {
    final selectedIdentity = exerciseIdentityId == null
        ? await createExercise(name ?? '')
        : await getExerciseById(exerciseIdentityId);
    if (selectedIdentity == null) throw StateError('Упражнение не найдено');

    final last =
        await (select(workoutTemplateExercises)
              ..where((e) => e.templateId.equals(templateId))
              ..orderBy([(e) => OrderingTerm.desc(e.orderIndex)])
              ..limit(1))
            .getSingleOrNull();

    final nextOrder = (last?.orderIndex ?? -1) + 1;

    final exerciseId = await into(workoutTemplateExercises).insert(
      WorkoutTemplateExercisesCompanion.insert(
        templateId: templateId,
        orderIndex: nextOrder,
        name: selectedIdentity.canonicalName,
        exerciseIdentityId: Value(selectedIdentity.id),
      ),
    );
    await _bindExerciseIdentity(
      sourceType: _templateExerciseSource,
      sourceId: exerciseId,
      identityId: selectedIdentity.id,
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

      // A program slot is editable configuration, not workout history.
      // Results retain both their identity and historical name snapshot.

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
              ..orderBy([
                (t) => OrderingTerm.asc(t.performedAt),
                (t) => OrderingTerm.asc(t.id),
              ]))
            .get();
    final planSize = st.planSize;
    final completed = st.completedInPlan;
    final bundleStart = (completed ~/ planSize) * planSize;
    final completedInBundle = completed - bundleStart;
    final indexedSessions = <int, WorkoutSession>{
      for (final session in sessions)
        if (session.absoluteIndex != null) session.absoluteIndex!: session,
    };
    final legacySessions = sessions
        .where((session) => session.absoluteIndex == null)
        .toList(growable: false);
    final overrides = await _getProgramDayOverrides(
      clientId: clientId,
      planInstance: st.planInstance,
    );

    final slots = <ProgramSlotVm>[];

    for (var k = 0; k < planSize; k++) {
      final absoluteIndex = bundleStart + k;
      final defaultIdx = _mod(st.cycleStartIndex + absoluteIndex, cycleLen);
      final exactSession = indexedSessions[absoluteIndex];
      final legacySession = absoluteIndex < legacySessions.length
          ? legacySessions[absoluteIndex]
          : null;
      final s = exactSession ?? (k < completedInBundle ? legacySession : null);
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

  Future<Map<String, dynamic>> buildBackupPayload({
    required String appVersion,
    required String buildNumber,
  }) async {
    await ensureIncomeTables();
    await ensureContestTables();
    await getTrainerUuid();

    final tables = await customSelect(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name",
    ).get();

    final payload = <String, dynamic>{
      'schemaVersion': schemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'backupMeta': <String, dynamic>{
        'formatVersion': 1,
        'appVersion': appVersion,
        'buildNumber': buildNumber,
      },
      'tables': <String, dynamic>{},
    };

    final tablesMap = payload['tables'] as Map<String, dynamic>;

    for (final row in tables) {
      final tableName = (row.data['name'] as String?) ?? '';
      if (tableName.isEmpty) continue;
      if (tableName == syncLog.actualTableName) continue;

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

  Future<void> exportBackupToFile(
    String filePath, {
    required String appVersion,
    required String buildNumber,
  }) async {
    final payload = await buildBackupPayload(
      appVersion: appVersion,
      buildNumber: buildNumber,
    );
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

  bool _isUuidV4(String value) {
    return RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      caseSensitive: false,
    ).hasMatch(value);
  }

  Map<String, dynamic> _normalizeBackupTables(Map<String, dynamic> rawTables) {
    final normalized = <String, dynamic>{};
    for (final entry in rawTables.entries) {
      final rows = entry.value;
      if (rows is! List) {
        throw FormatException(
          'Некорректный формат резервной копии: ${entry.key} не является массивом',
        );
      }
      normalized[entry.key] = rows
          .map((raw) {
            if (raw is! Map) {
              throw FormatException('Некорректная строка таблицы ${entry.key}');
            }
            return raw.map<String, dynamic>(
              (key, value) => MapEntry(key.toString(), value),
            );
          })
          .toList(growable: false);
    }

    void normalizeExternalIds(String tableName) {
      final rows = normalized[tableName];
      if (rows is! List<Map<String, dynamic>>) return;

      final used = <String>{};
      for (final row in rows) {
        final raw = row['external_id'];
        final value = raw is String ? raw.trim() : '';
        if (value.isNotEmpty) {
          if (!_isUuidV4(value)) {
            throw FormatException('Некорректный UUID в $tableName.external_id');
          }
          final normalizedValue = value.toLowerCase();
          if (!used.add(normalizedValue)) {
            throw FormatException('Дублирующий UUID в $tableName.external_id');
          }
          row['external_id'] = value;
          continue;
        }

        String generated;
        do {
          generated = _newUuid();
        } while (!used.add(generated));
        row['external_id'] = generated;
      }
    }

    normalizeExternalIds('clients');
    normalizeExternalIds('workout_sessions');
    normalizeExternalIds('exercise_identities');

    final settingsRows = normalized[appSettings.actualTableName];
    if (settingsRows is List<Map<String, dynamic>>) {
      for (final row in settingsRows) {
        if (row['setting_key'] != _trainerUuidSettingKey) continue;
        final value = row['setting_value'];
        if (value is! String || !_isUuidV4(value.trim())) {
          throw const FormatException('Некорректный UUID тренера в backup');
        }
      }
    }

    final clientRows = normalized['clients'];
    if (clientRows is List<Map<String, dynamic>>) {
      for (final row in clientRows) {
        final rawStatus = row['status'];
        final status = rawStatus is String && rawStatus.trim().isNotEmpty
            ? rawStatus.trim()
            : activeClientStatus;
        if (status != activeClientStatus && status != archivedClientStatus) {
          throw FormatException(
            'Недопустимый status клиента в backup: $status',
          );
        }
        row['status'] = status;
      }
    }

    final identityRows = normalized[exerciseIdentities.actualTableName];
    if (identityRows is List<Map<String, dynamic>>) {
      final identitiesById = <int, Map<String, dynamic>>{};
      for (final row in identityRows) {
        final id = row['id'];
        if (id is int) identitiesById[id] = row;
        final status = row['status'];
        if (status != null &&
            status != activeExerciseStatus &&
            status != archivedExerciseStatus) {
          throw FormatException(
            'Недопустимый status упражнения в backup: $status',
          );
        }
      }
      for (final entry in identitiesById.entries) {
        final mergedInto = entry.value['merged_into_identity_id'];
        if (mergedInto == null) continue;
        if (mergedInto is! int ||
            mergedInto == entry.key ||
            !identitiesById.containsKey(mergedInto)) {
          throw const FormatException(
            'Некорректная merge-ссылка упражнения в backup',
          );
        }
        final visited = <int>{entry.key};
        var current = mergedInto;
        while (true) {
          if (!visited.add(current)) {
            throw const FormatException(
              'Цикл merge-ссылок упражнений в backup',
            );
          }
          final next = identitiesById[current]?['merged_into_identity_id'];
          if (next == null) break;
          if (next is! int || !identitiesById.containsKey(next)) {
            throw const FormatException(
              'Некорректная merge-ссылка упражнения в backup',
            );
          }
          current = next;
        }
      }

      final aliases = normalized[exerciseIdentityAliases.actualTableName];
      if (aliases is List<Map<String, dynamic>>) {
        final oldUuids = <String>{};
        for (final alias in aliases) {
          final oldUuid = alias['old_external_id'];
          final canonicalId = alias['canonical_identity_id'];
          if (oldUuid is! String || !_isUuidV4(oldUuid.trim())) {
            throw const FormatException(
              'Некорректный old_external_id упражнения в backup',
            );
          }
          if (!oldUuids.add(oldUuid.trim().toLowerCase())) {
            throw const FormatException(
              'Дублирующий old_external_id упражнения в backup',
            );
          }
          if (canonicalId is! int || !identitiesById.containsKey(canonicalId)) {
            throw const FormatException(
              'Некорректная canonical identity alias в backup',
            );
          }
        }
      }
    }

    return normalized;
  }

  Future<void> _validateBackupColumnsBeforeImport(
    Map<String, dynamic> tables,
  ) async {
    for (final entry in tables.entries) {
      if (!await _tableExists(entry.key)) continue;
      final info = await customSelect(
        'PRAGMA table_info(${_quoteIdent(entry.key)})',
      ).get();
      final allowedColumns = info
          .map((row) => row.data['name'])
          .whereType<String>()
          .toSet();
      final rows = entry.value as List<Map<String, dynamic>>;
      for (final row in rows) {
        final unknown = row.keys.where((key) => !allowedColumns.contains(key));
        if (unknown.isNotEmpty) {
          throw FormatException(
            'Backup содержит неизвестные поля таблицы ${entry.key}: '
            '${unknown.join(', ')}',
          );
        }
      }
    }
  }

  Future<void> importBackupPayload(Map<String, dynamic> payload) async {
    await ensureIncomeTables();
    await ensureContestTables();

    final rawTablesValue = payload['tables'];
    if (rawTablesValue is! Map<String, dynamic>) {
      throw const FormatException(
        'Некорректный формат резервной копии: нет tables',
      );
    }
    for (final tableName in rawTablesValue.keys) {
      await _ensureAuxTableForBackup(tableName);
    }
    final rawTables = _normalizeBackupTables(rawTablesValue);
    await _validateBackupColumnsBeforeImport(rawTables);

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

        // Старый backup не содержит UUID/status/exercise identity. Backfill
        // выполняется до commit той же транзакции, поэтому при любой ошибке
        // удаление исходной базы также будет отменено.
        await _backfillExternalIdentities();
        await _mergeKnownEmptyExerciseDuplicates();
        await _applyConfirmedHammerResultDataFix();
        await _ensureTrainerUuid();
        if (!rawTables.containsKey(syncQueue.actualTableName)) {
          await _enqueueAllExistingWorkoutSessionsForSync();
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
