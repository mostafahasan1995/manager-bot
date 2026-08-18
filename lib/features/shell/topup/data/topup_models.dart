/// The shapes the top-up flow renders from.
///
/// These are the classes a live `TopUpRepository` will hydrate later. Nothing
/// here touches the network, and every amount is a [Money] over `BigInt` minor
/// units - there is no `double` anywhere in the flow.
library;

import 'package:flutter/foundation.dart' show immutable;
import 'package:manager_bot/core/money/money.dart';

/// How the money physically moves. Mirrors the backend's payment rails, and
/// each value already has an `AppStrings` label (`railMobileWallet`, ...).
enum TopUpRail {
  /// Syriatel Cash / MTN Cash.
  mobileWallet,

  /// A named bank account.
  bankTransfer,

  /// A money-transfer counter the player walks into.
  cashOffice,

  /// USDT and friends.
  crypto,
}

/// One account on a method that the player may send money to.
///
/// The label is carried in both languages because a live method returns one
/// display string per locale; the widgets never translate a destination.
@immutable
class TopUpDestination {
  const TopUpDestination({
    required this.id,
    required this.labelAr,
    required this.labelEn,
    required this.accountNumber,
    required this.accountHolder,
  });

  /// Stable identifier. What the draft stores, never the index.
  final String id;

  final String labelAr;
  final String labelEn;

  /// Shown verbatim and copied verbatim - never reformatted, never grouped.
  final String accountNumber;

  /// The person the transfer must be addressed to.
  final String accountHolder;

  /// The label for the reading locale (`ar` or `en`).
  String label(String localeTag) => localeTag == 'ar' ? labelAr : labelEn;
}

/// A payment method the player can top up over, with its own money window.
@immutable
class TopUpMethod {
  const TopUpMethod({
    required this.id,
    required this.rail,
    required this.nameAr,
    required this.nameEn,
    required this.minAmount,
    required this.maxAmount,
    required this.feeFixed,
    required this.requiresReference,
    required this.instructionsAr,
    required this.instructionsEn,
    required this.reviewMinutes,
    required this.destinations,
  });

  /// Stable identifier. What the draft stores.
  final String id;

  final TopUpRail rail;
  final String nameAr;
  final String nameEn;

  /// Smallest amount the method accepts, inclusive.
  final Money minAmount;

  /// Largest amount the method accepts, inclusive.
  final Money maxAmount;

  /// Flat fee taken off the top before the balance is credited.
  final Money feeFixed;

  /// True when the player must quote the reference in the transfer note.
  final bool requiresReference;

  final String instructionsAr;
  final String instructionsEn;

  /// Typical staff review time, in minutes. Shown as an expectation only.
  final int reviewMinutes;

  /// Accounts on this method. May be empty - a method whose destinations are
  /// all disabled is a real state, and the UI has to say so.
  final List<TopUpDestination> destinations;

  /// The display name for the reading locale.
  String name(String localeTag) => localeTag == 'ar' ? nameAr : nameEn;

  /// The player-facing instructions for the reading locale.
  String instructions(String localeTag) =>
      localeTag == 'ar' ? instructionsAr : instructionsEn;

  /// True when [amount] sits inside this method's window, inclusive of both
  /// ends. Exact `BigInt` comparison, never a rounded one.
  bool accepts(Money amount) => amount >= minAmount && amount <= maxAmount;

  /// What actually lands in the casino balance after [feeFixed].
  Money creditedFor(Money amount) => amount - feeFixed;

  /// The destination with [destinationId], or null when nothing matches.
  TopUpDestination? destinationById(String? destinationId) {
    if (destinationId == null) {
      return null;
    }
    for (final TopUpDestination destination in destinations) {
      if (destination.id == destinationId) {
        return destination;
      }
    }
    return null;
  }
}

/// The widest amount window the whole catalogue allows.
///
/// The amount step runs before a method is chosen, so it validates against
/// this; the method step then rejects the individual methods that cannot take
/// the typed amount.
@immutable
class TopUpLimits {
  const TopUpLimits({required this.minimum, required this.maximum});

  final Money minimum;
  final Money maximum;

  /// Union of every method's window. Null when [methods] is empty.
  static TopUpLimits? across(List<TopUpMethod> methods) {
    if (methods.isEmpty) {
      return null;
    }
    Money low = methods.first.minAmount;
    Money high = methods.first.maxAmount;
    for (final TopUpMethod method in methods) {
      if (method.minAmount < low) {
        low = method.minAmount;
      }
      if (method.maxAmount > high) {
        high = method.maxAmount;
      }
    }
    return TopUpLimits(minimum: low, maximum: high);
  }

  /// True when [amount] is inside the union window.
  bool accepts(Money amount) => amount >= minimum && amount <= maximum;
}
