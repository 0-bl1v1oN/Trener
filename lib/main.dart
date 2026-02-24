import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'app/app.dart';
import 'app/app_db_scope.dart';
import 'db/app_db.dart';
import 'theme_controller.dart';

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await initializeDateFormatting('ru_RU', null);
  await themeController.loadTheme();

  final db = AppDb();

  runApp(AppDbScope(db: db, child: const MyFitnessApp()));
}
