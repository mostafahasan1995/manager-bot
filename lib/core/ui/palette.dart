import 'package:flutter/material.dart';

/// Semantic meaning of a money state, independent of the enum it came from.
///
/// A feature maps its own status enum onto one of these and every widget in the
/// kit colours the same idea the same way. This is deliberately SEPARATE from
/// `StatusTone` in `core/theme/app_theme.dart`, which belongs to the flat admin
/// console: the player app has its own, brighter register.
enum AppTone {
  /// Submitted, under review, waiting on a human. Amber.
  pending,

  /// A human said yes; the credit has not landed yet. Cyan.
  approved,

  /// Money is in the casino balance. Green.
  credited,

  /// Refused, reversed, expired-with-loss. Red.
  rejected,

  /// The player must do something: better proof, wrong amount, expiring soon.
  /// Orange.
  attention,

  /// Neutral information in motion. Violet.
  info,

  /// Nothing to say. Grey.
  neutral,
}

/// The four colours one [AppTone] needs on a near-black canvas.
///
/// [foreground] is the only one ever used for text or an icon, and every
/// foreground in [AppPalette] clears 4.5:1 against [AppPalette.canvas] - see
/// `test/ui/palette_contrast_test.dart`, which fails the build if a future edit
/// muddies one.
@immutable
class ToneColors {
  const ToneColors({
    required this.foreground,
    required this.background,
    required this.border,
    required this.glow,
  });

  /// Text and icons. Opaque, high contrast.
  final Color foreground;

  /// Chip / pill fill. Translucent so it works on any surface tier.
  final Color background;

  /// 1px hairline around the fill.
  final Color border;

  /// Soft outer bloom, for `BoxShadow.color`. Never used for text.
  final Color glow;
}

/// The colour system for the player app.
///
/// Near-black canvas, layered surface tiers, one signature gradient, a cyan
/// family accent and money-semantic tones. Everything is `const`, so the whole
/// palette is usable inside `const` constructors.
///
/// ```dart
/// Container(
///   decoration: BoxDecoration(
///     color: AppPalette.surface1,
///     borderRadius: AppRadii.mdRadius,
///     border: Border.all(color: AppPalette.outline),
///   ),
/// )
/// ```
abstract final class AppPalette {
  // --- canvas and surface tiers -------------------------------------------

  /// The page behind everything. Near-black, very slightly blue.
  static const Color canvas = Color(0xFF07070C);

  /// Sunken areas: the scroll body under a raised bar, sheet backdrops.
  static const Color surface0 = Color(0xFF0C0C14);

  /// The default card.
  static const Color surface1 = Color(0xFF14141F);

  /// A card ON a card, input fills, the nav bar.
  static const Color surface2 = Color(0xFF1C1C2B);

  /// Pressed / selected state of [surface2], snackbars.
  static const Color surface3 = Color(0xFF262637);

  /// Hairline between rows and around cards.
  static const Color outline = Color(0xFF33334A);

  /// A border that must be noticed: focused input, selected chip.
  static const Color outlineStrong = Color(0xFF45455F);

  // --- text ----------------------------------------------------------------

  /// Amounts, titles. 18:1 on [canvas].
  static const Color textPrimary = Color(0xFFF6F6FB);

  /// Body copy, labels. 9.6:1 on [canvas].
  static const Color textSecondary = Color(0xFFB3B3C7);

  /// Captions, timestamps, helper text. 6:1 on [canvas].
  static const Color textTertiary = Color(0xFF8A8AA6);

  /// Disabled text. Still 4.8:1 - "disabled" must not mean "unreadable".
  static const Color textDisabled = Color(0xFF7A7A94);

  /// Text ON a saturated gradient fill.
  static const Color textOnAccent = Color(0xFF0A0A12);

  // --- accents -------------------------------------------------------------

  /// The cyan family accent. Focus rings, links, live indicators.
  static const Color accentCyan = Color(0xFF25F4EE);

  /// Pressed / deeper cyan.
  static const Color accentCyanDeep = Color(0xFF0FBFBA);

  /// The hot accent. The centre action, primary calls to action.
  static const Color accentPink = Color(0xFFFF2E63);

  /// Bigo-register magenta.
  static const Color accentMagenta = Color(0xFFFF3D9A);

  /// The signature violet.
  static const Color accentViolet = Color(0xFFA855FF);

  /// Warm end of the signature gradient.
  static const Color accentAmber = Color(0xFFFF8A3D);

  // --- pure overlays -------------------------------------------------------
  // Fully transparent WHITE, not transparent black: fading to Colors.transparent
  // drags a gradient through grey and looks muddy on this canvas.

  /// Alpha-0 white. The correct "fade to nothing" stop in any light gradient.
  static const Color clearWhite = Color(0x00FFFFFF);

  /// Alpha-0 canvas. The correct "fade to nothing" stop in a scrim.
  static const Color clearCanvas = Color(0x0007070C);

  /// 4% white: the top edge highlight on a raised surface.
  static const Color sheenFaint = Color(0x0AFFFFFF);

  /// 8% white: card wash, disabled fill.
  static const Color sheenLow = Color(0x14FFFFFF);

  /// 15% white: the moving sheen band.
  static const Color sheenMid = Color(0x26FFFFFF);

  /// 20% white: dividers on a gradient, the sheen band on a bright fill.
  static const Color sheenHigh = Color(0x33FFFFFF);

  /// Modal barrier / image scrim.
  static const Color scrim = Color(0xB3040409);

  // --- money ---------------------------------------------------------------

  /// Credits, money in. Same hue as [AppTone.credited].
  static const Color moneyPositive = Color(0xFF29E08A);

  /// Debits, reversals, money out. Never hidden behind an `abs()`.
  static const Color moneyNegative = Color(0xFFFF4D6A);

  // --- gradients -----------------------------------------------------------

  /// THE brand gradient: violet -> hot pink -> amber. Centre action, balance
  /// hero edge, primary button, gradient text.
  static const LinearGradient gradientSignature = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFFA855FF), Color(0xFFFF2E63), Color(0xFFFF8A3D)],
    stops: <double>[0.0, 0.55, 1.0],
  );

  /// Cyan -> violet. Secondary emphasis, "live" and connectivity affordances.
  static const LinearGradient gradientNeon = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF25F4EE), Color(0xFF6B6BFF), Color(0xFFA855FF)],
    stops: <double>[0.0, 0.5, 1.0],
  );

  /// Magenta -> violet, the Bigo register. Avatar rings, celebratory states.
  static const LinearGradient gradientHot = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFFFF3D9A), Color(0xFF7B2BFF)],
  );

  /// Purple -> red -> amber, the Instagram register. Story rings, profile.
  static const LinearGradient gradientSunset = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      Color(0xFF833AB4),
      Color(0xFFFD1D1D),
      Color(0xFFFCAF45),
    ],
    stops: <double>[0.0, 0.6, 1.0],
  );

  /// Cyan -> red with no blend in the middle: the offset-channel glitch feel.
  static const LinearGradient gradientGlitch = LinearGradient(
    colors: <Color>[Color(0xFF25F4EE), Color(0xFFFE2C55)],
    stops: <double>[0.35, 0.65],
  );

  /// Green -> cyan. Credited amounts, success sheets.
  static const LinearGradient gradientCredited = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF29E08A), Color(0xFF25F4EE)],
  );

  /// The quiet card fill. A gradient rather than a flat colour so a large card
  /// does not read as a grey slab.
  static const LinearGradient gradientSurface = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF171722), Color(0xFF0F0F18)],
  );

  /// The tint laid over a dark hero surface so it carries the brand without
  /// costing the amount any contrast. Violet at the reading start, hot pink at
  /// the reading end, nothing in the middle where the amount sits.
  static const LinearGradient gradientHeroWash = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0x38A855FF), Color(0x00FF2E63), Color(0x2EFF2E63)],
    stops: <double>[0.0, 0.55, 1.0],
  );

  /// The moving highlight band used by [gradientSheen] consumers.
  static const LinearGradient gradientSheen = LinearGradient(
    colors: <Color>[clearWhite, sheenHigh, clearWhite],
  );

  /// Bottom fade under a floating nav bar, so content dissolves instead of
  /// being chopped off.
  static const LinearGradient gradientScrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[clearCanvas, Color(0xE607070C)],
  );

  // --- tones ---------------------------------------------------------------

  /// The four colours for [tone]. Exhaustive: adding an [AppTone] value is a
  /// compile error here until it is given colours.
  static ToneColors tone(AppTone tone) => switch (tone) {
        AppTone.pending => const ToneColors(
            foreground: Color(0xFFFFB020),
            background: Color(0x1FFFB020),
            border: Color(0x52FFB020),
            glow: Color(0x66FFB020),
          ),
        AppTone.approved => const ToneColors(
            foreground: Color(0xFF35D6FF),
            background: Color(0x1F35D6FF),
            border: Color(0x5235D6FF),
            glow: Color(0x6635D6FF),
          ),
        AppTone.credited => const ToneColors(
            foreground: Color(0xFF29E08A),
            background: Color(0x1F29E08A),
            border: Color(0x5229E08A),
            glow: Color(0x6629E08A),
          ),
        AppTone.rejected => const ToneColors(
            foreground: Color(0xFFFF4D6A),
            background: Color(0x1FFF4D6A),
            border: Color(0x52FF4D6A),
            glow: Color(0x66FF4D6A),
          ),
        AppTone.attention => const ToneColors(
            foreground: Color(0xFFFF7A3D),
            background: Color(0x1FFF7A3D),
            border: Color(0x52FF7A3D),
            glow: Color(0x66FF7A3D),
          ),
        AppTone.info => const ToneColors(
            foreground: Color(0xFFB388FF),
            background: Color(0x1FB388FF),
            border: Color(0x52B388FF),
            glow: Color(0x66B388FF),
          ),
        AppTone.neutral => const ToneColors(
            foreground: Color(0xFFA8A8C0),
            background: Color(0x14A8A8C0),
            border: Color(0x33A8A8C0),
            glow: Color(0x33A8A8C0),
          ),
      };

  /// Every tone, in a stable order. Used by the contrast test and by any
  /// screen that wants to render a legend.
  static const List<AppTone> allTones = <AppTone>[
    AppTone.pending,
    AppTone.approved,
    AppTone.credited,
    AppTone.rejected,
    AppTone.attention,
    AppTone.info,
    AppTone.neutral,
  ];

  // --- helpers -------------------------------------------------------------

  /// WCAG 2.1 contrast ratio between two OPAQUE colours, 1.0 .. 21.0.
  ///
  /// Alpha is ignored (`Color.computeLuminance` ignores it), so only pass
  /// foregrounds that are actually opaque - compose translucent fills with
  /// [Color.alphaBlend] first.
  static double contrastRatio(Color a, Color b) {
    final double la = a.computeLuminance();
    final double lb = b.computeLuminance();
    final double lighter = la > lb ? la : lb;
    final double darker = la > lb ? lb : la;
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// True when [color] is readable as body text on the darkest surface.
  static bool isReadableOnCanvas(Color color) =>
      contrastRatio(color, canvas) >= 4.5;

  /// Flips a gradient's axis under RTL so a diagonal sweep still runs from the
  /// reading start to the reading end.
  ///
  /// The gradients above use plain [Alignment] (not [AlignmentDirectional]) on
  /// purpose: `Gradient.createShader` throws when a directional alignment meets
  /// a null `textDirection`, which is exactly what happens inside a bare
  /// `ShaderMask`. Mirror explicitly instead:
  ///
  /// ```dart
  /// AppPalette.mirrored(AppPalette.gradientSignature, Directionality.of(context))
  /// ```
  static LinearGradient mirrored(
    LinearGradient gradient,
    TextDirection direction,
  ) {
    if (direction == TextDirection.ltr) {
      return gradient;
    }
    return LinearGradient(
      begin: gradient.end,
      end: gradient.begin,
      colors: gradient.colors,
      stops: gradient.stops,
      tileMode: gradient.tileMode,
      transform: gradient.transform,
    );
  }
}
