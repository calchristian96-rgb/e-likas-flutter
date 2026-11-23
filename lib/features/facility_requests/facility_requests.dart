import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../core/network/staff_api_client.dart';
import '../../l10n/app_localizations.dart';
import '../evacuation_centers/presentation/widgets/facility_type_display.dart';
import '../outbox/domain/pending_action.dart';
import '../outbox/presentation/outbox_providers.dart';

/// The 19 facilities checklist types (backend `EvacuationCenterFacility::TYPES`).
const facilityTypes = [
  'latrine_compost_pit',
  'latrine_sealed',
  'toilet_male',
  'toilet_female',
  'toilet_common',
  'bathing_area_male',
  'bathing_area_female',
  'bathing_area_common',
  'handwashing_facility',
  'laundry_space',
  'women_friendly_space',
  'child_friendly_space',
  'health_facility',
  'prayer_room',
  'community_kitchen',
  'livestock_area',
  'camp_management_desk',
  'info_board',
  'storage_area',
];

/// A request to CSWD for what a center is missing (backend step 8).
class FacilityRequest {
  const FacilityRequest({
    required this.id,
    required this.status,
    required this.quantity,
    this.facilityType,
    this.item,
    this.reason,
    this.reviewNote,
  });

  final int id;

  /// pending | approved | sent | received | rejected
  final String status;
  final String? facilityType;
  final String? item;
  final int quantity;
  final String? reason;
  final String? reviewNote;

  factory FacilityRequest.fromJson(Map<String, dynamic> j) => FacilityRequest(
    id: j['id'] as int,
    status: j['status'] as String? ?? 'pending',
    facilityType: j['facility_type'] as String?,
    item: j['item'] as String?,
    quantity: (j['quantity_needed'] as num?)?.toInt() ?? 1,
    reason: j['reason'] as String?,
    reviewNote: j['review_note'] as String?,
  );
}

/// `GET /facility-requests?evacuation_center_id=` (own barangay for an
/// official), waiting first. Refetched after every sync.
final facilityRequestsForCenterProvider = FutureProvider.autoDispose
    .family<List<FacilityRequest>, int>((ref, centerId) async {
      ref.watch(outboxRevisionProvider);
      final response = await ref
          .watch(staffApiClientProvider)
          .get(
            '/facility-requests',
            queryParameters: {'evacuation_center_id': centerId, 'per_page': 50},
          );
      final page =
          (response.data as Map<String, dynamic>)['data']
              as Map<String, dynamic>;
      return [
        for (final r in page['data'] as List? ?? const [])
          FacilityRequest.fromJson(r as Map<String, dynamic>),
      ];
    });

String facilityRequestLabel(BuildContext context, String? type, String? item) =>
    type != null ? localizedFacilityType(context, type) : (item ?? '');

/// The center's facility requests and the way to ask for more (C20).
class FacilityRequestsSection extends ConsumerWidget {
  const FacilityRequestsSection({
    super.key,
    required this.centerId,
    required this.centerName,
    required this.canCreate,
  });

  final int centerId;
  final String centerName;
  final bool canCreate;

  String get _subject => 'center:$centerId:facility';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final requests = ref.watch(facilityRequestsForCenterProvider(centerId));
    final queued = [
      for (final a in ref.watch(pendingActionsProvider).value ?? const [])
        if (a.subjectKey == _subject) a,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.facilityRequestsTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final a in queued)
          _RequestTile(
            title: a.summary,
            status: l10n.syncWaiting,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        requests.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => Text(
            l10n.facilityRequestsNeedConnection,
            style: theme.textTheme.bodySmall,
          ),
          data: (list) => list.isEmpty && queued.isEmpty
              ? Text(
                  l10n.facilityRequestsNone,
                  style: theme.textTheme.bodySmall,
                )
              : Column(
                  children: [
                    for (final r in list)
                      _RequestTile(
                        title:
                            '${facilityRequestLabel(context, r.facilityType, r.item)} × ${r.quantity}',
                        status: _statusLabel(l10n, r.status),
                        color: _statusColor(theme, r.status),
                        note: r.reviewNote,
                      ),
                  ],
                ),
        ),
        if (canCreate) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (_) => _RequestForm(
                centerId: centerId,
                centerName: centerName,
                subjectKey: _subject,
              ),
            ),
            icon: const Icon(Icons.add),
            label: Text(l10n.facilityRequestsAsk),
          ),
        ],
      ],
    );
  }

  static String _statusLabel(AppLocalizations l10n, String status) =>
      switch (status) {
        'approved' => l10n.requestStatusApproved,
        'rejected' => l10n.requestStatusRejected,
        'sent' => l10n.requestStatusSent,
        // `fulfilled` is gone on the server (old rows became received).
        'received' || 'fulfilled' => l10n.requestStatusReceived,
        _ => l10n.requestStatusWaiting,
      };

  static Color _statusColor(ThemeData theme, String status) {
    final semantic = theme.extension<AppSemanticColors>()!;
    return switch (status) {
      'approved' || 'sent' || 'received' || 'fulfilled' => semantic.success,
      'rejected' => theme.colorScheme.error,
      _ => semantic.warning,
    };
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({
    required this.title,
    required this.status,
    required this.color,
    this.note,
  });

  final String title;
  final String status;
  final Color color;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minTileHeight: 48,
      title: Text(title),
      subtitle: note == null ? null : Text(note!),
      trailing: Text(
        status,
        style: theme.textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _RequestForm extends ConsumerStatefulWidget {
  const _RequestForm({
    required this.centerId,
    required this.centerName,
    required this.subjectKey,
  });

  final int centerId;
  final String centerName;
  final String subjectKey;

  @override
  ConsumerState<_RequestForm> createState() => _RequestFormState();
}

class _RequestFormState extends ConsumerState<_RequestForm> {
  static const _other = '__other__';
  String? _type;
  final _item = TextEditingController();
  final _reason = TextEditingController();
  int _quantity = 1;

  @override
  void dispose() {
    _item.dispose();
    _reason.dispose();
    super.dispose();
  }

  bool get _valid =>
      _type != null && (_type != _other || _item.text.trim().isNotEmpty);

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context);
    final isOther = _type == _other;
    final what = isOther
        ? _item.text.trim()
        : localizedFacilityType(context, _type!);
    await enqueueStaffAction(
      ref,
      kind: PendingActionKind.facilityRequest,
      method: 'POST',
      path: '/evacuation-centers/${widget.centerId}/facility-requests',
      body: {
        if (isOther) 'item': _item.text.trim() else 'facility_type': _type,
        'quantity_needed': _quantity,
        if (_reason.text.trim().isNotEmpty) 'reason': _reason.text.trim(),
      },
      summary: l10n.facilityRequestSummary(what, _quantity, widget.centerName),
      subjectKey: widget.subjectKey,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.facilityRequestSent)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
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
            Text(l10n.facilityRequestsAsk, style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _type,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.facilityRequestWhat,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final t in facilityTypes)
                  DropdownMenuItem(
                    value: t,
                    child: Text(localizedFacilityType(context, t)),
                  ),
                DropdownMenuItem(
                  value: _other,
                  child: Text(l10n.facilityRequestOther),
                ),
              ],
              onChanged: (t) => setState(() => _type = t),
            ),
            if (_type == _other) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _item,
                maxLength: 150,
                decoration: InputDecoration(
                  labelText: l10n.facilityRequestItem,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.facilityRequestQuantity,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                IconButton.outlined(
                  tooltip: l10n.decrease,
                  onPressed: _quantity > 1
                      ? () => setState(() => _quantity--)
                      : null,
                  icon: const Icon(Icons.remove),
                ),
                SizedBox(
                  width: 48,
                  child: Text(
                    '$_quantity',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                IconButton.outlined(
                  tooltip: l10n.increase,
                  onPressed: () => setState(() => _quantity++),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reason,
              decoration: InputDecoration(
                labelText: l10n.facilityRequestReason,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: _valid ? _send : null,
              child: Text(l10n.facilityRequestSend),
            ),
          ],
        ),
      ),
    );
  }
}
