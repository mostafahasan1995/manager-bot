/// The shapes the الرئيسية (home) destination renders.
///
/// Nothing in this file talks to the network and nothing here formats a
/// string for the screen. Today every value is produced by
/// `home_demo_data.dart`; when the player API gains a session the SAME shapes
/// come back from a repository and nothing under `presentation/` changes.
///
/// Money is always [Money] - exact `BigInt` minor units at scale 2. There is no
/// `double` anywhere in this feature.
library;

import 'package:flutter/foundation.dart' show immutable;
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/money/money.dart';

/// Where one of the player's own deposits currently sits.
///
/// A deliberately SMALLER set than the admin console's `DepositStatus`: a
/// player only ever needs to know "waiting", "accepted", "in my balance" or
/// "refused". The presentation layer maps this onto an `AppTone`.
enum HomeDepositStatus {
  /// Receipt uploaded, nobody has picked it up yet.
  submitted,

  /// A cashier has it open right now.
  underReview,

  /// A human said yes; the credit has not landed yet.
  approved,

  /// The money is in the casino balance.
  credited,

  /// Refused. The player must read the reason.
  rejected,
}

/// Which gradient family a promo card wears. Kept in the data layer because a
/// live campaign endpoint would carry the same hint; the mapping to an actual
/// `LinearGradient` lives in `presentation/home_labels.dart`.
enum HomeAccent {
  /// Violet -> pink -> amber, the brand.
  signature,

  /// Cyan -> violet.
  neon,

  /// Magenta -> violet, the Bigo register.
  hot,

  /// Purple -> red -> amber, the Instagram register.
  sunset,
}

/// Which piece of announcement copy a promo card shows.
///
/// The card carries a SLOT, never a sentence: every word on screen still comes
/// from `AppStrings`, so a promo translates like everything else.
enum HomePromoSlot {
  /// First top-up bonus.
  welcomeBonus,

  /// "Credited in minutes".
  instantCredit,

  /// "Trusted payment rails".
  trustedRails,
}

/// One row of "آخر العمليات".
@immutable
class HomeDeposit {
  const HomeDeposit({
    required this.shortId,
    required this.amount,
    required this.status,
    required this.methodName,
    required this.age,
  });

  /// The reference the bot quotes back to the player. Technical, never
  /// translated.
  final String shortId;

  /// Exact minor units. Never rendered by hand - `AmountText` owns that.
  final Money amount;

  final HomeDepositStatus status;

  /// Display name of the payment rail as the backend stores it ("Syriatel
  /// Cash", "Bemo Bank"). A brand, so it is NOT a translated string.
  final String methodName;

  /// How long ago the request was created. Turned into "منذ 12 د" by
  /// [HomeAgeFormat].
  final Duration age;

  @override
  bool operator ==(Object other) =>
      other is HomeDeposit &&
      other.shortId == shortId &&
      other.amount == amount &&
      other.status == status &&
      other.methodName == methodName &&
      other.age == age;

  @override
  int get hashCode => Object.hash(shortId, amount, status, methodName, age);

  @override
  String toString() => 'HomeDeposit($shortId, ${amount.toMinorString()}, '
      '${status.name})';
}

/// One page of the announcement carousel.
@immutable
class HomePromo {
  const HomePromo({required this.slot, required this.accent});

  final HomePromoSlot slot;
  final HomeAccent accent;

  @override
  bool operator ==(Object other) =>
      other is HomePromo && other.slot == slot && other.accent == accent;

  @override
  int get hashCode => Object.hash(slot, accent);

  @override
  String toString() => 'HomePromo(${slot.name}, ${accent.name})';
}

/// Everything the home tab needs for one paint.
///
/// One object, so the screen has exactly one `AsyncValue` to switch on and the
/// loading / empty / error shapes stay honest.
@immutable
class HomeSnapshot {
  const HomeSnapshot({
    required this.playerName,
    required this.playerInitials,
    required this.balance,
    required this.balanceAge,
    required this.pendingCount,
    required this.isCasinoAccountLinked,
    required this.promos,
    required this.recentDeposits,
  });

  /// The player's own name. Data, not copy - never translated.
  final String playerName;

  /// One or two glyphs for the avatar ring.
  final String playerInitials;

  /// The casino balance. Exact minor units.
  final Money balance;

  /// How stale the balance reading is.
  final Duration balanceAge;

  /// How many of the player's deposits are still waiting on a cashier.
  final int pendingCount;

  /// False shows the "link your casino account" banner.
  final bool isCasinoAccountLinked;

  final List<HomePromo> promos;

  /// Newest first. The screen shows at most [recentLimit] of them.
  final List<HomeDeposit> recentDeposits;

  /// How many rows "آخر العمليات" shows before deferring to the الكل link.
  static const int recentLimit = 3;

  bool get hasRecentDeposits => recentDeposits.isNotEmpty;

  /// The rows actually painted on the home tab.
  List<HomeDeposit> get visibleDeposits =>
      recentDeposits.length <= recentLimit
          ? recentDeposits
          : recentDeposits.sublist(0, recentLimit);

  @override
  String toString() => 'HomeSnapshot($playerName, '
      '${balance.toMinorString()}, ${recentDeposits.length} recent)';
}

/// Turns a [Duration] into the catalogue's age wording.
///
/// Both bundles already own `ageMinutes` / `ageHours` / `ageDaysHours` and the
/// `ageAgo` wrapper, so nothing new is invented here and the digits stay
/// Western in Arabic exactly as they do everywhere else in the app.
abstract final class HomeAgeFormat {
  /// The bare age: `12 د` / `12m`. Feed this to a key that adds its own
  /// "منذ", such as `headlineCreatedAgo`.
  static String compact(AppStrings s, Duration age) {
    final int totalMinutes = age.inMinutes;
    if (totalMinutes < 60) {
      return s.ageMinutes(count: totalMinutes < 1 ? 1 : totalMinutes);
    }
    if (age.inHours < 24) {
      final int hours = age.inHours;
      final int minutes = totalMinutes - hours * 60;
      return minutes == 0
          ? s.ageHours(count: hours)
          : s.ageHoursMinutes(hours: hours, minutes: minutes);
    }
    final int days = age.inDays;
    final int hours = age.inHours - days * 24;
    return s.ageDaysHours(days: days, hours: hours);
  }

  /// The full phrase: `منذ 12 د` / `12m ago`.
  static String ago(AppStrings s, Duration age) =>
      s.ageAgo(age: compact(s, age));
}
