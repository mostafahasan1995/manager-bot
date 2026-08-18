import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';

/// Date/time and duration rendering for the deposit screens, in the active
/// language.
///
/// Timestamps arrive as ISO-8601 UTC and are converted to LOCAL by the core
/// parsers, so everything here formats a local [DateTime] - pair any screen
/// that shows one with [AppStrings.timesAreLocalNote].
///
/// Only [AppDateFormats] ever sees the locale, and it maps Arabic-Indic digits
/// back to ASCII, so a timestamp can still be read against the bot's message
/// character for character. Money never passes through here.
abstract final class DepositFormat {
  /// `2026-08-16 10:04`, or the placeholder dash when absent.
  static String timestamp(DateTime? value, AppStrings s, String localeTag) =>
      value == null
          ? s.emptyValueDash
          : AppDateFormats.dayTime(value, localeTag);

  /// `2026-08-16`, or the placeholder dash when absent.
  static String dateOnly(DateTime? value, AppStrings s, String localeTag) =>
      value == null ? s.emptyValueDash : AppDateFormats.day(value, localeTag);

  /// `10:04:11`.
  static String timeOnly(DateTime value, String localeTag) =>
      AppDateFormats.timeOfDay(value, localeTag);

  /// Compact age for a queue row: `42s`, `18m`, `3h 20m`, `4d 6h`.
  ///
  /// Age is what a reviewer triages on, so it stays short enough to sit in a
  /// dense row without wrapping.
  static String age(DateTime since, AppStrings s, {DateTime? now}) {
    final Duration elapsed = (now ?? DateTime.now()).difference(since);
    if (elapsed.isNegative) {
      return s.ageNow;
    }
    if (elapsed.inSeconds < 60) {
      return s.ageSeconds(count: elapsed.inSeconds);
    }
    if (elapsed.inMinutes < 60) {
      return s.ageMinutes(count: elapsed.inMinutes);
    }
    if (elapsed.inHours < 24) {
      final int minutes = elapsed.inMinutes % 60;
      return minutes == 0
          ? s.ageHours(count: elapsed.inHours)
          : s.ageHoursMinutes(hours: elapsed.inHours, minutes: minutes);
    }
    final int hours = elapsed.inHours % 24;
    return hours == 0
        ? s.ageDays(count: elapsed.inDays)
        : s.ageDaysHours(days: elapsed.inDays, hours: hours);
  }

  /// Long form for a detail row: `2026-08-16 10:04 (3h 20m ago)`.
  static String timestampWithAge(
    DateTime? value,
    AppStrings s,
    String localeTag, {
    DateTime? now,
  }) {
    if (value == null) {
      return s.emptyValueDash;
    }
    return s.timestampWithAge(
      timestamp: AppDateFormats.dayTime(value, localeTag),
      age: age(value, s, now: now),
    );
  }

  /// Remaining time until [deadline], or null when it has passed.
  static String? timeLeft(DateTime? deadline, AppStrings s, {DateTime? now}) {
    if (deadline == null) {
      return null;
    }
    final Duration left = deadline.difference(now ?? DateTime.now());
    if (left.isNegative || left.inSeconds == 0) {
      return null;
    }
    if (left.inMinutes < 60) {
      return s.ageMinutes(count: left.inMinutes < 1 ? 1 : left.inMinutes);
    }
    if (left.inHours < 24) {
      return s.ageHours(count: left.inHours);
    }
    return s.ageDays(count: left.inDays);
  }

  /// Shortens a uuid for a dense row without pretending it is complete. The id
  /// itself is never translated.
  static String shortId(String? value, AppStrings s) {
    if (value == null || value.isEmpty) {
      return s.emptyValueDash;
    }
    return value.length <= 8 ? value : '${value.substring(0, 8)}...';
  }
}
