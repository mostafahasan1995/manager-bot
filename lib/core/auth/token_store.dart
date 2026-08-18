import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:manager_bot/core/api/json.dart';
import 'package:manager_bot/core/auth/admin_auth_api.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/i18n/locale_controller.dart';
import 'package:manager_bot/core/logging/app_logger.dart';

/// Persists the admin session in the platform keystore.
///
/// Android: EncryptedSharedPreferences (AES via the Android Keystore).
/// iOS: Keychain, `first_unlock_this_device` so a background refresh after a
/// reboot still works but the token never leaves the handset in a backup.
///
/// Only the session is stored - never a bot code, never a player token.
class TokenStore {
  TokenStore({FlutterSecureStorage? storage, AppStrings Function()? strings})
      : _strings = strings ?? _arabicStrings,
        _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  static const String sessionKey = 'manager_bot.admin_session.v1';

  final FlutterSecureStorage _storage;
  final AppStrings Function() _strings;

  static AppStrings _arabicStrings() => AppStrings.ar;

  /// Reads the persisted session, or null when there is none.
  ///
  /// A corrupt or outdated blob is deleted and treated as "no session" rather
  /// than crashing the app on launch.
  Future<AdminSession?> read() async {
    try {
      final raw = await _storage.read(key: sessionKey);
      if (raw == null || raw.isEmpty) {
        return null;
      }
      final Object? decoded = jsonDecode(raw) as Object?;
      return AdminSession.fromStorageJson(
        Json.asObject(decoded, path: sessionKey),
        strings: _strings(),
      );
    } on Object catch (e) {
      AppLogger.warn('Discarding unreadable stored session: $e', scope: 'auth');
      await clear();
      return null;
    }
  }

  Future<void> write(AdminSession session) async {
    await _storage.write(
      key: sessionKey,
      value: jsonEncode(session.toStorageJson()),
    );
  }

  Future<void> clear() async {
    try {
      await _storage.delete(key: sessionKey);
    } on Object catch (e) {
      AppLogger.warn('Could not clear the stored session: $e', scope: 'auth');
    }
  }
}

final Provider<TokenStore> tokenStoreProvider = Provider<TokenStore>(
  (ref) => TokenStore(strings: () => ref.read(stringsProvider)),
);
