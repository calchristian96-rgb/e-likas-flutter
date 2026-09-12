import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Compact greeting below the branded header.
///
/// Takes [now] from [HomePage] rather than calling `DateTime.now()`
/// itself, so the greeting can never drift out of sync with the
/// header's own live date/time line — both read the same tick.
class WelcomeSection extends StatelessWidget {
  const WelcomeSection({super.key, required this.now});

  final DateTime now;

  static String _greetingFor(DateTime now, AppLocalizations l10n) {
    final hour = now.hour;
    if (hour < 12) return l10n.goodMorning;
    if (hour < 18) return l10n.goodAfternoon;
    return l10n.goodEvening;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _greetingFor(now, l10n),
          style: theme.textTheme.titleLarge?.copyWith(fontSize: 20),
        ),
        const SizedBox(height: 2),
        Text(
          l10n.stayInformedSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
