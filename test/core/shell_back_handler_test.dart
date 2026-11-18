import 'package:elikas_mobile/core/widgets/shell_back_handler.dart';
import 'package:elikas_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Android back in a tabbed shell: a detail page goes back to where it
/// was opened from; a tab's first screen goes to Home; Home asks once
/// before the app closes.
GoRouter _router() => GoRouter(
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => ShellBackHandler(
        navigationShell: shell,
        homeBranch: 0,
        child: Scaffold(body: shell),
      ),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => Scaffold(
                body: Column(
                  children: [
                    const Text('Home screen'),
                    TextButton(
                      onPressed: () => context.push('/detail'),
                      child: const Text('Open detail'),
                    ),
                    TextButton(
                      onPressed: () => context.go('/alerts'),
                      child: const Text('Open alerts'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/alerts',
              builder: (context, state) =>
                  const Scaffold(body: Text('Alerts screen')),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/detail',
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Detail screen')),
      ),
    ),
  ],
);

Future<void> _back(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

void main() {
  late GoRouter router;

  Future<void> pump(WidgetTester tester) async {
    router = _router();
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a detail page has a back arrow and goes back to Home', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('Open detail'));
    await tester.pumpAndSettle();
    expect(find.text('Detail screen'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
    await _back(tester);
    expect(find.text('Home screen'), findsOneWidget);
  });

  testWidgets('another tab goes back to Home, not out of the app', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('Open alerts'));
    await tester.pumpAndSettle();
    expect(find.text('Alerts screen'), findsOneWidget);
    await _back(tester);
    expect(find.text('Home screen'), findsOneWidget);
  });

  testWidgets('on Home, the first back asks before closing', (tester) async {
    await pump(tester);
    await _back(tester);
    expect(find.text('Press back again to exit'), findsOneWidget);
    expect(find.text('Home screen'), findsOneWidget);
  });
}
