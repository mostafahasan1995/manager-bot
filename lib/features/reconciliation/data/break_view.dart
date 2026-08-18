import 'package:manager_bot/core/api/json.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/money/money.dart';
import 'package:manager_bot/core/theme/app_theme.dart';
import 'package:manager_bot/features/reconciliation/data/rail_ageing_report.dart';

/// Prisma `break_status`.
///
/// [unknown] is a CLIENT sentinel for a member the backend grew after this
/// build shipped; it is never sent to the server and never offered as a filter.
enum BreakStatus {
  open('OPEN'),
  investigating('INVESTIGATING'),
  resolved('RESOLVED'),
  writtenOff('WRITTEN_OFF'),
  falsePositive('FALSE_POSITIVE'),
  unknown('UNKNOWN');

  const BreakStatus(this.wireName);

  /// The only three values `POST /breaks/:id/resolve` accepts. Sending OPEN or
  /// INVESTIGATING is a 400 carrying `CORRECTION_NOT_ALLOWED`.
  static const List<BreakStatus> terminal = <BreakStatus>[
    resolved,
    writtenOff,
    falsePositive,
  ];

  /// What the `status` query param may contain, in list order.
  static const List<BreakStatus> filterable = <BreakStatus>[
    open,
    investigating,
    resolved,
    writtenOff,
    falsePositive,
  ];

  /// What the server filters on when `status` is omitted or empty.
  static const Set<BreakStatus> serverDefaultFilter = <BreakStatus>{
    open,
    investigating,
  };

  static final Map<String, BreakStatus> byWireName = <String, BreakStatus>{
    for (final BreakStatus status in BreakStatus.values) status.wireName: status,
  };

  final String wireName;

  /// Human label, resolved from the catalogue rather than stored on the enum.
  String label(AppStrings s) => switch (this) {
        BreakStatus.open => s.breakStatusOpen,
        BreakStatus.investigating => s.breakStatusInvestigating,
        BreakStatus.resolved => s.breakStatusResolved,
        BreakStatus.writtenOff => s.breakStatusWrittenOff,
        BreakStatus.falsePositive => s.breakStatusFalsePositive,
        BreakStatus.unknown => s.breakStatusUnknown,
      };

  /// Closed. No further action is possible (and assign must be hidden).
  bool get isTerminal =>
      this == resolved || this == writtenOff || this == falsePositive;

  /// Still work for a human.
  bool get isOpenWork => this == open || this == investigating;

  StatusTone get tone => switch (this) {
        BreakStatus.open => StatusTone.failed,
        BreakStatus.investigating => StatusTone.pending,
        BreakStatus.resolved => StatusTone.approve,
        BreakStatus.writtenOff => StatusTone.reject,
        BreakStatus.falsePositive => StatusTone.neutral,
        BreakStatus.unknown => StatusTone.neutral,
      };

  /// One line explaining what closing a break with this status MEANS. Shown in
  /// the confirmation sheet, because the three are not interchangeable.
  String closingMeaning(AppStrings s) => switch (this) {
        BreakStatus.resolved => s.closingMeaningResolved,
        BreakStatus.writtenOff => s.closingMeaningWrittenOff,
        BreakStatus.falsePositive => s.closingMeaningFalsePositive,
        BreakStatus.open ||
        BreakStatus.investigating ||
        BreakStatus.unknown =>
          s.closingMeaningNotClosing,
      };

  static BreakStatus? tryParse(String? raw) {
    if (raw == null) {
      return null;
    }
    return byWireName[raw.trim().toUpperCase()];
  }
}

/// Prisma `break_category`.
enum BreakCategory {
  agentFloatMismatch('AGENT_FLOAT_MISMATCH', true),
  playerBalanceMismatch('PLAYER_BALANCE_MISMATCH', false),
  missingCredit('MISSING_CREDIT', false),
  duplicateCredit('DUPLICATE_CREDIT', false),
  unidentifiedReceipt('UNIDENTIFIED_RECEIPT', true),
  ledgerImbalance('LEDGER_IMBALANCE', true),
  orphanIchancyCall('ORPHAN_ICHANCY_CALL', false),
  stuckDeposit('STUCK_DEPOSIT', false),
  unknown('UNKNOWN', false);

  const BreakCategory(this.wireName, this.hasDetector);

  /// Filterable members, in list order. Detector-backed ones first so the
  /// categories that can actually appear are the easy taps.
  static const List<BreakCategory> filterable = <BreakCategory>[
    agentFloatMismatch,
    unidentifiedReceipt,
    ledgerImbalance,
    playerBalanceMismatch,
    missingCredit,
    duplicateCredit,
    orphanIchancyCall,
    stuckDeposit,
  ];

  static final Map<String, BreakCategory> byWireName = <String, BreakCategory>{
    for (final BreakCategory category in BreakCategory.values)
      category.wireName: category,
  };

  final String wireName;

  /// True when a detector in the backend actually writes this category today.
  /// The other five exist in the enum but are never produced.
  final bool hasDetector;

  /// Human label, resolved from the catalogue.
  String label(AppStrings s) => switch (this) {
        BreakCategory.agentFloatMismatch => s.breakCategoryAgentFloatMismatch,
        BreakCategory.playerBalanceMismatch =>
          s.breakCategoryPlayerBalanceMismatch,
        BreakCategory.missingCredit => s.breakCategoryMissingCredit,
        BreakCategory.duplicateCredit => s.breakCategoryDuplicateCredit,
        BreakCategory.unidentifiedReceipt => s.breakCategoryUnidentifiedReceipt,
        BreakCategory.ledgerImbalance => s.breakCategoryLedgerImbalance,
        BreakCategory.orphanIchancyCall => s.breakCategoryOrphanIchancyCall,
        BreakCategory.stuckDeposit => s.breakCategoryStuckDeposit,
        BreakCategory.unknown => s.breakCategoryUnknown,
      };

  /// Only an `AGENT_FLOAT_MISMATCH` may be closed with a ledger correction.
  bool get supportsFloatCorrection => this == agentFloatMismatch;

  static BreakCategory? tryParse(String? raw) {
    if (raw == null) {
      return null;
    }
    return byWireName[raw.trim().toUpperCase()];
  }
}

/// Break severity is a plain integer 1..5, not an enum. 1 is informational,
/// 5 means money is missing right now.
abstract final class BreakSeverity {
  static const int min = 1;
  static const int max = 5;

  static int clamp(int value) {
    if (value < min) {
      return min;
    }
    return value > max ? max : value;
  }

  static String label(int severity, AppStrings s) => switch (clamp(severity)) {
        1 => s.severity1,
        2 => s.severity2,
        3 => s.severity3,
        4 => s.severity4,
        _ => s.severity5,
      };

  /// `S1`..`S5` - Latin in both locales.
  static String shortLabel(int severity, AppStrings s) =>
      s.severityShort(n: clamp(severity));

  static StatusTone tone(int severity) => switch (clamp(severity)) {
        1 => StatusTone.neutral,
        2 => StatusTone.info,
        3 => StatusTone.pending,
        4 => StatusTone.failed,
        _ => StatusTone.reject,
      };
}

/// One rendered row of a break's free-form `detail` blob.
class BreakDetailEntry {
  const BreakDetailEntry({
    required this.key,
    required this.label,
    required this.value,
    required this.isMoney,
  });

  final String key;

  /// `ichancyAvailableMinor` -> `Ichancy available`.
  final String label;

  /// Already rendered for display. Money keys are formatted at scale 2.
  final String value;

  /// True when [value] came from a `*Minor` money field.
  final bool isMoney;
}

/// `BreakView.detail` - a free-form Prisma `Json` column.
///
/// Nothing validates this server-side and each detector writes its own shape,
/// so every read is null-safe and no key is ever assumed to exist. The three
/// shapes seen today:
///
/// * `AGENT_FLOAT_MISMATCH` - ledgerMinor, ichancyAvailableMinor,
///   ichancyBalanceMinor, deltaMinor, hint
/// * `UNIDENTIFIED_RECEIPT` - accountCode, oldestUnsettledAt, buckets, hint
/// * `LEDGER_IMBALANCE`     - invariant, subject, message, truncated
class BreakDetail {
  const BreakDetail(this.raw);

  /// Accepts the whole `detail` value, which may legally be an object, an
  /// array, a scalar or null. Anything that is not an object becomes empty.
  factory BreakDetail.fromJson(Object? value) {
    if (value is Map<Object?, Object?>) {
      return BreakDetail(Json.asObject(value, path: 'detail'));
    }
    return empty;
  }

  static const BreakDetail empty = BreakDetail(<String, Object?>{});

  final Map<String, Object?> raw;

  bool get isEmpty => raw.isEmpty;
  bool get isNotEmpty => raw.isNotEmpty;

  String? string(String key) {
    final Object? value = raw[key];
    return value is String ? value : null;
  }

  /// A `*Minor` field of the blob as exact money.
  Money? money(String key, {String currency = Money.defaultCurrency}) =>
      Money.fromMinorStringOrNull(raw[key], currency: currency);

  /// `LEDGER_IMBALANCE` only: which invariant fired.
  String? get invariant => string('invariant');

  /// `LEDGER_IMBALANCE` only: the transaction / account / currency it is about.
  String? get subject => string('subject');

  /// A pre-formatted English sentence written by the detector. Safe verbatim.
  String? get message => string('message');

  /// Operator guidance written by the detector.
  String? get hint => string('hint');

  /// `UNIDENTIFIED_RECEIPT` only: the rail clearing account code.
  String? get accountCode => string('accountCode');

  /// `UNIDENTIFIED_RECEIPT` only: the ageing buckets as of detection.
  List<RailAgeingBucket> buckets({String currency = Money.defaultCurrency}) {
    final Object? value = raw['buckets'];
    if (value is! List<Object?>) {
      return const <RailAgeingBucket>[];
    }
    return List<RailAgeingBucket>.unmodifiable(<RailAgeingBucket>[
      for (final Object? bucket in value)
        if (bucket is Map<Object?, Object?>)
          RailAgeingBucket.fromJson(
            Json.asObject(bucket, path: 'detail.buckets[]'),
            currencyCode: currency,
          ),
    ]);
  }

  /// Every key/value of the blob, ready for a two-column evidence table.
  List<BreakDetailEntry> entries(
    AppStrings s, {
    String currency = Money.defaultCurrency,
  }) {
    final List<BreakDetailEntry> result = <BreakDetailEntry>[];
    for (final MapEntry<String, Object?> entry in raw.entries) {
      final bool isMoney = entry.key.endsWith('Minor');
      final Money? asMoney =
          isMoney ? Money.fromMinorStringOrNull(entry.value, currency: currency) : null;
      result.add(
        BreakDetailEntry(
          key: entry.key,
          label: labelForKey(entry.key, s),
          value: asMoney != null ? asMoney.format() : stringify(entry.value, s),
          isMoney: asMoney != null,
        ),
      );
    }
    return List<BreakDetailEntry>.unmodifiable(result);
  }

  /// `ichancyAvailableMinor` -> the catalogue's `Ichancy available`.
  ///
  /// A detector key this build has never seen falls back to the RAW key rather
  /// than to a machine-built English phrase: an untranslated wire code is
  /// honest, a fabricated sentence is not.
  static String labelForKey(String key, AppStrings s) {
    final String trimmed =
        key.endsWith('Minor') ? key.substring(0, key.length - 5) : key;
    return switch (trimmed) {
      'ichancyAvailable' => s.evidenceIchancyAvailable,
      'ichancyBalance' => s.evidenceIchancyBalance,
      'ledger' => s.evidenceLedger,
      'delta' => s.evidenceDelta,
      'accountCode' => s.evidenceAccountCode,
      'oldestUnsettledAt' => s.evidenceOldestUnsettledAt,
      'subject' => s.evidenceSubject,
      'truncated' => s.evidenceTruncated,
      'invariant' => s.evidenceInvariant,
      _ => key,
    };
  }

  /// Renders any JSON value as one short line, without ever calling a method on
  /// a `dynamic`.
  static String stringify(Object? value, AppStrings s) {
    if (value == null) {
      return s.emptyValueDash;
    }
    if (value is String) {
      return value.isEmpty ? s.emptyValueDash : value;
    }
    if (value is bool) {
      return value ? s.yes : s.no;
    }
    if (value is num) {
      return value.toString();
    }
    if (value is List<Object?>) {
      return s.detailValueItems(count: value.length);
    }
    if (value is Map<Object?, Object?>) {
      return s.detailValueFields(count: value.length);
    }
    return value.toString();
  }
}

/// `BreakView` - the payload of `GET /breaks`, `GET /breaks/:id`,
/// `POST /breaks/:id/resolve` and `POST /breaks/:id/assign`.
///
/// Money arrives as `{minor, amount}` WITHOUT a currency of its own; the
/// currency is the sibling [currencyCode]. `minor` is authoritative and is a
/// 64-bit decimal string, so it is parsed into [Money] (BigInt) and never a
/// `double`. Every id here is a UUID string - there are no 64-bit integer ids
/// in this payload.
class BreakView {
  const BreakView({
    required this.id,
    required this.category,
    required this.categoryWire,
    required this.status,
    required this.statusWire,
    required this.severity,
    required this.currencyCode,
    required this.detectedAt,
    required this.detail,
    this.expected,
    this.actual,
    this.delta,
    this.depositRequestId,
    this.playerId,
    this.ledgerAccountId,
    this.ichancyCallId,
    this.dedupeKey,
    this.assignedToAdminId,
    this.resolvedAt,
    this.resolvedByAdminId,
    this.resolutionNote,
    this.resolutionTxId,
  });

  factory BreakView.fromJson(Map<String, Object?> json) {
    final String currency =
        Json.stringOrNull(json, 'currencyCode')?.trim().toUpperCase() ??
            Money.defaultCurrency;
    return BreakView(
      id: Json.string(json, 'id'),
      category: Json.enumValue(
        json,
        'category',
        BreakCategory.byWireName,
        orElse: BreakCategory.unknown,
      ),
      categoryWire: Json.stringOrNull(json, 'category') ?? '',
      status: Json.enumValue(
        json,
        'status',
        BreakStatus.byWireName,
        orElse: BreakStatus.unknown,
      ),
      statusWire: Json.stringOrNull(json, 'status') ?? '',
      severity: BreakSeverity.clamp(Json.integer(json, 'severity', orElse: 3)),
      currencyCode: currency,
      expected: _money(json, 'expected', currency),
      actual: _money(json, 'actual', currency),
      delta: _money(json, 'delta', currency),
      depositRequestId: Json.stringOrNull(json, 'depositRequestId'),
      playerId: Json.stringOrNull(json, 'playerId'),
      ledgerAccountId: Json.stringOrNull(json, 'ledgerAccountId'),
      ichancyCallId: Json.stringOrNull(json, 'ichancyCallId'),
      detail: BreakDetail.fromJson(json['detail']),
      dedupeKey: Json.stringOrNull(json, 'dedupeKey'),
      detectedAt: Json.dateTime(json, 'detectedAt'),
      assignedToAdminId: Json.stringOrNull(json, 'assignedToAdminId'),
      resolvedAt: Json.dateTimeOrNull(json, 'resolvedAt'),
      resolvedByAdminId: Json.stringOrNull(json, 'resolvedByAdminId'),
      resolutionNote: Json.stringOrNull(json, 'resolutionNote'),
      resolutionTxId: Json.stringOrNull(json, 'resolutionTxId'),
    );
  }

  /// `BreakMoney` is `{minor, amount}` with no currency key of its own.
  static Money? _money(
    Map<String, Object?> json,
    String key,
    String currency,
  ) {
    final Map<String, Object?>? object = Json.objectOrNull(json, key);
    if (object == null) {
      return null;
    }
    final Money? fromMinor =
        Money.fromMinorStringOrNull(object['minor'], currency: currency);
    if (fromMinor != null) {
      return fromMinor;
    }
    // `amount` is display-only, but it is the only fallback if a future payload
    // ever drops `minor`.
    return Money.fromDecimalStringOrNull(object['amount'], currency: currency);
  }

  final String id;
  final BreakCategory category;

  /// The raw wire value, kept so an unrecognised category is still traceable.
  final String categoryWire;

  final BreakStatus status;
  final String statusWire;

  /// 1..5.
  final int severity;

  final String currencyCode;

  /// Our side (the ledger) at detection time.
  final Money? expected;

  /// The external / observed side at detection time.
  final Money? actual;

  /// `actual - expected`, computed server-side. Null whenever either side is
  /// null. SIGNED - a negative delta is not the same problem as a positive one,
  /// so it is never shown as a magnitude.
  final Money? delta;

  final String? depositRequestId;
  final String? playerId;
  final String? ledgerAccountId;
  final String? ichancyCallId;

  /// Free-form evidence written by whichever detector opened the break.
  final BreakDetail detail;

  /// Stable natural key of the finding, e.g. `agent-float:NSP:2026-08-16`.
  /// Breaks are upserted on it, so the same drift on the same UTC day reuses
  /// the same row and the same id.
  final String? dedupeKey;

  /// When the problem FIRST appeared. Re-observations never move it, and it is
  /// the cursor sort key.
  final DateTime detectedAt;

  final String? assignedToAdminId;
  final DateTime? resolvedAt;
  final String? resolvedByAdminId;
  final String? resolutionNote;

  /// UUID of the compensating ledger transaction. ONLY `correct-float` sets it;
  /// a plain resolve never does.
  final String? resolutionTxId;

  /// Short, human-quotable form of the UUID for a list row.
  String get shortId => id.length <= 8 ? id : id.substring(0, 8);

  bool get isTerminal => status.isTerminal;
  bool get isAssigned => assignedToAdminId != null;

  /// A non-zero difference that is still outstanding.
  bool get hasDrift {
    final Money? value = delta;
    return value != null && !value.isZero;
  }

  /// TRAP: an `I1_SINGLE_SIDED` invariant break carries ENTRY COUNTS in
  /// expected/actual/delta, which the backend still formats at scale 2 (a count
  /// of 2 renders as `0.02`). When this is true the numbers must be shown as
  /// plain counts, never as currency.
  bool get amountsAreEntryCounts => detail.invariant == 'I1_SINGLE_SIDED';

  /// Raw counts for the [amountsAreEntryCounts] case.
  BigInt? get expectedCount => expected?.minor;
  BigInt? get actualCount => actual?.minor;

  /// `POST /breaks/:id/assign` has NO terminal-status guard: it would happily
  /// flip a closed break back to INVESTIGATING while leaving the resolution
  /// fields populated. The client is the only guard, so this must gate the UI.
  bool get canAssign => !status.isTerminal;

  /// Resolve refuses an already-closed break with 422 BREAK_ALREADY_RESOLVED.
  bool get canResolve => !status.isTerminal;

  /// A ledger correction is only possible for an open agent-float mismatch that
  /// still has a non-zero delta.
  bool get canCorrectFloat =>
      category.supportsFloatCorrection && !status.isTerminal && hasDrift;

  /// The state assign can produce: INVESTIGATING with the resolution fields of
  /// a previous closure still attached. Worth flagging in the UI so nobody
  /// reads a stale note as the current decision.
  bool get isReopenedAfterClosure => !status.isTerminal && resolvedAt != null;

  /// Linked to a deposit whose credit needs reconciling. There is no admin
  /// endpoint that resolves this UUID to a deposit shortId, so it is shown as
  /// evidence rather than as a link.
  bool get touchesDeposit => depositRequestId != null;

  /// True when this break should shout: unresolved, high severity or drifting.
  bool get needsAttention =>
      !status.isTerminal && (severity >= 4 || hasDrift || status == BreakStatus.open);

  BreakView copyWith({
    BreakStatus? status,
    String? statusWire,
    String? assignedToAdminId,
    DateTime? resolvedAt,
    String? resolvedByAdminId,
    String? resolutionNote,
    String? resolutionTxId,
  }) {
    return BreakView(
      id: id,
      category: category,
      categoryWire: categoryWire,
      status: status ?? this.status,
      statusWire: statusWire ?? this.statusWire,
      severity: severity,
      currencyCode: currencyCode,
      detectedAt: detectedAt,
      detail: detail,
      expected: expected,
      actual: actual,
      delta: delta,
      depositRequestId: depositRequestId,
      playerId: playerId,
      ledgerAccountId: ledgerAccountId,
      ichancyCallId: ichancyCallId,
      dedupeKey: dedupeKey,
      assignedToAdminId: assignedToAdminId ?? this.assignedToAdminId,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedByAdminId: resolvedByAdminId ?? this.resolvedByAdminId,
      resolutionNote: resolutionNote ?? this.resolutionNote,
      resolutionTxId: resolutionTxId ?? this.resolutionTxId,
    );
  }
}
