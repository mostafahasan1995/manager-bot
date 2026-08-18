import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/theme/app_theme.dart';

/// `DepositStatus` from schema.prisma - all 13 values, exact spelling.
///
/// Parsed with a fallback (see [byWireName] + `Json.enumValue`) so a status
/// added by a backend deploy cannot crash the queue screen.
enum DepositStatus {
  draft('DRAFT'),
  awaitingProof('AWAITING_PROOF'),
  submitted('SUBMITTED'),
  underReview('UNDER_REVIEW'),
  pendingSecondApproval('PENDING_SECOND_APPROVAL'),
  approved('APPROVED'),
  crediting('CREDITING'),
  credited('CREDITED'),
  creditFailed('CREDIT_FAILED'),
  needsReconciliation('NEEDS_RECONCILIATION'),
  rejected('REJECTED'),
  expired('EXPIRED'),
  reversed('REVERSED');

  const DepositStatus(this.wireName);

  /// SCREAMING_SNAKE value on the wire. The ONLY thing ever sent or compared.
  final String wireName;

  /// Human label in the active language. Never show [wireName] on a screen an
  /// admin reads.
  String label(AppStrings s) => switch (this) {
        DepositStatus.draft => s.statusDraft,
        DepositStatus.awaitingProof => s.statusAwaitingProof,
        DepositStatus.submitted => s.statusSubmitted,
        DepositStatus.underReview => s.statusUnderReview,
        DepositStatus.pendingSecondApproval => s.statusPendingSecondApproval,
        DepositStatus.approved => s.statusApproved,
        DepositStatus.crediting => s.statusCrediting,
        DepositStatus.credited => s.statusCredited,
        DepositStatus.creditFailed => s.statusCreditFailed,
        DepositStatus.needsReconciliation => s.statusNeedsReconciliation,
        DepositStatus.rejected => s.statusRejected,
        DepositStatus.expired => s.statusExpired,
        DepositStatus.reversed => s.statusReversed,
      };

  static final Map<String, DepositStatus> byWireName = <String, DepositStatus>{
    for (final DepositStatus status in DepositStatus.values)
      status.wireName: status,
  };

  /// Null for an unknown/absent value rather than throwing.
  static DepositStatus? tryParse(String? raw) {
    if (raw == null) {
      return null;
    }
    return byWireName[raw.trim().toUpperCase()];
  }

  /// The queue's default server-side filter, and the only statuses from which
  /// approve/reject are accepted.
  static const Set<DepositStatus> reviewable = <DepositStatus>{
    DepositStatus.submitted,
    DepositStatus.underReview,
    DepositStatus.pendingSecondApproval,
  };

  /// Nothing further can happen; no admin action on this controller is legal.
  static const Set<DepositStatus> terminal = <DepositStatus>{
    DepositStatus.rejected,
    DepositStatus.expired,
    DepositStatus.reversed,
    DepositStatus.credited,
  };

  /// Counts against the player's open-deposit budget.
  static const Set<DepositStatus> open = <DepositStatus>{
    DepositStatus.draft,
    DepositStatus.awaitingProof,
    DepositStatus.submitted,
    DepositStatus.underReview,
    DepositStatus.pendingSecondApproval,
    DepositStatus.approved,
    DepositStatus.crediting,
  };

  bool get isReviewable => reviewable.contains(this);
  bool get isTerminal => terminal.contains(this);
  bool get isOpen => open.contains(this);

  StatusTone get tone => switch (this) {
        DepositStatus.approved || DepositStatus.credited => StatusTone.approve,
        DepositStatus.rejected || DepositStatus.reversed => StatusTone.reject,
        DepositStatus.creditFailed ||
        DepositStatus.needsReconciliation =>
          StatusTone.failed,
        DepositStatus.crediting => StatusTone.info,
        DepositStatus.draft ||
        DepositStatus.awaitingProof ||
        DepositStatus.expired =>
          StatusTone.neutral,
        DepositStatus.submitted ||
        DepositStatus.underReview ||
        DepositStatus.pendingSecondApproval =>
          StatusTone.pending,
      };
}

/// `RejectionCode` - required on `POST /{id}/reject`.
enum RejectionCode {
  duplicateProof('DUPLICATE_PROOF'),
  proofUnreadable('PROOF_UNREADABLE'),
  proofMissing('PROOF_MISSING'),
  amountMismatch('AMOUNT_MISMATCH'),
  referenceNotFound('REFERENCE_NOT_FOUND'),
  wrongDestination('WRONG_DESTINATION'),
  senderMismatch('SENDER_MISMATCH'),
  suspectedFraud('SUSPECTED_FRAUD'),
  limitExceeded('LIMIT_EXCEEDED'),
  playerIneligible('PLAYER_INELIGIBLE'),
  expired('EXPIRED'),
  other('OTHER');

  const RejectionCode(this.wireName);

  final String wireName;

  /// Human label in the active language.
  String label(AppStrings s) => switch (this) {
        RejectionCode.duplicateProof => s.rejectionDuplicateProof,
        RejectionCode.proofUnreadable => s.rejectionProofUnreadable,
        RejectionCode.proofMissing => s.rejectionProofMissing,
        RejectionCode.amountMismatch => s.rejectionAmountMismatch,
        RejectionCode.referenceNotFound => s.rejectionReferenceNotFound,
        RejectionCode.wrongDestination => s.rejectionWrongDestination,
        RejectionCode.senderMismatch => s.rejectionSenderMismatch,
        RejectionCode.suspectedFraud => s.rejectionSuspectedFraud,
        RejectionCode.limitExceeded => s.rejectionLimitExceeded,
        RejectionCode.playerIneligible => s.rejectionPlayerIneligible,
        // The wire value EXPIRED means the same thing as the deposit status.
        RejectionCode.expired => s.statusExpired,
        RejectionCode.other => s.rejectionOther,
      };

  static final Map<String, RejectionCode> byWireName = <String, RejectionCode>{
    for (final RejectionCode code in RejectionCode.values) code.wireName: code,
  };

  /// The wire type is widened to `string`, so decode defensively.
  static RejectionCode? tryParse(String? raw) {
    if (raw == null) {
      return null;
    }
    return byWireName[raw.trim().toUpperCase()];
  }

  /// Label for a code that may not be in our enum yet.
  ///
  /// An unknown code falls back to the RAW wire value: manufacturing an English
  /// sentence out of it would read as English inside an Arabic screen.
  static String labelFor(String? raw, AppStrings s) {
    final RejectionCode? parsed = tryParse(raw);
    if (parsed != null) {
      return parsed.label(s);
    }
    if (raw == null || raw.trim().isEmpty) {
      return s.emptyValueDash;
    }
    return raw.trim();
  }
}

/// `ProofSource` - value space of `DepositProofView.source` (widened to string
/// on the wire, so never parsed into a closed enum for rendering).
enum ProofSource {
  playerUpload('PLAYER_UPLOAD'),
  adminUpload('ADMIN_UPLOAD'),
  telegramPhoto('TELEGRAM_PHOTO'),
  telegramDocument('TELEGRAM_DOCUMENT'),
  systemImport('SYSTEM_IMPORT');

  const ProofSource(this.wireName);

  final String wireName;

  /// Human label in the active language.
  String label(AppStrings s) => switch (this) {
        ProofSource.playerUpload => s.proofSourcePlayerUpload,
        ProofSource.adminUpload => s.proofSourceAdminUpload,
        ProofSource.telegramPhoto => s.proofSourceTelegramPhoto,
        ProofSource.telegramDocument => s.proofSourceTelegramDocument,
        ProofSource.systemImport => s.proofSourceSystemImport,
      };

  static ProofSource? tryParse(String? raw) {
    if (raw == null) {
      return null;
    }
    final String normalized = raw.trim().toUpperCase();
    for (final ProofSource source in ProofSource.values) {
      if (source.wireName == normalized) {
        return source;
      }
    }
    return null;
  }

  /// Label for a value that may not be in our enum yet; an unknown source falls
  /// back to the raw wire value rather than to invented English.
  static String labelFor(String? raw, AppStrings s) {
    final ProofSource? parsed = tryParse(raw);
    if (parsed != null) {
      return parsed.label(s);
    }
    if (raw == null || raw.trim().isEmpty) {
      return s.emptyValueDash;
    }
    return raw.trim();
  }
}

/// `CreditVerifiedBy` - how we know the player was actually credited.
enum CreditVerifiedBy {
  apiOk('API_OK'),
  balanceDelta('BALANCE_DELTA'),
  manual('MANUAL');

  const CreditVerifiedBy(this.wireName);

  final String wireName;

  /// Human label in the active language. Ichancy stays Latin in both.
  String label(AppStrings s) => switch (this) {
        CreditVerifiedBy.apiOk => s.creditVerifiedApiOk,
        CreditVerifiedBy.balanceDelta => s.creditVerifiedBalanceDelta,
        CreditVerifiedBy.manual => s.creditVerifiedManual,
      };

  static CreditVerifiedBy? tryParse(String? raw) {
    if (raw == null) {
      return null;
    }
    final String normalized = raw.trim().toUpperCase();
    for (final CreditVerifiedBy value in CreditVerifiedBy.values) {
      if (value.wireName == normalized) {
        return value;
      }
    }
    return null;
  }
}

/// Risk flags reach the client as an OPEN `string[]` (the TypeScript const is
/// not in schema.prisma), so they are ordered and labelled, never parsed.
///
/// An empty list NEVER means "verified clean": flags are read back out of the
/// newest transition metadata row and unknown values are dropped server-side.
abstract final class RiskFlags {
  /// Severity order for display, highest first.
  static const List<String> severityOrder = <String>[
    'DUPLICATE_PROOF_EXACT',
    'DUPLICATE_PROOF_SIMILAR',
    'REFERENCE_REUSED',
    'DUPLICATE_PROOF_SAME_PLAYER',
    'RAPID_RESUBMISSION',
    'LARGE_AMOUNT',
    'NEW_PLAYER',
    'PROOF_UNREADABLE',
  ];

  /// Known flags first in severity order, then anything unrecognised, so a new
  /// backend flag is still shown rather than hidden.
  static List<String> sorted(List<String> flags) {
    final List<String> ordered = <String>[];
    for (final String known in severityOrder) {
      if (flags.contains(known)) {
        ordered.add(known);
      }
    }
    for (final String flag in flags) {
      if (!ordered.contains(flag)) {
        ordered.add(flag);
      }
    }
    return List<String>.unmodifiable(ordered);
  }

  /// Severity rank: 0 is the most serious, [severityOrder].length for unknown.
  static int rankOf(String flag) {
    final int index = severityOrder.indexOf(flag);
    return index < 0 ? severityOrder.length : index;
  }

  /// Human label for a flag, falling back to the RAW wire code for anything
  /// this build does not know - a new backend flag is shown, never hidden and
  /// never dressed up as a translated sentence.
  static String label(String flag, AppStrings s) => switch (flag.trim()) {
        'DUPLICATE_PROOF_EXACT' => s.riskDuplicateProofExact,
        'DUPLICATE_PROOF_SIMILAR' => s.riskDuplicateProofSimilar,
        'REFERENCE_REUSED' => s.riskReferenceReused,
        'DUPLICATE_PROOF_SAME_PLAYER' => s.riskDuplicateProofSamePlayer,
        'RAPID_RESUBMISSION' => s.riskRapidResubmission,
        'LARGE_AMOUNT' => s.riskLargeAmount,
        'NEW_PLAYER' => s.riskNewPlayer,
        'PROOF_UNREADABLE' => s.rejectionProofUnreadable,
        _ => flag,
      };
}

/// Deposit-module `error.code` values reachable on the admin surface.
///
/// `error.code` stays an OPEN string - these are constants to compare against,
/// never a closed enum.
abstract final class DepositErrorCodes {
  static const String depositNotFound = 'DEPOSIT_NOT_FOUND';
  static const String depositInvalidState = 'DEPOSIT_INVALID_STATE';
  static const String depositClaimedByOther = 'DEPOSIT_CLAIMED_BY_OTHER';
  static const String secondApproverMustDiffer = 'SECOND_APPROVER_MUST_DIFFER';
  static const String adminLimitExceeded = 'ADMIN_LIMIT_EXCEEDED';
  static const String adminNoApprovalLimit = 'ADMIN_NO_APPROVAL_LIMIT';
  static const String verifiedAmountRequired = 'VERIFIED_AMOUNT_REQUIRED';
  static const String proofNotFound = 'PROOF_NOT_FOUND';

  /// Codes that mean "another admin or a worker got there first". These are
  /// NORMAL outcomes in a review console: refresh the row, never show red.
  static const Set<String> raceOutcomes = <String>{
    depositClaimedByOther,
  };
}
