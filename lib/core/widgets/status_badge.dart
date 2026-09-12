import 'package:flutter/material.dart';

/// A small tinted pill for a status/severity label — consolidates what
/// used to be three near-identical `Container` + `Text` blocks
/// (evacuation center status, alert severity in the list, alert
/// severity on the details screen). [maxWidth], when set, lets the
/// label ellipsize instead of overflowing a Row it sits in next to a
/// sibling with no room to spare (e.g. a title `Expanded` next to this
/// badge) — the same guard [EvacuationCenterCard]'s status pill already
/// had, just generalized.
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
    final content = Container(
      padding: EdgeInsets.symmetric(
        horizontal: icon != null ? 10 : 8,
        vertical: icon != null ? 5 : 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
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
