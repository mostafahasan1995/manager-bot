import 'package:manager_bot/core/api/api_client.dart';
import 'package:manager_bot/core/api/json.dart';
import 'package:manager_bot/core/config/app_config.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/money/money.dart';
import 'package:manager_bot/core/theme/app_theme.dart';

/// One VERSION of an administrator's approval ceiling.
///
/// Wire shape - `ApprovalLimitView` in
/// `src/modules/admin/dtos/approval-limit.dto.ts`:
/// ```json
/// {
///   "id": "uuid",
///   "adminUserId": "uuid",
///   "currencyCode": "NSP",
///   "maxSingleApproval": "15000.00",
///   "maxDailyApproval": "90000.00",
///   "secondApprovalAbove": "10000.00",
///   "effectiveFrom": "2026-08-01T00:00:00.000Z",
///   "effectiveTo": null,
///   "createdAt": "2026-08-01T00:00:00.000Z"
/// }
/// ```
///
/// This is the SECOND money encoding on this API: bare decimal strings in MAJOR
/// units with `currencyCode` as a sibling field, not the `MoneyView`
/// `{minor, amount, currency}` object the deposit endpoints emit. Parsed with
/// [Money.fromDecimalString] so everything downstream is BigInt minor units.
///
/// Limits are never edited in place - setting a limit closes the open version
/// and opens a new one - so a list of these is a history, newest first, and an
/// old decision stays explicable by the ceiling that was in force at the time.
class ApprovalLimitView {
  const ApprovalLimitView({
    required this.id,
    required this.adminUserId,
    required this.currencyCode,
    required this.maxSingleApproval,
    required this.maxDailyApproval,
    required this.effectiveFrom,
    required this.createdAt,
    this.secondApprovalAbove,
    this.effectiveTo,
  });

  factory ApprovalLimitView.fromJson(ApiJson json) {
    final String currencyCode = Json.string(json, 'currencyCode');
    return ApprovalLimitView(
      id: Json.string(json, 'id'),
      adminUserId: Json.string(json, 'adminUserId'),
      currencyCode: currencyCode,
      maxSingleApproval: Money.fromDecimalString(
        Json.string(json, 'maxSingleApproval'),
        currency: currencyCode,
      ),
      maxDailyApproval: Money.fromDecimalString(
        Json.string(json, 'maxDailyApproval'),
        currency: currencyCode,
      ),
      effectiveFrom: Json.dateTime(json, 'effectiveFrom'),
      createdAt: Json.dateTime(json, 'createdAt'),
      secondApprovalAbove: Money.fromDecimalStringOrNull(
        json['secondApprovalAbove'],
        currency: currencyCode,
      ),
      effectiveTo: Json.dateTimeOrNull(json, 'effectiveTo'),
    );
  }

  final String id;
  final String adminUserId;
  final String currencyCode;
  final Money maxSingleApproval;
  final Money maxDailyApproval;
  final DateTime effectiveFrom;
  final DateTime createdAt;

  /// Per-admin override of the global dual-approval threshold. Null means
  /// "inherit the global threshold" - which is a different intention from a
  /// zero override, and the server treats the two differently.
  final Money? secondApprovalAbove;

  /// Null while this version is the one in force.
  final DateTime? effectiveTo;

  /// The version currently in force. Exactly one open version may exist per
  /// (administrator, currency).
  bool get isInForce => effectiveTo == null;

  bool get inheritsGlobalThreshold => secondApprovalAbove == null;

  String statusLabel(AppStrings s) =>
      isInForce ? s.alInForceChip : s.alSupersededChip;

  StatusTone get statusTone => isInForce ? StatusTone.approve : StatusTone.neutral;

  /// Mirror of the wire shape, for round-trip tests and logging.
  ApiJson toJson() => <String, Object?>{
        'id': id,
        'adminUserId': adminUserId,
        'currencyCode': currencyCode,
        'maxSingleApproval': maxSingleApproval.toDecimalString(),
        'maxDailyApproval': maxDailyApproval.toDecimalString(),
        'secondApprovalAbove': secondApprovalAbove?.toDecimalString(),
        'effectiveFrom': effectiveFrom.toUtc().toIso8601String(),
        'effectiveTo': effectiveTo?.toUtc().toIso8601String(),
        'createdAt': createdAt.toUtc().toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApprovalLimitView &&
          other.id == id &&
          other.adminUserId == adminUserId &&
          other.currencyCode == currencyCode &&
          other.maxSingleApproval == maxSingleApproval &&
          other.maxDailyApproval == maxDailyApproval &&
          other.secondApprovalAbove == secondApprovalAbove &&
          other.effectiveFrom == effectiveFrom &&
          other.effectiveTo == effectiveTo &&
          other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        adminUserId,
        currencyCode,
        maxSingleApproval,
        maxDailyApproval,
        secondApprovalAbove,
        effectiveFrom,
        effectiveTo,
        createdAt,
      );

  @override
  String toString() => 'ApprovalLimitView($id, $currencyCode, single: '
      '${maxSingleApproval.toDecimalString()}, inForce: $isInForce)';
}

/// Why a proposed ceiling cannot be saved.
///
/// Mirrors `AdminApprovalLimitService.assertCoherent`, so the operator sees the
/// problem before a round trip. The server re-checks and always wins.
enum ApprovalLimitProblem {
  singleNotPositive,
  dailyNotPositive,
  singleAboveDaily,
  secondApprovalNegative,
  currencyMismatch;

  /// The operator-facing sentence, resolved against the active language.
  String message(AppStrings s) => switch (this) {
        ApprovalLimitProblem.singleNotPositive => s.alSingleNotPositive,
        ApprovalLimitProblem.dailyNotPositive => s.alDailyNotPositive,
        ApprovalLimitProblem.singleAboveDaily => s.alSingleAboveDaily,
        ApprovalLimitProblem.secondApprovalNegative => s.alSecondNegative,
        ApprovalLimitProblem.currencyMismatch => s.pmAmountsCurrencyMismatch,
      };
}

/// Body of `POST /v1/admin/admins/{adminUserId}/approval-limits`.
///
/// This is a POST rather than a PATCH because it does not modify a row: it
/// creates the version that applies from now and closes the previous one.
///
/// The wire field names deliberately carry no `Minor` suffix - the server takes
/// MAJOR units as decimal strings and converts. [Money.toDecimalString] emits
/// exactly that, from BigInt minor units, so no double ever exists on this path.
class SetApprovalLimitRequest {
  const SetApprovalLimitRequest({
    required this.maxSingleApproval,
    required this.maxDailyApproval,
    this.secondApprovalAbove,
  });

  final Money maxSingleApproval;
  final Money maxDailyApproval;
  final Money? secondApprovalAbove;

  /// The currency is carried by the amounts themselves; the server wants it as
  /// its own uppercase field.
  String get currencyCode => maxSingleApproval.currency.toUpperCase();

  /// Null when the configuration is coherent.
  ApprovalLimitProblem? get problem => validate(
        maxSingleApproval: maxSingleApproval,
        maxDailyApproval: maxDailyApproval,
        secondApprovalAbove: secondApprovalAbove,
      );

  ApiJson toJson() => <String, Object?>{
        'currencyCode': currencyCode,
        'maxSingleApproval': maxSingleApproval.toDecimalString(),
        'maxDailyApproval': maxDailyApproval.toDecimalString(),
        if (secondApprovalAbove != null)
          'secondApprovalAbove': secondApprovalAbove!.toDecimalString(),
      };

  /// Client-side mirror of the server's coherence rules. Pure, so it is unit
  /// tested rather than discovered in production.
  static ApprovalLimitProblem? validate({
    required Money maxSingleApproval,
    required Money maxDailyApproval,
    Money? secondApprovalAbove,
  }) {
    final String currency = maxSingleApproval.currency;
    if (maxDailyApproval.currency != currency ||
        (secondApprovalAbove != null && secondApprovalAbove.currency != currency)) {
      return ApprovalLimitProblem.currencyMismatch;
    }
    if (!maxSingleApproval.isPositive) {
      return ApprovalLimitProblem.singleNotPositive;
    }
    if (!maxDailyApproval.isPositive) {
      return ApprovalLimitProblem.dailyNotPositive;
    }
    if (maxSingleApproval > maxDailyApproval) {
      return ApprovalLimitProblem.singleAboveDaily;
    }
    if (secondApprovalAbove != null && secondApprovalAbove.isNegative) {
      return ApprovalLimitProblem.secondApprovalNegative;
    }
    return null;
  }

  /// The currency this console defaults new ceilings to.
  static String get defaultCurrency => AppConfig.defaultCurrency;

  @override
  String toString() => 'SetApprovalLimitRequest(${toJson()})';
}
