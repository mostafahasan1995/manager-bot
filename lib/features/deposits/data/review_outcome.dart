import 'package:manager_bot/core/api/json.dart';
import 'package:manager_bot/core/money/money.dart';
import 'package:manager_bot/features/deposits/data/deposit_enums.dart';

/// The RAW Prisma `DepositRequest` row embedded in a [ReviewOutcome].
///
/// This is a DIFFERENT SHAPE from `AdminDepositView`: no `MoneyView` objects,
/// no formatted amounts, no proofs, no risk flags, plus internal columns. Every
/// bigint reaches JSON as a decimal STRING (`BigInt.prototype.toJSON` is patched
/// process-wide), so every `*Minor` field here is MINOR UNITS.
///
/// Only [status] and the amounts are worth reading; the UI re-fetches
/// `GET /v1/admin/deposits/{id}` after every mutation to refresh from the
/// stable view shape. Parsing is deliberately TOLERANT: a shape surprise here
/// must never make a server-side success look like a client failure.
class DepositRequestRaw {
  const DepositRequestRaw({
    required this.id,
    required this.shortId,
    required this.status,
    required this.currencyCode,
    this.claimedAmount,
    this.verifiedAmount,
    this.fee,
    this.creditedAmount,
    this.rejectionCode,
    this.rejectionNote,
    this.decidedAt,
    this.reviewStartedAt,
    this.secondApprovedAt,
    this.creditedAt,
    this.decidedByAdminId,
    this.secondApproverAdminId,
    this.creditKeyEpoch,
    this.creditAttempts,
  });

  factory DepositRequestRaw.fromJson(Map<String, Object?> json) {
    final String currency =
        (Json.stringOrNull(json, 'currencyCode') ?? Money.defaultCurrency)
            .trim()
            .toUpperCase();
    return DepositRequestRaw(
      id: Json.stringOrNull(json, 'id') ?? '',
      shortId: Json.stringOrNull(json, 'shortId') ?? '',
      status: DepositStatus.tryParse(Json.stringOrNull(json, 'status')),
      currencyCode: currency,
      claimedAmount: Money.fromMinorStringOrNull(
        json['claimedAmountMinor'],
        currency: currency,
      ),
      verifiedAmount: Money.fromMinorStringOrNull(
        json['verifiedAmountMinor'],
        currency: currency,
      ),
      fee: Money.fromMinorStringOrNull(json['feeMinor'], currency: currency),
      creditedAmount: Money.fromMinorStringOrNull(
        json['creditedAmountMinor'],
        currency: currency,
      ),
      rejectionCode: Json.stringOrNull(json, 'rejectionCode'),
      rejectionNote: Json.stringOrNull(json, 'rejectionNote'),
      decidedAt: Json.dateTimeOrNull(json, 'decidedAt'),
      reviewStartedAt: Json.dateTimeOrNull(json, 'reviewStartedAt'),
      secondApprovedAt: Json.dateTimeOrNull(json, 'secondApprovedAt'),
      creditedAt: Json.dateTimeOrNull(json, 'creditedAt'),
      decidedByAdminId: Json.stringOrNull(json, 'decidedByAdminId'),
      secondApproverAdminId: Json.stringOrNull(json, 'secondApproverAdminId'),
      creditKeyEpoch: Json.intOrNull(json, 'creditKeyEpoch'),
      creditAttempts: Json.intOrNull(json, 'creditAttempts'),
    );
  }

  final String id;
  final String shortId;

  /// Null only when the backend sent a status this build does not know.
  final DepositStatus? status;

  final String currencyCode;
  final Money? claimedAmount;
  final Money? verifiedAmount;
  final Money? fee;
  final Money? creditedAmount;
  final String? rejectionCode;
  final String? rejectionNote;
  final DateTime? decidedAt;
  final DateTime? reviewStartedAt;
  final DateTime? secondApprovedAt;
  final DateTime? creditedAt;
  final String? decidedByAdminId;
  final String? secondApproverAdminId;
  final int? creditKeyEpoch;
  final int? creditAttempts;
}

/// Body of claim / release / approve / reject: a discriminated union on `kind`.
///
/// ALL variants are HTTP 200. `alreadyHandled` is a SUCCESS, not an error - it
/// means another admin, a worker or the cron got there first, and the correct
/// response is to refresh the row, never to show a failure.
///
/// The other keys DIFFER PER VARIANT, so this is a sealed hierarchy rather than
/// one class with a nullable `deposit`: reading `deposit` on `alreadyHandled`
/// is a bug the type system now prevents.
sealed class ReviewOutcome {
  const ReviewOutcome();

  /// Maps `kind` onto a variant. An unrecognised kind becomes [ReviewUnknown]
  /// rather than throwing, so a new server variant cannot crash a review.
  factory ReviewOutcome.fromJson(Map<String, Object?> json) {
    final String kind = (Json.stringOrNull(json, 'kind') ?? '').trim();
    switch (kind) {
      case 'approved':
        return ReviewApproved(
          deposit: _deposit(json),
          ledgerTransactionId: Json.stringOrNull(json, 'ledgerTransactionId'),
        );
      case 'awaiting_second_approval':
        return ReviewAwaitingSecondApproval(deposit: _deposit(json));
      case 'rejected':
        return ReviewRejected(deposit: _deposit(json));
      case 'claimed':
        return ReviewClaimed(deposit: _deposit(json));
      case 'released':
        return ReviewReleased(deposit: _deposit(json));
      case 'alreadyHandled':
        return ReviewAlreadyHandled(
          status: DepositStatus.tryParse(Json.stringOrNull(json, 'status')),
        );
      default:
        return ReviewUnknown(kind: kind);
    }
  }

  static DepositRequestRaw? _deposit(Map<String, Object?> json) {
    final Object? raw = json['deposit'];
    if (raw == null) {
      return null;
    }
    return DepositRequestRaw.fromJson(Json.asObject(raw, path: 'deposit'));
  }

  /// The status the row holds after this outcome, when the server said so.
  DepositStatus? get resultingStatus => switch (this) {
        ReviewApproved(deposit: final DepositRequestRaw? d) => d?.status,
        ReviewAwaitingSecondApproval(deposit: final DepositRequestRaw? d) =>
          d?.status,
        ReviewRejected(deposit: final DepositRequestRaw? d) => d?.status,
        ReviewClaimed(deposit: final DepositRequestRaw? d) => d?.status,
        ReviewReleased(deposit: final DepositRequestRaw? d) => d?.status,
        ReviewAlreadyHandled(status: final DepositStatus? s) => s,
        ReviewUnknown() => null,
      };

  /// True when nothing changed because somebody else already decided.
  bool get isAlreadyHandled => this is ReviewAlreadyHandled;
}

/// Money committed: ledger T1 posted and the credit job enqueued in the same
/// transaction. The deposit moves to CREDITING/CREDITED asynchronously.
final class ReviewApproved extends ReviewOutcome {
  const ReviewApproved({this.deposit, this.ledgerTransactionId});

  final DepositRequestRaw? deposit;

  /// uuid of the posted ledger transaction.
  final String? ledgerTransactionId;
}

/// First of two approvals. Status is now PENDING_SECOND_APPROVAL, the verified
/// amount is already written so the second approver sees the number, and
/// NOTHING was posted to the ledger.
final class ReviewAwaitingSecondApproval extends ReviewOutcome {
  const ReviewAwaitingSecondApproval({this.deposit});

  final DepositRequestRaw? deposit;
}

final class ReviewRejected extends ReviewOutcome {
  const ReviewRejected({this.deposit});

  final DepositRequestRaw? deposit;
}

final class ReviewClaimed extends ReviewOutcome {
  const ReviewClaimed({this.deposit});

  final DepositRequestRaw? deposit;
}

final class ReviewReleased extends ReviewOutcome {
  const ReviewReleased({this.deposit});

  final DepositRequestRaw? deposit;
}

/// Somebody else decided first. There is NO `deposit` key on this variant.
final class ReviewAlreadyHandled extends ReviewOutcome {
  const ReviewAlreadyHandled({this.status});

  /// The status the row actually holds now, or null when the row is gone.
  final DepositStatus? status;
}

/// A `kind` this build does not know. Treated as "refresh and look again".
final class ReviewUnknown extends ReviewOutcome {
  const ReviewUnknown({required this.kind});

  final String kind;
}
