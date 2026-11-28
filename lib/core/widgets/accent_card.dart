import 'package:flutter/material.dart';

import '../../app/theme/sheet_tokens.dart';

/// A plate for a card whose content has one dominant meaning (an alert's
/// severity, a center's state, a hotline's category): map paper framed
/// by an ink hairline, square, no shadow.
///
/// The map sheet has no coloured side stripes (DESIGN.md), so
/// [accentColor] no longer paints a bar: each call site shows its meaning
/// with a symbol or a tag in its content instead. The parameter stays
/// until every caller has moved to that.
class AccentCard extends StatelessWidget {
  const AccentCard({
    super.key,
    required this.accentColor,
    required this.child,
    this.onTap,
    this.margin,
  });

  final Color accentColor;
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final p = SheetPalette.of(context);
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Material(
        color: p.plate,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: p.rule, width: Sheet.hairline),
        ),
        clipBehavior: Clip.antiAlias,
        child: onTap != null ? InkWell(onTap: onTap, child: child) : child,
      ),
    );
  }
}
