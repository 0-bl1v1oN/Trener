import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'app/app_db_scope.dart';
import 'app/app_error_reporter.dart';
import 'db/app_db.dart';
import 'sync/sync_service.dart';
import 'sync/sync_transport.dart';
import 'theme_controller.dart';

Future<void> main() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        AppErrorReporter.record(
          details.exception,
          details.stack ?? StackTrace.current,
          source: 'FlutterError',
        );
      };

      PlatformDispatcher.instance.onError = (error, stackTrace) {
        AppErrorReporter.record(
          error,
          stackTrace,
          source: 'PlatformDispatcher',
        );
        return false;
      };

      await Firebase.initializeApp();
      await initializeDateFormatting('ru_RU', null);
      await themeController.loadTheme();

      runApp(const AppBootstrap());
    },
    (error, stackTrace) {
      AppErrorReporter.record(error, stackTrace, source: 'runZonedGuarded');
    },
  );
}

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  static Future<void> restart(BuildContext context) async {
    final state = context.findAncestorStateOfType<_AppBootstrapState>();
    assert(state != null, 'AppBootstrap not found');
    await state?.restartApp();
  }

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  Key _appKey = UniqueKey();
  late AppDb _db;
  late SyncService _syncService;

  @override
  void initState() {
    super.initState();
    _createRuntime();
  }

  void _createRuntime() {
    _db = AppDb();
    _syncService = SyncService.shared(
      db: _db,
      transport: HttpSyncTransport.fromEnvironment(),
    );
    _db.configureAutomaticSyncTrigger(_syncService.triggerAutomatic);
  }

  Future<void> restartApp() async {
    await _db.close();
    if (!mounted) return;

    setState(() {
      _createRuntime();
      _appKey = UniqueKey();
    });
  }

  @override
  void dispose() {
    _db.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _appKey,
      child: AppDbScope(db: _db, child: const MyFitnessApp()),
    );
  }
}
