import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';

/// Timestamp and duration rendering for the reconciliation surface.
///
/// Formatting happens HERE and in widgets, never in a model: a model holds an
/// exact [DateTime] the same way it holds exact minor units.
///
/// Only [AppDateFormats] ever sees the locale, and it strips Arabic-Indic
/// digits back to ASCII. Money never comes through this file.
///
/// Every timestamp produced here is the DEVICE's local time while the bot
/// prints UTC, which is why `AppStrings.timesAreLocalNote` belongs on any
/// screen that renders one.
abstract final class ReconciliationFormats {
  /// `16 Aug 2026 10:04` in local time.
  static String timestamp(DateTime value, String localeTag) =>
      AppDateFormats.mediumDayTime(value, localeTag);

  static String time(DateTime value, String localeTag) =>
      AppDateFormats.timeOfDay(value, localeTag);

  static String day(DateTime value, String localeTag) =>
      AppDateFormats.day(value, localeTag);

  /// `3d 4h`, `12m`, `now`. Coarse on purpose - ageing is what matters, not
  /// seconds.
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

  /// `3d 4h ago` - the word order flips in Arabic.
  static String since(DateTime value, AppStrings s, {DateTime? now}) =>
      s.ageAgo(age: age((now ?? DateTime.now()).difference(value), s));

  /// `16 Aug 2026 10:04 (3d ago)`.
  static String timestampWithAge(
    DateTime value,
    AppStrings s,
    String localeTag, {
    DateTime? now,
  }) =>
      s.timestampWithAge(
        timestamp: timestamp(value, localeTag),
        age: age((now ?? DateTime.now()).difference(value), s),
      );
}
