import 'package:manager_bot/core/api/json.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/money/money.dart';
import 'package:manager_bot/core/theme/app_theme.dart';
import 'package:manager_bot/features/payment_methods/data/payment_enums.dart';

/// One row of `GET /v1/admin/payment-methods`.
///
/// MONEY WARNING: `minAmount`, `maxAmount` and `feeFixed` arrive as BARE
/// DECIMAL STRINGS IN MAJOR UNITS (`"50.00"`), with the currency in the sibling
/// `currencyCode` field - NOT as a `MoneyView` object and NOT in minor units.
/// They are parsed with [Money.fromDecimalString] and stay exact BigInt minor
/// units from here on; formatting happens only in a widget.
///
/// `feeBps`, `sortOrder` and `priority` are ordinary 32-bit JSON integers and
/// are the only numbers on this surface that may be read as Dart `int`.
class AdminPaymentMethodView {
  const AdminPaymentMethodView({
    required this.id,
    required this.code,
    required this.displayName,
    required this.rail,
    required this.currencyCode,
    required this.verificationMode,
    required this.minAmount,
    required this.maxAmount,
    required this.feeFixed,
    required this.feeBps,
    required this.requiresReference,
    required this.requiredProofFields,
    required this.isActive,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    this.instructions,
    this.referencePattern,
  });

  /// Hand-written parser: no codegen anywhere in this project.
  ///
  /// Unknown enum members fall back rather than throwing, because a backend
  /// that adds a rail must not brick the configuration screen. An unknown rail
  /// lands on [PaymentRail.internal], which the UI already renders as
  /// "no driver / not usable by players" - the safe reading.
  factory AdminPaymentMethodView.fromJson(Map<String, Object?> json) {
    final String currencyCode =
        Json.string(json, 'currencyCode').trim().toUpperCase();
    return AdminPaymentMethodView(
      id: Json.string(json, 'id'),
      code: Json.string(json, 'code'),
      displayName: Json.string(json, 'displayName'),
      rail: Json.enumValue(
        json,
        'rail',
        PaymentRail.byWireName,
        orElse: PaymentRail.internal,
      ),
      currencyCode: currencyCode,
      verificationMode: Json.enumValue(
        json,
        'verificationMode',
        VerificationMode.byWireName,
        orElse: VerificationMode.manualProof,
      ),
      minAmount: Money.fromDecimalString(
        Json.string(json, 'minAmount'),
        currency: currencyCode,
      ),
      maxAmount: Money.fromDecimalString(
        Json.string(json, 'maxAmount'),
        currency: currencyCode,
      ),
      feeFixed: Money.fromDecimalString(
        Json.string(json, 'feeFixed'),
        currency: currencyCode,
      ),
      feeBps: Json.integer(json, 'feeBps', orElse: 0),
      requiresReference: Json.boolean(json, 'requiresReference', orElse: false),
      instructions: Json.stringOrNull(json, 'instructions'),
      requiredProofFields: Json.stringList(json, 'requiredProofFields'),
      isActive: Json.boolean(json, 'isActive', orElse: true),
      sortOrder: Json.integer(json, 'sortOrder', orElse: 0),
      referencePattern: Json.stringOrNull(json, 'referencePattern'),
      createdAt: Json.dateTime(json, 'createdAt'),
      updatedAt: Json.dateTime(json, 'updatedAt'),
    );
  }

  /// UUID. Never an integer.
  final String id;

  /// SCREAMING_SNAKE machine code. IMMUTABLE after creation.
  final String code;

  final String displayName;

  /// IMMUTABLE after creation.
  final PaymentRail rail;

  /// IMMUTABLE after creation. Three uppercase letters; `NSP` in practice.
  final String currencyCode;

  final VerificationMode verificationMode;

  /// Smallest deposit the method accepts. Always > 0 server-side.
  final Money minAmount;

  final Money maxAmount;

  /// Flat part of the fee. Always < [minAmount] server-side, so the smallest
  /// allowed deposit still credits something.
  final Money feeFixed;

  /// Proportional part of the fee in basis points, 0..10000 (10000 == 100%).
  final int feeBps;

  /// Operator toggle. See [referenceIsMandatory]: on rails whose driver already
  /// demands a reference this flag CANNOT make it optional.
  final bool requiresReference;

  /// Free text (minimal Telegram-safe HTML) shown to the player.
  final String? instructions;

  /// Read-only, derived from the rail driver. EMPTY means the rail has no
  /// driver at all, which only ever happens on the admin list.
  final List<String> requiredProofFields;

  final bool isActive;

  /// Ascending; may be negative. Ties break on `displayName` server-side.
  final int sortOrder;

  /// Raw JS regex SOURCE (no `/.../`, no flags) run against player-typed
  /// references. The backend does NOT check that it compiles.
  final String? referencePattern;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Tone for a [StatusChip]-style badge.
  StatusTone get tone {
    if (!isActive) {
      return StatusTone.neutral;
    }
    return railHasNoDriver ? StatusTone.failed : StatusTone.approve;
  }

  /// GENDERED IN ARABIC: a payment METHOD is مفعّلة/معطّلة. Do not reuse the
  /// destination (`pdStatus*`) or administrator (`auStatus*`) pair here.
  String statusLabel(AppStrings s) =>
      isActive ? s.pmStatusActive : s.pmStatusDisabled;

  /// True when the API reported an empty `requiredProofFields`, i.e. no rail
  /// driver exists. Players can never deposit on such a method.
  bool get railHasNoDriver => requiredProofFields.isEmpty;

  /// [requiredProofFields] as known enum members, unknown strings dropped. Use
  /// [requiredProofFields] itself when rendering, so a new backend field is
  /// still shown.
  List<RailProofField> get proofFields => List<RailProofField>.unmodifiable(
        requiredProofFields
            .map(RailProofField.tryParse)
            .whereType<RailProofField>(),
      );

  /// True when the rail's own driver already lists `REFERENCE`.
  ///
  /// In that case toggling [requiresReference] off changes NOTHING: the backend
  /// demands a reference at submit time if EITHER source asks for one.
  bool get railDemandsReference =>
      requiredProofFields.contains(RailProofField.reference.wireName);

  /// The answer the player actually experiences.
  bool get referenceIsMandatory => requiresReference || railDemandsReference;

  /// True when flipping [requiresReference] cannot change the player's
  /// experience, so the form must say so instead of pretending it is a switch.
  bool get requiresReferenceToggleIsMoot => railDemandsReference;

  /// Proof fields the backend declares but CANNOT check (`SENDER_NAME`,
  /// `TX_HASH`, `NETWORK`). A reviewer has to eyeball these by hand.
  List<String> get unenforceableProofFields => List<String>.unmodifiable(
        requiredProofFields.where(
          (String field) => !RailProofField.isMachineEnforced(field),
        ),
      );

  bool get hasReferencePattern {
    final String? pattern = referencePattern;
    return pattern != null && pattern.trim().isNotEmpty;
  }

  /// Non-null when [referencePattern] does not compile as a Dart regex.
  ///
  /// The backend silently treats an uncompilable pattern as "no pattern", so
  /// nothing on the server will ever tell the operator. Dart's regex engine is
  /// not identical to V8's, so this is reported as a warning, not an error.
  String? get referencePatternCompileError {
    final String? pattern = referencePattern;
    if (pattern == null || pattern.trim().isEmpty) {
      return null;
    }
    try {
      RegExp(pattern);
      return null;
    } on FormatException catch (e) {
      return e.message;
    }
  }

  /// Total fee for [amount]: `feeFixed + feeBps/10000 * amount`, rounded
  /// HALF_UP, entirely in BigInt minor units. No `double` is involved.
  Money feeFor(Money amount) =>
      computeFee(amount: amount, feeFixed: feeFixed, feeBps: feeBps);

  /// The fee formula on its own, so an unsaved form can preview exactly what a
  /// saved method would charge without inventing a second implementation.
  ///
  /// Rounding is HALF_UP on the MAGNITUDE, matching the backend, and the sign
  /// is restored afterwards - amounts here are positive in practice, but a
  /// negative one must not silently round the wrong way.
  static Money computeFee({
    required Money amount,
    required Money feeFixed,
    required int feeBps,
  }) {
    final BigInt divisor = BigInt.from(10000);
    final BigInt product = amount.minor * BigInt.from(feeBps);
    final bool negative = product.isNegative;
    final BigInt magnitude = negative ? -product : product;
    BigInt quotient = magnitude ~/ divisor;
    final BigInt remainder = magnitude.remainder(divisor);
    if (remainder * BigInt.two >= divisor) {
      quotient += BigInt.one;
    }
    final BigInt variable = negative ? -quotient : quotient;
    return feeFixed +
        Money.fromMinor(
          variable,
          currency: feeFixed.currency,
          scale: feeFixed.scale,
        );
  }

  /// What a player depositing exactly [minAmount] would be credited. Zero or
  /// less means the method is unusable at its own floor; the server refuses to
  /// store that, but a stale row could still show it.
  Money get creditedAtMinimum => minAmount - feeFor(minAmount);

  @override
  String toString() =>
      'AdminPaymentMethodView($code, ${rail.wireName}, '
      '${isActive ? 'active' : 'disabled'})';
}
