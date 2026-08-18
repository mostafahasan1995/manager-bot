import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// `show DateFormat` is load-bearing: package:intl also exports a TextDirection
// that would shadow dart:ui's and break every Directionality call below.
import 'package:intl/intl.dart' show DateFormat;
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/i18n/locale_controller.dart';

/// Reads the string bundle, the locale and the reading direction off a
/// [BuildContext].
///
/// `context.s` resolves through `Localizations`, so every widget that uses it
/// rebuilds when the language changes - no `ref.watch`, no listener, nothing to
/// forget.
///
/// ```dart
/// @override
/// Widget build(BuildContext context) {
///   final AppStrings s = context.s;
///   return Column(
///     children: <Widget>[
///       Text(s.depositQueueTitle),                  // "طابور الإيداعات"
///       Text(s.claimHeldByYou(minutes: 7)),         // "المراجعة بعهدتك لمدة 7 د أخرى."
///     ],
///   );
/// }
/// ```
extension AppStringsX on BuildContext {
  /// The strings for the locale in scope, falling back to Arabic outside a
  /// `Localizations` subtree (a bare widget test, for instance).
  AppStrings get s =>
      AppStrings.of(Localizations.maybeLocaleOf(this) ?? AppLocales.fallback);

  /// The locale in scope. Same fallback as [s].
  Locale get appLocale =>
      Localizations.maybeLocaleOf(this) ?? AppLocales.fallback;

  /// `ar` or `en`. Hand this to [AppDateFormats] - NEVER to `Money.format`,
  /// which must render the same Western digits the bot logs.
  String get localeTag => appLocale.languageCode;

  /// Reading direction of the surrounding tree.
  ///
  /// `GlobalWidgetsLocalizations` already wraps the app in a `Directionality`
  /// for the active locale, so widgets do NOT need to wrap anything
  /// themselves. Read this only to make a layout decision that direction alone
  /// cannot express - an icon that must point "forward", a chart axis, a
  /// hand-rolled swipe gesture.
  TextDirection get textDirection => Directionality.of(this);

  /// True when the console is currently right-to-left (Arabic).
  ///
  /// Prefer `EdgeInsetsDirectional`, `AlignmentDirectional`, `start`/`end` and
  /// `TextAlign.start` over branching on this flag: they already flip.
  bool get isRtl => Directionality.of(this) == TextDirection.rtl;
}

/// The delegate list `MaterialApp` needs for Arabic Material/Cupertino chrome
/// and for the automatic RTL `Directionality`.
///
/// `flutter_localizations` is an SDK package, not code generation: it ships the
/// translations for Flutter's own widgets (date pickers, the text-selection
/// menu, `MaterialLocalizations.okButtonLabel`, ...). Without it an Arabic
/// build shows English system chrome and stays left-to-right.
///
/// Widget tests that pump a screen directly must pass this too:
///
/// ```dart
/// await tester.pumpWidget(
///   MaterialApp(
///     locale: AppLocales.arabic,
///     supportedLocales: AppLocales.supported,
///     localizationsDelegates: AppLocalizationsDelegates.all,
///     home: const DepositQueueScreen(),
///   ),
/// );
/// ```
abstract final class AppLocalizationsDelegates {
  static const List<LocalizationsDelegate<dynamic>> all =
      <LocalizationsDelegate<dynamic>>[
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];
}

/// Locale-aware date and time rendering - the ONLY place `intl` formatting is
/// allowed to see the active locale.
///
/// Two rules are enforced here:
///
/// 1. MONTH AND DAY NAMES ARE LOCALISED. `DateFormat('d MMM yyyy')` under `ar`
///    must read "17 آب 2026", not "17 Aug 2026".
/// 2. DIGITS STAY WESTERN. `intl` renders `ar` numerals as Arabic-Indic
///    (٠١٢٣٤٥٦٧٨٩); every output here is mapped back to ASCII so a timestamp on
///    a deposit card can be read against the bot's message character for
///    character. This matches `Money.format`, which is ASCII by construction.
///
/// Every value the API hands over is converted to LOCAL time by
/// `Json.dateTime()`, while the bot prints UTC. Whenever you show one of these,
/// show `AppStrings.timesAreLocalNote` somewhere on the same screen.
abstract final class AppDateFormats {
  /// `2026-08-17 14:05` - dense rows, timelines, technical panels.
  static String dayTime(DateTime value, String localeTag) =>
      _render('yyyy-MM-dd HH:mm', value, localeTag);

  /// `17 Aug 2026 14:05` / `17 آب 2026 14:05` - card headers.
  static String mediumDayTime(DateTime value, String localeTag) =>
      _render('d MMM yyyy HH:mm', value, localeTag);

  /// `2026-08-17` - date-only filter chips and pickers.
  static String day(DateTime value, String localeTag) =>
      _render('yyyy-MM-dd', value, localeTag);

  /// `14:05:33` - the agent-float reading title.
  static String timeOfDay(DateTime value, String localeTag) =>
      _render('HH:mm:ss', value, localeTag);

  /// Escape hatch for a pattern not listed above. Always pass the result
  /// through [toWesternDigits] - or just use this method, which does.
  static String custom(String pattern, DateTime value, String localeTag) =>
      _render(pattern, value, localeTag);

  /// Rewrites Arabic-Indic (U+0660..U+0669) and Extended Arabic-Indic
  /// (U+06F0..U+06F9) digits as ASCII 0-9, leaving every other character alone.
  ///
  /// Use it on anything `intl` produced that an operator will compare against a
  /// Telegram message.
  static String toWesternDigits(String input) {
    if (input.isEmpty) {
      return input;
    }
    final StringBuffer buffer = StringBuffer();
    for (final int rune in input.runes) {
      if (rune >= 0x0660 && rune <= 0x0669) {
        buffer.writeCharCode(0x30 + (rune - 0x0660));
      } else if (rune >= 0x06F0 && rune <= 0x06F9) {
        buffer.writeCharCode(0x30 + (rune - 0x06F0));
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }

  static String _render(String pattern, DateTime value, String localeTag) =>
      toWesternDigits(DateFormat(pattern, localeTag).format(value));
}
