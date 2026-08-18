import 'package:manager_bot/core/money/money.dart';

/// Where a player's account stands with the cashier desk.
///
/// The bot's `/profile` command prints the same three states, so the wording in
/// [AppStrings] mirrors it.
enum PlayerAccountStatus {
  /// Everything works: deposits are accepted and credited normally.
  active,

  /// Deposits still work but something needs the player's attention.
  limited,

  /// The desk has stopped this account.
  suspended,
}

/// State of the Ichancy gaming account the balance is credited into.
enum GamingAccountState {
  /// Linked; approved deposits land automatically.
  linked,

  /// The desk is still linking it.
  pending,

  /// No gaming account is attached yet.
  missing,
}

/// Everything the "حسابي" tab shows about the player.
///
/// Every amount is [Money] - exact `BigInt` minor units at scale 2. There is no
/// `double` anywhere in this file and there never may be.
class PlayerProfile {
  const PlayerProfile({
    required this.displayName,
    required this.initials,
    required this.username,
    required this.telegramId,
    required this.currency,
    required this.accountStatus,
    required this.gamingAccount,
    required this.referralCode,
    required this.inviteLink,
    required this.memberSince,
    required this.totalDeposited,
    required this.depositCount,
    required this.supportHandle,
    required this.appVersion,
  });

  /// Full name as the desk knows it.
  final String displayName;

  /// One or two glyphs for the avatar ring.
  final String initials;

  /// Telegram username WITHOUT the leading `@`.
  final String username;

  /// The 64-bit Telegram user id, kept as a STRING: it is an identifier, never
  /// a number to do arithmetic on.
  final String telegramId;

  /// Wallet currency code, `NSP`.
  final String currency;

  final PlayerAccountStatus accountStatus;
  final GamingAccountState gamingAccount;

  /// Short code the player gives a friend.
  final String referralCode;

  /// Deep link into the bot carrying [referralCode].
  final String inviteLink;

  /// When the account was created. Local time, like every other timestamp.
  final DateTime memberSince;

  /// Lifetime total of credited deposits.
  final Money totalDeposited;

  /// How many deposits have been credited.
  final int depositCount;

  /// Telegram handle of the cashier desk.
  final String supportHandle;

  /// Version name and build number of this build.
  final String appVersion;

  /// `@ahmad_hms`, ready to render.
  String get usernameHandle => '@$username';

  /// How long this player has been with the desk, as of [now].
  Duration membershipAge(DateTime now) => now.difference(memberSince);
}

/// The ONE file holding the profile tab's sample content.
///
/// Every data endpoint on the backend needs a bearer token and this build has
/// no session, so the screen renders from here instead. Swapping to the live
/// repository is a single change: give [load] a different body (or replace this
/// class with the repository provider) and nothing in `presentation/` moves.
///
/// The public `/health/live` probe is deliberately NOT here - it is a real
/// request and lives in `application/health_check_controller.dart`.
abstract final class ProfileDemoData {
  /// Stands in for the round trip a real `GET /v1/players/me` would cost, so
  /// the loading skeleton is exercised on every open instead of only in theory.
  static const Duration loadDelay = Duration(milliseconds: 260);

  /// Loads the profile.
  ///
  /// Returns null for "this player has no profile yet", which is the shape the
  /// screen's empty state is built for.
  static Future<PlayerProfile?> load() =>
      Future<PlayerProfile?>.delayed(loadDelay, _current);

  /// The sample profile, pinned to [now] so tests never depend on the clock.
  static PlayerProfile sampleAt(DateTime now) => PlayerProfile(
        displayName: 'أحمد الحموي',
        initials: 'أح',
        username: 'ahmad_hms',
        telegramId: '704218935',
        currency: Money.defaultCurrency,
        accountStatus: PlayerAccountStatus.active,
        gamingAccount: GamingAccountState.linked,
        referralCode: 'SYR-7QK2M9',
        inviteLink: 'https://t.me/Ichancy_global_syria_bot?start=SYR-7QK2M9',
        memberSince: now.subtract(const Duration(days: 287, hours: 6)),
        // 4,127,500.00 NSP across 37 credited deposits.
        totalDeposited: Money.fromMinorString('412750000'),
        depositCount: 37,
        supportHandle: '@Ichancy_global_syria_bot',
        appVersion: '0.1.0 (1)',
      );

  static PlayerProfile _current() => sampleAt(DateTime.now());
}
