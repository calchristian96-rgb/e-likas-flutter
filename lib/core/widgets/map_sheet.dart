import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/sheet_tokens.dart';

/// The "Ligao Map Sheet" building blocks shared by every screen
/// (elikas-backend DESIGN.md): state symbols, margin heads, captions,
/// the neatline frame and station numbers.

// ---------------------------------------------------------------------------
// Evacuation-center state symbols (public/js/map-symbols.js)
// ---------------------------------------------------------------------------

/// The five center states as the API sends them.
abstract final class CenterState {
  static const active = 'active';
  static const nearlyFull = 'nearly_full';
  static const full = 'full';
  static const onStandby = 'on_standby';
  static const closed = 'closed';

  /// An unknown status draws as on standby, as on the web.
  static String key(String status) {
    final s = status.toLowerCase();
    return const [active, nearlyFull, full, onStandby, closed].contains(s)
        ? s
        : onStandby;
  }

  static Color color(String status) => switch (key(status)) {
    active => Sheet.centerActive,
    nearlyFull => Sheet.centerNearlyFull,
    full => Sheet.centerFull,
    closed => Sheet.centerClosed,
    _ => Sheet.centerOnStandby,
  };
}

/// A center state drawn as shape + pattern + colour, never colour alone:
/// active is a solid green disc; nearly full the amber disc hatched at
/// 45 degrees; full the red disc cross-hatched; on standby a white disc
/// with a thick blue ring; closed a white square struck through in grey.
/// Always shown with the state's words next to it (or in [semanticLabel]).
class CenterSymbol extends StatelessWidget {
  const CenterSymbol({
    super.key,
    required this.status,
    this.size = 24,
    this.semanticLabel,
    this.stroke,
  });

  final String status;
  final double size;

  /// Read out instead of nothing; leave null when the words sit beside it.
  final String? semanticLabel;

  /// The outline round a filled disc. Defaults to the palette's (ink on
  /// paper, paper at night); a map marker passes ink.
  final Color? stroke;

  @override
  Widget build(BuildContext context) {
    final symbol = CustomPaint(
      size: Size.square(size),
      painter: CenterSymbolPainter(
        status: status,
        stroke: stroke ?? SheetPalette.of(context).symbolStroke,
      ),
    );
    if (semanticLabel == null) return ExcludeSemantics(child: symbol);
    return Semantics(label: semanticLabel, image: true, child: symbol);
  }
}

/// Paints [CenterSymbol] on a 24-unit grid, exactly as map-symbols.js.
class CenterSymbolPainter extends CustomPainter {
  const CenterSymbolPainter({required this.status, required this.stroke});

  final String status;
  final Color stroke;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    const c = Offset(12, 12);
    final key = CenterState.key(status);
    final color = CenterState.color(key);

    void disc() {
      canvas.drawCircle(c, 9, Paint()..color = color);
    }

    void discStroke() {
      canvas.drawCircle(
        c,
        9,
        Paint()
          ..color = stroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    final white = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;

    switch (key) {
      case CenterState.active:
        disc();
        discStroke();
      case CenterState.nearlyFull:
        disc();
        canvas.save();
        canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: 9)));
        // #sym-hatch: 2-unit white lines every 5 units, rotated 45deg.
        canvas.translate(12, 12);
        canvas.rotate(math.pi / 4);
        white.strokeWidth = 2;
        for (var x = -20.0; x <= 20; x += 5) {
          canvas.drawLine(Offset(x, -20), Offset(x, 20), white);
        }
        canvas.restore();
        discStroke();
      case CenterState.full:
        disc();
        canvas.save();
        canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: 9)));
        // #sym-cross: both diagonals of a 5-unit tile, 1.4 wide.
        white.strokeWidth = 1.4;
        for (var x = -25.0; x <= 50; x += 5) {
          canvas.drawLine(Offset(x, 0), Offset(x + 24, 24), white);
          canvas.drawLine(Offset(x, 0), Offset(x - 24, 24), white);
        }
        canvas.restore();
        discStroke();
      case CenterState.closed:
        const r = Rect.fromLTRB(4, 4, 20, 20);
        canvas.drawRect(r, Paint()..color = Colors.white);
        final grey = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5;
        canvas.drawRect(r, grey);
        canvas.drawLine(const Offset(6, 6), const Offset(18, 18), grey);
      default: // on standby
        canvas.drawCircle(c, 8, Paint()..color = Colors.white);
        canvas.drawCircle(
          c,
          8,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.5,
        );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(CenterSymbolPainter old) =>
      old.status != status || old.stroke != stroke;
}

/// A center state as its symbol and its words, in ink (the state colour
/// is in the symbol, so the words stay readable on any ground).
class CenterStateTag extends StatelessWidget {
  const CenterStateTag({
    super.key,
    required this.status,
    required this.label,
    this.symbolSize = 20,
    this.style,
  });

  final String status;
  final String label;
  final double symbolSize;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final p = SheetPalette.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CenterSymbol(status: status, size: symbolSize),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label.toUpperCase(),
            semanticsLabel: label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                style ??
                SheetText.label(
                  p.ink,
                  size: 15,
                ).copyWith(fontWeight: FontWeight.w700, letterSpacing: 1.2),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Barangay states
// ---------------------------------------------------------------------------

/// The fill and text colours of a barangay state tag. Normal is an
/// outlined tag with no fill (calm days show no colour).
({Color fill, Color text})? barangayStateColours(String status) =>
    switch (status) {
      'watch' => (fill: Sheet.barangayWatch, text: Sheet.barangayWatchText),
      'flooding_reported' => (fill: Sheet.barangayFlooding, text: Sheet.ink),
      'preemptive_evacuation' => (
        fill: Sheet.barangayPreemptive,
        text: Colors.white,
      ),
      'forced_evacuation' => (fill: Sheet.barangayForced, text: Colors.white),
      _ => null,
    };

/// A barangay's state as a square tag in its fixed colour with its words.
class BarangayStateTag extends StatelessWidget {
  const BarangayStateTag({
    super.key,
    required this.status,
    required this.label,
    this.size = 15,
  });

  final String status;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = SheetPalette.of(context);
    final c = barangayStateColours(status);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      heightFactor: 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: c?.fill,
          border: Border.all(
            color: c == null ? p.ink : p.symbolStroke,
            width: c == null ? Sheet.rule : Sheet.hairline,
          ),
        ),
        child: Text(
          label.toUpperCase(),
          semanticsLabel: label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: SheetText.label(
            c?.text ?? p.ink,
            size: size,
          ).copyWith(fontWeight: FontWeight.w700, letterSpacing: 1.1),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Type and frames
// ---------------------------------------------------------------------------

/// A section heading as printed beside a map: a map-label over a 1.5 px
/// ink rule. No kicker or eyebrow above it, ever.
class MarginHead extends StatelessWidget {
  const MarginHead(this.text, {super.key, this.trailing, this.top = 24});

  final String text;
  final Widget? trailing;
  final double top;

  @override
  Widget build(BuildContext context) {
    final p = SheetPalette.of(context);
    return Semantics(
      header: true,
      child: Container(
        margin: EdgeInsets.only(top: top, bottom: 12),
        padding: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: p.rule, width: Sheet.rule),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                text.toUpperCase(),
                semanticsLabel: text,
                style: SheetText.label(p.ink, size: 15),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

/// A big condensed title in caps (page titles, plate titles).
class SheetTitle extends StatelessWidget {
  const SheetTitle(this.text, {super.key, this.size = 32, this.color});

  final String text;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(
      text.toUpperCase(),
      semanticsLabel: text,
      style: SheetText.title(color ?? SheetPalette.of(context).ink, size: size),
    ),
  );
}

/// The cartographer's annotation: Source Serif 4 italic in hydro blue.
class SheetCaption extends StatelessWidget {
  const SheetCaption(this.text, {super.key, this.size = 15, this.maxLines});

  final String text;
  final double size;
  final int? maxLines;

  @override
  Widget build(BuildContext context) => Text(
    text,
    maxLines: maxLines,
    overflow: maxLines == null ? null : TextOverflow.ellipsis,
    style: SheetText.caption(SheetPalette.of(context).caption, size: size),
  );
}

/// The neatline: a 2 px ink border with a 1 px ink outline 5 px outside
/// it, round a map or an image plate.
class Neatline extends StatelessWidget {
  const Neatline({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = SheetPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: p.rule, width: Sheet.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            border: Border.all(color: p.rule, width: Sheet.frame),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// A 36 px sienna square with a white numeral (Before, Alert, Evacuate,
/// Return home).
class StationNo extends StatelessWidget {
  const StationNo(this.number, {super.key, this.size = 36});

  final int number;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    color: Sheet.sienna,
    child: Text(
      '$number',
      style: SheetText.title(Colors.white, size: size * 0.6),
    ),
  );
}

/// Map-label caps in a given colour (field labels, small heads).
class SheetLabel extends StatelessWidget {
  const SheetLabel(this.text, {super.key, this.color, this.size = 14});

  final String text;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    semanticsLabel: text,
    style: SheetText.label(color ?? SheetPalette.of(context).ink2, size: size),
  );
}

/// A note in the sheet's margin: the recessed paper fold ruled with a
/// hairline, or, for an [advisory] (call now, act now), the sienna tint
/// DESIGN.md gives an advisory note. Text stays ink; no side stripe.
class SheetNote extends StatelessWidget {
  const SheetNote({
    super.key,
    required this.icon,
    required this.message,
    this.advisory = false,
  });

  final IconData icon;
  final String message;
  final bool advisory;

  @override
  Widget build(BuildContext context) {
    final p = SheetPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: advisory ? scheme.primaryContainer : p.fold,
        border: Border.all(color: p.rule, width: Sheet.hairline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: advisory ? p.errorText : p.ink2),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: p.ink,
                fontWeight: advisory ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Process badges (the web's .badge-* on the staff pages)
// ---------------------------------------------------------------------------

/// The tone of a process status (a request, a transfer, a sync, an
/// event's phase): the same square tinted badges the web and desktop
/// staff pages use, so staff read one vocabulary on every app. Never the
/// solid evacuation state colours: those belong to centers and barangays.
enum BadgeTone {
  /// Done, approved, received, accepted.
  success,

  /// Waiting, pending, details missing.
  warning,

  /// Rejected, returned, needs attention, high risk.
  danger,

  /// Information, such as an event that is only monitoring.
  info,

  /// Neutral or closed.
  neutral,
}

/// Background, text and border of a [BadgeTone] (tailwind's -50 tint,
/// -700/-800 text and a 20-30% ring; hydro tint for info, the sheet's
/// tinted greys for neutral). The night sheet gets deep tints with light
/// text. Every pair passes AA (test/app/theme/sheet_contrast_test.dart).
({Color bg, Color text, Color border}) badgeColours(
  BadgeTone tone, {
  required bool night,
}) {
  if (night) {
    return switch (tone) {
      BadgeTone.success => (
        bg: const Color(0xFF163A24),
        text: const Color(0xFFA7E3BC),
        border: const Color(0x594ADE80),
      ),
      BadgeTone.warning => (
        bg: const Color(0xFF3D2C0C),
        text: const Color(0xFFFCD38D),
        border: const Color(0x59F59E0B),
      ),
      BadgeTone.danger => (
        bg: const Color(0xFF431816),
        text: const Color(0xFFFCA5A5),
        border: const Color(0x59F87171),
      ),
      BadgeTone.info => (
        bg: const Color(0xFF1D3A52),
        text: Sheet.hydroTint,
        border: const Color(0x598CBDE3),
      ),
      BadgeTone.neutral => (
        bg: const Color(0xFF2C3F34),
        text: Sheet.paper3,
        border: const Color(0x59A9BAAE),
      ),
    };
  }
  return switch (tone) {
    BadgeTone.success => (
      bg: const Color(0xFFF0FDF4),
      text: const Color(0xFF166534),
      border: const Color(0x3316A34A),
    ),
    BadgeTone.warning => (
      bg: const Color(0xFFFFFBEB),
      text: const Color(0xFF92400E),
      border: const Color(0x4DD97706),
    ),
    BadgeTone.danger => (
      bg: const Color(0xFFFEF2F2),
      text: const Color(0xFFB91C1C),
      border: const Color(0x33DC2626),
    ),
    BadgeTone.info => (
      bg: Sheet.hydroTint,
      text: const Color(0xFF164A73),
      border: const Color(0x3322689F),
    ),
    BadgeTone.neutral => (
      bg: Sheet.paper2,
      text: const Color(0xFF38463E),
      border: const Color(0x335F6E64),
    ),
  };
}

/// A process status as the web's square tinted badge: light tint, dark
/// text, thin border, the words always shown.
class SheetBadge extends StatelessWidget {
  const SheetBadge({
    super.key,
    required this.label,
    required this.tone,
    this.icon,
  });

  final String label;
  final BadgeTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = badgeColours(
      tone,
      night: Theme.of(context).brightness == Brightness.dark,
    );
    // Its own width, also in a ListView (which would stretch it).
    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      heightFactor: 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: c.bg,
          border: Border.all(color: c.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: c.text),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: Sheet.bodyFont,
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                  color: c.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
