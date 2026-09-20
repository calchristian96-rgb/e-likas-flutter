import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/connectivity/connectivity_service.dart';
import '../../core/widgets/error_state.dart';
import '../../features/alerts/domain/entities/alert.dart';
import '../../features/alerts/presentation/pages/alert_details_page.dart';
import '../../features/alerts/presentation/pages/alerts_page.dart';
import '../../features/alerts/presentation/providers/alerts_summary_provider.dart';
import '../../features/alerts/presentation/widgets/alert_type_display.dart';
import '../../features/ec_board/presentation/pages/ec_board_page.dart';
import '../../features/ec_board/presentation/pages/pending_ec_entry_detail_page.dart';
import '../../features/emergency_hotlines/presentation/pages/emergency_hotlines_page.dart';
import '../../features/evacuation_centers/presentation/pages/evacuation_center_details_page.dart';
import '../../features/evacuation_centers/presentation/pages/evacuation_centers_list_page.dart';
import '../../features/evacuation_centers/presentation/pages/nearest_center_page.dart';
import '../../features/evacuation_centers/presentation/providers/evacuation_centers_provider.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/home/presentation/providers/home_provider.dart';
import '../../features/map/presentation/pages/evacuation_map_page.dart';
import '../../features/map/presentation/providers/map_provider.dart';
import '../../features/family_registration/presentation/pages/family_registration_form_page.dart';
import '../../features/family_registration/presentation/pages/pending_registration_detail_page.dart';
import '../../features/family_registration/presentation/pages/pending_registrations_page.dart';
import '../../features/registered_families/presentation/pages/registered_families_page.dart';
import '../../features/settings/presentation/pages/dev_settings_page.dart';
import '../../features/settings/presentation/pages/offline_data_management_page.dart';
import '../../features/staff_evacuation_centers/presentation/pages/evacuation_center_form_page.dart';
import '../../features/staff_evacuation_centers/presentation/pages/staff_evacuation_center_detail_page.dart';
import '../../features/staff_evacuation_centers/presentation/pages/staff_evacuation_centers_list_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/staff_auth/presentation/pages/staff_login_page.dart';
import '../../features/staff_workspace/presentation/pages/staff_workspace_page.dart';
import '../../l10n/app_localizations.dart';
import '../splash/splash_page.dart';

/// Bottom-nav shell shared by the four top-level destinations. Uses
/// [StatefulShellRoute.indexedStack] so each tab keeps its own
/// navigation stack and scroll position when switching tabs.
///
/// Also the single, always-mounted home for two session-wide concerns
/// that have no natural per-screen owner: periodic alert polling (see
/// [_AppShellState._startPolling]) and the new-alert banner it can
/// trigger. Living here — rather than on [HomePage] or [AlertsListPage]
/// — means switching tabs can never spin up a second timer or duplicate
/// the "have we already announced this alert" tracking, since this
/// widget is created once per app session and never rebuilt by
/// navigation.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  static const _pollInterval = Duration(seconds: 60);

  Timer? _pollTimer;

  /// Whether this session has resolved the alerts summary at least
  /// once yet. The *first* resolution just establishes which alert is
  /// already "known" — it must never itself trigger the new-alert
  /// banner, or every normal app open would misreport its most recent
  /// existing alert (possibly from Isar, possibly hours old) as brand
  /// new.
  bool _seededLastSeenAlert = false;
  int? _lastSeenAlertId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // Coming back to the foreground is exactly when a resident is
        // most likely to actually look at the screen, so it's worth an
        // immediate refresh rather than waiting up to 60s for the next
        // tick. The connectivity refresh matters just as much here:
        // the cached reachability result (or the last interface-change
        // event) could be many minutes stale after a real background
        // period, and no interface-change event necessarily fires just
        // because the app came back to the foreground.
        ref.read(connectivityServiceProvider).refreshNow();
        _refreshAlertsNow();
        _startPolling();
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _stopPolling();
    }
  }

  void _startPolling() {
    // Cancels any existing timer first — called both from initState
    // and from every "resumed" transition, so this guards against ever
    // running two timers at once regardless of how many times the app
    // is backgrounded and re-foregrounded.
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _refreshAlertsNow());
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Alerts are the one thing polled on a timer — GIS/nearest-center/
  /// the full centers list are comparatively heavy and change far less
  /// often, so they're refreshed only via pull-to-refresh, the existing
  /// Quick Actions "Refresh Data" action, or once on connectivity
  /// restoration (see [_handleConnectivityChange]).
  void _refreshAlertsNow() {
    ref.invalidate(alertsSummaryProvider);
    ref.invalidate(alertsListProvider);
  }

  void _handleAlertsSummaryChange(
    AsyncValue<({Alert? latest, int count})>? previous,
    AsyncValue<({Alert? latest, int count})> next,
  ) {
    final summary = next.value;
    if (summary == null) return; // still loading, or this fetch failed
    final latest = summary.latest;

    if (!_seededLastSeenAlert) {
      _seededLastSeenAlert = true;
      _lastSeenAlertId = latest?.id;
      return;
    }

    if (latest != null && latest.id != _lastSeenAlertId) {
      _lastSeenAlertId = latest.id;
      _showNewAlertBanner(latest);
    }
  }

  void _handleConnectivityChange(
    AsyncValue<bool>? previous,
    AsyncValue<bool> next,
  ) {
    final wasOffline = previous?.value == false;
    final isOnlineNow = next.value == true;
    if (!wasOffline || !isOnlineNow) return;

    // One refresh on the offline→online transition, not a loop: this
    // fires exactly once per transition because it's driven by
    // ref.listen's previous/next comparison, not a timer.
    ref.invalidate(allEvacuationCentersProvider);
    ref.invalidate(alertsSummaryProvider);
    ref.invalidate(alertsListProvider);
    ref.invalidate(mapDataProvider);
  }

  void _showNewAlertBanner(Alert alert) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    // Replaces rather than stacks: if a resident hasn't dismissed the
    // last banner yet and another new alert arrives, the newer one
    // should win rather than queuing behind the old one.
    messenger.hideCurrentMaterialBanner();

    final color = alertDisplayColor(context, alert.alertType, alert.severity);
    final icon = alertDisplayIcon(alert.alertType, alert.severity);

    messenger.showMaterialBanner(
      MaterialBanner(
        backgroundColor: color.withValues(alpha: 0.08),
        leading: Icon(icon, color: color),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _newAlertHeadline(alert.severity, l10n),
              style: TextStyle(fontWeight: FontWeight.w700, color: color),
            ),
            const SizedBox(height: 2),
            Text(alert.title, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => messenger.hideCurrentMaterialBanner(),
            child: Text(l10n.dismiss),
          ),
          TextButton(
            onPressed: () {
              messenger.hideCurrentMaterialBanner();
              GoRouter.of(context).push('/alerts/${alert.id}');
            },
            child: Text(l10n.view),
          ),
        ],
      ),
    );
  }

  /// Matches the already-established severity mapping
  /// (mandatory/advisory/info/all_clear) — falls back to a neutral
  /// phrase for older cached alerts with no severity, the same
  /// fallback [alertDisplayColor]/[alertDisplayIcon] already use.
  static String _newAlertHeadline(String? severity, AppLocalizations l10n) {
    return switch (severity) {
      'mandatory' => l10n.emergencyAlertReceived,
      'advisory' => l10n.newAdvisoryReceived,
      'info' => l10n.newInformationAlert,
      'all_clear' => l10n.allClearUpdateReceived,
      _ => l10n.newAlertReceived,
    };
  }

  @override
  Widget build(BuildContext context) {
    // ref.listen, not ref.watch: this widget doesn't need to rebuild
    // when alerts or connectivity change, it only needs to react once
    // per actual change — exactly what listen is for.
    ref.listen(alertsSummaryProvider, _handleAlertsSummaryChange);
    ref.listen(connectivityStatusProvider, _handleConnectivityChange);

    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: widget.navigationShell,
      // A subtle top border + shadow on the nav surface itself, layered
      // on top of NavigationBarTheme's brand colors/indicator pill
      // (see AppTheme) — purely cosmetic, the destinations/routing
      // below are untouched.
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(top: BorderSide(color: theme.colorScheme.outline)),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: widget.navigationShell.currentIndex,
          onDestinationSelected: widget.navigationShell.goBranch,
          // Not const any more: labels now come from AppLocalizations,
          // which varies by the resident's selected language.
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: l10n.navHome,
            ),
            NavigationDestination(
              icon: const Icon(Icons.notifications_outlined),
              selectedIcon: const Icon(Icons.notifications),
              label: l10n.navAlerts,
            ),
            NavigationDestination(
              icon: const Icon(Icons.map_outlined),
              selectedIcon: const Icon(Icons.map),
              label: l10n.navMap,
            ),
            NavigationDestination(
              icon: const Icon(Icons.phone_in_talk_outlined),
              selectedIcon: const Icon(Icons.phone_in_talk),
              label: l10n.navHotlines,
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings),
              label: l10n.navSettings,
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown when `/alerts/:id` or `/centers/:id` is reached with an id
/// that isn't a number. Reuses the app's existing [ErrorState] rather
/// than inventing a second error look for a case this rare.
class _InvalidLinkPage extends StatelessWidget {
  const _InvalidLinkPage({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ErrorState(message: message),
        ),
      ),
    );
  }
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    // Outside the shell, same as /centers below — the bottom nav has
    // nothing to show yet at this point, and this route is never
    // returned to once left (SplashPage navigates with context.go,
    // which replaces rather than pushes).
    GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/alerts',
              builder: (context, state) => const AlertsListPage(),
              // Nested inside the Alerts branch rather than declared as
              // a top-level route like /centers, so opening an alert
              // pushes onto the Alerts tab's own stack — the bottom nav
              // stays visible, back returns to the list, and switching
              // tabs and coming back leaves the details screen open
              // where the resident left it. That's the whole reason
              // this shell uses indexedStack branches.
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) {
                    final id = int.tryParse(state.pathParameters['id'] ?? '');
                    // Unreachable from in-app navigation, which always
                    // pushes a real int id — but a deep link or a typed
                    // URL can put anything here, and int.parse would
                    // throw inside a builder rather than show anything
                    // useful.
                    if (id == null) {
                      final l10n = AppLocalizations.of(context);
                      return _InvalidLinkPage(
                        title: l10n.alertDetailsTitle,
                        message: l10n.invalidAlertLink,
                      );
                    }
                    return AlertDetailsPage(alertId: id);
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/map',
              builder: (context, state) => const EvacuationMapPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            // Promoted from a plain top-level route into its own branch
            // now that Hotlines is a permanent bottom-nav destination
            // (previously reached only from a Home Quick Action).
            GoRoute(
              path: '/emergency-hotlines',
              builder: (context, state) => const EmergencyHotlinesPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            // Settings is now a permanent bottom-nav destination too
            // (previously reached only from a Home Quick Action, which
            // has been removed since it would now duplicate this tab).
            // The whole existing subtree — Offline Data Management and
            // the entire Staff Access module — nests under it exactly
            // as before, so back navigation and every existing deep
            // path (e.g. `/settings/staff/register-family`) keep
            // working unchanged.
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsPage(),
              routes: [
                GoRoute(
                  path: 'offline-data',
                  builder: (context, state) =>
                      const OfflineDataManagementPage(),
                ),
                // Hidden developer screen for the persistent
                // local/staging backend override — reached only via
                // the tap sequence on Settings' "E-LIKAS" about row,
                // never linked anywhere else. DevSettingsPage's own
                // build() refuses to render anything in a release
                // build regardless of how this route was reached.
                GoRoute(
                  path: 'dev',
                  builder: (context, state) => const DevSettingsPage(),
                ),
                // Barangay Staff Access subtree — additive, no
                // interaction with the resident routes/branches above.
                // Everything past `staff/login` is gated by
                // StaffAuthGuard inside each page itself rather than a
                // router-level redirect (see that widget's doc
                // comment for why), so a logged-out resident who
                // somehow lands on e.g. `staff/workspace` sees the
                // login screen in place of it rather than the
                // workspace content.
                GoRoute(
                  path: 'staff',
                  builder: (context, state) => const StaffWorkspacePage(),
                  routes: [
                    GoRoute(
                      path: 'login',
                      builder: (context, state) => const StaffLoginPage(),
                    ),
                    GoRoute(
                      path: 'register-family',
                      builder: (context, state) =>
                          const FamilyRegistrationFormPage(),
                    ),
                    GoRoute(
                      path: 'pending-registrations',
                      builder: (context, state) =>
                          const PendingRegistrationsPage(),
                      routes: [
                        GoRoute(
                          path: ':localId',
                          builder: (context, state) =>
                              PendingRegistrationDetailPage(
                                localId: state.pathParameters['localId']!,
                              ),
                        ),
                      ],
                    ),
                    GoRoute(
                      path: 'all-evacuees',
                      builder: (context, state) =>
                          const RegisteredFamiliesPage(),
                    ),
                    // Staff evacuation-center management (Part 2) —
                    // Edit is reached via Navigator.push from the
                    // detail page rather than a named route here,
                    // same pattern PendingRegistrationDetailPage uses
                    // for its own edit flow (it needs the already-
                    // fetched center object, not a re-fetch keyed by
                    // a route param).
                    GoRoute(
                      path: 'evacuation-centers',
                      builder: (context, state) =>
                          const StaffEvacuationCentersListPage(),
                      routes: [
                        GoRoute(
                          path: 'add',
                          builder: (context, state) =>
                              const EvacuationCenterFormPage(),
                        ),
                        GoRoute(
                          path: ':id',
                          builder: (context, state) {
                            final id = int.tryParse(
                              state.pathParameters['id'] ?? '',
                            );
                            if (id == null) {
                              final l10n = AppLocalizations.of(context);
                              return _InvalidLinkPage(
                                title: l10n.centerDetailsTitle,
                                message: l10n.invalidCenterLink,
                              );
                            }
                            return StaffEvacuationCenterDetailPage(
                              centerId: id,
                            );
                          },
                          routes: [
                            // EC Information Board — Add Evacuee is
                            // reached via Navigator.push from this
                            // page and from the pending-entry detail
                            // page (same "already has what it needs
                            // in memory" reasoning as the center
                            // edit/pending-registration edit flows
                            // above), so only the board itself and its
                            // pending-entry detail need named routes.
                            GoRoute(
                              path: 'ec-board',
                              builder: (context, state) {
                                final id = int.tryParse(
                                  state.pathParameters['id'] ?? '',
                                );
                                return EcBoardPage(centerId: id ?? 0);
                              },
                              routes: [
                                GoRoute(
                                  path: ':localId',
                                  builder: (context, state) =>
                                      PendingEcEntryDetailPage(
                                        localId:
                                            state.pathParameters['localId']!,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    // Outside the shell so it's reachable (pushed on top of whichever
    // tab is active) without being a tab itself.
    GoRoute(
      path: '/centers',
      builder: (context, state) => const EvacuationCentersListPage(),
      routes: [
        GoRoute(
          path: ':id',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '');
            // Same defensive handling as /alerts/:id — unreachable from
            // in-app navigation (which always pushes a real int id),
            // but a stale/typed deep link could still land here.
            if (id == null) {
              final l10n = AppLocalizations.of(context);
              return _InvalidLinkPage(
                title: l10n.centerDetailsTitle,
                message: l10n.invalidCenterLink,
              );
            }
            return EvacuationCenterDetailsPage(centerId: id);
          },
        ),
      ],
    ),
    // No longer a bottom-nav tab (Settings took its slot) — moved from
    // a shell branch to a plain top-level route, same pattern as
    // /centers above. Every existing call site navigates to it by
    // path (`context.go('/nearest-center')` /
    // `context.push('/nearest-center')`), which resolves identically
    // whether the target is a branch or a top-level route, so nothing
    // else needed to change for it to stay reachable from Home and
    // Alerts/GIS Map as before.
    GoRoute(
      path: '/nearest-center',
      builder: (context, state) => const NearestCenterPage(),
    ),
  ],
);
