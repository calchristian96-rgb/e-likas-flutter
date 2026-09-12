import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Compact online/offline pill for the Home header — a translucent
/// chip readable against the navy header background, not a raw
/// technical connectivity message.
class ConnectivityBadge extends StatelessWidget {
  const ConnectivityBadge({super.key, required this.isConnected});

  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = isConnected ? l10n.online : l10n.offlineModeLabel;
    final color = isConnected
        ? const Color(0xFF5FD996)
        : const Color(0xFFFFB74D);

    return Semantics(
      label: isConnected
          ? 'Connected to the internet'
          : 'No internet connection, offline mode',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
