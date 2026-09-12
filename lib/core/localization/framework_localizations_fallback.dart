import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Bikol (Ligao) — `bcl` — has no translations in Flutter's own
/// Material/Widgets/Cupertino localization catalogs: verified against
/// the installed Flutter SDK, `bcl` appears in none of
/// `flutter_localizations`' generated language lists. Selecting it as
/// the app `locale` makes `GlobalMaterialLocalizations.delegate
/// .isSupported(locale)` return false, so the `Localizations` widget
/// never calls `.load()` for it and no `MaterialLocalizations`
/// instance gets registered — the "No MaterialLocalizations found"
/// crash reported for `RefreshIndicator`/`NavigationBar`.
///
/// These three delegates wrap the real Global ones and substitute
/// English *only* for Flutter's own framework-owned strings (button
/// labels, date-picker chrome, refresh-indicator semantics) when the
/// selected locale isn't one Flutter ships translations for. E-LIKAS's
/// own [AppLocalizations] delegate is untouched by this file and keeps
/// resolving `bcl` from `app_bcl.arb` as before — this only patches
/// the framework layer underneath it.
///
/// For any locale Flutter *does* support natively (`en`, `fil` as of
/// this SDK) `isSupported`/`load` behave identically to the wrapped
/// delegate — this is a no-op passthrough, not a hardcoded override.
const Locale _frameworkFallbackLocale = Locale('en');

class FallbackMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const FallbackMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    final resolved = GlobalMaterialLocalizations.delegate.isSupported(locale)
        ? locale
        : _frameworkFallbackLocale;
    return GlobalMaterialLocalizations.delegate.load(resolved);
  }

  @override
  bool shouldReload(FallbackMaterialLocalizationsDelegate old) => false;
}

class FallbackCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const FallbackCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) {
    final resolved = GlobalCupertinoLocalizations.delegate.isSupported(locale)
        ? locale
        : _frameworkFallbackLocale;
    return GlobalCupertinoLocalizations.delegate.load(resolved);
  }

  @override
  bool shouldReload(FallbackCupertinoLocalizationsDelegate old) => false;
}

class FallbackWidgetsLocalizationsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const FallbackWidgetsLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<WidgetsLocalizations> load(Locale locale) {
    final resolved = GlobalWidgetsLocalizations.delegate.isSupported(locale)
        ? locale
        : _frameworkFallbackLocale;
    return GlobalWidgetsLocalizations.delegate.load(resolved);
  }

  @override
  bool shouldReload(FallbackWidgetsLocalizationsDelegate old) => false;
}
