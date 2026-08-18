/// Amount validation for the top-up flow, as pure Dart.
///
/// Kept out of the widgets so it is unit-testable without pumping anything,
/// and kept away from `double` entirely: every check below is exact `BigInt`
/// comparison through [Money].
library;

import 'package:manager_bot/core/money/money.dart';

/// Why a typed amount cannot be used, in the order the player meets them.
enum TopUpAmountIssue {
  /// Nothing typed yet.
  empty,

  /// Not a plain decimal - letters, two separators, an exponent.
  malformed,

  /// More fraction digits than NSP has (scale 2).
  tooManyDecimals,

  /// Zero or negative.
  notPositive,

  /// Under the smallest window any method offers.
  belowMinimum,

  /// Over the largest window any method offers.
  aboveMaximum,
}

/// The single place the top-up amount is judged.
abstract final class TopUpAmountRules {
  /// Returns the first problem with [input], or null when it is usable.
  ///
  /// [minimum] and [maximum] are optional so the amount step can still give
  /// live feedback while the method catalogue is loading; the range checks
  /// simply do not run until the window is known.
  static TopUpAmountIssue? validate(
    String input, {
    Money? minimum,
    Money? maximum,
  }) {
    final String? reason = Money.validationReason(input);
    if (reason == 'MONEY_EMPTY') {
      return TopUpAmountIssue.empty;
    }
    if (reason == 'MONEY_TOO_MANY_DECIMALS') {
      return TopUpAmountIssue.tooManyDecimals;
    }
    final Money? amount = Money.tryParseUserInput(input);
    if (amount == null) {
      return TopUpAmountIssue.malformed;
    }
    if (!amount.isPositive) {
      return TopUpAmountIssue.notPositive;
    }
    final Money? low = minimum;
    if (low != null && amount < low) {
      return TopUpAmountIssue.belowMinimum;
    }
    final Money? high = maximum;
    if (high != null && amount > high) {
      return TopUpAmountIssue.aboveMaximum;
    }
    return null;
  }

  /// True when [input] can be carried forward to the method step.
  static bool isUsable(
    String input, {
    Money? minimum,
    Money? maximum,
  }) =>
      validate(input, minimum: minimum, maximum: maximum) == null;
}
