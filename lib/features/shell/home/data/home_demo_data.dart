/// EVERY piece of sample content the home destination shows, in ONE file.
///
/// WHY THIS EXISTS AND IS NOT A SHORTCUT
/// Each player endpoint on the backend demands a bearer token, and the owner
/// asked for the entry code to be removed for now. With no session there is
/// nothing real to fetch, so the home tab renders from here instead. The
/// contract is deliberate: `application/home_providers.dart` is the ONLY file
/// that names [HomeDemoData], so swapping in a live repository is a one-file
/// change and no widget moves.
///
/// The content is realistic on purpose - Syrian names, NSP amounts as exact
/// `BigInt` minor units at scale 2, believable ages and a spread of statuses -
/// so layout problems show up now rather than on the day the API is wired in.
library;

import 'package:manager_bot/core/money/money.dart';
import 'package:manager_bot/features/shell/home/data/home_models.dart';

/// Which shape the home tab renders.
///
/// The empty and failing layouts have to be reachable even though the data is
/// local; overriding `homeDemoModeProvider` is how a test (or a future dev
/// menu) exercises them.
enum HomeDemoMode {
  /// The normal, populated home tab.
  content,

  /// A brand-new player: balance, no history.
  empty,

  /// The load fails, so the error shape is exercised.
  unavailable,
}

/// The sample content itself.
abstract final class HomeDemoData {
  /// How long the fake load takes. Long enough that the skeleton is really
  /// seen, short enough that the app never feels slow.
  static const Duration loadDelay = Duration(milliseconds: 420);

  /// 1,507,500.00 NSP. Written as minor units so the value cannot drift:
  /// `150750000` minor == `1507500.00` major at scale 2.
  static Money balance() => Money.fromMinorString('150750000');

  /// The populated home tab.
  static HomeSnapshot snapshot() => HomeSnapshot(
        playerName: 'وسيم الحموي',
        playerInitials: 'و ح',
        balance: balance(),
        balanceAge: const Duration(minutes: 4),
        pendingCount: 1,
        isCasinoAccountLinked: false,
        promos: promos,
        recentDeposits: recentDeposits(),
      );

  /// A player who has just installed the app.
  static HomeSnapshot emptySnapshot() => HomeSnapshot(
        playerName: 'رهف العلي',
        playerInitials: 'ر ع',
        balance: Money.zero(),
        balanceAge: const Duration(minutes: 1),
        pendingCount: 0,
        isCasinoAccountLinked: false,
        promos: promos,
        recentDeposits: const <HomeDeposit>[],
      );

  /// The announcement carousel. Three pages, no auto-advance.
  static const List<HomePromo> promos = <HomePromo>[
    HomePromo(slot: HomePromoSlot.welcomeBonus, accent: HomeAccent.signature),
    HomePromo(slot: HomePromoSlot.instantCredit, accent: HomeAccent.neon),
    HomePromo(slot: HomePromoSlot.trustedRails, accent: HomeAccent.hot),
  ];

  /// Newest first, with a spread of statuses and a spread of ages so every
  /// tone and every age branch is on screen at once.
  ///
  /// Minor units, scale 2:
  /// * `25000000`  ==   250,000.00 NSP
  /// * `7500000`   ==    75,000.00 NSP
  /// * `50000000`  ==   500,000.00 NSP
  /// * `12000000`  ==   120,000.00 NSP
  static List<HomeDeposit> recentDeposits() => <HomeDeposit>[
        HomeDeposit(
          shortId: 'D-7QF2K9',
          amount: Money.fromMinorString('25000000'),
          status: HomeDepositStatus.credited,
          methodName: 'Syriatel Cash',
          age: const Duration(minutes: 12),
        ),
        HomeDeposit(
          shortId: 'D-3MX8P1',
          amount: Money.fromMinorString('7500000'),
          status: HomeDepositStatus.underReview,
          methodName: 'MTN Cash',
          age: const Duration(hours: 3, minutes: 20),
        ),
        HomeDeposit(
          shortId: 'D-9BC4T6',
          amount: Money.fromMinorString('50000000'),
          status: HomeDepositStatus.approved,
          methodName: 'Bemo Bank',
          age: const Duration(hours: 8),
        ),
        HomeDeposit(
          shortId: 'D-2LK7R0',
          amount: Money.fromMinorString('12000000'),
          status: HomeDepositStatus.rejected,
          methodName: 'USDT TRC20',
          age: const Duration(days: 1, hours: 6),
        ),
      ];
}
