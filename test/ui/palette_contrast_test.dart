import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manager_bot/core/ui/palette.dart';

/// The palette is allowed to be loud. It is NOT allowed to be unreadable.
///
/// Every colour that can carry text is checked against the surfaces it can
/// actually land on, at the WCAG AA threshold for body text (4.5:1). If a
/// future "let's make it more neon" edit muddies a tone, this fails before the
/// screens do.
void main() {
  const double aa = 4.5;

  double onCanvas(Color color) =>
      AppPalette.contrastRatio(color, AppPalette.canvas);

  group('AppPalette contrast', () {
    test('contrastRatio is symmetric, and 1.0 against itself', () {
      expect(
        AppPalette.contrastRatio(AppPalette.canvas, AppPalette.canvas),
        closeTo(1, 0.0001),
      );
      expect(
        AppPalette.contrastRatio(AppPalette.textPrimary, AppPalette.canvas),
        closeTo(
          AppPalette.contrastRatio(AppPalette.canvas, AppPalette.textPrimary),
          0.0001,
        ),
      );
    });

    test('text colours clear AA on the darkest surface', () {
      const Map<String, Color> texts = <String, Color>{
        'textPrimary': AppPalette.textPrimary,
        'textSecondary': AppPalette.textSecondary,
        'textTertiary': AppPalette.textTertiary,
        'textDisabled': AppPalette.textDisabled,
      };
      for (final MapEntry<String, Color> entry in texts.entries) {
        expect(
          onCanvas(entry.value),
          greaterThanOrEqualTo(aa),
          reason: entry.key,
        );
      }
    });

    test('accents are vibrant AND readable on the darkest surface', () {
      const Map<String, Color> accents = <String, Color>{
        'accentCyan': AppPalette.accentCyan,
        'accentCyanDeep': AppPalette.accentCyanDeep,
        'accentPink': AppPalette.accentPink,
        'accentMagenta': AppPalette.accentMagenta,
        'accentViolet': AppPalette.accentViolet,
        'accentAmber': AppPalette.accentAmber,
        'moneyPositive': AppPalette.moneyPositive,
        'moneyNegative': AppPalette.moneyNegative,
      };
      for (final MapEntry<String, Color> entry in accents.entries) {
        expect(
          onCanvas(entry.value),
          greaterThanOrEqualTo(aa),
          reason: entry.key,
        );
      }
    });

    test('every tone foreground clears AA on all three card surfaces', () {
      const List<Color> surfaces = <Color>[
        AppPalette.canvas,
        AppPalette.surface0,
        AppPalette.surface1,
        AppPalette.surface2,
      ];
      for (final AppTone tone in AppPalette.allTones) {
        final ToneColors colors = AppPalette.tone(tone);
        for (final Color surface in surfaces) {
          expect(
            AppPalette.contrastRatio(colors.foreground, surface),
            greaterThanOrEqualTo(aa),
            reason: '$tone on $surface',
          );
        }
      }
    });

    test('the on-accent ink clears AA on every signature gradient stop', () {
      for (final Color stop in AppPalette.gradientSignature.colors) {
        expect(
          AppPalette.contrastRatio(AppPalette.textOnAccent, stop),
          greaterThanOrEqualTo(aa),
          reason: '$stop',
        );
      }
    });

    test('surface tiers step up in lightness, canvas darkest', () {
      final List<double> luminance = <double>[
        AppPalette.canvas.computeLuminance(),
        AppPalette.surface0.computeLuminance(),
        AppPalette.surface1.computeLuminance(),
        AppPalette.surface2.computeLuminance(),
        AppPalette.surface3.computeLuminance(),
      ];
      for (int i = 1; i < luminance.length; i++) {
        expect(luminance[i], greaterThan(luminance[i - 1]), reason: 'tier $i');
      }
    });
  });
}
