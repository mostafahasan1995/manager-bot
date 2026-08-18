import 'package:intl/intl.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';

/// Thrown when a string cannot be interpreted as an exact minor-unit amount.
///
/// [reason] mirrors the backend's own reason codes so the UI can show the same
/// message the API would have returned:
/// * `MONEY_EMPTY`             - nothing to parse
/// * `MONEY_MALFORMED`         - not a plain decimal (exponent, `+`, `.5`, `1.`)
/// * `MONEY_TOO_MANY_DECIMALS` - more fraction digits than the currency scale
/// * `MONEY_CURRENCY_MISMATCH` - arithmetic across two currencies
class MoneyFormatException implements Exception {
  const MoneyFormatException(this.input, this.reason);

  final String input;
  final String reason;

  @override
  String toString() => 'MoneyFormatException($reason): "$input"';
}

/// An exact monetary amount held as a [BigInt] count of MINOR units.
///
/// The backend stores and computes every amount as a 64-bit integer of minor
/// units (NSP, scale 2 -> `minor = major * 100`). No value in this class is
/// ever routed through `double`, and negative amounts are meaningful (ledger
/// credit side, Ichancy withdrawals) so nothing is ever `abs()`-ed implicitly.
///
/// TWO wire encodings exist and both are supported:
///
/// 1. `MoneyView` OBJECT - deposit-shaped endpoints:
///    `{"minor":"150000","amount":"1500.00","currency":"NSP"}`
///    -> [Money.fromMoneyView] / [Money.fromMoneyViewOrNull]
///
/// 2. BARE DECIMAL STRING with the currency as a sibling field - payment
///    methods (`minAmount`/`maxAmount`/`feeFixed`), destinations (`dailyCap`,
///    nullable) and approval limits:
///    `{"minAmount":"1000.00","currencyCode":"NSP"}`
///    -> [Money.fromDecimalString] / [Money.fromDecimalStringOrNull]
///
/// Any field whose name ends in `Minor` is already minor units as a decimal
/// string -> [Money.fromMinorString].
class Money implements Comparable<Money> {

  /// Zero in [currency]. Safe for `fold` seeds and empty totals.
  factory Money.zero({
    String currency = defaultCurrency,
    int scale = defaultScale,
  }) =>
      Money.raw(BigInt.zero, currency: currency, scale: scale);

  /// Wraps an already-computed minor-unit [BigInt].
  factory Money.fromMinor(
    BigInt minor, {
    String currency = defaultCurrency,
    int scale = defaultScale,
  }) =>
      Money.raw(minor, currency: currency, scale: scale);

  /// Parses a raw minor-unit decimal string such as `"150000"` (== 1500.00).
  ///
  /// Use for any field whose name ends in `Minor`, and for `MoneyView.minor`.
  factory Money.fromMinorString(
    String minorString, {
    String currency = defaultCurrency,
    int scale = defaultScale,
  }) {
    final trimmed = minorString.trim();
    final parsed = BigInt.tryParse(trimmed);
    if (parsed == null) {
      throw MoneyFormatException(minorString, 'MONEY_MALFORMED');
    }
    return Money.raw(parsed, currency: currency, scale: scale);
  }

  /// Parses a bare decimal string such as `"1500.00"` or `"-12.5"`.
  ///
  /// Accepts at most [scale] fraction digits; anything longer is the same
  /// failure the backend reports as `INVALID_AMOUNT` /
  /// `MONEY_TOO_MANY_DECIMALS`. Grouping separators are NOT accepted here -
  /// this is the wire format, not user input. See [parseUserInput] for typing.
  factory Money.fromDecimalString(
    String amount, {
    String currency = defaultCurrency,
    int scale = defaultScale,
  }) =>
      Money.raw(
        _decimalToMinor(amount, scale),
        currency: currency,
        scale: scale,
      );

  /// Parses the `MoneyView` OBJECT `{minor, amount, currency}`.
  ///
  /// `minor` is authoritative; `amount` is only a fallback for a hypothetical
  /// payload that omits it. `currency` defaults to [defaultCurrency].
  factory Money.fromMoneyView(
    Map<String, Object?> json, {
    int scale = defaultScale,
  }) {
    final rawCurrency = json['currency'];
    final currency = rawCurrency is String && rawCurrency.trim().isNotEmpty
        ? rawCurrency.trim().toUpperCase()
        : defaultCurrency;

    final rawMinor = json['minor'];
    if (rawMinor is String && rawMinor.trim().isNotEmpty) {
      return Money.fromMinorString(rawMinor, currency: currency, scale: scale);
    }
    final rawAmount = json['amount'];
    if (rawAmount is String && rawAmount.trim().isNotEmpty) {
      return Money.fromDecimalString(rawAmount, currency: currency, scale: scale);
    }
    throw const MoneyFormatException('<MoneyView>', 'MONEY_MALFORMED');
  }
  const Money.raw(
    this.minor, {
    this.currency = defaultCurrency,
    this.scale = defaultScale,
  });

  /// Exact integer amount in minor units. Signed.
  final BigInt minor;

  /// ISO-ish 3-letter currency code as emitted by the API, e.g. `NSP`.
  final String currency;

  /// Number of fraction digits in the major representation. NSP is 2.
  final int scale;

  static const String defaultCurrency = 'NSP';
  static const int defaultScale = 2;

  /// Null-tolerant [Money.fromMinorString]. Returns null for null/blank input.
  static Money? fromMinorStringOrNull(
    Object? minorString, {
    String currency = defaultCurrency,
    int scale = defaultScale,
  }) {
    if (minorString == null) {
      return null;
    }
    if (minorString is! String || minorString.trim().isEmpty) {
      return null;
    }
    return Money.fromMinorString(minorString, currency: currency, scale: scale);
  }

  /// Null-tolerant [Money.fromDecimalString]; used for nullable wire fields
  /// such as `AdminPaymentDestinationView.dailyCap`.
  static Money? fromDecimalStringOrNull(
    Object? amount, {
    String currency = defaultCurrency,
    int scale = defaultScale,
  }) {
    if (amount == null) {
      return null;
    }
    if (amount is! String || amount.trim().isEmpty) {
      return null;
    }
    return Money.fromDecimalString(amount, currency: currency, scale: scale);
  }

  /// Null-tolerant [Money.fromMoneyView] for `verified` / `credited`, which are
  /// the WHOLE OBJECT-or-null.
  static Money? fromMoneyViewOrNull(Object? json, {int scale = defaultScale}) {
    if (json == null) {
      return null;
    }
    if (json is Map<String, Object?>) {
      return Money.fromMoneyView(json, scale: scale);
    }
    if (json is Map<Object?, Object?>) {
      return Money.fromMoneyView(
        json.map((key, value) => MapEntry(key.toString(), value)),
        scale: scale,
      );
    }
    return null;
  }

  /// Turns typed human input into exact minor units WITHOUT touching `double`.
  ///
  /// Accepts: `50000`, `50,000`, `50 000`, `50,000.25`, `50.000,25`,
  /// `-1 234.50`. Grouping separator handling:
  /// * both `.` and `,` present -> the LAST one is the decimal separator
  /// * only `,` present, appearing once, with exactly 3 digits after it and at
  ///   least one digit before -> treated as a GROUPING separator (`50,000`)
  /// * only `,` present otherwise -> decimal separator (`50,25`)
  ///
  /// Throws [MoneyFormatException] with `MONEY_TOO_MANY_DECIMALS` when the user
  /// types more precision than the currency has, which is exactly the 400 the
  /// backend would answer with.
  static Money parseUserInput(
    String input, {
    String currency = defaultCurrency,
    int scale = defaultScale,
  }) {
    final normalized = _normalizeUserInput(input);
    return Money.raw(
      _decimalToMinor(normalized, scale),
      currency: currency,
      scale: scale,
    );
  }

  /// Non-throwing [parseUserInput], for live form validation.
  static Money? tryParseUserInput(
    String input, {
    String currency = defaultCurrency,
    int scale = defaultScale,
  }) {
    try {
      return parseUserInput(input, currency: currency, scale: scale);
    } on MoneyFormatException {
      return null;
    }
  }

  /// Reason code from [MoneyFormatException] for the given input, or null when
  /// the input is valid. Handy for `TextFormField.validator`.
  static String? validationReason(
    String input, {
    int scale = defaultScale,
  }) {
    try {
      _decimalToMinor(_normalizeUserInput(input), scale);
      return null;
    } on MoneyFormatException catch (e) {
      return e.reason;
    }
  }

  bool get isZero => minor == BigInt.zero;
  bool get isNegative => minor.isNegative;
  bool get isPositive => minor > BigInt.zero;

  /// Exact wire-shaped decimal string, e.g. `-1500.00`. No grouping.
  String toDecimalString() {
    final negative = minor.isNegative;
    final digits = (negative ? -minor : minor).toString().padLeft(scale + 1, '0');
    final intPart = digits.substring(0, digits.length - scale);
    final sign = negative ? '-' : '';
    if (scale == 0) {
      return '$sign$intPart';
    }
    final fraction = digits.substring(digits.length - scale);
    return '$sign$intPart.$fraction';
  }

  /// Exact minor-unit string, e.g. `-150000`. What the wire calls `minor`.
  String toMinorString() => minor.toString();

  /// Request body shape for `MoneyDto`: `{"amount":"1500.00","currencyCode":"NSP"}`.
  ///
  /// The API rejects a JSON number here, so `amount` is always a string.
  Map<String, Object?> toMoneyDtoJson() => <String, Object?>{
        'amount': toDecimalString(),
        'currencyCode': currency,
      };

  /// Human rendering with locale grouping, e.g. `1,500.00 NSP`.
  ///
  /// Digits are always ASCII (deliberate: a money-review console must show the
  /// same glyphs the backend logs show); only the separators are localised.
  ///
  /// NEVER pass the UI locale in [locale]: the bot quotes `1,500.00 NSP` to
  /// Arabic operators and so does this app. [strings] supplies only the
  /// amount/currency LAYOUT, which is identical in both bundles by design.
  String format({
    String? locale,
    bool withCurrency = true,
    bool alwaysShowSign = false,
    AppStrings strings = AppStrings.ar,
  }) {
    final symbols = _symbolsFor(locale);
    final negative = minor.isNegative;
    final digits = (negative ? -minor : minor).toString().padLeft(scale + 1, '0');
    final intPart = digits.substring(0, digits.length - scale);
    final fraction = scale == 0 ? '' : digits.substring(digits.length - scale);

    final grouped = _group(intPart, symbols.group);
    final body = fraction.isEmpty ? grouped : '$grouped${symbols.decimal}$fraction';
    final sign = negative
        ? symbols.minus
        : (alwaysShowSign && !isZero ? '+' : '');
    return withCurrency
        ? strings.moneyAmountWithCurrency(
            amount: '$sign$body',
            currency: currency,
          )
        : '$sign$body';
  }

  Money operator +(Money other) {
    _assertCompatible(other);
    return Money.raw(minor + other.minor, currency: currency, scale: scale);
  }

  Money operator -(Money other) {
    _assertCompatible(other);
    return Money.raw(minor - other.minor, currency: currency, scale: scale);
  }

  Money operator -() => Money.raw(-minor, currency: currency, scale: scale);

  /// Exact scaling by a whole number of times. There is deliberately no
  /// division and no multiplication by a fraction: either would need a rounding
  /// policy the backend owns.
  Money multiplyBy(int factor) =>
      Money.raw(minor * BigInt.from(factor), currency: currency, scale: scale);

  /// Same as [multiplyBy] for counts that exceed 2^53.
  Money multiplyByBigInt(BigInt factor) =>
      Money.raw(minor * factor, currency: currency, scale: scale);

  /// Magnitude. Only call where the sign is genuinely irrelevant (e.g. showing
  /// "1,500.00 debited"); NEVER on a raw ledger value.
  Money magnitude() =>
      Money.raw(minor.isNegative ? -minor : minor, currency: currency, scale: scale);

  bool operator <(Money other) {
    _assertCompatible(other);
    return minor < other.minor;
  }

  bool operator <=(Money other) {
    _assertCompatible(other);
    return minor <= other.minor;
  }

  bool operator >(Money other) {
    _assertCompatible(other);
    return minor > other.minor;
  }

  bool operator >=(Money other) {
    _assertCompatible(other);
    return minor >= other.minor;
  }

  @override
  int compareTo(Money other) {
    _assertCompatible(other);
    return minor.compareTo(other.minor);
  }

  @override
  bool operator ==(Object other) =>
      other is Money &&
      other.minor == minor &&
      other.currency == currency &&
      other.scale == scale;

  @override
  int get hashCode => Object.hash(minor, currency, scale);

  @override
  String toString() => 'Money(${toDecimalString()} $currency)';

  void _assertCompatible(Money other) {
    if (other.currency != currency || other.scale != scale) {
      throw MoneyFormatException(
        '$currency/$scale vs ${other.currency}/${other.scale}',
        'MONEY_CURRENCY_MISMATCH',
      );
    }
  }

  // --- parsing internals ---------------------------------------------------

  static final RegExp _decimalPattern = RegExp(r'^(\d+)(?:\.(\d+))?$');
  static final RegExp _asciiDigit = RegExp('[0-9]');
  static final RegExp _nonDigitRun = RegExp('[^0-9]+');

  static BigInt _decimalToMinor(String raw, int scale) {
    var text = raw.trim();
    if (text.isEmpty) {
      throw MoneyFormatException(raw, 'MONEY_EMPTY');
    }
    var negative = false;
    if (text.startsWith('-')) {
      negative = true;
      text = text.substring(1).trim();
    }
    final match = _decimalPattern.firstMatch(text);
    if (match == null) {
      // Rejects exponents, a leading '+', a bare '.5' and a trailing '1.',
      // exactly like the backend's ^-?\d{1,18}(\.\d{1,6})?$ contract.
      throw MoneyFormatException(raw, 'MONEY_MALFORMED');
    }
    final intPart = match.group(1) ?? '0';
    final fraction = match.group(2) ?? '';
    if (fraction.length > scale) {
      throw MoneyFormatException(raw, 'MONEY_TOO_MANY_DECIMALS');
    }
    final padded = fraction.padRight(scale, '0');
    final value = BigInt.parse('$intPart$padded');
    return negative ? -value : value;
  }

  static String _normalizeUserInput(String input) {
    var text = input.trim();
    if (text.isEmpty) {
      return text;
    }
    // Drop every separator that can only ever be grouping: ASCII space,
    // NO-BREAK SPACE (U+00A0), NARROW NO-BREAK SPACE (U+202F), THIN SPACE
    // (U+2009), underscore and apostrophe (de-CH grouping).
    for (final separator in const <String>[
      ' ',
      '\u00A0',
      '\u202F',
      '\u2009',
      '_',
      "'",
    ]) {
      text = text.replaceAll(separator, '');
    }

    final lastDot = text.lastIndexOf('.');
    final lastComma = text.lastIndexOf(',');

    if (lastDot >= 0 && lastComma >= 0) {
      if (lastComma > lastDot) {
        text = text.replaceAll('.', '');
        text = text.replaceRange(text.lastIndexOf(','), text.lastIndexOf(',') + 1, '.');
      } else {
        text = text.replaceAll(',', '');
      }
    } else if (lastComma >= 0) {
      final commaCount = ','.allMatches(text).length;
      final digitsAfter = text.length - lastComma - 1;
      final looksGrouped =
          commaCount > 1 || (digitsAfter == 3 && lastComma > 0 && text[0] != ',');
      text = looksGrouped
          ? text.replaceAll(',', '')
          : text.replaceRange(lastComma, lastComma + 1, '.');
    }
    return text;
  }

  static String _group(String intDigits, String separator) {
    if (separator.isEmpty || intDigits.length <= 3) {
      return intDigits;
    }
    final buffer = StringBuffer();
    final head = intDigits.length % 3;
    if (head > 0) {
      buffer.write(intDigits.substring(0, head));
    }
    for (var i = head; i < intDigits.length; i += 3) {
      if (buffer.isNotEmpty) {
        buffer.write(separator);
      }
      buffer.write(intDigits.substring(i, i + 3));
    }
    return buffer.toString();
  }

  static final Map<String, _MoneySymbols> _symbolCache = <String, _MoneySymbols>{};

  static _MoneySymbols _symbolsFor(String? locale) {
    final key = locale ?? Intl.getCurrentLocale();
    final cached = _symbolCache[key];
    if (cached != null) {
      return cached;
    }
    final resolved = _probeSymbols(key);
    _symbolCache[key] = resolved;
    return resolved;
  }

  /// Discovers the locale's grouping/decimal separators by formatting a known
  /// INTEGER (never a double) and reading the punctuation back out. Falls back
  /// to `1,234.00` conventions for unknown or non-ASCII-digit locales.
  static _MoneySymbols _probeSymbols(String locale) {
    const fallback = _MoneySymbols(group: ',', decimal: '.', minus: '-');
    try {
      final formatter = NumberFormat.decimalPattern(locale)
        ..minimumFractionDigits = 2
        ..maximumFractionDigits = 2;
      final probe = formatter.format(-1234567);
      final firstDigit = probe.indexOf(_asciiDigit);
      if (firstDigit < 0) {
        return fallback;
      }
      final minus = firstDigit == 0 ? '-' : probe.substring(0, firstDigit);
      final body = probe.substring(firstDigit);
      final runs = _nonDigitRun
          .allMatches(body)
          .map((match) => match.group(0) ?? '')
          .where((run) => run.isNotEmpty)
          .toList();
      if (runs.length < 2) {
        return fallback;
      }
      return _MoneySymbols(group: runs.first, decimal: runs.last, minus: minus);
    } on Object {
      return fallback;
    }
  }
}

class _MoneySymbols {
  const _MoneySymbols({
    required this.group,
    required this.decimal,
    required this.minus,
  });

  final String group;
  final String decimal;
  final String minus;
}

/// Sums money safely, including the empty case.
extension MoneyIterable on Iterable<Money> {
  /// Total of the iterable. Returns zero in [currency] when empty.
  ///
  /// Throws [MoneyFormatException] (`MONEY_CURRENCY_MISMATCH`) if the iterable
  /// mixes currencies - which is a real bug, not something to paper over.
  Money totalIn({
    String currency = Money.defaultCurrency,
    int scale = Money.defaultScale,
  }) {
    var sum = Money.zero(currency: currency, scale: scale);
    for (final item in this) {
      sum = sum + item;
    }
    return sum;
  }
}
