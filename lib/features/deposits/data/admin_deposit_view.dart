import 'package:manager_bot/core/api/json.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/money/money.dart';
import 'package:manager_bot/features/deposits/data/deposit_enums.dart';

/// Where the player was told to pay: the method plus the concrete destination
/// row, assembled server-side. Non-null on both admin routes.
class DepositDestinationView {
  const DepositDestinationView({
    required this.methodCode,
    required this.methodName,
    required this.requiresReference,
    this.instructions,
    this.label,
    this.accountIdentifier,
    this.accountHolder,
  });

  factory DepositDestinationView.fromJson(Map<String, Object?> json) =>
      DepositDestinationView(
        methodCode: Json.string(json, 'methodCode'),
        methodName: Json.string(json, 'methodName'),
        requiresReference: Json.boolean(json, 'requiresReference', orElse: false),
        instructions: Json.stringOrNull(json, 'instructions'),
        label: Json.stringOrNull(json, 'label'),
        accountIdentifier: Json.stringOrNull(json, 'accountIdentifier'),
        accountHolder: Json.stringOrNull(json, 'accountHolder'),
      );

  /// Stable machine code, e.g. `SYRIATEL_CASH`.
  final String methodCode;
  final String methodName;

  /// True when the method demands an external reference from the player.
  final bool requiresReference;

  final String? instructions;

  /// `PaymentDestination.label`; null when the deposit has no destination row.
  final String? label;
  final String? accountIdentifier;
  final String? accountHolder;
}

/// One proof image. Deliberately carries NO url - the bytes come from the
/// two-step `/proofs/{proofId}/url` + `/content` flow.
class DepositProofView {
  const DepositProofView({
    required this.id,
    required this.source,
    required this.mimeType,
    required this.sizeBytes,
    required this.sha256,
    required this.createdAt,
    this.width,
    this.height,
  });

  factory DepositProofView.fromJson(Map<String, Object?> json) =>
      DepositProofView(
        id: Json.string(json, 'id'),
        source: Json.stringOrNull(json, 'source') ?? '',
        mimeType: Json.stringOrNull(json, 'mimeType') ?? '',
        sizeBytes: Json.integer(json, 'sizeBytes', orElse: 0),
        sha256: Json.stringOrNull(json, 'sha256') ?? '',
        createdAt: Json.dateTime(json, 'createdAt'),
        width: Json.intOrNull(json, 'width'),
        height: Json.intOrNull(json, 'height'),
      );

  /// Pass as `{proofId}` to the two proof routes.
  final String id;

  /// `ProofSource` value space, widened to string on the wire.
  final String source;

  /// The REAL stored content type - use this to decide how to render, not the
  /// hard-coded `.jpg` in the Content-Disposition header.
  final String mimeType;

  final int sizeBytes;

  /// 64 lowercase hex chars.
  final String sha256;

  final DateTime createdAt;
  final int? width;
  final int? height;

  String sourceLabel(AppStrings s) => ProofSource.labelFor(source, s);

  /// Short fingerprint for a caption; the full hash is far too long to show.
  String get shortHash =>
      sha256.length <= 12 ? sha256 : sha256.substring(0, 12);

  bool get looksRenderable => mimeType.toLowerCase().startsWith('image/');

  /// Digits stay Western in both languages, exactly like money.
  String sizeLabel(AppStrings s) {
    if (sizeBytes < 1024) {
      return s.sizeBytes(count: sizeBytes);
    }
    if (sizeBytes < 1024 * 1024) {
      return s.sizeKilobytes(count: (sizeBytes / 1024).round());
    }
    final double megabytes = sizeBytes / (1024 * 1024);
    return s.sizeMegabytes(value: megabytes.toStringAsFixed(1));
  }

  /// `1280 x 720`, or null when the dimensions were never extracted.
  String? dimensionLabel(AppStrings s) {
    final int? w = width;
    final int? h = height;
    if (w == null || h == null) {
      return null;
    }
    return s.dimensionLabel(width: w, height: h);
  }
}

/// A row of `GET /v1/admin/deposits` and the whole body of
/// `GET /v1/admin/deposits/{id}` - the same shape on both routes.
///
/// Money arrives as `MoneyView` objects (`{minor, amount, currency}`) and is
/// parsed to exact [Money]; `playerTelegramUserId` is a 64-bit decimal STRING
/// and is parsed to [BigInt]. Neither ever touches a double.
class AdminDepositView {
  const AdminDepositView({
    required this.id,
    required this.shortId,
    required this.status,
    required this.playerId,
    required this.paymentMethodId,
    required this.claimed,
    required this.fee,
    required this.proofCount,
    required this.createdAt,
    required this.riskFlags,
    required this.requiresSecondApproval,
    required this.creditAttempts,
    required this.creditKeyEpoch,
    required this.proofs,
    this.verified,
    this.credited,
    this.playerTelegramUserId,
    this.playerTelegramUsername,
    this.externalReference,
    this.senderAccount,
    this.expiresAt,
    this.submittedAt,
    this.reviewStartedAt,
    this.decidedAt,
    this.creditedAt,
    this.decidedByAdminId,
    this.secondApproverAdminId,
    this.creditVerifiedBy,
    this.rejectionCode,
    this.rejectionNote,
    this.destination,
  });

  factory AdminDepositView.fromJson(Map<String, Object?> json) {
    final Object? rawProofs = json['proofs'];
    return AdminDepositView(
      id: Json.string(json, 'id'),
      shortId: Json.string(json, 'shortId'),
      status: Json.enumValue<DepositStatus>(
        json,
        'status',
        DepositStatus.byWireName,
        orElse: DepositStatus.submitted,
      ),
      playerId: Json.string(json, 'playerId'),
      paymentMethodId: Json.string(json, 'paymentMethodId'),
      claimed: Money.fromMoneyView(Json.object(json, 'claimed')),
      fee: Money.fromMoneyView(Json.object(json, 'fee')),
      verified: Money.fromMoneyViewOrNull(json['verified']),
      credited: Money.fromMoneyViewOrNull(json['credited']),
      proofCount: Json.integer(json, 'proofCount', orElse: 0),
      createdAt: Json.dateTime(json, 'createdAt'),
      riskFlags: RiskFlags.sorted(Json.stringList(json, 'riskFlags')),
      requiresSecondApproval:
          Json.boolean(json, 'requiresSecondApproval', orElse: false),
      creditAttempts: Json.integer(json, 'creditAttempts', orElse: 0),
      creditKeyEpoch: Json.integer(json, 'creditKeyEpoch', orElse: 0),
      proofs: rawProofs == null
          ? const <DepositProofView>[]
          : Json.list<DepositProofView>(
              rawProofs,
              DepositProofView.fromJson,
              path: 'proofs',
            ),
      // 64-bit Telegram id: decimal string on the wire, BigInt here. NEVER int.
      playerTelegramUserId: Json.bigIntOrNull(json, 'playerTelegramUserId'),
      playerTelegramUsername: Json.stringOrNull(json, 'playerTelegramUsername'),
      externalReference: Json.stringOrNull(json, 'externalReference'),
      senderAccount: Json.stringOrNull(json, 'senderAccount'),
      expiresAt: Json.dateTimeOrNull(json, 'expiresAt'),
      submittedAt: Json.dateTimeOrNull(json, 'submittedAt'),
      reviewStartedAt: Json.dateTimeOrNull(json, 'reviewStartedAt'),
      decidedAt: Json.dateTimeOrNull(json, 'decidedAt'),
      creditedAt: Json.dateTimeOrNull(json, 'creditedAt'),
      decidedByAdminId: Json.stringOrNull(json, 'decidedByAdminId'),
      secondApproverAdminId: Json.stringOrNull(json, 'secondApproverAdminId'),
      creditVerifiedBy:
          CreditVerifiedBy.tryParse(Json.stringOrNull(json, 'creditVerifiedBy')),
      rejectionCode: Json.stringOrNull(json, 'rejectionCode'),
      rejectionNote: Json.stringOrNull(json, 'rejectionNote'),
      destination: json['destination'] == null
          ? null
          : DepositDestinationView.fromJson(Json.object(json, 'destination')),
    );
  }

  /// The uuid EVERY admin route addresses this row by. Not the [shortId].
  final String id;

  /// Human-facing reference (Crockford base32, 10 chars). What the player and
  /// the Telegram card show, and the only handle the router carries.
  final String shortId;

  final DepositStatus status;
  final String playerId;
  final String paymentMethodId;

  /// What the player says they sent. Never rewritten.
  final Money claimed;

  /// Always present, may be zero.
  final Money fee;

  /// What an admin confirmed. Null until verified.
  final Money? verified;

  /// What we asked Ichancy to credit (verified - fee). Null until approval.
  final Money? credited;

  final int proofCount;
  final DateTime createdAt;

  /// Already sorted by severity. Empty NEVER means "verified clean".
  final List<String> riskFlags;

  /// Server-computed as `status == PENDING_SECOND_APPROVAL`. It does NOT
  /// predict whether YOUR next approve will need a second pair of eyes.
  final bool requiresSecondApproval;

  final int creditAttempts;
  final int creditKeyEpoch;
  final List<DepositProofView> proofs;

  /// 64-bit Telegram id. Kept as [BigInt]; never parsed to a double.
  final BigInt? playerTelegramUserId;
  final String? playerTelegramUsername;

  final String? externalReference;
  final String? senderAccount;

  final DateTime? expiresAt;
  final DateTime? submittedAt;

  /// Non-null == somebody holds the 10-minute soft claim.
  final DateTime? reviewStartedAt;

  final DateTime? decidedAt;
  final DateTime? creditedAt;

  /// The claimer OR the first/only decider, depending on lifecycle stage.
  final String? decidedByAdminId;

  /// Set only after a genuine second approval - but see the four-eyes subtlety:
  /// a sufficiently privileged admin can finish a parked deposit alone, so a
  /// null here does NOT prove only one human touched it.
  final String? secondApproverAdminId;

  final CreditVerifiedBy? creditVerifiedBy;

  /// Value space is `RejectionCode`, widened to string on the wire.
  final String? rejectionCode;
  final String? rejectionNote;

  final DepositDestinationView? destination;

  bool get hasRiskFlags => riskFlags.isNotEmpty;

  /// The amount a reviewer should judge: verified once set, else claimed.
  Money get amountUnderReview => verified ?? claimed;

  /// What a player would receive if approved verbatim right now.
  Money get netOfFee => amountUnderReview - fee;

  /// Telegram id as a string for display/copy. Never `.toInt()`.
  String? get playerTelegramUserIdString => playerTelegramUserId?.toString();

  /// `@handle` when known, else the numeric id, else the truncated uuid.
  String get playerLabel {
    final String? username = playerTelegramUsername;
    if (username != null && username.trim().isNotEmpty) {
      return username.startsWith('@') ? username : '@$username';
    }
    final String? telegramId = playerTelegramUserIdString;
    if (telegramId != null) {
      return telegramId;
    }
    return playerId.length <= 8 ? playerId : '${playerId.substring(0, 8)}...';
  }

  /// True when [reviewStartedAt] is within the 10-minute claim TTL.
  bool claimIsFresh(DateTime now) {
    final DateTime? started = reviewStartedAt;
    if (started == null) {
      return false;
    }
    return now.difference(started) < const Duration(minutes: 10);
  }
}
