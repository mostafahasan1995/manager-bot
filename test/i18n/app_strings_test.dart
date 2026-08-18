import 'dart:ui' show Locale, TextDirection;

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/i18n/locale_controller.dart';

/// Matches Arabic-Indic and Extended Arabic-Indic digits.
final RegExp _easternDigits = RegExp(r'[٠-٩۰-۹]');

void main() {
  group('AppStrings.of', () {
    test('Arabic is the default, not English', () {
      expect(AppStrings.of(const Locale('ar')), isA<ArStrings>());
      expect(AppStrings.of(const Locale('en')), isA<EnStrings>());
      // An unknown language must NOT silently become English.
      expect(AppStrings.of(const Locale('fr')), isA<ArStrings>());
      expect(AppStrings.forLanguageTag(''), isA<ArStrings>());
    });

    test('regional tags resolve to their base language', () {
      expect(AppStrings.forLanguageTag('en-GB'), isA<EnStrings>());
      expect(AppStrings.forLanguageTag('EN_US'), isA<EnStrings>());
      expect(AppStrings.forLanguageTag('ar-SY'), isA<ArStrings>());
    });

    test('each bundle knows its tag and its direction', () {
      expect(AppStrings.ar.localeTag, 'ar');
      expect(AppStrings.ar.textDirection, TextDirection.rtl);
      expect(AppStrings.en.localeTag, 'en');
      expect(AppStrings.en.textDirection, TextDirection.ltr);
    });
  });

  group('AppLocales', () {
    test('parse never throws and never guesses English', () {
      expect(AppLocales.parse(null), AppLocales.arabic);
      expect(AppLocales.parse('   '), AppLocales.arabic);
      expect(AppLocales.parse('nonsense'), AppLocales.arabic);
      expect(AppLocales.parse('en'), AppLocales.english);
    });

    test('supported is exactly the two shipped locales', () {
      expect(AppLocales.supported, <Locale>[AppLocales.arabic, AppLocales.english]);
      expect(AppLocales.fallback, AppLocales.arabic);
      expect(AppLocales.isRtl(AppLocales.arabic), isTrue);
      expect(AppLocales.isRtl(AppLocales.english), isFalse);
    });
  });

  group('Arabic plurals', () {
    const AppStrings s = AppStrings.ar;

    test('queueLoadedCount uses zero/one/two/few/many', () {
      expect(s.queueLoadedCount(count: 0), 'لا إيداعات محمّلة.');
      expect(s.queueLoadedCount(count: 1), 'تم تحميل إيداع واحد.');
      expect(s.queueLoadedCount(count: 2), 'تم تحميل إيداعين.');
      expect(s.queueLoadedCount(count: 3), 'تم تحميل 3 إيداعات.');
      expect(s.queueLoadedCount(count: 10), 'تم تحميل 10 إيداعات.');
      expect(s.queueLoadedCount(count: 11), 'تم تحميل 11 إيداعاً.');
      expect(s.queueLoadedCount(count: 103), 'تم تحميل 103 إيداعات.');
    });

    test('English keeps its own singular/plural', () {
      expect(AppStrings.en.queueLoadedCount(count: 1), '1 deposit loaded.');
      expect(AppStrings.en.queueLoadedCount(count: 4), '4 deposits loaded.');
    });
  });

  test('every Arabic string with a count renders WESTERN digits', () {
    const AppStrings s = AppStrings.ar;
    final List<String> rendered = <String>[
      s.queueLoadedCount(count: 1234),
      s.entriesCount(count: 7),
      s.timelineProofsAttached(count: 3),
      s.claimHeldByYou(minutes: 9),
      s.ageMinutes(count: 45),
      s.ageDaysHours(days: 12, hours: 6),
      s.sizeKilobytes(count: 512),
      s.severityShort(n: 5),
      s.proofIndexOfTotal(index: 2, total: 8),
      s.errorTooManyRequestsRetryIn(seconds: 30),
      s.violationsFound(count: 21),
      s.auCountShownOfTotal(shown: 25, total: 140),
    ];
    for (final String value in rendered) {
      expect(
        _easternDigits.hasMatch(value),
        isFalse,
        reason: 'Eastern Arabic numerals leaked into "$value" - the bot prints '
            'Western digits and so must the console.',
      );
    }
  });

  test('placeholders are interpolated, not left as braces', () {
    expect(
      AppStrings.ar.detailNotFound(shortId: 'K7Q2ZP9V3M'),
      contains('K7Q2ZP9V3M'),
    );
    expect(
      AppStrings.en.rejectSheetSubtitle(shortId: 'K7Q2ZP9V3M', amount: '1,500.00 NSP'),
      'K7Q2ZP9V3M - 1,500.00 NSP',
    );
    // The money key is a pure layout template: it must never reformat.
    expect(
      AppStrings.ar.moneyAmountWithCurrency(amount: '1,500.00', currency: 'NSP'),
      '1,500.00 NSP',
    );
  });

  group('AppDateFormats', () {
    setUpAll(() async {
      await initializeDateFormatting();
    });

    test('localises month names but never the digits', () {
      final DateTime value = DateTime(2026, 8, 17, 14, 5);
      final String ar = AppDateFormats.mediumDayTime(value, 'ar');
      final String en = AppDateFormats.mediumDayTime(value, 'en');

      expect(_easternDigits.hasMatch(ar), isFalse);
      expect(ar, contains('17'));
      expect(ar, contains('2026'));
      expect(ar, contains('14:05'));
      // The month name really is translated, so the two differ.
      expect(ar, isNot(en));
      expect(en, contains('Aug'));
    });

    test('dayTime and day are stable, sortable and ASCII in both locales', () {
      final DateTime value = DateTime(2026, 1, 3, 9, 7, 33);
      expect(AppDateFormats.dayTime(value, 'ar'), '2026-01-03 09:07');
      expect(AppDateFormats.dayTime(value, 'en'), '2026-01-03 09:07');
      expect(AppDateFormats.day(value, 'ar'), '2026-01-03');
      expect(AppDateFormats.timeOfDay(value, 'ar'), '09:07:33');
    });

    test('toWesternDigits rewrites both Arabic-Indic ranges and nothing else', () {
      expect(AppDateFormats.toWesternDigits('١٢٣٤٥٦٧٨٩٠'), '1234567890');
      expect(AppDateFormats.toWesternDigits('۱۲۳'), '123');
      expect(AppDateFormats.toWesternDigits('الطابور فارغ'), 'الطابور فارغ');
      expect(AppDateFormats.toWesternDigits(''), '');
    });
  });
}
