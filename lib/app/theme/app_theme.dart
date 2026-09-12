import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Brand tokens the Material 3 [ColorScheme] roles don't cover:
/// warning/success (no such roles exist), plus the two navy shades and
/// light-blue tint used for the branded header and highlighted
/// containers across the E-LIKAS web dashboard. Kept as a
/// [ThemeExtension] — same pattern the project already used for
/// warning/success — rather than hardcoded [Colors] constants in a
/// widget, so dark mode and any future re-theming stay centralized here.
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
    warning: Color(0xFFF59E0B),
    success: Color(0xFF1EAF63),
    navy: Color(0xFF082B5C),
    deepNavy: Color(0xFF041F46),
    lightBlue: Color(0xFFEAF2FF),
  );

  static const dark = AppSemanticColors(
    warning: Color(0xFFFFB74D),
    success: Color(0xFF5FD996),
    navy: Color(0xFF0E3B7A),
    deepNavy: Color(0xFF041F46),
    lightBlue: Color(0xFF13294D),
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
/// An explicit [ColorScheme] built from the brand palette (matching the
/// web admin dashboard's navy/blue/red/green/orange) rather than
/// [ColorScheme.fromSeed] — the brand colors are specified exactly, not
/// derived algorithmically, so the mobile app and the web dashboard
/// read as the same product.
class AppTheme {
  AppTheme._();

  static const Color _primaryBlue = Color(0xFF1769E0);
  static const Color _lightBlue = Color(0xFFEAF2FF);
  static const Color _navy = Color(0xFF082B5C);
  static const Color _deepNavy = Color(0xFF041F46);
  static const Color _emergencyRed = Color(0xFFE5242A);
  static const Color _background = Color(0xFFF5F7FB);
  static const Color _cardSurface = Color(0xFFFFFFFF);
  static const Color _primaryText = Color(0xFF10213D);
  static const Color _secondaryText = Color(0xFF667085);
  static const Color _border = Color(0xFFE4E9F2);

  static final ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: _primaryBlue,
    onPrimary: Colors.white,
    primaryContainer: _lightBlue,
    onPrimaryContainer: _navy,
    secondary: _navy,
    onSecondary: Colors.white,
    secondaryContainer: _lightBlue,
    onSecondaryContainer: _navy,
    tertiary: _deepNavy,
    onTertiary: Colors.white,
    error: _emergencyRed,
    onError: Colors.white,
    errorContainer: const Color(0xFFFCE4E4),
    onErrorContainer: const Color(0xFF7A1216),
    surface: _cardSurface,
    onSurface: _primaryText,
    surfaceContainerHighest: const Color(0xFFEDF1F7),
    onSurfaceVariant: _secondaryText,
    outline: _border,
    outlineVariant: _border,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: _deepNavy,
    onInverseSurface: Colors.white,
    inversePrimary: _lightBlue,
  );

  static final ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: const Color(0xFF6CA6F5),
    onPrimary: _deepNavy,
    primaryContainer: const Color(0xFF13294D),
    onPrimaryContainer: _lightBlue,
    secondary: const Color(0xFF6CA6F5),
    onSecondary: _deepNavy,
    secondaryContainer: const Color(0xFF13294D),
    onSecondaryContainer: _lightBlue,
    tertiary: _lightBlue,
    onTertiary: _deepNavy,
    error: const Color(0xFFFF6B6B),
    onError: _deepNavy,
    errorContainer: const Color(0xFF5C1A1D),
    onErrorContainer: const Color(0xFFFCE4E4),
    surface: const Color(0xFF0F1B2E),
    onSurface: const Color(0xFFE7ECF3),
    surfaceContainerHighest: const Color(0xFF1B2A45),
    onSurfaceVariant: const Color(0xFFA6B1C4),
    outline: const Color(0xFF2C3B57),
    outlineVariant: const Color(0xFF2C3B57),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: const Color(0xFFE7ECF3),
    onInverseSurface: _deepNavy,
    inversePrimary: _primaryBlue,
  );

  static ThemeData get light => _themeFrom(_lightScheme);

  static ThemeData get dark => _themeFrom(_darkScheme);

  static ThemeData _themeFrom(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    final semanticColors = isDark
        ? AppSemanticColors.dark
        : AppSemanticColors.light;
    final textTheme = _textThemeFrom(colorScheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? colorScheme.surface : _background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outline),
        ),
      ),
      dividerTheme: DividerThemeData(color: colorScheme.outline, space: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: semanticColors.lightBlue,
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
                ? semanticColors.navy
                : colorScheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected
                ? semanticColors.navy
                : colorScheme.onSurfaceVariant,
          );
        }),
      ),
      extensions: [semanticColors],
    );
  }

  /// Hierarchy per the design spec: page title 24–28 bold, section
  /// title 17–19 semibold, card title 13–15 semibold, metric value
  /// 22–28 bold, supporting text 12–14, labels medium weight.
  static TextTheme _textThemeFrom(ColorScheme colorScheme) {
    final base = Typography.material2021(colorScheme: colorScheme).englishLike
        .merge(Typography.material2021(colorScheme: colorScheme).black);
    return base
        .copyWith(
          headlineSmall: base.headlineSmall?.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
          titleLarge: base.titleLarge?.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w700,
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
        .apply(fontSizeFactor: 1.0);
  }
}
