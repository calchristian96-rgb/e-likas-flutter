import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cache/staff_read_cache.dart';
import '../../core/connectivity/connectivity_service.dart';
import '../../core/network/staff_api_client.dart';
import '../../core/network/staff_api_error_mapper.dart';
import '../../core/utils/data_freshness_formatter.dart';
import '../../core/widgets/ui_kit.dart';
import '../../l10n/app_localizations.dart';
import '../home/presentation/providers/home_provider.dart';
import '../staff_shell/current_event.dart';
import '../../core/widgets/lock_note.dart';
import '../../core/utils/formatters.dart';
import '../staff_shell/event_lock.dart';

/// One family in a request. The receiving barangay gets only the head's
/// name and the number of members (no id): privacy, backend df031fe.
class TransferFamily {
  const TransferFamily({required this.head, required this.members, this.id});

  final int? id;
  final String head;
  final int members;
}

/// A request to move families to another barangay's center
/// (\`GET /transfer-requests\` row, docs/backend/apps-api-2026-11-transfers-capacity.md 4.5).
class TransferRequest {
  const TransferRequest({
    required this.id,
    required this.status,
    required this.direction,
    required this.fromCenter,
    required this.toCenter,
    required this.fromBarangay,
    required this.toBarangay,
    required this.families,
    required this.persons,
    required this.familyList,
    required this.mayDecide,
    this.note,
    this.requestedBy,
    this.requestedAt,
    this.decidedBy,
    this.decidedAt,
    this.decidedAs,
    this.declineReason,
    this.escalatedAt,
    this.waitingMinutes,
  });

  factory TransferRequest.fromJson(Map<String, dynamic> j) {
    String name(Object? m) =>
        (m as Map<String, dynamic>?)?['name'] as String? ?? '';
    DateTime? time(String k) => DateTime.tryParse(j[k] as String? ?? '');
    return TransferRequest(
      id: j['id'] as int,
      status: j['status'] as String? ?? 'pending',
      direction: j['direction'] as String? ?? 'all',
      fromCenter: name(j['from_center']),
      toCenter: name(j['to_center']),
      fromBarangay: name(j['from_barangay']),
      toBarangay: name(j['to_barangay']),
      families: (j['families'] as num?)?.toInt() ?? 0,
      persons: (j['persons'] as num?)?.toInt() ?? 0,
      familyList: [
        for (final f in j['family_list'] as List? ?? const [])
          TransferFamily(
            id: (f as Map<String, dynamic>)['id'] as int?,
            head: f['head'] as String? ?? '',
            members: (f['members'] as num?)?.toInt() ?? 0,
          ),
      ],
      note: j['note'] as String?,
      requestedBy:
          (j['requested_by'] as Map<String, dynamic>?)?['name'] as String?,
      requestedAt: time('requested_at'),
      decidedBy: (j['decided_by'] as Map<String, dynamic>?)?['name'] as String?,
      decidedAt: time('decided_at'),
      decidedAs: j['decided_as'] as String?,
      declineReason: j['decline_reason'] as String?,
      escalatedAt: time('escalated_at'),
      waitingMinutes: (j['waiting_minutes'] as num?)?.toInt(),
      mayDecide: j['may_decide'] == true,
    );
  }

  final int id;

  /// pending | accepted | declined
  final String status;

  /// incoming (to my barangay) | outgoing (sent by my barangay) | all (CSWD)
  final String direction;
  final String fromCenter;
  final String toCenter;
  final String fromBarangay;
  final String toBarangay;
  final int families;
  final int persons;
  final List<TransferFamily> familyList;
  final String? note;

  /// Null for a demo request (docs 4.5): show the sending barangay.
  final String? requestedBy;
  final DateTime? requestedAt;
  final String? decidedBy;
  final DateTime? decidedAt;

  /// receiving_official | cswd
  final String? decidedAs;
  final String? declineReason;

  /// When CSWD was told it had waited 30 minutes (still answerable).
  final DateTime? escalatedAt;
  final int? waitingMinutes;

  /// This user may accept or decline it now (hidden while offline).
  final bool mayDecide;

  bool get isPending => status == 'pending';
  bool get isEscalated => isPending && escalatedAt != null;

  /// Who sent it: the requester, or for a demo request (no requester)
  /// the sending barangay.
  String get sender =>
      (requestedBy ?? '').trim().isNotEmpty ? requestedBy! : fromBarangay;
}

class TransferRequests {
  const TransferRequests({
    required this.requests,
    required this.pending,
    required this.fetchedAt,
    required this.fromCache,
    this.incomingPending,
  });

  final List<TransferRequest> requests;
  final int pending;

  /// Requests to the official's barangay waiting for an answer; null for
  /// CSWD.
  final int? incomingPending;
  final DateTime fetchedAt;
  final bool fromCache;
}

/// \`GET /transfer-requests\` for the selected event: saved for offline
/// display only (every answer needs a connection).
final transferRequestsProvider = FutureProvider.autoDispose<TransferRequests>((
  ref,
) async {
  final event = await ref.watch(currentStaffEventProvider.future);
  final read = await ref
      .watch(staffReadCacheProvider)
      .get('/transfer-requests', query: {'evacuation_event_id': ?event?.id});
  final counts = read.data['counts'] as Map<String, dynamic>? ?? const {};
  return TransferRequests(
    requests: [
      for (final r in read.data['requests'] as List? ?? const [])
        TransferRequest.fromJson(r as Map<String, dynamic>),
    ],
    pending: (counts['pending'] as num?)?.toInt() ?? 0,
    incomingPending: (counts['incoming_pending'] as num?)?.toInt(),
    fetchedAt: read.fetchedAt,
    fromCache: read.isFromCache,
  );
});

/// Online right now (Accept, Decline and sending are hidden or refused
/// without a connection; nothing is queued).
final transfersOnlineProvider = Provider.autoDispose<bool>(
  (ref) => ref.watch(connectivityStatusProvider).value ?? false,
);

Color transferStatusColor(TransferRequest r) => switch (r.status) {
  'accepted' => const Color(0xFF15803D),
  'declined' => const Color(0xFF374151),
  _ => r.isEscalated ? const Color(0xFFDC2626) : const Color(0xFFB45309),
};

String transferStatusLabel(AppLocalizations l10n, TransferRequest r) =>
    switch (r.status) {
      'accepted' => l10n.transferAccepted,
      'declined' => l10n.transferDeclined,
      _ => r.isEscalated ? l10n.transferEscalated : l10n.transferPending,
    };

/// The Transfers screen: requests to and from my barangay (CSWD: all),
/// pending first. Accept / Decline behind may_decide, a confirm dialog,
/// and a connection.
class TransfersPage extends ConsumerStatefulWidget {
  const TransfersPage({super.key});

  @override
  ConsumerState<TransfersPage> createState() => _TransfersPageState();
}

class _TransfersPageState extends ConsumerState<TransfersPage> {
  String? _status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final async = ref.watch(transferRequestsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.transfersTitle)),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(transferRequestsProvider),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: pagePadding(context),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (value, label) in [
                  (null, l10n.transfersAll),
                  ('pending', l10n.transferPending),
                  ('accepted', l10n.transferAccepted),
                  ('declined', l10n.transferDeclined),
                ])
                  ChoiceChip(
                    label: Text(label),
                    selected: _status == value,
                    onSelected: (_) => setState(() => _status = value),
                  ),
              ],
            ),
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
                final shown = [
                  for (final r in d.requests)
                    if (_status == null || r.status == _status) r,
                ];
                return [
                  if (d.fromCache)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        l10n.savedCopyAge(formatElapsedSince(d.fetchedAt)),
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  if (shown.isEmpty)
                    EmptyNote(
                      icon: Icons.swap_horiz,
                      message: l10n.transfersNone,
                    )
                  else
                    for (final r in shown) ...[
                      TransferCard(request: r),
                      const SizedBox(height: 8),
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

class TransferCard extends ConsumerWidget {
  const TransferCard({super.key, required this.request});

  final TransferRequest request;

  Future<void> _answer(
    BuildContext context,
    WidgetRef ref, {
    required bool accept,
  }) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final r = request;
    String? reason;
    if (accept) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.transferAcceptTitle),
          content: Text(
            l10n.transferMoveSummary(
              l10n.countFamilies(r.families),
              l10n.countPersons(r.persons),
              r.fromCenter,
              r.toCenter,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.transferAccept),
            ),
          ],
        ),
      );
      if (ok != true) return;
    } else {
      reason = await showDialog<String>(
        context: context,
        builder: (context) => _DeclineDialog(request: r),
      );
      if (reason == null) return;
    }
    if (!await ref.read(connectivityServiceProvider).hasConnection) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.transferNeedsConnection)),
      );
      return;
    }
    try {
      final response = await ref
          .read(staffApiClientProvider)
          .post(
            '/transfer-requests/${r.id}/${accept ? 'accept' : 'decline'}',
            data: accept ? null : {'reason': reason},
          );
      final message = (response.data as Map?)?['message'] as String?;
      messenger.showSnackBar(SnackBar(content: Text(message ?? '')));
    } on DioException catch (e) {
      messenger.showSnackBar(failureSnackBar(mapStaffDioError(e)));
    }
    // Answered here or already by someone else: read the list again.
    ref.invalidate(transferRequestsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final online = ref.watch(transfersOnlineProvider);
    final r = request;
    String at(DateTime? t) => t == null ? '' : formatShortDateTime(t);
    return AppCard(
      highlight: r.isPending && r.mayDecide,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(switch (r.direction) {
                  'incoming' => l10n.transferIncoming(r.fromBarangay),
                  'outgoing' => l10n.transferOutgoing(r.toBarangay),
                  _ => l10n.transferBetween(r.fromBarangay, r.toBarangay),
                }, style: theme.textTheme.titleMedium),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: StatusChip(
                  label: transferStatusLabel(l10n, r),
                  color: transferStatusColor(r),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.transferMoveSummary(
              l10n.countFamilies(r.families),
              l10n.countPersons(r.persons),
              r.fromCenter,
              r.toCenter,
            ),
          ),
          for (final f in r.familyList)
            Text(
              l10n.transferFamilyLine(f.head, l10n.countPersons(f.members)),
              style: theme.textTheme.bodyMedium,
            ),
          if ((r.note ?? '').isNotEmpty) Text(l10n.transferReasonLine(r.note!)),
          const SizedBox(height: 4),
          Text(
            l10n.transferRequestedBy(r.sender, at(r.requestedAt)),
            style: theme.textTheme.bodySmall,
          ),
          if (r.isPending && r.waitingMinutes != null)
            Text(
              l10n.waitingDuration(
                formatDuration(l10n, Duration(minutes: r.waitingMinutes!)),
              ),
              style: theme.textTheme.bodySmall,
            ),
          if (r.isEscalated)
            Text(
              l10n.transferEscalatedNote(at(r.escalatedAt)),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          if (!r.isPending)
            Text(
              l10n.transferDecidedBy(
                r.decidedAs == 'cswd'
                    ? l10n.transferByCswd(r.decidedBy ?? '')
                    : r.decidedBy ?? '',
                at(r.decidedAt),
              ),
              style: theme.textTheme.bodySmall,
            ),
          if (r.status == 'declined' && (r.declineReason ?? '').isNotEmpty)
            Text(l10n.transferDeclineReasonLine(r.declineReason!)),
          if (r.isPending && r.mayDecide) ...[
            const SizedBox(height: 12),
            if (ref.watch(eventMonitoredProvider))
              const LockNote(dense: true)
            else if (!online)
              Text(
                l10n.transferNeedsConnection,
                style: theme.textTheme.bodySmall,
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed: () => _answer(context, ref, accept: false),
                      child: Text(l10n.transferDecline),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed: () => _answer(context, ref, accept: true),
                      child: Text(l10n.transferAccept),
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

/// Decline needs a reason, 3 to 500 characters (the sender chooses
/// another center).
class _DeclineDialog extends StatefulWidget {
  const _DeclineDialog({required this.request});

  final TransferRequest request;

  @override
  State<_DeclineDialog> createState() => _DeclineDialogState();
}

class _DeclineDialogState extends State<_DeclineDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final r = widget.request;
    final ok = _reason.text.trim().length >= 3;
    return AlertDialog(
      title: Text(l10n.transferDeclineTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.transferMoveSummary(
              l10n.countFamilies(r.families),
              l10n.countPersons(r.persons),
              r.fromCenter,
              r.toCenter,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reason,
            maxLength: 500,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: l10n.transferDeclineReason,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: ok
              ? () => Navigator.of(context).pop(_reason.text.trim())
              : null,
          child: Text(l10n.transferDecline),
        ),
      ],
    );
  }
}

/// "Transfers: 1 waiting for your answer", one tap from the screen.
class TransfersCard extends ConsumerWidget {
  const TransfersCard({super.key, required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final d = ref.watch(transferRequestsProvider).value;
    final waiting = d == null ? 0 : (d.incomingPending ?? d.pending);
    return AppCard(
      highlight: waiting > 0,
      onTap: onOpen,
      child: Row(
        children: [
          Icon(Icons.swap_horiz, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.transfersTitle, style: theme.textTheme.titleMedium),
                Text(
                  waiting > 0
                      ? l10n.transfersWaitingAnswer(waiting)
                      : l10n.transfersSubtitle,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}
