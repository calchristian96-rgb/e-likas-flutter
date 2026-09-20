import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/localization/app_locale.dart';
import '../core/localization/app_theme_mode.dart';
import '../core/localization/framework_localizations_fallback.dart';
import '../core/widgets/dev_mode_banner.dart';
import '../l10n/app_localizations.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

/// Root widget. Resident-facing, no login — this is the entire auth
/// surface of the app (there isn't one).
class ElikasApp extends ConsumerWidget {
  const ElikasApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watched, not read: changing the selected language updates this
    // one `locale` argument, which cascades a rebuild through every
    // `AppLocalizations.of(context)` call in the tree on the same
    // frame — no app restart, and GoRouter's own state (current route,
    // navigation stack) lives outside this widget entirely, so it's
    // untouched by the rebuild.
    final locale = ref.watch(appLocaleProvider);
    final themeMode = ref.watch(appThemeModeProvider);

    return MaterialApp.router(
      title: 'E-LIKAS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: supportedAppLocales,
      // Not AppLocalizations.localizationsDelegates directly — that
      // list includes the raw Global*Localizations delegates, which
      // don't support `bcl` (Bikol isn't in Flutter's own translation
      // catalog) and crash Material widgets like RefreshIndicator with
      // "No MaterialLocalizations found" when selected. The Fallback*
      // wrappers delegate to those same Global ones for every locale
      // they actually support (en, fil — unchanged behavior) and only
      // substitute English for locales they don't. AppLocalizations
      // .delegate itself is unaffected and keeps resolving `bcl` from
      // app_bcl.arb.
      localizationsDelegates: [
        AppLocalizations.delegate,
        const FallbackMaterialLocalizationsDelegate(),
        const FallbackCupertinoLocalizationsDelegate(),
        const FallbackWidgetsLocalizationsDelegate(),
      ],
      routerConfig: appRouter,
      builder: (context, child) =>
          DevModeBanner(child: child ?? const SizedBox.shrink()),
    );
  }
}
