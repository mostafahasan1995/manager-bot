/// Client-side mirrors of the server's payment-method rules.
///
/// These exist to catch a mistake BEFORE it becomes a 400, not to replace the
/// server: every rule here is enforced again in `payment-method.service.ts`,
/// and the server always wins. Each issue carries the WIRE field name so a
/// server rejection (`details.field`) and a local rejection highlight the same
/// input.
///
/// Everything in this file is pure Dart with no Flutter import, so it is unit
/// testable without a binding.
///
/// Every validator takes an [AppStrings] rather than reading one: this layer has
/// no `BuildContext`, and a caller inside a widget already holds `context.s`
/// while a controller holds `ref.read(stringsProvider)`.
library;

import 'package:manager_bot/core/auth/roles.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/money/money.dart';

/// A problem with one request field.
class FieldIssue {
  const FieldIssue(this.field, this.message);

  /// Wire field name, e.g. `minAmount`. Matches `error.details.field`.
  final String field;

  /// Sentence an operator can act on.
  final String message;

  @override
  bool operator ==(Object other) =>
      other is FieldIssue && other.field == field && other.message == message;

  @override
  int get hashCode => Object.hash(field, message);

  @override
  String toString() => 'FieldIssue($field: $message)';
}

/// Role gates for this surface, taken from `payment-method.constants.ts`.
///
/// NOTE: they are NOT the same as the core `AdminCapability.viewPaymentMethods`
/// gate. The core map allows every role to READ the admin surface (true for the
/// deposit queue), but `PAYMENT_METHOD_READER_ROLES` excludes `VIEWER`, so a
/// VIEWER gets a 403 on every route here including the GETs. The router will
/// still let a VIEWER reach the screen, which is why the screen renders its own
/// permission-denied state instead of an inevitable red error.
abstract final class PaymentMethodRoles {
  /// `PAYMENT_METHOD_READER_ROLES` - all GET routes.
  static const Set<AdminRole> readers = <AdminRole>{
    AdminRole.superAdmin,
    AdminRole.financeAdmin,
    AdminRole.reviewer,
    AdminRole.support,
  };

  /// `PAYMENT_METHOD_MANAGER_ROLES` - all POST / PATCH / DELETE routes.
  static const Set<AdminRole> managers = <AdminRole>{
    AdminRole.superAdmin,
    AdminRole.financeAdmin,
  };

  static bool canView(AdminRole? role) => AdminRoles.isAnyOf(role, readers);

  static bool canManage(AdminRole? role) => AdminRoles.isAnyOf(role, managers);
}

/// Validators shared by the method and destination forms.
abstract final class PaymentMethodRules {
  static const int displayNameMaxLength = 120;
  static const int labelMaxLength = 120;
  static const int accountIdentifierMaxLength = 256;
  static const int accountHolderMaxLength = 160;
  static const int referencePatternMaxLength = 256;
  static const int instructionsMaxLength = 2000;
  static const int notesMaxLength = 1000;
  static const int codeMaxLength = 48;
  static const int feeBpsMax = 10000;

  /// `^[A-Z][A-Z0-9_]{1,47}$`, exactly as `METHOD_CODE_PATTERN` on the server.
  static final RegExp codePattern = RegExp(r'^[A-Z][A-Z0-9_]{1,47}$');

  /// `^[A-Z]{3}$`.
  static final RegExp currencyPattern = RegExp(r'^[A-Z]{3}$');

  /// The server uppercases and trims `code` before validating, so the form
  /// shows the operator the value that will actually be stored.
  static String normalizeCode(String raw) => raw.trim().toUpperCase();

  static String normalizeCurrency(String raw) => raw.trim().toUpperCase();

  static FieldIssue? validateCode(String raw, AppStrings s) {
    final String code = normalizeCode(raw);
    if (code.isEmpty) {
      return FieldIssue('code', s.pmCodeRequired);
    }
    if (!codePattern.hasMatch(code)) {
      return FieldIssue('code', s.pmCodeMalformed);
    }
    return null;
  }

  static FieldIssue? validateCurrency(String raw, AppStrings s) {
    final String currency = normalizeCurrency(raw);
    if (!currencyPattern.hasMatch(currency)) {
      return FieldIssue('currencyCode', s.pmCurrencyInvalid);
    }
    return null;
  }

  static FieldIssue? validateDisplayName(String raw, AppStrings s) =>
      _validateText(
        'displayName',
        raw,
        s.pmDisplayNameRequired,
        displayNameMaxLength,
        s,
      );

  static FieldIssue? validateDestinationLabel(String raw, AppStrings s) =>
      _validateText('label', raw, s.pmDestLabelRequired, labelMaxLength, s);

  static FieldIssue? validateAccountIdentifier(String raw, AppStrings s) =>
      _validateText(
        'accountIdentifier',
        raw,
        s.pmAccountIdentifierRequired,
        accountIdentifierMaxLength,
        s,
      );

  static FieldIssue? validateAccountHolder(String raw, AppStrings s) {
    if (raw.trim().length > accountHolderMaxLength) {
      return FieldIssue(
        'accountHolder',
        s.pmAccountHolderTooLong(max: accountHolderMaxLength),
      );
    }
    return null;
  }

  static FieldIssue? validateNotes(String raw, AppStrings s) {
    if (raw.length > notesMaxLength) {
      return FieldIssue('notes', s.pmNotesTooLong(max: notesMaxLength));
    }
    return null;
  }

  static FieldIssue? validateInstructions(String raw, AppStrings s) {
    if (raw.length > instructionsMaxLength) {
      return FieldIssue(
        'instructions',
        s.pmInstructionsTooLong(max: instructionsMaxLength),
      );
    }
    return null;
  }

  static FieldIssue? validateFeeBps(int? feeBps, AppStrings s) {
    if (feeBps == null) {
      return null;
    }
    if (feeBps < 0 || feeBps > feeBpsMax) {
      return FieldIssue('feeBps', s.pmFeeBpsRange(max: feeBpsMax));
    }
    return null;
  }

  static FieldIssue? validatePriority(int? priority, AppStrings s) {
    if (priority == null) {
      return null;
    }
    if (priority < 0) {
      return FieldIssue('priority', s.pmPriorityNegative);
    }
    return null;
  }

  static FieldIssue? validateReferencePattern(String raw, AppStrings s) {
    if (raw.length > referencePatternMaxLength) {
      return FieldIssue(
        'referencePattern',
        s.pmPatternTooLong(max: referencePatternMaxLength),
      );
    }
    return null;
  }

  /// Compile check for a reference pattern.
  ///
  /// The backend never validates this: an uncompilable pattern is silently
  /// treated as "no pattern", and a compilable-but-wrong one silently rejects
  /// every player reference on the method. Dart's engine is not V8's, so this
  /// is reported as a WARNING and never blocks a save.
  static String? referencePatternWarning(String raw, AppStrings s) {
    final String pattern = raw.trim();
    if (pattern.isEmpty) {
      return null;
    }
    try {
      RegExp(pattern);
    } on FormatException catch (e) {
      return s.pmPatternWarning(error: e.message);
    }
    return null;
  }

  /// Tests a candidate reference against a pattern, the way the rail driver
  /// would. Returns null when the pattern is blank or uncompilable (both mean
  /// "no pattern" server-side).
  static bool? matchesReferencePattern(String pattern, String candidate) {
    final String source = pattern.trim();
    if (source.isEmpty) {
      return null;
    }
    // The driver applies a 128-character ReDoS guard BEFORE testing.
    if (candidate.length > 128) {
      return false;
    }
    try {
      return RegExp(source).hasMatch(candidate);
    } on FormatException {
      return null;
    }
  }

  /// The four coherence rules the service enforces, evaluated against the
  /// MERGED values (incoming where present, stored otherwise) exactly as the
  /// server does on a PATCH.
  ///
  /// All four surface as 400 `PAYMENT_METHOD_INVALID` with `details.field`.
  static List<FieldIssue> validateAmounts({
    required Money minAmount,
    required Money maxAmount,
    required Money feeFixed,
    required AppStrings strings,
  }) {
    final List<FieldIssue> issues = <FieldIssue>[];
    if (!minAmount.isPositive) {
      return <FieldIssue>[
        FieldIssue('minAmount', strings.pmMinNotPositive),
      ];
    }
    if (maxAmount.currency != minAmount.currency ||
        feeFixed.currency != minAmount.currency) {
      return <FieldIssue>[
        FieldIssue('currencyCode', strings.pmAmountsCurrencyMismatch),
      ];
    }
    if (maxAmount < minAmount) {
      issues.add(FieldIssue('maxAmount', strings.pmMaxBelowMin));
    }
    if (feeFixed.isNegative) {
      issues.add(FieldIssue('feeFixed', strings.pmFeeNegative));
    } else if (feeFixed >= minAmount) {
      issues.add(FieldIssue('feeFixed', strings.pmFeeNotBelowMin));
    }
    return List<FieldIssue>.unmodifiable(issues);
  }

  /// Turns a [Money] reason code into a sentence for a form field.
  ///
  /// The reason codes are the same strings the backend answers with, so the
  /// copy stays consistent whichever side rejected the value.
  static String messageForMoneyReason(String reason, AppStrings s) =>
      switch (reason) {
        'MONEY_EMPTY' => s.moneyErrorEmpty,
        'MONEY_TOO_MANY_DECIMALS' => s.moneyErrorScaleTwo,
        'MONEY_CURRENCY_MISMATCH' => s.moneyErrorOtherCurrency,
        _ => s.moneyErrorPlainAmountExample,
      };

  /// Form-field validator for a money input. Returns null when [raw] parses.
  ///
  /// [required] false lets an empty field through as "leave unchanged / omit".
  static String? validateMoneyInput(
    String raw,
    AppStrings s, {
    required bool required,
  }) {
    if (raw.trim().isEmpty) {
      return required ? s.moneyErrorEmpty : null;
    }
    final String? reason = Money.validationReason(raw);
    return reason == null ? null : messageForMoneyReason(reason, s);
  }

  /// Form-field validator for an optional 32-bit integer input.
  static String? validateIntegerInput(
    String raw,
    AppStrings s, {
    required bool required,
    int? min,
    int? max,
  }) {
    final String text = raw.trim();
    if (text.isEmpty) {
      return required ? s.pmIntegerRequired : null;
    }
    final int? value = int.tryParse(text);
    if (value == null) {
      return s.pmIntegerRequired;
    }
    if (min != null && value < min) {
      return s.pmIntegerMin(min: min);
    }
    if (max != null && value > max) {
      return s.pmIntegerMax(max: max);
    }
    return null;
  }

  /// Human label for a wire field name, used to attach a server
  /// `details.field` to the right input.
  ///
  /// An unknown field falls back to the RAW WIRE NAME - it is what the server
  /// said, and inventing prose for it would only hide the mismatch.
  static String labelForField(String field, AppStrings s) => switch (field) {
        'code' => s.pmMachineCodeLabel,
        'displayName' => s.displayNameLabel,
        'rail' => s.pmRailLabel,
        'currencyCode' => s.currencyLabel,
        'verificationMode' => s.pmVerificationModeLabel,
        'minAmount' => s.pmMinAmountLabel,
        'maxAmount' => s.pmMaxAmountLabel,
        'feeFixed' => s.pmFixedFeeLabel,
        'feeBps' => s.pmFieldLabelFeeBps,
        'requiresReference' => s.referenceRequiredLabel,
        'referencePattern' => s.pmReferencePatternRowLabel,
        'instructions' => s.instructionsLabel,
        'isActive' => s.pmStatusActive,
        'sortOrder' => s.pmSortOrderLabel,
        'label' => s.destCaptionLabel,
        'accountIdentifier' => s.accountCaptionInternal,
        'accountHolder' => s.accountHolderLabel,
        'priority' => s.pdPriorityLabel,
        'dailyCap' => s.pdDailyCapFieldLabel,
        'notes' => s.notesLabel,
        _ => field,
      };

  /// One line for an issue banner: "Minimum amount: must be greater than zero."
  static String describeIssue(FieldIssue issue, AppStrings s) =>
      s.fieldIssuePrefix(
        field: labelForField(issue.field, s),
        message: issue.message,
      );

  static FieldIssue? _validateText(
    String field,
    String raw,
    String requiredMessage,
    int maxLength,
    AppStrings s,
  ) {
    final String text = raw.trim();
    if (text.isEmpty) {
      return FieldIssue(field, requiredMessage);
    }
    if (text.length > maxLength) {
      return FieldIssue(field, s.pmKeepUnderChars(max: maxLength));
    }
    return null;
  }
}
