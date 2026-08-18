import 'package:manager_bot/core/api/json.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/money/money.dart';

/// One row of `GET /v1/admin/payment-methods/{id}/destinations`.
///
/// This is the account a player is told to pay into. The seed ships PLACEHOLDER
/// rows on purpose so a fresh install can render a deposit flow, and the
/// backend's STATUS.md is explicit that a player who pays into one has sent
/// money nowhere. [looksLikePlaceholder] exists so the console shouts about
/// that instead of quietly listing it as a normal account.
class AdminPaymentDestinationView {
  const AdminPaymentDestinationView({
    required this.id,
    required this.paymentMethodId,
    required this.label,
    required this.accountIdentifier,
    required this.isActive,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
    this.accountHolder,
    this.notes,
    this.dailyCap,
  });

  /// Hand-written parser.
  ///
  /// NOTE on the currency: the destination payload carries NO `currencyCode`,
  /// so `dailyCap` is parsed in [Money.defaultCurrency]. It is really in the
  /// owning method's currency - use [dailyCapIn] before comparing or adding it
  /// to a method amount, or `Money` will (correctly) refuse the mismatch.
  factory AdminPaymentDestinationView.fromJson(Map<String, Object?> json) =>
      AdminPaymentDestinationView(
        id: Json.string(json, 'id'),
        paymentMethodId: Json.string(json, 'paymentMethodId'),
        label: Json.string(json, 'label'),
        accountIdentifier: Json.string(json, 'accountIdentifier'),
        accountHolder: Json.stringOrNull(json, 'accountHolder'),
        notes: Json.stringOrNull(json, 'notes'),
        isActive: Json.boolean(json, 'isActive', orElse: true),
        priority: Json.integer(json, 'priority', orElse: 0),
        dailyCap: Money.fromDecimalStringOrNull(json['dailyCap']),
        createdAt: Json.dateTime(json, 'createdAt'),
        updatedAt: Json.dateTime(json, 'updatedAt'),
      );

  /// Prefix the backend seed gives every placeholder account identifier.
  ///
  /// Verified in `prisma/seed/payment-method.seed.ts`
  /// (`const PLACEHOLDER_PREFIX = 'SEED-PLACEHOLDER'`).
  static const String seedPlaceholderPrefix = 'SEED-PLACEHOLDER';

  /// Account holder the seed writes, verbatim.
  static const String seedPlaceholderHolder = 'REPLACE ME';

  /// Note the seed writes, matched case-insensitively on a stable fragment.
  static const String seedPlaceholderNoteFragment = 'created by the seed';

  /// Extra hand-typed markers. Deliberately short and specific: a false
  /// positive on a real IBAN would train operators to ignore the warning.
  static const List<String> placeholderMarkers = <String>[
    'PLACEHOLDER',
    'CHANGEME',
    'CHANGE-ME',
    'REPLACE-ME',
  ];

  /// UUID of the DESTINATION. Note the update/delete routes are flat
  /// (`/v1/admin/payment-destinations/{id}`), not nested under the method.
  final String id;

  /// UUID of the owning payment method.
  final String paymentMethodId;

  /// Rail-dependent heading the player sees: `Bank:`, `Wallet:`, `Office:` or
  /// - critically - `Network:` on CRYPTO, where it is the chain name.
  final String label;

  /// The IBAN / MSISDN / address / office code, stored EXACTLY as typed (trim
  /// only, never case-normalised, because uppercasing a Base58 address yields a
  /// different, valid-looking address). IMMUTABLE after creation.
  final String accountIdentifier;

  /// Shown by the bank / e-wallet / cash drivers; IGNORED by the crypto driver.
  final String? accountHolder;

  /// Appended verbatim to the player-facing instructions.
  final String? notes;

  final bool isActive;

  /// LOWER IS OFFERED FIRST. The picker inverts it into a rotation weight
  /// capped at 16, so priorities 0 and 4 split traffic roughly 5:1. It is not a
  /// boolean "preferred" flag.
  final int priority;

  /// SOFT daily cap measured against CLAIMED amounts. When every destination is
  /// over cap the picker ignores caps rather than blocking the player, so this
  /// must never be presented as a hard limit. Null means no cap.
  final Money? dailyCap;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// [dailyCap] restated in [currency] (the owning method's currency).
  ///
  /// The minor units are exact and unchanged; only the label moves, because the
  /// wire simply does not say which currency the cap is in.
  Money? dailyCapIn(String currency) {
    final Money? cap = dailyCap;
    if (cap == null) {
      return null;
    }
    return Money.fromMinor(cap.minor, currency: currency, scale: cap.scale);
  }

  /// True when the identifier is the seed's own placeholder.
  bool get _identifierIsSeeded =>
      accountIdentifier.trim().toUpperCase().startsWith(seedPlaceholderPrefix);

  /// True when the identifier carries a hand-typed placeholder marker.
  bool get _identifierHasMarker {
    final String identifier = accountIdentifier.trim().toUpperCase();
    return !_identifierIsSeeded && placeholderMarkers.any(identifier.contains);
  }

  bool get _holderIsPlaceholder {
    final String holder = (accountHolder ?? '').trim().toUpperCase();
    return holder == seedPlaceholderHolder ||
        placeholderMarkers.any(holder.contains);
  }

  bool get _notesAreSeeded =>
      (notes ?? '').toLowerCase().contains(seedPlaceholderNoteFragment);

  /// Human reasons this row looks like a seeded/unfinished placeholder.
  ///
  /// Empty means nothing suspicious was found. This is a heuristic on top of
  /// one VERIFIED fact (the seed's `SEED-PLACEHOLDER-` prefix); the rest are
  /// conservative markers for a half-finished manual entry.
  List<String> placeholderReasons(AppStrings s) => List<String>.unmodifiable(
        <String>[
          if (_identifierIsSeeded)
            s.pdReasonSeedPrefix(prefix: seedPlaceholderPrefix)
          else if (_identifierHasMarker)
            s.pdReasonMarker,
          if (_holderIsPlaceholder) s.pdReasonHolder,
          if (_notesAreSeeded) s.pdReasonNotes,
        ],
      );

  /// True when at least one placeholder marker matched.
  bool get looksLikePlaceholder =>
      _identifierIsSeeded ||
      _identifierHasMarker ||
      _holderIsPlaceholder ||
      _notesAreSeeded;

  /// A placeholder that is ACTIVE, i.e. one the picker can hand to a real
  /// player right now. This is the state the backend warns about.
  bool get isLivePlaceholder => isActive && looksLikePlaceholder;

  @override
  String toString() => 'AdminPaymentDestinationView($label, '
      '${isActive ? 'active' : 'disabled'}, priority $priority)';
}
