import 'package:flutter/material.dart';

import '../../app/theme/sheet_tokens.dart';

/// A small square status/severity tag: map-label caps in ink beside a
/// swatch (or the given [icon]) in [color], framed by a hairline. The
/// words carry the meaning; the colour is never alone. [maxWidth], when
/// set, lets the label ellipsize instead of overflowing a Row it sits in
/// next to a sibling with no room to spare.
///
/// For a center or barangay state use CenterStateTag / BarangayStateTag
/// (lib/core/widgets/map_sheet.dart), which draw the state's own symbol.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.maxWidth,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final p = SheetPalette.of(context);
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: p.rule, width: Sheet.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(icon, size: 16, color: p.ink)
          else
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                border: Border.all(color: p.symbolStroke, width: 1),
              ),
            ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label.toUpperCase(),
              semanticsLabel: label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SheetText.label(
                p.ink,
                size: 15,
              ).copyWith(fontWeight: FontWeight.w700, letterSpacing: 1.1),
            ),
          ),
        ],
      ),
    );
    if (maxWidth == null) return content;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth!),
      child: content,
    );
  }
}
