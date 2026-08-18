import 'package:flutter_test/flutter_test.dart';
import 'package:manager_bot/core/money/money.dart';
import 'package:manager_bot/features/shell/profile/data/profile_demo_data.dart';

/// The profile tab renders from local sample content, which makes it exactly
/// the place a `double` could sneak into the money path unnoticed. It cannot.
void main() {
  final DateTime now = DateTime.utc(2026, 8, 17, 12);

  group('ProfileDemoData.sampleAt', () {
    test('the lifetime total is exact BigInt minor units at scale 2', () {
      final PlayerProfile profile = ProfileDemoData.sampleAt(now);

      expect(profile.totalDeposited.minor, BigInt.parse('412750000'));
      expect(profile.totalDeposited.toMinorString(), '412750000');
      expect(profile.totalDeposited.toDecimalString(), '4127500.00');
      expect(profile.totalDeposited.scale, 2);
      expect(profile.totalDeposited.currency, Money.defaultCurrency);
      expect(profile.currency, 'NSP');
    });

    test('the total renders with Western digits and no rounding', () {
      final PlayerProfile profile = ProfileDemoData.sampleAt(now);

      expect(
        profile.totalDeposited.format(locale: 'en', withCurrency: false),
        '4,127,500.00',
      );
      expect(
        profile.totalDeposited.format(locale: 'ar', withCurrency: false),
        '4,127,500.00',
      );
    });

    test('is pinned to the instant it is given, never to the wall clock', () {
      final PlayerProfile profile = ProfileDemoData.sampleAt(now);

      expect(profile.memberSince.isBefore(now), isTrue);
      expect(profile.membershipAge(now).inDays, 287);
      expect(ProfileDemoData.sampleAt(now).memberSince, profile.memberSince);
    });

    test('the invite link carries the referral code the player copies', () {
      final PlayerProfile profile = ProfileDemoData.sampleAt(now);

      expect(profile.referralCode, isNotEmpty);
      expect(profile.inviteLink, contains(profile.referralCode));
      expect(profile.inviteLink, startsWith('https://t.me/'));
    });

    test('the username handle is built once, with a single @', () {
      final PlayerProfile profile = ProfileDemoData.sampleAt(now);

      expect(profile.username, isNot(startsWith('@')));
      expect(profile.usernameHandle, '@${profile.username}');
      expect('@'.allMatches(profile.usernameHandle).length, 1);
    });

    test('the Telegram id is digits held as a string, not a number', () {
      final PlayerProfile profile = ProfileDemoData.sampleAt(now);

      expect(profile.telegramId, matches(RegExp(r'^\d{5,19}$')));
    });
  });

  group('ProfileDemoData.load', () {
    test('resolves to a profile, which is what the data state renders', () async {
      final PlayerProfile? profile = await ProfileDemoData.load();

      expect(profile, isNotNull);
      expect(profile?.depositCount, greaterThan(0));
    });
  });
}
