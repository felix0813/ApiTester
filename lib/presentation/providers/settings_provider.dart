import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local/local_database.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.light) {
    _load();
  }

  Future<void> _load() async {
    final box = LocalDatabase.settings;
    final saved = box.get('themeMode', defaultValue: 'light') ?? 'light';
    state = ThemeMode.values.firstWhere(
      (e) => e.name == saved,
      orElse: () => ThemeMode.light,
    );
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    await LocalDatabase.settings.put('themeMode', mode.name);
  }
}
