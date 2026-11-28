import '../../../../core/widgets/map_sheet.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../family_registration/domain/entities/lookup_entities.dart';

/// A center's approval state as a word, the web's badge colours:
/// Unverified (warning), Rejected (danger), Edit waiting for CSWD
/// (info). Nothing for an approved center with nothing waiting.
class ApprovalBadge extends StatelessWidget {
  const ApprovalBadge({super.key, required this.center});

  final EvacuationCenterLookup center;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // The web's badges: rejected red, unverified amber, an edit waiting
    // for approval info.
    final (String label, BadgeTone tone)? badge = center.isRejected
        ? (l10n.centerApprovalRejected, BadgeTone.danger)
        : center.isPending
        ? (l10n.centerApprovalUnverified, BadgeTone.warning)
        : center.hasPendingChange
        ? (l10n.centerApprovalEditWaiting, BadgeTone.info)
        : null;
    if (badge == null) return const SizedBox.shrink();
    return SheetBadge(label: badge.$1, tone: badge.$2);
  }
}
