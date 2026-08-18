import 'package:flutter_test/flutter_test.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/features/shell/home/data/home_models.dart';

const AppStrings _ar = AppStrings.ar;
const AppStrings _en = AppStrings.en;

/// Arabic-Indic (U+0660..U+0669) and Extended Arabic-Indic (U+06F0..U+06F9).
final RegExp _easternDigits = RegExp(r'[٠-٩۰-۹]');

/// "قبل 12 دقيقة" on a deposit row comes from the existing age vocabulary, not
/// from a new literal. These tests pin the branch boundaries and the rule that
/// digits stay Western in Arabic, exactly as amounts do.
void main() {
  group('HomeAgeFormat.compact', () {
    test('anything under a minute still reads as one minute, never zero', () {
      expect(HomeAgeFormat.compact(_ar, const Duration(seconds: 8)), '1 د');
      expect(HomeAgeFormat.compact(_ar, Duration.zero), '1 د');
      expect(HomeAgeFormat.compact(_en, const Duration(seconds: 8)), '1m');
    });

    test('under an hour is minutes only', () {
      expect(HomeAgeFormat.compact(_ar, const Duration(minutes: 12)), '12 د');
      expect(HomeAgeFormat.compact(_ar, const Duration(minutes: 59)), '59 د');
      expect(HomeAgeFormat.compact(_en, const Duration(minutes: 12)), '12m');
    });

    test('a whole number of hours drops the minutes', () {
      expect(HomeAgeFormat.compact(_ar, const Duration(hours: 8)), '8 س');
      expect(HomeAgeFormat.compact(_en, const Duration(hours: 8)), '8h');
    });

    test('hours plus minutes keeps both', () {
      expect(
        HomeAgeFormat.compact(_ar, const Duration(hours: 3, minutes: 20)),
        '3 س 20 د',
      );
      expect(
        HomeAgeFormat.compact(_en, const Duration(hours: 3, minutes: 20)),
        '3h 20m',
      );
    });

    test('a day or more switches to days and hours', () {
      expect(
        HomeAgeFormat.compact(_ar, const Duration(days: 1, hours: 6)),
        '1 ي 6 س',
      );
      expect(
        HomeAgeFormat.compact(_en, const Duration(days: 2)),
        '2d 0h',
      );
    });

    test('23:59 is still hours, 24:00 is already days', () {
      expect(
        HomeAgeFormat.compact(_ar, const Duration(hours: 23, minutes: 59)),
        '23 س 59 د',
      );
      expect(
        HomeAgeFormat.compact(_ar, const Duration(hours: 24)),
        '1 ي 0 س',
      );
    });
  });

  group('HomeAgeFormat.ago', () {
    test('wraps the compact age in the catalogue phrase', () {
      expect(HomeAgeFormat.ago(_ar, const Duration(minutes: 4)), 'منذ 4 د');
      expect(HomeAgeFormat.ago(_en, const Duration(minutes: 4)), '4m ago');
    });
  });

  group('digits', () {
    test('stay Western in Arabic, exactly like every amount in this app', () {
      const List<Duration> samples = <Duration>[
        Duration(seconds: 1),
        Duration(minutes: 12),
        Duration(hours: 3, minutes: 20),
        Duration(hours: 8),
        Duration(days: 1, hours: 6),
      ];

      for (final Duration sample in samples) {
        expect(
          _easternDigits.hasMatch(HomeAgeFormat.ago(_ar, sample)),
          isFalse,
          reason: '$sample rendered with Arabic-Indic digits',
        );
      }
    });
  });
}
