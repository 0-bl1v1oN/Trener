import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../features/calendar/calendar_screen.dart';
import '../features/clients/clients_screen.dart';
import '../features/clients/client_detail_screen.dart';
import '../features/clients/client_program_screen.dart';
import '../features/workouts/workout_screen.dart';
import '../features/programs/defalut_programs_screen.dart';
import '../features/more/more_screen.dart';
import '../features/more/income_screen.dart';
import '../features/more/records_screen.dart';
import '../features/more/contests_screen.dart';

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
            colorScheme:
                ColorScheme.fromSeed(
                  seedColor: const Color(0xFF8D7CFF),
                  brightness: Brightness.dark,
                ).copyWith(
                  surface: const Color(0xFF1B1D2A),
                  surfaceContainerHighest: const Color(0xFF2A2D3E),
                  outlineVariant: const Color(0xFF3A3D52),
                ),
            scaffoldBackgroundColor: const Color(0xFF141623),
            canvasColor: const Color(0xFF141623),
            cardColor: const Color(0xFF1B1D2A),
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
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/more',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: MoreScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/calendar',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: CalendarScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
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
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/programs',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: DefaultProgramsScreen()),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      parentNavigatorKey: _rootNavKey,
      path: '/workout',
      builder: (context, state) {
        final clientId = state.uri.queryParameters['clientId']!;
        final dayStr = state.uri.queryParameters['day']!; // yyyy-MM-dd
        final day = DateTime.parse(dayStr);
        return WorkoutScreen(clientId: clientId, day: day);
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavKey,
      path: '/income',
      builder: (context, state) => const IncomeScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavKey,
      path: '/records',
      builder: (context, state) => const RecordsScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavKey,
      path: '/contests',
      builder: (context, state) => const ContestsScreen(),
    ),
  ],
);

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTap,
        destinations: const [
          NavigationDestination(
            icon: _NavPngIcon(
              assetPath: 'assets/nav/menu.png',
              fallback: Icons.menu_rounded,
              size: 30,
            ),
            label: 'Меню',
          ),
          NavigationDestination(
            icon: _NavPngIcon(
              assetPath: 'assets/nav/calendar.png',
              fallback: Icons.calendar_month,
            ),
            label: 'Календарь',
          ),
          NavigationDestination(
            icon: _NavPngIcon(
              assetPath: 'assets/nav/clients.png',
              fallback: Icons.people,
            ),
            label: 'Клиенты',
          ),
          NavigationDestination(
            icon: _NavPngIcon(
              assetPath: 'assets/nav/program.png',
              fallback: Icons.fitness_center,
            ),
            label: 'Программа',
          ),
        ],
      ),
    );
  }
}

class _NavPngIcon extends StatelessWidget {
  const _NavPngIcon({
    required this.assetPath,
    required this.fallback,
    this.size = 24,
  });

  final String assetPath;
  final IconData fallback;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(fallback, size: size),
    );
  }
}
