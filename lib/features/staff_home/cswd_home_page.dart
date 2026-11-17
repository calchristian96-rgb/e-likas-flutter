import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../core/cache/staff_read_cache.dart';
import '../../core/connectivity/connectivity_service.dart';
import '../../core/network/staff_api_client.dart';
import '../../core/network/staff_api_error_mapper.dart';
import '../../core/widgets/stat_strip.dart';
import '../../core/widgets/ui_kit.dart';
import '../../l10n/app_localizations.dart';
import '../barangay_status/presentation/barangay_status_card.dart'
    show barangayStatusColor;
import '../evacuation_centers/presentation/widgets/center_status_display.dart';
import '../monitoring/monitoring_page.dart';
import '../notifications/notifications.dart';
import '../staff_auth/domain/entities/staff_session.dart';
import '../staff_shell/current_event.dart';

/// Barangays with families in the event and no final count sent yet
/// (`GET /count-submissions/barangays`, CSWD).
final countsNotSentProvider = FutureProvider.autoDispose<List<String>>((
  ref,
) async {
  final event = await ref.watch(currentStaffEventProvider.future);
  if (event == null) return const [];
  final read = await ref
      .watch(staffReadCacheProvider)
      .get(
        '/count-submissions/barangays',
        query: {'evacuation_event_id': event.id},
      );
  return [
    for (final r in read.data['barangays'] as List? ?? const [])
      if ((r as Map<String, dynamic>)['current_submission'] == null &&
          (((r['computed'] as Map<String, dynamic>?)?['families'] as num?) ??
                  0) >
              0)
        (r['barangay'] as Map<String, dynamic>?)?['name'] as String? ?? '',
  ];
});

/// CSWDO's home (Part 4.2): the event and its status, city totals, how
/// many barangays are in each status, and what needs attention: full or
/// nearly full centers, barangays short of boxes, final counts not sent.
/// With no event open (or one being monitored), the readiness view.
/// Everything here is read-only; decisions are made on the web.
class CswdHomePage extends ConsumerWidget {
  const CswdHomePage({super.key, required this.session});

  final StaffSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final event = ref.watch(currentStaffEventProvider).value;
    final active = event?.status == 'active';
    final overview = ref.watch(monitoringSectionProvider('overview')).value;
    final f = overview?.data?['figures'] as Map<String, dynamic>? ?? const {};
    String n(String k) => '${(f[k] as num?)?.toInt() ?? '–'}';
    final barangays = ref.watch(monitoringSectionProvider('barangays')).value;
    final counts =
        barangays?.data?['counts'] as Map<String, dynamic>? ?? const {};
    final labels = {
      for (final s in barangays?.data?['statuses'] as List? ?? const [])
        (s as Map<String, dynamic>)['key'] as String: s['label'] as String,
    };
    final centers = ref.watch(monitoringSectionProvider('centers')).value;
    final full = [
      for (final c in centers?.data?['centers'] as List? ?? const [])
        if (((c as Map<String, dynamic>)['percent'] as num? ?? 0) >= 90) c,
    ];
    final relief = ref.watch(monitoringSectionProvider('relief')).value;
    final rounds = relief?.data?['rounds'] as List? ?? const [];
    final latest = rounds.isEmpty ? null : rounds.last as Map<String, dynamic>;
    final shortBoxes = [
      for (final b in latest?['barangays'] as List? ?? const [])
        if (((b as Map<String, dynamic>)['short'] as num? ?? 0) > 0) b,
    ];
    final notSent = ref.watch(countsNotSentProvider).value ?? const [];
    final warning = theme.extension<AppSemanticColors>()!.warning;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cswdHomeTitle),
        actions: const [NotificationsBell(), SizedBox(width: 8)],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          for (final s in ['overview', 'barangays', 'centers', 'relief']) {
            ref.invalidate(monitoringSectionProvider(s));
          }
          ref.invalidate(countsNotSentProvider);
          ref.invalidate(notificationsProvider);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: pagePadding(context),
          children: [
            const StaffEventBar(),
            if (event != null) ...[
              const SizedBox(height: 4),
              StatusChip(
                label: switch (event.status) {
                  'active' => l10n.eventStatusActive,
                  'monitoring' => l10n.eventStatusMonitoring,
                  _ => event.status,
                },
                color: active ? warning : theme.colorScheme.primary,
              ),
            ],
            if (!active) ...[
              const SizedBox(height: 16),
              const _ReadinessCard(),
            ],
            const SizedBox(height: 16),
            StatStrip(
              items: [
                StatItem(l10n.monitoringPersons, n('persons')),
                StatItem(l10n.monitoringFamilies, n('families')),
                StatItem(l10n.monitoringInside, n('inside')),
                StatItem(l10n.monitoringCentersInUse, n('centers_in_use')),
              ],
            ),
            SectionTitle(l10n.cswdBarangaysByStatus),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in labels.entries)
                  ActionChip(
                    avatar: CircleAvatar(
                      backgroundColor: barangayStatusColor(context, e.key),
                    ),
                    label: Text('${e.value}: ${counts[e.key] ?? 0}'),
                    onPressed: () => context.go('/staff/barangays'),
                  ),
              ],
            ),
            SectionTitle(l10n.monitoringNeedsAttention),
            if (full.isEmpty && shortBoxes.isEmpty && notSent.isEmpty)
              EmptyNote(
                icon: Icons.check_circle_outline,
                message: l10n.monitoringNothingUrgent,
              ),
            for (final c in full)
              _Warning(
                text: l10n.cswdCenterNearlyFull(
                  c['name'] as String? ?? '',
                  (c['percent'] as num?)?.toInt() ?? 0,
                ),
              ),
            for (final b in shortBoxes)
              _Warning(
                text: l10n.cswdBarangayShortBoxes(
                  ((b['barangay'] as Map<String, dynamic>?)?['name']
                          as String?) ??
                      '',
                  l10n.countBoxes((b['short'] as num?)?.toInt() ?? 0),
                ),
              ),
            if (notSent.isNotEmpty)
              _Warning(
                text: l10n.cswdFinalCountsNotSent(
                  l10n.countBarangays(notSent.length),
                  notSent.take(5).join(', '),
                ),
              ),
            const SizedBox(height: 8),
            AppCard(
              child: Row(
                children: [
                  const Icon(Icons.desktop_windows_outlined),
                  const SizedBox(width: 12),
                  Expanded(child: Text(l10n.cswdDoThisOnTheWeb)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => context.go('/staff/home/monitoring'),
              child: Text(l10n.cswdOpenMonitoring),
            ),
          ],
        ),
      ),
    );
  }
}

class _Warning extends StatelessWidget {
  const _Warning({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        child: Row(
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
          ],
        ),
      ),
    );
  }
}

/// While no event is open or the event is being monitored: are we
/// ready (`GET /monitoring/readiness`).
class _ReadinessCard extends ConsumerWidget {
  const _ReadinessCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final d = ref.watch(monitoringSectionProvider('readiness')).value?.data;
    if (d == null) return const SizedBox.shrink();
    final c = d['centers'] as Map<String, dynamic>? ?? const {};
    final below = d['below_standards'] as Map<String, dynamic>? ?? const {};
    final boxes = d['boxes'] as Map<String, dynamic>?;
    final watched = d['barangays'] as List?;
    int i(Map<String, dynamic> m, String k) => (m[k] as num?)?.toInt() ?? 0;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.cswdReadiness, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            l10n.cswdReadyCenters(
              l10n.countCenters(i(c, 'ready')),
              i(c, 'approved'),
            ),
          ),
          Text(l10n.cswdBelowStandards(l10n.countCenters(i(below, 'count')))),
          if (boxes != null)
            Text(l10n.cswdBoxStock(l10n.countBoxes(i(boxes, 'on_hand')))),
          if (watched != null && watched.isNotEmpty)
            Text(
              l10n.cswdWatchedBarangays(
                [
                  for (final w in watched)
                    ((w as Map<String, dynamic>)['barangay']
                            as Map<String, dynamic>?)?['name'] ??
                        '',
                ].join(', '),
              ),
            ),
        ],
      ),
    );
  }
}

/// `GET /gis/situation`: every barangay's status (CSWD).
final citySituationProvider = FutureProvider.autoDispose<Map<String, dynamic>>(
  (ref) async =>
      (await ref.watch(staffReadCacheProvider).get('/gis/situation')).data,
);

/// Barangays (Part 4.3): every barangay with its status word, most
/// urgent first; a row opens the barangay.
class CswdBarangaysPage extends ConsumerWidget {
  const CswdBarangaysPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final async = ref.watch(citySituationProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.monitoringBarangays)),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(citySituationProvider),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: pagePadding(context),
          children: async.when(
            loading: () => [const Center(child: CircularProgressIndicator())],
            error: (_, _) => [
              EmptyNote(
                icon: Icons.cloud_off_outlined,
                message: l10n.monitoringNeedsConnection,
              ),
            ],
            data: (d) {
              final rows =
                  [
                    for (final b in d['barangays'] as List? ?? const [])
                      b as Map<String, dynamic>,
                  ]..sort((a, b) {
                    final r = ((b['rank'] as num?) ?? 0).compareTo(
                      (a['rank'] as num?) ?? 0,
                    );
                    if (r != 0) return r;
                    return '${(a['barangay'] as Map)['name']}'.compareTo(
                      '${(b['barangay'] as Map)['name']}',
                    );
                  });
              return [
                for (final b in rows) ...[
                  AppCard(
                    onTap: () => context.go(
                      '/staff/barangays/${(b['barangay'] as Map)['id']}',
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${(b['barangay'] as Map)['name']}',
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        StatusChip(
                          label: b['label'] as String? ?? '',
                          color: barangayStatusColor(
                            context,
                            b['status'] as String? ?? 'normal',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ];
            },
          ),
        ),
      ),
    );
  }
}

final barangayPanelProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, int>(
      (ref, id) async =>
          (await ref.watch(staffReadCacheProvider).get('/gis/barangays/$id'))
              .data,
    );

/// One barangay (Part 4.3): its status, evacuees, centers and relief,
/// and for CSWDO, ordering a preemptive or forced evacuation (online
/// only, never queued: it notifies the barangay).
class CswdBarangayDetailPage extends ConsumerWidget {
  const CswdBarangayDetailPage({super.key, required this.barangayId});

  final int barangayId;

  Future<void> _order(
    BuildContext context,
    WidgetRef ref, {
    required String name,
    required int eventId,
    required String status,
    required String label,
  }) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (!await ref.read(connectivityServiceProvider).hasConnection) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.cswdOrderNeedsConnection)),
      );
      return;
    }
    if (!context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.cswdOrderTitle(label.toLowerCase(), name)),
        content: Text(l10n.cswdOrderBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.cswdOrderConfirm(label)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(staffApiClientProvider)
          .post(
            '/gis/barangay-status',
            data: {
              'evacuation_event_id': eventId,
              'barangay_id': barangayId,
              'status': status,
            },
          );
      ref.invalidate(barangayPanelProvider(barangayId));
      ref.invalidate(citySituationProvider);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.barangayStatusOrdered(label, name))),
      );
    } on DioException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(mapStaffDioError(e).message)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final panel = ref.watch(barangayPanelProvider(barangayId));
    final situation = ref.watch(citySituationProvider).value;
    final orders = [
      for (final s in situation?['statuses'] as List? ?? const [])
        if ((s as Map<String, dynamic>)['evacuation_order'] == true &&
            s['may_set'] == true)
          s,
    ];
    final eventId =
        (situation?['evacuation_event'] as Map<String, dynamic>?)?['id']
            as int?;
    final open = situation?['open'] == true;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.monitoringBarangays)),
      body: ListView(
        padding: pagePadding(context),
        children: panel.when(
          loading: () => [const Center(child: CircularProgressIndicator())],
          error: (_, _) => [
            EmptyNote(
              icon: Icons.cloud_off_outlined,
              message: l10n.monitoringNeedsConnection,
            ),
          ],
          data: (d) {
            final name =
                (d['barangay'] as Map<String, dynamic>?)?['name'] as String? ??
                '';
            final status = d['status'] as Map<String, dynamic>? ?? const {};
            final reg = d['registered'] as Map<String, dynamic>?;
            final boxes = d['relief_boxes'] as Map<String, dynamic>?;
            int i(Map<String, dynamic>? m, String k) =>
                (m?[k] as num?)?.toInt() ?? 0;
            return [
              Text(name, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              StatusChip(
                label: status['label'] as String? ?? '',
                color: barangayStatusColor(
                  context,
                  status['status'] as String? ?? 'normal',
                ),
              ),
              if ((status['note'] as String?)?.isNotEmpty ?? false) ...[
                const SizedBox(height: 4),
                Text(status['note'] as String),
              ],
              const SizedBox(height: 16),
              StatStrip(
                items: [
                  StatItem(l10n.monitoringFamilies, '${i(reg, 'families')}'),
                  StatItem(l10n.monitoringPersons, '${i(reg, 'persons')}'),
                  if (boxes != null) ...[
                    StatItem(l10n.reliefGiven, '${i(boxes, 'given')}'),
                    StatItem(
                      l10n.reliefShort,
                      '${i(boxes, 'short')}',
                      alert: i(boxes, 'short') > 0,
                    ),
                  ],
                ],
              ),
              SectionTitle(l10n.monitoringCenters),
              for (final c in d['centers'] as List? ?? const []) ...[
                AppCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (c as Map<String, dynamic>)['name'] as String? ??
                                  '',
                              style: theme.textTheme.titleMedium,
                            ),
                            Text(
                              c['capacity_persons'] == null
                                  ? l10n.monitoringInsideNoCapacity(
                                      (c['current_occupancy'] as num?)
                                              ?.toInt() ??
                                          0,
                                    )
                                  : '${c['current_occupancy'] ?? 0} / ${c['capacity_persons']}',
                            ),
                          ],
                        ),
                      ),
                      StatusChip(
                        label: localizedCenterStatus(
                          context,
                          c['status'] as String? ?? '',
                        ),
                        color: centerStatusColorOf(
                          c['status'] as String? ?? '',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (open && eventId != null && orders.isNotEmpty) ...[
                SectionTitle(l10n.cswdOrderEvacuation),
                for (final o in orders) ...[
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                    onPressed: () => _order(
                      context,
                      ref,
                      name: name,
                      eventId: eventId,
                      status: o['key'] as String,
                      label: o['label'] as String? ?? '',
                    ),
                    child: Text(o['label'] as String? ?? ''),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ];
          },
        ),
      ),
    );
  }
}
