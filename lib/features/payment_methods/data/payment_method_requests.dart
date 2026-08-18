/// Request bodies for the admin payment-method surface.
///
/// THE RULE THAT SHAPES EVERY CLASS HERE: the backend runs its ValidationPipe
/// with `whitelist: true` + `forbidNonWhitelisted: true`, and every optional
/// field carries `@IsString` / `@IsBoolean` / `@IsInt`. Therefore
///
/// * an unknown or misspelled key is a 400, not a shrug;
/// * an EXPLICIT `null` for an optional field is also a 400.
///
/// So a null field here means OMIT THE KEY, never "send null". Every `toJson`
/// below builds its map with `if (x != null)` guards for exactly that reason.
///
/// Money is sent as a MAJOR-UNIT DECIMAL STRING (`"50.00"`) produced by
/// [Money.toDecimalString], which emits exactly `scale` fraction digits. The
/// server's regex allows up to 6 decimals but then parses at scale 2, so
/// anything longer would be a 400 `INVALID_AMOUNT`.
library;

import 'package:manager_bot/core/money/money.dart';
import 'package:manager_bot/features/payment_methods/data/payment_enums.dart';

/// Body of `POST /v1/admin/payment-methods`.
///
/// `code`, `rail` and `currencyCode` are set HERE and are immutable afterwards.
class CreatePaymentMethodRequest {
  const CreatePaymentMethodRequest({
    required this.code,
    required this.displayName,
    required this.rail,
    required this.currencyCode,
    required this.verificationMode,
    required this.minAmount,
    required this.maxAmount,
    this.feeFixed,
    this.feeBps,
    this.requiresReference,
    this.referencePattern,
    this.instructions,
    this.isActive,
    this.sortOrder,
  });

  /// Uppercased and trimmed by the server before validation, then matched
  /// against `^[A-Z][A-Z0-9_]{1,47}$`. Sent already normalised so the operator
  /// sees exactly what will be stored.
  final String code;
  final String displayName;
  final PaymentRail rail;

  /// Three uppercase letters, and it must exist in the `currencies` table -
  /// `NSP` is the only seeded one.
  final String currencyCode;
  final VerificationMode verificationMode;
  final Money minAmount;
  final Money maxAmount;

  /// Defaults to `0.00` server-side. Must be >= 0 and strictly < [minAmount].
  final Money? feeFixed;

  /// 0..10000 inclusive. Defaults to 0.
  final int? feeBps;

  /// Defaults to false.
  final bool? requiresReference;

  /// Raw regex SOURCE, max 256 chars. Defaults to null.
  final String? referencePattern;

  /// Max 2000 chars. Defaults to null.
  final String? instructions;

  /// Defaults to true.
  final bool? isActive;

  /// Defaults to 0. May be negative.
  final int? sortOrder;

  Map<String, Object?> toJson() => <String, Object?>{
        'code': code,
        'displayName': displayName,
        'rail': rail.wireName,
        'currencyCode': currencyCode,
        'verificationMode': verificationMode.wireName,
        'minAmount': minAmount.toDecimalString(),
        'maxAmount': maxAmount.toDecimalString(),
        if (feeFixed != null) 'feeFixed': feeFixed!.toDecimalString(),
        if (feeBps != null) 'feeBps': feeBps,
        if (requiresReference != null) 'requiresReference': requiresReference,
        if (referencePattern != null) 'referencePattern': referencePattern,
        if (instructions != null) 'instructions': instructions,
        if (isActive != null) 'isActive': isActive,
        if (sortOrder != null) 'sortOrder': sortOrder,
      };
}

/// Body of `PATCH /v1/admin/payment-methods/{id}`.
///
/// `code`, `rail` and `currencyCode` are absent BY DESIGN: sending any of them
/// is a 400 `VALIDATION_FAILED`. An empty body is legal and is a no-op update
/// that still writes an audit row.
///
/// There is NO way to clear [referencePattern] or [instructions] back to null
/// through this endpoint - null fails validation and omitting the key leaves
/// the stored value untouched. Sending `''` is the closest available action:
/// the driver treats a blank pattern as "no pattern" and blank instructions are
/// not appended.
class UpdatePaymentMethodRequest {
  const UpdatePaymentMethodRequest({
    this.displayName,
    this.verificationMode,
    this.minAmount,
    this.maxAmount,
    this.feeFixed,
    this.feeBps,
    this.requiresReference,
    this.referencePattern,
    this.instructions,
    this.isActive,
    this.sortOrder,
  });

  /// Convenience for the enable/disable buttons, which are just a PATCH.
  const UpdatePaymentMethodRequest.activation({required bool isActive})
      : this(isActive: isActive);

  final String? displayName;
  final VerificationMode? verificationMode;
  final Money? minAmount;
  final Money? maxAmount;
  final Money? feeFixed;
  final int? feeBps;
  final bool? requiresReference;
  final String? referencePattern;
  final String? instructions;
  final bool? isActive;
  final int? sortOrder;

  /// True when nothing would be sent. The API accepts `{}`, but the console
  /// should not burn an audit row on an empty save.
  bool get isEmpty => toJson().isEmpty;

  bool get isNotEmpty => !isEmpty;

  Map<String, Object?> toJson() => <String, Object?>{
        if (displayName != null) 'displayName': displayName,
        if (verificationMode != null)
          'verificationMode': verificationMode!.wireName,
        if (minAmount != null) 'minAmount': minAmount!.toDecimalString(),
        if (maxAmount != null) 'maxAmount': maxAmount!.toDecimalString(),
        if (feeFixed != null) 'feeFixed': feeFixed!.toDecimalString(),
        if (feeBps != null) 'feeBps': feeBps,
        if (requiresReference != null) 'requiresReference': requiresReference,
        if (referencePattern != null) 'referencePattern': referencePattern,
        if (instructions != null) 'instructions': instructions,
        if (isActive != null) 'isActive': isActive,
        if (sortOrder != null) 'sortOrder': sortOrder,
      };
}

/// Body of `POST /v1/admin/payment-methods/{id}/destinations`.
///
/// `paymentMethodId` comes from the PATH and must NOT be in the body.
class CreatePaymentDestinationRequest {
  const CreatePaymentDestinationRequest({
    required this.label,
    required this.accountIdentifier,
    this.accountHolder,
    this.isActive,
    this.priority,
    this.dailyCap,
    this.notes,
  });

  /// Trimmed, 1..120. On CRYPTO this is the CHAIN NAME the player reads as
  /// `Network: {label}`.
  final String label;

  /// Trimmed only - NEVER case-normalised, client side included. Immutable
  /// after creation and part of the `(paymentMethodId, accountIdentifier)`
  /// unique key, so a repeat POST is a 409, not a replay.
  final String accountIdentifier;

  /// Trimmed, max 160. Ignored by the crypto driver.
  final String? accountHolder;

  /// Defaults to true.
  final bool? isActive;

  /// >= 0, defaults to 0. LOWER IS OFFERED FIRST.
  final int? priority;

  /// Soft cap, major-unit decimal string. Omit for "no cap".
  final Money? dailyCap;

  /// Max 1000, appended verbatim to the player's instructions.
  final String? notes;

  Map<String, Object?> toJson() => <String, Object?>{
        'label': label,
        'accountIdentifier': accountIdentifier,
        if (accountHolder != null) 'accountHolder': accountHolder,
        if (isActive != null) 'isActive': isActive,
        if (priority != null) 'priority': priority,
        if (dailyCap != null) 'dailyCap': dailyCap!.toDecimalString(),
        if (notes != null) 'notes': notes,
      };
}

/// Body of `PATCH /v1/admin/payment-destinations/{id}`.
///
/// `accountIdentifier` and `paymentMethodId` are absent BY DESIGN (immutable);
/// sending either is a 400.
///
/// `dailyCap` is set-only-once-or-overwrite: null fails validation and `''`
/// fails the money regex, so a cap CANNOT be removed through this API. That is
/// a backend gap, not something to guess a payload for.
class UpdatePaymentDestinationRequest {
  const UpdatePaymentDestinationRequest({
    this.label,
    this.accountHolder,
    this.isActive,
    this.priority,
    this.dailyCap,
    this.notes,
  });

  /// Convenience for the enable/disable buttons.
  const UpdatePaymentDestinationRequest.activation({required bool isActive})
      : this(isActive: isActive);

  final String? label;
  final String? accountHolder;
  final bool? isActive;
  final int? priority;
  final Money? dailyCap;
  final String? notes;

  bool get isEmpty => toJson().isEmpty;

  bool get isNotEmpty => !isEmpty;

  Map<String, Object?> toJson() => <String, Object?>{
        if (label != null) 'label': label,
        if (accountHolder != null) 'accountHolder': accountHolder,
        if (isActive != null) 'isActive': isActive,
        if (priority != null) 'priority': priority,
        if (dailyCap != null) 'dailyCap': dailyCap!.toDecimalString(),
        if (notes != null) 'notes': notes,
      };
}
