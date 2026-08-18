import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/money/money.dart';
import 'package:manager_bot/features/deposits/data/deposit_enums.dart';

/// `?sort=` on the admin queue.
///
/// [isPageable] encodes a real server limitation: `buildCursorWhere` returns
/// null for the amount sorts, because the cursor carries only `createdAt + id`,
/// which is not a valid keyset for an amount ordering. The server STILL emits a
/// non-null `meta.nextCursor` when `hasMore` is true, but passing it back
/// returns THE SAME FIRST PAGE - an infinite scroll would loop forever. The UI
/// must therefore refuse to load more on an amount sort.
enum DepositSort {
  newest('newest', true),
  oldest('oldest', true),
  amountDesc('amount_desc', false),
  amountAsc('amount_asc', false);

  const DepositSort(this.wireName, this.isPageable);

  final String wireName;

  /// Human label in the active language.
  String label(AppStrings s) => switch (this) {
        DepositSort.newest => s.sortNewest,
        DepositSort.oldest => s.sortOldest,
        DepositSort.amountDesc => s.sortAmountDesc,
        DepositSort.amountAsc => s.sortAmountAsc,
      };

  /// False for the amount sorts: keyset paging is broken there, so only the
  /// first page may ever be shown.
  final bool isPageable;

  static DepositSort? tryParse(String? raw) {
    if (raw == null) {
      return null;
    }
    final String normalized = raw.trim().toLowerCase();
    for (final DepositSort sort in DepositSort.values) {
      if (sort.wireName == normalized) {
        return sort;
      }
    }
    return null;
  }
}

/// Strict UUID v4, which is what the queue's `playerId`/`paymentMethodId`
/// filters demand (`@IsUUID('4')`). A v1/v7 uuid is a 400 there, even though
/// the PATH params accept any version.
final RegExp _uuidV4 = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
);

/// Every filter `GET /v1/admin/deposits` accepts, as one immutable value.
///
/// The ValidationPipe runs with `whitelist` + `forbidNonWhitelisted`, so ANY
/// unknown query key is a 400 - [toQuery] therefore emits exactly the
/// documented keys and nothing else.
class DepositQueueFilter {
  const DepositQueueFilter({
    this.statuses = const <DepositStatus>{},
    this.sort = DepositSort.newest,
    this.playerId,
    this.paymentMethodId,
    this.shortId,
    this.externalReference,
    this.createdFrom,
    this.createdTo,
    this.minAmount,
    this.maxAmount,
    this.unclaimedOnly = false,
  });

  /// The queue as it opens: server-default statuses (the three reviewable
  /// ones), newest first.
  static const DepositQueueFilter initial = DepositQueueFilter();

  /// Empty means "let the server default to SUBMITTED, UNDER_REVIEW and
  /// PENDING_SECOND_APPROVAL". To see CREDITED/REJECTED/etc. they must be
  /// listed explicitly.
  final Set<DepositStatus> statuses;

  final DepositSort sort;

  /// Strict UUID v4, exact match.
  final String? playerId;

  /// Strict UUID v4, exact match.
  final String? paymentMethodId;

  /// EXACT match (not a prefix search). Upper-cased server-side.
  final String? shortId;

  /// EXACT match, case-SENSITIVE, not trimmed server-side.
  final String? externalReference;

  /// INCLUSIVE lower bound on `createdAt`.
  final DateTime? createdFrom;

  /// EXCLUSIVE upper bound on `createdAt`.
  final DateTime? createdTo;

  /// Compared against `claimedAmountMinor` only - never verified or credited.
  final Money? minAmount;
  final Money? maxAmount;

  /// Adds `reviewStartedAt IS NULL`. Does NOT filter by status.
  final bool unclaimedOnly;

  /// True when this filter differs from the untouched queue view.
  bool get isActive =>
      statuses.isNotEmpty ||
      playerId != null ||
      paymentMethodId != null ||
      shortId != null ||
      externalReference != null ||
      createdFrom != null ||
      createdTo != null ||
      minAmount != null ||
      maxAmount != null ||
      unclaimedOnly;

  /// How many distinct filters are set, for a badge on the filter button.
  /// The sort is not counted - it is always set to something.
  int get activeCount {
    int count = 0;
    if (statuses.isNotEmpty) {
      count++;
    }
    if (playerId != null) {
      count++;
    }
    if (paymentMethodId != null) {
      count++;
    }
    if (shortId != null) {
      count++;
    }
    if (externalReference != null) {
      count++;
    }
    if (createdFrom != null || createdTo != null) {
      count++;
    }
    if (minAmount != null || maxAmount != null) {
      count++;
    }
    if (unclaimedOnly) {
      count++;
    }
    return count;
  }

  /// Client-side validation that mirrors the server's, so a typo becomes an
  /// inline message instead of a 400 round trip. Empty means valid.
  List<String> validate(AppStrings s) {
    final List<String> problems = <String>[];
    final String? player = playerId;
    if (player != null && !_uuidV4.hasMatch(player)) {
      problems.add(s.validationPlayerIdUuid);
    }
    final String? method = paymentMethodId;
    if (method != null && !_uuidV4.hasMatch(method)) {
      problems.add(s.validationPaymentMethodIdUuid);
    }
    final String? reference = externalReference;
    if (reference != null && reference.length > 120) {
      problems.add(s.validationReferenceTooLong);
    }
    final String? short = shortId;
    if (short != null && short.length > 32) {
      problems.add(s.validationShortIdTooLong);
    }
    final Money? min = minAmount;
    final Money? max = maxAmount;
    if (min != null && max != null && min > max) {
      problems.add(s.validationMinAboveMax);
    }
    final DateTime? from = createdFrom;
    final DateTime? to = createdTo;
    if (from != null && to != null && !from.isBefore(to)) {
      problems.add(s.validationFromBeforeTo);
    }
    return problems;
  }

  /// Exactly the query keys the DTO whitelists. Null/empty values are dropped
  /// by `ApiClient`, and `limit`/`cursor` are added by `getCursorPage`.
  Map<String, Object?> toQuery() {
    final Money? min = minAmount;
    final Money? max = maxAmount;
    return <String, Object?>{
      if (statuses.isNotEmpty)
        // Comma-separated; the server trims and upper-cases each entry.
        'status': statuses
            .map((DepositStatus status) => status.wireName)
            .join(','),
      if (playerId != null) 'playerId': playerId,
      if (paymentMethodId != null) 'paymentMethodId': paymentMethodId,
      if (shortId != null) 'shortId': shortId!.trim().toUpperCase(),
      if (externalReference != null) 'externalReference': externalReference,
      if (createdFrom != null)
        'createdFrom': createdFrom!.toUtc().toIso8601String(),
      if (createdTo != null) 'createdTo': createdTo!.toUtc().toIso8601String(),
      // ALWAYS exactly 2 decimals: the controller parses these directly with
      // parseDecimalToMinor, so >2 decimals escapes as a plain Error and 500s.
      if (min != null) 'minAmount': min.toDecimalString(),
      if (max != null) 'maxAmount': max.toDecimalString(),
      // Only `true`/`1`/JSON true read as true; omit it entirely when false.
      if (unclaimedOnly) 'unclaimedOnly': 'true',
      'sort': sort.wireName,
    };
  }

  /// `null` sentinels mean "leave unchanged"; the `clear*` flags remove a
  /// value, which a nullable named parameter alone cannot express.
  DepositQueueFilter copyWith({
    Set<DepositStatus>? statuses,
    DepositSort? sort,
    String? playerId,
    String? paymentMethodId,
    String? shortId,
    String? externalReference,
    DateTime? createdFrom,
    DateTime? createdTo,
    Money? minAmount,
    Money? maxAmount,
    bool? unclaimedOnly,
    bool clearPlayerId = false,
    bool clearPaymentMethodId = false,
    bool clearShortId = false,
    bool clearExternalReference = false,
    bool clearCreatedFrom = false,
    bool clearCreatedTo = false,
    bool clearMinAmount = false,
    bool clearMaxAmount = false,
  }) =>
      DepositQueueFilter(
        statuses: statuses ?? this.statuses,
        sort: sort ?? this.sort,
        playerId: clearPlayerId ? null : (playerId ?? this.playerId),
        paymentMethodId: clearPaymentMethodId
            ? null
            : (paymentMethodId ?? this.paymentMethodId),
        shortId: clearShortId ? null : (shortId ?? this.shortId),
        externalReference: clearExternalReference
            ? null
            : (externalReference ?? this.externalReference),
        createdFrom: clearCreatedFrom ? null : (createdFrom ?? this.createdFrom),
        createdTo: clearCreatedTo ? null : (createdTo ?? this.createdTo),
        minAmount: clearMinAmount ? null : (minAmount ?? this.minAmount),
        maxAmount: clearMaxAmount ? null : (maxAmount ?? this.maxAmount),
        unclaimedOnly: unclaimedOnly ?? this.unclaimedOnly,
      );

  @override
  bool operator ==(Object other) =>
      other is DepositQueueFilter &&
      _sameStatuses(other.statuses, statuses) &&
      other.sort == sort &&
      other.playerId == playerId &&
      other.paymentMethodId == paymentMethodId &&
      other.shortId == shortId &&
      other.externalReference == externalReference &&
      other.createdFrom == createdFrom &&
      other.createdTo == createdTo &&
      other.minAmount == minAmount &&
      other.maxAmount == maxAmount &&
      other.unclaimedOnly == unclaimedOnly;

  @override
  int get hashCode => Object.hash(
        Object.hashAllUnordered(statuses),
        sort,
        playerId,
        paymentMethodId,
        shortId,
        externalReference,
        createdFrom,
        createdTo,
        minAmount,
        maxAmount,
        unclaimedOnly,
      );

  static bool _sameStatuses(Set<DepositStatus> a, Set<DepositStatus> b) {
    if (a.length != b.length) {
      return false;
    }
    for (final DepositStatus status in a) {
      if (!b.contains(status)) {
        return false;
      }
    }
    return true;
  }
}
