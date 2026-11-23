import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../core/cache/staff_read_cache.dart';
import '../../core/connectivity/connectivity_service.dart';
import '../../core/network/staff_api_client.dart';
import '../../core/network/staff_api_error_mapper.dart';
import '../../core/utils/data_freshness_formatter.dart';
import '../../core/widgets/lock_note.dart';
import '../../core/widgets/stat_strip.dart';
import '../../core/widgets/ui_kit.dart';
import '../../l10n/app_localizations.dart';
import '../outbox/domain/pending_action.dart';
import '../outbox/presentation/outbox_providers.dart';
import '../puroks/puroks.dart';
import '../staff_auth/presentation/providers/staff_auth_provider.dart';
import '../staff_evacuation_centers/presentation/providers/own_centers_provider.dart';
import '../staff_shell/current_event.dart';

/// A purok on a listed family: `{id, name, is_high_risk, risk}`.
class ListPurok {
  const ListPurok({
    required this.id,
    required this.name,
    this.isHighRisk = false,
    this.risk,
  });

  factory ListPurok.fromJson(Map<String, dynamic> j) => ListPurok(
    id: (j['id'] as num).toInt(),
    name: j['name'] as String? ?? '',
    isHighRisk: j['is_high_risk'] == true,
    risk: j['risk'] as String?,
  );

  final int id;
  final String name;
  final bool isHighRisk;
  final String? risk;
}

/// One family a barangay expects to move (docs/backend/apps-api-2026-11-22.md
/// section 3). **A listed family is not an evacuee**: it is never in a
/// total, a final count, DROMIC or relief until it is checked in.
class ListedFamily {
  const ListedFamily({
    required this.id,
    required this.head,
    required this.membersCount,
    required this.status,
    this.headFirstName,
    this.headLastName,
    this.headSex,
    this.purok,
    this.contactNumber,
    this.note,
    this.fromPastEvent = false,
    this.familyId,
    this.checkedInAt,
  });

  factory ListedFamily.fromJson(Map<String, dynamic> j) => ListedFamily(
    id: (j['id'] as num).toInt(),
    head: j['head'] as String? ?? '',
    headFirstName: j['head_first_name'] as String?,
    headLastName: j['head_last_name'] as String?,
    headSex: j['head_sex'] as String?,
    membersCount: (j['members_count'] as num?)?.toInt() ?? 1,
    purok: j['purok'] is Map<String, dynamic>
        ? ListPurok.fromJson(j['purok'] as Map<String, dynamic>)
        : null,
    contactNumber: j['contact_number'] as String?,
    note: j['note'] as String?,
    fromPastEvent: j['from_past_event'] == true,
    status: j['status'] as String? ?? 'expected',
    familyId: (j['family_id'] as num?)?.toInt(),
    checkedInAt: DateTime.tryParse(j['checked_in_at'] as String? ?? ''),
  );

  final int id;
  final String head;
  final String? headFirstName;
  final String? headLastName;
  final String? headSex;
  final int membersCount;
  final ListPurok? purok;
  final String? contactNumber;
  final String? note;
  final bool fromPastEvent;

  /// expected | checked_in
  final String status;
  final int? familyId;
  final DateTime? checkedInAt;

  bool get checkedIn => status == 'checked_in';
}

class FamiliesToEvacuate {
  const FamiliesToEvacuate({
    required this.families,
    required this.summaryFamilies,
    required this.summaryPersons,
    required this.summaryCheckedIn,
    required this.canManage,
    required this.canCheckIn,
    required this.eventId,
    required this.fetchedAt,
    required this.fromCache,
  });

  factory FamiliesToEvacuate.fromJson(
    Map<String, dynamic> j, {
    required int? eventId,
    required DateTime fetchedAt,
    required bool fromCache,
  }) {
    final summary = j['summary'] as Map<String, dynamic>? ?? const {};
    final can = j['can'] as Map<String, dynamic>? ?? const {};
    int n(Object? v) => (v as num?)?.toInt() ?? 0;
    return FamiliesToEvacuate(
      families: [
        for (final f in j['families'] as List? ?? const [])
          ListedFamily.fromJson(f as Map<String, dynamic>),
      ],
      summaryFamilies: n(summary['families']),
      summaryPersons: n(summary['persons']),
      summaryCheckedIn: n(summary['checked_in']),
      canManage: can['manage'] == true,
      canCheckIn: can['check_in'] == true,
      eventId:
          (j['evacuation_event'] as Map<String, dynamic>?)?['id'] as int? ??
          eventId,
      fetchedAt: fetchedAt,
      fromCache: fromCache,
    );
  }

  final List<ListedFamily> families;
  final int summaryFamilies;
  final int summaryPersons;
  final int summaryCheckedIn;
  final bool canManage;

  /// Only while the event is Active.
  final bool canCheckIn;
  final int? eventId;
  final DateTime fetchedAt;
  final bool fromCache;

  /// Per purok, high-risk puroks first (the server's order is kept
  /// inside a purok), families without a purok last.
  List<(ListPurok?, List<ListedFamily>)> get byPurok {
    final groups = <int?, List<ListedFamily>>{};
    final puroks = <int?, ListPurok?>{};
    for (final f in families) {
      groups.putIfAbsent(f.purok?.id, () => []).add(f);
      puroks[f.purok?.id] = f.purok;
    }
    final keys = groups.keys.toList()
      ..sort((a, b) {
        final pa = puroks[a];
        final pb = puroks[b];
        if (pa == null) return 1;
        if (pb == null) return -1;
        if (pa.isHighRisk != pb.isHighRisk) return pa.isHighRisk ? -1 : 1;
        return pa.name.toLowerCase().compareTo(pb.name.toLowerCase());
      });
    return [for (final k in keys) (puroks[k], groups[k]!)];
  }
}

/// `GET /families-to-evacuate` for the selected event, saved for
/// offline. Refetched after every sync.
final familiesToEvacuateProvider =
    FutureProvider.autoDispose<FamiliesToEvacuate?>((ref) async {
      ref.watch(outboxRevisionProvider);
      final event = await ref.watch(currentStaffEventProvider.future);
      if (event == null) return null;
      final read = await ref
          .watch(staffReadCacheProvider)
          .get(
            '/families-to-evacuate',
            query: {'evacuation_event_id': event.id},
          );
      return FamiliesToEvacuate.fromJson(
        read.data,
        eventId: event.id,
        fetchedAt: read.fetchedAt,
        fromCache: read.isFromCache,
      );
    });

/// The subject of a queued check-in, so the row shows "Waiting to sync".
String checkInSubject(int listedId) => 'listed:$listedId:check-in';

/// Where a listed family is checked in.
sealed class CheckInPlace {
  const CheckInPlace();
}

class CheckInCenter extends CheckInPlace {
  const CheckInCenter(this.centerId, this.name, {this.pending = false});
  final int centerId;
  final String name;
  final bool pending;
}

class CheckInPrivateHouse extends CheckInPlace {
  const CheckInPrivateHouse({
    required this.hostName,
    this.hostPurokId,
    this.hostAddress,
  });
  final String hostName;
  final int? hostPurokId;
  final String? hostAddress;
}

/// The body of `POST /families-to-evacuate/{id}/check-in`. The queue adds
/// `client_ref` (its own UUID): a retry returns the first answer.
Map<String, dynamic> checkInBody(CheckInPlace place) => switch (place) {
  CheckInCenter(:final centerId) => {'evacuation_center_id': centerId},
  CheckInPrivateHouse(
    :final hostName,
    :final hostPurokId,
    :final hostAddress,
  ) =>
    {
      'host_name': hostName,
      'host_purok_id': ?hostPurokId,
      if (hostPurokId == null) 'host_address': ?hostAddress,
    },
};

/// The queue's subject for a past family being added (one at a time).
String pastFamilySubject(int sourceFamilyId) =>
    'families-to-evacuate:add:past:$sourceFamilyId';

/// `POST /families-to-evacuate`, queued (works offline); the queue adds
/// the row's UUID as `client_ref`.
Future<void> queueListedFamilyAdd(
  WidgetRef ref,
  AppLocalizations l10n, {
  required int eventId,
  required Map<String, dynamic> body,
  required String name,
  String? subjectKey,
}) => enqueueStaffAction(
  ref,
  kind: PendingActionKind.listedFamilyAdd,
  method: 'POST',
  path: '/families-to-evacuate',
  body: {'evacuation_event_id': eventId, ...body},
  summary: l10n.listAddSummary(name),
  subjectKey: subjectKey,
);

/// Check in with one tap: queued (works offline), sent by the next sync.
Future<void> queueCheckIn(
  WidgetRef ref,
  AppLocalizations l10n,
  ListedFamily family,
  CheckInPlace place,
) async {
  await enqueueStaffAction(
    ref,
    kind: PendingActionKind.familyCheckIn,
    method: 'POST',
    path: '/families-to-evacuate/${family.id}/check-in',
    body: checkInBody(place),
    summary: l10n.listedCheckInSummary(family.head, switch (place) {
      CheckInCenter(:final name) => name,
      CheckInPrivateHouse(:final hostName) => l10n.privateHouseWith(hostName),
    }),
    subjectKey: checkInSubject(family.id),
  );
}

/// Families to evacuate (officials, while the event is Monitoring or
/// Active): the list per purok, add from past events or new, mark
/// high-risk puroks, and Check in with one tap once Active.
class FamiliesToEvacuatePage extends ConsumerWidget {
  const FamiliesToEvacuatePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final async = ref.watch(familiesToEvacuateProvider);
    final pending = ref.watch(pendingActionsProvider).value ?? const [];
    final queued = {for (final a in pending) ?a.subjectKey};
    final queuedAdds = [
      for (final a in pending)
        if (a.kind == PendingActionKind.listedFamilyAdd) a,
    ];
    final data = async.value;
    final event = ref.watch(currentStaffEventProvider).value;
    final barangayId = ref.watch(staffAuthProvider).value?.barangayId;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.listTitle),
        actions: [
          if (barangayId != null && (data?.canManage ?? false))
            IconButton(
              tooltip: l10n.listHighRiskPuroks,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => HighRiskPuroksPage(barangayId: barangayId),
                ),
              ),
              icon: const Icon(Icons.warning_amber_outlined),
            ),
        ],
      ),
      floatingActionButton: (data?.canManage ?? false) && event != null
          ? FloatingActionButton.extended(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                builder: (_) => AddListedFamilySheet(eventId: event.id),
              ),
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: Text(l10n.listAdd),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(familiesToEvacuateProvider);
          await ref.read(staffSyncAllProvider)();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: pagePadding(context).copyWith(bottom: 96),
          children: [
            const StaffEventBar(),
            const SizedBox(height: 8),
            Text(l10n.listNotEvacuees, style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            ...async.when(
              loading: () => [const Center(child: CircularProgressIndicator())],
              error: (_, _) => [
                EmptyNote(
                  icon: Icons.cloud_off_outlined,
                  message: l10n.monitoringNeedsConnection,
                ),
              ],
              data: (d) {
                if (d == null) return [Text(l10n.staffNoOpenEvent)];
                return [
                  if (d.fromCache)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        l10n.savedCopyAge(formatElapsedSince(d.fetchedAt)),
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  StatStrip(
                    items: [
                      StatItem(l10n.monitoringFamilies, '${d.summaryFamilies}'),
                      StatItem(l10n.monitoringPersons, '${d.summaryPersons}'),
                      StatItem(l10n.listCheckedIn, '${d.summaryCheckedIn}'),
                    ],
                  ),
                  if (!d.canCheckIn && d.families.any((f) => !f.checkedIn)) ...[
                    const SizedBox(height: 12),
                    const LockNote(dense: true),
                  ],
                  if (queuedAdds.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      l10n.listAddsWaiting,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    for (final a in queuedAdds)
                      Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          minTileHeight: 56,
                          leading: const Icon(Icons.cloud_upload_outlined),
                          title: Text(a.summary),
                          subtitle: Text(
                            a.needsAttention
                                ? (a.lastErrorMessage ?? l10n.syncWaiting)
                                : l10n.syncWaiting,
                          ),
                        ),
                      ),
                  ],
                  if (d.families.isEmpty && queuedAdds.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: EmptyNote(
                        icon: Icons.checklist_outlined,
                        message: l10n.planListAdd,
                      ),
                    ),
                  for (final (purok, families) in d.byPurok) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            purok?.name ?? l10n.purokNone,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        if (purok?.isHighRisk ?? false)
                          StatusChip(
                            label: l10n.listHighRisk,
                            color: theme.colorScheme.error,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    for (final f in families)
                      _ListedFamilyTile(
                        family: f,
                        canCheckIn: d.canCheckIn,
                        canManage: d.canManage,
                        queued: queued.contains(checkInSubject(f.id)),
                      ),
                  ],
                ];
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ListedFamilyTile extends ConsumerWidget {
  const _ListedFamilyTile({
    required this.family,
    required this.canCheckIn,
    required this.canManage,
    required this.queued,
  });

  final ListedFamily family;
  final bool canCheckIn;
  final bool canManage;
  final bool queued;

  Future<void> _checkIn(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final place = await showModalBottomSheet<CheckInPlace>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => CheckInPlaceSheet(family: family),
    );
    if (place == null) return;
    await queueCheckIn(ref, l10n, family, place);
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.listCheckInQueued(family.head))),
    );
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (!await ref.read(connectivityServiceProvider).hasConnection) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.listNeedsConnection)));
      return;
    }
    if (!context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.listRemoveTitle(family.head)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.listRemove),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(staffApiClientProvider)
          .delete('/families-to-evacuate/${family.id}');
      ref.invalidate(familiesToEvacuateProvider);
    } on DioException catch (e) {
      // Removed already (apps-api-2026-11-24.md 5.4): done.
      if (e.response?.statusCode == 404) {
        ref.invalidate(familiesToEvacuateProvider);
        return;
      }
      messenger.showSnackBar(failureSnackBar(mapStaffDioError(e)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final semantic = theme.extension<AppSemanticColors>()!;
    final Widget trailing;
    if (family.checkedIn) {
      trailing = Text(
        l10n.listCheckedInTag,
        style: theme.textTheme.labelMedium?.copyWith(
          color: semantic.success,
          fontWeight: FontWeight.w600,
        ),
      );
    } else if (queued) {
      trailing = Text(l10n.syncWaiting, style: theme.textTheme.labelMedium);
    } else if (canCheckIn) {
      trailing = FilledButton(
        style: FilledButton.styleFrom(minimumSize: const Size(96, 48)),
        onPressed: () => _checkIn(context, ref),
        child: Text(l10n.listCheckIn),
      );
    } else {
      trailing = Icon(
        Icons.lock_outline,
        color: theme.colorScheme.onSurfaceVariant,
        semanticLabel: l10n.lockAvailableWhenActive,
      );
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        minTileHeight: 64,
        leading: Icon(
          family.checkedIn || queued
              ? Icons.check_circle
              : Icons.radio_button_unchecked,
          color: family.checkedIn
              ? semantic.success
              : theme.colorScheme.onSurfaceVariant,
        ),
        title: Text(family.head),
        subtitle: Text(
          [
            l10n.ecBoardFamilyMembers(family.membersCount),
            if (family.fromPastEvent) l10n.listFromPastEvent,
            if ((family.contactNumber ?? '').isNotEmpty) family.contactNumber!,
            if ((family.note ?? '').isNotEmpty) family.note!,
          ].join(' · '),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            trailing,
            if (canManage && !family.checkedIn && !queued)
              MoreButton(
                title: family.head,
                actions: [
                  SheetAction(
                    label: l10n.listRemove,
                    icon: Icons.delete_outline,
                    destructive: true,
                    onTap: () => _remove(context, ref),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Where to check the family in: one of the barangay's own centers (a
/// pending one carries "Pending CSWD approval"), or a private house.
class CheckInPlaceSheet extends ConsumerStatefulWidget {
  const CheckInPlaceSheet({super.key, required this.family});

  final ListedFamily family;

  @override
  ConsumerState<CheckInPlaceSheet> createState() => _CheckInPlaceSheetState();
}

class _CheckInPlaceSheetState extends ConsumerState<CheckInPlaceSheet> {
  bool _private = false;
  final _host = TextEditingController();
  final _address = TextEditingController();
  int? _hostPurokId;

  @override
  void dispose() {
    _host.dispose();
    _address.dispose();
    super.dispose();
  }

  bool get _privateValid =>
      _host.text.trim().isNotEmpty &&
      (_hostPurokId != null || _address.text.trim().isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final centers = [
      for (final c
          in ref.watch(ownCentersProvider).value ?? const <OwnCenter>[])
        if (c.center.isUsable && c.center.status != 'closed') c,
    ];
    final barangayId = ref.watch(staffAuthProvider).value?.barangayId;
    final puroks = barangayId == null
        ? const <Purok>[]
        : ref.watch(puroksForBarangayProvider(barangayId)).value ??
              const <Purok>[];
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.listCheckInTitle(widget.family.head),
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, label: Text(l10n.listAtCenter)),
                ButtonSegment(
                  value: true,
                  label: Text(l10n.registerPrivateHouse),
                ),
              ],
              selected: {_private},
              onSelectionChanged: (s) => setState(() => _private = s.first),
            ),
            const SizedBox(height: 12),
            if (!_private) ...[
              if (centers.isEmpty) Text(l10n.staffOwnCentersEmpty),
              for (final c in centers)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  minTileHeight: 56,
                  leading: const Icon(Icons.home_work_outlined),
                  title: Text(c.name),
                  subtitle: c.center.isPending
                      ? Text(
                          l10n.pendingCswdApproval,
                          style: TextStyle(
                            color: theme
                                .extension<AppSemanticColors>()!
                                .warning,
                          ),
                        )
                      : null,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).pop(
                    CheckInCenter(c.id, c.name, pending: c.center.isPending),
                  ),
                ),
            ] else ...[
              TextField(
                controller: _host,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: l10n.listHostName,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              if (puroks.isNotEmpty)
                DropdownButtonFormField<int?>(
                  initialValue: _hostPurokId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.listHostPurok,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l10n.purokNone)),
                    for (final p in puroks)
                      DropdownMenuItem(value: p.id, child: Text(p.name)),
                  ],
                  onChanged: (v) => setState(() => _hostPurokId = v),
                ),
              if (_hostPurokId == null) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _address,
                  decoration: InputDecoration(
                    labelText: l10n.listHostAddress,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: _privateValid
                    ? () => Navigator.of(context).pop(
                        CheckInPrivateHouse(
                          hostName: _host.text.trim(),
                          hostPurokId: _hostPurokId,
                          hostAddress: _address.text.trim().isEmpty
                              ? null
                              : _address.text.trim(),
                        ),
                      )
                    : null,
                child: Text(l10n.listCheckIn),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A family from a past (closed) event that can be listed again.
class PastFamily {
  const PastFamily({
    required this.id,
    required this.head,
    required this.membersCount,
    this.purok,
    this.lastEvent,
  });

  factory PastFamily.fromJson(Map<String, dynamic> j) => PastFamily(
    id: ((j['source_family_id'] ?? j['id']) as num).toInt(),
    head: (j['head'] ?? j['label'] ?? '') as String,
    membersCount:
        ((j['members_count'] ?? j['member_count']) as num?)?.toInt() ?? 1,
    purok: (j['purok'] as Map<String, dynamic>?)?['name'] as String?,
    lastEvent:
        (j['evacuation_event'] as Map<String, dynamic>?)?['name'] as String? ??
        j['event_name'] as String?,
  );

  final int id;
  final String head;
  final int membersCount;
  final String? purok;
  final String? lastEvent;
}

/// Add a family to the list: from a past event (head and members come
/// from that record) or new. Online only: the server has no duplicate
/// protection for adding.
class AddListedFamilySheet extends ConsumerStatefulWidget {
  const AddListedFamilySheet({super.key, required this.eventId});

  final int eventId;

  @override
  ConsumerState<AddListedFamilySheet> createState() =>
      _AddListedFamilySheetState();
}

class _AddListedFamilySheetState extends ConsumerState<AddListedFamilySheet> {
  bool _past = true;
  final _search = TextEditingController();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _contact = TextEditingController();
  final _note = TextEditingController();
  String? _sex;
  int _members = 1;
  int? _purokId;
  List<PastFamily>? _results;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_search, _first, _last, _contact, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _find() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final response = await ref
          .read(staffApiClientProvider)
          .get(
            '/families-to-evacuate/past-families',
            queryParameters: {'search': _search.text.trim()},
          );
      final data = (response.data as Map<String, dynamic>)['data'];
      final rows = data is List
          ? data
          : (data as Map<String, dynamic>)['families'] as List? ?? const [];
      setState(
        () => _results = [
          for (final r in rows) PastFamily.fromJson(r as Map<String, dynamic>),
        ],
      );
    } on DioException catch (e) {
      setState(() => _error = mapStaffDioError(e).message);
    } catch (_) {
      setState(() => _error = l10n.listNeedsConnection);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Queued with its own client_ref (apps-api-2026-11-24.md 5.2), so it
  /// works offline and a retry lists the family once. [name] is for the
  /// Sync screen.
  Future<void> _add(Map<String, dynamic> body, String name) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    final source = body['source_family_id'];
    await queueListedFamilyAdd(
      ref,
      l10n,
      eventId: widget.eventId,
      body: body,
      name: name,
      subjectKey: source == null ? null : pastFamilySubject(source as int),
    );
    if (!mounted) return;
    navigator.pop();
    messenger.showSnackBar(SnackBar(content: Text(l10n.listAddQueued)));
  }

  bool get _newValid =>
      _first.text.trim().isNotEmpty && _last.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final barangayId = ref.watch(staffAuthProvider).value?.barangayId;
    final puroks = barangayId == null
        ? const <Purok>[]
        : ref.watch(puroksForBarangayProvider(barangayId)).value ??
              const <Purok>[];
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.listAdd, style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: true, label: Text(l10n.listFromPast)),
                ButtonSegment(value: false, label: Text(l10n.listNewFamily)),
              ],
              selected: {_past},
              onSelectionChanged: (s) => setState(() => _past = s.first),
            ),
            const SizedBox(height: 12),
            if (_error != null) ...[
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              const SizedBox(height: 8),
            ],
            if (_past) ...[
              TextField(
                controller: _search,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _find(),
                decoration: InputDecoration(
                  labelText: l10n.listSearchPast,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    tooltip: l10n.listSearchPast,
                    onPressed: _busy ? null : _find,
                    icon: const Icon(Icons.search),
                  ),
                ),
              ),
              if (_busy) const LinearProgressIndicator(),
              if (_results != null && _results!.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(l10n.listNoPastFamilies),
                ),
              for (final f in _results ?? const <PastFamily>[])
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  minTileHeight: 56,
                  title: Text(f.head),
                  subtitle: Text(
                    [
                      l10n.ecBoardFamilyMembers(f.membersCount),
                      ?f.purok,
                      ?f.lastEvent,
                    ].join(' · '),
                  ),
                  trailing: const Icon(Icons.add),
                  onTap: _busy
                      ? null
                      : () => _add({'source_family_id': f.id}, f.head),
                ),
            ] else ...[
              TextField(
                controller: _first,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: l10n.listHeadFirstName,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _last,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: l10n.listHeadLastName,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              SegmentedButton<String?>(
                emptySelectionAllowed: true,
                segments: [
                  ButtonSegment(
                    value: 'female',
                    label: Text(l10n.staffRegSexFemale),
                  ),
                  ButtonSegment(
                    value: 'male',
                    label: Text(l10n.staffRegSexMale),
                  ),
                ],
                selected: {?_sex},
                onSelectionChanged: (s) =>
                    setState(() => _sex = s.isEmpty ? null : s.first),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.listMembersCount,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                  IconButton.outlined(
                    tooltip: l10n.decrease,
                    onPressed: _members > 1
                        ? () => setState(() => _members--)
                        : null,
                    icon: const Icon(Icons.remove),
                  ),
                  SizedBox(
                    width: 48,
                    child: Text(
                      '$_members',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  IconButton.outlined(
                    tooltip: l10n.increase,
                    onPressed: _members < 30
                        ? () => setState(() => _members++)
                        : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              if (puroks.isNotEmpty) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  initialValue: _purokId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.listPurok,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l10n.purokNone)),
                    for (final p in puroks)
                      DropdownMenuItem(value: p.id, child: Text(p.name)),
                  ],
                  onChanged: (v) => setState(() => _purokId = v),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _contact,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: l10n.listContactNumber,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _note,
                decoration: InputDecoration(
                  labelText: l10n.listNote,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: _newValid && !_busy
                    ? () => _add({
                        'head_first_name': _first.text.trim(),
                        'head_last_name': _last.text.trim(),
                        'head_sex': ?_sex,
                        'members_count': _members,
                        'purok_id': ?_purokId,
                        if (_contact.text.trim().isNotEmpty)
                          'contact_number': _contact.text.trim(),
                        if (_note.text.trim().isNotEmpty)
                          'note': _note.text.trim(),
                      }, '${_first.text.trim()} ${_last.text.trim()}')
                    : null,
                child: Text(l10n.listAdd),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A purok with its high-risk marks (`PATCH /puroks/{id}`
/// `high_risk_flood`, `high_risk_landslide`).
class RiskPurok {
  const RiskPurok({
    required this.id,
    required this.name,
    this.flood = false,
    this.landslide = false,
  });

  final int id;
  final String name;
  final bool flood;
  final bool landslide;
}

final riskPuroksProvider = FutureProvider.autoDispose
    .family<List<RiskPurok>, int>((ref, barangayId) async {
      final response = await ref
          .watch(staffApiClientProvider)
          .get('/puroks', queryParameters: {'barangay_id': barangayId});
      return [
        for (final p
            in (response.data as Map<String, dynamic>)['data'] as List? ??
                const [])
          RiskPurok(
            id: ((p as Map<String, dynamic>)['id'] as num).toInt(),
            name: p['name'] as String? ?? '',
            flood: p['high_risk_flood'] == true,
            landslide: p['high_risk_landslide'] == true,
          ),
      ];
    });

/// Mark high-risk puroks (flood / landslide): online only, one switch per
/// mark. High-risk puroks come first on the list.
class HighRiskPuroksPage extends ConsumerWidget {
  const HighRiskPuroksPage({super.key, required this.barangayId});

  final int barangayId;

  Future<void> _set(
    BuildContext context,
    WidgetRef ref,
    RiskPurok p,
    String key,
    bool value,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(staffApiClientProvider)
          .patch('/puroks/${p.id}', data: {key: value});
      ref.invalidate(riskPuroksProvider(barangayId));
      ref.invalidate(familiesToEvacuateProvider);
    } on DioException catch (e) {
      messenger.showSnackBar(failureSnackBar(mapStaffDioError(e)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(riskPuroksProvider(barangayId));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.listHighRiskPuroks)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: EmptyNote(
            icon: Icons.cloud_off_outlined,
            message: l10n.listNeedsConnection,
          ),
        ),
        data: (puroks) => ListView(
          padding: pagePadding(context),
          children: [
            Text(l10n.listHighRiskHint),
            const SizedBox(height: 8),
            for (final p in puroks)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Text(
                        p.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    SwitchListTile(
                      title: Text(l10n.listRiskFlood),
                      value: p.flood,
                      onChanged: (v) =>
                          _set(context, ref, p, 'high_risk_flood', v),
                    ),
                    SwitchListTile(
                      title: Text(l10n.listRiskLandslide),
                      value: p.landslide,
                      onChanged: (v) =>
                          _set(context, ref, p, 'high_risk_landslide', v),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
