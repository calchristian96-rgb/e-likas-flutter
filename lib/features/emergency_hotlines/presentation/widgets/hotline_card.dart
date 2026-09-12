import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/widgets/accent_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/hotline.dart';
import '../providers/hotline_favorites_provider.dart';
import 'hotline_category_display.dart';

/// A single emergency contact card — icon, name, number, short
/// description, favorite toggle, and Call/Copy actions. The left-edge
/// accent (via the shared [AccentCard]) matches its category colour,
/// the same as the icon circle already had — one less colour to keep
/// in sync by hand.
class HotlineCard extends ConsumerWidget {
  const HotlineCard({super.key, required this.hotline});

  final Hotline hotline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final categoryColor = hotlineCategoryColor(hotline.category, theme);
    final favoritesAsync = ref.watch(hotlineFavoritesProvider);
    final isFavorite = favoritesAsync.value?.contains(hotline.name) ?? false;
    final hasNumber = hotline.number.trim().isNotEmpty;

    return AccentCard(
      accentColor: categoryColor,
      borderRadius: 16,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: categoryColor.withValues(alpha: 0.15),
                  child: Icon(
                    hotlineCategoryIcon(hotline.category),
                    color: categoryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hotline.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      if (hasNumber)
                        // Selectable so a resident can copy the number
                        // by long-pressing it directly, in addition to
                        // the explicit Copy button below — never a
                        // requirement, just one less tap when it helps.
                        SelectableText(
                          hotline.number,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: categoryColor,
                          ),
                        )
                      else
                        Text(
                          l10n.hotlineNumberNotSet,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                Semantics(
                  label: isFavorite
                      ? l10n.removeFromFavoritesTooltip(hotline.name)
                      : l10n.addToFavoritesTooltip(hotline.name),
                  button: true,
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: IconButton(
                      onPressed: () => ref
                          .read(hotlineFavoritesProvider.notifier)
                          .toggle(hotline.name),
                      icon: Icon(
                        isFavorite ? Icons.star_rounded : Icons.star_border,
                        color: isFavorite
                            ? Colors.amber.shade700
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              hotline.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            // Wrap, not a fixed-width Row split: at 1.3x text scale or
            // under a longer Filipino/Bikol label, two Expanded buttons
            // side by side could each be squeezed too narrow for their
            // own icon+label — Wrap lets Copy drop to its own line
            // instead of clipping or overflowing.
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Semantics(
                  label: hasNumber
                      ? l10n.callNumberTooltip(hotline.number)
                      : l10n.hotlineNumberNotSet,
                  button: true,
                  child: FilledButton.icon(
                    onPressed: hasNumber
                        ? () => _handleCall(context, hotline)
                        : null,
                    icon: const Icon(Icons.call, size: 18),
                    label: Text(l10n.call),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(120, 48),
                    ),
                  ),
                ),
                if (hasNumber)
                  Semantics(
                    label: l10n.copyNumberTooltip(hotline.number),
                    button: true,
                    child: OutlinedButton.icon(
                      onPressed: () => _handleCopy(context, hotline),
                      icon: const Icon(Icons.copy_outlined, size: 18),
                      label: Text(l10n.copy),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(120, 48),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Opens the device's phone dialer pre-filled with the number — the
  /// `tel:` scheme hands off to the dialer app entirely, it does not
  /// place the call itself, so the resident still has to press the
  /// dialer's own Call button. Spaces are stripped since `tel:` URIs
  /// expect a plain dialable string, not the display-formatted number.
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
