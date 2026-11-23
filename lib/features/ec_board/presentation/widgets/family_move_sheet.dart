import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/connectivity/connectivity_service.dart';
import '../../../../core/network/staff_api_client.dart';
import '../../../../core/network/staff_api_error_mapper.dart';
import '../../../../core/widgets/lock_note.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../staff_evacuation_centers/presentation/providers/own_centers_provider.dart';
import '../../../transfers/transfer_request_page.dart';
import '../../domain/entities/family_here.dart';
import '../providers/ec_board_provider.dart';

/// Transfer one family from this center (0.4.0 Part 6): to another of the
/// barangay's own centers directly (`PATCH /families/{id}/evacuation-center`,
/// reason optional for an official), or to another barangay's center
/// through a transfer request. Online only: the move happens at once on
/// the server (docs/backend/apps-api-2026-11-transfers-capacity.md 2).
Future<void> showFamilyTransferSheet(
  BuildContext context,
  WidgetRef ref, {
  required FamilyHere family,
  required String familyName,
  required int centerId,
  required int eventId,
}) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  if (!await ref.read(connectivityServiceProvider).hasConnection) {
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.transferNeedsConnection)),
    );
    return;
  }
  if (!context.mounted) return;
  final choice = await showModalBottomSheet<Object>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      final theme = Theme.of(context);
      return Consumer(
        builder: (context, ref, _) {
          final centers = [
            for (final c
                in ref.watch(ownCentersProvider).value ?? const <OwnCenter>[])
              if (c.id != centerId &&
                  c.center.isUsable &&
                  c.center.status != 'closed')
                c,
          ];
          return SafeArea(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                Text(
                  l10n.familyTransferTitle(familyName),
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.familyMoveOurCenters,
                  style: theme.textTheme.titleSmall,
                ),
                if (centers.isEmpty) Text(l10n.familyMoveNoOtherCenter),
                for (final c in centers)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    minTileHeight: 56,
                    leading: const Icon(Icons.home_work_outlined),
                    title: Text(c.name),
                    subtitle: c.center.isPending
                        ? Text(l10n.pendingCswdApproval)
                        : null,
                    onTap: () => Navigator.of(context).pop(c),
                  ),
                const Divider(height: 24),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  minTileHeight: 56,
                  leading: const Icon(Icons.swap_horiz),
                  title: Text(l10n.transferAskTitle),
                  subtitle: Text(l10n.familyMoveOtherBarangay),
                  onTap: () => Navigator.of(context).pop('ask'),
                ),
              ],
            ),
          );
        },
      );
    },
  );
  if (choice == null || !context.mounted) return;
  if (choice == 'ask') {
    await navigator.push(
      MaterialPageRoute<void>(
        builder: (_) =>
            TransferRequestPage(centerId: centerId, eventId: eventId),
      ),
    );
    return;
  }
  final target = choice as OwnCenter;
  final reason = await showDialog<String>(
    context: context,
    builder: (_) => _MoveDialog(
      title: l10n.familyMoveConfirm(
        familyName,
        l10n.ecBoardFamilyMembers(family.memberCount),
        target.name,
      ),
    ),
  );
  if (reason == null) return;
  try {
    final response = await ref
        .read(staffApiClientProvider)
        .patch(
          '/families/${family.id}/evacuation-center',
          data: {
            'evacuation_center_id': target.id,
            if (reason.isNotEmpty) 'reason': reason,
          },
        );
    ref.invalidate(ecBoardFamiliesHereProvider(centerId, eventId));
    ref.invalidate(ecBoardQuickCountProvider(centerId, eventId));
    final message = (response.data as Map?)?['message'] as String?;
    messenger.showSnackBar(
      SnackBar(content: Text(message ?? l10n.familyMoved(target.name))),
    );
  } on DioException catch (e) {
    messenger.showSnackBar(failureSnackBar(mapStaffDioError(e)));
  }
}

class _MoveDialog extends StatefulWidget {
  const _MoveDialog({required this.title});

  final String title;

  @override
  State<_MoveDialog> createState() => _MoveDialogState();
}

class _MoveDialogState extends State<_MoveDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _reason,
        maxLength: 500,
        decoration: InputDecoration(
          labelText: l10n.familyMoveReason,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_reason.text.trim()),
          child: Text(l10n.familyMove),
        ),
      ],
    );
  }
}
