import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Replaces the removed Open-Meteo weather card in the exact same slot
/// on Home — same card shape/padding as every other Home card, so
/// removing weather doesn't shift or reshape the approved dashboard
/// layout around it. Deliberately honest, not a disguised error state:
/// there's no live weather integration in this app at all right now
/// (Open-Meteo was removed, and this is not a placeholder for some
/// other weather source still to come), so it says exactly that
/// rather than "unavailable"/"loading," and never shows a fabricated
/// temperature, forecast, or "PAGASA" attribution.
class WeatherUnavailablePlaceholder extends StatelessWidget {
  const WeatherUnavailablePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 24,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.weatherNotYetAvailable,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
