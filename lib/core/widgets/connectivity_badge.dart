import 'package:flutter/material.dart';

import '../../app/theme/sheet_tokens.dart';
import '../../l10n/app_localizations.dart';

/// Compact online/offline tag for the Home title box: square, ink
/// hairline, a solid ink dot when online and a hollow ring when offline,
/// with the words (no state colour is borrowed for this).
class ConnectivityBadge extends StatelessWidget {
  const ConnectivityBadge({super.key, required this.isConnected});

  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = isConnected ? l10n.online : l10n.offlineModeLabel;
    final p = SheetPalette.of(context);

    return Semantics(
      label: isConnected
          ? 'Connected to the internet'
          : 'No internet connection, offline mode',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: p.rule, width: Sheet.hairline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: isConnected ? p.ink : null,
                  shape: BoxShape.circle,
                  border: Border.all(color: p.ink, width: 1.5),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label.toUpperCase(),
                style: SheetText.label(
                  p.ink,
                  size: 14,
                ).copyWith(fontWeight: FontWeight.w700, letterSpacing: 1.1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
