import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
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
    final theme = Theme.of(context);
    final semantic = theme.extension<AppSemanticColors>()!;
    final (String label, Color color)? badge = center.isRejected
        ? (l10n.centerApprovalRejected, theme.colorScheme.error)
        : center.isPending
        ? (l10n.centerApprovalUnverified, semantic.warning)
        : center.hasPendingChange
        ? (l10n.centerApprovalEditWaiting, theme.colorScheme.primary)
        : null;
    if (badge == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: badge.$2.withValues(alpha: 0.12),
        borderRadius: BorderRadius.zero,
      ),
      child: Text(
        badge.$1,
        style: theme.textTheme.labelMedium?.copyWith(
          color: badge.$2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
