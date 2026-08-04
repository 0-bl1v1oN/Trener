enum ClientSubscriptionStatus { active, expiringSoon, expired, noDate }

ClientSubscriptionStatus resolveClientSubscriptionStatus(
  DateTime? planEnd, {
  DateTime? now,
}) {
  if (planEnd == null) return ClientSubscriptionStatus.noDate;

  final current = now ?? DateTime.now();
  final endDate = DateTime(planEnd.year, planEnd.month, planEnd.day);
  final today = DateTime(current.year, current.month, current.day);
  final daysLeft = endDate.difference(today).inDays;

  if (daysLeft < 0) return ClientSubscriptionStatus.expired;
  if (daysLeft <= 3) return ClientSubscriptionStatus.expiringSoon;
  return ClientSubscriptionStatus.active;
}

extension ClientSubscriptionStatusUi on ClientSubscriptionStatus {
  String get label => switch (this) {
    ClientSubscriptionStatus.active => 'Активен',
    ClientSubscriptionStatus.expiringSoon => 'Скоро конец',
    ClientSubscriptionStatus.expired => 'Истёк',
    ClientSubscriptionStatus.noDate => 'Без даты',
  };
}
