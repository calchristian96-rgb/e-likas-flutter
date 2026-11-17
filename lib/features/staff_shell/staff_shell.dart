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

/// Staff Mode's tabs, in order: at most 5, one short word each
/// (Part 2.4). A barangay official: Home, Centers, Relief, More. CSWDO:
/// Home, Barangays, More. The administrator never gets here
/// (StaffAuthGuard shows "Use the web"). Barangay status, Monitoring and
/// Notifications open from Home; the public view from More.
final staffTabs = <StaffTab>[
  StaffTab(
    branch: 3,
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
    label: (l10n) => l10n.staffTabHome,
    visibleTo: (s) => true,
  ),
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
    branch: 4,
    icon: Icons.location_city_outlined,
    selectedIcon: Icons.location_city,
    label: (l10n) => l10n.monitoringBarangays,
    visibleTo: (s) => s.isCityMonitor,
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
/// app's. Signed-in staff open here; the public view is in More.
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
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: (i) => navigationShell.goBranch(
              tabs[i].branch,
              initialLocation: tabs[i].branch == navigationShell.currentIndex,
            ),
            destinations: [
              for (final t in tabs)
                NavigationDestination(
                  icon: Icon(t.icon),
                  selectedIcon: Icon(t.selectedIcon),
                  label: t.label(l10n),
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

/// Staff paths that moved under Home (Part 3).
String? redirectMovedStaffPath(String path) => switch (path) {
  '/staff' || '/staff/' => '/staff/home',
  '/staff/barangay' => '/staff/home/barangay',
  '/staff/monitoring' => '/staff/home/monitoring',
  _ => null,
};
