import 'package:flutter/material.dart';

class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController() : super(ThemeMode.light);

  void toggle() {
    value = (value == ThemeMode.dark) ? ThemeMode.light : ThemeMode.dark;
  }
}

final themeController = ThemeController();
