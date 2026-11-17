import '../../core/widgets/ui_kit.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../core/cache/staff_read_cache.dart';
import '../../core/utils/data_freshness_formatter.dart';
import '../../core/widgets/demo_badge.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/stat_strip.dart';
import '../../l10n/app_localizations.dart';
import '../barangay_status/presentation/barangay_status_card.dart'
    show barangayStatusColor;

/// One section of `GET /monitoring/{section}` (backend monitoring-api.md):
/// the event, and the section's data (null with no event open).
class MonitoringSection {
  const MonitoringSection({
    required this.data,
    required this.fetchedAt,
    required this.fromCache,
    this.eventName,
    this.isDemo = false,
  });

  final Map<String, dynamic>? data;
  final String? eventName;
  final bool isDemo;
  final DateTime fetchedAt;
  final bool fromCache;
}

final monitoringSectionProvider = FutureProvider.autoDispose
    .family<MonitoringSection, String>((ref, section) async {
      final read = await ref
          .watch(staffReadCacheProvider)
          .get('/monitoring/$section');
      final event = read.data['evacuation_event'] as Map<String, dynamic>?;
      return MonitoringSection(
        data: read.data['data'] as Map<String, dynamic>?,
        eventName: event?['name'] as String?,
        isDemo: event?['is_demo'] == true,
        fetchedAt: read.fetchedAt,
        fromCache: read.isFromCache,
      );
    });

/// CSWD's read-only Monitoring (D25): the current event as it unfolds,
/// city-wide, one question per tab, refreshed every 60 s like the web.
class MonitoringPage extends ConsumerStatefulWidget {
  const MonitoringPage({super.key});

  @override
  ConsumerState<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends ConsumerState<MonitoringPage> {
  static const sections = ['overview', 'centers', 'barangays', 'requests'];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) {
      for (final s in sections) {
        ref.invalidate(monitoringSectionProvider(s));
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: sections.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.monitoringTitle),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: l10n.monitoringOverview),
              Tab(text: l10n.monitoringCenters),
              Tab(text: l10n.monitoringBarangays),
              Tab(text: l10n.monitoringRequests),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            for (final s in sections)
              _SectionView(
                section: s,
                builder: switch (s) {
                  'overview' => _overview,
                  'centers' => _centers,
                  'barangays' => _barangays,
                  _ => _requests,
                },
              ),
          ],
        ),
      ),
    );
  }

  static List<Widget> _overview(BuildContext context, Map<String, dynamic> d) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final semantic = theme.extension<AppSemanticColors>()!;
    final f = d['figures'] as Map<String, dynamic>? ?? const {};
    String n(String k) => '${(f[k] as num?)?.toInt() ?? 0}';
    final attention = d['attention'] as List? ?? const [];
    return [
      StatStrip(
        items: [
          StatItem(l10n.monitoringPersons, n('persons')),
          StatItem(l10n.monitoringFamilies, n('families')),
          StatItem(l10n.monitoringInside, n('inside')),
          StatItem(l10n.monitoringCentersInUse, n('centers_in_use')),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        l10n.monitoringArrivedLastHour(int.parse(n('arrived_last_hour'))),
        style: theme.textTheme.bodyMedium,
      ),
      const SizedBox(height: 24),
      Text(l10n.monitoringNeedsAttention, style: theme.textTheme.titleMedium),
      const SizedBox(height: 8),
      if (attention.isEmpty)
        Text(l10n.monitoringNothingUrgent)
      else
        for (final a in attention)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(
                Icons.error_outline,
                color: (a as Map<String, dynamic>)['level'] == 'danger'
                    ? theme.colorScheme.error
                    : semantic.warning,
              ),
              title: Text(a['text'] as String? ?? ''),
            ),
          ),
    ];
  }

  static List<Widget> _centers(BuildContext context, Map<String, dynamic> d) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final semantic = theme.extension<AppSemanticColors>()!;
    final centers = d['centers'] as List? ?? const [];
    return [
      Text(
        l10n.monitoringCentersSummary(
          (d['in_use'] as num?)?.toInt() ?? 0,
          l10n.countCenters((d['total'] as num?)?.toInt() ?? 0),
          (d['capacity_not_set'] as num?)?.toInt() ?? 0,
        ),
        style: theme.textTheme.titleMedium,
      ),
      const SizedBox(height: 8),
      for (final c in centers.take(50))
        () {
          final center = c as Map<String, dynamic>;
          final percent = (center['percent'] as num?)?.toInt();
          final capacity = (center['capacity'] as num?)?.toInt();
          final inside = (center['inside'] as num?)?.toInt() ?? 0;
          final shortfalls = [
            for (final s in center['facility_shortfalls'] as List? ?? const [])
              if (((s as Map<String, dynamic>)['short'] as num? ?? 0) > 0)
                '${s['short']} ${s['label']}',
          ];
          final color = percent == null
              ? theme.colorScheme.onSurfaceVariant
              : percent >= 90
              ? theme.colorScheme.error
              : percent >= 70
              ? semantic.warning
              : semantic.success;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(center['name'] as String? ?? ''),
              subtitle: Text(
                [
                  ?(center['barangay'] as Map<String, dynamic>?)?['name']
                      as String?,
                  if (shortfalls.isNotEmpty)
                    l10n.monitoringShort(shortfalls.join(', ')),
                  if (center['facility_shortfalls'] == null)
                    l10n.monitoringNoChecklist,
                ].join(' · '),
              ),
              trailing: Text(
                capacity == null
                    ? l10n.monitoringInsideNoCapacity(inside)
                    : '$inside / $capacity · $percent%',
                style: theme.textTheme.labelLarge?.copyWith(color: color),
              ),
            ),
          );
        }(),
    ];
  }

  static List<Widget> _barangays(BuildContext context, Map<String, dynamic> d) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final statuses = {
      for (final s in d['statuses'] as List? ?? const [])
        (s as Map<String, dynamic>)['key'] as String: s['label'] as String,
    };
    final counts = d['counts'] as Map<String, dynamic>? ?? const {};
    final marked =
        [
          for (final b in d['barangays'] as List? ?? const [])
            if ((b as Map<String, dynamic>)['status'] != 'normal') b,
        ]..sort(
          (a, b) =>
              ((b['rank'] as num?) ?? 0).compareTo(a['rank'] as num? ?? 0),
        );
    final timeline = d['timeline'] as List? ?? const [];
    return [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final e in statuses.entries)
            Chip(
              avatar: CircleAvatar(
                backgroundColor: barangayStatusColor(context, e.key),
              ),
              label: Text('${e.value}: ${counts[e.key] ?? 0}'),
            ),
        ],
      ),
      const SizedBox(height: 24),
      Text(l10n.monitoringNotNormal, style: theme.textTheme.titleMedium),
      const SizedBox(height: 8),
      if (marked.isEmpty)
        Text(l10n.monitoringAllNormal)
      else
        for (final b in marked)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              radius: 8,
              backgroundColor: barangayStatusColor(
                context,
                b['status'] as String,
              ),
            ),
            title: Text(
              ((b['barangay'] as Map<String, dynamic>?)?['name'] as String?) ??
                  '',
            ),
            subtitle: b['note'] == null ? null : Text(b['note'] as String),
            trailing: Text(b['label'] as String? ?? ''),
          ),
      if (timeline.isNotEmpty) ...[
        const SizedBox(height: 24),
        Text(l10n.monitoringLatestChanges, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final t in timeline.take(10))
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              '${((t as Map<String, dynamic>)['barangay'] as Map<String, dynamic>?)?['name'] ?? ''}: ${t['label'] ?? ''}',
            ),
            subtitle: Text(
              [
                ?t['set_by'] as String?,
                if (DateTime.tryParse(t['at'] as String? ?? '') case final at?)
                  formatElapsedSince(at.toLocal()),
              ].join(' · '),
            ),
          ),
      ],
    ];
  }

  static List<Widget> _requests(BuildContext context, Map<String, dynamic> d) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final requests = d['requests'] as List? ?? const [];
    final waitLimit = (d['waiting_minutes'] as num?)?.toInt() ?? 120;
    if (requests.isEmpty) return [Text(l10n.monitoringNoRequests)];
    return [
      for (final r in requests)
        () {
          final req = r as Map<String, dynamic>;
          final waited = (req['waited_minutes'] as num?)?.toInt() ?? 0;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(req['what'] as String? ?? ''),
              subtitle: Text(
                [
                  ?req['kind_label'] as String?,
                  ?req['where'] as String?,
                ].join(' · '),
              ),
              trailing: Text(
                l10n.monitoringWaited(waited ~/ 60, waited % 60),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: waited >= waitLimit ? theme.colorScheme.error : null,
                ),
              ),
            ),
          );
        }(),
    ];
  }
}

class _SectionView extends ConsumerWidget {
  const _SectionView({required this.section, required this.builder});

  final String section;
  final List<Widget> Function(BuildContext, Map<String, dynamic>) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final async = ref.watch(monitoringSectionProvider(section));
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(monitoringSectionProvider(section));
        await ref.read(monitoringSectionProvider(section).future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: pagePadding(context),
        children: async.when(
          loading: () => [const Center(child: CircularProgressIndicator())],
          error: (_, _) => [
            ErrorState(
              message: l10n.monitoringNeedsConnection,
              onRetry: () => ref.invalidate(monitoringSectionProvider(section)),
            ),
          ],
          data: (s) => [
            Row(
              children: [
                Flexible(
                  child: Text(
                    s.eventName ?? l10n.staffNoOpenEvent,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                if (s.isDemo) ...[const SizedBox(width: 8), const DemoBadge()],
              ],
            ),
            Text(
              s.fromCache
                  ? l10n.savedCopyAge(formatElapsedSince(s.fetchedAt))
                  : l10n.monitoringUpdated(formatElapsedSince(s.fetchedAt)),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            if (s.data != null) ...builder(context, s.data!),
          ],
        ),
      ),
    );
  }
}
