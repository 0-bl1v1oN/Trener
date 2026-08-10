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
  static const VerificationMeta _externalIdMeta = const VerificationMeta(
    'externalId',
  );
  @override
  late final GeneratedColumn<String> externalId = GeneratedColumn<String>(
    'external_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
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
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('ACTIVE'),
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
    externalId,
    name,
    status,
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
    if (data.containsKey('external_id')) {
      context.handle(
        _externalIdMeta,
        externalId.isAcceptableOrUnknown(data['external_id']!, _externalIdMeta),
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
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
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
      externalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
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
  final String? externalId;
  final String name;
  final String status;
  final String? gender;
  final String? plan;
  final DateTime? planStart;
  final DateTime? planEnd;
  final DateTime createdAt;
  const Client({
    required this.id,
    this.externalId,
    required this.name,
    required this.status,
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
    if (!nullToAbsent || externalId != null) {
      map['external_id'] = Variable<String>(externalId);
    }
    map['name'] = Variable<String>(name);
    map['status'] = Variable<String>(status);
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
      externalId: externalId == null && nullToAbsent
          ? const Value.absent()
          : Value(externalId),
      name: Value(name),
      status: Value(status),
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
      externalId: serializer.fromJson<String?>(json['externalId']),
      name: serializer.fromJson<String>(json['name']),
      status: serializer.fromJson<String>(json['status']),
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
      'externalId': serializer.toJson<String?>(externalId),
      'name': serializer.toJson<String>(name),
      'status': serializer.toJson<String>(status),
      'gender': serializer.toJson<String?>(gender),
      'plan': serializer.toJson<String?>(plan),
      'planStart': serializer.toJson<DateTime?>(planStart),
      'planEnd': serializer.toJson<DateTime?>(planEnd),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Client copyWith({
    String? id,
    Value<String?> externalId = const Value.absent(),
    String? name,
    String? status,
    Value<String?> gender = const Value.absent(),
    Value<String?> plan = const Value.absent(),
    Value<DateTime?> planStart = const Value.absent(),
    Value<DateTime?> planEnd = const Value.absent(),
    DateTime? createdAt,
  }) => Client(
    id: id ?? this.id,
    externalId: externalId.present ? externalId.value : this.externalId,
    name: name ?? this.name,
    status: status ?? this.status,
    gender: gender.present ? gender.value : this.gender,
    plan: plan.present ? plan.value : this.plan,
    planStart: planStart.present ? planStart.value : this.planStart,
    planEnd: planEnd.present ? planEnd.value : this.planEnd,
    createdAt: createdAt ?? this.createdAt,
  );
  Client copyWithCompanion(ClientsCompanion data) {
    return Client(
      id: data.id.present ? data.id.value : this.id,
      externalId: data.externalId.present
          ? data.externalId.value
          : this.externalId,
      name: data.name.present ? data.name.value : this.name,
      status: data.status.present ? data.status.value : this.status,
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
          ..write('externalId: $externalId, ')
          ..write('name: $name, ')
          ..write('status: $status, ')
          ..write('gender: $gender, ')
          ..write('plan: $plan, ')
          ..write('planStart: $planStart, ')
          ..write('planEnd: $planEnd, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    externalId,
    name,
    status,
    gender,
    plan,
    planStart,
    planEnd,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Client &&
          other.id == this.id &&
          other.externalId == this.externalId &&
          other.name == this.name &&
          other.status == this.status &&
          other.gender == this.gender &&
          other.plan == this.plan &&
          other.planStart == this.planStart &&
          other.planEnd == this.planEnd &&
          other.createdAt == this.createdAt);
}

class ClientsCompanion extends UpdateCompanion<Client> {
  final Value<String> id;
  final Value<String?> externalId;
  final Value<String> name;
  final Value<String> status;
  final Value<String?> gender;
  final Value<String?> plan;
  final Value<DateTime?> planStart;
  final Value<DateTime?> planEnd;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ClientsCompanion({
    this.id = const Value.absent(),
    this.externalId = const Value.absent(),
    this.name = const Value.absent(),
    this.status = const Value.absent(),
    this.gender = const Value.absent(),
    this.plan = const Value.absent(),
    this.planStart = const Value.absent(),
    this.planEnd = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClientsCompanion.insert({
    required String id,
    this.externalId = const Value.absent(),
    required String name,
    this.status = const Value.absent(),
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
    Expression<String>? externalId,
    Expression<String>? name,
    Expression<String>? status,
    Expression<String>? gender,
    Expression<String>? plan,
    Expression<DateTime>? planStart,
    Expression<DateTime>? planEnd,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (externalId != null) 'external_id': externalId,
      if (name != null) 'name': name,
      if (status != null) 'status': status,
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
    Value<String?>? externalId,
    Value<String>? name,
    Value<String>? status,
    Value<String?>? gender,
    Value<String?>? plan,
    Value<DateTime?>? planStart,
    Value<DateTime?>? planEnd,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ClientsCompanion(
      id: id ?? this.id,
      externalId: externalId ?? this.externalId,
      name: name ?? this.name,
      status: status ?? this.status,
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
    if (externalId.present) {
      map['external_id'] = Variable<String>(externalId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
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
          ..write('externalId: $externalId, ')
          ..write('name: $name, ')
          ..write('status: $status, ')
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
  static const VerificationMeta _externalIdMeta = const VerificationMeta(
    'externalId',
  );
  @override
  late final GeneratedColumn<String> externalId = GeneratedColumn<String>(
    'external_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    externalId,
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
    if (data.containsKey('external_id')) {
      context.handle(
        _externalIdMeta,
        externalId.isAcceptableOrUnknown(data['external_id']!, _externalIdMeta),
      );
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
      externalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_id'],
      ),
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
  final String? externalId;
  final String clientId;
  final DateTime performedAt;
  final int planInstance;
  final String gender;
  final int templateIdx;
  const WorkoutSession({
    required this.id,
    this.externalId,
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
    if (!nullToAbsent || externalId != null) {
      map['external_id'] = Variable<String>(externalId);
    }
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
      externalId: externalId == null && nullToAbsent
          ? const Value.absent()
          : Value(externalId),
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
      externalId: serializer.fromJson<String?>(json['externalId']),
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
      'externalId': serializer.toJson<String?>(externalId),
      'clientId': serializer.toJson<String>(clientId),
      'performedAt': serializer.toJson<DateTime>(performedAt),
      'planInstance': serializer.toJson<int>(planInstance),
      'gender': serializer.toJson<String>(gender),
      'templateIdx': serializer.toJson<int>(templateIdx),
    };
  }

  WorkoutSession copyWith({
    int? id,
    Value<String?> externalId = const Value.absent(),
    String? clientId,
    DateTime? performedAt,
    int? planInstance,
    String? gender,
    int? templateIdx,
  }) => WorkoutSession(
    id: id ?? this.id,
    externalId: externalId.present ? externalId.value : this.externalId,
    clientId: clientId ?? this.clientId,
    performedAt: performedAt ?? this.performedAt,
    planInstance: planInstance ?? this.planInstance,
    gender: gender ?? this.gender,
    templateIdx: templateIdx ?? this.templateIdx,
  );
  WorkoutSession copyWithCompanion(WorkoutSessionsCompanion data) {
    return WorkoutSession(
      id: data.id.present ? data.id.value : this.id,
      externalId: data.externalId.present
          ? data.externalId.value
          : this.externalId,
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
          ..write('externalId: $externalId, ')
          ..write('clientId: $clientId, ')
          ..write('performedAt: $performedAt, ')
          ..write('planInstance: $planInstance, ')
          ..write('gender: $gender, ')
          ..write('templateIdx: $templateIdx')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    externalId,
    clientId,
    performedAt,
    planInstance,
    gender,
    templateIdx,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutSession &&
          other.id == this.id &&
          other.externalId == this.externalId &&
          other.clientId == this.clientId &&
          other.performedAt == this.performedAt &&
          other.planInstance == this.planInstance &&
          other.gender == this.gender &&
          other.templateIdx == this.templateIdx);
}

class WorkoutSessionsCompanion extends UpdateCompanion<WorkoutSession> {
  final Value<int> id;
  final Value<String?> externalId;
  final Value<String> clientId;
  final Value<DateTime> performedAt;
  final Value<int> planInstance;
  final Value<String> gender;
  final Value<int> templateIdx;
  const WorkoutSessionsCompanion({
    this.id = const Value.absent(),
    this.externalId = const Value.absent(),
    this.clientId = const Value.absent(),
    this.performedAt = const Value.absent(),
    this.planInstance = const Value.absent(),
    this.gender = const Value.absent(),
    this.templateIdx = const Value.absent(),
  });
  WorkoutSessionsCompanion.insert({
    this.id = const Value.absent(),
    this.externalId = const Value.absent(),
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
    Expression<String>? externalId,
    Expression<String>? clientId,
    Expression<DateTime>? performedAt,
    Expression<int>? planInstance,
    Expression<String>? gender,
    Expression<int>? templateIdx,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (externalId != null) 'external_id': externalId,
      if (clientId != null) 'client_id': clientId,
      if (performedAt != null) 'performed_at': performedAt,
      if (planInstance != null) 'plan_instance': planInstance,
      if (gender != null) 'gender': gender,
      if (templateIdx != null) 'template_idx': templateIdx,
    });
  }

  WorkoutSessionsCompanion copyWith({
    Value<int>? id,
    Value<String?>? externalId,
    Value<String>? clientId,
    Value<DateTime>? performedAt,
    Value<int>? planInstance,
    Value<String>? gender,
    Value<int>? templateIdx,
  }) {
    return WorkoutSessionsCompanion(
      id: id ?? this.id,
      externalId: externalId ?? this.externalId,
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
    if (externalId.present) {
      map['external_id'] = Variable<String>(externalId.value);
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
          ..write('externalId: $externalId, ')
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
  static const VerificationMeta _exerciseIdentityIdMeta =
      const VerificationMeta('exerciseIdentityId');
  @override
  late final GeneratedColumn<int> exerciseIdentityId = GeneratedColumn<int>(
    'exercise_identity_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _exerciseNameSnapshotMeta =
      const VerificationMeta('exerciseNameSnapshot');
  @override
  late final GeneratedColumn<String> exerciseNameSnapshot =
      GeneratedColumn<String>(
        'exercise_name_snapshot',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
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
    exerciseIdentityId,
    exerciseNameSnapshot,
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
    if (data.containsKey('exercise_identity_id')) {
      context.handle(
        _exerciseIdentityIdMeta,
        exerciseIdentityId.isAcceptableOrUnknown(
          data['exercise_identity_id']!,
          _exerciseIdentityIdMeta,
        ),
      );
    }
    if (data.containsKey('exercise_name_snapshot')) {
      context.handle(
        _exerciseNameSnapshotMeta,
        exerciseNameSnapshot.isAcceptableOrUnknown(
          data['exercise_name_snapshot']!,
          _exerciseNameSnapshotMeta,
        ),
      );
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
      exerciseIdentityId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}exercise_identity_id'],
      ),
      exerciseNameSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_name_snapshot'],
      ),
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
  final int? exerciseIdentityId;
  final String? exerciseNameSnapshot;
  final double? lastWeightKg;
  final int? lastReps;
  const WorkoutExerciseResult({
    required this.id,
    required this.sessionId,
    required this.templateExerciseId,
    this.exerciseIdentityId,
    this.exerciseNameSnapshot,
    this.lastWeightKg,
    this.lastReps,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<int>(sessionId);
    map['template_exercise_id'] = Variable<int>(templateExerciseId);
    if (!nullToAbsent || exerciseIdentityId != null) {
      map['exercise_identity_id'] = Variable<int>(exerciseIdentityId);
    }
    if (!nullToAbsent || exerciseNameSnapshot != null) {
      map['exercise_name_snapshot'] = Variable<String>(exerciseNameSnapshot);
    }
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
      exerciseIdentityId: exerciseIdentityId == null && nullToAbsent
          ? const Value.absent()
          : Value(exerciseIdentityId),
      exerciseNameSnapshot: exerciseNameSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(exerciseNameSnapshot),
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
      exerciseIdentityId: serializer.fromJson<int?>(json['exerciseIdentityId']),
      exerciseNameSnapshot: serializer.fromJson<String?>(
        json['exerciseNameSnapshot'],
      ),
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
      'exerciseIdentityId': serializer.toJson<int?>(exerciseIdentityId),
      'exerciseNameSnapshot': serializer.toJson<String?>(exerciseNameSnapshot),
      'lastWeightKg': serializer.toJson<double?>(lastWeightKg),
      'lastReps': serializer.toJson<int?>(lastReps),
    };
  }

  WorkoutExerciseResult copyWith({
    int? id,
    int? sessionId,
    int? templateExerciseId,
    Value<int?> exerciseIdentityId = const Value.absent(),
    Value<String?> exerciseNameSnapshot = const Value.absent(),
    Value<double?> lastWeightKg = const Value.absent(),
    Value<int?> lastReps = const Value.absent(),
  }) => WorkoutExerciseResult(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    templateExerciseId: templateExerciseId ?? this.templateExerciseId,
    exerciseIdentityId: exerciseIdentityId.present
        ? exerciseIdentityId.value
        : this.exerciseIdentityId,
    exerciseNameSnapshot: exerciseNameSnapshot.present
        ? exerciseNameSnapshot.value
        : this.exerciseNameSnapshot,
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
      exerciseIdentityId: data.exerciseIdentityId.present
          ? data.exerciseIdentityId.value
          : this.exerciseIdentityId,
      exerciseNameSnapshot: data.exerciseNameSnapshot.present
          ? data.exerciseNameSnapshot.value
          : this.exerciseNameSnapshot,
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
          ..write('exerciseIdentityId: $exerciseIdentityId, ')
          ..write('exerciseNameSnapshot: $exerciseNameSnapshot, ')
          ..write('lastWeightKg: $lastWeightKg, ')
          ..write('lastReps: $lastReps')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    templateExerciseId,
    exerciseIdentityId,
    exerciseNameSnapshot,
    lastWeightKg,
    lastReps,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutExerciseResult &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.templateExerciseId == this.templateExerciseId &&
          other.exerciseIdentityId == this.exerciseIdentityId &&
          other.exerciseNameSnapshot == this.exerciseNameSnapshot &&
          other.lastWeightKg == this.lastWeightKg &&
          other.lastReps == this.lastReps);
}

class WorkoutExerciseResultsCompanion
    extends UpdateCompanion<WorkoutExerciseResult> {
  final Value<int> id;
  final Value<int> sessionId;
  final Value<int> templateExerciseId;
  final Value<int?> exerciseIdentityId;
  final Value<String?> exerciseNameSnapshot;
  final Value<double?> lastWeightKg;
  final Value<int?> lastReps;
  const WorkoutExerciseResultsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.templateExerciseId = const Value.absent(),
    this.exerciseIdentityId = const Value.absent(),
    this.exerciseNameSnapshot = const Value.absent(),
    this.lastWeightKg = const Value.absent(),
    this.lastReps = const Value.absent(),
  });
  WorkoutExerciseResultsCompanion.insert({
    this.id = const Value.absent(),
    required int sessionId,
    required int templateExerciseId,
    this.exerciseIdentityId = const Value.absent(),
    this.exerciseNameSnapshot = const Value.absent(),
    this.lastWeightKg = const Value.absent(),
    this.lastReps = const Value.absent(),
  }) : sessionId = Value(sessionId),
       templateExerciseId = Value(templateExerciseId);
  static Insertable<WorkoutExerciseResult> custom({
    Expression<int>? id,
    Expression<int>? sessionId,
    Expression<int>? templateExerciseId,
    Expression<int>? exerciseIdentityId,
    Expression<String>? exerciseNameSnapshot,
    Expression<double>? lastWeightKg,
    Expression<int>? lastReps,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (templateExerciseId != null)
        'template_exercise_id': templateExerciseId,
      if (exerciseIdentityId != null)
        'exercise_identity_id': exerciseIdentityId,
      if (exerciseNameSnapshot != null)
        'exercise_name_snapshot': exerciseNameSnapshot,
      if (lastWeightKg != null) 'last_weight_kg': lastWeightKg,
      if (lastReps != null) 'last_reps': lastReps,
    });
  }

  WorkoutExerciseResultsCompanion copyWith({
    Value<int>? id,
    Value<int>? sessionId,
    Value<int>? templateExerciseId,
    Value<int?>? exerciseIdentityId,
    Value<String?>? exerciseNameSnapshot,
    Value<double?>? lastWeightKg,
    Value<int?>? lastReps,
  }) {
    return WorkoutExerciseResultsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      templateExerciseId: templateExerciseId ?? this.templateExerciseId,
      exerciseIdentityId: exerciseIdentityId ?? this.exerciseIdentityId,
      exerciseNameSnapshot: exerciseNameSnapshot ?? this.exerciseNameSnapshot,
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
    if (exerciseIdentityId.present) {
      map['exercise_identity_id'] = Variable<int>(exerciseIdentityId.value);
    }
    if (exerciseNameSnapshot.present) {
      map['exercise_name_snapshot'] = Variable<String>(
        exerciseNameSnapshot.value,
      );
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
          ..write('exerciseIdentityId: $exerciseIdentityId, ')
          ..write('exerciseNameSnapshot: $exerciseNameSnapshot, ')
          ..write('lastWeightKg: $lastWeightKg, ')
          ..write('lastReps: $lastReps')
          ..write(')'))
        .toString();
  }
}

class $WorkoutDraftsTable extends WorkoutDrafts
    with TableInfo<$WorkoutDraftsTable, WorkoutDraft> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutDraftsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<DateTime> day = GeneratedColumn<DateTime>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
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
    requiredDuringInsert: false,
    defaultValue: const Constant(-1),
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
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
    day,
    templateIdx,
    templateExerciseId,
    lastWeightKg,
    lastReps,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_drafts';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkoutDraft> instance, {
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
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('template_idx')) {
      context.handle(
        _templateIdxMeta,
        templateIdx.isAcceptableOrUnknown(
          data['template_idx']!,
          _templateIdxMeta,
        ),
      );
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
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {clientId, day, templateIdx, templateExerciseId},
  ];
  @override
  WorkoutDraft map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutDraft(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}day'],
      )!,
      templateIdx: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}template_idx'],
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
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $WorkoutDraftsTable createAlias(String alias) {
    return $WorkoutDraftsTable(attachedDatabase, alias);
  }
}

class WorkoutDraft extends DataClass implements Insertable<WorkoutDraft> {
  final int id;
  final String clientId;
  final DateTime day;
  final int templateIdx;
  final int templateExerciseId;
  final double? lastWeightKg;
  final int? lastReps;
  final DateTime updatedAt;
  const WorkoutDraft({
    required this.id,
    required this.clientId,
    required this.day,
    required this.templateIdx,
    required this.templateExerciseId,
    this.lastWeightKg,
    this.lastReps,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['client_id'] = Variable<String>(clientId);
    map['day'] = Variable<DateTime>(day);
    map['template_idx'] = Variable<int>(templateIdx);
    map['template_exercise_id'] = Variable<int>(templateExerciseId);
    if (!nullToAbsent || lastWeightKg != null) {
      map['last_weight_kg'] = Variable<double>(lastWeightKg);
    }
    if (!nullToAbsent || lastReps != null) {
      map['last_reps'] = Variable<int>(lastReps);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  WorkoutDraftsCompanion toCompanion(bool nullToAbsent) {
    return WorkoutDraftsCompanion(
      id: Value(id),
      clientId: Value(clientId),
      day: Value(day),
      templateIdx: Value(templateIdx),
      templateExerciseId: Value(templateExerciseId),
      lastWeightKg: lastWeightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(lastWeightKg),
      lastReps: lastReps == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReps),
      updatedAt: Value(updatedAt),
    );
  }

  factory WorkoutDraft.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutDraft(
      id: serializer.fromJson<int>(json['id']),
      clientId: serializer.fromJson<String>(json['clientId']),
      day: serializer.fromJson<DateTime>(json['day']),
      templateIdx: serializer.fromJson<int>(json['templateIdx']),
      templateExerciseId: serializer.fromJson<int>(json['templateExerciseId']),
      lastWeightKg: serializer.fromJson<double?>(json['lastWeightKg']),
      lastReps: serializer.fromJson<int?>(json['lastReps']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'clientId': serializer.toJson<String>(clientId),
      'day': serializer.toJson<DateTime>(day),
      'templateIdx': serializer.toJson<int>(templateIdx),
      'templateExerciseId': serializer.toJson<int>(templateExerciseId),
      'lastWeightKg': serializer.toJson<double?>(lastWeightKg),
      'lastReps': serializer.toJson<int?>(lastReps),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  WorkoutDraft copyWith({
    int? id,
    String? clientId,
    DateTime? day,
    int? templateIdx,
    int? templateExerciseId,
    Value<double?> lastWeightKg = const Value.absent(),
    Value<int?> lastReps = const Value.absent(),
    DateTime? updatedAt,
  }) => WorkoutDraft(
    id: id ?? this.id,
    clientId: clientId ?? this.clientId,
    day: day ?? this.day,
    templateIdx: templateIdx ?? this.templateIdx,
    templateExerciseId: templateExerciseId ?? this.templateExerciseId,
    lastWeightKg: lastWeightKg.present ? lastWeightKg.value : this.lastWeightKg,
    lastReps: lastReps.present ? lastReps.value : this.lastReps,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  WorkoutDraft copyWithCompanion(WorkoutDraftsCompanion data) {
    return WorkoutDraft(
      id: data.id.present ? data.id.value : this.id,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      day: data.day.present ? data.day.value : this.day,
      templateIdx: data.templateIdx.present
          ? data.templateIdx.value
          : this.templateIdx,
      templateExerciseId: data.templateExerciseId.present
          ? data.templateExerciseId.value
          : this.templateExerciseId,
      lastWeightKg: data.lastWeightKg.present
          ? data.lastWeightKg.value
          : this.lastWeightKg,
      lastReps: data.lastReps.present ? data.lastReps.value : this.lastReps,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutDraft(')
          ..write('id: $id, ')
          ..write('clientId: $clientId, ')
          ..write('day: $day, ')
          ..write('templateIdx: $templateIdx, ')
          ..write('templateExerciseId: $templateExerciseId, ')
          ..write('lastWeightKg: $lastWeightKg, ')
          ..write('lastReps: $lastReps, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clientId,
    day,
    templateIdx,
    templateExerciseId,
    lastWeightKg,
    lastReps,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutDraft &&
          other.id == this.id &&
          other.clientId == this.clientId &&
          other.day == this.day &&
          other.templateIdx == this.templateIdx &&
          other.templateExerciseId == this.templateExerciseId &&
          other.lastWeightKg == this.lastWeightKg &&
          other.lastReps == this.lastReps &&
          other.updatedAt == this.updatedAt);
}

class WorkoutDraftsCompanion extends UpdateCompanion<WorkoutDraft> {
  final Value<int> id;
  final Value<String> clientId;
  final Value<DateTime> day;
  final Value<int> templateIdx;
  final Value<int> templateExerciseId;
  final Value<double?> lastWeightKg;
  final Value<int?> lastReps;
  final Value<DateTime> updatedAt;
  const WorkoutDraftsCompanion({
    this.id = const Value.absent(),
    this.clientId = const Value.absent(),
    this.day = const Value.absent(),
    this.templateIdx = const Value.absent(),
    this.templateExerciseId = const Value.absent(),
    this.lastWeightKg = const Value.absent(),
    this.lastReps = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  WorkoutDraftsCompanion.insert({
    this.id = const Value.absent(),
    required String clientId,
    required DateTime day,
    this.templateIdx = const Value.absent(),
    required int templateExerciseId,
    this.lastWeightKg = const Value.absent(),
    this.lastReps = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : clientId = Value(clientId),
       day = Value(day),
       templateExerciseId = Value(templateExerciseId);
  static Insertable<WorkoutDraft> custom({
    Expression<int>? id,
    Expression<String>? clientId,
    Expression<DateTime>? day,
    Expression<int>? templateIdx,
    Expression<int>? templateExerciseId,
    Expression<double>? lastWeightKg,
    Expression<int>? lastReps,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientId != null) 'client_id': clientId,
      if (day != null) 'day': day,
      if (templateIdx != null) 'template_idx': templateIdx,
      if (templateExerciseId != null)
        'template_exercise_id': templateExerciseId,
      if (lastWeightKg != null) 'last_weight_kg': lastWeightKg,
      if (lastReps != null) 'last_reps': lastReps,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  WorkoutDraftsCompanion copyWith({
    Value<int>? id,
    Value<String>? clientId,
    Value<DateTime>? day,
    Value<int>? templateIdx,
    Value<int>? templateExerciseId,
    Value<double?>? lastWeightKg,
    Value<int?>? lastReps,
    Value<DateTime>? updatedAt,
  }) {
    return WorkoutDraftsCompanion(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      day: day ?? this.day,
      templateIdx: templateIdx ?? this.templateIdx,
      templateExerciseId: templateExerciseId ?? this.templateExerciseId,
      lastWeightKg: lastWeightKg ?? this.lastWeightKg,
      lastReps: lastReps ?? this.lastReps,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (day.present) {
      map['day'] = Variable<DateTime>(day.value);
    }
    if (templateIdx.present) {
      map['template_idx'] = Variable<int>(templateIdx.value);
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
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutDraftsCompanion(')
          ..write('id: $id, ')
          ..write('clientId: $clientId, ')
          ..write('day: $day, ')
          ..write('templateIdx: $templateIdx, ')
          ..write('templateExerciseId: $templateExerciseId, ')
          ..write('lastWeightKg: $lastWeightKg, ')
          ..write('lastReps: $lastReps, ')
          ..write('updatedAt: $updatedAt')
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

class $ExerciseIdentitiesTable extends ExerciseIdentities
    with TableInfo<$ExerciseIdentitiesTable, ExerciseIdentity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExerciseIdentitiesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _externalIdMeta = const VerificationMeta(
    'externalId',
  );
  @override
  late final GeneratedColumn<String> externalId = GeneratedColumn<String>(
    'external_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  List<GeneratedColumn> get $columns => [id, externalId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercise_identities';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExerciseIdentity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('external_id')) {
      context.handle(
        _externalIdMeta,
        externalId.isAcceptableOrUnknown(data['external_id']!, _externalIdMeta),
      );
    } else if (isInserting) {
      context.missing(_externalIdMeta);
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
  ExerciseIdentity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExerciseIdentity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      externalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ExerciseIdentitiesTable createAlias(String alias) {
    return $ExerciseIdentitiesTable(attachedDatabase, alias);
  }
}

class ExerciseIdentity extends DataClass
    implements Insertable<ExerciseIdentity> {
  final int id;
  final String externalId;
  final DateTime createdAt;
  const ExerciseIdentity({
    required this.id,
    required this.externalId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['external_id'] = Variable<String>(externalId);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ExerciseIdentitiesCompanion toCompanion(bool nullToAbsent) {
    return ExerciseIdentitiesCompanion(
      id: Value(id),
      externalId: Value(externalId),
      createdAt: Value(createdAt),
    );
  }

  factory ExerciseIdentity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExerciseIdentity(
      id: serializer.fromJson<int>(json['id']),
      externalId: serializer.fromJson<String>(json['externalId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'externalId': serializer.toJson<String>(externalId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ExerciseIdentity copyWith({
    int? id,
    String? externalId,
    DateTime? createdAt,
  }) => ExerciseIdentity(
    id: id ?? this.id,
    externalId: externalId ?? this.externalId,
    createdAt: createdAt ?? this.createdAt,
  );
  ExerciseIdentity copyWithCompanion(ExerciseIdentitiesCompanion data) {
    return ExerciseIdentity(
      id: data.id.present ? data.id.value : this.id,
      externalId: data.externalId.present
          ? data.externalId.value
          : this.externalId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseIdentity(')
          ..write('id: $id, ')
          ..write('externalId: $externalId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, externalId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExerciseIdentity &&
          other.id == this.id &&
          other.externalId == this.externalId &&
          other.createdAt == this.createdAt);
}

class ExerciseIdentitiesCompanion extends UpdateCompanion<ExerciseIdentity> {
  final Value<int> id;
  final Value<String> externalId;
  final Value<DateTime> createdAt;
  const ExerciseIdentitiesCompanion({
    this.id = const Value.absent(),
    this.externalId = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ExerciseIdentitiesCompanion.insert({
    this.id = const Value.absent(),
    required String externalId,
    this.createdAt = const Value.absent(),
  }) : externalId = Value(externalId);
  static Insertable<ExerciseIdentity> custom({
    Expression<int>? id,
    Expression<String>? externalId,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (externalId != null) 'external_id': externalId,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ExerciseIdentitiesCompanion copyWith({
    Value<int>? id,
    Value<String>? externalId,
    Value<DateTime>? createdAt,
  }) {
    return ExerciseIdentitiesCompanion(
      id: id ?? this.id,
      externalId: externalId ?? this.externalId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (externalId.present) {
      map['external_id'] = Variable<String>(externalId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseIdentitiesCompanion(')
          ..write('id: $id, ')
          ..write('externalId: $externalId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ExerciseIdentityBindingsTable extends ExerciseIdentityBindings
    with TableInfo<$ExerciseIdentityBindingsTable, ExerciseIdentityBinding> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExerciseIdentityBindingsTable(this.attachedDatabase, [this._alias]);
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
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceTypeMeta = const VerificationMeta(
    'sourceType',
  );
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
    'source_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<int> sourceId = GeneratedColumn<int>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _identityIdMeta = const VerificationMeta(
    'identityId',
  );
  @override
  late final GeneratedColumn<int> identityId = GeneratedColumn<int>(
    'identity_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isCurrentMeta = const VerificationMeta(
    'isCurrent',
  );
  @override
  late final GeneratedColumn<bool> isCurrent = GeneratedColumn<bool>(
    'is_current',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_current" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
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
  static const VerificationMeta _retiredAtMeta = const VerificationMeta(
    'retiredAt',
  );
  @override
  late final GeneratedColumn<DateTime> retiredAt = GeneratedColumn<DateTime>(
    'retired_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clientId,
    sourceType,
    sourceId,
    identityId,
    isCurrent,
    createdAt,
    retiredAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercise_identity_bindings';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExerciseIdentityBinding> instance, {
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
    }
    if (data.containsKey('source_type')) {
      context.handle(
        _sourceTypeMeta,
        sourceType.isAcceptableOrUnknown(data['source_type']!, _sourceTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceTypeMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('identity_id')) {
      context.handle(
        _identityIdMeta,
        identityId.isAcceptableOrUnknown(data['identity_id']!, _identityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_identityIdMeta);
    }
    if (data.containsKey('is_current')) {
      context.handle(
        _isCurrentMeta,
        isCurrent.isAcceptableOrUnknown(data['is_current']!, _isCurrentMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('retired_at')) {
      context.handle(
        _retiredAtMeta,
        retiredAt.isAcceptableOrUnknown(data['retired_at']!, _retiredAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExerciseIdentityBinding map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExerciseIdentityBinding(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      ),
      sourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_type'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_id'],
      )!,
      identityId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}identity_id'],
      )!,
      isCurrent: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_current'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      retiredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}retired_at'],
      ),
    );
  }

  @override
  $ExerciseIdentityBindingsTable createAlias(String alias) {
    return $ExerciseIdentityBindingsTable(attachedDatabase, alias);
  }
}

class ExerciseIdentityBinding extends DataClass
    implements Insertable<ExerciseIdentityBinding> {
  final int id;
  final String? clientId;
  final String sourceType;
  final int sourceId;
  final int identityId;
  final bool isCurrent;
  final DateTime createdAt;
  final DateTime? retiredAt;
  const ExerciseIdentityBinding({
    required this.id,
    this.clientId,
    required this.sourceType,
    required this.sourceId,
    required this.identityId,
    required this.isCurrent,
    required this.createdAt,
    this.retiredAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || clientId != null) {
      map['client_id'] = Variable<String>(clientId);
    }
    map['source_type'] = Variable<String>(sourceType);
    map['source_id'] = Variable<int>(sourceId);
    map['identity_id'] = Variable<int>(identityId);
    map['is_current'] = Variable<bool>(isCurrent);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || retiredAt != null) {
      map['retired_at'] = Variable<DateTime>(retiredAt);
    }
    return map;
  }

  ExerciseIdentityBindingsCompanion toCompanion(bool nullToAbsent) {
    return ExerciseIdentityBindingsCompanion(
      id: Value(id),
      clientId: clientId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientId),
      sourceType: Value(sourceType),
      sourceId: Value(sourceId),
      identityId: Value(identityId),
      isCurrent: Value(isCurrent),
      createdAt: Value(createdAt),
      retiredAt: retiredAt == null && nullToAbsent
          ? const Value.absent()
          : Value(retiredAt),
    );
  }

  factory ExerciseIdentityBinding.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExerciseIdentityBinding(
      id: serializer.fromJson<int>(json['id']),
      clientId: serializer.fromJson<String?>(json['clientId']),
      sourceType: serializer.fromJson<String>(json['sourceType']),
      sourceId: serializer.fromJson<int>(json['sourceId']),
      identityId: serializer.fromJson<int>(json['identityId']),
      isCurrent: serializer.fromJson<bool>(json['isCurrent']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      retiredAt: serializer.fromJson<DateTime?>(json['retiredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'clientId': serializer.toJson<String?>(clientId),
      'sourceType': serializer.toJson<String>(sourceType),
      'sourceId': serializer.toJson<int>(sourceId),
      'identityId': serializer.toJson<int>(identityId),
      'isCurrent': serializer.toJson<bool>(isCurrent),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'retiredAt': serializer.toJson<DateTime?>(retiredAt),
    };
  }

  ExerciseIdentityBinding copyWith({
    int? id,
    Value<String?> clientId = const Value.absent(),
    String? sourceType,
    int? sourceId,
    int? identityId,
    bool? isCurrent,
    DateTime? createdAt,
    Value<DateTime?> retiredAt = const Value.absent(),
  }) => ExerciseIdentityBinding(
    id: id ?? this.id,
    clientId: clientId.present ? clientId.value : this.clientId,
    sourceType: sourceType ?? this.sourceType,
    sourceId: sourceId ?? this.sourceId,
    identityId: identityId ?? this.identityId,
    isCurrent: isCurrent ?? this.isCurrent,
    createdAt: createdAt ?? this.createdAt,
    retiredAt: retiredAt.present ? retiredAt.value : this.retiredAt,
  );
  ExerciseIdentityBinding copyWithCompanion(
    ExerciseIdentityBindingsCompanion data,
  ) {
    return ExerciseIdentityBinding(
      id: data.id.present ? data.id.value : this.id,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      identityId: data.identityId.present
          ? data.identityId.value
          : this.identityId,
      isCurrent: data.isCurrent.present ? data.isCurrent.value : this.isCurrent,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      retiredAt: data.retiredAt.present ? data.retiredAt.value : this.retiredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseIdentityBinding(')
          ..write('id: $id, ')
          ..write('clientId: $clientId, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceId: $sourceId, ')
          ..write('identityId: $identityId, ')
          ..write('isCurrent: $isCurrent, ')
          ..write('createdAt: $createdAt, ')
          ..write('retiredAt: $retiredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clientId,
    sourceType,
    sourceId,
    identityId,
    isCurrent,
    createdAt,
    retiredAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExerciseIdentityBinding &&
          other.id == this.id &&
          other.clientId == this.clientId &&
          other.sourceType == this.sourceType &&
          other.sourceId == this.sourceId &&
          other.identityId == this.identityId &&
          other.isCurrent == this.isCurrent &&
          other.createdAt == this.createdAt &&
          other.retiredAt == this.retiredAt);
}

class ExerciseIdentityBindingsCompanion
    extends UpdateCompanion<ExerciseIdentityBinding> {
  final Value<int> id;
  final Value<String?> clientId;
  final Value<String> sourceType;
  final Value<int> sourceId;
  final Value<int> identityId;
  final Value<bool> isCurrent;
  final Value<DateTime> createdAt;
  final Value<DateTime?> retiredAt;
  const ExerciseIdentityBindingsCompanion({
    this.id = const Value.absent(),
    this.clientId = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.identityId = const Value.absent(),
    this.isCurrent = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.retiredAt = const Value.absent(),
  });
  ExerciseIdentityBindingsCompanion.insert({
    this.id = const Value.absent(),
    this.clientId = const Value.absent(),
    required String sourceType,
    required int sourceId,
    required int identityId,
    this.isCurrent = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.retiredAt = const Value.absent(),
  }) : sourceType = Value(sourceType),
       sourceId = Value(sourceId),
       identityId = Value(identityId);
  static Insertable<ExerciseIdentityBinding> custom({
    Expression<int>? id,
    Expression<String>? clientId,
    Expression<String>? sourceType,
    Expression<int>? sourceId,
    Expression<int>? identityId,
    Expression<bool>? isCurrent,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? retiredAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientId != null) 'client_id': clientId,
      if (sourceType != null) 'source_type': sourceType,
      if (sourceId != null) 'source_id': sourceId,
      if (identityId != null) 'identity_id': identityId,
      if (isCurrent != null) 'is_current': isCurrent,
      if (createdAt != null) 'created_at': createdAt,
      if (retiredAt != null) 'retired_at': retiredAt,
    });
  }

  ExerciseIdentityBindingsCompanion copyWith({
    Value<int>? id,
    Value<String?>? clientId,
    Value<String>? sourceType,
    Value<int>? sourceId,
    Value<int>? identityId,
    Value<bool>? isCurrent,
    Value<DateTime>? createdAt,
    Value<DateTime?>? retiredAt,
  }) {
    return ExerciseIdentityBindingsCompanion(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      identityId: identityId ?? this.identityId,
      isCurrent: isCurrent ?? this.isCurrent,
      createdAt: createdAt ?? this.createdAt,
      retiredAt: retiredAt ?? this.retiredAt,
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
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<int>(sourceId.value);
    }
    if (identityId.present) {
      map['identity_id'] = Variable<int>(identityId.value);
    }
    if (isCurrent.present) {
      map['is_current'] = Variable<bool>(isCurrent.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (retiredAt.present) {
      map['retired_at'] = Variable<DateTime>(retiredAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseIdentityBindingsCompanion(')
          ..write('id: $id, ')
          ..write('clientId: $clientId, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceId: $sourceId, ')
          ..write('identityId: $identityId, ')
          ..write('isCurrent: $isCurrent, ')
          ..write('createdAt: $createdAt, ')
          ..write('retiredAt: $retiredAt')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _settingKeyMeta = const VerificationMeta(
    'settingKey',
  );
  @override
  late final GeneratedColumn<String> settingKey = GeneratedColumn<String>(
    'setting_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _settingValueMeta = const VerificationMeta(
    'settingValue',
  );
  @override
  late final GeneratedColumn<String> settingValue = GeneratedColumn<String>(
    'setting_value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [settingKey, settingValue];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('setting_key')) {
      context.handle(
        _settingKeyMeta,
        settingKey.isAcceptableOrUnknown(data['setting_key']!, _settingKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_settingKeyMeta);
    }
    if (data.containsKey('setting_value')) {
      context.handle(
        _settingValueMeta,
        settingValue.isAcceptableOrUnknown(
          data['setting_value']!,
          _settingValueMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_settingValueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {settingKey};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      settingKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}setting_key'],
      )!,
      settingValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}setting_value'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String settingKey;
  final String settingValue;
  const AppSetting({required this.settingKey, required this.settingValue});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['setting_key'] = Variable<String>(settingKey);
    map['setting_value'] = Variable<String>(settingValue);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      settingKey: Value(settingKey),
      settingValue: Value(settingValue),
    );
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      settingKey: serializer.fromJson<String>(json['settingKey']),
      settingValue: serializer.fromJson<String>(json['settingValue']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'settingKey': serializer.toJson<String>(settingKey),
      'settingValue': serializer.toJson<String>(settingValue),
    };
  }

  AppSetting copyWith({String? settingKey, String? settingValue}) => AppSetting(
    settingKey: settingKey ?? this.settingKey,
    settingValue: settingValue ?? this.settingValue,
  );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      settingKey: data.settingKey.present
          ? data.settingKey.value
          : this.settingKey,
      settingValue: data.settingValue.present
          ? data.settingValue.value
          : this.settingValue,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('settingKey: $settingKey, ')
          ..write('settingValue: $settingValue')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(settingKey, settingValue);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.settingKey == this.settingKey &&
          other.settingValue == this.settingValue);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> settingKey;
  final Value<String> settingValue;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.settingKey = const Value.absent(),
    this.settingValue = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String settingKey,
    required String settingValue,
    this.rowid = const Value.absent(),
  }) : settingKey = Value(settingKey),
       settingValue = Value(settingValue);
  static Insertable<AppSetting> custom({
    Expression<String>? settingKey,
    Expression<String>? settingValue,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (settingKey != null) 'setting_key': settingKey,
      if (settingValue != null) 'setting_value': settingValue,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? settingKey,
    Value<String>? settingValue,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      settingKey: settingKey ?? this.settingKey,
      settingValue: settingValue ?? this.settingValue,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (settingKey.present) {
      map['setting_key'] = Variable<String>(settingKey.value);
    }
    if (settingValue.present) {
      map['setting_value'] = Variable<String>(settingValue.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('settingKey: $settingKey, ')
          ..write('settingValue: $settingValue, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityExternalIdMeta = const VerificationMeta(
    'entityExternalId',
  );
  @override
  late final GeneratedColumn<String> entityExternalId = GeneratedColumn<String>(
    'entity_external_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(SyncQueueStatuses.pending),
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _lastAttemptAtMeta = const VerificationMeta(
    'lastAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAttemptAt =
      GeneratedColumn<DateTime>(
        'last_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextAttemptAt =
      GeneratedColumn<DateTime>(
        'next_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entityType,
    entityExternalId,
    operation,
    payload,
    status,
    attempts,
    createdAt,
    updatedAt,
    lastAttemptAt,
    nextAttemptAt,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_external_id')) {
      context.handle(
        _entityExternalIdMeta,
        entityExternalId.isAcceptableOrUnknown(
          data['entity_external_id']!,
          _entityExternalIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_entityExternalIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
        _lastAttemptAtMeta,
        lastAttemptAt.isAcceptableOrUnknown(
          data['last_attempt_at']!,
          _lastAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {entityType, entityExternalId, operation},
  ];
  @override
  SyncQueueEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityExternalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_external_id'],
      )!,
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      lastAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_attempt_at'],
      ),
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_attempt_at'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncQueueEntry extends DataClass implements Insertable<SyncQueueEntry> {
  final int id;
  final String entityType;
  final String entityExternalId;
  final String operation;
  final String payload;
  final String status;
  final int attempts;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastAttemptAt;
  final DateTime? nextAttemptAt;
  final String? lastError;
  const SyncQueueEntry({
    required this.id,
    required this.entityType,
    required this.entityExternalId,
    required this.operation,
    required this.payload,
    required this.status,
    required this.attempts,
    required this.createdAt,
    required this.updatedAt,
    this.lastAttemptAt,
    this.nextAttemptAt,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_external_id'] = Variable<String>(entityExternalId);
    map['operation'] = Variable<String>(operation);
    map['payload'] = Variable<String>(payload);
    map['status'] = Variable<String>(status);
    map['attempts'] = Variable<int>(attempts);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt);
    }
    if (!nullToAbsent || nextAttemptAt != null) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      entityType: Value(entityType),
      entityExternalId: Value(entityExternalId),
      operation: Value(operation),
      payload: Value(payload),
      status: Value(status),
      attempts: Value(attempts),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
      nextAttemptAt: nextAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextAttemptAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory SyncQueueEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueEntry(
      id: serializer.fromJson<int>(json['id']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityExternalId: serializer.fromJson<String>(json['entityExternalId']),
      operation: serializer.fromJson<String>(json['operation']),
      payload: serializer.fromJson<String>(json['payload']),
      status: serializer.fromJson<String>(json['status']),
      attempts: serializer.fromJson<int>(json['attempts']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      lastAttemptAt: serializer.fromJson<DateTime?>(json['lastAttemptAt']),
      nextAttemptAt: serializer.fromJson<DateTime?>(json['nextAttemptAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entityType': serializer.toJson<String>(entityType),
      'entityExternalId': serializer.toJson<String>(entityExternalId),
      'operation': serializer.toJson<String>(operation),
      'payload': serializer.toJson<String>(payload),
      'status': serializer.toJson<String>(status),
      'attempts': serializer.toJson<int>(attempts),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'lastAttemptAt': serializer.toJson<DateTime?>(lastAttemptAt),
      'nextAttemptAt': serializer.toJson<DateTime?>(nextAttemptAt),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  SyncQueueEntry copyWith({
    int? id,
    String? entityType,
    String? entityExternalId,
    String? operation,
    String? payload,
    String? status,
    int? attempts,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> lastAttemptAt = const Value.absent(),
    Value<DateTime?> nextAttemptAt = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
  }) => SyncQueueEntry(
    id: id ?? this.id,
    entityType: entityType ?? this.entityType,
    entityExternalId: entityExternalId ?? this.entityExternalId,
    operation: operation ?? this.operation,
    payload: payload ?? this.payload,
    status: status ?? this.status,
    attempts: attempts ?? this.attempts,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    lastAttemptAt: lastAttemptAt.present
        ? lastAttemptAt.value
        : this.lastAttemptAt,
    nextAttemptAt: nextAttemptAt.present
        ? nextAttemptAt.value
        : this.nextAttemptAt,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  SyncQueueEntry copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueEntry(
      id: data.id.present ? data.id.value : this.id,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityExternalId: data.entityExternalId.present
          ? data.entityExternalId.value
          : this.entityExternalId,
      operation: data.operation.present ? data.operation.value : this.operation,
      payload: data.payload.present ? data.payload.value : this.payload,
      status: data.status.present ? data.status.value : this.status,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueEntry(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityExternalId: $entityExternalId, ')
          ..write('operation: $operation, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entityType,
    entityExternalId,
    operation,
    payload,
    status,
    attempts,
    createdAt,
    updatedAt,
    lastAttemptAt,
    nextAttemptAt,
    lastError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueEntry &&
          other.id == this.id &&
          other.entityType == this.entityType &&
          other.entityExternalId == this.entityExternalId &&
          other.operation == this.operation &&
          other.payload == this.payload &&
          other.status == this.status &&
          other.attempts == this.attempts &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.lastAttemptAt == this.lastAttemptAt &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.lastError == this.lastError);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueEntry> {
  final Value<int> id;
  final Value<String> entityType;
  final Value<String> entityExternalId;
  final Value<String> operation;
  final Value<String> payload;
  final Value<String> status;
  final Value<int> attempts;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> lastAttemptAt;
  final Value<DateTime?> nextAttemptAt;
  final Value<String?> lastError;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityExternalId = const Value.absent(),
    this.operation = const Value.absent(),
    this.payload = const Value.absent(),
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    this.id = const Value.absent(),
    required String entityType,
    required String entityExternalId,
    required String operation,
    required String payload,
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
  }) : entityType = Value(entityType),
       entityExternalId = Value(entityExternalId),
       operation = Value(operation),
       payload = Value(payload);
  static Insertable<SyncQueueEntry> custom({
    Expression<int>? id,
    Expression<String>? entityType,
    Expression<String>? entityExternalId,
    Expression<String>? operation,
    Expression<String>? payload,
    Expression<String>? status,
    Expression<int>? attempts,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? lastAttemptAt,
    Expression<DateTime>? nextAttemptAt,
    Expression<String>? lastError,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityType != null) 'entity_type': entityType,
      if (entityExternalId != null) 'entity_external_id': entityExternalId,
      if (operation != null) 'operation': operation,
      if (payload != null) 'payload': payload,
      if (status != null) 'status': status,
      if (attempts != null) 'attempts': attempts,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (lastError != null) 'last_error': lastError,
    });
  }

  SyncQueueCompanion copyWith({
    Value<int>? id,
    Value<String>? entityType,
    Value<String>? entityExternalId,
    Value<String>? operation,
    Value<String>? payload,
    Value<String>? status,
    Value<int>? attempts,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? lastAttemptAt,
    Value<DateTime?>? nextAttemptAt,
    Value<String?>? lastError,
  }) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityExternalId: entityExternalId ?? this.entityExternalId,
      operation: operation ?? this.operation,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      lastError: lastError ?? this.lastError,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityExternalId.present) {
      map['entity_external_id'] = Variable<String>(entityExternalId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityExternalId: $entityExternalId, ')
          ..write('operation: $operation, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }
}

class $SyncLogTable extends SyncLog
    with TableInfo<$SyncLogTable, SyncLogEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncLogTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityExternalIdMeta = const VerificationMeta(
    'entityExternalId',
  );
  @override
  late final GeneratedColumn<String> entityExternalId = GeneratedColumn<String>(
    'entity_external_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resultMeta = const VerificationMeta('result');
  @override
  late final GeneratedColumn<String> result = GeneratedColumn<String>(
    'result',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _httpStatusMeta = const VerificationMeta(
    'httpStatus',
  );
  @override
  late final GeneratedColumn<int> httpStatus = GeneratedColumn<int>(
    'http_status',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _messageMeta = const VerificationMeta(
    'message',
  );
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
    'message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attemptNumberMeta = const VerificationMeta(
    'attemptNumber',
  );
  @override
  late final GeneratedColumn<int> attemptNumber = GeneratedColumn<int>(
    'attempt_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    timestamp,
    entityType,
    entityExternalId,
    result,
    httpStatus,
    message,
    attemptNumber,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncLogEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_external_id')) {
      context.handle(
        _entityExternalIdMeta,
        entityExternalId.isAcceptableOrUnknown(
          data['entity_external_id']!,
          _entityExternalIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_entityExternalIdMeta);
    }
    if (data.containsKey('result')) {
      context.handle(
        _resultMeta,
        result.isAcceptableOrUnknown(data['result']!, _resultMeta),
      );
    } else if (isInserting) {
      context.missing(_resultMeta);
    }
    if (data.containsKey('http_status')) {
      context.handle(
        _httpStatusMeta,
        httpStatus.isAcceptableOrUnknown(data['http_status']!, _httpStatusMeta),
      );
    }
    if (data.containsKey('message')) {
      context.handle(
        _messageMeta,
        message.isAcceptableOrUnknown(data['message']!, _messageMeta),
      );
    }
    if (data.containsKey('attempt_number')) {
      context.handle(
        _attemptNumberMeta,
        attemptNumber.isAcceptableOrUnknown(
          data['attempt_number']!,
          _attemptNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_attemptNumberMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncLogEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncLogEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityExternalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_external_id'],
      )!,
      result: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}result'],
      )!,
      httpStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}http_status'],
      ),
      message: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message'],
      ),
      attemptNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt_number'],
      )!,
    );
  }

  @override
  $SyncLogTable createAlias(String alias) {
    return $SyncLogTable(attachedDatabase, alias);
  }
}

class SyncLogEntry extends DataClass implements Insertable<SyncLogEntry> {
  final int id;
  final DateTime timestamp;
  final String entityType;
  final String entityExternalId;
  final String result;
  final int? httpStatus;
  final String? message;
  final int attemptNumber;
  const SyncLogEntry({
    required this.id,
    required this.timestamp,
    required this.entityType,
    required this.entityExternalId,
    required this.result,
    this.httpStatus,
    this.message,
    required this.attemptNumber,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_external_id'] = Variable<String>(entityExternalId);
    map['result'] = Variable<String>(result);
    if (!nullToAbsent || httpStatus != null) {
      map['http_status'] = Variable<int>(httpStatus);
    }
    if (!nullToAbsent || message != null) {
      map['message'] = Variable<String>(message);
    }
    map['attempt_number'] = Variable<int>(attemptNumber);
    return map;
  }

  SyncLogCompanion toCompanion(bool nullToAbsent) {
    return SyncLogCompanion(
      id: Value(id),
      timestamp: Value(timestamp),
      entityType: Value(entityType),
      entityExternalId: Value(entityExternalId),
      result: Value(result),
      httpStatus: httpStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(httpStatus),
      message: message == null && nullToAbsent
          ? const Value.absent()
          : Value(message),
      attemptNumber: Value(attemptNumber),
    );
  }

  factory SyncLogEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncLogEntry(
      id: serializer.fromJson<int>(json['id']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityExternalId: serializer.fromJson<String>(json['entityExternalId']),
      result: serializer.fromJson<String>(json['result']),
      httpStatus: serializer.fromJson<int?>(json['httpStatus']),
      message: serializer.fromJson<String?>(json['message']),
      attemptNumber: serializer.fromJson<int>(json['attemptNumber']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'entityType': serializer.toJson<String>(entityType),
      'entityExternalId': serializer.toJson<String>(entityExternalId),
      'result': serializer.toJson<String>(result),
      'httpStatus': serializer.toJson<int?>(httpStatus),
      'message': serializer.toJson<String?>(message),
      'attemptNumber': serializer.toJson<int>(attemptNumber),
    };
  }

  SyncLogEntry copyWith({
    int? id,
    DateTime? timestamp,
    String? entityType,
    String? entityExternalId,
    String? result,
    Value<int?> httpStatus = const Value.absent(),
    Value<String?> message = const Value.absent(),
    int? attemptNumber,
  }) => SyncLogEntry(
    id: id ?? this.id,
    timestamp: timestamp ?? this.timestamp,
    entityType: entityType ?? this.entityType,
    entityExternalId: entityExternalId ?? this.entityExternalId,
    result: result ?? this.result,
    httpStatus: httpStatus.present ? httpStatus.value : this.httpStatus,
    message: message.present ? message.value : this.message,
    attemptNumber: attemptNumber ?? this.attemptNumber,
  );
  SyncLogEntry copyWithCompanion(SyncLogCompanion data) {
    return SyncLogEntry(
      id: data.id.present ? data.id.value : this.id,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityExternalId: data.entityExternalId.present
          ? data.entityExternalId.value
          : this.entityExternalId,
      result: data.result.present ? data.result.value : this.result,
      httpStatus: data.httpStatus.present
          ? data.httpStatus.value
          : this.httpStatus,
      message: data.message.present ? data.message.value : this.message,
      attemptNumber: data.attemptNumber.present
          ? data.attemptNumber.value
          : this.attemptNumber,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncLogEntry(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('entityType: $entityType, ')
          ..write('entityExternalId: $entityExternalId, ')
          ..write('result: $result, ')
          ..write('httpStatus: $httpStatus, ')
          ..write('message: $message, ')
          ..write('attemptNumber: $attemptNumber')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    timestamp,
    entityType,
    entityExternalId,
    result,
    httpStatus,
    message,
    attemptNumber,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncLogEntry &&
          other.id == this.id &&
          other.timestamp == this.timestamp &&
          other.entityType == this.entityType &&
          other.entityExternalId == this.entityExternalId &&
          other.result == this.result &&
          other.httpStatus == this.httpStatus &&
          other.message == this.message &&
          other.attemptNumber == this.attemptNumber);
}

class SyncLogCompanion extends UpdateCompanion<SyncLogEntry> {
  final Value<int> id;
  final Value<DateTime> timestamp;
  final Value<String> entityType;
  final Value<String> entityExternalId;
  final Value<String> result;
  final Value<int?> httpStatus;
  final Value<String?> message;
  final Value<int> attemptNumber;
  const SyncLogCompanion({
    this.id = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityExternalId = const Value.absent(),
    this.result = const Value.absent(),
    this.httpStatus = const Value.absent(),
    this.message = const Value.absent(),
    this.attemptNumber = const Value.absent(),
  });
  SyncLogCompanion.insert({
    this.id = const Value.absent(),
    this.timestamp = const Value.absent(),
    required String entityType,
    required String entityExternalId,
    required String result,
    this.httpStatus = const Value.absent(),
    this.message = const Value.absent(),
    required int attemptNumber,
  }) : entityType = Value(entityType),
       entityExternalId = Value(entityExternalId),
       result = Value(result),
       attemptNumber = Value(attemptNumber);
  static Insertable<SyncLogEntry> custom({
    Expression<int>? id,
    Expression<DateTime>? timestamp,
    Expression<String>? entityType,
    Expression<String>? entityExternalId,
    Expression<String>? result,
    Expression<int>? httpStatus,
    Expression<String>? message,
    Expression<int>? attemptNumber,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (timestamp != null) 'timestamp': timestamp,
      if (entityType != null) 'entity_type': entityType,
      if (entityExternalId != null) 'entity_external_id': entityExternalId,
      if (result != null) 'result': result,
      if (httpStatus != null) 'http_status': httpStatus,
      if (message != null) 'message': message,
      if (attemptNumber != null) 'attempt_number': attemptNumber,
    });
  }

  SyncLogCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? timestamp,
    Value<String>? entityType,
    Value<String>? entityExternalId,
    Value<String>? result,
    Value<int?>? httpStatus,
    Value<String?>? message,
    Value<int>? attemptNumber,
  }) {
    return SyncLogCompanion(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      entityType: entityType ?? this.entityType,
      entityExternalId: entityExternalId ?? this.entityExternalId,
      result: result ?? this.result,
      httpStatus: httpStatus ?? this.httpStatus,
      message: message ?? this.message,
      attemptNumber: attemptNumber ?? this.attemptNumber,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityExternalId.present) {
      map['entity_external_id'] = Variable<String>(entityExternalId.value);
    }
    if (result.present) {
      map['result'] = Variable<String>(result.value);
    }
    if (httpStatus.present) {
      map['http_status'] = Variable<int>(httpStatus.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (attemptNumber.present) {
      map['attempt_number'] = Variable<int>(attemptNumber.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncLogCompanion(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('entityType: $entityType, ')
          ..write('entityExternalId: $entityExternalId, ')
          ..write('result: $result, ')
          ..write('httpStatus: $httpStatus, ')
          ..write('message: $message, ')
          ..write('attemptNumber: $attemptNumber')
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
  late final $WorkoutDraftsTable workoutDrafts = $WorkoutDraftsTable(this);
  late final $ClientTemplateExerciseOverridesTable
  clientTemplateExerciseOverrides = $ClientTemplateExerciseOverridesTable(this);
  late final $ExerciseIdentitiesTable exerciseIdentities =
      $ExerciseIdentitiesTable(this);
  late final $ExerciseIdentityBindingsTable exerciseIdentityBindings =
      $ExerciseIdentityBindingsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  late final $SyncLogTable syncLog = $SyncLogTable(this);
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
    workoutDrafts,
    clientTemplateExerciseOverrides,
    exerciseIdentities,
    exerciseIdentityBindings,
    appSettings,
    syncQueue,
    syncLog,
  ];
}

typedef $$ClientsTableCreateCompanionBuilder =
    ClientsCompanion Function({
      required String id,
      Value<String?> externalId,
      required String name,
      Value<String> status,
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
      Value<String?> externalId,
      Value<String> name,
      Value<String> status,
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

  ColumnFilters<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
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

  ColumnOrderings<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
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

  GeneratedColumn<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

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
                Value<String?> externalId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> gender = const Value.absent(),
                Value<String?> plan = const Value.absent(),
                Value<DateTime?> planStart = const Value.absent(),
                Value<DateTime?> planEnd = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClientsCompanion(
                id: id,
                externalId: externalId,
                name: name,
                status: status,
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
                Value<String?> externalId = const Value.absent(),
                required String name,
                Value<String> status = const Value.absent(),
                Value<String?> gender = const Value.absent(),
                Value<String?> plan = const Value.absent(),
                Value<DateTime?> planStart = const Value.absent(),
                Value<DateTime?> planEnd = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClientsCompanion.insert(
                id: id,
                externalId: externalId,
                name: name,
                status: status,
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
      Value<String?> externalId,
      required String clientId,
      required DateTime performedAt,
      required int planInstance,
      required String gender,
      required int templateIdx,
    });
typedef $$WorkoutSessionsTableUpdateCompanionBuilder =
    WorkoutSessionsCompanion Function({
      Value<int> id,
      Value<String?> externalId,
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

  ColumnFilters<String> get externalId => $composableBuilder(
    column: $table.externalId,
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

  ColumnOrderings<String> get externalId => $composableBuilder(
    column: $table.externalId,
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

  GeneratedColumn<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => column,
  );

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
                Value<String?> externalId = const Value.absent(),
                Value<String> clientId = const Value.absent(),
                Value<DateTime> performedAt = const Value.absent(),
                Value<int> planInstance = const Value.absent(),
                Value<String> gender = const Value.absent(),
                Value<int> templateIdx = const Value.absent(),
              }) => WorkoutSessionsCompanion(
                id: id,
                externalId: externalId,
                clientId: clientId,
                performedAt: performedAt,
                planInstance: planInstance,
                gender: gender,
                templateIdx: templateIdx,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> externalId = const Value.absent(),
                required String clientId,
                required DateTime performedAt,
                required int planInstance,
                required String gender,
                required int templateIdx,
              }) => WorkoutSessionsCompanion.insert(
                id: id,
                externalId: externalId,
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
      Value<int?> exerciseIdentityId,
      Value<String?> exerciseNameSnapshot,
      Value<double?> lastWeightKg,
      Value<int?> lastReps,
    });
typedef $$WorkoutExerciseResultsTableUpdateCompanionBuilder =
    WorkoutExerciseResultsCompanion Function({
      Value<int> id,
      Value<int> sessionId,
      Value<int> templateExerciseId,
      Value<int?> exerciseIdentityId,
      Value<String?> exerciseNameSnapshot,
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

  ColumnFilters<int> get exerciseIdentityId => $composableBuilder(
    column: $table.exerciseIdentityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exerciseNameSnapshot => $composableBuilder(
    column: $table.exerciseNameSnapshot,
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

  ColumnOrderings<int> get exerciseIdentityId => $composableBuilder(
    column: $table.exerciseIdentityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exerciseNameSnapshot => $composableBuilder(
    column: $table.exerciseNameSnapshot,
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

  GeneratedColumn<int> get exerciseIdentityId => $composableBuilder(
    column: $table.exerciseIdentityId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get exerciseNameSnapshot => $composableBuilder(
    column: $table.exerciseNameSnapshot,
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
                Value<int?> exerciseIdentityId = const Value.absent(),
                Value<String?> exerciseNameSnapshot = const Value.absent(),
                Value<double?> lastWeightKg = const Value.absent(),
                Value<int?> lastReps = const Value.absent(),
              }) => WorkoutExerciseResultsCompanion(
                id: id,
                sessionId: sessionId,
                templateExerciseId: templateExerciseId,
                exerciseIdentityId: exerciseIdentityId,
                exerciseNameSnapshot: exerciseNameSnapshot,
                lastWeightKg: lastWeightKg,
                lastReps: lastReps,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int sessionId,
                required int templateExerciseId,
                Value<int?> exerciseIdentityId = const Value.absent(),
                Value<String?> exerciseNameSnapshot = const Value.absent(),
                Value<double?> lastWeightKg = const Value.absent(),
                Value<int?> lastReps = const Value.absent(),
              }) => WorkoutExerciseResultsCompanion.insert(
                id: id,
                sessionId: sessionId,
                templateExerciseId: templateExerciseId,
                exerciseIdentityId: exerciseIdentityId,
                exerciseNameSnapshot: exerciseNameSnapshot,
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
typedef $$WorkoutDraftsTableCreateCompanionBuilder =
    WorkoutDraftsCompanion Function({
      Value<int> id,
      required String clientId,
      required DateTime day,
      Value<int> templateIdx,
      required int templateExerciseId,
      Value<double?> lastWeightKg,
      Value<int?> lastReps,
      Value<DateTime> updatedAt,
    });
typedef $$WorkoutDraftsTableUpdateCompanionBuilder =
    WorkoutDraftsCompanion Function({
      Value<int> id,
      Value<String> clientId,
      Value<DateTime> day,
      Value<int> templateIdx,
      Value<int> templateExerciseId,
      Value<double?> lastWeightKg,
      Value<int?> lastReps,
      Value<DateTime> updatedAt,
    });

class $$WorkoutDraftsTableFilterComposer
    extends Composer<_$AppDb, $WorkoutDraftsTable> {
  $$WorkoutDraftsTableFilterComposer({
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

  ColumnFilters<DateTime> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get templateIdx => $composableBuilder(
    column: $table.templateIdx,
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

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WorkoutDraftsTableOrderingComposer
    extends Composer<_$AppDb, $WorkoutDraftsTable> {
  $$WorkoutDraftsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get templateIdx => $composableBuilder(
    column: $table.templateIdx,
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

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorkoutDraftsTableAnnotationComposer
    extends Composer<_$AppDb, $WorkoutDraftsTable> {
  $$WorkoutDraftsTableAnnotationComposer({
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

  GeneratedColumn<DateTime> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<int> get templateIdx => $composableBuilder(
    column: $table.templateIdx,
    builder: (column) => column,
  );

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

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$WorkoutDraftsTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $WorkoutDraftsTable,
          WorkoutDraft,
          $$WorkoutDraftsTableFilterComposer,
          $$WorkoutDraftsTableOrderingComposer,
          $$WorkoutDraftsTableAnnotationComposer,
          $$WorkoutDraftsTableCreateCompanionBuilder,
          $$WorkoutDraftsTableUpdateCompanionBuilder,
          (
            WorkoutDraft,
            BaseReferences<_$AppDb, $WorkoutDraftsTable, WorkoutDraft>,
          ),
          WorkoutDraft,
          PrefetchHooks Function()
        > {
  $$WorkoutDraftsTableTableManager(_$AppDb db, $WorkoutDraftsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutDraftsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutDraftsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutDraftsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> clientId = const Value.absent(),
                Value<DateTime> day = const Value.absent(),
                Value<int> templateIdx = const Value.absent(),
                Value<int> templateExerciseId = const Value.absent(),
                Value<double?> lastWeightKg = const Value.absent(),
                Value<int?> lastReps = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => WorkoutDraftsCompanion(
                id: id,
                clientId: clientId,
                day: day,
                templateIdx: templateIdx,
                templateExerciseId: templateExerciseId,
                lastWeightKg: lastWeightKg,
                lastReps: lastReps,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String clientId,
                required DateTime day,
                Value<int> templateIdx = const Value.absent(),
                required int templateExerciseId,
                Value<double?> lastWeightKg = const Value.absent(),
                Value<int?> lastReps = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => WorkoutDraftsCompanion.insert(
                id: id,
                clientId: clientId,
                day: day,
                templateIdx: templateIdx,
                templateExerciseId: templateExerciseId,
                lastWeightKg: lastWeightKg,
                lastReps: lastReps,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WorkoutDraftsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $WorkoutDraftsTable,
      WorkoutDraft,
      $$WorkoutDraftsTableFilterComposer,
      $$WorkoutDraftsTableOrderingComposer,
      $$WorkoutDraftsTableAnnotationComposer,
      $$WorkoutDraftsTableCreateCompanionBuilder,
      $$WorkoutDraftsTableUpdateCompanionBuilder,
      (
        WorkoutDraft,
        BaseReferences<_$AppDb, $WorkoutDraftsTable, WorkoutDraft>,
      ),
      WorkoutDraft,
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
typedef $$ExerciseIdentitiesTableCreateCompanionBuilder =
    ExerciseIdentitiesCompanion Function({
      Value<int> id,
      required String externalId,
      Value<DateTime> createdAt,
    });
typedef $$ExerciseIdentitiesTableUpdateCompanionBuilder =
    ExerciseIdentitiesCompanion Function({
      Value<int> id,
      Value<String> externalId,
      Value<DateTime> createdAt,
    });

class $$ExerciseIdentitiesTableFilterComposer
    extends Composer<_$AppDb, $ExerciseIdentitiesTable> {
  $$ExerciseIdentitiesTableFilterComposer({
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

  ColumnFilters<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExerciseIdentitiesTableOrderingComposer
    extends Composer<_$AppDb, $ExerciseIdentitiesTable> {
  $$ExerciseIdentitiesTableOrderingComposer({
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

  ColumnOrderings<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExerciseIdentitiesTableAnnotationComposer
    extends Composer<_$AppDb, $ExerciseIdentitiesTable> {
  $$ExerciseIdentitiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ExerciseIdentitiesTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $ExerciseIdentitiesTable,
          ExerciseIdentity,
          $$ExerciseIdentitiesTableFilterComposer,
          $$ExerciseIdentitiesTableOrderingComposer,
          $$ExerciseIdentitiesTableAnnotationComposer,
          $$ExerciseIdentitiesTableCreateCompanionBuilder,
          $$ExerciseIdentitiesTableUpdateCompanionBuilder,
          (
            ExerciseIdentity,
            BaseReferences<_$AppDb, $ExerciseIdentitiesTable, ExerciseIdentity>,
          ),
          ExerciseIdentity,
          PrefetchHooks Function()
        > {
  $$ExerciseIdentitiesTableTableManager(
    _$AppDb db,
    $ExerciseIdentitiesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExerciseIdentitiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExerciseIdentitiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExerciseIdentitiesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> externalId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ExerciseIdentitiesCompanion(
                id: id,
                externalId: externalId,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String externalId,
                Value<DateTime> createdAt = const Value.absent(),
              }) => ExerciseIdentitiesCompanion.insert(
                id: id,
                externalId: externalId,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExerciseIdentitiesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $ExerciseIdentitiesTable,
      ExerciseIdentity,
      $$ExerciseIdentitiesTableFilterComposer,
      $$ExerciseIdentitiesTableOrderingComposer,
      $$ExerciseIdentitiesTableAnnotationComposer,
      $$ExerciseIdentitiesTableCreateCompanionBuilder,
      $$ExerciseIdentitiesTableUpdateCompanionBuilder,
      (
        ExerciseIdentity,
        BaseReferences<_$AppDb, $ExerciseIdentitiesTable, ExerciseIdentity>,
      ),
      ExerciseIdentity,
      PrefetchHooks Function()
    >;
typedef $$ExerciseIdentityBindingsTableCreateCompanionBuilder =
    ExerciseIdentityBindingsCompanion Function({
      Value<int> id,
      Value<String?> clientId,
      required String sourceType,
      required int sourceId,
      required int identityId,
      Value<bool> isCurrent,
      Value<DateTime> createdAt,
      Value<DateTime?> retiredAt,
    });
typedef $$ExerciseIdentityBindingsTableUpdateCompanionBuilder =
    ExerciseIdentityBindingsCompanion Function({
      Value<int> id,
      Value<String?> clientId,
      Value<String> sourceType,
      Value<int> sourceId,
      Value<int> identityId,
      Value<bool> isCurrent,
      Value<DateTime> createdAt,
      Value<DateTime?> retiredAt,
    });

class $$ExerciseIdentityBindingsTableFilterComposer
    extends Composer<_$AppDb, $ExerciseIdentityBindingsTable> {
  $$ExerciseIdentityBindingsTableFilterComposer({
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

  ColumnFilters<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get identityId => $composableBuilder(
    column: $table.identityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCurrent => $composableBuilder(
    column: $table.isCurrent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get retiredAt => $composableBuilder(
    column: $table.retiredAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExerciseIdentityBindingsTableOrderingComposer
    extends Composer<_$AppDb, $ExerciseIdentityBindingsTable> {
  $$ExerciseIdentityBindingsTableOrderingComposer({
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

  ColumnOrderings<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get identityId => $composableBuilder(
    column: $table.identityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCurrent => $composableBuilder(
    column: $table.isCurrent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get retiredAt => $composableBuilder(
    column: $table.retiredAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExerciseIdentityBindingsTableAnnotationComposer
    extends Composer<_$AppDb, $ExerciseIdentityBindingsTable> {
  $$ExerciseIdentityBindingsTableAnnotationComposer({
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

  GeneratedColumn<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<int> get identityId => $composableBuilder(
    column: $table.identityId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCurrent =>
      $composableBuilder(column: $table.isCurrent, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get retiredAt =>
      $composableBuilder(column: $table.retiredAt, builder: (column) => column);
}

class $$ExerciseIdentityBindingsTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $ExerciseIdentityBindingsTable,
          ExerciseIdentityBinding,
          $$ExerciseIdentityBindingsTableFilterComposer,
          $$ExerciseIdentityBindingsTableOrderingComposer,
          $$ExerciseIdentityBindingsTableAnnotationComposer,
          $$ExerciseIdentityBindingsTableCreateCompanionBuilder,
          $$ExerciseIdentityBindingsTableUpdateCompanionBuilder,
          (
            ExerciseIdentityBinding,
            BaseReferences<
              _$AppDb,
              $ExerciseIdentityBindingsTable,
              ExerciseIdentityBinding
            >,
          ),
          ExerciseIdentityBinding,
          PrefetchHooks Function()
        > {
  $$ExerciseIdentityBindingsTableTableManager(
    _$AppDb db,
    $ExerciseIdentityBindingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExerciseIdentityBindingsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ExerciseIdentityBindingsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ExerciseIdentityBindingsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<String> sourceType = const Value.absent(),
                Value<int> sourceId = const Value.absent(),
                Value<int> identityId = const Value.absent(),
                Value<bool> isCurrent = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> retiredAt = const Value.absent(),
              }) => ExerciseIdentityBindingsCompanion(
                id: id,
                clientId: clientId,
                sourceType: sourceType,
                sourceId: sourceId,
                identityId: identityId,
                isCurrent: isCurrent,
                createdAt: createdAt,
                retiredAt: retiredAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                required String sourceType,
                required int sourceId,
                required int identityId,
                Value<bool> isCurrent = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> retiredAt = const Value.absent(),
              }) => ExerciseIdentityBindingsCompanion.insert(
                id: id,
                clientId: clientId,
                sourceType: sourceType,
                sourceId: sourceId,
                identityId: identityId,
                isCurrent: isCurrent,
                createdAt: createdAt,
                retiredAt: retiredAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExerciseIdentityBindingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $ExerciseIdentityBindingsTable,
      ExerciseIdentityBinding,
      $$ExerciseIdentityBindingsTableFilterComposer,
      $$ExerciseIdentityBindingsTableOrderingComposer,
      $$ExerciseIdentityBindingsTableAnnotationComposer,
      $$ExerciseIdentityBindingsTableCreateCompanionBuilder,
      $$ExerciseIdentityBindingsTableUpdateCompanionBuilder,
      (
        ExerciseIdentityBinding,
        BaseReferences<
          _$AppDb,
          $ExerciseIdentityBindingsTable,
          ExerciseIdentityBinding
        >,
      ),
      ExerciseIdentityBinding,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String settingKey,
      required String settingValue,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> settingKey,
      Value<String> settingValue,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDb, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get settingKey => $composableBuilder(
    column: $table.settingKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get settingValue => $composableBuilder(
    column: $table.settingValue,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDb, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get settingKey => $composableBuilder(
    column: $table.settingKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get settingValue => $composableBuilder(
    column: $table.settingValue,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDb, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get settingKey => $composableBuilder(
    column: $table.settingKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get settingValue => $composableBuilder(
    column: $table.settingValue,
    builder: (column) => column,
  );
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (AppSetting, BaseReferences<_$AppDb, $AppSettingsTable, AppSetting>),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDb db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> settingKey = const Value.absent(),
                Value<String> settingValue = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion(
                settingKey: settingKey,
                settingValue: settingValue,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String settingKey,
                required String settingValue,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                settingKey: settingKey,
                settingValue: settingValue,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (AppSetting, BaseReferences<_$AppDb, $AppSettingsTable, AppSetting>),
      AppSetting,
      PrefetchHooks Function()
    >;
typedef $$SyncQueueTableCreateCompanionBuilder =
    SyncQueueCompanion Function({
      Value<int> id,
      required String entityType,
      required String entityExternalId,
      required String operation,
      required String payload,
      Value<String> status,
      Value<int> attempts,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> lastAttemptAt,
      Value<DateTime?> nextAttemptAt,
      Value<String?> lastError,
    });
typedef $$SyncQueueTableUpdateCompanionBuilder =
    SyncQueueCompanion Function({
      Value<int> id,
      Value<String> entityType,
      Value<String> entityExternalId,
      Value<String> operation,
      Value<String> payload,
      Value<String> status,
      Value<int> attempts,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> lastAttemptAt,
      Value<DateTime?> nextAttemptAt,
      Value<String?> lastError,
    });

class $$SyncQueueTableFilterComposer
    extends Composer<_$AppDb, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer({
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

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityExternalId => $composableBuilder(
    column: $table.entityExternalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncQueueTableOrderingComposer
    extends Composer<_$AppDb, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer({
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

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityExternalId => $composableBuilder(
    column: $table.entityExternalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncQueueTableAnnotationComposer
    extends Composer<_$AppDb, $SyncQueueTable> {
  $$SyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityExternalId => $composableBuilder(
    column: $table.entityExternalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$SyncQueueTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $SyncQueueTable,
          SyncQueueEntry,
          $$SyncQueueTableFilterComposer,
          $$SyncQueueTableOrderingComposer,
          $$SyncQueueTableAnnotationComposer,
          $$SyncQueueTableCreateCompanionBuilder,
          $$SyncQueueTableUpdateCompanionBuilder,
          (
            SyncQueueEntry,
            BaseReferences<_$AppDb, $SyncQueueTable, SyncQueueEntry>,
          ),
          SyncQueueEntry,
          PrefetchHooks Function()
        > {
  $$SyncQueueTableTableManager(_$AppDb db, $SyncQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityExternalId = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
              }) => SyncQueueCompanion(
                id: id,
                entityType: entityType,
                entityExternalId: entityExternalId,
                operation: operation,
                payload: payload,
                status: status,
                attempts: attempts,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastAttemptAt: lastAttemptAt,
                nextAttemptAt: nextAttemptAt,
                lastError: lastError,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String entityType,
                required String entityExternalId,
                required String operation,
                required String payload,
                Value<String> status = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
              }) => SyncQueueCompanion.insert(
                id: id,
                entityType: entityType,
                entityExternalId: entityExternalId,
                operation: operation,
                payload: payload,
                status: status,
                attempts: attempts,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastAttemptAt: lastAttemptAt,
                nextAttemptAt: nextAttemptAt,
                lastError: lastError,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $SyncQueueTable,
      SyncQueueEntry,
      $$SyncQueueTableFilterComposer,
      $$SyncQueueTableOrderingComposer,
      $$SyncQueueTableAnnotationComposer,
      $$SyncQueueTableCreateCompanionBuilder,
      $$SyncQueueTableUpdateCompanionBuilder,
      (
        SyncQueueEntry,
        BaseReferences<_$AppDb, $SyncQueueTable, SyncQueueEntry>,
      ),
      SyncQueueEntry,
      PrefetchHooks Function()
    >;
typedef $$SyncLogTableCreateCompanionBuilder =
    SyncLogCompanion Function({
      Value<int> id,
      Value<DateTime> timestamp,
      required String entityType,
      required String entityExternalId,
      required String result,
      Value<int?> httpStatus,
      Value<String?> message,
      required int attemptNumber,
    });
typedef $$SyncLogTableUpdateCompanionBuilder =
    SyncLogCompanion Function({
      Value<int> id,
      Value<DateTime> timestamp,
      Value<String> entityType,
      Value<String> entityExternalId,
      Value<String> result,
      Value<int?> httpStatus,
      Value<String?> message,
      Value<int> attemptNumber,
    });

class $$SyncLogTableFilterComposer extends Composer<_$AppDb, $SyncLogTable> {
  $$SyncLogTableFilterComposer({
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

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityExternalId => $composableBuilder(
    column: $table.entityExternalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get result => $composableBuilder(
    column: $table.result,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get httpStatus => $composableBuilder(
    column: $table.httpStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attemptNumber => $composableBuilder(
    column: $table.attemptNumber,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncLogTableOrderingComposer extends Composer<_$AppDb, $SyncLogTable> {
  $$SyncLogTableOrderingComposer({
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

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityExternalId => $composableBuilder(
    column: $table.entityExternalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get result => $composableBuilder(
    column: $table.result,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get httpStatus => $composableBuilder(
    column: $table.httpStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attemptNumber => $composableBuilder(
    column: $table.attemptNumber,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncLogTableAnnotationComposer
    extends Composer<_$AppDb, $SyncLogTable> {
  $$SyncLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityExternalId => $composableBuilder(
    column: $table.entityExternalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get result =>
      $composableBuilder(column: $table.result, builder: (column) => column);

  GeneratedColumn<int> get httpStatus => $composableBuilder(
    column: $table.httpStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<int> get attemptNumber => $composableBuilder(
    column: $table.attemptNumber,
    builder: (column) => column,
  );
}

class $$SyncLogTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $SyncLogTable,
          SyncLogEntry,
          $$SyncLogTableFilterComposer,
          $$SyncLogTableOrderingComposer,
          $$SyncLogTableAnnotationComposer,
          $$SyncLogTableCreateCompanionBuilder,
          $$SyncLogTableUpdateCompanionBuilder,
          (SyncLogEntry, BaseReferences<_$AppDb, $SyncLogTable, SyncLogEntry>),
          SyncLogEntry,
          PrefetchHooks Function()
        > {
  $$SyncLogTableTableManager(_$AppDb db, $SyncLogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityExternalId = const Value.absent(),
                Value<String> result = const Value.absent(),
                Value<int?> httpStatus = const Value.absent(),
                Value<String?> message = const Value.absent(),
                Value<int> attemptNumber = const Value.absent(),
              }) => SyncLogCompanion(
                id: id,
                timestamp: timestamp,
                entityType: entityType,
                entityExternalId: entityExternalId,
                result: result,
                httpStatus: httpStatus,
                message: message,
                attemptNumber: attemptNumber,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                required String entityType,
                required String entityExternalId,
                required String result,
                Value<int?> httpStatus = const Value.absent(),
                Value<String?> message = const Value.absent(),
                required int attemptNumber,
              }) => SyncLogCompanion.insert(
                id: id,
                timestamp: timestamp,
                entityType: entityType,
                entityExternalId: entityExternalId,
                result: result,
                httpStatus: httpStatus,
                message: message,
                attemptNumber: attemptNumber,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncLogTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $SyncLogTable,
      SyncLogEntry,
      $$SyncLogTableFilterComposer,
      $$SyncLogTableOrderingComposer,
      $$SyncLogTableAnnotationComposer,
      $$SyncLogTableCreateCompanionBuilder,
      $$SyncLogTableUpdateCompanionBuilder,
      (SyncLogEntry, BaseReferences<_$AppDb, $SyncLogTable, SyncLogEntry>),
      SyncLogEntry,
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
  $$WorkoutDraftsTableTableManager get workoutDrafts =>
      $$WorkoutDraftsTableTableManager(_db, _db.workoutDrafts);
  $$ClientTemplateExerciseOverridesTableTableManager
  get clientTemplateExerciseOverrides =>
      $$ClientTemplateExerciseOverridesTableTableManager(
        _db,
        _db.clientTemplateExerciseOverrides,
      );
  $$ExerciseIdentitiesTableTableManager get exerciseIdentities =>
      $$ExerciseIdentitiesTableTableManager(_db, _db.exerciseIdentities);
  $$ExerciseIdentityBindingsTableTableManager get exerciseIdentityBindings =>
      $$ExerciseIdentityBindingsTableTableManager(
        _db,
        _db.exerciseIdentityBindings,
      );
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
  $$SyncLogTableTableManager get syncLog =>
      $$SyncLogTableTableManager(_db, _db.syncLog);
}
