import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myfitness/app/app_db_scope.dart';
import 'package:myfitness/db/app_db.dart';
import 'package:myfitness/features/more/service_data_screen.dart';

void main() {
  testWidgets('service screen shows client UUID without changing it', (
    tester,
  ) async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (_) async => null,
    );
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final db = AppDb.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.upsertClient(
      ClientsCompanion.insert(
        id: 'service-client',
        name: 'Клиент для UUID',
        gender: const Value('М'),
      ),
    );
    final originalUuid = (await db.getClientById(
      'service-client',
    ))!.externalId!;

    await tester.pumpWidget(
      AppDbScope(
        db: db,
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: const ServiceDataScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('UUID тренера'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Клиент для UUID').last);
    await tester.pumpAndSettle();

    expect(find.text(originalUuid), findsOneWidget);
    expect(
      (await db.getClientById('service-client'))!.externalId,
      originalUuid,
    );

    final clientCopyButton = find.ancestor(
      of: find.text('Копировать').last,
      matching: find.byWidgetPredicate((widget) => widget is FilledButton),
    );
    expect(clientCopyButton, findsOneWidget);
    await tester.ensureVisible(clientCopyButton);
    await tester.tap(clientCopyButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('UUID скопирован'), findsOneWidget);
  });
}
