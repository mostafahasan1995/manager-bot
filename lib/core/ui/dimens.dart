import 'package:flutter/material.dart';

/// The spacing scale. Every gap in the app is one of these numbers.
///
/// ```dart
/// const SizedBox(height: AppSpacing.md)          // const-constructible
/// EdgeInsetsDirectional.all(AppSpacing.lg)
/// ```
abstract final class AppSpacing {
  /// 4 - inside a chip, between an icon and its label.
  static const double xs = 4;

  /// 8 - between two chips, list item internal rows.
  static const double sm = 8;

  /// 12 - between stacked lines of text.
  static const double md = 12;

  /// 16 - the default card padding and screen gutter.
  static const double lg = 16;

  /// 20 - generous card padding (the balance hero).
  static const double xl = 20;

  /// 28 - between sections.
  static const double xxl = 28;

  /// Horizontal page gutter.
  static const double gutter = 16;

  /// Bottom padding a scroll body needs to clear the floating nav bar.
  static const double navClearance = 108;

  /// Default padding inside [AppCard] / [GlowCard].
  static const EdgeInsetsGeometry cardPadding =
      EdgeInsetsDirectional.all(AppSpacing.lg);

  /// Default page padding: gutter on both sides, nav clearance at the bottom.
  static const EdgeInsetsGeometry pagePadding = EdgeInsetsDirectional.fromSTEB(
    AppSpacing.gutter,
    AppSpacing.lg,
    AppSpacing.gutter,
    AppSpacing.navClearance,
  );
}

/// Font fallbacks that keep Arabic from turning into tofu.
///
/// The default family (Roboto on Android, SF on iOS) carries no Arabic glyphs,
/// and pinning tabular figures can keep the resolver inside a Latin-only face.
/// Naming the platform Arabic faces fixes that; the list is simply ignored
/// where those families do not exist, and Latin text still renders in the
/// default family because it is tried first.
abstract final class NeonFonts {
  /// Platform Arabic faces, in preference order.
  static const List<String> arabicFallback = <String>[
    'Noto Naskh Arabic', // Android
    'Noto Sans Arabic', // Android (newer)
    'Geeza Pro', // iOS
    '.SF Arabic', // iOS 16+
  ];

  /// Tabular, slashed-zero figures. Every amount, id and timestamp uses these
  /// so digits line up column to column.
  static const List<FontFeature> numericFeatures = <FontFeature>[
    FontFeature.tabularFigures(),
    FontFeature.slashedZero(),
  ];
}

/// The shape scale: 12 / 20 / 28, plus a pill.
///
/// Small things (chips, inputs, skeleton bars) are 12, cards are 20, hero
/// surfaces and sheets are 28. Nothing in this app is square-cornered.
abstract final class AppRadii {
  /// 12 - chips, inputs, skeletons, small tiles.
  static const double sm = 12;

  /// 20 - cards, list rows, images.
  static const double md = 20;

  /// 28 - the balance hero, sheets, the raised centre action.
  static const double lg = 28;

  /// A fully rounded end cap. Safe for any height.
  static const double pill = 999;

  /// [sm] on all corners.
  static const BorderRadius smRadius = BorderRadius.all(Radius.circular(sm));

  /// [md] on all corners.
  static const BorderRadius mdRadius = BorderRadius.all(Radius.circular(md));

  /// [lg] on all corners.
  static const BorderRadius lgRadius = BorderRadius.all(Radius.circular(lg));

  /// [pill] on all corners.
  static const BorderRadius pillRadius =
      BorderRadius.all(Radius.circular(pill));

  /// Top-rounded, for a bottom sheet.
  static const BorderRadius sheetRadius =
      BorderRadius.vertical(top: Radius.circular(lg));
}

/// Elevation as GLOW, not as a grey drop shadow.
///
/// On a near-black canvas a neutral shadow is invisible; a coloured bloom of
/// the surface's own accent is what reads as "raised". Every shadow here is
/// static - none of them animate, so they cost one blur per paint and nothing
/// per frame.
abstract final class AppShadows {
  /// The quiet lift under a card.
  static const List<BoxShadow> card = <BoxShadow>[
    BoxShadow(color: Color(0x66000000), blurRadius: 18, offset: Offset(0, 8)),
  ];

  /// The lift under a floating bar or sheet.
  static const List<BoxShadow> raised = <BoxShadow>[
    BoxShadow(color: Color(0x99000000), blurRadius: 28, offset: Offset(0, -6)),
  ];

  /// A coloured bloom around an accent surface.
  ///
  /// [alpha] is 0..255 and deliberately low by default: glow is an edge effect,
  /// not a fog. `spread` is negative so the bloom hugs the shape.
  static List<BoxShadow> glow(
    Color color, {
    double blur = 26,
    double spread = -6,
    Offset offset = const Offset(0, 10),
    int alpha = 0x66,
  }) =>
      <BoxShadow>[
        BoxShadow(
          color: color.withAlpha(alpha),
          blurRadius: blur,
          spreadRadius: spread,
          offset: offset,
        ),
      ];
}
