import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';

part 'app_theme_mode.g.dart';

const _themeModePrefsKey = 'elikas.themeMode';

String appThemeModeDisplayName(AppLocalizations l10n, ThemeMode mode) {
  return switch (mode) {
    ThemeMode.system => l10n.appearanceSystem,
    ThemeMode.light => l10n.appearanceLight,
    ThemeMode.dark => l10n.appearanceDark,
  };
}

/// The resident's chosen appearance — System (default), Light, or Dark.
/// [ElikasApp] already wires both a light and a dark [ThemeData] (see
/// `app_theme.dart`); this only controls which one `MaterialApp.router`
/// picks, via its standard `themeMode` parameter — no new theming work,
/// just exposing the switch. Persisted the same way as [AppLocale]: a
/// dedicated [SharedPreferences] key, applied immediately on change
/// (every widget rebuilds with the new theme on the same frame, no
/// restart), loaded once during splash alongside the locale and Isar
/// warm-up.
@riverpod
class AppThemeModeNotifier extends _$AppThemeModeNotifier {
  @override
  ThemeMode build() => ThemeMode.system;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_themeModePrefsKey);
    if (name == null) return;
    state = ThemeMode.values.firstWhere(
      (mode) => mode.name == name,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModePrefsKey, mode.name);
  }
}
