import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/filter_chip_row.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../../core/widgets/search_field.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../../domain/entities/alert.dart';
import '../providers/alerts_summary_provider.dart';
import '../widgets/alert_list_tile.dart';
import '../widgets/alert_type_display.dart';

enum _AlertSort { newest, oldest, severity }

/// The Alerts tab — search, severity filter, sort, date-grouped list,
/// all operating on the single already-loaded [alertsListProvider]
/// result. None of search/filter/sort ever triggers a new network
/// request; they're pure client-side operations over data already in
/// memory, recomputed on every build (the list this app fetches is at
/// most 20 rows, so there's no real cost to redoing this on each
/// keystroke rather than caching it separately).
class AlertsListPage extends ConsumerStatefulWidget {
  const AlertsListPage({super.key});

  @override
  ConsumerState<AlertsListPage> createState() => _AlertsListPageState();
}

class _AlertsListPageState extends ConsumerState<AlertsListPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _severityFilter;
  _AlertSort _sort = _AlertSort.newest;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Alert> _visibleAlerts(List<Alert> alerts) {
    final query = _searchQuery.trim().toLowerCase();
    final filtered = alerts.where((alert) {
      if (_severityFilter != null && alert.severity != _severityFilter) {
        return false;
      }
      if (query.isEmpty) return true;
      return alert.title.toLowerCase().contains(query) ||
          alert.message.toLowerCase().contains(query) ||
          alert.alertType.toLowerCase().contains(query);
    }).toList();

    filtered.sort((a, b) {
      return switch (_sort) {
        _AlertSort.newest => _compareByDate(a, b, descending: true),
        _AlertSort.oldest => _compareByDate(a, b, descending: false),
        _AlertSort.severity => _severityRank(
          a.severity,
        ).compareTo(_severityRank(b.severity)),
      };
    });
    return filtered;
  }

  /// A missing date always sorts last, regardless of direction — the
  /// same rule [AlertsLocalDatasource] already applies when reading the
  /// cache, kept consistent here rather than inventing a second rule.
  static int _compareByDate(Alert a, Alert b, {required bool descending}) {
    final da = a.dateSent;
    final db = b.dateSent;
    if (da == null && db == null) return 0;
    if (da == null) return 1;
    if (db == null) return -1;
    return descending ? db.compareTo(da) : da.compareTo(db);
  }

  static int _severityRank(String? severity) => switch (severity) {
    'mandatory' => 0,
    'advisory' => 1,
    'info' => 2,
    'all_clear' => 3,
    _ => 4,
  };

  /// Groups already-sorted [alerts] under "Today"/"Yesterday"/plain-date
  /// headers, as a flat list of `String` (a header) and `Alert` items
  /// for [ListView.builder] to switch on. Skipped entirely when sorted
  /// by severity — a severity-ordered list isn't chronological, so date
  /// headers on it would misrepresent the ordering rather than describe
  /// it.
  List<Object> _groupedItems(List<Alert> alerts, AppLocalizations l10n) {
    if (_sort == _AlertSort.severity) return alerts;
    final items = <Object>[];
    String? lastLabel;
    for (final alert in alerts) {
      final label = alert.dateSent != null
          ? _dateGroupLabel(alert.dateSent!, l10n)
          : l10n.dateUnavailable;
      if (label != lastLabel) {
        items.add(label);
        lastLabel = label;
      }
      items.add(alert);
    }
    return items;
  }

  /// Device-local "today", compared against [date] (already device-local
  /// via [Alert.dateSent]'s own `.toLocal()` conversion) — deliberately
  /// not [philippineNow], which encodes Manila wall-clock fields into a
  /// mislabelled `isUtc: true` DateTime purely for *display* formatting
  /// and isn't safe to compare against a real local instant like this.
  static String _dateGroupLabel(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(date.year, date.month, date.day);
    final diffDays = today.difference(that).inDays;
    if (diffDays == 0) return l10n.dateGroupToday;
    if (diffDays == 1) return l10n.dateGroupYesterday;
    return DateFormat('EEEE, MMMM d').format(date);
  }

  String _countLabel(BuildContext context, List<Alert> visible) {
    final l10n = AppLocalizations.of(context);
    final severity = _severityFilter;
    if (severity == null) return l10n.publicAlertsCount(visible.length);
    return l10n.filteredAlertsCount(
      visible.length,
      alertSeverityLabel(context, severity),
    );
  }

  Future<void> _handleRefresh() async {
    ref.invalidate(alertsListProvider);
    try {
      await ref.read(alertsListProvider.future);
    } catch (_) {
      // The error state below already handles this — this callback
      // just needs to let the pull-to-refresh spinner finish.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final alertsAsync = ref.watch(alertsListProvider);
    final isConnected = ref.watch(connectivityStatusProvider).value ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.alertsAndNoticesTitle)),
      body: Column(
        children: [
          OfflineBanner(isOffline: !isConnected, lastUpdated: null),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.alertsAndNoticesSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SearchField(
                        controller: _searchController,
                        hintText: l10n.searchAlertsHint,
                        clearTooltip: l10n.clearSearch,
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _SortButton(
                      sort: _sort,
                      l10n: l10n,
                      onChanged: (sort) => setState(() => _sort = sort),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                FilterChipRow<String?>(
                  options: const [
                    null,
                    'mandatory',
                    'advisory',
                    'info',
                    'all_clear',
                  ],
                  selected: _severityFilter,
                  labelBuilder: (severity) => severity == null
                      ? l10n.filterAll
                      : alertSeverityLabel(context, severity),
                  colorBuilder: (severity) => severity == null
                      ? null
                      : alertSeverityColor(context, severity),
                  onSelected: (severity) =>
                      setState(() => _severityFilter = severity),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              child: alertsAsync.when(
                data: (alerts) {
                  if (alerts.isEmpty) {
                    return _CenteredScrollable(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          EmptyState(
                            message: l10n.noActiveAlerts,
                            icon: Icons.notifications_none,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.normalMonitoring,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final visible = _visibleAlerts(alerts);
                  if (visible.isEmpty) {
                    return _CenteredScrollable(
                      child: EmptyState(
                        message: l10n.noAlertsMatchFilter,
                        icon: Icons.search_off,
                      ),
                    );
                  }

                  final items = _groupedItems(visible, l10n);
                  final latestAlertId = alerts.first.id;
                  final latestBadgeEligible =
                      _searchQuery.isEmpty &&
                      _severityFilter == null &&
                      _sort == _AlertSort.newest;

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: items.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            _countLabel(context, visible),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }
                      final item = items[index - 1];
                      if (item is String) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(2, 14, 2, 8),
                          child: Text(item, style: theme.textTheme.titleSmall),
                        );
                      }
                      final alert = item as Alert;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AlertListTile(
                          alert: alert,
                          isLatest:
                              latestBadgeEligible && alert.id == latestAlertId,
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _CenteredScrollable(
                  child: ErrorState(
                    message: _describeError(error, l10n),
                    onRetry: () => ref.invalidate(alertsListProvider),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _describeError(Object error, AppLocalizations l10n) {
    if (error is Failure) {
      return '${l10n.couldNotLoadAlerts} — ${error.message}';
    }
    return '${l10n.couldNotLoadAlerts} — $error';
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({
    required this.sort,
    required this.onChanged,
    required this.l10n,
  });

  final _AlertSort sort;
  final ValueChanged<_AlertSort> onChanged;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: PopupMenuButton<_AlertSort>(
        initialValue: sort,
        onSelected: onChanged,
        tooltip: l10n.sortAlertsTooltip,
        icon: Icon(Icons.sort, color: theme.colorScheme.onSurfaceVariant),
        itemBuilder: (context) => [
          CheckedPopupMenuItem(
            value: _AlertSort.newest,
            checked: sort == _AlertSort.newest,
            child: Text(l10n.sortNewestFirst),
          ),
          CheckedPopupMenuItem(
            value: _AlertSort.oldest,
            checked: sort == _AlertSort.oldest,
            child: Text(l10n.sortOldestFirst),
          ),
          CheckedPopupMenuItem(
            value: _AlertSort.severity,
            checked: sort == _AlertSort.severity,
            child: Text(l10n.sortBySeverity),
          ),
        ],
      ),
    );
  }
}

/// Same reasoning as the Evacuation Centers list page's equivalent:
/// `RefreshIndicator` needs a scrollable descendant to work at all,
/// even when there's nothing (or just an error) to show.
class _CenteredScrollable extends StatelessWidget {
  const _CenteredScrollable({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(padding: const EdgeInsets.all(24), child: child),
            ),
          ),
        );
      },
    );
  }
}
