import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'sheet_tokens.dart';

export 'sheet_tokens.dart';

/// Tokens the Material 3 [ColorScheme] roles don't cover: a warning and
/// a success colour for plain messages (never for an evacuation state:
/// those are [Sheet]'s state colours), plus three names kept from the
/// earlier design so existing screens keep compiling. On the map sheet,
/// [navy] and [deepNavy] are the heading ink (paper at night) and
/// [lightBlue] the quiet hydro tint; bulletin navy itself is live status
/// only and lives in [Sheet.bulletin].
///
/// [warning] and [success] are dark enough to be text on the ground and
/// on their own light tints at WCAG AA (4.5:1).
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
    // 5.1:1 and 5.5:1 on map paper.
    warning: Color(0xFFA84E08),
    success: Color(0xFF13723A),
    navy: Sheet.ink,
    deepNavy: Sheet.ink,
    lightBlue: Sheet.hydroTint,
  );

  static const dark = AppSemanticColors(
    // 8.7:1 and 7.5:1 on the night ground.
    warning: Color(0xFFF0B45A),
    success: Color(0xFF5FC583),
    navy: Sheet.paper,
    deepNavy: Sheet.paper,
    lightBlue: Color(0xFF1D3A52),
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

/// E-LIKAS app theme: the "Ligao Map Sheet" (elikas-backend DESIGN.md).
///
/// Map paper and green-black ink, square corners everywhere (only full
/// circles stay round), ink rules instead of shadows (only things that
/// float, such as dialogs, menus, sheets and snackbars, cast one), sienna
/// as the one action colour, hydro blue for focus and captions.
/// Barlow Condensed names, labels and acts; Public Sans explains.
///
/// Dark mode is the "night sheet": the same system on an ink ground with
/// paper text. Buttons keep the sienna fill; sienna and hydro *text*
/// step lighter there so they still pass WCAG AA (see
/// test/app/theme/sheet_contrast_test.dart).
class AppTheme {
  AppTheme._();

  /// The body face (Public Sans).
  static const String fontFamily = Sheet.bodyFont;

  static const _square = RoundedRectangleBorder();

  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Sheet.sienna,
    onPrimary: Colors.white,
    primaryContainer: Sheet.siennaTint,
    onPrimaryContainer: Sheet.siennaDark,
    secondary: Sheet.hydro,
    onSecondary: Colors.white,
    secondaryContainer: Sheet.hydroTint,
    onSecondaryContainer: Color(0xFF164A73),
    tertiary: Sheet.ink,
    onTertiary: Sheet.paper,
    error: Sheet.errorInk,
    onError: Colors.white,
    errorContainer: Color(0xFFF9E3E0),
    onErrorContainer: Color(0xFF7A1A12),
    surface: Sheet.paper,
    onSurface: Sheet.ink,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: Sheet.paper,
    surfaceContainer: Sheet.paper2,
    surfaceContainerHigh: Sheet.paper2,
    surfaceContainerHighest: Sheet.paper3,
    onSurfaceVariant: Sheet.ink2,
    outline: Sheet.ink,
    outlineVariant: Sheet.paper3,
    shadow: Sheet.ink,
    scrim: Sheet.ink,
    inverseSurface: Sheet.ink,
    onInverseSurface: Sheet.paper,
    inversePrimary: Sheet.nightSiennaText,
    surfaceTint: Colors.transparent,
  );

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    // Sienna as text/icons on the ink ground; buttons keep Sheet.sienna.
    primary: Sheet.nightSiennaText,
    onPrimary: Sheet.ink,
    primaryContainer: Color(0xFF4A2A18),
    onPrimaryContainer: Sheet.siennaTint,
    secondary: Sheet.nightHydroText,
    onSecondary: Sheet.ink,
    secondaryContainer: Color(0xFF1D3A52),
    onSecondaryContainer: Sheet.hydroTint,
    tertiary: Sheet.paper,
    onTertiary: Sheet.ink,
    error: Sheet.nightErrorText,
    onError: Sheet.ink,
    errorContainer: Color(0xFF4A1A14),
    onErrorContainer: Color(0xFFFAD4CF),
    surface: Sheet.nightGround,
    onSurface: Sheet.paper,
    surfaceContainerLowest: Sheet.nightField,
    surfaceContainerLow: Sheet.nightPlate,
    surfaceContainer: Sheet.nightPlate,
    surfaceContainerHigh: Sheet.nightFold,
    surfaceContainerHighest: Sheet.nightFold,
    onSurfaceVariant: Sheet.nightText2,
    outline: Sheet.nightRule,
    outlineVariant: Sheet.nightCrease,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: Sheet.paper,
    onInverseSurface: Sheet.ink,
    inversePrimary: Sheet.sienna,
    surfaceTint: Colors.transparent,
  );

  static ThemeData get light => _themeFrom(_lightScheme);

  static ThemeData get dark => _themeFrom(_darkScheme);

  static ThemeData _themeFrom(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    final semantic = isDark ? AppSemanticColors.dark : AppSemanticColors.light;
    final sheet = isDark ? SheetPalette.night : SheetPalette.light;
    final text = _textThemeFrom(scheme);

    // 48 dp: the touch target for field use.
    const buttonMinSize = Size(64, 48);
    const buttonPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 12);
    final buttonText = text.labelLarge!;

    // Things that float over the page keep a soft shadow and an ink border.
    final floatingShape = RoundedRectangleBorder(
      side: BorderSide(color: sheet.rule, width: Sheet.frame),
    );
    final floatingShadow = Sheet.ink.withValues(alpha: isDark ? 0.6 : 0.18);

    OutlineInputBorder field(Color color, [double width = Sheet.rule]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: color, width: width),
        );
    final fieldColor = isDark ? Sheet.nightRule : Sheet.ink2;
    final focus = isDark ? Sheet.nightHydroText : Sheet.hydro;

    WidgetStateProperty<Color?> pressOverlay(Color c) =>
        WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.pressed) ||
                  s.contains(WidgetState.hovered)
              ? c.withValues(alpha: 0.12)
              : s.contains(WidgetState.focused)
              ? focus.withValues(alpha: 0.16)
              : null,
        );

    final sienna = ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.disabled)
            ? Sheet.sienna.withValues(alpha: 0.6)
            : s.contains(WidgetState.pressed)
            ? Sheet.siennaDark
            : Sheet.sienna,
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.disabled)
            ? Colors.white.withValues(alpha: 0.85)
            : Colors.white,
      ),
      iconColor: const WidgetStatePropertyAll(Colors.white),
      overlayColor: pressOverlay(Colors.black),
      elevation: const WidgetStatePropertyAll(0),
      shadowColor: const WidgetStatePropertyAll(Colors.transparent),
      shape: const WidgetStatePropertyAll(_square),
      padding: const WidgetStatePropertyAll(buttonPadding),
      minimumSize: const WidgetStatePropertyAll(buttonMinSize),
      textStyle: WidgetStatePropertyAll(buttonText),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      fontFamily: fontFamily,
      colorScheme: scheme,
      scaffoldBackgroundColor: sheet.ground,
      canvasColor: sheet.ground,
      textTheme: text,
      focusColor: focus.withValues(alpha: 0.16),
      splashFactory: InkRipple.splashFactory,
      dividerColor: sheet.rule,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: sheet.ink,
        selectionColor: isDark
            ? Sheet.sienna.withValues(alpha: 0.5)
            : Sheet.siennaTint,
        selectionHandleColor: scheme.primary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: sheet.ground,
        foregroundColor: sheet.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: text.titleLarge,
        shape: Border(
          bottom: BorderSide(color: sheet.rule, width: Sheet.rule),
        ),
        iconTheme: IconThemeData(color: sheet.ink),
        actionsIconTheme: IconThemeData(color: sheet.ink),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: sheet.plate,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: sheet.rule, width: Sheet.hairline),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(style: sienna),
      elevatedButtonTheme: ElevatedButtonThemeData(style: sienna),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled) ? sheet.ink3 : sheet.ink,
          ),
          iconColor: WidgetStatePropertyAll(sheet.ink),
          overlayColor: pressOverlay(sheet.ink),
          side: WidgetStateProperty.resolveWith(
            (s) => BorderSide(
              color: s.contains(WidgetState.disabled) ? sheet.ink3 : sheet.ink,
              width: Sheet.frame,
            ),
          ),
          shape: const WidgetStatePropertyAll(_square),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          minimumSize: const WidgetStatePropertyAll(buttonMinSize),
          textStyle: WidgetStatePropertyAll(buttonText),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled)
                ? sheet.ink3
                : sheet.actionText,
          ),
          iconColor: WidgetStatePropertyAll(sheet.actionText),
          overlayColor: pressOverlay(sheet.actionText),
          shape: const WidgetStatePropertyAll(_square),
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          textStyle: WidgetStatePropertyAll(buttonText),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(_square),
          overlayColor: pressOverlay(sheet.ink),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Sheet.sienna,
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(),
        elevation: 2,
        focusElevation: 2,
        hoverElevation: 3,
        highlightElevation: 3,
        extendedTextStyle: buttonText,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(_square),
          side: WidgetStatePropertyAll(
            BorderSide(color: sheet.ink, width: Sheet.rule),
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? sheet.ink : null,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? sheet.ground : sheet.ink,
          ),
          iconColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? sheet.ground : sheet.ink,
          ),
          textStyle: WidgetStatePropertyAll(text.labelMedium),
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: sheet.field,
        border: field(fieldColor),
        enabledBorder: field(fieldColor),
        focusedBorder: field(focus, 2.5),
        errorBorder: field(scheme.error),
        focusedErrorBorder: field(scheme.error, 2.5),
        disabledBorder: field(sheet.crease),
        hintStyle: TextStyle(color: sheet.ink3),
        labelStyle: TextStyle(color: sheet.ink2),
        floatingLabelStyle: WidgetStateTextStyle.resolveWith(
          (s) => TextStyle(
            color: s.contains(WidgetState.error)
                ? scheme.error
                : s.contains(WidgetState.focused)
                ? focus
                : sheet.ink2,
          ),
        ),
        prefixIconColor: sheet.ink2,
        suffixIconColor: sheet.ink2,
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          shape: WidgetStatePropertyAll(floatingShape),
          backgroundColor: WidgetStatePropertyAll(sheet.plate),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          elevation: const WidgetStatePropertyAll(4),
          shadowColor: WidgetStatePropertyAll(floatingShadow),
        ),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          shape: WidgetStatePropertyAll(floatingShape),
          backgroundColor: WidgetStatePropertyAll(sheet.plate),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          elevation: const WidgetStatePropertyAll(4),
          shadowColor: WidgetStatePropertyAll(floatingShadow),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        shape: floatingShape,
        color: sheet.plate,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shadowColor: floatingShadow,
        textStyle: text.bodyLarge,
      ),
      chipTheme: ChipThemeData(
        shape: const RoundedRectangleBorder(),
        side: BorderSide(color: sheet.ink, width: Sheet.rule),
        backgroundColor: sheet.ground,
        selectedColor: isDark ? const Color(0xFF4A2A18) : Sheet.siennaTint,
        checkmarkColor: sheet.actionText,
        labelStyle: text.labelMedium?.copyWith(color: sheet.ink),
        secondaryLabelStyle: text.labelMedium?.copyWith(color: sheet.ink),
        iconTheme: IconThemeData(color: sheet.ink, size: 18),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: const RoundedRectangleBorder(),
        side: BorderSide(color: sheet.ink2, width: Sheet.frame),
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Sheet.sienna : null,
        ),
        checkColor: const WidgetStatePropertyAll(Colors.white),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? scheme.primary : sheet.ink2,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : sheet.ink2,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Sheet.sienna : sheet.fold,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Sheet.sienna : sheet.ink2,
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: const RoundedRectangleBorder(),
        iconColor: sheet.ink2,
        textColor: sheet.ink,
        titleTextStyle: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        subtitleTextStyle: text.bodyMedium?.copyWith(color: sheet.ink2),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        shape: const RoundedRectangleBorder(),
        collapsedShape: const RoundedRectangleBorder(),
        iconColor: sheet.ink,
        collapsedIconColor: sheet.ink,
        textColor: sheet.ink,
        collapsedTextColor: sheet.ink,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: sheet.plate,
        surfaceTintColor: Colors.transparent,
        shape: floatingShape,
        elevation: 6,
        shadowColor: floatingShadow,
        titleTextStyle: text.headlineSmall,
        contentTextStyle: text.bodyLarge,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: sheet.plate,
        modalBackgroundColor: sheet.plate,
        surfaceTintColor: Colors.transparent,
        shape: Border(top: BorderSide(color: sheet.rule, width: Sheet.frame)),
        elevation: 6,
        modalElevation: 6,
        shadowColor: floatingShadow,
        dragHandleColor: sheet.ink3,
        dragHandleSize: const Size(40, 4),
        showDragHandle: false,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? Sheet.paper : Sheet.ink,
        contentTextStyle: text.bodyLarge?.copyWith(
          color: isDark ? Sheet.ink : Sheet.paper,
        ),
        actionTextColor: isDark ? Sheet.sienna : Sheet.nightSiennaText,
        shape: const RoundedRectangleBorder(),
        elevation: 4,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: isDark ? Sheet.paper : Sheet.ink),
        textStyle: text.bodyMedium?.copyWith(
          color: isDark ? Sheet.ink : Sheet.paper,
        ),
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: isDark ? Sheet.paper : Sheet.ink,
        textColor: isDark ? Sheet.ink : Sheet.paper,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: sheet.ink,
        linearTrackColor: sheet.crease,
        circularTrackColor: Colors.transparent,
        refreshBackgroundColor: sheet.plate,
        borderRadius: BorderRadius.zero,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: Sheet.sienna,
        thumbColor: Sheet.sienna,
        inactiveTrackColor: sheet.crease,
      ),
      dividerTheme: DividerThemeData(
        color: sheet.rule,
        space: 1,
        thickness: Sheet.hairline,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: sheet.ink,
        unselectedLabelColor: sheet.ink2,
        labelStyle: text.labelLarge,
        unselectedLabelStyle: text.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: sheet.actionText, width: 3),
        ),
        dividerColor: sheet.rule,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: sheet.plate,
        shape: const RoundedRectangleBorder(),
        endShape: const RoundedRectangleBorder(),
      ),
      searchBarTheme: SearchBarThemeData(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            side: BorderSide(color: sheet.ink, width: Sheet.frame),
          ),
        ),
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: WidgetStatePropertyAll(sheet.field),
      ),
      datePickerTheme: DatePickerThemeData(
        shape: floatingShape,
        backgroundColor: sheet.plate,
        surfaceTintColor: Colors.transparent,
        dayShape: const WidgetStatePropertyAll(CircleBorder()),
      ),
      timePickerTheme: TimePickerThemeData(
        shape: floatingShape,
        backgroundColor: sheet.plate,
        hourMinuteShape: const RoundedRectangleBorder(),
        dayPeriodShape: const RoundedRectangleBorder(),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: sheet.ground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        // The current tab: a sienna rule under its icon, like the web's
        // active nav underline (no tinted pill).
        indicatorColor: Colors.transparent,
        indicatorShape: Border(
          bottom: BorderSide(color: sheet.actionText, width: 3),
        ),
        // No custom height: Material 3's default (80) gives long labels
        // room to wrap to a second line without clipping.
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return text.labelSmall?.copyWith(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: selected ? sheet.ink : sheet.ink2,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? sheet.ink : sheet.ink2);
        }),
      ),
      extensions: [semantic, sheet],
    );
  }

  /// Barlow Condensed for display, headline, title and label (names,
  /// labels, buttons, big numbers); Public Sans for body (explaining).
  /// Nothing smaller than 14 on a phone; the condensed face runs a step
  /// larger than Public Sans to read at the same size.
  static TextTheme _textThemeFrom(ColorScheme scheme) {
    final ink = scheme.onSurface;
    final muted = scheme.onSurfaceVariant;

    TextStyle condensed(
      double px,
      FontWeight w,
      Color c, {
      double height = 0.95,
      double? spacing,
    }) => TextStyle(
      fontFamily: Sheet.labelFont,
      fontSize: px,
      height: height,
      fontWeight: w,
      letterSpacing: spacing ?? -0.005 * px,
      color: c,
    );

    TextStyle body(double px, double line, FontWeight w, Color c) => TextStyle(
      fontFamily: Sheet.bodyFont,
      fontSize: px,
      height: line,
      fontWeight: w,
      color: c,
    );

    return TextTheme(
      displayLarge: condensed(44, FontWeight.w800, ink),
      displayMedium: condensed(40, FontWeight.w800, ink),
      displaySmall: condensed(36, FontWeight.w800, ink),
      headlineLarge: condensed(34, FontWeight.w800, ink),
      headlineMedium: condensed(30, FontWeight.w800, ink),
      // Page titles and headline figures.
      headlineSmall: condensed(28, FontWeight.w800, ink, height: 1.0),
      // Section titles and the app bar.
      titleLarge: condensed(23, FontWeight.w800, ink, height: 1.05),
      // Card titles: the name of a center, an alert, a family.
      titleMedium: condensed(20, FontWeight.w700, ink, height: 1.1),
      titleSmall: condensed(18, FontWeight.w700, ink, height: 1.1),
      bodyLarge: body(15, 1.5, FontWeight.w400, ink),
      bodyMedium: body(14, 1.5, FontWeight.w400, ink),
      bodySmall: body(14, 1.45, FontWeight.w400, muted),
      // Buttons.
      labelLarge: condensed(18, FontWeight.w700, ink, height: 1.1, spacing: 1.2),
      labelMedium: condensed(
        16,
        FontWeight.w600,
        ink,
        height: 1.15,
        spacing: 0.6,
      ),
      labelSmall: condensed(
        15,
        FontWeight.w600,
        muted,
        height: 1.15,
        spacing: 0.6,
      ),
    );
  }
}
