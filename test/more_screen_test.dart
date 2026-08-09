import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:myfitness/features/more/more_screen.dart';

void main() {
  testWidgets('menu uses a two-column card grid and keeps navigation', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 1200);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final router = GoRouter(
      initialLocation: '/more',
      routes: [
        GoRoute(path: '/more', builder: (_, __) => const MoreScreen()),
        GoRoute(
          path: '/income',
          builder: (_, __) => const Scaffold(body: Text('Доход открыт')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(theme: ThemeData.dark(), routerConfig: router),
    );
    await tester.pumpAndSettle();

    expect(find.text('Меню'), findsOneWidget);
    expect(find.text('Выберите раздел'), findsOneWidget);
    expect(find.byType(SliverGrid), findsOneWidget);
    for (final title in [
      'Категории',
      'Конкурсы',
      'Прогресс',
      'Синхронизация',
      'Экспорт / Импорт',
      'Доход',
      'Рекорды',
    ]) {
      expect(find.text(title), findsOneWidget);
    }

    await tester.tap(find.text('Доход'));
    await tester.pumpAndSettle();
    expect(find.text('Доход открыт'), findsOneWidget);
  });
}
