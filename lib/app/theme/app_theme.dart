import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Brand tokens the Material 3 [ColorScheme] roles don't cover:
/// warning/success (no such roles exist), plus the two navy shades and
/// light-blue tint used for the branded header and highlighted
/// containers. Kept as a [ThemeExtension] — same pattern the project
/// already used for warning/success — rather than hardcoded [Colors]
/// constants in a widget, so dark mode and any future re-theming stay
/// centralized here.
///
/// The values are the E-LIKAS design system's (the web dashboard's
/// docs/design-system.md): [navy] is the logo's own navy, and
/// [warning]/[success] are dark enough to be used as *text* on white or
/// on their own light tints at WCAG AA (4.5:1), not just as icon fills.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.warning,
    required this.success,
    required this.navy,
    required this.deepNavy,
    required this.lightBlue,
  });

  final Color warning;
  final Color success;
  final Color navy;
  final Color deepNavy;
  final Color lightBlue;

  static const light = AppSemanticColors(
    // Both are used as text on their own 6-15% tints (badges, callouts),
    // so they're picked to clear 4.5:1 there too: 4.51:1 (warning) and
    // 4.83:1 (success) on a 15% tint, 5.6:1 and 6.0:1 on white.
    warning: Color(0xFFA84E08),
    success: Color(0xFF13723A),
    navy: Color(0xFF094776),
    deepNavy: Color(0xFF073A61),
    lightBlue: Color(0xFFEFF6FF),
  );

  static const dark = AppSemanticColors(
    warning: Color(0xFFFBBF24),
    success: Color(0xFF4ADE80),
    navy: Color(0xFF094776),
    deepNavy: Color(0xFF062B48),
    lightBlue: Color(0xFF172554),
  );

  @override
  AppSemanticColors copyWith({
    Color? warning,
    Color? success,
    Color? navy,
    Color? deepNavy,
    Color? lightBlue,
  }) {
    return AppSemanticColors(
      warning: warning ?? this.warning,
      success: success ?? this.success,
      navy: navy ?? this.navy,
      deepNavy: deepNavy ?? this.deepNavy,
      lightBlue: lightBlue ?? this.lightBlue,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      warning: Color.lerp(warning, other.warning, t)!,
      success: Color.lerp(success, other.success, t)!,
      navy: Color.lerp(navy, other.navy, t)!,
      deepNavy: Color.lerp(deepNavy, other.deepNavy, t)!,
      lightBlue: Color.lerp(lightBlue, other.lightBlue, t)!,
    );
  }
}

/// E-LIKAS app theme.
///
/// An explicit [ColorScheme] built from the E-LIKAS design system — the
/// same tokens as the web dashboard and the desktop app (brand blue
/// #2563EB, the logo's navy #094776, gray neutrals, red for danger) —
/// rather than [ColorScheme.fromSeed]: the brand colors are specified
/// exactly, not derived algorithmically, so the three apps read as the
/// same product. Typeface: Public Sans, bundled in assets/fonts/.
class AppTheme {
  AppTheme._();

  static const String fontFamily = 'PublicSans';

  static const Color _brandBlue = Color(0xFF2563EB);
  static const Color _brandBlue100 = Color(0xFFDBEAFE);
  static const Color _navy = Color(0xFF094776);
  static const Color _deepNavy = Color(0xFF073A61);
  static const Color _danger = Color(0xFFDC2626);
  static const Color _background = Color(0xFFF9FAFB); // gray-50
  static const Color _cardSurface = Color(0xFFFFFFFF);
  static const Color _primaryText = Color(0xFF111827); // gray-900
  static const Color _secondaryText = Color(0xFF4B5563); // gray-600, 7.56:1
  static const Color _border = Color(0xFFE5E7EB); // gray-200
  static const Color _buttonBorder = Color(0xFFD1D5DB); // gray-300

  /// Form-field border: 3.30:1 on white, the WCAG 1.4.11 minimum for a
  /// control's boundary (the card border above is far lighter).
  static const Color _fieldBorder = Color(0xFF868E9C);

  static final ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: _brandBlue,
    onPrimary: Colors.white,
    primaryContainer: _brandBlue100,
    onPrimaryContainer: _navy,
    secondary: _navy,
    onSecondary: Colors.white,
    secondaryContainer: const Color(0xFFEFF6FF),
    onSecondaryContainer: _navy,
    tertiary: _deepNavy,
    onTertiary: Colors.white,
    error: _danger,
    onError: Colors.white,
    errorContainer: const Color(0xFFFEF2F2),
    onErrorContainer: const Color(0xFF991B1B),
    surface: _cardSurface,
    onSurface: _primaryText,
    surfaceContainerHighest: const Color(0xFFF3F4F6),
    onSurfaceVariant: _secondaryText,
    outline: _border,
    outlineVariant: _border,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: const Color(0xFF1F2937),
    onInverseSurface: Colors.white,
    inversePrimary: const Color(0xFF93C5FD),
  );

  static final ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: const Color(0xFF60A5FA),
    onPrimary: const Color(0xFF0F172A),
    primaryContainer: const Color(0xFF1E3A8A),
    onPrimaryContainer: _brandBlue100,
    secondary: const Color(0xFF93C5FD),
    onSecondary: const Color(0xFF0F172A),
    secondaryContainer: const Color(0xFF1E3A8A),
    onSecondaryContainer: _brandBlue100,
    tertiary: _brandBlue100,
    onTertiary: _deepNavy,
    error: const Color(0xFFF87171),
    onError: const Color(0xFF450A0A),
    errorContainer: const Color(0xFF7F1D1D),
    onErrorContainer: const Color(0xFFFEE2E2),
    surface: const Color(0xFF111827),
    onSurface: const Color(0xFFF3F4F6),
    surfaceContainerHighest: const Color(0xFF1F2937),
    onSurfaceVariant: const Color(0xFF9CA3AF),
    outline: const Color(0xFF374151),
    outlineVariant: const Color(0xFF374151),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: const Color(0xFFF3F4F6),
    onInverseSurface: const Color(0xFF111827),
    inversePrimary: _brandBlue,
  );

  static ThemeData get light => _themeFrom(_lightScheme);

  static ThemeData get dark => _themeFrom(_darkScheme);

  static ThemeData _themeFrom(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    final semanticColors = isDark
        ? AppSemanticColors.dark
        : AppSemanticColors.light;
    final textTheme = _textThemeFrom(colorScheme);

    // One shape for every button and field, like the web's rounded-lg.
    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    );
    const buttonPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 10);
    // 44 logical px: the minimum comfortable touch target height.
    const buttonMinSize = Size(64, 44);
    final buttonText = textTheme.labelLarge?.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w600,
    );
    final fieldBorderColor = isDark ? const Color(0xFF6B7280) : _fieldBorder;
    OutlineInputBorder fieldBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? colorScheme.surface : _background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleMedium?.copyWith(fontSize: 19),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outline),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: controlShape,
          padding: buttonPadding,
          minimumSize: buttonMinSize,
          textStyle: buttonText,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: controlShape,
          padding: buttonPadding,
          minimumSize: buttonMinSize,
          textStyle: buttonText,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: controlShape,
          padding: buttonPadding,
          minimumSize: buttonMinSize,
          textStyle: buttonText,
          side: BorderSide(color: isDark ? colorScheme.outline : _buttonBorder),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(shape: controlShape, textStyle: buttonText),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: fieldBorder(fieldBorderColor),
        enabledBorder: fieldBorder(fieldBorderColor),
        focusedBorder: fieldBorder(colorScheme.primary, 2),
        errorBorder: fieldBorder(colorScheme.error),
        focusedErrorBorder: fieldBorder(colorScheme.error, 2),
        disabledBorder: fieldBorder(colorScheme.outline),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: isDark ? colorScheme.outline : _buttonBorder),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      snackBarTheme: SnackBarThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dividerTheme: DividerThemeData(color: colorScheme.outline, space: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        elevation: 0,
        // No custom height override: Material 3's own default (80) is
        // what gives longer labels like "Nearest Center" room to wrap
        // to a second line without clipping — a smaller custom value
        // here reintroduces exactly that clipping.
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected
                ? (isDark ? colorScheme.onSurface : semanticColors.navy)
                : colorScheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected
                ? (isDark ? colorScheme.onSurface : semanticColors.navy)
                : colorScheme.onSurfaceVariant,
          );
        }),
      ),
      extensions: [semanticColors],
    );
  }

  /// Hierarchy per the design spec: page title 24–28, section title
  /// 17–19, card title 13–15, metric value 22–28, supporting text 12–14,
  /// labels medium weight. Titles are semibold, as on the web dashboard.
  static TextTheme _textThemeFrom(ColorScheme colorScheme) {
    final base = Typography.material2021(colorScheme: colorScheme).englishLike
        .merge(Typography.material2021(colorScheme: colorScheme).black);
    return base
        .copyWith(
          headlineSmall: base.headlineSmall?.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
          titleLarge: base.titleLarge?.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
          titleMedium: base.titleMedium?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
          titleSmall: base.titleSmall?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
          bodyLarge: base.bodyLarge?.copyWith(
            fontSize: 15,
            color: colorScheme.onSurface,
          ),
          bodyMedium: base.bodyMedium?.copyWith(
            fontSize: 14,
            color: colorScheme.onSurface,
          ),
          bodySmall: base.bodySmall?.copyWith(
            fontSize: 12.5,
            color: colorScheme.onSurfaceVariant,
          ),
          // The one style this override block used to leave out —
          // `Typography.material2021(...).black` (the "black" half of
          // the `.merge()` above) colors it for a light background, so
          // on this app's dark theme it rendered as near-invisible
          // dark-on-dark text. Every field-group label that uses
          // `labelLarge` (Add Evacuee's "Sex"/"Age Bracket" headers,
          // the sectoral/4Ps form's category names) was silently
          // affected until this was added alongside its siblings above.
          labelLarge: base.labelLarge?.copyWith(color: colorScheme.onSurface),
          labelMedium: base.labelMedium?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
          labelSmall: base.labelSmall?.copyWith(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        )
        .apply(fontSizeFactor: 1.0, fontFamily: fontFamily);
  }
}
