import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/connectivity/connectivity_service.dart';
import '../../core/network/staff_api_client.dart';
import '../../core/network/staff_api_error_mapper.dart';
import '../../core/widgets/ui_kit.dart';
import '../../l10n/app_localizations.dart';
import '../ec_board/domain/entities/family_here.dart';
import '../ec_board/presentation/providers/ec_board_provider.dart';
import '../staff_evacuation_centers/presentation/providers/own_centers_provider.dart';
import 'transfers.dart';

/// A center of another barangay with room (\`GET /transfer-requests/suggestions\`).
class TransferSuggestion {
  const TransferSuggestion({
    required this.centerId,
    required this.centerName,
    required this.barangayName,
    required this.fits,
    required this.capacityUnknown,
    this.distanceKm,
    this.aboutDistance = false,
    this.remainingPersons,
    this.capacityEstimated = false,
  });

  factory TransferSuggestion.fromJson(Map<String, dynamic> j) {
    final center = j['evacuation_center'] as Map<String, dynamic>? ?? const {};
    return TransferSuggestion(
      centerId: center['id'] as int,
      centerName: center['name'] as String? ?? '',
      barangayName:
          (j['barangay'] as Map<String, dynamic>?)?['name'] as String? ?? '',
      distanceKm: (j['distance_km'] as num?)?.toDouble(),
      aboutDistance: j['distance_basis'] == 'barangay_centroid',
      remainingPersons: (j['remaining_persons'] as num?)?.toInt(),
      fits: j['fits'] == true,
      capacityUnknown: j['capacity_unknown'] == true,
      capacityEstimated: j['capacity_source'] == 'estimated',
    );
  }

  final int centerId;
  final String centerName;
  final String barangayName;

  /// Null: no distance shown.
  final double? distanceKm;

  /// The center is not on the map yet: "about 2.9 km" from the barangay.
  final bool aboutDistance;
  final int? remainingPersons;

  /// Room for every person asked.
  final bool fits;
  final bool capacityUnknown;
  final bool capacityEstimated;
}

/// Room left is computed from who is inside each center right now, so
/// the list is fetched live, never from a saved copy.
final transferSuggestionsProvider = FutureProvider.autoDispose
    .family<List<TransferSuggestion>, ({int centerId, int persons})>((
      ref,
      args,
    ) async {
      final response = await ref
          .watch(staffApiClientProvider)
          .get(
            '/transfer-requests/suggestions',
            queryParameters: {
              'from_center_id': args.centerId,
              'persons': args.persons,
            },
          );
      final data =
          (response.data as Map<String, dynamic>)['data']
              as Map<String, dynamic>? ??
          const {};
      return [
        for (final c in data['centers'] as List? ?? const [])
          TransferSuggestion.fromJson(c as Map<String, dynamic>),
      ];
    });

/// Ask another barangay's center to take families (Part 6): tick
/// families of this center (own barangay only), choose a center with
/// room, say why, confirm, send. Online only, never queued; the families
/// stay here until the other barangay accepts.
class TransferRequestPage extends ConsumerStatefulWidget {
  const TransferRequestPage({
    super.key,
    required this.centerId,
    required this.eventId,
  });

  final int centerId;
  final int eventId;

  @override
  ConsumerState<TransferRequestPage> createState() =>
      _TransferRequestPageState();
}

class _TransferRequestPageState extends ConsumerState<TransferRequestPage> {
  final _picked = <int>{};
  int? _toCenterId;
  final _reason = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  int _persons(List<FamilyHere> families) => [
    for (final f in families)
      if (_picked.contains(f.id)) f.hereCount ?? f.memberCount,
  ].fold(0, (a, b) => a + b);

  Future<void> _send(
    List<FamilyHere> families,
    TransferSuggestion to,
    String fromCenter,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final persons = _persons(families);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.transferSendTitle(to.barangayName)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.transferMoveSummary(
                l10n.countFamilies(_picked.length),
                l10n.countPersons(persons),
                fromCenter,
                to.centerName,
              ),
            ),
            const SizedBox(height: 8),
            Text(l10n.transferStayUntilAccepted),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.transferSend),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!await ref.read(connectivityServiceProvider).hasConnection) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.transferNeedsConnection)),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      final response = await ref
          .read(staffApiClientProvider)
          .post(
            '/transfer-requests',
            data: {
              'evacuation_event_id': widget.eventId,
              'family_ids': _picked.toList(),
              'to_center_id': to.centerId,
              'note': _reason.text.trim(),
            },
          );
      ref.invalidate(transferRequestsProvider);
      final message = (response.data as Map?)?['message'] as String?;
      messenger.showSnackBar(
        SnackBar(content: Text(message ?? l10n.transferSent)),
      );
      navigator.maybePop();
    } on DioException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(mapStaffDioError(e).message)),
      );
      // Not knowing whether it went through: the list says.
      ref.invalidate(transferRequestsProvider);
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final familiesAsync = ref.watch(
      ecBoardFamiliesHereProvider(widget.centerId, widget.eventId),
    );
    final online = ref.watch(transfersOnlineProvider);
    final fromCenter =
        (ref.watch(ownCentersProvider).value ?? const <OwnCenter>[])
            .where((c) => c.id == widget.centerId)
            .firstOrNull
            ?.name ??
        '';
    final own = [
      for (final f in familiesAsync.value ?? const <FamilyHere>[])
        if (!f.isGeneric) f,
    ];
    final persons = _persons(own);
    final suggestions = _picked.isEmpty || !online
        ? null
        : ref.watch(
            transferSuggestionsProvider((
              centerId: widget.centerId,
              persons: persons,
            )),
          );
    final to = suggestions?.value
        ?.where((s) => s.centerId == _toCenterId)
        .firstOrNull;
    final ready =
        online &&
        _picked.isNotEmpty &&
        to != null &&
        _reason.text.trim().isNotEmpty &&
        !_sending;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.transferAskTitle),
        bottom: fromCenter.isEmpty
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(24),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(l10n.transferFromCenter(fromCenter)),
                ),
              ),
      ),
      bottomNavigationBar: BottomActionBar(
        children: [
          FilledButton(
            onPressed: ready ? () => _send(own, to, fromCenter) : null,
            child: Text(l10n.transferSend),
          ),
        ],
      ),
      body: ListView(
        padding: pagePadding(context),
        children: [
          if (!online)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: EmptyNote(
                icon: Icons.cloud_off_outlined,
                message: l10n.transferNeedsConnection,
              ),
            ),
          Text(l10n.transferStepFamilies, style: theme.textTheme.titleMedium),
          Text(l10n.transferStepFamiliesHint, style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          ...familiesAsync.when(
            loading: () => [const Center(child: CircularProgressIndicator())],
            error: (_, _) => [Text(l10n.ecBoardFamiliesHereOffline)],
            data: (_) => own.isEmpty
                ? [Text(l10n.ecBoardFamiliesHereEmpty)]
                : [
                    for (final f in own)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _picked.contains(f.id),
                        title: Text(f.name ?? l10n.ecBoardFamilyNumber(f.id)),
                        subtitle: Text(
                          l10n.countPersons(f.hereCount ?? f.memberCount),
                        ),
                        onChanged: (v) => setState(() {
                          v == true ? _picked.add(f.id) : _picked.remove(f.id);
                          _toCenterId = null;
                        }),
                      ),
                  ],
          ),
          SectionTitle(l10n.transferStepCenter),
          if (_picked.isEmpty)
            Text(l10n.transferPickFamiliesFirst)
          else if (suggestions != null)
            ...suggestions.when(
              loading: () => [const Center(child: CircularProgressIndicator())],
              error: (e, _) => [
                Text(
                  e is DioException
                      ? mapStaffDioError(e).message
                      : l10n.transferNeedsConnection,
                ),
              ],
              data: (list) => list.isEmpty
                  ? [Text(l10n.transferNoCenterWithSpace)]
                  : [
                      RadioGroup<int>(
                        groupValue: _toCenterId,
                        onChanged: (id) => setState(() => _toCenterId = id),
                        child: Column(
                          children: [
                            for (final s in list) _SuggestionTile(s: s),
                          ],
                        ),
                      ),
                    ],
            ),
          SectionTitle(l10n.transferStepReason),
          TextField(
            controller: _reason,
            maxLength: 500,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: l10n.transferReason,
              helperText: l10n.transferReasonHint,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({required this.s});

  final TransferSuggestion s;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final distance = s.distanceKm == null
        ? null
        : s.aboutDistance
        ? l10n.transferAboutKm(s.distanceKm!.toStringAsFixed(1))
        : l10n.distanceKmAway(s.distanceKm!.toStringAsFixed(1));
    final room = s.capacityUnknown
        ? l10n.capacityUnknownTag
        : s.remainingPersons == null
        ? null
        : l10n.transferRoomFor(s.remainingPersons!);
    return RadioListTile<int>(
      contentPadding: EdgeInsets.zero,
      value: s.centerId,
      title: Text(s.centerName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text([s.barangayName, ?distance].join(' · ')),
          if (room != null)
            Text(
              s.capacityEstimated && !s.capacityUnknown
                  ? '$room (${l10n.capacityEstimatedShort})'
                  : room,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: !s.fits && !s.capacityUnknown
                    ? const Color(0xFFB45309)
                    : null,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}
