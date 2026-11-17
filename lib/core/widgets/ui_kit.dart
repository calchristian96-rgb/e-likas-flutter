import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// The shared look of every screen (Part 2): the web design system's card,
/// spacing (8-point grid), 48 dp targets and status words.

/// Page gutter on a phone.
const double kGutter = 16;

/// Space under the last item of a scrolling screen, on top of the
/// system inset, so it is never hidden behind a bottom bar.
const double kEndSpace = 32;

/// Padding for a scrolling page: gutters plus the bottom system inset
/// (gesture bar) and [kEndSpace], so the last item is fully visible.
EdgeInsets pagePadding(BuildContext context, {double top = kGutter}) =>
    EdgeInsets.fromLTRB(
      kGutter,
      top,
      kGutter,
      kEndSpace + MediaQuery.paddingOf(context).bottom,
    );

/// The real E-LIKAS logo (the web's and the app icon's).
class ElikasLogo extends StatelessWidget {
  const ElikasLogo({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/elikas_logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticLabel: 'E-LIKAS',
    );
  }
}

/// The one card style: surface, gray-200 hairline, 12 px radius, no
/// shadow. [highlight] marks staff-only items with a thin brand-blue
/// border and a light blue tint, never a heavy dark card.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.highlight = false,
    this.padding = const EdgeInsets.all(kGutter),
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool highlight;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(
        color: highlight ? scheme.primary : scheme.outline,
        width: highlight ? 1.5 : 1,
      ),
    );
    return Material(
      color: highlight
          ? Color.alphaBlend(
              scheme.primary.withValues(alpha: 0.06),
              scheme.surface,
            )
          : scheme.surface,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// A status word in its colour (status is never colour alone).
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Color.lerp(color, Colors.black, 0.25),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// A section heading with the 24 px space above it.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.titleLarge),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// The page's one primary action, fixed at the bottom, above the system
/// navigation bar and above the keyboard.
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({
    super.key,
    required this.children,
    this.liftAboveKeyboard = true,
  });

  /// False when it already sits in a body the Scaffold resizes for the
  /// keyboard (padding it again would double the gap).
  final bool liftAboveKeyboard;

  /// Usually one big FilledButton; Back + Next for steps.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        bottom: liftAboveKeyboard ? MediaQuery.viewInsetsOf(context).bottom : 0,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(top: BorderSide(color: scheme.outline)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(kGutter, 12, kGutter, 12),
            child: Row(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: children[i]),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One action of a "..." sheet.
class SheetAction {
  const SheetAction({
    required this.label,
    required this.onTap,
    this.icon,
    this.destructive = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback onTap;

  /// Red, listed last after a divider (web design rule 5).
  final bool destructive;
}

/// The "..." of a card: its other actions in a bottom sheet.
Future<void> showActionsSheet(
  BuildContext context, {
  required String title,
  required List<SheetAction> actions,
}) {
  final scheme = Theme.of(context).colorScheme;
  final normal = actions.where((a) => !a.destructive).toList();
  final danger = actions.where((a) => a.destructive).toList();
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(kGutter, 0, kGutter, 8),
            child: Text(title, style: Theme.of(sheet).textTheme.titleLarge),
          ),
          for (final a in normal) _tile(sheet, a, scheme),
          if (normal.isNotEmpty && danger.isNotEmpty) const Divider(),
          for (final a in danger) _tile(sheet, a, scheme),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

Widget _tile(BuildContext sheet, SheetAction a, ColorScheme scheme) {
  final color = a.destructive ? scheme.error : null;
  return ListTile(
    minTileHeight: 56,
    leading: a.icon == null ? null : Icon(a.icon, color: color),
    title: Text(a.label, style: TextStyle(color: color)),
    onTap: () {
      Navigator.of(sheet).pop();
      a.onTap();
    },
  );
}

/// The "..." button that opens [showActionsSheet].
class MoreButton extends StatelessWidget {
  const MoreButton({super.key, required this.title, required this.actions});

  final String title;
  final List<SheetAction> actions;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: AppLocalizations.of(context).moreActions,
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      icon: const Icon(Icons.more_horiz),
      onPressed: () =>
          showActionsSheet(context, title: title, actions: actions),
    );
  }
}

/// A short message and, where useful, the action that fixes it; never a
/// large blank area.
class EmptyNote extends StatelessWidget {
  const EmptyNote({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: theme.textTheme.bodyLarge)),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: 8),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
