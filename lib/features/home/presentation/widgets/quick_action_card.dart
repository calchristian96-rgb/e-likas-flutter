import 'package:flutter/material.dart';

/// A single tappable quick-action tile. [accentColor], when given,
/// tints the icon chip so each category (centers, hotlines, refresh,
/// settings, …) reads as visually distinct at a glance — falls back to
/// the theme's primary colour when omitted, matching this widget's
/// original single-colour look.
class QuickActionCard extends StatelessWidget {
  const QuickActionCard({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.accentColor,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // The sheet has one action colour (sienna, for buttons); a tile's
    // icon is plain ink, so [accentColor] is no longer painted.
    final ink = colorScheme.onSurface;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: theme.colorScheme.outline),
      ),
      child: InkWell(
        onTap: onTap,
        // No fixed-height ancestor any more — this tile's own content
        // (icon chip + up to 2 lines of label) determines its height;
        // see _QuickActionsGrid, which lays these out via
        // IntrinsicHeight + Expanded rows rather than a GridView with a
        // guessed mainAxisExtent, after that exact pattern caused a
        // real RenderFlex overflow elsewhere in this app.
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: ink, size: 26),
              const SizedBox(height: 10),
              Text(
                label.toUpperCase(),
                semanticsLabel: label,
                textAlign: TextAlign.center,
                maxLines: 2,
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
