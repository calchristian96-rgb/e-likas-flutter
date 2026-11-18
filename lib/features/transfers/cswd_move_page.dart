import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/connectivity/connectivity_service.dart';
import '../../core/network/staff_api_client.dart';
import '../../core/network/staff_api_error_mapper.dart';
import '../../core/widgets/search_field.dart';
import '../../core/widgets/ui_kit.dart';
import '../../l10n/app_localizations.dart';
import '../ec_board/domain/entities/family_here.dart';
import '../ec_board/presentation/providers/ec_board_provider.dart';
import '../family_registration/domain/entities/lookup_entities.dart';
import '../family_registration/presentation/providers/lookup_providers.dart';
import 'transfers.dart';

/// The families at a center, for CSWDO to move one directly (Part 7).
class CswdCenterFamiliesPage extends ConsumerWidget {
  const CswdCenterFamiliesPage({
    super.key,
    required this.centerId,
    required this.centerName,
    required this.eventId,
  });

  final int centerId;
  final String centerName;
  final int eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(ecBoardFamiliesHereProvider(centerId, eventId));
    return Scaffold(
      appBar: AppBar(title: Text(centerName)),
      body: ListView(
        padding: pagePadding(context),
        children: [
          Text(l10n.cswdMoveHint),
          const SizedBox(height: 16),
          ...async.when(
            loading: () => [const Center(child: CircularProgressIndicator())],
            error: (_, _) => [
              EmptyNote(
                icon: Icons.cloud_off_outlined,
                message: l10n.ecBoardFamiliesHereOffline,
              ),
            ],
            data: (families) => families.isEmpty
                ? [EmptyNote(message: l10n.ecBoardFamiliesHereEmpty)]
                : [
                    for (final f in families) ...[
                      AppCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    f.name ?? l10n.ecBoardFamilyNumber(f.id),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  Text(
                                    [
                                      ?f.barangayName,
                                      l10n.countPersons(
                                        f.hereCount ?? f.memberCount,
                                      ),
                                    ].join(' · '),
                                  ),
                                ],
                              ),
                            ),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(48, 48),
                              ),
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => CswdMovePage(
                                    family: f,
                                    fromCenterId: centerId,
                                    fromCenterName: centerName,
                                    eventId: eventId,
                                  ),
                                ),
                              ),
                              child: Text(l10n.cswdMove),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
          ),
        ],
      ),
    );
  }
}

/// CSWDO moves one family to any center, with a reason
/// (\`PATCH /families/{id}/evacuation-center\`): online only, never queued,
/// after a confirm naming the family, persons and both centers.
class CswdMovePage extends ConsumerStatefulWidget {
  const CswdMovePage({
    super.key,
    required this.family,
    required this.fromCenterId,
    required this.fromCenterName,
    required this.eventId,
  });

  final FamilyHere family;
  final int fromCenterId;
  final String fromCenterName;
  final int eventId;

  @override
  ConsumerState<CswdMovePage> createState() => _CswdMovePageState();
}

class _CswdMovePageState extends ConsumerState<CswdMovePage> {
  final _search = TextEditingController();
  final _reason = TextEditingController();
  String _query = '';
  int? _toId;
  bool _sending = false;

  @override
  void dispose() {
    _search.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _move(EvacuationCenterLookup to) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final f = widget.family;
    final name = f.name ?? l10n.ecBoardFamilyNumber(f.id);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.cswdMoveTitle(name)),
        content: Text(
          l10n.transferMoveSummary(
            l10n.countFamilies(1),
            l10n.countPersons(f.hereCount ?? f.memberCount),
            widget.fromCenterName,
            to.name,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.cswdMove),
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
          .patch(
            '/families/${f.id}/evacuation-center',
            data: {
              'evacuation_center_id': to.id,
              'reason': _reason.text.trim(),
            },
          );
      ref.invalidate(
        ecBoardFamiliesHereProvider(widget.fromCenterId, widget.eventId),
      );
      final message = (response.data as Map?)?['message'] as String?;
      messenger.showSnackBar(
        SnackBar(content: Text(message ?? l10n.cswdMoved(name, to.name))),
      );
      navigator.maybePop();
    } on DioException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(mapStaffDioError(e).message)),
      );
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final online = ref.watch(transfersOnlineProvider);
    final barangays = {
      for (final b in ref.watch(barangaysProvider).value ?? const <Barangay>[])
        b.id: b.name,
    };
    final q = _query.trim().toLowerCase();
    final centers = [
      for (final c
          in ref.watch(evacuationCentersLookupProvider).value ??
              const <EvacuationCenterLookup>[])
        if (c.id != widget.fromCenterId &&
            c.isApproved &&
            c.status != 'closed' &&
            (q.isEmpty ||
                c.name.toLowerCase().contains(q) ||
                (barangays[c.barangayId] ?? '').toLowerCase().contains(q)))
          c,
    ]..sort((a, b) => a.name.compareTo(b.name));
    final to = centers.where((c) => c.id == _toId).firstOrNull;
    final ready =
        online && to != null && _reason.text.trim().isNotEmpty && !_sending;
    final f = widget.family;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.cswdMoveTitle(f.name ?? '#${f.id}'))),
      bottomNavigationBar: BottomActionBar(
        children: [
          FilledButton(
            onPressed: ready ? () => _move(to) : null,
            child: Text(l10n.cswdMove),
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
          Text(
            l10n.transferFromCenter(widget.fromCenterName),
            style: theme.textTheme.bodyLarge,
          ),
          SectionTitle(l10n.cswdMoveReason),
          TextField(
            controller: _reason,
            maxLength: 500,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: l10n.transferReason,
              helperText: l10n.cswdMoveReasonRequired,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          SectionTitle(l10n.transferStepCenter),
          SearchField(
            controller: _search,
            hintText: l10n.searchCentersHint,
            clearTooltip: l10n.clearSearch,
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 8),
          RadioGroup<int>(
            groupValue: _toId,
            onChanged: (id) => setState(() => _toId = id),
            child: Column(
              children: [
                for (final c in centers.take(50))
                  RadioListTile<int>(
                    contentPadding: EdgeInsets.zero,
                    value: c.id,
                    title: Text(c.name),
                    subtitle: Text(barangays[c.barangayId] ?? ''),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
