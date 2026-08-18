import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';

/// Age and timestamp phrasing for the Money tab, in the active language.
///
/// `ReconciliationFormats` is the same idea for the reconciliation workbench,
/// but its phrases ("3d ago", "just now") are English literals. Everything on
/// the Money tab goes through the catalogue instead, so an Arabic operator
/// never reads half a sentence in English.
///
/// Money itself is NEVER formatted here: `Money.format()` owns that, and it
/// stays Western-digit in both languages exactly like the bot.
abstract final class MoneyFormats {
  /// `3d 4h`, `12m`, `now`. Coarse on purpose - ageing is what matters.
  static String age(Duration duration, AppStrings s) {
    if (duration.isNegative) {
      return s.ageInFuture;
    }
    if (duration.inMinutes < 1) {
      return s.ageNow;
    }
    if (duration.inHours < 1) {
      return s.ageMinutes(count: duration.inMinutes);
    }
    if (duration.inDays < 1) {
      final int hours = duration.inHours;
      final int minutes = duration.inMinutes - hours * 60;
      return minutes == 0
          ? s.ageHours(count: hours)
          : s.ageHoursMinutes(hours: hours, minutes: minutes);
    }
    final int days = duration.inDays;
    final int hours = duration.inHours - days * 24;
    return hours == 0
        ? s.ageDays(count: days)
        : s.ageDaysHours(days: days, hours: hours);
  }

  /// `3d 4h ago` / `منذ 3d 4h`.
  static String since(DateTime value, AppStrings s, {DateTime? now}) =>
      s.ageAgo(age: age((now ?? DateTime.now()).difference(value), s));

  /// `17 Aug 2026 14:05 (3d ago)`. LOCAL time - pair it with
  /// [AppStrings.timesAreLocalNote] on any screen that shows one.
  static String timestampWithAge(
    DateTime value,
    AppStrings s,
    String localeTag, {
    DateTime? now,
  }) =>
      s.timestampWithAge(
        timestamp: AppDateFormats.mediumDayTime(value, localeTag),
        age: age((now ?? DateTime.now()).difference(value), s),
      );
}
