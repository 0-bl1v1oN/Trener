import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

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

class MyFitnessApp extends StatefulWidget {
  const MyFitnessApp({super.key});

  @override
  State<MyFitnessApp> createState() => _MyFitnessAppState();
}

class _MyFitnessAppState extends State<MyFitnessApp> {
  bool _backgroundWarmedUp = false;
  bool _nativeSplashRemoved = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_backgroundWarmedUp) return;
    _warmUpCalendarBackground();
  }

  Future<void> _warmUpCalendarBackground() async {
    final startedAt = DateTime.now();
    const minSplashDuration = Duration(milliseconds: 900);

    try {
      await precacheImage(
        const AssetImage('assets/calendar/calendar_bg_boy.jpg'),
        context,
      );
    } catch (_) {
      // Если ассет не прогрелся, продолжаем запуск без блокировки.
    }

    final elapsed = DateTime.now().difference(startedAt);
    final waitMore = minSplashDuration - elapsed;
    if (waitMore > Duration.zero) {
      await Future.delayed(waitMore);
    }

    if (!mounted) return;
    setState(() {
      _backgroundWarmedUp = true;
    });

    if (!_nativeSplashRemoved) {
      _nativeSplashRemoved = true;
      FlutterNativeSplash.remove();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeController,
      builder: (context, mode, _) {
        if (!_backgroundWarmedUp) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: _StartupWarmupScreen(),
          );
        }
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

class _StartupWarmupScreen extends StatefulWidget {
  const _StartupWarmupScreen();

  @override
  State<_StartupWarmupScreen> createState() => _StartupWarmupScreenState();
}

class _StartupWarmupScreenState extends State<_StartupWarmupScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = Tween<double>(
      begin: 0.96,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    final opacity = Tween<double>(
      begin: 0.88,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFFF4F5FA)),
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Opacity(
            opacity: opacity.value,
            child: Transform.scale(
              scale: scale.value,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/branding/splash_hero.jpg',
                    width: 220,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Image.asset(
                      'assets/branding/splash_icon.png',
                      width: 170,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      valueColor: AlwaysStoppedAnimation(Color(0xFF7C4DFF)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final _rootNavKey = GlobalKey<NavigatorState>();

final GoRouter _router = GoRouter(
  navigatorKey: _rootNavKey,
  initialLocation: '/calendar',
  routes: [
    StatefulShellRoute(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      navigatorContainerBuilder: (context, navigationShell, children) =>
          _AnimatedBranchContainer(
            currentIndex: navigationShell.currentIndex,
            children: children,
          ),
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

class _AnimatedBranchContainer extends StatefulWidget {
  const _AnimatedBranchContainer({
    required this.currentIndex,
    required this.children,
  });

  final int currentIndex;
  final List<Widget> children;

  @override
  State<_AnimatedBranchContainer> createState() =>
      _AnimatedBranchContainerState();
}

class _AnimatedBranchContainerState extends State<_AnimatedBranchContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late int _fromIndex;
  late int _toIndex;

  @override
  void initState() {
    super.initState();
    _fromIndex = widget.currentIndex;
    _toIndex = widget.currentIndex;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      value: 1,
    );
  }

  @override
  void didUpdateWidget(covariant _AnimatedBranchContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex == _toIndex) return;

    _fromIndex = _toIndex;
    _toIndex = widget.currentIndex;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeInOutCubic.transform(_controller.value);

        return Stack(
          children: [
            for (var i = 0; i < widget.children.length; i++)
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: i != _toIndex,
                  child: TickerMode(
                    enabled: i == _toIndex,
                    child: Opacity(
                      opacity: i == _toIndex
                          ? t
                          : i == _fromIndex
                          ? 1 - t
                          : 0,
                      child: widget.children[i],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
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
