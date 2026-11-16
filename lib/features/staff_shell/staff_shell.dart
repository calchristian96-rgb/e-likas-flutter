import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../outbox/presentation/outbox_providers.dart';
import '../staff_auth/domain/entities/staff_session.dart';
import '../staff_auth/presentation/widgets/staff_auth_guard.dart';

/// One tab of Staff Mode: its branch index in the staff shell's
/// `StatefulShellRoute`, and who sees it.
class StaffTab {
  const StaffTab({
    required this.branch,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.visibleTo,
  });

  final int branch;
  final IconData icon;
  final IconData selectedIcon;
  final String Function(AppLocalizations l10n) label;
  final bool Function(StaffSession session) visibleTo;
}

/// Staff Mode's tabs, in order. A barangay official does field work;
/// CSWD only monitors (read-only); the administrator never gets here
/// (StaffAuthGuard shows "Use the web").
final staffTabs = <StaffTab>[
  StaffTab(
    branch: 0,
    icon: Icons.fact_check_outlined,
    selectedIcon: Icons.fact_check,
    label: (l10n) => l10n.staffTabCenters,
    visibleTo: (s) => s.isFieldOfficial,
  ),
  StaffTab(
    branch: 2,
    icon: Icons.inventory_2_outlined,
    selectedIcon: Icons.inventory_2,
    label: (l10n) => l10n.staffTabRelief,
    visibleTo: (s) => s.isFieldOfficial && s.can(StaffPermission.boxDistribute),
  ),
  StaffTab(
    branch: 1,
    icon: Icons.more_horiz,
    selectedIcon: Icons.more_horiz,
    label: (l10n) => l10n.staffTabMore,
    visibleTo: (s) => true,
  ),
];

/// Staff Mode's own screens and bottom tabs, separate from the resident
/// app's. The last destination leaves Staff Mode (the session stays
/// signed in).
class StaffShell extends StatelessWidget {
  const StaffShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return StaffAuthGuard(
      builder: (context, session) {
        final l10n = AppLocalizations.of(context);
        final tabs = [
          for (final t in staffTabs)
            if (t.visibleTo(session)) t,
        ];
        // A tab this account cannot use (for example after a role
        // change) falls back to its first tab.
        var selected = tabs.indexWhere(
          (t) => t.branch == navigationShell.currentIndex,
        );
        if (selected < 0) {
          selected = 0;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            navigationShell.goBranch(tabs.first.branch);
          });
        }
        return Scaffold(
          // Syncs on open, on reconnect and on resume (C15).
          body: StaffAutoSync(child: navigationShell),
          bottomNavigationBar: NavigationBar(
            selectedIndex: selected,
            onDestinationSelected: (i) {
              if (i == tabs.length) {
                context.go('/home');
                return;
              }
              navigationShell.goBranch(
                tabs[i].branch,
                initialLocation: tabs[i].branch == navigationShell.currentIndex,
              );
            },
            destinations: [
              for (final t in tabs)
                NavigationDestination(
                  icon: Icon(t.icon),
                  selectedIcon: Icon(t.selectedIcon),
                  label: t.label(l10n),
                ),
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                label: l10n.staffTabResidentApp,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Old `/settings/staff/...` links (bookmarks, notifications, older
/// code) to their Staff Mode paths.
String? redirectOldStaffPath(String path) {
  if (!path.startsWith('/settings/staff')) return null;
  final rest = path.substring('/settings/staff'.length);
  if (rest.isEmpty || rest == '/' || rest == '/login') return '/staff';
  if (rest.startsWith('/ec-board')) {
    return '/staff/centers${rest.substring('/ec-board'.length)}';
  }
  return '/staff/more$rest';
}
