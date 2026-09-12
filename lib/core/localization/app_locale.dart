import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';

part 'app_locale.g.dart';

/// The three languages E-LIKAS ships with. English and Filipino carry
/// real translations throughout; the Bikol (Ligao) ARB file
/// (`lib/l10n/app_bcl.arb`) exists as real localization structure but
/// currently holds the English text for every key — no Ligao-specific
/// wording has been supplied and reviewed yet, so nothing is guessed.
/// Each key that's safety/emergency-adjacent is flagged in that ARB
/// file's own `@key` description as "PENDING Bikol (Ligao)
/// local-language review" for whoever picks that work up later.
const supportedAppLocales = <Locale>[
  Locale('en'),
  Locale('fil'),
  Locale('bcl'),
];

const defaultAppLocale = Locale('en');

/// The same fixed display names [showLanguageSelectorSheet] uses,
/// exposed for the Settings row that shows the *current* choice
/// without opening the sheet — one source of names for both.
String appLocaleDisplayName(AppLocalizations l10n, Locale locale) {
  return switch (locale.languageCode) {
    'fil' => l10n.languageFilipino,
    'bcl' => l10n.languageBikolLigao,
    _ => l10n.languageEnglish,
  };
}

const _localePrefsKey = 'elikas.locale';

/// The resident's selected app language. Backed by [SharedPreferences]
/// — the one piece of local key-value storage this app needs; nothing
/// else here touches Isar (which stays reserved for the offline data
/// cache) or the backend.
@riverpod
class AppLocale extends _$AppLocale {
  @override
  Locale build() => defaultAppLocale;

  /// Reads the persisted choice, if any. Called once during splash
  /// (alongside the existing Isar warm-up) so Home never has to flash
  /// English before switching to a previously-chosen language.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_localePrefsKey);
    if (code == null) return;
    final match = supportedAppLocales.where((l) => l.languageCode == code);
    if (match.isNotEmpty) state = match.first;
  }

  /// Applies [locale] immediately (every widget watching this provider
  /// rebuilds with the new language on this same frame — no app
  /// restart, no lost navigation stack, no provider re-fetching since
  /// nothing data-related depends on this state) and persists it for
  /// next launch.
  Future<void> setLocale(Locale locale) async {
    if (!supportedAppLocales.contains(locale)) return;
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localePrefsKey, locale.languageCode);
  }
}
