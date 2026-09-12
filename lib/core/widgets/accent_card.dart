import 'package:flutter/material.dart';

/// A card with a coloured left-edge accent bar — the same KPI-card
/// motif [HomeStatsSection]'s stat tiles use, reused everywhere else a
/// card's content has one dominant semantic colour (an alert's
/// severity, a center's occupancy, a hotline's category), so the whole
/// app reads as one consistent design rather than each feature having
/// invented its own card treatment.
///
/// [accentColor] is required rather than optional with a neutral
/// default — every call site has a real semantic colour to show, so
/// there's no meaningful "no accent" case to design for.
class AccentCard extends StatelessWidget {
  const AccentCard({
    super.key,
    required this.accentColor,
    required this.child,
    this.onTap,
    this.margin,
    this.borderRadius = 14,
  });

  final Color accentColor;
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    return Card(
      margin: margin,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: radius),
      // IntrinsicHeight, not a plain Row: every call site here sits
      // inside a vertically-scrolling list, which gives this Row an
      // *unbounded* height. CrossAxisAlignment.stretch can't stretch
      // to an unbounded height — Flutter fails that layout silently
      // (no error screen, just nothing painted) rather than throwing
      // somewhere visible. IntrinsicHeight measures the content's
      // natural height first and hands the Row that as a bounded
      // constraint, which is what stretch actually needs to work.
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: accentColor),
            Expanded(
              child: onTap != null
                  ? InkWell(onTap: onTap, child: child)
                  : child,
            ),
          ],
        ),
      ),
    );
  }
}
