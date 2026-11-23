import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/ui_kit.dart';
import '../../l10n/app_localizations.dart';
import 'barangay_dashboard.dart';

int? _int(Object? v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}');

/// The barangay's plan from `GET /dashboard/barangay` `plan` (while the
/// event is not closed): the forecast for this barangay, the space in its
/// centers against it, and how many centers are ready. Read defensively:
/// any figure the server leaves out is shown as unknown, never as 0.
class BarangayPlan {
  const BarangayPlan({
    this.familiesLow,
    this.familiesHigh,
    this.personsLow,
    this.personsHigh,
    this.aboveSeen = false,
    this.hasForecast = false,
    this.volcanic = false,
    this.spacePersons,
    this.spaceNeeded,
    this.spaceShort,
    this.centersWithoutCapacity,
    this.centersReady,
    this.centersTotal,
    this.spaceEstimated = false,
    this.centersBelow,
    this.centersNoChecklist,
    this.centersNoCapacity,
  });

  factory BarangayPlan.fromDashboard(BarangayDashboard d) {
    final plan = d.plan ?? const {};
    final f = plan['forecast'];
    final forecast = f is Map<String, dynamic> ? f : null;
    final s = plan['space'];
    final space = s is Map<String, dynamic> ? s : null;
    final r = plan['centers_ready'];
    final event = d.data['evacuation_event'] as Map<String, dynamic>?;
    // apps-api-2026-11-24.md 7.1: forecast {families, persons,
    // families_low, families_high}. Plan for the high end.
    final familiesHigh = _int(
      forecast?['families_high'] ?? forecast?['families'],
    );
    final personsHigh = _int(forecast?['persons_high'] ?? forecast?['persons']);
    return BarangayPlan(
      hasForecast: forecast != null && familiesHigh != null,
      familiesLow: _int(forecast?['families_low']),
      familiesHigh: familiesHigh,
      personsLow: _int(forecast?['persons_low']),
      personsHigh: personsHigh,
      aboveSeen: forecast?['above_seen'] == true,
      volcanic:
          event?['is_volcanic'] == true ||
          event?['event_type'] == 'volcanic_eruption' ||
          plan['is_volcanic'] == true,
      spacePersons: _int(space?['capacity_persons']),
      spaceEstimated: space?['estimated'] == true,
      // Null without a forecast: never compared with anything else.
      spaceNeeded: _int(space?['forecast_persons']),
      spaceShort: _int(space?['short']),
      centersWithoutCapacity: _int(space?['centers_without_capacity']),
      centersReady: r is Map ? _int(r['ready']) : null,
      centersTotal: r is Map ? _int(r['total']) : null,
      centersBelow: r is Map ? _int(r['below']) : null,
      centersNoChecklist: r is Map ? _int(r['no_checklist']) : null,
      centersNoCapacity: r is Map ? _int(r['no_capacity']) : null,
    );
  }

  final bool spaceEstimated;
  final int? centersBelow;
  final int? centersNoChecklist;
  final int? centersNoCapacity;

  final bool hasForecast;
  final bool volcanic;
  final int? familiesLow;
  final int? familiesHigh;
  final int? personsLow;
  final int? personsHigh;
  final bool aboveSeen;
  final int? spacePersons;
  final int? spaceNeeded;
  final int? spaceShort;
  final int? centersWithoutCapacity;
  final int? centersReady;
  final int? centersTotal;
}

/// Four tiles on the official's home: Plan for, Your list, Center space
/// vs forecast, Centers ready.
class OfficialPlanCard extends ConsumerWidget {
  const OfficialPlanCard({super.key, required this.dashboard});

  final BarangayDashboard dashboard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final semantic = theme.extension<AppSemanticColors>()!;
    final plan = BarangayPlan.fromDashboard(dashboard);
    final list = dashboard.list;
    final listed = _int(list?['families']);
    final checkedIn = _int(list?['checked_in']) ?? 0;

    final String planFor;
    String? planDetail;
    if (plan.hasForecast) {
      planFor = l10n.countFamilies(plan.familiesHigh!);
      planDetail = [
        if (plan.personsHigh != null) l10n.countPersons(plan.personsHigh!),
        if (plan.familiesLow != null && plan.familiesLow != plan.familiesHigh)
          l10n.planForRange(
            formatCount(plan.familiesLow),
            formatCount(plan.familiesHigh),
          ),
        if (plan.aboveSeen) l10n.planAboveSeen,
      ].join(' · ');
    } else {
      planFor = '–';
      planDetail = plan.volcanic
          ? l10n.planNoForecastVolcanic
          : l10n.planNoForecast;
    }

    final String space;
    String? spaceDetail;
    Color? spaceColor;
    if (plan.spacePersons == null) {
      space = '–';
      spaceDetail = l10n.planSpaceUnknown;
    } else {
      space = l10n.planSpaceFigure(
        formatCount(plan.spacePersons),
        plan.spaceNeeded == null ? '–' : formatCount(plan.spaceNeeded),
      );
      final short =
          plan.spaceShort ??
          (plan.spaceNeeded == null
              ? null
              : (plan.spaceNeeded! - plan.spacePersons!));
      if (short != null && short > 0) {
        spaceDetail = l10n.planSpaceShort(short);
        spaceColor = theme.colorScheme.error;
      } else if (short != null) {
        spaceDetail = l10n.planSpaceEnough;
        spaceColor = semantic.success;
      }
      if ((plan.centersWithoutCapacity ?? 0) > 0 || plan.spaceEstimated) {
        spaceDetail = [
          ?spaceDetail,
          if (plan.spaceEstimated) l10n.planSpaceEstimated,
          if ((plan.centersWithoutCapacity ?? 0) > 0)
            l10n.planCentersWithoutCapacity(
              l10n.countCenters(plan.centersWithoutCapacity!),
            ),
        ].join(' · ');
      }
    }
    final readyDetail = [
      if ((plan.centersBelow ?? 0) > 0)
        l10n.planReadyBelow(formatCount(plan.centersBelow)),
      if ((plan.centersNoChecklist ?? 0) > 0)
        l10n.planReadyNoChecklist(formatCount(plan.centersNoChecklist)),
      if ((plan.centersNoCapacity ?? 0) > 0)
        l10n.planReadyNoCapacity(formatCount(plan.centersNoCapacity)),
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(l10n.planTitle),
        _PlanTile(
          icon: Icons.insights_outlined,
          title: l10n.planForTitle,
          value: planFor,
          detail: planDetail,
        ),
        _PlanTile(
          icon: Icons.checklist_outlined,
          title: l10n.planYourList,
          value: listed == null || listed == 0
              ? l10n.planListNone
              : l10n.countFamilies(listed),
          detail: listed == null || listed == 0
              ? l10n.planListAdd
              : l10n.planListCheckedIn(
                  formatCount(checkedIn),
                  formatCount(listed),
                ),
          onTap: () => context.go('/staff/home/families-to-evacuate'),
        ),
        _PlanTile(
          icon: Icons.meeting_room_outlined,
          title: l10n.planSpaceTitle,
          value: space,
          detail: spaceDetail,
          detailColor: spaceColor,
        ),
        _PlanTile(
          icon: Icons.verified_outlined,
          title: l10n.planCentersReady,
          value: plan.centersReady == null
              ? '–'
              : plan.centersTotal == null
              ? formatCount(plan.centersReady)
              : l10n.planOfTotal(
                  formatCount(plan.centersReady),
                  formatCount(plan.centersTotal),
                ),
          detail: readyDetail,
          onTap: () => context.go('/staff/more/evacuation-centers'),
        ),
      ],
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.icon,
    required this.title,
    required this.value,
    this.detail,
    this.detailColor,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final String? detail;
  final Color? detailColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.bodyMedium),
                  Text(value, style: theme.textTheme.titleLarge),
                  if (detail != null && detail!.isNotEmpty)
                    Text(
                      detail!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: detailColor,
                      ),
                    ),
                ],
              ),
            ),
            if (onTap != null) const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

/// What a dashboard `todo` item opens in the app: the server's `href` is a
/// web path, so the app picks its own screen by `kind`
/// (apps-api-2026-11-24.md 7.1). Unknown kinds are shown without a button.
enum TodoTarget { centers, supplies, none }

TodoTarget todoTargetOf(Map<String, dynamic> item) =>
    switch ('${item['kind'] ?? ''}') {
      'center_capacity' ||
      'center_location' ||
      'center_checklist' => TodoTarget.centers,
      'supplies_short' => TodoTarget.supplies,
      _ => TodoTarget.none,
    };

/// The one center a To do item is about, when it names one: `center_id`
/// (supplies), or the id in the web link (`/gis-map?locate=1`,
/// `/evacuation-centers/1#facilities`). Null for a list of centers.
int? todoCenterId(Map<String, dynamic> item) {
  final direct = _int(item['center_id']);
  if (direct != null) return direct;
  final uri = Uri.tryParse('${item['href'] ?? ''}');
  if (uri == null) return null;
  final locate = int.tryParse(uri.queryParameters['locate'] ?? '');
  if (locate != null) return locate;
  final segments = uri.pathSegments;
  if (segments.length == 2 && segments.first == 'evacuation-centers') {
    return int.tryParse(segments[1]);
  }
  return null;
}

/// The app screen for a To do item: the facility request page for that
/// center's suggestions, the center's own page when one center is named,
/// else My centers.
String? todoPathOf(Map<String, dynamic> item) {
  final center = todoCenterId(item);
  return switch (todoTargetOf(item)) {
    TodoTarget.supplies =>
      center == null
          ? '/staff/home/facility-requests'
          : '/staff/home/facility-requests?center=$center',
    TodoTarget.centers =>
      center == null
          ? '/staff/more/evacuation-centers'
          : '/staff/more/evacuation-centers/$center',
    TodoTarget.none => null,
  };
}

/// One dashboard To do item: the server's `text` and `detail` as they
/// are, with its action ("Request supplies", "Open centers").
class DashboardTodoCard extends StatelessWidget {
  const DashboardTodoCard({super.key, required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final target = todoTargetOf(item);
    final path = todoPathOf(item);
    // The server's button label ("Set location", "Request supplies").
    final serverLabel = item['action'] is String
        ? item['action'] as String
        : null;
    final label =
        serverLabel ??
        switch (target) {
          TodoTarget.supplies => l10n.todoRequestSupplies,
          TodoTarget.centers => l10n.todoOpenCenters,
          TodoTarget.none => null,
        };
    final icon = switch ('${item['kind']}') {
      'supplies_short' => Icons.inventory_outlined,
      'center_location' => Icons.location_off_outlined,
      'center_checklist' => Icons.checklist_rtl_outlined,
      _ => Icons.straighten_outlined,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        onTap: path == null ? null : () => context.go(path),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['text'] as String? ?? '',
                    style: theme.textTheme.bodyLarge,
                  ),
                  if ((item['detail'] as String?)?.isNotEmpty ?? false)
                    Text(
                      item['detail'] as String,
                      style: theme.textTheme.bodySmall,
                    ),
                  if (path != null && label != null) ...[
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => context.go(path),
                      child: Text(label),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
