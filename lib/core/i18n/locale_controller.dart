import 'dart:ui' show Locale;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/date_symbol_data_local.dart';
// `show Intl` only: package:intl also exports a TextDirection that clashes with
// dart:ui's, and this file has no business seeing it.
import 'package:intl/intl.dart' show Intl;
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/logging/app_logger.dart';

/// The two locales this console ships, and nothing else.
///
/// ARABIC IS THE DEFAULT. An unknown or absent preference resolves to Arabic,
/// not to the device language and not to English: the operators are a Syrian
/// cashier desk and the bot they cross-check against speaks Arabic.
abstract final class AppLocales {
  /// `ar` - the default.
  static const Locale arabic = Locale('ar');

  /// `en` - reachable from the Settings language toggle.
  static const Locale english = Locale('en');

  /// What `MaterialApp.supportedLocales` is given. Order matters only for
  /// Flutter's own resolution; the app always passes an explicit `locale`.
  static const List<Locale> supported = <Locale>[arabic, english];

  /// Used whenever a stored or device locale cannot be honoured.
  static const Locale fallback = arabic;

  /// Parses a persisted or device language tag (`ar`, `en`, `en-GB`, `ar_SY`).
  ///
  /// Anything that is not English becomes [arabic]. Returns [fallback] for
  /// null, empty or unparseable input rather than throwing - a corrupt
  /// preference must never stop the app booting.
  static Locale parse(String? tag) {
    final String normalized = (tag ?? '').trim().toLowerCase();
    if (normalized.isEmpty) {
      return fallback;
    }
    return normalized.startsWith('en') ? english : arabic;
  }

  /// The tag written to the keystore and handed to `DateFormat`.
  static String tagOf(Locale locale) => locale.languageCode;

  /// True when [locale] renders right to left.
  static bool isRtl(Locale locale) => locale.languageCode != 'en';
}

/// Persists the language choice in the platform keystore.
///
/// It shares the keystore with [TokenStore] but NOT its key, so signing out
/// does not silently flip an operator's console back to English. A corrupt
/// value is deleted and treated as "no preference".
class LocaleStore {
  LocaleStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  /// Keystore key. Versioned so a future format change cannot be misread.
  static const String localeKey = 'manager_bot.locale.v1';

  final FlutterSecureStorage _storage;

  /// The stored preference, or null when the operator has never chosen one.
  Future<Locale?> read() async {
    try {
      final String? raw = await _storage.read(key: localeKey);
      if (raw == null || raw.trim().isEmpty) {
        return null;
      }
      return AppLocales.parse(raw);
    } on Object catch (e) {
      AppLogger.warn('Discarding unreadable stored locale: $e', scope: 'i18n');
      await clear();
      return null;
    }
  }

  /// Writes the preference. Failures are logged, never thrown: a keystore that
  /// refuses to write must not block a language change for this session.
  Future<void> write(Locale locale) async {
    try {
      await _storage.write(key: localeKey, value: AppLocales.tagOf(locale));
    } on Object catch (e) {
      AppLogger.warn('Could not persist the locale: $e', scope: 'i18n');
    }
  }

  Future<void> clear() async {
    try {
      await _storage.delete(key: localeKey);
    } on Object catch (e) {
      AppLogger.warn('Could not clear the stored locale: $e', scope: 'i18n');
    }
  }
}

final Provider<LocaleStore> localeStoreProvider =
    Provider<LocaleStore>((ref) => LocaleStore());

/// The locale resolved from the keystore BEFORE the first frame.
///
/// `main()` overrides this with the value [bootstrapLocale] returned, which is
/// why the app never paints an English frame and then flips to Arabic. Widget
/// tests override it directly to pin a locale.
///
/// ```dart
/// ProviderScope(
///   overrides: <Override>[
///     initialLocaleProvider.overrideWithValue(AppLocales.english),
///   ],
///   child: const ManagerBotApp(),
/// );
/// ```
final Provider<Locale> initialLocaleProvider =
    Provider<Locale>((ref) => AppLocales.fallback);

/// Holds the active [Locale] and persists every change.
///
/// The state is synchronous from the very first read because the restore
/// happened in `main()`; nothing here awaits the keystore on the paint path.
class LocaleController extends Notifier<Locale> {
  @override
  Locale build() {
    final Locale restored = ref.read(initialLocaleProvider);
    Intl.defaultLocale = AppLocales.tagOf(restored);
    return restored;
  }

  /// Switches the console and writes the choice through to the keystore.
  ///
  /// The UI updates immediately; the write is awaited so a caller can show a
  /// failure, but a keystore error only costs the persistence, not the switch.
  Future<void> setLocale(Locale locale) async {
    final Locale next =
        AppLocales.parse(locale.languageCode) == AppLocales.english
            ? AppLocales.english
            : AppLocales.arabic;
    if (next == state) {
      return;
    }
    state = next;
    Intl.defaultLocale = AppLocales.tagOf(next);
    AppLogger.info('locale -> ${AppLocales.tagOf(next)}', scope: 'i18n');
    await ref.read(localeStoreProvider).write(next);
  }

  /// Convenience for the Settings toggle.
  Future<void> useArabic() => setLocale(AppLocales.arabic);

  /// Convenience for the Settings toggle.
  Future<void> useEnglish() => setLocale(AppLocales.english);

  /// Flips between the two shipped locales.
  Future<void> toggle() => setLocale(
        state == AppLocales.english ? AppLocales.arabic : AppLocales.english,
      );
}

/// The active locale. Watch this in `MaterialApp.locale`.
final NotifierProvider<LocaleController, Locale> localeControllerProvider =
    NotifierProvider<LocaleController, Locale>(LocaleController.new);

/// The string bundle for the active locale.
///
/// Widgets should prefer `context.s`, which reads the locale from
/// `Localizations` and therefore rebuilds with the rest of the tree. Use this
/// provider in controllers, repositories and anywhere without a
/// [BuildContext]:
///
/// ```dart
/// final AppStrings s = ref.read(stringsProvider);
/// throw ApiNotFound(s.detailNotFound(shortId: shortId));
/// ```
final Provider<AppStrings> stringsProvider = Provider<AppStrings>(
  (ref) => AppStrings.of(ref.watch(localeControllerProvider)),
);

/// True when the console is currently right-to-left.
final Provider<bool> isRtlProvider =
    Provider<bool>((ref) => AppLocales.isRtl(ref.watch(localeControllerProvider)));

/// Prepares localisation BEFORE the first frame. Call from `main()`.
///
/// It does two things and both must happen before `runApp`:
/// 1. loads `intl` date symbols, so an Arabic `DateFormat` has month names;
/// 2. reads the persisted locale, so the first frame is already correct.
///
/// Pass the result to [initialLocaleProvider] as a `ProviderScope` override.
Future<Locale> bootstrapLocale({LocaleStore? store}) async {
  await initializeDateFormatting();
  final Locale restored =
      await (store ?? LocaleStore()).read() ?? AppLocales.fallback;
  Intl.defaultLocale = AppLocales.tagOf(restored);
  return restored;
}
