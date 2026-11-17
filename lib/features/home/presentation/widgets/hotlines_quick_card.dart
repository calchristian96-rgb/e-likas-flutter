import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/widgets/ui_kit.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../emergency_hotlines/domain/emergency_hotlines_data.dart';

/// The first emergency numbers, one tap to call (Part 3.2); the rest on
/// the Hotlines tab. Built into the app, so it works offline.
class HotlinesQuickCard extends StatelessWidget {
  const HotlinesQuickCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final h in emergencyHotlines.take(3))
            ListTile(
              contentPadding: EdgeInsets.zero,
              minTileHeight: 56,
              title: Text(h.name, style: theme.textTheme.titleMedium),
              subtitle: Text(h.number),
              trailing: IconButton.filled(
                tooltip: l10n.callNumberTooltip(h.number),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: const Icon(Icons.call),
                onPressed: () =>
                    launchUrl(Uri(scheme: 'tel', path: h.dialableNumber)),
              ),
              onTap: () =>
                  launchUrl(Uri(scheme: 'tel', path: h.dialableNumber)),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => context.go('/emergency-hotlines'),
              child: Text(l10n.homeAllHotlines),
            ),
          ),
        ],
      ),
    );
  }
}
