import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/cache/staff_read_cache.dart';
import '../../../core/utils/data_freshness_formatter.dart';
import '../../../core/widgets/error_state.dart';
import '../../../l10n/app_localizations.dart';
import '../../outbox/domain/pending_action.dart';
import '../../outbox/presentation/outbox_providers.dart';
import '../../staff_auth/presentation/providers/staff_auth_provider.dart';
import '../../staff_shell/current_event.dart';
import '../presentation/barangay_status_card.dart' show barangayStatusColor;

class SituationStatusOption {
  const SituationStatusOption({
    required this.key,
    required this.label,
    required this.maySet,
  });

  final String key;
  final String label;
  final bool maySet;
}

/// The official's barangay in `GET /gis/situation` (backend map-api.md).
class OwnSituation {
  const OwnSituation({
    required this.eventId,
    required this.open,
    required this.status,
    required this.label,
    required this.mayUpdate,
    required this.options,
    this.note,
    this.setBy,
    this.setAt,
  });

  final int? eventId;

  /// False with no event or a closed one: read-only.
  final bool open;
  final String status;
  final String label;
  final String? note;
  final String? setBy;
  final DateTime? setAt;

  /// False under an evacuation order set by CSWD.
  final bool mayUpdate;
  final List<SituationStatusOption> options;

  static OwnSituation? fromJson(Map<String, dynamic> j, int barangayId) {
    final row = [
      for (final b in j['barangays'] as List? ?? const [])
        if (((b as Map<String, dynamic>)['barangay']
                as Map<String, dynamic>?)?['id'] ==
            barangayId)
          b,
    ].firstOrNull;
    if (row == null) return null;
    return OwnSituation(
      eventId: (j['evacuation_event'] as Map<String, dynamic>?)?['id'] as int?,
      open: j['open'] == true,
      status: row['status'] as String? ?? 'normal',
      label: row['label'] as String? ?? 'Normal',
      note: row['note'] as String?,
      setBy: (row['set_by'] as Map<String, dynamic>?)?['name'] as String?,
      setAt: DateTime.tryParse(row['set_at'] as String? ?? '')?.toLocal(),
      mayUpdate: row['may_update'] == true,
      options: [
        for (final s in j['statuses'] as List? ?? const [])
          SituationStatusOption(
            key: (s as Map<String, dynamic>)['key'] as String,
            label: s['label'] as String? ?? s['key'] as String,
            maySet: s['may_set'] == true,
          ),
      ],
    );
  }
}

final ownSituationProvider =
    FutureProvider.autoDispose<
      ({OwnSituation? situation, DateTime fetchedAt, bool fromCache})?
    >((ref) async {
      ref.watch(outboxRevisionProvider);
      final session = await ref.watch(staffAuthProvider.future);
      final event = await ref.watch(currentStaffEventProvider.future);
      final barangayId = session?.barangayId;
      if (barangayId == null) return null;
      final read = await ref
          .watch(staffReadCacheProvider)
          .get('/gis/situation', query: {'evacuation_event_id': ?event?.id});
      return (
        situation: OwnSituation.fromJson(read.data, barangayId),
        fetchedAt: read.fetchedAt,
        fromCache: read.isFromCache,
      );
    });

/// The Barangay tab (C23): the barangay's status in the current event,
/// and the way to change it (Normal / Watch / Flooding reported for an
/// official; evacuation orders are CSWD's). Works offline: a change is
/// queued and sent by the next sync.
class StaffBarangayPage extends ConsumerWidget {
  const StaffBarangayPage({super.key, this.extraSections = const []});

  /// Further sections of the tab (the final count, C23b).
  final List<Widget> extraSections;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final session = ref.watch(staffAuthProvider).value;
    final async = ref.watch(ownSituationProvider);
    final queued = (ref.watch(pendingActionsProvider).value ?? const [])
        .where((a) => a.kind == PendingActionKind.barangayStatus)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          session?.barangayName == null
              ? l10n.staffTabBarangay
              : l10n.residentBarangayStatusOf(session!.barangayName!),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(ownSituationProvider);
          await ref.read(staffSyncAllProvider)();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            const StaffEventBar(),
            const SizedBox(height: 16),
            ...async.when(
              loading: () => [const Center(child: CircularProgressIndicator())],
              error: (_, _) => [
                ErrorState(
                  message: l10n.barangayStatusNeedsConnection,
                  onRetry: () => ref.invalidate(ownSituationProvider),
                ),
              ],
              data: (result) {
                final s = result?.situation;
                if (result == null || s == null) {
                  return [Text(l10n.staffNoOpenEvent)];
                }
                final color = barangayStatusColor(context, s.status);
                return [
                  if (result.fromCache)
                    Text(
                      l10n.savedCopyAge(formatElapsedSince(result.fetchedAt)),
                      style: theme.textTheme.bodySmall,
                    ),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  queued.isEmpty
                                      ? s.label
                                      : queued.last.summary,
                                  style: theme.textTheme.headlineSmall,
                                ),
                              ),
                            ],
                          ),
                          if (queued.isNotEmpty)
                            Text(
                              l10n.syncWaiting,
                              style: theme.textTheme.bodySmall,
                            )
                          else if (s.setAt != null)
                            Text(
                              l10n.barangayStatusSetBy(
                                s.setBy ?? '',
                                DateFormat.yMMMd().add_jm().format(s.setAt!),
                              ),
                              style: theme.textTheme.bodySmall,
                            ),
                          if (s.note != null && s.note!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(s.note!),
                          ],
                          const SizedBox(height: 16),
                          if (!s.open)
                            Text(l10n.barangayStatusReadOnly)
                          else if (!s.mayUpdate)
                            Text(l10n.barangayStatusCswdOrder(s.label))
                          else
                            FilledButton(
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                              ),
                              onPressed: () => showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                showDragHandle: true,
                                builder: (_) => _ChangeStatusSheet(
                                  situation: s,
                                  barangayId: session!.barangayId!,
                                ),
                              ),
                              child: Text(l10n.barangayStatusChange),
                            ),
                        ],
                      ),
                    ),
                  ),
                ];
              },
            ),
            ...extraSections,
          ],
        ),
      ),
    );
  }
}

class _ChangeStatusSheet extends ConsumerStatefulWidget {
  const _ChangeStatusSheet({required this.situation, required this.barangayId});

  final OwnSituation situation;
  final int barangayId;

  @override
  ConsumerState<_ChangeStatusSheet> createState() => _ChangeStatusSheetState();
}

class _ChangeStatusSheetState extends ConsumerState<_ChangeStatusSheet> {
  late String _status = widget.situation.status;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  /// The same status again needs a note (it records an update).
  bool get _valid =>
      _status != widget.situation.status || _note.text.trim().isNotEmpty;

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final option = widget.situation.options.firstWhere((o) => o.key == _status);
    await enqueueStaffAction(
      ref,
      kind: PendingActionKind.barangayStatus,
      method: 'POST',
      path: '/gis/barangay-status',
      body: {
        'evacuation_event_id': widget.situation.eventId,
        'barangay_id': widget.barangayId,
        'status': _status,
        if (_note.text.trim().isNotEmpty) 'note': _note.text.trim(),
      },
      summary: option.label,
      subjectKey: 'barangay:${widget.barangayId}:status',
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.barangayStatusSaved(option.label))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final options = [
      for (final o in widget.situation.options)
        if (o.maySet) o,
    ];
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.barangayStatusChange, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          RadioGroup<String>(
            groupValue: _status,
            onChanged: (v) => setState(() => _status = v ?? _status),
            child: Column(
              children: [
                for (final o in options)
                  RadioListTile<String>(
                    value: o.key,
                    title: Text(o.label),
                    secondary: CircleAvatar(
                      radius: 8,
                      backgroundColor: barangayStatusColor(context, o.key),
                    ),
                  ),
              ],
            ),
          ),
          TextField(
            controller: _note,
            maxLength: 500,
            decoration: InputDecoration(
              labelText: l10n.barangayStatusNote,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: _valid ? _save : null,
            child: Text(l10n.barangayStatusSave),
          ),
        ],
      ),
    );
  }
}
