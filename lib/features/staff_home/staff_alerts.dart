import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/alerts/alert_level.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/ui_kit.dart';
import '../../l10n/app_localizations.dart';
import '../staff_auth/presentation/providers/staff_auth_provider.dart';
import 'barangay_dashboard.dart';

/// Whether an alert row is for this official: sent, not archived, and
/// for the whole city or their own barangay (the server already filters;
/// this keeps a cached copy honest too).
bool alertIsForOfficial(Map<String, dynamic> a, int? barangayId) {
  if (a['archived_at'] != null) return false;
  final target = a['target'] as Map<String, dynamic>?;
  final kind = target?['kind'] as String?;
  final alertBarangay =
      ((a['target_barangay'] as Map<String, dynamic>?)?['id'] as num?)?.toInt();
  if (kind == 'person' || kind == 'evacuee') return false;
  if (alertBarangay != null && barangayId != null) {
    return alertBarangay == barangayId;
  }
  return true;
}

/// The barangay's alerts on the official's home: level and "New".
class StaffAlertsSection extends ConsumerWidget {
  const StaffAlertsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final barangayId = ref.watch(staffAuthProvider).value?.barangayId;
    final alerts = [
      for (final a
          in ref.watch(barangayDashboardProvider).value?.alerts ??
              const <Map<String, dynamic>>[])
        if (alertIsForOfficial(a, barangayId) && a['id'] is num) a,
    ];
    if (alerts.isEmpty) return const SizedBox.shrink();
    final seen = ref.watch(seenAlertsProvider('staff'));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(l10n.navAlerts),
        for (final a in alerts.take(5))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              onTap: () {
                ref.read(seenAlertsProvider('staff').notifier).markSeen([
                  (a['id'] as num).toInt(),
                ]);
                showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(a['title'] as String? ?? ''),
                    // The dashboard's rows carry no message: the date.
                    content: SingleChildScrollView(
                      child: Text(
                        (a['message'] as String?)?.isNotEmpty == true
                            ? a['message'] as String
                            : switch (parseServerTime(a['date_sent'])) {
                                final DateTime t => formatShortDateTime(t),
                                null => '',
                              },
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(l10n.dismiss),
                      ),
                    ],
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      AlertLevelChip(severity: a['severity'] as String?),
                      if (!seen.contains((a['id'] as num).toInt()))
                        const NewBadge(),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    a['title'] as String? ?? '',
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(
                    [
                      ?(a['target'] as Map<String, dynamic>?)?['label']
                          as String?,
                      if (parseServerTime(a['sent_at'] ?? a['created_at'])
                          case final t?)
                        formatShortDateTime(t),
                    ].join(' · '),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
