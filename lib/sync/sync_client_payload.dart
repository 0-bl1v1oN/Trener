class SyncClientPayload {
  const SyncClientPayload({
    required this.clientExternalId,
    this.name,
    this.gender,
    this.subscriptionSize,
    this.subscriptionStart,
    this.subscriptionEnd,
    this.remainingSessions,
  });

  factory SyncClientPayload.fromJson(Map<dynamic, dynamic> json) {
    final externalId = json['client_id'] ?? json['uuid'];
    if (externalId is! String || externalId.trim().isEmpty) {
      throw const FormatException(
        'В sync client payload отсутствует client_id',
      );
    }
    return SyncClientPayload(
      clientExternalId: externalId.trim(),
      name: _nonEmpty(json['name']),
      gender: _nonEmpty(json['gender']),
      subscriptionSize: (json['subscription_size'] as num?)?.toInt(),
      subscriptionStart: _nonEmpty(json['subscription_start']),
      subscriptionEnd: _nonEmpty(json['subscription_end']),
      remainingSessions: (json['remaining_sessions'] as num?)?.toInt(),
    );
  }

  final String clientExternalId;
  final String? name;
  final String? gender;
  final int? subscriptionSize;
  final String? subscriptionStart;
  final String? subscriptionEnd;
  final int? remainingSessions;

  Map<String, dynamic> toJson() => {
    'client_id': clientExternalId,
    if (name != null) 'name': name,
    if (gender != null) 'gender': gender,
    if (subscriptionSize != null) 'subscription_size': subscriptionSize,
    if (subscriptionStart != null) 'subscription_start': subscriptionStart,
    if (subscriptionEnd != null) 'subscription_end': subscriptionEnd,
    if (remainingSessions != null) 'remaining_sessions': remainingSessions,
  };
}

String syncDateOnly(DateTime value) {
  final local = value.toLocal();
  String twoDigits(int part) => part.toString().padLeft(2, '0');
  return '${local.year}-${twoDigits(local.month)}-${twoDigits(local.day)}';
}

String? _nonEmpty(Object? value) {
  if (value is! String) return null;
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}
