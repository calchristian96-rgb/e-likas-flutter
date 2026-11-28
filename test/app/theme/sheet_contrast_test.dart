import 'package:elikas_mobile/app/theme/app_theme.dart';
import 'package:elikas_mobile/core/widgets/map_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG 2.2 contrast ratio of two opaque colours.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  // Text needs 4.5:1 (AA); a symbol or a control's edge needs 3:1.
  group('map sheet (light)', () {
    const p = SheetPalette.light;
    test('text on the ground passes AA', () {
      for (final c in [p.ink, p.ink2, p.actionText, p.caption, p.errorText]) {
        expect(contrast(c, p.ground), greaterThanOrEqualTo(4.5), reason: '$c');
        expect(contrast(c, p.fold), greaterThanOrEqualTo(4.5), reason: '$c');
      }
    });
    test('semantic warning and success are readable as text', () {
      const s = AppSemanticColors.light;
      expect(contrast(s.warning, p.ground), greaterThanOrEqualTo(4.5));
      expect(contrast(s.success, p.ground), greaterThanOrEqualTo(4.5));
    });
  });

  group('night sheet (dark)', () {
    const p = SheetPalette.night;
    test('text on the ground, plates and folds passes AA', () {
      for (final bg in [p.ground, p.plate, p.fold]) {
        for (final c in [p.ink, p.ink2, p.actionText, p.caption, p.errorText]) {
          expect(contrast(c, bg), greaterThanOrEqualTo(4.5), reason: '$c/$bg');
        }
      }
    });
    test('the rule is visible (3:1) and ink-3 icons too', () {
      expect(contrast(p.rule, p.ground), greaterThanOrEqualTo(3));
      expect(contrast(p.ink3, p.ground), greaterThanOrEqualTo(3));
    });
    test('semantic warning and success are readable as text', () {
      const s = AppSemanticColors.dark;
      expect(contrast(s.warning, p.plate), greaterThanOrEqualTo(4.5));
      expect(contrast(s.success, p.plate), greaterThanOrEqualTo(4.5));
    });
    test('every center symbol stands off the ground (3:1)', () {
      // Filled discs carry a paper stroke at night; standby and closed
      // are drawn on a white face.
      expect(contrast(p.symbolStroke, p.ground), greaterThanOrEqualTo(3));
      expect(contrast(Colors.white, p.ground), greaterThanOrEqualTo(3));
    });
  });

  group('fixed colours', () {
    test('white on the sienna button passes AA', () {
      expect(contrast(Colors.white, Sheet.sienna), greaterThanOrEqualTo(4.5));
    });
    test('barangay tags use a text colour that passes AA', () {
      expect(
        contrast(Sheet.barangayWatchText, Sheet.barangayWatch),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrast(Sheet.ink, Sheet.barangayFlooding),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrast(Colors.white, Sheet.barangayPreemptive),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrast(Colors.white, Sheet.barangayForced),
        greaterThanOrEqualTo(4.5),
      );
    });
    test('the live strip text passes AA on bulletin navy', () {
      expect(
        contrast(Sheet.bulletinText, Sheet.bulletin),
        greaterThanOrEqualTo(4.5),
      );
      expect(contrast(Colors.white, Sheet.bulletin), greaterThanOrEqualTo(4.5));
    });
  });

  test(
    'process badges: dark text on their tint passes AA, light and night',
    () {
      for (final night in [false, true]) {
        for (final tone in BadgeTone.values) {
          final c = badgeColours(tone, night: night);
          expect(
            contrast(c.text, c.bg),
            greaterThanOrEqualTo(4.5),
            reason: '$tone night=$night',
          );
        }
      }
    },
  );
}
