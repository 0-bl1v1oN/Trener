// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_db.dart';

// ignore_for_file: type=lint
class $ClientsTable extends Clients with TableInfo<$ClientsTable, Client> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClientsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _genderMeta = const VerificationMeta('gender');
  @override
  late final GeneratedColumn<String> gender = GeneratedColumn<String>(
    'gender',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _planMeta = const VerificationMeta('plan');
  @override
  late final GeneratedColumn<String> plan = GeneratedColumn<String>(
    'plan',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _planStartMeta = const VerificationMeta(
    'planStart',
  );
  @override
  late final GeneratedColumn<DateTime> planStart = GeneratedColumn<DateTime>(
    'plan_start',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _planEndMeta = const VerificationMeta(
    'planEnd',
  );
  @override
  late final GeneratedColumn<DateTime> planEnd = GeneratedColumn<DateTime>(
    'plan_end',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    gender,
    plan,
    planStart,
    planEnd,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'clients';
  @override
  VerificationContext validateIntegrity(
    Insertable<Client> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('gender')) {
      context.handle(
        _genderMeta,
        gender.isAcceptableOrUnknown(data['gender']!, _genderMeta),
      );
    }
    if (data.containsKey('plan')) {
      context.handle(
        _planMeta,
        plan.isAcceptableOrUnknown(data['plan']!, _planMeta),
      );
    }
    if (data.containsKey('plan_start')) {
      context.handle(
        _planStartMeta,
        planStart.isAcceptableOrUnknown(data['plan_start']!, _planStartMeta),
      );
    }
    if (data.containsKey('plan_end')) {
      context.handle(
        _planEndMeta,
        planEnd.isAcceptableOrUnknown(data['plan_end']!, _planEndMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Client map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Client(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      gender: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gender'],
      ),
      plan: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan'],
      ),
      planStart: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}plan_start'],
      ),
      planEnd: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}plan_end'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ClientsTable createAlias(String alias) {
    return $ClientsTable(attachedDatabase, alias);
  }
}

class Client extends DataClass implements Insertable<Client> {
  final String id;
  final String name;
  final String? gender;
  final String? plan;
  final DateTime? planStart;
  final DateTime? planEnd;
  final DateTime createdAt;
  const Client({
    required this.id,
    required this.name,
    this.gender,
    this.plan,
    this.planStart,
    this.planEnd,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || gender != null) {
      map['gender'] = Variable<String>(gender);
    }
    if (!nullToAbsent || plan != null) {
      map['plan'] = Variable<String>(plan);
    }
    if (!nullToAbsent || planStart != null) {
      map['plan_start'] = Variable<DateTime>(planStart);
    }
    if (!nullToAbsent || planEnd != null) {
      map['plan_end'] = Variable<DateTime>(planEnd);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ClientsCompanion toCompanion(bool nullToAbsent) {
    return ClientsCompanion(
      id: Value(id),
      name: Value(name),
      gender: gender == null && nullToAbsent
          ? const Value.absent()
          : Value(gender),
      plan: plan == null && nullToAbsent ? const Value.absent() : Value(plan),
      planStart: planStart == null && nullToAbsent
          ? const Value.absent()
          : Value(planStart),
      planEnd: planEnd == null && nullToAbsent
          ? const Value.absent()
          : Value(planEnd),
      createdAt: Value(createdAt),
    );
  }

  factory Client.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Client(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      gender: serializer.fromJson<String?>(json['gender']),
      plan: serializer.fromJson<String?>(json['plan']),
      planStart: serializer.fromJson<DateTime?>(json['planStart']),
      planEnd: serializer.fromJson<DateTime?>(json['planEnd']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'gender': serializer.toJson<String?>(gender),
      'plan': serializer.toJson<String?>(plan),
      'planStart': serializer.toJson<DateTime?>(planStart),
      'planEnd': serializer.toJson<DateTime?>(planEnd),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Client copyWith({
    String? id,
    String? name,
    Value<String?> gender = const Value.absent(),
    Value<String?> plan = const Value.absent(),
    Value<DateTime?> planStart = const Value.absent(),
    Value<DateTime?> planEnd = const Value.absent(),
    DateTime? createdAt,
  }) => Client(
    id: id ?? this.id,
    name: name ?? this.name,
    gender: gender.present ? gender.value : this.gender,
    plan: plan.present ? plan.value : this.plan,
    planStart: planStart.present ? planStart.value : this.planStart,
    planEnd: planEnd.present ? planEnd.value : this.planEnd,
    createdAt: createdAt ?? this.createdAt,
  );
  Client copyWithCompanion(ClientsCompanion data) {
    return Client(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      gender: data.gender.present ? data.gender.value : this.gender,
      plan: data.plan.present ? data.plan.value : this.plan,
      planStart: data.planStart.present ? data.planStart.value : this.planStart,
      planEnd: data.planEnd.present ? data.planEnd.value : this.planEnd,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Client(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('gender: $gender, ')
          ..write('plan: $plan, ')
          ..write('planStart: $planStart, ')
          ..write('planEnd: $planEnd, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, gender, plan, planStart, planEnd, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Client &&
          other.id == this.id &&
          other.name == this.name &&
          other.gender == this.gender &&
          other.plan == this.plan &&
          other.planStart == this.planStart &&
          other.planEnd == this.planEnd &&
          other.createdAt == this.createdAt);
}

class ClientsCompanion extends UpdateCompanion<Client> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> gender;
  final Value<String?> plan;
  final Value<DateTime?> planStart;
  final Value<DateTime?> planEnd;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ClientsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.gender = const Value.absent(),
    this.plan = const Value.absent(),
    this.planStart = const Value.absent(),
    this.planEnd = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClientsCompanion.insert({
    required String id,
    required String name,
    this.gender = const Value.absent(),
    this.plan = const Value.absent(),
    this.planStart = const Value.absent(),
    this.planEnd = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<Client> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? gender,
    Expression<String>? plan,
    Expression<DateTime>? planStart,
    Expression<DateTime>? planEnd,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (gender != null) 'gender': gender,
      if (plan != null) 'plan': plan,
      if (planStart != null) 'plan_start': planStart,
      if (planEnd != null) 'plan_end': planEnd,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClientsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? gender,
    Value<String?>? plan,
    Value<DateTime?>? planStart,
    Value<DateTime?>? planEnd,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ClientsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      plan: plan ?? this.plan,
      planStart: planStart ?? this.planStart,
      planEnd: planEnd ?? this.planEnd,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (gender.present) {
      map['gender'] = Variable<String>(gender.value);
    }
    if (plan.present) {
      map['plan'] = Variable<String>(plan.value);
    }
    if (planStart.present) {
      map['plan_start'] = Variable<DateTime>(planStart.value);
    }
    if (planEnd.present) {
      map['plan_end'] = Variable<DateTime>(planEnd.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClientsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('gender: $gender, ')
          ..write('plan: $plan, ')
          ..write('planStart: $planStart, ')
          ..write('planEnd: $planEnd, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppointmentsTable extends Appointments
    with TableInfo<$AppointmentsTable, Appointment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppointmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startAtMeta = const VerificationMeta(
    'startAt',
  );
  @override
  late final GeneratedColumn<DateTime> startAt = GeneratedColumn<DateTime>(
    'start_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clientId,
    startAt,
    note,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'appointments';
  @override
  VerificationContext validateIntegrity(
    Insertable<Appointment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clientIdMeta);
    }
    if (data.containsKey('start_at')) {
      context.handle(
        _startAtMeta,
        startAt.isAcceptableOrUnknown(data['start_at']!, _startAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startAtMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Appointment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Appointment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      )!,
      startAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_at'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AppointmentsTable createAlias(String alias) {
    return $AppointmentsTable(attachedDatabase, alias);
  }
}

class Appointment extends DataClass implements Insertable<Appointment> {
  final String id;
  final String clientId;
  final DateTime startAt;
  final String? note;
  final DateTime createdAt;
  const Appointment({
    required this.id,
    required this.clientId,
    required this.startAt,
    this.note,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['client_id'] = Variable<String>(clientId);
    map['start_at'] = Variable<DateTime>(startAt);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AppointmentsCompanion toCompanion(bool nullToAbsent) {
    return AppointmentsCompanion(
      id: Value(id),
      clientId: Value(clientId),
      startAt: Value(startAt),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory Appointment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Appointment(
      id: serializer.fromJson<String>(json['id']),
      clientId: serializer.fromJson<String>(json['clientId']),
      startAt: serializer.fromJson<DateTime>(json['startAt']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'clientId': serializer.toJson<String>(clientId),
      'startAt': serializer.toJson<DateTime>(startAt),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Appointment copyWith({
    String? id,
    String? clientId,
    DateTime? startAt,
    Value<String?> note = const Value.absent(),
    DateTime? createdAt,
  }) => Appointment(
    id: id ?? this.id,
    clientId: clientId ?? this.clientId,
    startAt: startAt ?? this.startAt,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
  );
  Appointment copyWithCompanion(AppointmentsCompanion data) {
    return Appointment(
      id: data.id.present ? data.id.value : this.id,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      startAt: data.startAt.present ? data.startAt.value : this.startAt,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Appointment(')
          ..write('id: $id, ')
          ..write('clientId: $clientId, ')
          ..write('startAt: $startAt, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, clientId, startAt, note, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Appointment &&
          other.id == this.id &&
          other.clientId == this.clientId &&
          other.startAt == this.startAt &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class AppointmentsCompanion extends UpdateCompanion<Appointment> {
  final Value<String> id;
  final Value<String> clientId;
  final Value<DateTime> startAt;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AppointmentsCompanion({
    this.id = const Value.absent(),
    this.clientId = const Value.absent(),
    this.startAt = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppointmentsCompanion.insert({
    required String id,
    required String clientId,
    required DateTime startAt,
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       clientId = Value(clientId),
       startAt = Value(startAt);
  static Insertable<Appointment> custom({
    Expression<String>? id,
    Expression<String>? clientId,
    Expression<DateTime>? startAt,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientId != null) 'client_id': clientId,
      if (startAt != null) 'start_at': startAt,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppointmentsCompanion copyWith({
    Value<String>? id,
    Value<String>? clientId,
    Value<DateTime>? startAt,
    Value<String?>? note,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return AppointmentsCompanion(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      startAt: startAt ?? this.startAt,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (startAt.present) {
      map['start_at'] = Variable<DateTime>(startAt.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppointmentsCompanion(')
          ..write('id: $id, ')
          ..write('clientId: $clientId, ')
          ..write('startAt: $startAt, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkoutTemplatesTable extends WorkoutTemplates
    with TableInfo<$WorkoutTemplatesTable, WorkoutTemplate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _genderMeta = const VerificationMeta('gender');
  @override
  late final GeneratedColumn<String> gender = GeneratedColumn<String>(
    'gender',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idxMeta = const VerificationMeta('idx');
  @override
  late final GeneratedColumn<int> idx = GeneratedColumn<int>(
    'idx',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    gender,
    idx,
    label,
    title,
    payloadJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkoutTemplate> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('gender')) {
      context.handle(
        _genderMeta,
        gender.isAcceptableOrUnknown(data['gender']!, _genderMeta),
      );
    } else if (isInserting) {
      context.missing(_genderMeta);
    }
    if (data.containsKey('idx')) {
      context.handle(
        _idxMeta,
        idx.isAcceptableOrUnknown(data['idx']!, _idxMeta),
      );
    } else if (isInserting) {
      context.missing(_idxMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {gender, idx},
  ];
  @override
  WorkoutTemplate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutTemplate(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      gender: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gender'],
      )!,
      idx: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}idx'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      ),
    );
  }

  @override
  $WorkoutTemplatesTable createAlias(String alias) {
    return $WorkoutTemplatesTable(attachedDatabase, alias);
  }
}

class WorkoutTemplate extends DataClass implements Insertable<WorkoutTemplate> {
  final int id;
  final String gender;
  final int idx;
  final String label;
  final String title;
  final String? payloadJson;
  const WorkoutTemplate({
    required this.id,
    required this.gender,
    required this.idx,
    required this.label,
    required this.title,
    this.payloadJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['gender'] = Variable<String>(gender);
    map['idx'] = Variable<int>(idx);
    map['label'] = Variable<String>(label);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || payloadJson != null) {
      map['payload_json'] = Variable<String>(payloadJson);
    }
    return map;
  }

  WorkoutTemplatesCompanion toCompanion(bool nullToAbsent) {
    return WorkoutTemplatesCompanion(
      id: Value(id),
      gender: Value(gender),
      idx: Value(idx),
      label: Value(label),
      title: Value(title),
      payloadJson: payloadJson == null && nullToAbsent
          ? const Value.absent()
          : Value(payloadJson),
    );
  }

  factory WorkoutTemplate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutTemplate(
      id: serializer.fromJson<int>(json['id']),
      gender: serializer.fromJson<String>(json['gender']),
      idx: serializer.fromJson<int>(json['idx']),
      label: serializer.fromJson<String>(json['label']),
      title: serializer.fromJson<String>(json['title']),
      payloadJson: serializer.fromJson<String?>(json['payloadJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'gender': serializer.toJson<String>(gender),
      'idx': serializer.toJson<int>(idx),
      'label': serializer.toJson<String>(label),
      'title': serializer.toJson<String>(title),
      'payloadJson': serializer.toJson<String?>(payloadJson),
    };
  }

  WorkoutTemplate copyWith({
    int? id,
    String? gender,
    int? idx,
    String? label,
    String? title,
    Value<String?> payloadJson = const Value.absent(),
  }) => WorkoutTemplate(
    id: id ?? this.id,
    gender: gender ?? this.gender,
    idx: idx ?? this.idx,
    label: label ?? this.label,
    title: title ?? this.title,
    payloadJson: payloadJson.present ? payloadJson.value : this.payloadJson,
  );
  WorkoutTemplate copyWithCompanion(WorkoutTemplatesCompanion data) {
    return WorkoutTemplate(
      id: data.id.present ? data.id.value : this.id,
      gender: data.gender.present ? data.gender.value : this.gender,
      idx: data.idx.present ? data.idx.value : this.idx,
      label: data.label.present ? data.label.value : this.label,
      title: data.title.present ? data.title.value : this.title,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutTemplate(')
          ..write('id: $id, ')
          ..write('gender: $gender, ')
          ..write('idx: $idx, ')
          ..write('label: $label, ')
          ..write('title: $title, ')
          ..write('payloadJson: $payloadJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, gender, idx, label, title, payloadJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutTemplate &&
          other.id == this.id &&
          other.gender == this.gender &&
          other.idx == this.idx &&
          other.label == this.label &&
          other.title == this.title &&
          other.payloadJson == this.payloadJson);
}

class WorkoutTemplatesCompanion extends UpdateCompanion<WorkoutTemplate> {
  final Value<int> id;
  final Value<String> gender;
  final Value<int> idx;
  final Value<String> label;
  final Value<String> title;
  final Value<String?> payloadJson;
  const WorkoutTemplatesCompanion({
    this.id = const Value.absent(),
    this.gender = const Value.absent(),
    this.idx = const Value.absent(),
    this.label = const Value.absent(),
    this.title = const Value.absent(),
    this.payloadJson = const Value.absent(),
  });
  WorkoutTemplatesCompanion.insert({
    this.id = const Value.absent(),
    required String gender,
    required int idx,
    required String label,
    required String title,
    this.payloadJson = const Value.absent(),
  }) : gender = Value(gender),
       idx = Value(idx),
       label = Value(label),
       title = Value(title);
  static Insertable<WorkoutTemplate> custom({
    Expression<int>? id,
    Expression<String>? gender,
    Expression<int>? idx,
    Expression<String>? label,
    Expression<String>? title,
    Expression<String>? payloadJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (gender != null) 'gender': gender,
      if (idx != null) 'idx': idx,
      if (label != null) 'label': label,
      if (title != null) 'title': title,
      if (payloadJson != null) 'payload_json': payloadJson,
    });
  }

  WorkoutTemplatesCompanion copyWith({
    Value<int>? id,
    Value<String>? gender,
    Value<int>? idx,
    Value<String>? label,
    Value<String>? title,
    Value<String?>? payloadJson,
  }) {
    return WorkoutTemplatesCompanion(
      id: id ?? this.id,
      gender: gender ?? this.gender,
      idx: idx ?? this.idx,
      label: label ?? this.label,
      title: title ?? this.title,
      payloadJson: payloadJson ?? this.payloadJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (gender.present) {
      map['gender'] = Variable<String>(gender.value);
    }
    if (idx.present) {
      map['idx'] = Variable<int>(idx.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('gender: $gender, ')
          ..write('idx: $idx, ')
          ..write('label: $label, ')
          ..write('title: $title, ')
          ..write('payloadJson: $payloadJson')
          ..write(')'))
        .toString();
  }
}

class $ClientProgramStatesTable extends ClientProgramStates
    with TableInfo<$ClientProgramStatesTable, ClientProgramState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClientProgramStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _planSizeMeta = const VerificationMeta(
    'planSize',
  );
  @override
  late final GeneratedColumn<int> planSize = GeneratedColumn<int>(
    'plan_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _planInstanceMeta = const VerificationMeta(
    'planInstance',
  );
  @override
  late final GeneratedColumn<int> planInstance = GeneratedColumn<int>(
    'plan_instance',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _completedInPlanMeta = const VerificationMeta(
    'completedInPlan',
  );
  @override
  late final GeneratedColumn<int> completedInPlan = GeneratedColumn<int>(
    'completed_in_plan',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _cycleStartIndexMeta = const VerificationMeta(
    'cycleStartIndex',
  );
  @override
  late final GeneratedColumn<int> cycleStartIndex = GeneratedColumn<int>(
    'cycle_start_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextOffsetMeta = const VerificationMeta(
    'nextOffset',
  );
  @override
  late final GeneratedColumn<int> nextOffset = GeneratedColumn<int>(
    'next_offset',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _windowStartMeta = const VerificationMeta(
    'windowStart',
  );
  @override
  late final GeneratedColumn<int> windowStart = GeneratedColumn<int>(
    'window_start',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _planStartMeta = const VerificationMeta(
    'planStart',
  );
  @override
  late final GeneratedColumn<DateTime> planStart = GeneratedColumn<DateTime>(
    'plan_start',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _planEndMeta = const VerificationMeta(
    'planEnd',
  );
  @override
  late final GeneratedColumn<DateTime> planEnd = GeneratedColumn<DateTime>(
    'plan_end',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    clientId,
    planSize,
    planInstance,
    completedInPlan,
    cycleStartIndex,
    nextOffset,
    windowStart,
    planStart,
    planEnd,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'client_program_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<ClientProgramState> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clientIdMeta);
    }
    if (data.containsKey('plan_size')) {
      context.handle(
        _planSizeMeta,
        planSize.isAcceptableOrUnknown(data['plan_size']!, _planSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_planSizeMeta);
    }
    if (data.containsKey('plan_instance')) {
      context.handle(
        _planInstanceMeta,
        planInstance.isAcceptableOrUnknown(
          data['plan_instance']!,
          _planInstanceMeta,
        ),
      );
    }
    if (data.containsKey('completed_in_plan')) {
      context.handle(
        _completedInPlanMeta,
        completedInPlan.isAcceptableOrUnknown(
          data['completed_in_plan']!,
          _completedInPlanMeta,
        ),
      );
    }
    if (data.containsKey('cycle_start_index')) {
      context.handle(
        _cycleStartIndexMeta,
        cycleStartIndex.isAcceptableOrUnknown(
          data['cycle_start_index']!,
          _cycleStartIndexMeta,
        ),
      );
    }
    if (data.containsKey('next_offset')) {
      context.handle(
        _nextOffsetMeta,
        nextOffset.isAcceptableOrUnknown(data['next_offset']!, _nextOffsetMeta),
      );
    }
    if (data.containsKey('window_start')) {
      context.handle(
        _windowStartMeta,
        windowStart.isAcceptableOrUnknown(
          data['window_start']!,
          _windowStartMeta,
        ),
      );
    }
    if (data.containsKey('plan_start')) {
      context.handle(
        _planStartMeta,
        planStart.isAcceptableOrUnknown(data['plan_start']!, _planStartMeta),
      );
    }
    if (data.containsKey('plan_end')) {
      context.handle(
        _planEndMeta,
        planEnd.isAcceptableOrUnknown(data['plan_end']!, _planEndMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clientId};
  @override
  ClientProgramState map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClientProgramState(
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      )!,
      planSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}plan_size'],
      )!,
      planInstance: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}plan_instance'],
      )!,
      completedInPlan: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_in_plan'],
      )!,
      cycleStartIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cycle_start_index'],
      )!,
      nextOffset: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}next_offset'],
      )!,
      windowStart: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}window_start'],
      )!,
      planStart: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}plan_start'],
      ),
      planEnd: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}plan_end'],
      ),
    );
  }

  @override
  $ClientProgramStatesTable createAlias(String alias) {
    return $ClientProgramStatesTable(attachedDatabase, alias);
  }
}

class ClientProgramState extends DataClass
    implements Insertable<ClientProgramState> {
  final String clientId;
  final int planSize;
  final int planInstance;
  final int completedInPlan;
  final int cycleStartIndex;
  final int nextOffset;
  final int windowStart;
  final DateTime? planStart;
  final DateTime? planEnd;
  const ClientProgramState({
    required this.clientId,
    required this.planSize,
    required this.planInstance,
    required this.completedInPlan,
    required this.cycleStartIndex,
    required this.nextOffset,
    required this.windowStart,
    this.planStart,
    this.planEnd,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['client_id'] = Variable<String>(clientId);
    map['plan_size'] = Variable<int>(planSize);
    map['plan_instance'] = Variable<int>(planInstance);
    map['completed_in_plan'] = Variable<int>(completedInPlan);
    map['cycle_start_index'] = Variable<int>(cycleStartIndex);
    map['next_offset'] = Variable<int>(nextOffset);
    map['window_start'] = Variable<int>(windowStart);
    if (!nullToAbsent || planStart != null) {
      map['plan_start'] = Variable<DateTime>(planStart);
    }
    if (!nullToAbsent || planEnd != null) {
      map['plan_end'] = Variable<DateTime>(planEnd);
    }
    return map;
  }

  ClientProgramStatesCompanion toCompanion(bool nullToAbsent) {
    return ClientProgramStatesCompanion(
      clientId: Value(clientId),
      planSize: Value(planSize),
      planInstance: Value(planInstance),
      completedInPlan: Value(completedInPlan),
      cycleStartIndex: Value(cycleStartIndex),
      nextOffset: Value(nextOffset),
      windowStart: Value(windowStart),
      planStart: planStart == null && nullToAbsent
          ? const Value.absent()
          : Value(planStart),
      planEnd: planEnd == null && nullToAbsent
          ? const Value.absent()
          : Value(planEnd),
    );
  }

  factory ClientProgramState.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClientProgramState(
      clientId: serializer.fromJson<String>(json['clientId']),
      planSize: serializer.fromJson<int>(json['planSize']),
      planInstance: serializer.fromJson<int>(json['planInstance']),
      completedInPlan: serializer.fromJson<int>(json['completedInPlan']),
      cycleStartIndex: serializer.fromJson<int>(json['cycleStartIndex']),
      nextOffset: serializer.fromJson<int>(json['nextOffset']),
      windowStart: serializer.fromJson<int>(json['windowStart']),
      planStart: serializer.fromJson<DateTime?>(json['planStart']),
      planEnd: serializer.fromJson<DateTime?>(json['planEnd']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clientId': serializer.toJson<String>(clientId),
      'planSize': serializer.toJson<int>(planSize),
      'planInstance': serializer.toJson<int>(planInstance),
      'completedInPlan': serializer.toJson<int>(completedInPlan),
      'cycleStartIndex': serializer.toJson<int>(cycleStartIndex),
      'nextOffset': serializer.toJson<int>(nextOffset),
      'windowStart': serializer.toJson<int>(windowStart),
      'planStart': serializer.toJson<DateTime?>(planStart),
      'planEnd': serializer.toJson<DateTime?>(planEnd),
    };
  }

  ClientProgramState copyWith({
    String? clientId,
    int? planSize,
    int? planInstance,
    int? completedInPlan,
    int? cycleStartIndex,
    int? nextOffset,
    int? windowStart,
    Value<DateTime?> planStart = const Value.absent(),
    Value<DateTime?> planEnd = const Value.absent(),
  }) => ClientProgramState(
    clientId: clientId ?? this.clientId,
    planSize: planSize ?? this.planSize,
    planInstance: planInstance ?? this.planInstance,
    completedInPlan: completedInPlan ?? this.completedInPlan,
    cycleStartIndex: cycleStartIndex ?? this.cycleStartIndex,
    nextOffset: nextOffset ?? this.nextOffset,
    windowStart: windowStart ?? this.windowStart,
    planStart: planStart.present ? planStart.value : this.planStart,
    planEnd: planEnd.present ? planEnd.value : this.planEnd,
  );
  ClientProgramState copyWithCompanion(ClientProgramStatesCompanion data) {
    return ClientProgramState(
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      planSize: data.planSize.present ? data.planSize.value : this.planSize,
      planInstance: data.planInstance.present
          ? data.planInstance.value
          : this.planInstance,
      completedInPlan: data.completedInPlan.present
          ? data.completedInPlan.value
          : this.completedInPlan,
      cycleStartIndex: data.cycleStartIndex.present
          ? data.cycleStartIndex.value
          : this.cycleStartIndex,
      nextOffset: data.nextOffset.present
          ? data.nextOffset.value
          : this.nextOffset,
      windowStart: data.windowStart.present
          ? data.windowStart.value
          : this.windowStart,
      planStart: data.planStart.present ? data.planStart.value : this.planStart,
      planEnd: data.planEnd.present ? data.planEnd.value : this.planEnd,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClientProgramState(')
          ..write('clientId: $clientId, ')
          ..write('planSize: $planSize, ')
          ..write('planInstance: $planInstance, ')
          ..write('completedInPlan: $completedInPlan, ')
          ..write('cycleStartIndex: $cycleStartIndex, ')
          ..write('nextOffset: $nextOffset, ')
          ..write('windowStart: $windowStart, ')
          ..write('planStart: $planStart, ')
          ..write('planEnd: $planEnd')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    clientId,
    planSize,
    planInstance,
    completedInPlan,
    cycleStartIndex,
    nextOffset,
    windowStart,
    planStart,
    planEnd,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClientProgramState &&
          other.clientId == this.clientId &&
          other.planSize == this.planSize &&
          other.planInstance == this.planInstance &&
          other.completedInPlan == this.completedInPlan &&
          other.cycleStartIndex == this.cycleStartIndex &&
          other.nextOffset == this.nextOffset &&
          other.windowStart == this.windowStart &&
          other.planStart == this.planStart &&
          other.planEnd == this.planEnd);
}

class ClientProgramStatesCompanion extends UpdateCompanion<ClientProgramState> {
  final Value<String> clientId;
  final Value<int> planSize;
  final Value<int> planInstance;
  final Value<int> completedInPlan;
  final Value<int> cycleStartIndex;
  final Value<int> nextOffset;
  final Value<int> windowStart;
  final Value<DateTime?> planStart;
  final Value<DateTime?> planEnd;
  final Value<int> rowid;
  const ClientProgramStatesCompanion({
    this.clientId = const Value.absent(),
    this.planSize = const Value.absent(),
    this.planInstance = const Value.absent(),
    this.completedInPlan = const Value.absent(),
    this.cycleStartIndex = const Value.absent(),
    this.nextOffset = const Value.absent(),
    this.windowStart = const Value.absent(),
    this.planStart = const Value.absent(),
    this.planEnd = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClientProgramStatesCompanion.insert({
    required String clientId,
    required int planSize,
    this.planInstance = const Value.absent(),
    this.completedInPlan = const Value.absent(),
    this.cycleStartIndex = const Value.absent(),
    this.nextOffset = const Value.absent(),
    this.windowStart = const Value.absent(),
    this.planStart = const Value.absent(),
    this.planEnd = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : clientId = Value(clientId),
       planSize = Value(planSize);
  static Insertable<ClientProgramState> custom({
    Expression<String>? clientId,
    Expression<int>? planSize,
    Expression<int>? planInstance,
    Expression<int>? completedInPlan,
    Expression<int>? cycleStartIndex,
    Expression<int>? nextOffset,
    Expression<int>? windowStart,
    Expression<DateTime>? planStart,
    Expression<DateTime>? planEnd,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clientId != null) 'client_id': clientId,
      if (planSize != null) 'plan_size': planSize,
      if (planInstance != null) 'plan_instance': planInstance,
      if (completedInPlan != null) 'completed_in_plan': completedInPlan,
      if (cycleStartIndex != null) 'cycle_start_index': cycleStartIndex,
      if (nextOffset != null) 'next_offset': nextOffset,
      if (windowStart != null) 'window_start': windowStart,
      if (planStart != null) 'plan_start': planStart,
      if (planEnd != null) 'plan_end': planEnd,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClientProgramStatesCompanion copyWith({
    Value<String>? clientId,
    Value<int>? planSize,
    Value<int>? planInstance,
    Value<int>? completedInPlan,
    Value<int>? cycleStartIndex,
    Value<int>? nextOffset,
    Value<int>? windowStart,
    Value<DateTime?>? planStart,
    Value<DateTime?>? planEnd,
    Value<int>? rowid,
  }) {
    return ClientProgramStatesCompanion(
      clientId: clientId ?? this.clientId,
      planSize: planSize ?? this.planSize,
      planInstance: planInstance ?? this.planInstance,
      completedInPlan: completedInPlan ?? this.completedInPlan,
      cycleStartIndex: cycleStartIndex ?? this.cycleStartIndex,
      nextOffset: nextOffset ?? this.nextOffset,
      windowStart: windowStart ?? this.windowStart,
      planStart: planStart ?? this.planStart,
      planEnd: planEnd ?? this.planEnd,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (planSize.present) {
      map['plan_size'] = Variable<int>(planSize.value);
    }
    if (planInstance.present) {
      map['plan_instance'] = Variable<int>(planInstance.value);
    }
    if (completedInPlan.present) {
      map['completed_in_plan'] = Variable<int>(completedInPlan.value);
    }
    if (cycleStartIndex.present) {
      map['cycle_start_index'] = Variable<int>(cycleStartIndex.value);
    }
    if (nextOffset.present) {
      map['next_offset'] = Variable<int>(nextOffset.value);
    }
    if (windowStart.present) {
      map['window_start'] = Variable<int>(windowStart.value);
    }
    if (planStart.present) {
      map['plan_start'] = Variable<DateTime>(planStart.value);
    }
    if (planEnd.present) {
      map['plan_end'] = Variable<DateTime>(planEnd.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClientProgramStatesCompanion(')
          ..write('clientId: $clientId, ')
          ..write('planSize: $planSize, ')
          ..write('planInstance: $planInstance, ')
          ..write('completedInPlan: $completedInPlan, ')
          ..write('cycleStartIndex: $cycleStartIndex, ')
          ..write('nextOffset: $nextOffset, ')
          ..write('windowStart: $windowStart, ')
          ..write('planStart: $planStart, ')
          ..write('planEnd: $planEnd, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkoutSessionsTable extends WorkoutSessions
    with TableInfo<$WorkoutSessionsTable, WorkoutSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _performedAtMeta = const VerificationMeta(
    'performedAt',
  );
  @override
  late final GeneratedColumn<DateTime> performedAt = GeneratedColumn<DateTime>(
    'performed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _planInstanceMeta = const VerificationMeta(
    'planInstance',
  );
  @override
  late final GeneratedColumn<int> planInstance = GeneratedColumn<int>(
    'plan_instance',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _genderMeta = const VerificationMeta('gender');
  @override
  late final GeneratedColumn<String> gender = GeneratedColumn<String>(
    'gender',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _templateIdxMeta = const VerificationMeta(
    'templateIdx',
  );
  @override
  late final GeneratedColumn<int> templateIdx = GeneratedColumn<int>(
    'template_idx',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clientId,
    performedAt,
    planInstance,
    gender,
    templateIdx,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkoutSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clientIdMeta);
    }
    if (data.containsKey('performed_at')) {
      context.handle(
        _performedAtMeta,
        performedAt.isAcceptableOrUnknown(
          data['performed_at']!,
          _performedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_performedAtMeta);
    }
    if (data.containsKey('plan_instance')) {
      context.handle(
        _planInstanceMeta,
        planInstance.isAcceptableOrUnknown(
          data['plan_instance']!,
          _planInstanceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_planInstanceMeta);
    }
    if (data.containsKey('gender')) {
      context.handle(
        _genderMeta,
        gender.isAcceptableOrUnknown(data['gender']!, _genderMeta),
      );
    } else if (isInserting) {
      context.missing(_genderMeta);
    }
    if (data.containsKey('template_idx')) {
      context.handle(
        _templateIdxMeta,
        templateIdx.isAcceptableOrUnknown(
          data['template_idx']!,
          _templateIdxMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_templateIdxMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      )!,
      performedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}performed_at'],
      )!,
      planInstance: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}plan_instance'],
      )!,
      gender: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gender'],
      )!,
      templateIdx: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}template_idx'],
      )!,
    );
  }

  @override
  $WorkoutSessionsTable createAlias(String alias) {
    return $WorkoutSessionsTable(attachedDatabase, alias);
  }
}

class WorkoutSession extends DataClass implements Insertable<WorkoutSession> {
  final int id;
  final String clientId;
  final DateTime performedAt;
  final int planInstance;
  final String gender;
  final int templateIdx;
  const WorkoutSession({
    required this.id,
    required this.clientId,
    required this.performedAt,
    required this.planInstance,
    required this.gender,
    required this.templateIdx,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['client_id'] = Variable<String>(clientId);
    map['performed_at'] = Variable<DateTime>(performedAt);
    map['plan_instance'] = Variable<int>(planInstance);
    map['gender'] = Variable<String>(gender);
    map['template_idx'] = Variable<int>(templateIdx);
    return map;
  }

  WorkoutSessionsCompanion toCompanion(bool nullToAbsent) {
    return WorkoutSessionsCompanion(
      id: Value(id),
      clientId: Value(clientId),
      performedAt: Value(performedAt),
      planInstance: Value(planInstance),
      gender: Value(gender),
      templateIdx: Value(templateIdx),
    );
  }

  factory WorkoutSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutSession(
      id: serializer.fromJson<int>(json['id']),
      clientId: serializer.fromJson<String>(json['clientId']),
      performedAt: serializer.fromJson<DateTime>(json['performedAt']),
      planInstance: serializer.fromJson<int>(json['planInstance']),
      gender: serializer.fromJson<String>(json['gender']),
      templateIdx: serializer.fromJson<int>(json['templateIdx']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'clientId': serializer.toJson<String>(clientId),
      'performedAt': serializer.toJson<DateTime>(performedAt),
      'planInstance': serializer.toJson<int>(planInstance),
      'gender': serializer.toJson<String>(gender),
      'templateIdx': serializer.toJson<int>(templateIdx),
    };
  }

  WorkoutSession copyWith({
    int? id,
    String? clientId,
    DateTime? performedAt,
    int? planInstance,
    String? gender,
    int? templateIdx,
  }) => WorkoutSession(
    id: id ?? this.id,
    clientId: clientId ?? this.clientId,
    performedAt: performedAt ?? this.performedAt,
    planInstance: planInstance ?? this.planInstance,
    gender: gender ?? this.gender,
    templateIdx: templateIdx ?? this.templateIdx,
  );
  WorkoutSession copyWithCompanion(WorkoutSessionsCompanion data) {
    return WorkoutSession(
      id: data.id.present ? data.id.value : this.id,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      performedAt: data.performedAt.present
          ? data.performedAt.value
          : this.performedAt,
      planInstance: data.planInstance.present
          ? data.planInstance.value
          : this.planInstance,
      gender: data.gender.present ? data.gender.value : this.gender,
      templateIdx: data.templateIdx.present
          ? data.templateIdx.value
          : this.templateIdx,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSession(')
          ..write('id: $id, ')
          ..write('clientId: $clientId, ')
          ..write('performedAt: $performedAt, ')
          ..write('planInstance: $planInstance, ')
          ..write('gender: $gender, ')
          ..write('templateIdx: $templateIdx')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, clientId, performedAt, planInstance, gender, templateIdx);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutSession &&
          other.id == this.id &&
          other.clientId == this.clientId &&
          other.performedAt == this.performedAt &&
          other.planInstance == this.planInstance &&
          other.gender == this.gender &&
          other.templateIdx == this.templateIdx);
}

class WorkoutSessionsCompanion extends UpdateCompanion<WorkoutSession> {
  final Value<int> id;
  final Value<String> clientId;
  final Value<DateTime> performedAt;
  final Value<int> planInstance;
  final Value<String> gender;
  final Value<int> templateIdx;
  const WorkoutSessionsCompanion({
    this.id = const Value.absent(),
    this.clientId = const Value.absent(),
    this.performedAt = const Value.absent(),
    this.planInstance = const Value.absent(),
    this.gender = const Value.absent(),
    this.templateIdx = const Value.absent(),
  });
  WorkoutSessionsCompanion.insert({
    this.id = const Value.absent(),
    required String clientId,
    required DateTime performedAt,
    required int planInstance,
    required String gender,
    required int templateIdx,
  }) : clientId = Value(clientId),
       performedAt = Value(performedAt),
       planInstance = Value(planInstance),
       gender = Value(gender),
       templateIdx = Value(templateIdx);
  static Insertable<WorkoutSession> custom({
    Expression<int>? id,
    Expression<String>? clientId,
    Expression<DateTime>? performedAt,
    Expression<int>? planInstance,
    Expression<String>? gender,
    Expression<int>? templateIdx,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientId != null) 'client_id': clientId,
      if (performedAt != null) 'performed_at': performedAt,
      if (planInstance != null) 'plan_instance': planInstance,
      if (gender != null) 'gender': gender,
      if (templateIdx != null) 'template_idx': templateIdx,
    });
  }

  WorkoutSessionsCompanion copyWith({
    Value<int>? id,
    Value<String>? clientId,
    Value<DateTime>? performedAt,
    Value<int>? planInstance,
    Value<String>? gender,
    Value<int>? templateIdx,
  }) {
    return WorkoutSessionsCompanion(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      performedAt: performedAt ?? this.performedAt,
      planInstance: planInstance ?? this.planInstance,
      gender: gender ?? this.gender,
      templateIdx: templateIdx ?? this.templateIdx,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (performedAt.present) {
      map['performed_at'] = Variable<DateTime>(performedAt.value);
    }
    if (planInstance.present) {
      map['plan_instance'] = Variable<int>(planInstance.value);
    }
    if (gender.present) {
      map['gender'] = Variable<String>(gender.value);
    }
    if (templateIdx.present) {
      map['template_idx'] = Variable<int>(templateIdx.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSessionsCompanion(')
          ..write('id: $id, ')
          ..write('clientId: $clientId, ')
          ..write('performedAt: $performedAt, ')
          ..write('planInstance: $planInstance, ')
          ..write('gender: $gender, ')
          ..write('templateIdx: $templateIdx')
          ..write(')'))
        .toString();
  }
}

class $WorkoutTemplateExercisesTable extends WorkoutTemplateExercises
    with TableInfo<$WorkoutTemplateExercisesTable, WorkoutTemplateExercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutTemplateExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<int> templateId = GeneratedColumn<int>(
    'template_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<int> groupId = GeneratedColumn<int>(
    'group_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    templateId,
    orderIndex,
    groupId,
    name,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_template_exercises';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkoutTemplateExercise> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    } else if (isInserting) {
      context.missing(_templateIdMeta);
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_orderIndexMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {templateId, orderIndex},
  ];
  @override
  WorkoutTemplateExercise map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutTemplateExercise(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}template_id'],
      )!,
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}group_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $WorkoutTemplateExercisesTable createAlias(String alias) {
    return $WorkoutTemplateExercisesTable(attachedDatabase, alias);
  }
}

class WorkoutTemplateExercise extends DataClass
    implements Insertable<WorkoutTemplateExercise> {
  final int id;
  final int templateId;
  final int orderIndex;
  final int? groupId;
  final String name;
  const WorkoutTemplateExercise({
    required this.id,
    required this.templateId,
    required this.orderIndex,
    this.groupId,
    required this.name,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['template_id'] = Variable<int>(templateId);
    map['order_index'] = Variable<int>(orderIndex);
    if (!nullToAbsent || groupId != null) {
      map['group_id'] = Variable<int>(groupId);
    }
    map['name'] = Variable<String>(name);
    return map;
  }

  WorkoutTemplateExercisesCompanion toCompanion(bool nullToAbsent) {
    return WorkoutTemplateExercisesCompanion(
      id: Value(id),
      templateId: Value(templateId),
      orderIndex: Value(orderIndex),
      groupId: groupId == null && nullToAbsent
          ? const Value.absent()
          : Value(groupId),
      name: Value(name),
    );
  }

  factory WorkoutTemplateExercise.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutTemplateExercise(
      id: serializer.fromJson<int>(json['id']),
      templateId: serializer.fromJson<int>(json['templateId']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      groupId: serializer.fromJson<int?>(json['groupId']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'templateId': serializer.toJson<int>(templateId),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'groupId': serializer.toJson<int?>(groupId),
      'name': serializer.toJson<String>(name),
    };
  }

  WorkoutTemplateExercise copyWith({
    int? id,
    int? templateId,
    int? orderIndex,
    Value<int?> groupId = const Value.absent(),
    String? name,
  }) => WorkoutTemplateExercise(
    id: id ?? this.id,
    templateId: templateId ?? this.templateId,
    orderIndex: orderIndex ?? this.orderIndex,
    groupId: groupId.present ? groupId.value : this.groupId,
    name: name ?? this.name,
  );
  WorkoutTemplateExercise copyWithCompanion(
    WorkoutTemplateExercisesCompanion data,
  ) {
    return WorkoutTemplateExercise(
      id: data.id.present ? data.id.value : this.id,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutTemplateExercise(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('groupId: $groupId, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, templateId, orderIndex, groupId, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutTemplateExercise &&
          other.id == this.id &&
          other.templateId == this.templateId &&
          other.orderIndex == this.orderIndex &&
          other.groupId == this.groupId &&
          other.name == this.name);
}

class WorkoutTemplateExercisesCompanion
    extends UpdateCompanion<WorkoutTemplateExercise> {
  final Value<int> id;
  final Value<int> templateId;
  final Value<int> orderIndex;
  final Value<int?> groupId;
  final Value<String> name;
  const WorkoutTemplateExercisesCompanion({
    this.id = const Value.absent(),
    this.templateId = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.groupId = const Value.absent(),
    this.name = const Value.absent(),
  });
  WorkoutTemplateExercisesCompanion.insert({
    this.id = const Value.absent(),
    required int templateId,
    required int orderIndex,
    this.groupId = const Value.absent(),
    required String name,
  }) : templateId = Value(templateId),
       orderIndex = Value(orderIndex),
       name = Value(name);
  static Insertable<WorkoutTemplateExercise> custom({
    Expression<int>? id,
    Expression<int>? templateId,
    Expression<int>? orderIndex,
    Expression<int>? groupId,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (templateId != null) 'template_id': templateId,
      if (orderIndex != null) 'order_index': orderIndex,
      if (groupId != null) 'group_id': groupId,
      if (name != null) 'name': name,
    });
  }

  WorkoutTemplateExercisesCompanion copyWith({
    Value<int>? id,
    Value<int>? templateId,
    Value<int>? orderIndex,
    Value<int?>? groupId,
    Value<String>? name,
  }) {
    return WorkoutTemplateExercisesCompanion(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      orderIndex: orderIndex ?? this.orderIndex,
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<int>(templateId.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<int>(groupId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutTemplateExercisesCompanion(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('groupId: $groupId, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class $WorkoutExerciseResultsTable extends WorkoutExerciseResults
    with TableInfo<$WorkoutExerciseResultsTable, WorkoutExerciseResult> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutExerciseResultsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _templateExerciseIdMeta =
      const VerificationMeta('templateExerciseId');
  @override
  late final GeneratedColumn<int> templateExerciseId = GeneratedColumn<int>(
    'template_exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastWeightKgMeta = const VerificationMeta(
    'lastWeightKg',
  );
  @override
  late final GeneratedColumn<double> lastWeightKg = GeneratedColumn<double>(
    'last_weight_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastRepsMeta = const VerificationMeta(
    'lastReps',
  );
  @override
  late final GeneratedColumn<int> lastReps = GeneratedColumn<int>(
    'last_reps',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    templateExerciseId,
    lastWeightKg,
    lastReps,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_exercise_results';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkoutExerciseResult> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('template_exercise_id')) {
      context.handle(
        _templateExerciseIdMeta,
        templateExerciseId.isAcceptableOrUnknown(
          data['template_exercise_id']!,
          _templateExerciseIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_templateExerciseIdMeta);
    }
    if (data.containsKey('last_weight_kg')) {
      context.handle(
        _lastWeightKgMeta,
        lastWeightKg.isAcceptableOrUnknown(
          data['last_weight_kg']!,
          _lastWeightKgMeta,
        ),
      );
    }
    if (data.containsKey('last_reps')) {
      context.handle(
        _lastRepsMeta,
        lastReps.isAcceptableOrUnknown(data['last_reps']!, _lastRepsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {sessionId, templateExerciseId},
  ];
  @override
  WorkoutExerciseResult map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutExerciseResult(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
      )!,
      templateExerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}template_exercise_id'],
      )!,
      lastWeightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}last_weight_kg'],
      ),
      lastReps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_reps'],
      ),
    );
  }

  @override
  $WorkoutExerciseResultsTable createAlias(String alias) {
    return $WorkoutExerciseResultsTable(attachedDatabase, alias);
  }
}

class WorkoutExerciseResult extends DataClass
    implements Insertable<WorkoutExerciseResult> {
  final int id;
  final int sessionId;
  final int templateExerciseId;
  final double? lastWeightKg;
  final int? lastReps;
  const WorkoutExerciseResult({
    required this.id,
    required this.sessionId,
    required this.templateExerciseId,
    this.lastWeightKg,
    this.lastReps,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<int>(sessionId);
    map['template_exercise_id'] = Variable<int>(templateExerciseId);
    if (!nullToAbsent || lastWeightKg != null) {
      map['last_weight_kg'] = Variable<double>(lastWeightKg);
    }
    if (!nullToAbsent || lastReps != null) {
      map['last_reps'] = Variable<int>(lastReps);
    }
    return map;
  }

  WorkoutExerciseResultsCompanion toCompanion(bool nullToAbsent) {
    return WorkoutExerciseResultsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      templateExerciseId: Value(templateExerciseId),
      lastWeightKg: lastWeightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(lastWeightKg),
      lastReps: lastReps == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReps),
    );
  }

  factory WorkoutExerciseResult.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutExerciseResult(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<int>(json['sessionId']),
      templateExerciseId: serializer.fromJson<int>(json['templateExerciseId']),
      lastWeightKg: serializer.fromJson<double?>(json['lastWeightKg']),
      lastReps: serializer.fromJson<int?>(json['lastReps']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<int>(sessionId),
      'templateExerciseId': serializer.toJson<int>(templateExerciseId),
      'lastWeightKg': serializer.toJson<double?>(lastWeightKg),
      'lastReps': serializer.toJson<int?>(lastReps),
    };
  }

  WorkoutExerciseResult copyWith({
    int? id,
    int? sessionId,
    int? templateExerciseId,
    Value<double?> lastWeightKg = const Value.absent(),
    Value<int?> lastReps = const Value.absent(),
  }) => WorkoutExerciseResult(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    templateExerciseId: templateExerciseId ?? this.templateExerciseId,
    lastWeightKg: lastWeightKg.present ? lastWeightKg.value : this.lastWeightKg,
    lastReps: lastReps.present ? lastReps.value : this.lastReps,
  );
  WorkoutExerciseResult copyWithCompanion(
    WorkoutExerciseResultsCompanion data,
  ) {
    return WorkoutExerciseResult(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      templateExerciseId: data.templateExerciseId.present
          ? data.templateExerciseId.value
          : this.templateExerciseId,
      lastWeightKg: data.lastWeightKg.present
          ? data.lastWeightKg.value
          : this.lastWeightKg,
      lastReps: data.lastReps.present ? data.lastReps.value : this.lastReps,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutExerciseResult(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('templateExerciseId: $templateExerciseId, ')
          ..write('lastWeightKg: $lastWeightKg, ')
          ..write('lastReps: $lastReps')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, sessionId, templateExerciseId, lastWeightKg, lastReps);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutExerciseResult &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.templateExerciseId == this.templateExerciseId &&
          other.lastWeightKg == this.lastWeightKg &&
          other.lastReps == this.lastReps);
}

class WorkoutExerciseResultsCompanion
    extends UpdateCompanion<WorkoutExerciseResult> {
  final Value<int> id;
  final Value<int> sessionId;
  final Value<int> templateExerciseId;
  final Value<double?> lastWeightKg;
  final Value<int?> lastReps;
  const WorkoutExerciseResultsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.templateExerciseId = const Value.absent(),
    this.lastWeightKg = const Value.absent(),
    this.lastReps = const Value.absent(),
  });
  WorkoutExerciseResultsCompanion.insert({
    this.id = const Value.absent(),
    required int sessionId,
    required int templateExerciseId,
    this.lastWeightKg = const Value.absent(),
    this.lastReps = const Value.absent(),
  }) : sessionId = Value(sessionId),
       templateExerciseId = Value(templateExerciseId);
  static Insertable<WorkoutExerciseResult> custom({
    Expression<int>? id,
    Expression<int>? sessionId,
    Expression<int>? templateExerciseId,
    Expression<double>? lastWeightKg,
    Expression<int>? lastReps,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (templateExerciseId != null)
        'template_exercise_id': templateExerciseId,
      if (lastWeightKg != null) 'last_weight_kg': lastWeightKg,
      if (lastReps != null) 'last_reps': lastReps,
    });
  }

  WorkoutExerciseResultsCompanion copyWith({
    Value<int>? id,
    Value<int>? sessionId,
    Value<int>? templateExerciseId,
    Value<double?>? lastWeightKg,
    Value<int?>? lastReps,
  }) {
    return WorkoutExerciseResultsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      templateExerciseId: templateExerciseId ?? this.templateExerciseId,
      lastWeightKg: lastWeightKg ?? this.lastWeightKg,
      lastReps: lastReps ?? this.lastReps,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (templateExerciseId.present) {
      map['template_exercise_id'] = Variable<int>(templateExerciseId.value);
    }
    if (lastWeightKg.present) {
      map['last_weight_kg'] = Variable<double>(lastWeightKg.value);
    }
    if (lastReps.present) {
      map['last_reps'] = Variable<int>(lastReps.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutExerciseResultsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('templateExerciseId: $templateExerciseId, ')
          ..write('lastWeightKg: $lastWeightKg, ')
          ..write('lastReps: $lastReps')
          ..write(')'))
        .toString();
  }
}

class $ClientTemplateExerciseOverridesTable
    extends ClientTemplateExerciseOverrides
    with
        TableInfo<
          $ClientTemplateExerciseOverridesTable,
          ClientTemplateExerciseOverride
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClientTemplateExerciseOverridesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _templateExerciseIdMeta =
      const VerificationMeta('templateExerciseId');
  @override
  late final GeneratedColumn<int> templateExerciseId = GeneratedColumn<int>(
    'template_exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _supersetGroupMeta = const VerificationMeta(
    'supersetGroup',
  );
  @override
  late final GeneratedColumn<int> supersetGroup = GeneratedColumn<int>(
    'superset_group',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clientId,
    templateExerciseId,
    supersetGroup,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'client_template_exercise_overrides';
  @override
  VerificationContext validateIntegrity(
    Insertable<ClientTemplateExerciseOverride> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clientIdMeta);
    }
    if (data.containsKey('template_exercise_id')) {
      context.handle(
        _templateExerciseIdMeta,
        templateExerciseId.isAcceptableOrUnknown(
          data['template_exercise_id']!,
          _templateExerciseIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_templateExerciseIdMeta);
    }
    if (data.containsKey('superset_group')) {
      context.handle(
        _supersetGroupMeta,
        supersetGroup.isAcceptableOrUnknown(
          data['superset_group']!,
          _supersetGroupMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {clientId, templateExerciseId},
  ];
  @override
  ClientTemplateExerciseOverride map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClientTemplateExerciseOverride(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      )!,
      templateExerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}template_exercise_id'],
      )!,
      supersetGroup: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}superset_group'],
      ),
    );
  }

  @override
  $ClientTemplateExerciseOverridesTable createAlias(String alias) {
    return $ClientTemplateExerciseOverridesTable(attachedDatabase, alias);
  }
}

class ClientTemplateExerciseOverride extends DataClass
    implements Insertable<ClientTemplateExerciseOverride> {
  final int id;
  final String clientId;
  final int templateExerciseId;
  final int? supersetGroup;
  const ClientTemplateExerciseOverride({
    required this.id,
    required this.clientId,
    required this.templateExerciseId,
    this.supersetGroup,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['client_id'] = Variable<String>(clientId);
    map['template_exercise_id'] = Variable<int>(templateExerciseId);
    if (!nullToAbsent || supersetGroup != null) {
      map['superset_group'] = Variable<int>(supersetGroup);
    }
    return map;
  }

  ClientTemplateExerciseOverridesCompanion toCompanion(bool nullToAbsent) {
    return ClientTemplateExerciseOverridesCompanion(
      id: Value(id),
      clientId: Value(clientId),
      templateExerciseId: Value(templateExerciseId),
      supersetGroup: supersetGroup == null && nullToAbsent
          ? const Value.absent()
          : Value(supersetGroup),
    );
  }

  factory ClientTemplateExerciseOverride.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClientTemplateExerciseOverride(
      id: serializer.fromJson<int>(json['id']),
      clientId: serializer.fromJson<String>(json['clientId']),
      templateExerciseId: serializer.fromJson<int>(json['templateExerciseId']),
      supersetGroup: serializer.fromJson<int?>(json['supersetGroup']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'clientId': serializer.toJson<String>(clientId),
      'templateExerciseId': serializer.toJson<int>(templateExerciseId),
      'supersetGroup': serializer.toJson<int?>(supersetGroup),
    };
  }

  ClientTemplateExerciseOverride copyWith({
    int? id,
    String? clientId,
    int? templateExerciseId,
    Value<int?> supersetGroup = const Value.absent(),
  }) => ClientTemplateExerciseOverride(
    id: id ?? this.id,
    clientId: clientId ?? this.clientId,
    templateExerciseId: templateExerciseId ?? this.templateExerciseId,
    supersetGroup: supersetGroup.present
        ? supersetGroup.value
        : this.supersetGroup,
  );
  ClientTemplateExerciseOverride copyWithCompanion(
    ClientTemplateExerciseOverridesCompanion data,
  ) {
    return ClientTemplateExerciseOverride(
      id: data.id.present ? data.id.value : this.id,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      templateExerciseId: data.templateExerciseId.present
          ? data.templateExerciseId.value
          : this.templateExerciseId,
      supersetGroup: data.supersetGroup.present
          ? data.supersetGroup.value
          : this.supersetGroup,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClientTemplateExerciseOverride(')
          ..write('id: $id, ')
          ..write('clientId: $clientId, ')
          ..write('templateExerciseId: $templateExerciseId, ')
          ..write('supersetGroup: $supersetGroup')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, clientId, templateExerciseId, supersetGroup);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClientTemplateExerciseOverride &&
          other.id == this.id &&
          other.clientId == this.clientId &&
          other.templateExerciseId == this.templateExerciseId &&
          other.supersetGroup == this.supersetGroup);
}

class ClientTemplateExerciseOverridesCompanion
    extends UpdateCompanion<ClientTemplateExerciseOverride> {
  final Value<int> id;
  final Value<String> clientId;
  final Value<int> templateExerciseId;
  final Value<int?> supersetGroup;
  const ClientTemplateExerciseOverridesCompanion({
    this.id = const Value.absent(),
    this.clientId = const Value.absent(),
    this.templateExerciseId = const Value.absent(),
    this.supersetGroup = const Value.absent(),
  });
  ClientTemplateExerciseOverridesCompanion.insert({
    this.id = const Value.absent(),
    required String clientId,
    required int templateExerciseId,
    this.supersetGroup = const Value.absent(),
  }) : clientId = Value(clientId),
       templateExerciseId = Value(templateExerciseId);
  static Insertable<ClientTemplateExerciseOverride> custom({
    Expression<int>? id,
    Expression<String>? clientId,
    Expression<int>? templateExerciseId,
    Expression<int>? supersetGroup,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientId != null) 'client_id': clientId,
      if (templateExerciseId != null)
        'template_exercise_id': templateExerciseId,
      if (supersetGroup != null) 'superset_group': supersetGroup,
    });
  }

  ClientTemplateExerciseOverridesCompanion copyWith({
    Value<int>? id,
    Value<String>? clientId,
    Value<int>? templateExerciseId,
    Value<int?>? supersetGroup,
  }) {
    return ClientTemplateExerciseOverridesCompanion(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      templateExerciseId: templateExerciseId ?? this.templateExerciseId,
      supersetGroup: supersetGroup ?? this.supersetGroup,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (templateExerciseId.present) {
      map['template_exercise_id'] = Variable<int>(templateExerciseId.value);
    }
    if (supersetGroup.present) {
      map['superset_group'] = Variable<int>(supersetGroup.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClientTemplateExerciseOverridesCompanion(')
          ..write('id: $id, ')
          ..write('clientId: $clientId, ')
          ..write('templateExerciseId: $templateExerciseId, ')
          ..write('supersetGroup: $supersetGroup')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDb extends GeneratedDatabase {
  _$AppDb(QueryExecutor e) : super(e);
  $AppDbManager get managers => $AppDbManager(this);
  late final $ClientsTable clients = $ClientsTable(this);
  late final $AppointmentsTable appointments = $AppointmentsTable(this);
  late final $WorkoutTemplatesTable workoutTemplates = $WorkoutTemplatesTable(
    this,
  );
  late final $ClientProgramStatesTable clientProgramStates =
      $ClientProgramStatesTable(this);
  late final $WorkoutSessionsTable workoutSessions = $WorkoutSessionsTable(
    this,
  );
  late final $WorkoutTemplateExercisesTable workoutTemplateExercises =
      $WorkoutTemplateExercisesTable(this);
  late final $WorkoutExerciseResultsTable workoutExerciseResults =
      $WorkoutExerciseResultsTable(this);
  late final $ClientTemplateExerciseOverridesTable
  clientTemplateExerciseOverrides = $ClientTemplateExerciseOverridesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    clients,
    appointments,
    workoutTemplates,
    clientProgramStates,
    workoutSessions,
    workoutTemplateExercises,
    workoutExerciseResults,
    clientTemplateExerciseOverrides,
  ];
}

typedef $$ClientsTableCreateCompanionBuilder =
    ClientsCompanion Function({
      required String id,
      required String name,
      Value<String?> gender,
      Value<String?> plan,
      Value<DateTime?> planStart,
      Value<DateTime?> planEnd,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$ClientsTableUpdateCompanionBuilder =
    ClientsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> gender,
      Value<String?> plan,
      Value<DateTime?> planStart,
      Value<DateTime?> planEnd,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$ClientsTableFilterComposer extends Composer<_$AppDb, $ClientsTable> {
  $$ClientsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get plan => $composableBuilder(
    column: $table.plan,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get planStart => $composableBuilder(
    column: $table.planStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get planEnd => $composableBuilder(
    column: $table.planEnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ClientsTableOrderingComposer extends Composer<_$AppDb, $ClientsTable> {
  $$ClientsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plan => $composableBuilder(
    column: $table.plan,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get planStart => $composableBuilder(
    column: $table.planStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get planEnd => $composableBuilder(
    column: $table.planEnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ClientsTableAnnotationComposer
    extends Composer<_$AppDb, $ClientsTable> {
  $$ClientsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get gender =>
      $composableBuilder(column: $table.gender, builder: (column) => column);

  GeneratedColumn<String> get plan =>
      $composableBuilder(column: $table.plan, builder: (column) => column);

  GeneratedColumn<DateTime> get planStart =>
      $composableBuilder(column: $table.planStart, builder: (column) => column);

  GeneratedColumn<DateTime> get planEnd =>
      $composableBuilder(column: $table.planEnd, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ClientsTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $ClientsTable,
          Client,
          $$ClientsTableFilterComposer,
          $$ClientsTableOrderingComposer,
          $$ClientsTableAnnotationComposer,
          $$ClientsTableCreateCompanionBuilder,
          $$ClientsTableUpdateCompanionBuilder,
          (Client, BaseReferences<_$AppDb, $ClientsTable, Client>),
          Client,
          PrefetchHooks Function()
        > {
  $$ClientsTableTableManager(_$AppDb db, $ClientsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClientsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClientsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClientsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> gender = const Value.absent(),
                Value<String?> plan = const Value.absent(),
                Value<DateTime?> planStart = const Value.absent(),
                Value<DateTime?> planEnd = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClientsCompanion(
                id: id,
                name: name,
                gender: gender,
                plan: plan,
                planStart: planStart,
                planEnd: planEnd,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> gender = const Value.absent(),
                Value<String?> plan = const Value.absent(),
                Value<DateTime?> planStart = const Value.absent(),
                Value<DateTime?> planEnd = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClientsCompanion.insert(
                id: id,
                name: name,
                gender: gender,
                plan: plan,
                planStart: planStart,
                planEnd: planEnd,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ClientsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $ClientsTable,
      Client,
      $$ClientsTableFilterComposer,
      $$ClientsTableOrderingComposer,
      $$ClientsTableAnnotationComposer,
      $$ClientsTableCreateCompanionBuilder,
      $$ClientsTableUpdateCompanionBuilder,
      (Client, BaseReferences<_$AppDb, $ClientsTable, Client>),
      Client,
      PrefetchHooks Function()
    >;
typedef $$AppointmentsTableCreateCompanionBuilder =
    AppointmentsCompanion Function({
      required String id,
      required String clientId,
      required DateTime startAt,
      Value<String?> note,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$AppointmentsTableUpdateCompanionBuilder =
    AppointmentsCompanion Function({
      Value<String> id,
      Value<String> clientId,
      Value<DateTime> startAt,
      Value<String?> note,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$AppointmentsTableFilterComposer
    extends Composer<_$AppDb, $AppointmentsTable> {
  $$AppointmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startAt => $composableBuilder(
    column: $table.startAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppointmentsTableOrderingComposer
    extends Composer<_$AppDb, $AppointmentsTable> {
  $$AppointmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startAt => $composableBuilder(
    column: $table.startAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppointmentsTableAnnotationComposer
    extends Composer<_$AppDb, $AppointmentsTable> {
  $$AppointmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<DateTime> get startAt =>
      $composableBuilder(column: $table.startAt, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$AppointmentsTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $AppointmentsTable,
          Appointment,
          $$AppointmentsTableFilterComposer,
          $$AppointmentsTableOrderingComposer,
          $$AppointmentsTableAnnotationComposer,
          $$AppointmentsTableCreateCompanionBuilder,
          $$AppointmentsTableUpdateCompanionBuilder,
          (
            Appointment,
            BaseReferences<_$AppDb, $AppointmentsTable, Appointment>,
          ),
          Appointment,
          PrefetchHooks Function()
        > {
  $$AppointmentsTableTableManager(_$AppDb db, $AppointmentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppointmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppointmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppointmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> clientId = const Value.absent(),
                Value<DateTime> startAt = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppointmentsCompanion(
                id: id,
                clientId: clientId,
                startAt: startAt,
                note: note,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String clientId,
                required DateTime startAt,
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppointmentsCompanion.insert(
                id: id,
                clientId: clientId,
                startAt: startAt,
                note: note,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppointmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $AppointmentsTable,
      Appointment,
      $$AppointmentsTableFilterComposer,
      $$AppointmentsTableOrderingComposer,
      $$AppointmentsTableAnnotationComposer,
      $$AppointmentsTableCreateCompanionBuilder,
      $$AppointmentsTableUpdateCompanionBuilder,
      (Appointment, BaseReferences<_$AppDb, $AppointmentsTable, Appointment>),
      Appointment,
      PrefetchHooks Function()
    >;
typedef $$WorkoutTemplatesTableCreateCompanionBuilder =
    WorkoutTemplatesCompanion Function({
      Value<int> id,
      required String gender,
      required int idx,
      required String label,
      required String title,
      Value<String?> payloadJson,
    });
typedef $$WorkoutTemplatesTableUpdateCompanionBuilder =
    WorkoutTemplatesCompanion Function({
      Value<int> id,
      Value<String> gender,
      Value<int> idx,
      Value<String> label,
      Value<String> title,
      Value<String?> payloadJson,
    });

class $$WorkoutTemplatesTableFilterComposer
    extends Composer<_$AppDb, $WorkoutTemplatesTable> {
  $$WorkoutTemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get idx => $composableBuilder(
    column: $table.idx,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WorkoutTemplatesTableOrderingComposer
    extends Composer<_$AppDb, $WorkoutTemplatesTable> {
  $$WorkoutTemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get idx => $composableBuilder(
    column: $table.idx,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorkoutTemplatesTableAnnotationComposer
    extends Composer<_$AppDb, $WorkoutTemplatesTable> {
  $$WorkoutTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get gender =>
      $composableBuilder(column: $table.gender, builder: (column) => column);

  GeneratedColumn<int> get idx =>
      $composableBuilder(column: $table.idx, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );
}

class $$WorkoutTemplatesTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $WorkoutTemplatesTable,
          WorkoutTemplate,
          $$WorkoutTemplatesTableFilterComposer,
          $$WorkoutTemplatesTableOrderingComposer,
          $$WorkoutTemplatesTableAnnotationComposer,
          $$WorkoutTemplatesTableCreateCompanionBuilder,
          $$WorkoutTemplatesTableUpdateCompanionBuilder,
          (
            WorkoutTemplate,
            BaseReferences<_$AppDb, $WorkoutTemplatesTable, WorkoutTemplate>,
          ),
          WorkoutTemplate,
          PrefetchHooks Function()
        > {
  $$WorkoutTemplatesTableTableManager(_$AppDb db, $WorkoutTemplatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutTemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutTemplatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> gender = const Value.absent(),
                Value<int> idx = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> payloadJson = const Value.absent(),
              }) => WorkoutTemplatesCompanion(
                id: id,
                gender: gender,
                idx: idx,
                label: label,
                title: title,
                payloadJson: payloadJson,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String gender,
                required int idx,
                required String label,
                required String title,
                Value<String?> payloadJson = const Value.absent(),
              }) => WorkoutTemplatesCompanion.insert(
                id: id,
                gender: gender,
                idx: idx,
                label: label,
                title: title,
                payloadJson: payloadJson,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WorkoutTemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $WorkoutTemplatesTable,
      WorkoutTemplate,
      $$WorkoutTemplatesTableFilterComposer,
      $$WorkoutTemplatesTableOrderingComposer,
      $$WorkoutTemplatesTableAnnotationComposer,
      $$WorkoutTemplatesTableCreateCompanionBuilder,
      $$WorkoutTemplatesTableUpdateCompanionBuilder,
      (
        WorkoutTemplate,
        BaseReferences<_$AppDb, $WorkoutTemplatesTable, WorkoutTemplate>,
      ),
      WorkoutTemplate,
      PrefetchHooks Function()
    >;
typedef $$ClientProgramStatesTableCreateCompanionBuilder =
    ClientProgramStatesCompanion Function({
      required String clientId,
      required int planSize,
      Value<int> planInstance,
      Value<int> completedInPlan,
      Value<int> cycleStartIndex,
      Value<int> nextOffset,
      Value<int> windowStart,
      Value<DateTime?> planStart,
      Value<DateTime?> planEnd,
      Value<int> rowid,
    });
typedef $$ClientProgramStatesTableUpdateCompanionBuilder =
    ClientProgramStatesCompanion Function({
      Value<String> clientId,
      Value<int> planSize,
      Value<int> planInstance,
      Value<int> completedInPlan,
      Value<int> cycleStartIndex,
      Value<int> nextOffset,
      Value<int> windowStart,
      Value<DateTime?> planStart,
      Value<DateTime?> planEnd,
      Value<int> rowid,
    });

class $$ClientProgramStatesTableFilterComposer
    extends Composer<_$AppDb, $ClientProgramStatesTable> {
  $$ClientProgramStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get planSize => $composableBuilder(
    column: $table.planSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get planInstance => $composableBuilder(
    column: $table.planInstance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedInPlan => $composableBuilder(
    column: $table.completedInPlan,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cycleStartIndex => $composableBuilder(
    column: $table.cycleStartIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nextOffset => $composableBuilder(
    column: $table.nextOffset,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get windowStart => $composableBuilder(
    column: $table.windowStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get planStart => $composableBuilder(
    column: $table.planStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get planEnd => $composableBuilder(
    column: $table.planEnd,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ClientProgramStatesTableOrderingComposer
    extends Composer<_$AppDb, $ClientProgramStatesTable> {
  $$ClientProgramStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get planSize => $composableBuilder(
    column: $table.planSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get planInstance => $composableBuilder(
    column: $table.planInstance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedInPlan => $composableBuilder(
    column: $table.completedInPlan,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cycleStartIndex => $composableBuilder(
    column: $table.cycleStartIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nextOffset => $composableBuilder(
    column: $table.nextOffset,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get windowStart => $composableBuilder(
    column: $table.windowStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get planStart => $composableBuilder(
    column: $table.planStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get planEnd => $composableBuilder(
    column: $table.planEnd,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ClientProgramStatesTableAnnotationComposer
    extends Composer<_$AppDb, $ClientProgramStatesTable> {
  $$ClientProgramStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<int> get planSize =>
      $composableBuilder(column: $table.planSize, builder: (column) => column);

  GeneratedColumn<int> get planInstance => $composableBuilder(
    column: $table.planInstance,
    builder: (column) => column,
  );

  GeneratedColumn<int> get completedInPlan => $composableBuilder(
    column: $table.completedInPlan,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cycleStartIndex => $composableBuilder(
    column: $table.cycleStartIndex,
    builder: (column) => column,
  );

  GeneratedColumn<int> get nextOffset => $composableBuilder(
    column: $table.nextOffset,
    builder: (column) => column,
  );

  GeneratedColumn<int> get windowStart => $composableBuilder(
    column: $table.windowStart,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get planStart =>
      $composableBuilder(column: $table.planStart, builder: (column) => column);

  GeneratedColumn<DateTime> get planEnd =>
      $composableBuilder(column: $table.planEnd, builder: (column) => column);
}

class $$ClientProgramStatesTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $ClientProgramStatesTable,
          ClientProgramState,
          $$ClientProgramStatesTableFilterComposer,
          $$ClientProgramStatesTableOrderingComposer,
          $$ClientProgramStatesTableAnnotationComposer,
          $$ClientProgramStatesTableCreateCompanionBuilder,
          $$ClientProgramStatesTableUpdateCompanionBuilder,
          (
            ClientProgramState,
            BaseReferences<
              _$AppDb,
              $ClientProgramStatesTable,
              ClientProgramState
            >,
          ),
          ClientProgramState,
          PrefetchHooks Function()
        > {
  $$ClientProgramStatesTableTableManager(
    _$AppDb db,
    $ClientProgramStatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClientProgramStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClientProgramStatesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ClientProgramStatesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> clientId = const Value.absent(),
                Value<int> planSize = const Value.absent(),
                Value<int> planInstance = const Value.absent(),
                Value<int> completedInPlan = const Value.absent(),
                Value<int> cycleStartIndex = const Value.absent(),
                Value<int> nextOffset = const Value.absent(),
                Value<int> windowStart = const Value.absent(),
                Value<DateTime?> planStart = const Value.absent(),
                Value<DateTime?> planEnd = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClientProgramStatesCompanion(
                clientId: clientId,
                planSize: planSize,
                planInstance: planInstance,
                completedInPlan: completedInPlan,
                cycleStartIndex: cycleStartIndex,
                nextOffset: nextOffset,
                windowStart: windowStart,
                planStart: planStart,
                planEnd: planEnd,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String clientId,
                required int planSize,
                Value<int> planInstance = const Value.absent(),
                Value<int> completedInPlan = const Value.absent(),
                Value<int> cycleStartIndex = const Value.absent(),
                Value<int> nextOffset = const Value.absent(),
                Value<int> windowStart = const Value.absent(),
                Value<DateTime?> planStart = const Value.absent(),
                Value<DateTime?> planEnd = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClientProgramStatesCompanion.insert(
                clientId: clientId,
                planSize: planSize,
                planInstance: planInstance,
                completedInPlan: completedInPlan,
                cycleStartIndex: cycleStartIndex,
                nextOffset: nextOffset,
                windowStart: windowStart,
                planStart: planStart,
                planEnd: planEnd,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ClientProgramStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $ClientProgramStatesTable,
      ClientProgramState,
      $$ClientProgramStatesTableFilterComposer,
      $$ClientProgramStatesTableOrderingComposer,
      $$ClientProgramStatesTableAnnotationComposer,
      $$ClientProgramStatesTableCreateCompanionBuilder,
      $$ClientProgramStatesTableUpdateCompanionBuilder,
      (
        ClientProgramState,
        BaseReferences<_$AppDb, $ClientProgramStatesTable, ClientProgramState>,
      ),
      ClientProgramState,
      PrefetchHooks Function()
    >;
typedef $$WorkoutSessionsTableCreateCompanionBuilder =
    WorkoutSessionsCompanion Function({
      Value<int> id,
      required String clientId,
      required DateTime performedAt,
      required int planInstance,
      required String gender,
      required int templateIdx,
    });
typedef $$WorkoutSessionsTableUpdateCompanionBuilder =
    WorkoutSessionsCompanion Function({
      Value<int> id,
      Value<String> clientId,
      Value<DateTime> performedAt,
      Value<int> planInstance,
      Value<String> gender,
      Value<int> templateIdx,
    });

class $$WorkoutSessionsTableFilterComposer
    extends Composer<_$AppDb, $WorkoutSessionsTable> {
  $$WorkoutSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get performedAt => $composableBuilder(
    column: $table.performedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get planInstance => $composableBuilder(
    column: $table.planInstance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get templateIdx => $composableBuilder(
    column: $table.templateIdx,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WorkoutSessionsTableOrderingComposer
    extends Composer<_$AppDb, $WorkoutSessionsTable> {
  $$WorkoutSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get performedAt => $composableBuilder(
    column: $table.performedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get planInstance => $composableBuilder(
    column: $table.planInstance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get templateIdx => $composableBuilder(
    column: $table.templateIdx,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorkoutSessionsTableAnnotationComposer
    extends Composer<_$AppDb, $WorkoutSessionsTable> {
  $$WorkoutSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<DateTime> get performedAt => $composableBuilder(
    column: $table.performedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get planInstance => $composableBuilder(
    column: $table.planInstance,
    builder: (column) => column,
  );

  GeneratedColumn<String> get gender =>
      $composableBuilder(column: $table.gender, builder: (column) => column);

  GeneratedColumn<int> get templateIdx => $composableBuilder(
    column: $table.templateIdx,
    builder: (column) => column,
  );
}

class $$WorkoutSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $WorkoutSessionsTable,
          WorkoutSession,
          $$WorkoutSessionsTableFilterComposer,
          $$WorkoutSessionsTableOrderingComposer,
          $$WorkoutSessionsTableAnnotationComposer,
          $$WorkoutSessionsTableCreateCompanionBuilder,
          $$WorkoutSessionsTableUpdateCompanionBuilder,
          (
            WorkoutSession,
            BaseReferences<_$AppDb, $WorkoutSessionsTable, WorkoutSession>,
          ),
          WorkoutSession,
          PrefetchHooks Function()
        > {
  $$WorkoutSessionsTableTableManager(_$AppDb db, $WorkoutSessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> clientId = const Value.absent(),
                Value<DateTime> performedAt = const Value.absent(),
                Value<int> planInstance = const Value.absent(),
                Value<String> gender = const Value.absent(),
                Value<int> templateIdx = const Value.absent(),
              }) => WorkoutSessionsCompanion(
                id: id,
                clientId: clientId,
                performedAt: performedAt,
                planInstance: planInstance,
                gender: gender,
                templateIdx: templateIdx,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String clientId,
                required DateTime performedAt,
                required int planInstance,
                required String gender,
                required int templateIdx,
              }) => WorkoutSessionsCompanion.insert(
                id: id,
                clientId: clientId,
                performedAt: performedAt,
                planInstance: planInstance,
                gender: gender,
                templateIdx: templateIdx,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WorkoutSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $WorkoutSessionsTable,
      WorkoutSession,
      $$WorkoutSessionsTableFilterComposer,
      $$WorkoutSessionsTableOrderingComposer,
      $$WorkoutSessionsTableAnnotationComposer,
      $$WorkoutSessionsTableCreateCompanionBuilder,
      $$WorkoutSessionsTableUpdateCompanionBuilder,
      (
        WorkoutSession,
        BaseReferences<_$AppDb, $WorkoutSessionsTable, WorkoutSession>,
      ),
      WorkoutSession,
      PrefetchHooks Function()
    >;
typedef $$WorkoutTemplateExercisesTableCreateCompanionBuilder =
    WorkoutTemplateExercisesCompanion Function({
      Value<int> id,
      required int templateId,
      required int orderIndex,
      Value<int?> groupId,
      required String name,
    });
typedef $$WorkoutTemplateExercisesTableUpdateCompanionBuilder =
    WorkoutTemplateExercisesCompanion Function({
      Value<int> id,
      Value<int> templateId,
      Value<int> orderIndex,
      Value<int?> groupId,
      Value<String> name,
    });

class $$WorkoutTemplateExercisesTableFilterComposer
    extends Composer<_$AppDb, $WorkoutTemplateExercisesTable> {
  $$WorkoutTemplateExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WorkoutTemplateExercisesTableOrderingComposer
    extends Composer<_$AppDb, $WorkoutTemplateExercisesTable> {
  $$WorkoutTemplateExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorkoutTemplateExercisesTableAnnotationComposer
    extends Composer<_$AppDb, $WorkoutTemplateExercisesTable> {
  $$WorkoutTemplateExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );

  GeneratedColumn<int> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);
}

class $$WorkoutTemplateExercisesTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $WorkoutTemplateExercisesTable,
          WorkoutTemplateExercise,
          $$WorkoutTemplateExercisesTableFilterComposer,
          $$WorkoutTemplateExercisesTableOrderingComposer,
          $$WorkoutTemplateExercisesTableAnnotationComposer,
          $$WorkoutTemplateExercisesTableCreateCompanionBuilder,
          $$WorkoutTemplateExercisesTableUpdateCompanionBuilder,
          (
            WorkoutTemplateExercise,
            BaseReferences<
              _$AppDb,
              $WorkoutTemplateExercisesTable,
              WorkoutTemplateExercise
            >,
          ),
          WorkoutTemplateExercise,
          PrefetchHooks Function()
        > {
  $$WorkoutTemplateExercisesTableTableManager(
    _$AppDb db,
    $WorkoutTemplateExercisesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutTemplateExercisesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$WorkoutTemplateExercisesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$WorkoutTemplateExercisesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> templateId = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<int?> groupId = const Value.absent(),
                Value<String> name = const Value.absent(),
              }) => WorkoutTemplateExercisesCompanion(
                id: id,
                templateId: templateId,
                orderIndex: orderIndex,
                groupId: groupId,
                name: name,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int templateId,
                required int orderIndex,
                Value<int?> groupId = const Value.absent(),
                required String name,
              }) => WorkoutTemplateExercisesCompanion.insert(
                id: id,
                templateId: templateId,
                orderIndex: orderIndex,
                groupId: groupId,
                name: name,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WorkoutTemplateExercisesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $WorkoutTemplateExercisesTable,
      WorkoutTemplateExercise,
      $$WorkoutTemplateExercisesTableFilterComposer,
      $$WorkoutTemplateExercisesTableOrderingComposer,
      $$WorkoutTemplateExercisesTableAnnotationComposer,
      $$WorkoutTemplateExercisesTableCreateCompanionBuilder,
      $$WorkoutTemplateExercisesTableUpdateCompanionBuilder,
      (
        WorkoutTemplateExercise,
        BaseReferences<
          _$AppDb,
          $WorkoutTemplateExercisesTable,
          WorkoutTemplateExercise
        >,
      ),
      WorkoutTemplateExercise,
      PrefetchHooks Function()
    >;
typedef $$WorkoutExerciseResultsTableCreateCompanionBuilder =
    WorkoutExerciseResultsCompanion Function({
      Value<int> id,
      required int sessionId,
      required int templateExerciseId,
      Value<double?> lastWeightKg,
      Value<int?> lastReps,
    });
typedef $$WorkoutExerciseResultsTableUpdateCompanionBuilder =
    WorkoutExerciseResultsCompanion Function({
      Value<int> id,
      Value<int> sessionId,
      Value<int> templateExerciseId,
      Value<double?> lastWeightKg,
      Value<int?> lastReps,
    });

class $$WorkoutExerciseResultsTableFilterComposer
    extends Composer<_$AppDb, $WorkoutExerciseResultsTable> {
  $$WorkoutExerciseResultsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get templateExerciseId => $composableBuilder(
    column: $table.templateExerciseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lastWeightKg => $composableBuilder(
    column: $table.lastWeightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastReps => $composableBuilder(
    column: $table.lastReps,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WorkoutExerciseResultsTableOrderingComposer
    extends Composer<_$AppDb, $WorkoutExerciseResultsTable> {
  $$WorkoutExerciseResultsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get templateExerciseId => $composableBuilder(
    column: $table.templateExerciseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lastWeightKg => $composableBuilder(
    column: $table.lastWeightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastReps => $composableBuilder(
    column: $table.lastReps,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorkoutExerciseResultsTableAnnotationComposer
    extends Composer<_$AppDb, $WorkoutExerciseResultsTable> {
  $$WorkoutExerciseResultsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<int> get templateExerciseId => $composableBuilder(
    column: $table.templateExerciseId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get lastWeightKg => $composableBuilder(
    column: $table.lastWeightKg,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastReps =>
      $composableBuilder(column: $table.lastReps, builder: (column) => column);
}

class $$WorkoutExerciseResultsTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $WorkoutExerciseResultsTable,
          WorkoutExerciseResult,
          $$WorkoutExerciseResultsTableFilterComposer,
          $$WorkoutExerciseResultsTableOrderingComposer,
          $$WorkoutExerciseResultsTableAnnotationComposer,
          $$WorkoutExerciseResultsTableCreateCompanionBuilder,
          $$WorkoutExerciseResultsTableUpdateCompanionBuilder,
          (
            WorkoutExerciseResult,
            BaseReferences<
              _$AppDb,
              $WorkoutExerciseResultsTable,
              WorkoutExerciseResult
            >,
          ),
          WorkoutExerciseResult,
          PrefetchHooks Function()
        > {
  $$WorkoutExerciseResultsTableTableManager(
    _$AppDb db,
    $WorkoutExerciseResultsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutExerciseResultsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$WorkoutExerciseResultsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$WorkoutExerciseResultsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> sessionId = const Value.absent(),
                Value<int> templateExerciseId = const Value.absent(),
                Value<double?> lastWeightKg = const Value.absent(),
                Value<int?> lastReps = const Value.absent(),
              }) => WorkoutExerciseResultsCompanion(
                id: id,
                sessionId: sessionId,
                templateExerciseId: templateExerciseId,
                lastWeightKg: lastWeightKg,
                lastReps: lastReps,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int sessionId,
                required int templateExerciseId,
                Value<double?> lastWeightKg = const Value.absent(),
                Value<int?> lastReps = const Value.absent(),
              }) => WorkoutExerciseResultsCompanion.insert(
                id: id,
                sessionId: sessionId,
                templateExerciseId: templateExerciseId,
                lastWeightKg: lastWeightKg,
                lastReps: lastReps,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WorkoutExerciseResultsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $WorkoutExerciseResultsTable,
      WorkoutExerciseResult,
      $$WorkoutExerciseResultsTableFilterComposer,
      $$WorkoutExerciseResultsTableOrderingComposer,
      $$WorkoutExerciseResultsTableAnnotationComposer,
      $$WorkoutExerciseResultsTableCreateCompanionBuilder,
      $$WorkoutExerciseResultsTableUpdateCompanionBuilder,
      (
        WorkoutExerciseResult,
        BaseReferences<
          _$AppDb,
          $WorkoutExerciseResultsTable,
          WorkoutExerciseResult
        >,
      ),
      WorkoutExerciseResult,
      PrefetchHooks Function()
    >;
typedef $$ClientTemplateExerciseOverridesTableCreateCompanionBuilder =
    ClientTemplateExerciseOverridesCompanion Function({
      Value<int> id,
      required String clientId,
      required int templateExerciseId,
      Value<int?> supersetGroup,
    });
typedef $$ClientTemplateExerciseOverridesTableUpdateCompanionBuilder =
    ClientTemplateExerciseOverridesCompanion Function({
      Value<int> id,
      Value<String> clientId,
      Value<int> templateExerciseId,
      Value<int?> supersetGroup,
    });

class $$ClientTemplateExerciseOverridesTableFilterComposer
    extends Composer<_$AppDb, $ClientTemplateExerciseOverridesTable> {
  $$ClientTemplateExerciseOverridesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get templateExerciseId => $composableBuilder(
    column: $table.templateExerciseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get supersetGroup => $composableBuilder(
    column: $table.supersetGroup,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ClientTemplateExerciseOverridesTableOrderingComposer
    extends Composer<_$AppDb, $ClientTemplateExerciseOverridesTable> {
  $$ClientTemplateExerciseOverridesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get templateExerciseId => $composableBuilder(
    column: $table.templateExerciseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get supersetGroup => $composableBuilder(
    column: $table.supersetGroup,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ClientTemplateExerciseOverridesTableAnnotationComposer
    extends Composer<_$AppDb, $ClientTemplateExerciseOverridesTable> {
  $$ClientTemplateExerciseOverridesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<int> get templateExerciseId => $composableBuilder(
    column: $table.templateExerciseId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get supersetGroup => $composableBuilder(
    column: $table.supersetGroup,
    builder: (column) => column,
  );
}

class $$ClientTemplateExerciseOverridesTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $ClientTemplateExerciseOverridesTable,
          ClientTemplateExerciseOverride,
          $$ClientTemplateExerciseOverridesTableFilterComposer,
          $$ClientTemplateExerciseOverridesTableOrderingComposer,
          $$ClientTemplateExerciseOverridesTableAnnotationComposer,
          $$ClientTemplateExerciseOverridesTableCreateCompanionBuilder,
          $$ClientTemplateExerciseOverridesTableUpdateCompanionBuilder,
          (
            ClientTemplateExerciseOverride,
            BaseReferences<
              _$AppDb,
              $ClientTemplateExerciseOverridesTable,
              ClientTemplateExerciseOverride
            >,
          ),
          ClientTemplateExerciseOverride,
          PrefetchHooks Function()
        > {
  $$ClientTemplateExerciseOverridesTableTableManager(
    _$AppDb db,
    $ClientTemplateExerciseOverridesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClientTemplateExerciseOverridesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ClientTemplateExerciseOverridesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ClientTemplateExerciseOverridesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> clientId = const Value.absent(),
                Value<int> templateExerciseId = const Value.absent(),
                Value<int?> supersetGroup = const Value.absent(),
              }) => ClientTemplateExerciseOverridesCompanion(
                id: id,
                clientId: clientId,
                templateExerciseId: templateExerciseId,
                supersetGroup: supersetGroup,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String clientId,
                required int templateExerciseId,
                Value<int?> supersetGroup = const Value.absent(),
              }) => ClientTemplateExerciseOverridesCompanion.insert(
                id: id,
                clientId: clientId,
                templateExerciseId: templateExerciseId,
                supersetGroup: supersetGroup,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ClientTemplateExerciseOverridesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $ClientTemplateExerciseOverridesTable,
      ClientTemplateExerciseOverride,
      $$ClientTemplateExerciseOverridesTableFilterComposer,
      $$ClientTemplateExerciseOverridesTableOrderingComposer,
      $$ClientTemplateExerciseOverridesTableAnnotationComposer,
      $$ClientTemplateExerciseOverridesTableCreateCompanionBuilder,
      $$ClientTemplateExerciseOverridesTableUpdateCompanionBuilder,
      (
        ClientTemplateExerciseOverride,
        BaseReferences<
          _$AppDb,
          $ClientTemplateExerciseOverridesTable,
          ClientTemplateExerciseOverride
        >,
      ),
      ClientTemplateExerciseOverride,
      PrefetchHooks Function()
    >;

class $AppDbManager {
  final _$AppDb _db;
  $AppDbManager(this._db);
  $$ClientsTableTableManager get clients =>
      $$ClientsTableTableManager(_db, _db.clients);
  $$AppointmentsTableTableManager get appointments =>
      $$AppointmentsTableTableManager(_db, _db.appointments);
  $$WorkoutTemplatesTableTableManager get workoutTemplates =>
      $$WorkoutTemplatesTableTableManager(_db, _db.workoutTemplates);
  $$ClientProgramStatesTableTableManager get clientProgramStates =>
      $$ClientProgramStatesTableTableManager(_db, _db.clientProgramStates);
  $$WorkoutSessionsTableTableManager get workoutSessions =>
      $$WorkoutSessionsTableTableManager(_db, _db.workoutSessions);
  $$WorkoutTemplateExercisesTableTableManager get workoutTemplateExercises =>
      $$WorkoutTemplateExercisesTableTableManager(
        _db,
        _db.workoutTemplateExercises,
      );
  $$WorkoutExerciseResultsTableTableManager get workoutExerciseResults =>
      $$WorkoutExerciseResultsTableTableManager(
        _db,
        _db.workoutExerciseResults,
      );
  $$ClientTemplateExerciseOverridesTableTableManager
  get clientTemplateExerciseOverrides =>
      $$ClientTemplateExerciseOverridesTableTableManager(
        _db,
        _db.clientTemplateExerciseOverrides,
      );
}
