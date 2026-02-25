import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'app/app_db_scope.dart';
import 'db/app_db.dart';
import 'theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru_RU', null);
  await themeController.loadTheme();

  runApp(const AppBootstrap());
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
  AppDb _db = AppDb();

  Future<void> restartApp() async {
    await _db.close();
    if (!mounted) return;

    setState(() {
      _db = AppDb();
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
