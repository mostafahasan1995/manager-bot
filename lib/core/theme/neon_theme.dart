import 'package:flutter/material.dart';
import 'package:manager_bot/core/ui/dimens.dart';
import 'package:manager_bot/core/ui/palette.dart';

/// The player app's Material 3 theme: near-black canvas, neon accents, 12/20/28
/// shapes, tabular money figures and Arabic-safe font fallbacks.
///
/// This is a SECOND theme. `core/theme/app_theme.dart` still belongs to the
/// staff admin console and is untouched - nothing here edits it and nothing
/// there needs to change.
///
/// The point of this file is that screens style almost nothing locally:
/// buttons, inputs, sheets, snackbars, dividers and chips already arrive
/// correct. Where a screen needs the brand register (gradients, glow, the
/// balance hero) it uses `core/ui`, not a bespoke `BoxDecoration`.
///
/// ```dart
/// MaterialApp.router(
///   theme: NeonTheme.dark(),
///   darkTheme: NeonTheme.dark(),
///   themeMode: ThemeMode.dark,
///   locale: locale,
///   supportedLocales: AppLocales.supported,
///   localizationsDelegates: AppLocalizationsDelegates.all,
///   routerConfig: router,
/// )
/// ```
abstract final class NeonTheme {
  /// The seed the Material 3 algorithm expands into the tonal palettes that
  /// are not overridden below.
  static const Color seed = AppPalette.accentViolet;

  /// The one theme this app ships. There is no light variant: the design is a
  /// near-black canvas by definition, and a half-hearted light mode would just
  /// be a second thing to keep contrast-correct.
  static ThemeData dark() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppPalette.accentViolet,
      onPrimary: AppPalette.textOnAccent,
      primaryContainer: AppPalette.surface2,
      onPrimaryContainer: AppPalette.textPrimary,
      secondary: AppPalette.accentCyan,
      onSecondary: AppPalette.textOnAccent,
      tertiary: AppPalette.accentPink,
      onTertiary: Colors.white,
      surface: AppPalette.canvas,
      onSurface: AppPalette.textPrimary,
      surfaceContainerHighest: AppPalette.surface2,
      onSurfaceVariant: AppPalette.textSecondary,
      outline: AppPalette.outline,
      outlineVariant: AppPalette.outline,
      error: AppPalette.moneyNegative,
      onError: AppPalette.textOnAccent,
      inverseSurface: AppPalette.surface3,
      onInverseSurface: AppPalette.textPrimary,
    );

    final ThemeData base = ThemeData(colorScheme: scheme, useMaterial3: true);
    // Applied to the WHOLE text theme, not to individual styles, so a widget
    // that builds its own TextStyle from any of them keeps the Arabic faces.
    final TextTheme scripted = base.textTheme.apply(
      fontFamilyFallback: NeonFonts.arabicFallback,
      bodyColor: AppPalette.textPrimary,
      displayColor: AppPalette.textPrimary,
    );
    final TextTheme textTheme = scripted.copyWith(
      displayLarge: scripted.displayLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
        fontFeatures: NeonFonts.numericFeatures,
      ),
      displaySmall: scripted.displaySmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        fontFeatures: NeonFonts.numericFeatures,
      ),
      headlineSmall: scripted.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      titleLarge: scripted.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: scripted.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        fontFeatures: NeonFonts.numericFeatures,
      ),
      // Arabic needs a touch more leading than Latin for its descenders and
      // diacritics; 1.45 is comfortable in both scripts.
      bodyMedium: scripted.bodyMedium?.copyWith(height: 1.45),
      bodySmall: scripted.bodySmall?.copyWith(
        height: 1.4,
        color: AppPalette.textTertiary,
      ),
      labelLarge: scripted.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      labelMedium: scripted.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppPalette.textSecondary,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppPalette.canvas,
      canvasColor: AppPalette.canvas,
      splashColor: AppPalette.sheenLow,
      highlightColor: AppPalette.sheenFaint,
      textTheme: textTheme,
      iconTheme: const IconThemeData(color: AppPalette.textSecondary),
      appBarTheme: AppBarTheme(
        backgroundColor: AppPalette.canvas,
        foregroundColor: AppPalette.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      // NOTE: `cardTheme` is deliberately NOT set. Its type changed between
      // Flutter versions (CardTheme -> CardThemeData) and this project must
      // compile on whatever SDK the build box has. Use `AppCard` / `GlowCard`.
      dividerTheme: const DividerThemeData(
        color: AppPalette.outline,
        space: 1,
        thickness: 1,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        iconColor: AppPalette.textTertiary,
        textColor: AppPalette.textPrimary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppPalette.surface2,
        hintStyle: const TextStyle(color: AppPalette.textDisabled),
        contentPadding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: const OutlineInputBorder(
          borderRadius: AppRadii.smRadius,
          borderSide: BorderSide(color: AppPalette.outline),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadii.smRadius,
          borderSide: BorderSide(color: AppPalette.outline),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadii.smRadius,
          borderSide: BorderSide(color: AppPalette.accentCyan, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadii.smRadius,
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadii.smRadius,
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
        isDense: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          backgroundColor: AppPalette.accentViolet,
          foregroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadii.pillRadius,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 52),
          foregroundColor: AppPalette.textPrimary,
          side: const BorderSide(color: AppPalette.outlineStrong),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadii.pillRadius,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppPalette.accentCyan,
          textStyle: textTheme.labelLarge,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppPalette.surface3,
        actionTextColor: AppPalette.accentCyan,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppPalette.textPrimary,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.smRadius),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppPalette.surface1,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: AppPalette.outlineStrong,
        showDragHandle: true,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.sheetRadius),
      ),
      // The real bottom bar is a custom five-slot bar with a raised centre
      // action, but a stock NavigationBar (a sub-navigation inside a screen,
      // say) must not look foreign.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppPalette.surface1,
        indicatorColor: AppPalette.accentViolet.withAlpha(0x33),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppPalette.surface2,
        side: const BorderSide(color: AppPalette.outline),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.pillRadius),
        labelStyle: textTheme.labelMedium,
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppPalette.accentCyan,
        selectionColor: Color(0x4425F4EE),
        selectionHandleColor: AppPalette.accentCyan,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppPalette.accentCyan,
        linearTrackColor: AppPalette.surface2,
      ),
      tooltipTheme: const TooltipThemeData(
        decoration: BoxDecoration(
          color: AppPalette.surface3,
          borderRadius: AppRadii.smRadius,
        ),
        textStyle: TextStyle(color: AppPalette.textPrimary, fontSize: 12),
      ),
    );
  }

  /// Style for an amount that is NOT rendered through `AmountText` - a money
  /// value inside a sentence, a table header. Tabular figures, tight tracking.
  static TextStyle moneyStyle(BuildContext context, {double? fontSize}) {
    final TextStyle base =
        Theme.of(context).textTheme.titleMedium ?? const TextStyle();
    return base.copyWith(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      fontFeatures: NeonFonts.numericFeatures,
      fontFamilyFallback: NeonFonts.arabicFallback,
    );
  }

  /// Style for ids, references and correlation ids: small, tabular, dim.
  static TextStyle monoStyle(BuildContext context) {
    final TextStyle base =
        Theme.of(context).textTheme.bodySmall ?? const TextStyle();
    return base.copyWith(
      color: AppPalette.textTertiary,
      letterSpacing: 0.3,
      fontFeatures: NeonFonts.numericFeatures,
    );
  }
}
