import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../alerts/presentation/providers/alerts_summary_provider.dart';
import 'barangay_status_providers.dart';

/// True while the public data is a drill: the backend shows an open demo
/// event publicly (ELIKAS_PUBLIC_SHOW_DEMO) and marks it `is_drill` on
/// the barangay status and on the alerts sent for it. Centers' occupancy
/// then counts the drill's made-up families too, with no flag of its
/// own, so one notice covers every screen.
final drillActiveProvider = Provider<bool>((ref) {
  final board = ref.watch(barangayStatusBoardProvider).value;
  final latest = ref.watch(alertsSummaryProvider).value?.latest;
  return (board?.isDrill ?? false) || (latest?.isDrill ?? false);
});

/// One line that prevents harm (web design rule 9): this is practice.
class DrillNotice extends ConsumerWidget {
  const DrillNotice({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(drillActiveProvider)) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final warning = theme.extension<AppSemanticColors>()!.warning;
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: warning.withValues(alpha: 0.12),
          border: Border.all(color: warning),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.campaign_outlined, color: warning),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.drillNotice,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
