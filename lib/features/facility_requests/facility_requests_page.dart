import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cache/staff_read_cache.dart';
import '../../core/utils/data_freshness_formatter.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/ui_kit.dart';
import '../../l10n/app_localizations.dart';
import '../outbox/domain/pending_action.dart';
import '../outbox/presentation/outbox_providers.dart';
import '../staff_auth/domain/entities/staff_session.dart';
import '../staff_auth/presentation/providers/staff_auth_provider.dart';
import '../staff_evacuation_centers/presentation/providers/own_centers_provider.dart';
import 'facility_requests.dart';

/// One row of `GET /facility-requests/suggestions` (officials): what a
/// center is short of by the planning standards for a full center, minus
/// what is already asked; ready to send as a request.
class FacilitySuggestion {
  const FacilitySuggestion({
    required this.centerId,
    required this.centerName,
    required this.quantity,
    this.facilityType,
    this.item,
    this.unit,
    this.reason,
    this.label,
  });

  /// One row of `GET /facility-requests/suggestions`
  /// (apps-api-2026-11-24.md 7.2): `{center: {id, name}, facility_type,
  /// label, quantity, unit, reason}`; `quantity` is what is left to ask.
  static FacilitySuggestion? fromJson(Map<String, dynamic> j) {
    final center = j['center'] as Map<String, dynamic>?;
    final id = (center?['id'] as num?)?.toInt();
    if (id == null) return null;
    return FacilitySuggestion(
      centerId: id,
      centerName: center?['name'] as String? ?? '',
      facilityType: j['facility_type'] as String?,
      label: j['label'] as String?,
      quantity: (j['quantity'] as num?)?.toInt() ?? 1,
      unit: j['unit'] as String?,
      reason: j['reason'] as String?,
    );
  }

  /// The server's words for the supply ("toilets", "bathing cubicles").
  final String? label;

  /// What the row shows: the server's label, else the facility type's.
  String what(BuildContext context) => (label != null && label!.isNotEmpty)
      ? label!
      : facilityType != null
      ? facilityRequestLabel(context, facilityType, null)
      : item ?? '';

  /// The request form filled from this suggestion (the official may change
  /// it before sending).
  FacilityRequest get asPrefill => FacilityRequest(
    id: 0,
    status: 'pending',
    quantity: quantity,
    facilityType: facilityType,
    item: item ?? label,
    unit: unit,
    reason: reason,
  );

  final int centerId;
  final String centerName;
  final String? facilityType;
  final String? item;
  final int quantity;
  final String? unit;
  final String? reason;

  String get key => '$centerId:${facilityType ?? item}';

  Map<String, dynamic> get body => {
    if (facilityType != null) 'facility_type': facilityType else 'item': item,
    'quantity_needed': quantity,
    'unit': ?unit,
    'reason': ?reason,
  };
}

final facilitySuggestionsProvider =
    FutureProvider.autoDispose<List<FacilitySuggestion>>((ref) async {
      ref.watch(outboxRevisionProvider);
      final read = await ref
          .watch(staffReadCacheProvider)
          .get('/facility-requests/suggestions');
      final list = read.data['suggestions'] as List? ?? const [];
      return [
        for (final r in list)
          ?FacilitySuggestion.fromJson(r as Map<String, dynamic>),
      ];
    });

/// The barangay's facility requests, newest first (saved for offline).
final barangayFacilityRequestsProvider =
    FutureProvider.autoDispose<
      ({List<FacilityRequest> requests, DateTime fetchedAt, bool fromCache})
    >((ref) async {
      ref.watch(outboxRevisionProvider);
      final read = await ref
          .watch(staffReadCacheProvider)
          .get('/facility-requests', query: {'per_page': 50});
      final rows = read.data['data'] as List? ?? const [];
      return (
        requests: [
          for (final r in rows)
            FacilityRequest.fromJson(r as Map<String, dynamic>),
        ],
        fetchedAt: read.fetchedAt,
        fromCache: read.isFromCache,
      );
    });

/// Facility requests for all the barangay's centers (Home > To do >
/// Request supplies): "Suggested for your centers", then the requests
/// with Mark received and Request again.
class FacilityRequestsPage extends ConsumerStatefulWidget {
  const FacilityRequestsPage({super.key, this.centerId});

  /// From a To do item ("Request supplies" for one center): only that
  /// center's suggestions, with "Show all centers".
  final int? centerId;

  @override
  ConsumerState<FacilityRequestsPage> createState() =>
      _FacilityRequestsPageState();
}

class _FacilityRequestsPageState extends ConsumerState<FacilityRequestsPage> {
  late int? _centerId = widget.centerId;

  Future<void> _sendSuggestion(
    BuildContext context,
    WidgetRef ref,
    FacilitySuggestion s,
  ) async {
    final l10n = AppLocalizations.of(context);
    final what = s.what(context);
    await enqueueStaffAction(
      ref,
      kind: PendingActionKind.facilityRequest,
      method: 'POST',
      path: '/evacuation-centers/${s.centerId}/facility-requests',
      body: s.body,
      summary: l10n.facilityRequestSummary(what, s.quantity, s.centerName),
      subjectKey: 'suggestion:${s.key}',
    );
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.facilityRequestSent)));
    }
  }

  Future<void> _newRequest(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final centers = ref.read(ownCentersProvider).value ?? const <OwnCenter>[];
    final center = await showModalBottomSheet<OwnCenter>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l10n.facilityRequestWhichCenter,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final c in centers)
              if (c.center.isUsable)
                ListTile(
                  minTileHeight: 56,
                  title: Text(c.name),
                  onTap: () => Navigator.of(context).pop(c),
                ),
          ],
        ),
      ),
    );
    if (center == null || !context.mounted) return;
    await showFacilityRequestForm(
      context,
      centerId: center.id,
      centerName: center.name,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final canCreate =
        ref
            .watch(staffAuthProvider)
            .value
            ?.can(StaffPermission.facilityRequestsCreate) ??
        false;
    final suggestions = ref.watch(facilitySuggestionsProvider);
    final requests = ref.watch(barangayFacilityRequestsProvider);
    final queued = {
      for (final a in ref.watch(pendingActionsProvider).value ?? const [])
        ?a.subjectKey,
    };
    final centerNames = {
      for (final c
          in ref.watch(ownCentersProvider).value ?? const <OwnCenter>[])
        c.id: c.name,
    };
    return Scaffold(
      appBar: AppBar(title: Text(l10n.facilityRequestsTitle)),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => _newRequest(context, ref),
              icon: const Icon(Icons.add),
              label: Text(l10n.facilityRequestsAsk),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(facilitySuggestionsProvider);
          ref.invalidate(barangayFacilityRequestsProvider);
          await ref.read(staffSyncAllProvider)();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: pagePadding(context).copyWith(bottom: 96),
          children: [
            SectionTitle(l10n.facilitySuggested),
            ...suggestions.when(
              loading: () => [const LinearProgressIndicator()],
              error: (_, _) => [
                Text(
                  l10n.facilityRequestsNeedConnection,
                  style: theme.textTheme.bodySmall,
                ),
              ],
              data: (all) {
                final list = [
                  for (final s in all)
                    if (_centerId == null || s.centerId == _centerId) s,
                ];
                final onlyName = _centerId == null
                    ? null
                    : centerNames[_centerId] ?? list.firstOrNull?.centerName;
                return [
                  if (_centerId != null)
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (onlyName != null && onlyName.isNotEmpty)
                          Text(
                            l10n.facilityForCenter(onlyName),
                            style: theme.textTheme.labelLarge,
                          ),
                        TextButton(
                          onPressed: () => setState(() => _centerId = null),
                          child: Text(l10n.facilityShowAllCenters),
                        ),
                      ],
                    ),
                  ...(list.isEmpty
                      ? [
                          Text(
                            l10n.facilitySuggestedNone,
                            style: theme.textTheme.bodySmall,
                          ),
                        ]
                      : [
                          Text(
                            l10n.facilitySuggestedHint,
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          for (final s in list)
                            Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                minTileHeight: 64,
                                // "2 toilets" with the server's label;
                                // else "Toilet × 2 pieces".
                                title: Text(
                                  (s.label ?? '').isNotEmpty
                                      ? l10n.quantityWithUnit(
                                          formatCount(s.quantity),
                                          s.label!,
                                        )
                                      : '${s.what(context)} × '
                                            '${s.unit == null ? formatCount(s.quantity) : l10n.quantityWithUnit(formatCount(s.quantity), s.unit!)}',
                                ),
                                // Tap: the form filled in, to change first.
                                onTap: canCreate
                                    ? () => showFacilityRequestForm(
                                        context,
                                        centerId: s.centerId,
                                        centerName: s.centerName,
                                        again: s.asPrefill,
                                      )
                                    : null,
                                subtitle: Text(
                                  [
                                    s.centerName,
                                    if ((s.reason ?? '').isNotEmpty) s.reason!,
                                  ].join(' · '),
                                ),
                                trailing: queued.contains('suggestion:${s.key}')
                                    ? Text(
                                        l10n.syncWaiting,
                                        style: theme.textTheme.labelMedium,
                                      )
                                    : canCreate
                                    ? FilledButton.tonal(
                                        style: FilledButton.styleFrom(
                                          minimumSize: const Size(48, 48),
                                        ),
                                        onPressed: () =>
                                            _sendSuggestion(context, ref, s),
                                        child: Text(l10n.facilityRequestSend),
                                      )
                                    : null,
                              ),
                            ),
                        ]),
                ];
              },
            ),
            SectionTitle(l10n.facilityYourRequests),
            ...requests.when(
              loading: () => [const LinearProgressIndicator()],
              error: (_, _) => [
                Text(
                  l10n.facilityRequestsNeedConnection,
                  style: theme.textTheme.bodySmall,
                ),
              ],
              data: (d) => [
                if (d.fromCache)
                  Text(
                    l10n.savedCopyAge(formatElapsedSince(d.fetchedAt)),
                    style: theme.textTheme.bodySmall,
                  ),
                if (d.requests.isEmpty)
                  Text(
                    l10n.facilityRequestsNone,
                    style: theme.textTheme.bodySmall,
                  ),
                for (final r in d.requests)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.centerName ?? centerNames[r.centerId] ?? '',
                            style: theme.textTheme.labelMedium,
                          ),
                          FacilityRequestTile(
                            request: r,
                            centerName:
                                r.centerName ?? centerNames[r.centerId] ?? '',
                            canCreate: canCreate,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
