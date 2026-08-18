/// Player-facing models for the طرق الدفع destination.
///
/// These are DEMO-SHAPED, not wire-shaped: every field is exactly what the
/// player screen renders, so when the live `GET /payment-methods` endpoint is
/// wired in only `payment_methods_demo_data.dart` changes - a repository builds
/// these same objects from JSON and nothing in `application/` or
/// `presentation/` moves.
///
/// Two deliberate choices:
///
/// * MONEY IS [Money] over `BigInt` minor units, scale 2. There is no `double`
///   anywhere in this file and no amount is ever built from one.
/// * AGES ARE [Duration], NOT `DateTime`. A duration is `const`-able, so the
///   whole demo catalogue is a compile-time constant and a test never has to
///   freeze the clock to assert on "منذ 12 د".
library;

import 'package:flutter/foundation.dart' show immutable;
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/money/money.dart';

/// The rail a method settles over.
///
/// Mirrors the backend's `PaymentRail` values, but this enum is the PLAYER
/// app's own so the destination never depends on the admin console's feature
/// code. The labels come from the existing catalogue keys.
enum MethodRail {
  bankTransfer,
  mobileWallet,
  cashOffice,
  crypto,

  /// Present for wire completeness. No player-visible method uses it.
  internal;

  /// Localised rail noun, e.g. "محفظة موبايل" / "Mobile wallet".
  String label(AppStrings s) => switch (this) {
        MethodRail.bankTransfer => s.railBankTransfer,
        MethodRail.mobileWallet => s.railMobileWallet,
        MethodRail.cashOffice => s.railCashOffice,
        MethodRail.crypto => s.railCrypto,
        MethodRail.internal => s.railInternal,
      };
}

/// How usable a method is RIGHT NOW.
///
/// The brief asks for a clear visual difference between a method a player can
/// use and one that is temporarily off, so this is a three-state enum rather
/// than a boolean: "busy" is still usable but slower, and hiding that would be
/// a small lie in a money app.
enum MethodAvailability {
  /// Open, settling at its usual speed.
  available,

  /// Open, but under load - settlement will run long.
  busy,

  /// Temporarily paused. A top-up cannot be started on it.
  unavailable;

  /// True when the player may start a top-up on this method.
  bool get acceptsTopUp => this != MethodAvailability.unavailable;
}

/// Which gradient from `AppPalette` carries a method's identity.
///
/// The DATA layer names an intent; `presentation/methods_formats.dart` turns it
/// into a `LinearGradient`. Keeping `dart:ui` out of the model is what lets the
/// demo catalogue be tested without a widget binding.
enum MethodAccent { signature, neon, hot, sunset, glitch, credited }

/// A string the backend would return already localised.
///
/// Method names, account holders and instruction lines are DATA, not UI chrome:
/// they never belong in `AppStrings`. The demo source carries both languages so
/// switching the locale switches them, exactly as a localised API would.
@immutable
class LocalizedText {
  const LocalizedText(this.ar, this.en);

  final String ar;
  final String en;

  /// [localeTag] is `context.localeTag` - `ar` or `en`.
  String resolve(String localeTag) => localeTag == 'ar' ? ar : en;

  @override
  bool operator ==(Object other) =>
      other is LocalizedText && other.ar == ar && other.en == en;

  @override
  int get hashCode => Object.hash(ar, en);

  @override
  String toString() => 'LocalizedText($en)';
}

/// One rail a player can pay over.
@immutable
class PlayerPaymentMethod {
  const PlayerPaymentMethod({
    required this.id,
    required this.name,
    required this.monogram,
    required this.rail,
    required this.accent,
    required this.minAmount,
    required this.maxAmount,
    required this.fixedFee,
    required this.settlement,
    required this.requiresReference,
    required this.availability,
    required this.checkedAgo,
    required this.destinationAccount,
    required this.destinationHolder,
    required this.steps,
    required this.proofItems,
    this.popular = false,
  });

  /// Stable identifier. A UUID on the wire; a slug here.
  final String id;

  /// What the player calls this rail.
  final LocalizedText name;

  /// Two-to-four Latin characters standing in for the brand logo. Latin on
  /// purpose: it is a mark, not a word, and it must not flip under RTL.
  final String monogram;

  final MethodRail rail;

  /// Which brand gradient this method wears.
  final MethodAccent accent;

  /// Smallest accepted top-up. Below it the backend answers
  /// `AMOUNT_BELOW_MINIMUM`.
  final Money minAmount;

  /// Largest accepted top-up.
  final Money maxAmount;

  /// Flat fee taken off the transfer. `Money.zero` means the rail is free.
  final Money fixedFee;

  /// How long the player should expect to wait for the credit.
  /// [Duration.zero] means the rail settles instantly.
  final Duration settlement;

  /// Whether the player must type the transfer reference with the receipt.
  final bool requiresReference;

  final MethodAvailability availability;

  /// How long ago the rail's health was last confirmed, e.g. 12 minutes.
  final Duration checkedAgo;

  /// The account the player pays INTO. Digits only, never localised.
  final String destinationAccount;

  /// The name on that account.
  final LocalizedText destinationHolder;

  /// Ordered "how to pay" instructions.
  final List<LocalizedText> steps;

  /// What the player must be able to show as proof.
  final List<LocalizedText> proofItems;

  /// Surfaced as the featured card. At most one method should set this.
  final bool popular;

  /// True only in the fully-open state; "busy" is deliberately excluded so a
  /// caller cannot accidentally treat a slow rail as a fast one.
  bool get isFullyOpen => availability == MethodAvailability.available;

  /// True while a top-up may be started - open OR busy.
  bool get acceptsTopUp => availability.acceptsTopUp;

  /// True when [fixedFee] actually costs the player something.
  bool get hasFee => fixedFee.isPositive;

  /// True when the rail credits with no perceptible wait.
  bool get isInstant => settlement <= Duration.zero;

  /// The player-visible name in the active language.
  String displayName(String localeTag) => name.resolve(localeTag);

  /// Filter predicate. A null [wanted] means "every rail".
  bool matchesRail(MethodRail? wanted) => wanted == null || wanted == rail;

  @override
  bool operator ==(Object other) => other is PlayerPaymentMethod && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'PlayerPaymentMethod($id, ${availability.name})';
}
