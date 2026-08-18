import 'package:manager_bot/core/api/json.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/money/money.dart';

/// One age bucket of a `RAIL_CLEARING` account.
///
/// WIRE: `GET /v1/admin/reconciliation/rail-ageing` -> `rows[].buckets[]`, and
/// also inside the `detail` blob of an `UNIDENTIFIED_RECEIPT` break.
///
/// `debitMinor` / `creditMinor` / `netMinor` are MONEY MINOR UNITS as decimal
/// strings (64-bit, may exceed 2^53) - parsed as [Money], never as `double`.
/// `entryCount`, `fromDays` and `toDays` are genuinely plain ints.
///
/// A report only contains buckets that actually have entries, so the list is
/// 0..5 long and SPARSE. Never index by position; match on [label] or on
/// [fromDays] / [toDays].
class RailAgeingBucket {
  const RailAgeingBucket({
    required this.label,
    required this.fromDays,
    required this.toDays,
    required this.debit,
    required this.credit,
    required this.net,
    required this.entryCount,
  });

  /// Parses one bucket. [currencyCode] comes from the owning row - the bucket
  /// object itself carries no currency.
  factory RailAgeingBucket.fromJson(
    Map<String, Object?> json, {
    String currencyCode = Money.defaultCurrency,
  }) {
    return RailAgeingBucket(
      label: Json.stringOrNull(json, 'label') ?? '?',
      fromDays: Json.integer(json, 'fromDays', orElse: 0),
      toDays: Json.intOrNull(json, 'toDays'),
      debit: Money.fromMinorStringOrNull(json['debitMinor'],
              currency: currencyCode) ??
          Money.zero(currency: currencyCode),
      credit: Money.fromMinorStringOrNull(json['creditMinor'],
              currency: currencyCode) ??
          Money.zero(currency: currencyCode),
      net: Money.fromMinorStringOrNull(json['netMinor'],
              currency: currencyCode) ??
          Money.zero(currency: currencyCode),
      entryCount: Json.integer(json, 'entryCount', orElse: 0),
    );
  }

  /// The complete closed set of labels the backend can emit, youngest first.
  static const List<String> knownLabels = <String>[
    '0-1d',
    '1-3d',
    '3-7d',
    '7-30d',
    '30d+',
  ];

  /// The RAW wire label, e.g. `0-1d`. Matched on, never shown directly - use
  /// [displayLabel].
  final String label;

  /// The bucket chip's text. The wire label is a closed set, so it is mapped
  /// through the catalogue; anything the backend grows later falls back to the
  /// raw value rather than to an invented translation.
  String displayLabel(AppStrings s) => switch (label) {
        '0-1d' => s.bucket0to1d,
        '1-3d' => s.bucket1to3d,
        '3-7d' => s.bucket3to7d,
        '7-30d' => s.bucket7to30d,
        '30d+' => s.bucket30dPlus,
        _ => label,
      };

  /// Inclusive lower bound in days: one of 0, 1, 3, 7, 30.
  final int fromDays;

  /// Exclusive upper bound, or null for the open-ended `30d+` bucket.
  final int? toDays;

  final Money debit;
  final Money credit;

  /// Signed: `debit - credit`. Can be negative.
  final Money net;

  /// Plain int32 count of ledger entries. NOT money.
  final int entryCount;

  /// The open-ended bucket is the one that makes an account stale.
  bool get isOpenEnded => toDays == null;

  /// Money that has been sitting in this bucket long enough to matter.
  bool get isAgeing => fromDays >= 7;
}

/// One `RAIL_CLEARING` ledger account in the ageing report.
class RailAgeingRow {
  const RailAgeingRow({
    required this.accountId,
    required this.accountCode,
    required this.currencyCode,
    required this.balance,
    required this.buckets,
    this.paymentMethodId,
    this.oldestUnsettledAt,
  });

  factory RailAgeingRow.fromJson(Map<String, Object?> json) {
    final String currency =
        Json.stringOrNull(json, 'currencyCode')?.trim().toUpperCase() ??
            Money.defaultCurrency;
    final Object? bucketsValue = json['buckets'];
    final List<Object?> rawBuckets =
        bucketsValue is List<Object?> ? bucketsValue : const <Object?>[];
    final List<RailAgeingBucket> buckets = <RailAgeingBucket>[
      for (final Object? bucket in rawBuckets)
        if (bucket is Map<Object?, Object?>)
          RailAgeingBucket.fromJson(
            Json.asObject(bucket, path: 'buckets[]'),
            currencyCode: currency,
          ),
    ];
    return RailAgeingRow(
      accountId: Json.string(json, 'accountId'),
      accountCode: Json.stringOrNull(json, 'accountCode') ?? '?',
      currencyCode: currency,
      paymentMethodId: Json.stringOrNull(json, 'paymentMethodId'),
      balance: Money.fromMinorStringOrNull(json['balanceMinor'],
              currency: currency) ??
          Money.zero(currency: currency),
      oldestUnsettledAt: Json.dateTimeOrNull(json, 'oldestUnsettledAt'),
      buckets: List<RailAgeingBucket>.unmodifiable(buckets),
    );
  }

  final String accountId;

  /// Stable human account code; this is what appears in
  /// [RailAgeingReport.staleAccountCodes].
  final String accountCode;

  final String currencyCode;
  final String? paymentMethodId;

  /// Signed sum of the buckets' net amounts. Can be negative or zero.
  final Money balance;

  /// MIN(created_at) across the account's entries, in local time.
  final DateTime? oldestUnsettledAt;

  /// Sparse: only buckets that actually have entries. Length 0..5.
  final List<RailAgeingBucket> buckets;

  /// The `30d+` bucket, when the account has one.
  RailAgeingBucket? get openEndedBucket {
    for (final RailAgeingBucket bucket in buckets) {
      if (bucket.isOpenEnded) {
        return bucket;
      }
    }
    return null;
  }

  /// How long the oldest unsettled entry has been waiting, or null.
  Duration? ageOfOldest({DateTime? now}) {
    final DateTime? oldest = oldestUnsettledAt;
    if (oldest == null) {
      return null;
    }
    return (now ?? DateTime.now()).difference(oldest);
  }

  /// Total number of ledger entries across the buckets present.
  int get entryCount {
    int total = 0;
    for (final RailAgeingBucket bucket in buckets) {
      total += bucket.entryCount;
    }
    return total;
  }
}

/// `GET /v1/admin/reconciliation/rail-ageing` - money credited to players that
/// the rail has not confirmed yet, bucketed by age.
class RailAgeingReport {
  const RailAgeingReport({
    required this.generatedAt,
    required this.rows,
    required this.staleAccountCodes,
  });

  factory RailAgeingReport.fromJson(Map<String, Object?> json) {
    return RailAgeingReport(
      generatedAt: Json.dateTimeOrNull(json, 'generatedAt') ?? DateTime.now(),
      rows: Json.list<RailAgeingRow>(
        json['rows'] ?? const <Object?>[],
        RailAgeingRow.fromJson,
        path: 'rows',
      ),
      staleAccountCodes: Json.stringList(json, 'staleAccountCodes'),
    );
  }

  final DateTime generatedAt;

  /// Ordered by `accountCode` ascending. Possibly empty, never null.
  final List<RailAgeingRow> rows;

  /// Accounts holding a positive balance with a positive open-ended bucket -
  /// i.e. money that has been unconfirmed for over thirty days.
  final List<String> staleAccountCodes;

  bool get isEmpty => rows.isEmpty;
  bool get hasStaleAccounts => staleAccountCodes.isNotEmpty;

  bool isStale(String accountCode) => staleAccountCodes.contains(accountCode);

  /// Stale rows first, then the rest, each keeping the server's ordering.
  List<RailAgeingRow> get rowsWorstFirst {
    final List<RailAgeingRow> stale = <RailAgeingRow>[];
    final List<RailAgeingRow> rest = <RailAgeingRow>[];
    for (final RailAgeingRow row in rows) {
      if (isStale(row.accountCode)) {
        stale.add(row);
      } else {
        rest.add(row);
      }
    }
    return List<RailAgeingRow>.unmodifiable(<RailAgeingRow>[...stale, ...rest]);
  }
}
