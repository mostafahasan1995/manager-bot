import 'package:manager_bot/core/api/json.dart';
import 'package:manager_bot/core/money/money.dart';

/// `POST /v1/admin/reconciliation/agent-float/sync`.
///
/// Compares the `ICHANCY_AGENT_FLOAT` ledger balance against the Ichancy agent
/// wallet's AVAILABLE balance. Every amount is a raw minor-unit decimal string
/// (no formatted twin), so all three are parsed into [Money].
///
/// IMPORTANT: an unreachable Ichancy API is NOT an error response. It is a 200
/// with [ichancy], [delta] and [breakId] all null. That is [walletUnavailable].
class FloatSyncResult {
  const FloatSyncResult({
    required this.currencyCode,
    required this.ledger,
    required this.belowWatermark,
    this.ichancy,
    this.delta,
    this.breakId,
  });

  factory FloatSyncResult.fromJson(Map<String, Object?> json) {
    final String currency =
        Json.stringOrNull(json, 'currencyCode')?.trim().toUpperCase() ??
            Money.defaultCurrency;
    return FloatSyncResult(
      currencyCode: currency,
      ledger: Money.fromMinorStringOrNull(json['ledgerMinor'],
              currency: currency) ??
          Money.zero(currency: currency),
      ichancy: Money.fromMinorStringOrNull(json['ichancyMinor'],
          currency: currency),
      delta:
          Money.fromMinorStringOrNull(json['deltaMinor'], currency: currency),
      breakId: Json.stringOrNull(json, 'breakId'),
      belowWatermark: Json.boolean(json, 'belowWatermark', orElse: false),
    );
  }

  /// Server-chosen currency (config `ICHANCY_CURRENCY`); NOT client selectable.
  final String currencyCode;

  /// Our books. `0` when the float account does not exist yet.
  final Money ledger;

  /// The Ichancy wallet's AVAILABLE balance, or null when the read failed.
  final Money? ichancy;

  /// SIGNED `ichancy - ledger`. Positive means Ichancy holds MORE than our
  /// books say. Null exactly when [ichancy] is null.
  final Money? delta;

  /// The break opened or refreshed by this comparison. Null when the delta was
  /// zero OR when the wallet read failed.
  final String? breakId;

  /// Computed from DIFFERENT sources in the two branches: against the Ichancy
  /// balance on a successful read, against the LEDGER balance on a failed one.
  /// The watermark itself is not returned by the endpoint.
  final bool belowWatermark;

  /// The Ichancy side could not be read. Everything shown is our side only.
  bool get walletUnavailable => ichancy == null;

  /// Tolerance is exactly 0 minor units, so any non-zero delta opens a break.
  bool get inTolerance {
    final Money? value = delta;
    return value != null && value.isZero;
  }

  /// A real difference exists right now.
  bool get hasDrift {
    final Money? value = delta;
    return value != null && !value.isZero;
  }

  /// True when Ichancy holds more than our books (we owe the books an entry).
  bool get ichancyHoldsMore {
    final Money? value = delta;
    return value != null && value.isPositive;
  }

  /// The figure the watermark comparison actually used, for an honest caption.
  Money get watermarkSubject => ichancy ?? ledger;
}

/// `POST /v1/admin/reconciliation/breaks/:id/correct-float` success body.
///
/// Exactly two keys; the updated break is NOT returned, so the caller must
/// re-fetch `GET /breaks/:id` to see it as RESOLVED with `resolutionTxId` set.
class CorrectFloatReceipt {
  const CorrectFloatReceipt({
    required this.ledgerTransactionId,
    required this.delta,
  });

  /// [currencyCode] must come from the break: the response carries no currency.
  factory CorrectFloatReceipt.fromJson(
    Map<String, Object?> json, {
    String currencyCode = Money.defaultCurrency,
  }) {
    return CorrectFloatReceipt(
      ledgerTransactionId: Json.string(json, 'ledgerTransactionId'),
      delta: Money.fromMinorStringOrNull(json['deltaMinor'],
              currency: currencyCode) ??
          Money.zero(currency: currencyCode),
    );
  }

  /// UUID of the posted `AGENT_FLOAT_SYNC` ledger transaction.
  final String ledgerTransactionId;

  /// The break's stored delta that was corrected. Signed.
  final Money delta;
}
