
import 'package:flutter/material.dart';

/// Semantic meaning of a piece of state, independent of the enum it came from.
///
/// Feature code maps its own enum onto this (DepositStatus, BreakStatus,
/// OutboxStatus, ...) and the shared widgets colour it consistently.
enum StatusTone {
  /// Terminal success: APPROVED, CREDITED, RESOLVED.
  approve,

  /// Terminal refusal by a human: REJECTED, WRITTEN_OFF.
  reject,

  /// Waiting on somebody: SUBMITTED, UNDER_REVIEW, PENDING_SECOND_APPROVAL.
  pending,

  /// The system broke: CREDIT_FAILED, NEEDS_RECONCILIATION, DEAD.
  failed,

  /// In motion, no action needed yet: CREDITING, IN_FLIGHT.
  info,

  /// Nothing to say: DRAFT, EXPIRED, VIEWER-only rows.
  neutral,
}

/// Foreground / background / border triple for one [StatusTone].
@immutable
class SemanticTone {
  const SemanticTone({
    required this.foreground,
    required this.background,
    required this.border,
  });

  final Color foreground;
  final Color background;
  final Color border;

  static SemanticTone lerp(SemanticTone a, SemanticTone b, double t) =>
      SemanticTone(
        foreground: Color.lerp(a.foreground, b.foreground, t) ?? b.foreground,
        background: Color.lerp(a.background, b.background, t) ?? b.background,
        border: Color.lerp(a.border, b.border, t) ?? b.border,
      );
}

/// The semantic palette a money-review tool needs on top of Material 3.
///
/// Approve/reject/pending/failed must be unmistakable at a glance and must not
/// collide with the primary colour of a button, so they are defined here rather
/// than borrowed from the [ColorScheme].
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.approve,
    required this.reject,
    required this.pending,
    required this.failed,
    required this.info,
    required this.neutral,
    required this.moneyPositive,
    required this.moneyNegative,
    required this.riskFlag,
  });

  static const AppSemanticColors dark = AppSemanticColors(
    approve: SemanticTone(
      foreground: Color(0xFF6EE7A8),
      background: Color(0x2214B866),
      border: Color(0x5514B866),
    ),
    reject: SemanticTone(
      foreground: Color(0xFFFF8A80),
      background: Color(0x22F4433C),
      border: Color(0x55F4433C),
    ),
    pending: SemanticTone(
      foreground: Color(0xFFFFC46B),
      background: Color(0x22FFB300),
      border: Color(0x55FFB300),
    ),
    failed: SemanticTone(
      foreground: Color(0xFFFF9E6B),
      background: Color(0x22FF6B2C),
      border: Color(0x55FF6B2C),
    ),
    info: SemanticTone(
      foreground: Color(0xFF8AB4FF),
      background: Color(0x224C7DFF),
      border: Color(0x554C7DFF),
    ),
    neutral: SemanticTone(
      foreground: Color(0xFFB6BDCC),
      background: Color(0x1AB6BDCC),
      border: Color(0x33B6BDCC),
    ),
    moneyPositive: Color(0xFF6EE7A8),
    moneyNegative: Color(0xFFFF8A80),
    riskFlag: Color(0xFFFFC46B),
  );

  static const AppSemanticColors light = AppSemanticColors(
    approve: SemanticTone(
      foreground: Color(0xFF0F7A45),
      background: Color(0x1A14B866),
      border: Color(0x4414B866),
    ),
    reject: SemanticTone(
      foreground: Color(0xFFB3261E),
      background: Color(0x14F4433C),
      border: Color(0x44F4433C),
    ),
    pending: SemanticTone(
      foreground: Color(0xFF8A5A00),
      background: Color(0x14FFB300),
      border: Color(0x44FFB300),
    ),
    failed: SemanticTone(
      foreground: Color(0xFFA33A0F),
      background: Color(0x14FF6B2C),
      border: Color(0x44FF6B2C),
    ),
    info: SemanticTone(
      foreground: Color(0xFF1F4FCC),
      background: Color(0x144C7DFF),
      border: Color(0x444C7DFF),
    ),
    neutral: SemanticTone(
      foreground: Color(0xFF4A5163),
      background: Color(0x14444C5E),
      border: Color(0x33444C5E),
    ),
    moneyPositive: Color(0xFF0F7A45),
    moneyNegative: Color(0xFFB3261E),
    riskFlag: Color(0xFF8A5A00),
  );

  final SemanticTone approve;
  final SemanticTone reject;
  final SemanticTone pending;
  final SemanticTone failed;
  final SemanticTone info;
  final SemanticTone neutral;

  /// Credits / money in.
  final Color moneyPositive;

  /// Debits / reversals / money out. Never hidden behind an `abs()`.
  final Color moneyNegative;

  /// Risk badges on a deposit (DUPLICATE_PROOF_EXACT, LARGE_AMOUNT, ...).
  final Color riskFlag;

  /// The palette for the current theme. Falls back to the dark set so a widget
  /// used outside a themed subtree still renders sensibly.
  static AppSemanticColors of(BuildContext context) =>
      Theme.of(context).extension<AppSemanticColors>() ?? dark;

  SemanticTone tone(StatusTone tone) => switch (tone) {
        StatusTone.approve => approve,
        StatusTone.reject => reject,
        StatusTone.pending => pending,
        StatusTone.failed => failed,
        StatusTone.info => info,
        StatusTone.neutral => neutral,
      };

  @override
  AppSemanticColors copyWith({
    SemanticTone? approve,
    SemanticTone? reject,
    SemanticTone? pending,
    SemanticTone? failed,
    SemanticTone? info,
    SemanticTone? neutral,
    Color? moneyPositive,
    Color? moneyNegative,
    Color? riskFlag,
  }) =>
      AppSemanticColors(
        approve: approve ?? this.approve,
        reject: reject ?? this.reject,
        pending: pending ?? this.pending,
        failed: failed ?? this.failed,
        info: info ?? this.info,
        neutral: neutral ?? this.neutral,
        moneyPositive: moneyPositive ?? this.moneyPositive,
        moneyNegative: moneyNegative ?? this.moneyNegative,
        riskFlag: riskFlag ?? this.riskFlag,
      );

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) {
      return this;
    }
    return AppSemanticColors(
      approve: SemanticTone.lerp(approve, other.approve, t),
      reject: SemanticTone.lerp(reject, other.reject, t),
      pending: SemanticTone.lerp(pending, other.pending, t),
      failed: SemanticTone.lerp(failed, other.failed, t),
      info: SemanticTone.lerp(info, other.info, t),
      neutral: SemanticTone.lerp(neutral, other.neutral, t),
      moneyPositive: Color.lerp(moneyPositive, other.moneyPositive, t) ??
          other.moneyPositive,
      moneyNegative: Color.lerp(moneyNegative, other.moneyNegative, t) ??
          other.moneyNegative,
      riskFlag: Color.lerp(riskFlag, other.riskFlag, t) ?? other.riskFlag,
    );
  }
}

/// Dark-first Material 3 theme.
abstract final class AppTheme {
  /// Seed for the Material 3 scheme: a calm blue that never competes with the
  /// approve/reject semantics.
  static const Color seed = Color(0xFF4C7DFF);

  static const Color _darkSurface = Color(0xFF101318);
  static const Color _darkSurfaceContainer = Color(0xFF171B22);
  static const Color _darkOutline = Color(0xFF2A303A);

  /// Amounts, ids, cursors and timestamps must line up column to column, so
  /// every numeric style uses tabular figures and slashed zero.
  static const List<FontFeature> numericFeatures = <FontFeature>[
    FontFeature.tabularFigures(),
    FontFeature.slashedZero(),
  ];

  /// Arabic-safe font fallbacks.
  ///
  /// The default family (Roboto on Android, SF on iOS) carries no Arabic
  /// glyphs, and the numeric styles above pin tabular figures, which on some
  /// Android builds keeps the resolver inside a Latin-only face and drops
  /// Arabic to tofu. Naming the platform Arabic faces here fixes that without
  /// touching a single colour or size: the list is simply ignored where those
  /// families do not exist, and Latin text still renders in the default family
  /// because it is tried first.
  static const List<String> arabicFontFallback = <String>[
    'Noto Naskh Arabic', // Android
    'Noto Sans Arabic', // Android (newer)
    'Geeza Pro', // iOS
    '.SF Arabic', // iOS 16+
  ];

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    ).copyWith(
      surface: _darkSurface,
      surfaceContainerHighest: _darkSurfaceContainer,
      outlineVariant: _darkOutline,
      error: const Color(0xFFFF8A80),
    );
    return _build(scheme, AppSemanticColors.dark);
  }

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
    );
    return _build(scheme, AppSemanticColors.light);
  }

  /// Style for any amount. Monospaced digits, slightly tighter tracking.
  ///
  /// ```dart
  /// Text(money.format(), style: AppTheme.moneyStyle(context))
  /// ```
  static TextStyle moneyStyle(BuildContext context, {double? fontSize}) {
    final base = Theme.of(context).textTheme.titleMedium ?? const TextStyle();
    return base.copyWith(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      fontFeatures: numericFeatures,
      letterSpacing: 0,
    );
  }

  /// Style for ids, cursors and correlation ids: small, tabular, dimmed.
  static TextStyle monoStyle(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.textTheme.bodySmall ?? const TextStyle();
    return base.copyWith(
      fontFeatures: numericFeatures,
      color: theme.colorScheme.onSurfaceVariant,
      letterSpacing: 0.2,
    );
  }

  static ThemeData _build(ColorScheme scheme, AppSemanticColors semantics) {
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);
    // Applied to the WHOLE text theme, not to individual styles, so a widget
    // that builds its own TextStyle from any of them inherits the Arabic faces.
    final TextTheme scripted =
        base.textTheme.apply(fontFamilyFallback: arabicFontFallback);
    final textTheme = scripted.copyWith(
      titleMedium: scripted.titleMedium?.copyWith(fontFeatures: numericFeatures),
      titleLarge: scripted.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      // Arabic needs a touch more leading than Latin for its descenders and
      // diacritics; 1.4 is comfortable in both scripts.
      bodyMedium: scripted.bodyMedium?.copyWith(height: 1.4),
      labelLarge: scripted.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    );

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[semantics],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      // NOTE: `cardTheme` is intentionally not set. Its type changed between
      // Flutter versions (CardTheme -> CardThemeData) and this project must
      // compile on whatever SDK the CI box has. Use `AppCard` / a themed
      // Container instead.
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        space: 1,
        thickness: 1,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        isDense: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: BorderSide(color: scheme.outlineVariant),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: textTheme.labelLarge),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: scheme.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        indicatorColor: Color.alphaBlend(
          scheme.primary.withAlpha(46),
          scheme.surfaceContainerHighest,
        ),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      chipTheme: ChipThemeData(
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: textTheme.labelSmall,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
    );
  }
}
