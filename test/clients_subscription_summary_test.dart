import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myfitness/app/app_db_scope.dart';
import 'package:myfitness/db/app_db.dart';
import 'package:myfitness/features/clients/client_subscription_status.dart';
import 'package:myfitness/features/clients/clients_screen.dart';

void main() {
  test('subscription status keeps the client card boundary rules', () {
    final now = DateTime(2026, 8, 5, 23, 45);

    expect(
      resolveClientSubscriptionStatus(null, now: now),
      ClientSubscriptionStatus.noDate,
    );
    expect(
      resolveClientSubscriptionStatus(DateTime(2026, 8, 4), now: now),
      ClientSubscriptionStatus.expired,
    );
    expect(
      resolveClientSubscriptionStatus(DateTime(2026, 8, 5), now: now),
      ClientSubscriptionStatus.expiringSoon,
    );
    expect(
      resolveClientSubscriptionStatus(DateTime(2026, 8, 8), now: now),
      ClientSubscriptionStatus.expiringSoon,
    );
    expect(
      resolveClientSubscriptionStatus(DateTime(2026, 8, 9), now: now),
      ClientSubscriptionStatus.active,
    );
  });

  testWidgets(
    'summary counts active clients only and is independent from search',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final db = AppDb.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final today = DateTime.now();
      final activeEnd = today.add(const Duration(days: 10));
      final expiredEnd = today.subtract(const Duration(days: 1));

      await _saveClient(
        db,
        id: 'active-male',
        name: 'Иван',
        gender: 'М',
        planEnd: activeEnd,
      );
      await _saveClient(
        db,
        id: 'expired-female',
        name: 'Анна',
        gender: 'Ж',
        planEnd: expiredEnd,
      );
      await _saveClient(
        db,
        id: 'soon-female',
        name: 'Вера',
        gender: 'Ж',
        planEnd: today.add(const Duration(days: 2)),
      );
      await _saveClient(
        db,
        id: 'without-date-male',
        name: 'Максим',
        gender: 'М',
      );
      await _saveClient(
        db,
        id: 'archived-active',
        name: 'Архивный',
        gender: 'М',
        planEnd: activeEnd,
        status: AppDb.archivedClientStatus,
      );

      await _pumpClientsScreen(tester, db, revision: 0);
      _expectSummary(total: 4, male: 2, female: 2, active: 1, expired: 1);
      expect(find.text('Архивный'), findsNothing);

      await tester.enterText(find.byType(TextField), 'Нет такого клиента');
      await tester.pump();
      expect(find.textContaining('ничего не найдено'), findsOneWidget);
      _expectSummary(total: 4, male: 2, female: 2, active: 1, expired: 1);

      await _saveClient(
        db,
        id: 'new-active-female',
        name: 'Новая',
        gender: 'Ж',
        planEnd: activeEnd,
      );
      await _pumpClientsScreen(tester, db, revision: 1);
      _expectSummary(total: 5, male: 2, female: 3, active: 2, expired: 1);

      await db.archiveClient('expired-female');
      await _pumpClientsScreen(tester, db, revision: 2);
      _expectSummary(total: 4, male: 2, female: 2, active: 2, expired: 0);

      await db.restoreClient('expired-female');
      await _pumpClientsScreen(tester, db, revision: 3);
      _expectSummary(total: 5, male: 2, female: 3, active: 2, expired: 1);
    },
  );
}

Future<void> _saveClient(
  AppDb db, {
  required String id,
  required String name,
  required String gender,
  DateTime? planEnd,
  String status = AppDb.activeClientStatus,
}) {
  return db.upsertClient(
    ClientsCompanion.insert(
      id: id,
      name: name,
      gender: Value(gender),
      planEnd: Value(planEnd),
      status: Value(status),
    ),
  );
}

Future<void> _pumpClientsScreen(
  WidgetTester tester,
  AppDb db, {
  required int revision,
}) async {
  await tester.pumpWidget(
    AppDbScope(
      db: db,
      child: MaterialApp(home: ClientsScreen(key: ValueKey(revision))),
    ),
  );
  await tester.pumpAndSettle();
}

void _expectSummary({
  required int total,
  required int male,
  required int female,
  required int active,
  required int expired,
}) {
  expect(find.text('Всего: $total'), findsOneWidget);
  expect(find.text('М: $male'), findsOneWidget);
  expect(find.text('Ж: $female'), findsOneWidget);
  expect(find.text('Активные: $active'), findsOneWidget);
  expect(find.text('Истёкшие: $expired'), findsOneWidget);
}
