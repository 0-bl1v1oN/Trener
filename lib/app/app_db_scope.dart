import 'package:flutter/material.dart';
import '../db/app_db.dart';

class AppDbScope extends InheritedWidget {
  const AppDbScope({super.key, required this.db, required super.child});

  final AppDb db;

  static AppDb of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppDbScope>();
    assert(scope != null, 'AppDbScope not found in widget tree');
    return scope!.db;
  }

  @override
  bool updateShouldNotify(AppDbScope oldWidget) => db != oldWidget.db;
}
