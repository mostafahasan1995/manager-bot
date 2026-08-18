import 'package:manager_bot/core/api/json.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/money/money.dart';
import 'package:manager_bot/core/theme/app_theme.dart';

/// The four ledger invariants the sweep can report on.
enum LedgerInvariant {
  transactionZeroSum('I1_TRANSACTION_ZERO_SUM'),
  singleSided('I1_SINGLE_SIDED'),
  globalZeroSum('I2_GLOBAL_ZERO_SUM'),
  accountBalanceMatchesEntries('I3_ACCOUNT_BALANCE_MATCHES_ENTRIES'),
  unknown('UNKNOWN');

  const LedgerInvariant(this.wireName);

  static final Map<String, LedgerInvariant> byWireName =
      <String, LedgerInvariant>{
    for (final LedgerInvariant invariant in LedgerInvariant.values)
      invariant.wireName: invariant,
  };

  final String wireName;

  /// Card title.
  String label(AppStrings s) => switch (this) {
        LedgerInvariant.transactionZeroSum => s.invariantI1TransactionZeroSum,
        LedgerInvariant.singleSided => s.invariantI1SingleSided,
        LedgerInvariant.globalZeroSum => s.invariantI2GlobalZeroSum,
        LedgerInvariant.accountBalanceMatchesEntries =>
          s.invariantI3CachedBalanceDrift,
        LedgerInvariant.unknown => s.invariantUnknown,
      };

  /// One line saying what the invariant guarantees.
  String explanation(AppStrings s) => switch (this) {
        LedgerInvariant.transactionZeroSum =>
          s.invariantI1TransactionZeroSumExplain,
        LedgerInvariant.singleSided => s.invariantI1SingleSidedExplain,
        LedgerInvariant.globalZeroSum => s.invariantI2GlobalZeroSumExplain,
        LedgerInvariant.accountBalanceMatchesEntries =>
          s.invariantI3CachedBalanceDriftExplain,
        LedgerInvariant.unknown => s.invariantUnknownExplain,
      };

  /// TRAP: for `I1_SINGLE_SIDED` the expected/actual/delta fields hold ENTRY
  /// COUNTS (expected is the literal `2`), not money. Rendering them as
  /// currency turns "1 entry" into "0.01 NSP".
  bool get valuesAreEntryCounts => this == singleSided;

  /// What the `subject` string identifies for this invariant.
  String subjectKind(AppStrings s) => switch (this) {
        LedgerInvariant.transactionZeroSum ||
        LedgerInvariant.singleSided =>
          s.subjectKindTransaction,
        LedgerInvariant.globalZeroSum => s.subjectKindCurrency,
        LedgerInvariant.accountBalanceMatchesEntries => s.subjectKindAccount,
        LedgerInvariant.unknown => s.subjectKindSubject,
      };

  /// I1/I2 are "the books are broken"; I3 is a cache that drifted.
  StatusTone get tone => switch (this) {
        LedgerInvariant.transactionZeroSum ||
        LedgerInvariant.singleSided ||
        LedgerInvariant.globalZeroSum =>
          StatusTone.reject,
        LedgerInvariant.accountBalanceMatchesEntries => StatusTone.pending,
        LedgerInvariant.unknown => StatusTone.neutral,
      };

  static LedgerInvariant? tryParse(String? raw) {
    if (raw == null) {
      return null;
    }
    return byWireName[raw.trim().toUpperCase()];
  }
}

/// One violation from `POST /v1/admin/reconciliation/invariants/run`.
///
/// All seven wire keys are always present. `expectedMinor` / `actualMinor` /
/// `deltaMinor` are 64-bit decimal strings which are USUALLY money - except for
/// [LedgerInvariant.singleSided], where they are entry counts. The raw BigInt
/// is kept so a caller can render either meaning without a lossy conversion.
class LedgerInvariantViolation {
  const LedgerInvariantViolation({
    required this.invariant,
    required this.invariantWire,
    required this.subject,
    required this.currencyCode,
    required this.expectedRaw,
    required this.actualRaw,
    required this.deltaRaw,
    required this.detail,
  });

  factory LedgerInvariantViolation.fromJson(Map<String, Object?> json) {
    return LedgerInvariantViolation(
      invariant: Json.enumValue(
        json,
        'invariant',
        LedgerInvariant.byWireName,
        orElse: LedgerInvariant.unknown,
      ),
      invariantWire: Json.stringOrNull(json, 'invariant') ?? '',
      subject: Json.stringOrNull(json, 'subject') ?? '',
      currencyCode:
          Json.stringOrNull(json, 'currencyCode')?.trim().toUpperCase() ??
              Money.defaultCurrency,
      expectedRaw: _bigInt(json['expectedMinor']),
      actualRaw: _bigInt(json['actualMinor']),
      deltaRaw: _bigInt(json['deltaMinor']),
      detail: Json.stringOrNull(json, 'detail') ?? '',
    );
  }

  static BigInt _bigInt(Object? value) {
    if (value is String) {
      return BigInt.tryParse(value.trim()) ?? BigInt.zero;
    }
    if (value is int) {
      return BigInt.from(value);
    }
    return BigInt.zero;
  }

  final LedgerInvariant invariant;

  /// Raw wire value, so an unknown invariant is still quotable.
  final String invariantWire;

  /// A transaction UUID, an account UUID or a currency code, depending on
  /// [invariant]. Always a string - never assume it parses as a UUID.
  final String subject;

  final String currencyCode;

  /// Exact 64-bit values. Money OR entry counts - see
  /// [LedgerInvariant.valuesAreEntryCounts].
  final BigInt expectedRaw;
  final BigInt actualRaw;
  final BigInt deltaRaw;

  /// A pre-formatted English sentence. Safe to show verbatim; do not parse it.
  final String detail;

  bool get valuesAreEntryCounts => invariant.valuesAreEntryCounts;

  Money? get expected => valuesAreEntryCounts
      ? null
      : Money.fromMinor(expectedRaw, currency: currencyCode);

  Money? get actual => valuesAreEntryCounts
      ? null
      : Money.fromMinor(actualRaw, currency: currencyCode);

  Money? get delta => valuesAreEntryCounts
      ? null
      : Money.fromMinor(deltaRaw, currency: currencyCode);

  /// Display string that is correct for BOTH meanings. Money is formatted by
  /// [Money] itself and never routed through the catalogue.
  String expectedLabel(AppStrings s) => valuesAreEntryCounts
      ? s.entriesCount(count: expectedRaw.toInt())
      : expected!.format();

  String actualLabel(AppStrings s) => valuesAreEntryCounts
      ? s.entriesCount(count: actualRaw.toInt())
      : actual!.format();

  String deltaLabel(AppStrings s) => valuesAreEntryCounts
      ? s.entriesCount(count: deltaRaw.toInt())
      : delta!.format(alwaysShowSign: true);

  /// Shortened subject for a dense row.
  String get shortSubject =>
      subject.length <= 12 ? subject : '${subject.substring(0, 12)}...';
}

/// `POST /v1/admin/reconciliation/invariants/run`.
///
/// Read-only apart from an automatic I3 cache repair, and every violation is
/// also persisted as a `LEDGER_IMBALANCE` break. Can be slow: three full ledger
/// aggregates inside one transaction.
class LedgerInvariantReport {
  const LedgerInvariantReport({
    required this.ok,
    required this.checkedAt,
    required this.violations,
    required this.truncated,
  });

  factory LedgerInvariantReport.fromJson(Map<String, Object?> json) {
    return LedgerInvariantReport(
      ok: Json.boolean(json, 'ok', orElse: false),
      checkedAt: Json.dateTimeOrNull(json, 'checkedAt') ?? DateTime.now(),
      violations: Json.list<LedgerInvariantViolation>(
        json['violations'] ?? const <Object?>[],
        LedgerInvariantViolation.fromJson,
        path: 'violations',
      ),
      truncated: Json.boolean(json, 'truncated', orElse: false),
    );
  }

  /// True iff [violations] is empty.
  final bool ok;

  /// Server clock at the moment of the sweep, in local time.
  final DateTime checkedAt;

  final List<LedgerInvariantViolation> violations;

  /// A check hit the 100-row cap: there may be MORE violations than listed.
  final bool truncated;

  bool get isHealthy => ok && violations.isEmpty;

  /// Violation counts per invariant, for a summary strip.
  Map<LedgerInvariant, int> get countsByInvariant {
    final Map<LedgerInvariant, int> counts = <LedgerInvariant, int>{};
    for (final LedgerInvariantViolation violation in violations) {
      counts[violation.invariant] = (counts[violation.invariant] ?? 0) + 1;
    }
    return Map<LedgerInvariant, int>.unmodifiable(counts);
  }

  /// I1/I2 first (the books are wrong), then I3 (a cache drifted).
  List<LedgerInvariantViolation> get violationsWorstFirst {
    final List<LedgerInvariantViolation> severe = <LedgerInvariantViolation>[];
    final List<LedgerInvariantViolation> rest = <LedgerInvariantViolation>[];
    for (final LedgerInvariantViolation violation in violations) {
      if (violation.invariant == LedgerInvariant.accountBalanceMatchesEntries ||
          violation.invariant == LedgerInvariant.unknown) {
        rest.add(violation);
      } else {
        severe.add(violation);
      }
    }
    return List<LedgerInvariantViolation>.unmodifiable(
      <LedgerInvariantViolation>[...severe, ...rest],
    );
  }
}
