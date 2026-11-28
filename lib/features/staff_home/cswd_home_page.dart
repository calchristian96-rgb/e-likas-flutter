import '../../core/widgets/map_sheet.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:elikas_mobile/features/evacuation_centers/presentation/widgets/capacity_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/cache/staff_read_cache.dart';
import '../../core/connectivity/connectivity_service.dart';
import '../../core/network/staff_api_client.dart';
import '../../core/network/staff_api_error_mapper.dart';
import '../../core/widgets/stat_strip.dart';
import '../../core/widgets/ui_kit.dart';
import '../../l10n/app_localizations.dart';
import '../barangay_status/presentation/barangay_status_card.dart'
    show barangayStatusColor;
import '../barangay_status/staff/barangay_page.dart'
    show EvacuationOrder, EvacuationOrderLine;
import '../evacuation_centers/presentation/widgets/center_status_display.dart';
import '../monitoring/monitoring_page.dart';
import '../count_submissions/final_count_card.dart'
    show ComputedCount, CountFigures, OnBehalfNote;
import '../notifications/notifications.dart';
import '../private_houses/private_houses.dart';
import '../staff_auth/domain/entities/staff_session.dart';
import '../staff_auth/presentation/providers/staff_auth_provider.dart';
import '../staff_shell/current_event.dart';
import '../transfers/cswd_move_page.dart';
import '../transfers/transfers.dart';
import '../../core/widgets/lock_note.dart';
import 'cswd_actions.dart';

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

/// Families and persons registered or removed after their barangay's
/// latest final count, city-wide (`late_entries_total`): not in any
/// validated count yet.
final cityLateEntriesProvider = FutureProvider.autoDispose<int>((ref) async {
  final event = await ref.watch(currentStaffEventProvider.future);
  if (event == null) return 0;
  final read = await ref
      .watch(staffReadCacheProvider)
      .get(
        '/count-submissions/barangays',
        query: {'evacuation_event_id': event.id},
      );
  return (read.data['late_entries_total'] as num?)?.toInt() ?? 0;
});

/// Pending transfer requests in the selected event
/// (`GET /dashboard/city` `actions.transfer_requests_pending`); 0 when the
/// dashboard cannot be read.
final cityTransfersPendingProvider = FutureProvider.autoDispose<int>((
  ref,
) async {
  final event = await ref.watch(currentStaffEventProvider.future);
  try {
    final read = await ref
        .watch(staffReadCacheProvider)
        .get('/dashboard/city', query: {'evacuation_event_id': ?event?.id});
    final actions = read.data['actions'] as Map<String, dynamic>? ?? const {};
    return (actions['transfer_requests_pending'] as num?)?.toInt() ?? 0;
  } catch (_) {
    return 0;
  }
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
        if ((c as Map<String, dynamic>)['capacity_source'] != 'unknown' &&
            ((c['percent'] as num?) ?? 0) >= 90)
          c,
    ];
    final relief = ref.watch(monitoringSectionProvider('relief')).value;
    final rounds = relief?.data?['rounds'] as List? ?? const [];
    final latest = rounds.isEmpty ? null : rounds.last as Map<String, dynamic>;
    final shortBoxes = [
      for (final b in latest?['barangays'] as List? ?? const [])
        if (((b as Map<String, dynamic>)['short'] as num? ?? 0) > 0) b,
    ];
    final notSent = ref.watch(countsNotSentProvider).value ?? const [];
    final lateEntries = ref.watch(cityLateEntriesProvider).value ?? 0;
    final transfersPending = ref.watch(cityTransfersPendingProvider).value ?? 0;
    // Families staying with relatives or friends, city-wide.
    final privateHouses = ref.watch(privateHousesProvider(null)).value;
    final privateFamilies = privateHouses?.barangays.values.fold<int>(
      0,
      (sum, b) => sum + b.families,
    );

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
          ref.invalidate(cityLateEntriesProvider);
          ref.invalidate(transferRequestsProvider);
          ref.invalidate(cityTransfersPendingProvider);
          ref.invalidate(notificationsProvider);
          ref.invalidate(privateHousesProvider(null));
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: pagePadding(context),
          children: [
            const StaffEventBar(),
            if (session.can(StaffPermission.eventsManage))
              const StartEvacuationCard(),
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
                StatItem(
                  l10n.cswdPrivateHouseFamilies,
                  '${privateFamilies ?? '–'}',
                ),
              ],
            ),
            if (session.can(StaffPermission.transfersManage)) ...[
              const SizedBox(height: 16),
              TransfersCard(onOpen: () => context.go('/staff/home/transfers')),
            ],
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
            if (full.isEmpty &&
                shortBoxes.isEmpty &&
                notSent.isEmpty &&
                lateEntries == 0 &&
                transfersPending == 0)
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
            if (transfersPending > 0)
              _Warning(
                text: l10n.cswdTransfersWaiting(transfersPending),
                onTap: () => context.go('/staff/home/transfers'),
              ),
            if (lateEntries > 0)
              _Warning(text: l10n.cswdLateEntriesPending(lateEntries)),
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
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () => context.go('/staff/home/progress'),
              icon: const Icon(Icons.stacked_bar_chart),
              label: Text(l10n.cswdProgressTitle),
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
  const _Warning({required this.text, this.onTap});

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        onTap: onTap,
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
final citySituationProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) async {
  final event = await ref.watch(currentStaffEventProvider.future);
  return (await ref
          .watch(staffReadCacheProvider)
          .get('/gis/situation', query: {'evacuation_event_id': ?event?.id}))
      .data;
});

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
                        BarangayStateTag(
                          status: b['status'] as String? ?? 'normal',
                          label: b['label'] as String? ?? '',
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
    .family<Map<String, dynamic>, int>((ref, id) async {
      final event = await ref.watch(currentStaffEventProvider.future);
      return (await ref
              .watch(staffReadCacheProvider)
              .get(
                '/gis/barangays/$id',
                query: {'evacuation_event_id': ?event?.id},
              ))
          .data;
    });

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
    required String eventName,
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
    // Who ordered it and when (backend cb20427), then the confirmation.
    final order = await showDialog<_OrderAnswer>(
      context: context,
      builder: (context) => _OrderDialog(
        title: l10n.cswdOrderRecordTitle(label.toLowerCase(), name, eventName),
        label: label,
      ),
    );
    if (order == null) return;
    try {
      final response = await ref
          .read(staffApiClientProvider)
          .post(
            '/gis/barangay-status',
            data: {
              'evacuation_event_id': eventId,
              'barangay_id': barangayId,
              'status': status,
              'ordered_by': order.orderedBy,
              if (order.orderedBy == 'other') 'ordered_by_other': order.other,
              if (order.orderedAt != null)
                'ordered_at': order.orderedAt!.toUtc().toIso8601String(),
            },
          );
      ref.invalidate(barangayPanelProvider(barangayId));
      ref.invalidate(citySituationProvider);
      final message = (response.data as Map?)?['message'] as String?;
      messenger.showSnackBar(
        SnackBar(
          content: Text(message ?? l10n.barangayStatusOrdered(label, name)),
        ),
      );
    } on DioException catch (e) {
      messenger.showSnackBar(failureSnackBar(mapStaffDioError(e)));
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
              BarangayStateTag(
                status: status['status'] as String? ?? 'normal',
                label: status['label'] as String? ?? '',
              ),
              EvacuationOrderLine(
                order: EvacuationOrder.fromJson(status['order']),
              ),
              if ((status['note'] as String?)?.isNotEmpty ?? false) ...[
                const SizedBox(height: 4),
                Text(status['note'] as String),
              ],
              if (open)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: () => askBarangayToUpdate(
                      context,
                      ref,
                      barangayId: barangayId,
                      name: name,
                    ),
                    icon: const Icon(Icons.campaign_outlined),
                    label: Text(l10n.cswdAskUpdate),
                  ),
                ),
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
              const SizedBox(height: 8),
              PrivateHousesCard(
                barangayId: barangayId,
                onOpen: () =>
                    context.go('/staff/barangays/$barangayId/private-houses'),
              ),
              _CswdFinalCount(barangayId: barangayId, name: name),
              SectionTitle(l10n.monitoringCenters),
              for (final c in d['centers'] as List? ?? const []) ...[
                AppCard(
                  // CSWDO opens a center's families to move one (Part 7).
                  onTap:
                      open &&
                          eventId != null &&
                          (ref
                                  .watch(staffAuthProvider)
                                  .value
                                  ?.can(StaffPermission.evacueesTransfer) ??
                              false)
                      ? () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => CswdCenterFamiliesPage(
                              centerId:
                                  (c as Map<String, dynamic>)['id'] as int,
                              centerName: c['name'] as String? ?? '',
                              eventId: eventId,
                            ),
                          ),
                        )
                      : null,
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
                            Tooltip(
                              message:
                                  capacityBasisTooltip(
                                    l10n,
                                    c['capacity_basis'] as String?,
                                  ) ??
                                  '',
                              child: Text(
                                capacityFigure(
                                  l10n,
                                  capacity: (c['capacity_persons'] as num?)
                                      ?.toInt(),
                                  source: c['capacity_source'] as String?,
                                  occupancy:
                                      (c['current_occupancy'] as num?)
                                          ?.toInt() ??
                                      0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      CenterStateTag(
                        status: c['status'] as String? ?? '',
                        label: localizedCenterStatus(
                          context,
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
                      eventName:
                          (situation?['evacuation_event']
                                  as Map<String, dynamic>?)?['name']
                              as String? ??
                          '',
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

typedef _OrderAnswer = ({String orderedBy, String? other, DateTime? orderedAt});

/// "Record a forced evacuation order for Binatagan in Typhoon Rolly?":
/// who ordered it (the City Mayor, CDRRMO, or someone named), and when
/// (now, or a time today that is not in the future).
class _OrderDialog extends StatefulWidget {
  const _OrderDialog({required this.title, required this.label});

  final String title;
  final String label;

  @override
  State<_OrderDialog> createState() => _OrderDialogState();
}

class _OrderDialogState extends State<_OrderDialog> {
  String? _by;
  final _other = TextEditingController();
  TimeOfDay? _time;

  @override
  void dispose() {
    _other.dispose();
    super.dispose();
  }

  bool get _ready =>
      _by != null && (_by != 'other' || _other.text.trim().isNotEmpty);

  DateTime? get _orderedAt {
    final t = _time;
    if (t == null) return null;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, t.hour, t.minute);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked == null) return;
    final now = DateTime.now();
    final at = DateTime(
      now.year,
      now.month,
      now.day,
      picked.hour,
      picked.minute,
    );
    // Never in the future (the server refuses it).
    setState(() => _time = at.isAfter(now) ? TimeOfDay.now() : picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.cswdOrderBody),
            const SizedBox(height: 16),
            Text(l10n.cswdOrderWhoOrdered, style: theme.textTheme.titleSmall),
            RadioGroup<String>(
              groupValue: _by,
              onChanged: (v) => setState(() => _by = v),
              child: Column(
                children: [
                  for (final (value, text) in [
                    ('city_mayor', l10n.cswdOrderByMayor),
                    ('cdrrmo', l10n.cswdOrderByCdrrmo),
                    ('other', l10n.cswdOrderByOther),
                  ])
                    RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      value: value,
                      title: Text(text),
                    ),
                ],
              ),
            ),
            if (_by == 'other')
              TextField(
                controller: _other,
                maxLength: 100,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: l10n.cswdOrderByOtherName,
                ),
                onChanged: (_) => setState(() {}),
              ),
            const SizedBox(height: 8),
            Text(l10n.cswdOrderWhen, style: theme.textTheme.titleSmall),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _time == null ? l10n.cswdOrderNow : _time!.format(context),
                  ),
                ),
                // Flexible: a large text size wraps the label instead of
                // pushing the row off the dialog.
                Flexible(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: _pickTime,
                    child: Text(l10n.cswdOrderChangeTime),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        // An action: sienna like every other (red means the
        // evacuation status itself, never a button).
        FilledButton(
          onPressed: !_ready
              ? null
              : () => Navigator.of(context).pop((
                  orderedBy: _by!,
                  other: _by == 'other' ? _other.text.trim() : null,
                  orderedAt: _orderedAt,
                )),
          child: Text(l10n.cswdOrderRecord),
        ),
      ],
    );
  }
}

/// A barangay's count as the system computes it now, with its latest
/// submission (`GET /count-submissions/computed` with `barangay_id`).
final barangayComputedProvider = FutureProvider.autoDispose
    .family<ComputedCount?, int>((ref, barangayId) async {
      final event = await ref.watch(currentStaffEventProvider.future);
      if (event == null) return null;
      final read = await ref
          .watch(staffReadCacheProvider)
          .get(
            '/count-submissions/computed',
            query: {'evacuation_event_id': event.id, 'barangay_id': barangayId},
          );
      return ComputedCount.fromJson(read.data);
    });

/// The barangay's final count on the CSWDO side (Part 5): the registered
/// count now, the latest submission and its late entries; for a barangay
/// with no official account, "Submit for this barangay" (online only).
class _CswdFinalCount extends ConsumerWidget {
  const _CswdFinalCount({required this.barangayId, required this.name});

  final int barangayId;
  final String name;

  Future<void> _submit(
    BuildContext context,
    WidgetRef ref,
    ComputedCount count,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (!await ref.read(connectivityServiceProvider).hasConnection) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.cswdSubmitNeedsConnection)),
      );
      return;
    }
    if (!context.mounted) return;
    final c = count.computed;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.cswdSubmitForTitle(name)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.finalCountFigures(
                l10n.countFamilies(c.families),
                l10n.countPersons(c.persons),
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              l10n.finalCountCentersPrivate(
                l10n.countFamilies(c.familiesInside),
                l10n.countFamilies(c.familiesOutside),
              ),
            ),
            if (count.checks.incompleteFamilies > 0)
              Text(
                l10n.finalCountCheckIncomplete(count.checks.incompleteFamilies),
              ),
            if (count.checks.possibleDuplicates > 0)
              Text(
                l10n.finalCountCheckDuplicates(count.checks.possibleDuplicates),
              ),
            const SizedBox(height: 8),
            Text(l10n.cswdSubmitForBody),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.finalCountSubmitShort),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final response = await ref
          .read(staffApiClientProvider)
          .post(
            '/barangays/$barangayId/count-submissions',
            data: {'evacuation_event_id': count.eventId},
          );
      ref.invalidate(barangayComputedProvider(barangayId));
      ref.invalidate(countsNotSentProvider);
      final message = (response.data as Map?)?['message'] as String?;
      messenger.showSnackBar(
        SnackBar(content: Text(message ?? l10n.cswdSubmitForDone(name))),
      );
    } on DioException catch (e) {
      messenger.showSnackBar(failureSnackBar(mapStaffDioError(e)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final session = ref.watch(staffAuthProvider).value;
    final count = ref.watch(barangayComputedProvider(barangayId)).value;
    if (count == null) return const SizedBox.shrink();
    final CountFigures c = count.computed;
    final status = switch (count.submissionStatus) {
      'validated' => l10n.finalCountValidated(
        l10n.countFamilies(count.validatedFamilies ?? 0),
      ),
      'returned' => l10n.finalCountReturned,
      'pending' => l10n.finalCountWaiting,
      _ => l10n.finalCountNotSubmitted,
    };
    final mayOnBehalf =
        (session?.can(StaffPermission.countSubmitOnBehalf) ?? false) &&
        !count.hasOfficialAccount;
    final canSend =
        count.eventActive &&
        !(count.submissionStatus == 'pending' && !count.changedSinceSubmission);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.finalCountTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              l10n.cswdRegisteredNow(
                l10n.countFamilies(c.families),
                l10n.countPersons(c.persons),
              ),
            ),
            Text(
              status,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (count.hasLateEntries)
              Text(l10n.lateEntriesTodo(count.lateEntries!.total)),
            if (count.submittedOnBehalf &&
                (count.submissionNote ?? '').isNotEmpty)
              OnBehalfNote(note: count.submissionNote!),
            const SizedBox(height: 8),
            if (!count.hasOfficialAccount && !mayOnBehalf)
              const SizedBox.shrink()
            else if (count.hasOfficialAccount) ...[
              Text(
                l10n.cswdOfficialSubmits(name),
                style: theme.textTheme.bodySmall,
              ),
              if (count.eventActive &&
                  (count.submissionStatus != 'validated' ||
                      count.hasLateEntries))
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () => remindFinalCount(
                    context,
                    ref,
                    barangayId: barangayId,
                    name: name,
                  ),
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: Text(l10n.cswdRemindFinalCount),
                ),
            ] else if (canSend)
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () => _submit(context, ref, count),
                child: Text(l10n.cswdSubmitForBarangay),
              ),
          ],
        ),
      ),
    );
  }
}
