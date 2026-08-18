/// Wire enums of the admin payment-method surface.
///
/// Every [wireName] is the EXACT, case-sensitive string the backend sends and
/// accepts (`PaymentRail`, `VerificationMode`, `RailProofField` in
/// `schema.prisma` / `rail.interface.ts`). Nothing here is generated; the maps
/// are hand-written so `flutter pub get` is the only build step.
///
/// Every HUMAN label is a METHOD taking [AppStrings], never a const field: the
/// wire names below are fixed forever, the words an operator reads are not.
library;

import 'package:manager_bot/core/i18n/app_strings.dart';

/// The transport a method settles on. Drives which proof fields the player
/// form asks for and what a destination's `label` actually means.
enum PaymentRail {
  bankTransfer('BANK_TRANSFER'),
  mobileWallet('MOBILE_WALLET'),
  cashOffice('CASH_OFFICE'),
  crypto('CRYPTO'),

  /// No driver implements it. Rows on this rail can only ever be READ through
  /// the admin list; creating one is refused with 422 `RAIL_NOT_SUPPORTED`.
  internal('INTERNAL');

  const PaymentRail(this.wireName);

  /// Value on the wire, e.g. `BANK_TRANSFER`.
  final String wireName;

  static final Map<String, PaymentRail> byWireName = <String, PaymentRail>{
    for (final PaymentRail rail in PaymentRail.values) rail.wireName: rail,
  };

  /// Rails a method can actually be CREATED on. `INTERNAL` passes DTO
  /// validation and is then refused by the service, so it never appears here.
  static const List<PaymentRail> creatable = <PaymentRail>[
    PaymentRail.bankTransfer,
    PaymentRail.mobileWallet,
    PaymentRail.cashOffice,
    PaymentRail.crypto,
  ];

  static PaymentRail? tryParse(String? raw) {
    if (raw == null) {
      return null;
    }
    return byWireName[raw.trim().toUpperCase()];
  }

  /// False only for [PaymentRail.internal]: no driver exists, so the method
  /// cannot be used by a player at all.
  bool get hasDriver => this != PaymentRail.internal;

  /// Human label for chips and dropdowns.
  String label(AppStrings s) => switch (this) {
        PaymentRail.bankTransfer => s.railBankTransfer,
        PaymentRail.mobileWallet => s.railMobileWallet,
        PaymentRail.cashOffice => s.railCashOffice,
        PaymentRail.crypto => s.railCrypto,
        PaymentRail.internal => s.railInternal,
      };

  /// The proof fields the rail DRIVER declares, in the order it declares them.
  ///
  /// This mirrors the server exactly, but it is only a fallback for previewing
  /// a rail the admin has not saved yet - a loaded method always carries the
  /// authoritative `requiredProofFields` from the API.
  List<RailProofField> get declaredProofFields => switch (this) {
        PaymentRail.bankTransfer => const <RailProofField>[
            RailProofField.reference,
            RailProofField.senderAccount,
            RailProofField.senderName,
            RailProofField.receiptImage,
          ],
        PaymentRail.mobileWallet => const <RailProofField>[
            RailProofField.reference,
            RailProofField.senderAccount,
            RailProofField.receiptImage,
          ],
        PaymentRail.cashOffice => const <RailProofField>[
            RailProofField.reference,
            RailProofField.receiptImage,
          ],
        PaymentRail.crypto => const <RailProofField>[
            RailProofField.txHash,
            RailProofField.network,
            RailProofField.senderAccount,
            RailProofField.receiptImage,
          ],
        PaymentRail.internal => const <RailProofField>[],
      };

  /// What a destination's `label` is printed as in the player's instructions.
  ///
  /// On [PaymentRail.crypto] the label IS the chain name (`Network: {label}`);
  /// getting it wrong makes funds unrecoverable, which is why the forms say so.
  String destinationLabelCaption(AppStrings s) => switch (this) {
        PaymentRail.bankTransfer => s.destCaptionBank,
        PaymentRail.mobileWallet => s.destCaptionWallet,
        PaymentRail.cashOffice => s.destCaptionOffice,
        PaymentRail.crypto => s.networkLabel,
        PaymentRail.internal => s.destCaptionLabel,
      };

  /// Hint text for the destination `label` input.
  String destinationLabelHint(AppStrings s) => switch (this) {
        PaymentRail.bankTransfer => s.destHintBank,
        PaymentRail.mobileWallet => s.destHintWallet,
        PaymentRail.cashOffice => s.destHintOffice,
        PaymentRail.crypto => s.destHintCrypto,
        PaymentRail.internal => s.destHintInternal,
      };

  /// What `accountIdentifier` means on this rail.
  String accountIdentifierCaption(AppStrings s) => switch (this) {
        PaymentRail.bankTransfer => s.accountCaptionBank,
        PaymentRail.mobileWallet => s.accountCaptionWallet,
        PaymentRail.cashOffice => s.accountCaptionOffice,
        PaymentRail.crypto => s.accountCaptionCrypto,
        PaymentRail.internal => s.accountCaptionInternal,
      };

  /// True where the driver ignores `accountHolder` (crypto prints only the
  /// address and the network).
  bool get ignoresAccountHolder => this == PaymentRail.crypto;
}

/// How a deposit on the method is verified.
///
/// v1 has no statement ingestion and `tryAutoVerify()` returns null for every
/// rail, so all four values behave identically today. It is stored metadata,
/// not behaviour - the UI says as much rather than implying automation.
enum VerificationMode {
  manualProof('MANUAL_PROOF'),
  referenceMatch('REFERENCE_MATCH'),
  autoStatement('AUTO_STATEMENT'),
  none('NONE');

  const VerificationMode(this.wireName);

  final String wireName;

  static final Map<String, VerificationMode> byWireName =
      <String, VerificationMode>{
    for (final VerificationMode mode in VerificationMode.values)
      mode.wireName: mode,
  };

  static VerificationMode? tryParse(String? raw) {
    if (raw == null) {
      return null;
    }
    return byWireName[raw.trim().toUpperCase()];
  }

  String label(AppStrings s) => switch (this) {
        VerificationMode.manualProof => s.verificationManualProof,
        VerificationMode.referenceMatch => s.verificationReferenceMatch,
        VerificationMode.autoStatement => s.verificationAutoStatement,
        VerificationMode.none => s.verificationNone,
      };
}

/// Element type of `AdminPaymentMethodView.requiredProofFields`.
///
/// The list is derived from the rail DRIVER, never from the database row, and
/// is read-only: no request field sets it.
enum RailProofField {
  reference('REFERENCE', machineEnforced: true),
  senderAccount('SENDER_ACCOUNT', machineEnforced: true),
  senderName('SENDER_NAME', machineEnforced: false),
  receiptImage('RECEIPT_IMAGE', machineEnforced: true),
  txHash('TX_HASH', machineEnforced: false),
  network('NETWORK', machineEnforced: false);

  const RailProofField(this.wireName, {required this.machineEnforced});

  final String wireName;

  /// True when the backend can actually CHECK the field at submit time.
  ///
  /// `RailSubmission` carries only a reference, a sender account and a proof
  /// count, so `SENDER_NAME`, `TX_HASH` and `NETWORK` exist purely to drive the
  /// player form and the reviewer's checklist. Nothing validates them. The
  /// admin needs to know that before trusting a crypto method.
  final bool machineEnforced;

  static final Map<String, RailProofField> byWireName =
      <String, RailProofField>{
    for (final RailProofField field in RailProofField.values)
      field.wireName: field,
  };

  static RailProofField? tryParse(String? raw) {
    if (raw == null) {
      return null;
    }
    return byWireName[raw.trim().toUpperCase()];
  }

  String label(AppStrings s) => switch (this) {
        RailProofField.reference => s.referenceLabel,
        RailProofField.senderAccount => s.senderAccountLabel,
        RailProofField.senderName => s.proofFieldSenderName,
        RailProofField.receiptImage => s.proofFieldReceiptImage,
        RailProofField.txHash => s.proofFieldTxHash,
        RailProofField.network => s.networkLabel,
      };

  /// Label for a raw wire string, tolerating a proof field this build does not
  /// know yet (the backend may add one). An unknown value falls back to the RAW
  /// WIRE CODE, which is at least searchable, rather than to invented prose.
  static String labelFor(String raw, AppStrings s) =>
      tryParse(raw)?.label(s) ?? raw;

  /// Whether a raw wire string is one of the machine-enforced fields. Unknown
  /// values are reported as NOT enforced, which is the safe direction: the UI
  /// warns rather than promising a check that may not exist.
  static bool isMachineEnforced(String raw) =>
      tryParse(raw)?.machineEnforced ?? false;
}
