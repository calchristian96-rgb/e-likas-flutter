import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/hotline.dart';

/// A visually stronger card for the single highest-priority hotline
/// (national emergency, 911) — larger number, filled emergency-red
/// background, a bigger primary Call button. Static, no animation, no
/// blinking: the visual weight comes from size/colour/contrast alone,
/// not motion, matching the "no flashing indicators" requirement. Same
/// Call/Copy behaviour as [HotlineCard] — this never bypasses the
/// dialer or auto-dials; the resident still presses Call themselves.
class PriorityHotlineCard extends StatelessWidget {
  const PriorityHotlineCard({super.key, required this.hotline});

  final Hotline hotline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final emergencyColor = theme.colorScheme.error;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: emergencyColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: emergencyColor.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: emergencyColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.emergency, color: emergencyColor, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hotline.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: emergencyColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    SelectableText(
                      hotline.number,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: emergencyColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hotline.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Semantics(
                label: l10n.callNumberTooltip(hotline.number),
                button: true,
                child: FilledButton.icon(
                  onPressed: () => _handleCall(context, hotline),
                  icon: const Icon(Icons.call, size: 20),
                  label: Text(l10n.call),
                  style: FilledButton.styleFrom(
                    backgroundColor: emergencyColor,
                    minimumSize: const Size(140, 52),
                    textStyle: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Semantics(
                label: l10n.copyNumberTooltip(hotline.number),
                button: true,
                child: OutlinedButton.icon(
                  onPressed: () => _handleCopy(context, hotline),
                  icon: const Icon(Icons.copy_outlined, size: 18),
                  label: Text(l10n.copy),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: emergencyColor,
                    side: BorderSide(color: emergencyColor),
                    minimumSize: const Size(120, 52),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleCall(BuildContext context, Hotline hotline) async {
    final uri = Uri(scheme: 'tel', path: hotline.dialableNumber);
    final launched = await launchUrl(uri);
    if (!launched && context.mounted) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).couldNotOpenDialer),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _handleCopy(BuildContext context, Hotline hotline) {
    Clipboard.setData(ClipboardData(text: hotline.number));
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context).numberCopiedFor(hotline.name),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
