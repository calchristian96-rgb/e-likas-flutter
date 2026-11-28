import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/app_update_manifest.dart';
import '../../domain/update_decision.dart';

/// "Version X is ready" — optional or required wording, with [Later]
/// always available: a required update is asked on every launch but
/// never locks residents out of a disaster app.
class UpdateOfferDialog extends StatelessWidget {
  const UpdateOfferDialog({
    super.key,
    required this.manifest,
    required this.kind,
    required this.languageCode,
    required this.onLater,
    required this.onUpdateNow,
  });

  final AppUpdateManifest manifest;
  final UpdateKind kind;
  final String languageCode;
  final VoidCallback onLater;
  final VoidCallback onUpdateNow;

  static String _formatMegabytes(double mb) =>
      mb >= 10 ? mb.round().toString() : mb.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isRequired = kind == UpdateKind.required;
    final mb = manifest.sizeMegabytes;
    final notes = manifest.notesFor(languageCode);

    return AlertDialog(
      icon: Icon(
        isRequired ? Icons.system_update_alt : Icons.system_update,
        color: isRequired
            ? theme.colorScheme.error
            : theme.colorScheme.onSurface,
      ),
      title: Text(
        isRequired ? l10n.updateRequiredTitle : l10n.updateAvailableTitle,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.updateVersionReady(
                manifest.latestVersion ?? '${manifest.latestBuild}',
              ),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              mb == null
                  ? l10n.updateWifiRecommended
                  : l10n.updateSizeWifi(_formatMegabytes(mb)),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(height: 12),
              Text(l10n.updateRequiredBody),
            ],
            if (notes != null) ...[
              const SizedBox(height: 12),
              Text(l10n.updateWhatsNew, style: theme.textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(notes),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: onLater, child: Text(l10n.updateLater)),
        FilledButton(onPressed: onUpdateNow, child: Text(l10n.updateNow)),
      ],
    );
  }
}
