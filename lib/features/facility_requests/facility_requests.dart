import '../../core/widgets/map_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/staff_api_client.dart';
import '../../l10n/app_localizations.dart';
import '../evacuation_centers/presentation/widgets/facility_type_display.dart';
import '../outbox/domain/pending_action.dart';
import '../outbox/presentation/outbox_providers.dart';
import '../../core/utils/formatters.dart';

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
    this.unit,
    this.quantityApproved,
    this.mayReceive = false,
    this.centerId,
    this.centerName,
  });

  /// e.g. "pieces", "boxes" (sent with the request).
  final String? unit;

  /// Approving fewer than asked needs a note: "Approved 6 of 10".
  final int? quantityApproved;

  /// The center's barangay may mark a sent request as received.
  final bool mayReceive;
  final int? centerId;
  final String? centerName;

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
    unit: j['unit'] as String?,
    quantityApproved: (j['quantity_approved'] as num?)?.toInt(),
    mayReceive: j['may_receive'] == true,
    centerId:
        (j['evacuation_center_id'] as num?)?.toInt() ??
        ((j['evacuation_center'] as Map<String, dynamic>?)?['id'] as num?)
            ?.toInt(),
    centerName:
        (j['evacuation_center'] as Map<String, dynamic>?)?['name'] as String?,
  );

  /// "Toilet × 10 pieces".
  String quantityText(BuildContext context, AppLocalizations l10n) =>
      '${facilityRequestLabel(context, facilityType, item)} × '
      '${unit == null || unit!.isEmpty ? formatCount(quantity) : l10n.quantityWithUnit(formatCount(quantity), unit!)}';

  /// "Approved 6 of 10" when fewer were approved than asked.
  String? approvedOf(AppLocalizations l10n) =>
      quantityApproved != null && quantityApproved! < quantity
      ? l10n.facilityApprovedOf(
          formatCount(quantityApproved),
          formatCount(quantity),
        )
      : null;

  bool get finished =>
      status == 'received' || status == 'fulfilled' || status == 'rejected';
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
                      FacilityRequestTile(
                        request: r,
                        centerName: centerName,
                        canCreate: canCreate,
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
            onPressed: () => showFacilityRequestForm(
              context,
              centerId: centerId,
              centerName: centerName,
            ),
            icon: const Icon(Icons.add),
            label: Text(l10n.facilityRequestsAsk),
          ),
        ],
      ],
    );
  }

  static String statusLabel(AppLocalizations l10n, String status) =>
      switch (status) {
        'approved' => l10n.requestStatusApproved,
        'rejected' => l10n.requestStatusRejected,
        'sent' => l10n.requestStatusSent,
        // `fulfilled` is gone on the server (old rows became received).
        'received' || 'fulfilled' => l10n.requestStatusReceived,
        _ => l10n.requestStatusWaiting,
      };

  /// The web's badge tone: approved/sent/received green, rejected red,
  /// waiting amber.
  static BadgeTone statusTone(String status) => switch (status) {
    'approved' || 'sent' || 'received' || 'fulfilled' => BadgeTone.success,
    'rejected' => BadgeTone.danger,
    _ => BadgeTone.warning,
  };
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({
    required this.title,
    required this.status,
    required this.color,
  });

  final String title;
  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minTileHeight: 48,
      title: Text(title),
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

/// One facility request: what, how many and the unit, its status
/// (Waiting, Approved, Sent, Received, Rejected), "Approved 6 of 10",
/// and its actions: Mark received (the center's barangay, once sent),
/// Request again (a received or rejected request).
class FacilityRequestTile extends ConsumerWidget {
  const FacilityRequestTile({
    super.key,
    required this.request,
    required this.centerName,
    this.canCreate = false,
  });

  final FacilityRequest request;
  final String centerName;
  final bool canCreate;

  String get _receiveKey => 'facility-request:${request.id}:receive';

  Future<void> _receive(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.facilityReceiveTitle),
        content: Text(request.quantityText(context, l10n)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.facilityMarkReceived),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await enqueueStaffAction(
      ref,
      kind: PendingActionKind.facilityReceive,
      method: 'POST',
      path: '/facility-requests/${request.id}/receive',
      body: const {},
      summary: l10n.facilityReceiveSummary(
        request.quantityText(context, l10n),
        centerName,
      ),
      subjectKey: _receiveKey,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final queuedReceive = (ref.watch(pendingActionsProvider).value ?? const [])
        .any((a) => a.subjectKey == _receiveKey);
    final approvedOf = request.approvedOf(l10n);
    final canReceive =
        request.mayReceive &&
        (request.status == 'sent' || request.status == 'approved');
    final centerId = request.centerId;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.quantityText(context, l10n),
                  style: theme.textTheme.bodyLarge,
                ),
              ),
              const SizedBox(width: 8),
              SheetBadge(
                label: queuedReceive
                    ? l10n.syncWaiting
                    : FacilityRequestsSection.statusLabel(l10n, request.status),
                tone: queuedReceive
                    ? BadgeTone.warning
                    : FacilityRequestsSection.statusTone(request.status),
              ),
            ],
          ),
          if (approvedOf != null)
            Text(approvedOf, style: theme.textTheme.bodySmall),
          if ((request.reviewNote ?? '').isNotEmpty)
            Text(request.reviewNote!, style: theme.textTheme.bodySmall),
          if ((canReceive && !queuedReceive) ||
              (canCreate && request.finished && centerId != null))
            Wrap(
              spacing: 8,
              children: [
                if (canReceive && !queuedReceive)
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: () => _receive(context, ref),
                    child: Text(l10n.facilityMarkReceived),
                  ),
                if (canCreate && request.finished && centerId != null)
                  TextButton(
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: () => showFacilityRequestForm(
                      context,
                      centerId: centerId,
                      centerName: request.centerName ?? centerName,
                      again: request,
                    ),
                    child: Text(l10n.facilityRequestAgain),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Ask CSWD for what a center is missing: item (a facility type or
/// another item), quantity and unit, and why. [again] fills it from an
/// earlier request ("Request again"). Queued, so it works offline.
Future<void> showFacilityRequestForm(
  BuildContext context, {
  required int centerId,
  required String centerName,
  FacilityRequest? again,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _RequestForm(
    centerId: centerId,
    centerName: centerName,
    subjectKey: 'center:$centerId:facility',
    again: again,
  ),
);

class _RequestForm extends ConsumerStatefulWidget {
  const _RequestForm({
    required this.centerId,
    required this.centerName,
    required this.subjectKey,
    this.again,
  });

  final int centerId;
  final String centerName;
  final String subjectKey;
  final FacilityRequest? again;

  @override
  ConsumerState<_RequestForm> createState() => _RequestFormState();
}

class _RequestFormState extends ConsumerState<_RequestForm> {
  static const _other = '__other__';
  String? _type;
  final _item = TextEditingController();
  final _reason = TextEditingController();
  final _unit = TextEditingController();
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    final again = widget.again;
    if (again != null) {
      if (again.facilityType != null &&
          facilityTypes.contains(again.facilityType)) {
        _type = again.facilityType;
      } else {
        _type = _other;
        _item.text = again.item ?? '';
      }
      _quantity = again.quantity < 1 ? 1 : again.quantity;
      _unit.text = again.unit ?? '';
      _reason.text = again.reason ?? '';
    }
  }

  @override
  void dispose() {
    _item.dispose();
    _reason.dispose();
    _unit.dispose();
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
        if (_unit.text.trim().isNotEmpty) 'unit': _unit.text.trim(),
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
              controller: _unit,
              maxLength: 30,
              decoration: InputDecoration(
                labelText: l10n.facilityRequestUnit,
                hintText: l10n.facilityRequestUnitHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
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
