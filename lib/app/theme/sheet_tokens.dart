import 'package:flutter/material.dart';

/// The "Ligao Map Sheet" tokens, the same values as the web
/// (elikas-backend DESIGN.md and tailwind.public.config.cjs) and the
/// desktop app, so the three E-LIKAS apps read as one printed sheet.
///
/// Sienna is the only action colour. Hydro blue is the caption voice and
/// the focus ring. Bulletin navy and signal yellow are for live status
/// only (the live strip). The state colours mean their state and nothing
/// else, in every app.
abstract final class Sheet {
  // Map paper and ink.
  static const paper = Color(0xFFF3F5EF);
  static const paper2 = Color(0xFFE8ECE2);
  static const paper3 = Color(0xFFDCE3D3);
  static const ink = Color(0xFF17241D);
  static const ink2 = Color(0xFF46564C);

  /// Placeholders and secondary icons only (4.1:1 on paper: not for text).
  static const ink3 = Color(0xFF6B7A70);

  // The one action colour.
  static const sienna = Color(0xFF9C4F27);
  static const siennaDark = Color(0xFF7E3E1D);
  static const siennaTint = Color(0xFFF2E4DA);

  // Captions, the focus ring, water.
  static const hydro = Color(0xFF22689F);
  static const hydroTint = Color(0xFFDCE9F3);
  static const veg = Color(0xFFD6E6C6);

  // Live status only.
  static const bulletin = Color(0xFF0B2A5B);
  static const bulletin2 = Color(0xFF13396F);
  static const bulletinText = Color(0xFFC9D7EC);
  static const signal = Color(0xFFF6C400);

  static const errorInk = Color(0xFFB42318);

  // Evacuation-center states (shape + pattern + colour + label).
  static const centerActive = Color(0xFF15803D);
  static const centerNearlyFull = Color(0xFFD97706);
  static const centerFull = Color(0xFFDC2626);
  static const centerOnStandby = Color(0xFF2563EB);
  static const centerClosed = Color(0xFF4B5563);

  // Barangay states, with the text colour each one needs.
  static const barangayWatch = Color(0xFFFACC15);
  static const barangayWatchText = Color(0xFF422006);
  static const barangayFlooding = Color(0xFFF97316);
  static const barangayPreemptive = Color(0xFFDC2626);
  static const barangayForced = Color(0xFF7F1D1D);

  // The night sheet (dark mode): ink ground, paper text.
  static const nightGround = Color(0xFF17241D);
  static const nightPlate = Color(0xFF1E2D25);
  static const nightFold = Color(0xFF24352C);
  static const nightCrease = Color(0xFF33463B);
  static const nightText2 = Color(0xFFC4CEC6);
  static const nightText3 = Color(0xFF93A398);
  static const nightRule = Color(0xFFA9BAAE);
  static const nightField = Color(0xFF101A14);

  /// Sienna as text or an icon on the night ground (7.4:1); the button
  /// fill itself stays [sienna].
  static const nightSiennaText = Color(0xFFE3A27C);
  static const nightHydroText = Color(0xFF8CBDE3);
  static const nightErrorText = Color(0xFFF4A097);

  // Typefaces, all bundled in assets/fonts/ so they work offline.
  static const labelFont = 'BarlowCondensed';
  static const bodyFont = 'PublicSans';
  static const captionFont = 'SourceSerif4';

  /// The map-label tracking (0.14em) for a given font size.
  static double tracking(double fontSize) => fontSize * 0.14;

  /// Border weights: hairline rules, fields and margin heads, frames.
  static const double hairline = 1;
  static const double rule = 1.5;
  static const double frame = 2;
}

/// The sheet's roles for the current brightness: what a widget should
/// paint with, rather than picking light or night values itself.
@immutable
class SheetPalette extends ThemeExtension<SheetPalette> {
  const SheetPalette({
    required this.ground,
    required this.plate,
    required this.fold,
    required this.crease,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.rule,
    required this.actionText,
    required this.caption,
    required this.field,
    required this.symbolStroke,
    required this.errorText,
  });

  /// Page background.
  final Color ground;

  /// Plates, cards, bars.
  final Color plate;

  /// A recessed panel (paper-2).
  final Color fold;

  /// Soft dividers inside a menu (paper-3).
  final Color crease;

  /// Headings and strong text, and the frames round plates.
  final Color ink;

  /// Body copy and labels.
  final Color ink2;

  /// Placeholders and secondary icons only.
  final Color ink3;

  /// Rules and borders.
  final Color rule;

  /// Text links and sienna icons (the button fill is always [Sheet.sienna]).
  final Color actionText;

  /// The italic serif caption colour.
  final Color caption;

  /// Inside a text field.
  final Color field;

  /// The outline round a filled center symbol: ink on paper, paper at night.
  final Color symbolStroke;

  /// Inline error sentences.
  final Color errorText;

  static const light = SheetPalette(
    ground: Sheet.paper,
    plate: Sheet.paper,
    fold: Sheet.paper2,
    crease: Sheet.paper3,
    ink: Sheet.ink,
    ink2: Sheet.ink2,
    ink3: Sheet.ink3,
    rule: Sheet.ink,
    actionText: Sheet.sienna,
    caption: Sheet.hydro,
    field: Colors.white,
    symbolStroke: Sheet.ink,
    errorText: Sheet.errorInk,
  );

  static const night = SheetPalette(
    ground: Sheet.nightGround,
    plate: Sheet.nightPlate,
    fold: Sheet.nightFold,
    crease: Sheet.nightCrease,
    ink: Sheet.paper,
    ink2: Sheet.nightText2,
    ink3: Sheet.nightText3,
    rule: Sheet.nightRule,
    actionText: Sheet.nightSiennaText,
    caption: Sheet.nightHydroText,
    field: Sheet.nightField,
    symbolStroke: Sheet.paper,
    errorText: Sheet.nightErrorText,
  );

  /// The palette of [context]'s theme.
  static SheetPalette of(BuildContext context) =>
      Theme.of(context).extension<SheetPalette>() ?? light;

  @override
  SheetPalette copyWith({
    Color? ground,
    Color? plate,
    Color? fold,
    Color? crease,
    Color? ink,
    Color? ink2,
    Color? ink3,
    Color? rule,
    Color? actionText,
    Color? caption,
    Color? field,
    Color? symbolStroke,
    Color? errorText,
  }) => SheetPalette(
    ground: ground ?? this.ground,
    plate: plate ?? this.plate,
    fold: fold ?? this.fold,
    crease: crease ?? this.crease,
    ink: ink ?? this.ink,
    ink2: ink2 ?? this.ink2,
    ink3: ink3 ?? this.ink3,
    rule: rule ?? this.rule,
    actionText: actionText ?? this.actionText,
    caption: caption ?? this.caption,
    field: field ?? this.field,
    symbolStroke: symbolStroke ?? this.symbolStroke,
    errorText: errorText ?? this.errorText,
  );

  @override
  SheetPalette lerp(ThemeExtension<SheetPalette>? other, double t) {
    if (other is! SheetPalette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return SheetPalette(
      ground: l(ground, other.ground),
      plate: l(plate, other.plate),
      fold: l(fold, other.fold),
      crease: l(crease, other.crease),
      ink: l(ink, other.ink),
      ink2: l(ink2, other.ink2),
      ink3: l(ink3, other.ink3),
      rule: l(rule, other.rule),
      actionText: l(actionText, other.actionText),
      caption: l(caption, other.caption),
      field: l(field, other.field),
      symbolStroke: l(symbolStroke, other.symbolStroke),
      errorText: l(errorText, other.errorText),
    );
  }
}

/// Type styles the [TextTheme] has no slot for.
abstract final class SheetText {
  /// Map-label caps: margin heads, field labels, the issuing line. Give
  /// it an upper-cased string.
  static TextStyle label(Color color, {double size = 14}) => TextStyle(
    fontFamily: Sheet.labelFont,
    fontWeight: FontWeight.w600,
    fontSize: size,
    height: 1.1,
    letterSpacing: Sheet.tracking(size),
    color: color,
  );

  /// Condensed extra-bold caps for titles and big numbers.
  static TextStyle title(Color color, {double size = 28}) => TextStyle(
    fontFamily: Sheet.labelFont,
    fontWeight: FontWeight.w800,
    fontSize: size,
    height: 0.95,
    letterSpacing: -0.005 * size,
    color: color,
  );

  /// The cartographer's annotation: Source Serif 4 italic 500.
  static TextStyle caption(Color color, {double size = 15}) => TextStyle(
    fontFamily: Sheet.captionFont,
    fontStyle: FontStyle.italic,
    fontWeight: FontWeight.w500,
    fontVariations: const [FontVariation('wght', 500)],
    fontSize: size,
    height: 1.4,
    color: color,
  );
}
