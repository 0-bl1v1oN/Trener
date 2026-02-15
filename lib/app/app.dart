import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../features/calendar/calendar_screen.dart';
import '../features/clients/clients_screen.dart';
import '../features/clients/client_detail_screen.dart';
import '../features/clients/client_program_screen.dart';
import '../features/workouts/workout_screen.dart';
import '../features/programs/defalut_programs_screen.dart'

import '../theme_controller.dart';

class MyFitnessApp extends StatelessWidget {
  const MyFitnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeController,
      builder: (context, mode, _) {
        return MaterialApp.router(
          title: 'MyFitness',

          // ✅ темы
          themeMode: mode,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorSchemeSeed: const Color(0xFF7C4DFF), // можно менять под “неон”
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorSchemeSeed: const Color(0xFF7C4DFF),
          ),

          // --- только русский интерфейс ---
          supportedLocales: const [Locale('ru', 'RU')],
          locale: const Locale('ru', 'RU'),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          // -------------------------------
          routerConfig: _router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

final _rootNavKey = GlobalKey<NavigatorState>();

final GoRouter _router = GoRouter(
  navigatorKey: _rootNavKey,
  initialLocation: '/calendar',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/calendar',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: CalendarScreen()),
        ),

        // ✅ ДОБАВЬ ЭТО
        GoRoute(
          path: '/workout',
          builder: (context, state) {
            final clientId = state.uri.queryParameters['clientId']!;
            final dayStr = state.uri.queryParameters['day']!; // yyyy-MM-dd
            final day = DateTime.parse(dayStr);
            return WorkoutScreen(clientId: clientId, day: day);
          },
        ),

        GoRoute(
          path: '/clients',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ClientsScreen()),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return ClientDetailScreen(clientId: id);
              },
            ),
            GoRoute(
              path: ':id/program',
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                final dayStr = state.uri.queryParameters['day'];
                final day = dayStr == null ? null : DateTime.parse(dayStr);
                return ClientProgramScreen(clientId: id, day: day);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/programs',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: DefaultProgramsScreen()),
        ),
      ],
    ),
  ],
);

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  int _locationToIndex(String location) {
    if (location.startsWith('/clients')) return 1;
    if (location.startsWith('/programs')) return 2;
    return 0; // /calendar
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/calendar');
        break;
      case 1:
        context.go('/clients');
        break;
      case 2:
        context.go('/programs');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _locationToIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) => _onTap(context, i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_month),
            label: 'Календарь',
          ),
          NavigationDestination(icon: Icon(Icons.people), label: 'Клиенты'),
          NavigationDestination(
            icon: Icon(Icons.fitness_center),
            label: 'Программа',
          ),
        ],
      ),
    );
  }
}
