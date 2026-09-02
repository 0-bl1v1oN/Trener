import 'dart:convert';

class ScheduleSyncAppointment {
  const ScheduleSyncAppointment({required this.date, required this.time});

  factory ScheduleSyncAppointment.fromStartAt(DateTime startAt) {
    final local = startAt.toLocal();
    return ScheduleSyncAppointment(
      date: _dateOnly(local),
      time: _timeOnly(local),
    );
  }

  final String date;
  final String time;

  Map<String, dynamic> toJson() => {'date': date, 'time': time};
}

class ScheduleSyncPayload {
  const ScheduleSyncPayload({
    required this.clientExternalId,
    required this.from,
    required this.to,
    required this.appointments,
  });

  factory ScheduleSyncPayload.fromRange({
    required String clientExternalId,
    required DateTime fromInclusive,
    required DateTime toExclusive,
    required List<DateTime> appointmentStarts,
  }) {
    final lastDay = DateTime(
      toExclusive.year,
      toExclusive.month,
      toExclusive.day - 1,
    );
    return ScheduleSyncPayload(
      clientExternalId: clientExternalId,
      from: _dateOnly(fromInclusive),
      to: _dateOnly(lastDay),
      appointments: [
        for (final startAt in appointmentStarts)
          ScheduleSyncAppointment.fromStartAt(startAt),
      ],
    );
  }

  factory ScheduleSyncPayload.fromJson(Map<String, dynamic> json) {
    final client = json['client'];
    final schedule = json['schedule'];
    if (client is! Map || schedule is! Map) {
      throw const FormatException('Некорректный schedule sync payload');
    }
    final rawAppointments = schedule['appointments'];
    if (rawAppointments is! List) {
      throw const FormatException('Некорректный список schedule appointments');
    }
    return ScheduleSyncPayload(
      clientExternalId: client['client_id'] as String,
      from: schedule['from'] as String,
      to: schedule['to'] as String,
      appointments: [
        for (final raw in rawAppointments)
          if (raw is Map)
            ScheduleSyncAppointment(
              date: raw['date'] as String,
              time: raw['time'] as String,
            )
          else
            throw const FormatException(
              'Некорректная запись schedule appointment',
            ),
      ],
    );
  }

  final String clientExternalId;
  final String from;
  final String to;
  final List<ScheduleSyncAppointment> appointments;

  Map<String, dynamic> toJson() => {
    'type': 'schedule',
    'client': {'client_id': clientExternalId},
    'schedule': {
      'from': from,
      'to': to,
      'appointments': [for (final item in appointments) item.toJson()],
    },
  };

  String encode() => jsonEncode(toJson());
}

String _dateOnly(DateTime value) {
  final local = value.toLocal();
  String twoDigits(int part) => part.toString().padLeft(2, '0');
  return '${local.year}-${twoDigits(local.month)}-${twoDigits(local.day)}';
}

String _timeOnly(DateTime value) {
  String twoDigits(int part) => part.toString().padLeft(2, '0');
  return '${twoDigits(value.hour)}:${twoDigits(value.minute)}';
}
