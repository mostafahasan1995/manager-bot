/// THE ONE FILE that holds every piece of sample content the top-up flow
/// renders.
///
/// Why demo data at all: every deposit endpoint on the backend needs a bearer
/// token and the entry code has been removed for now, so there is no session
/// and nothing real to fetch. Swapping this for the live repository is a single
/// change - keep the two `Future`-returning entry points ([loadMethods] and
/// [submitTopUp]) and delete the rest.
///
/// Amounts are NSP at scale 2, written as minor-unit strings, so `'5000000'`
/// reads as `50,000.00 NSP`.
library;

import 'package:manager_bot/core/money/money.dart';
import 'package:manager_bot/features/shell/topup/data/topup_models.dart';

/// Sample payment methods, destinations and identifiers for the top-up flow.
abstract final class TopUpDemoData {
  /// How long the fake catalogue takes to "arrive". Long enough that the
  /// skeleton state is real, short enough that nobody waits.
  static const Duration catalogueLatency = Duration(milliseconds: 700);

  /// How long a fake submission takes.
  static const Duration submitLatency = Duration(milliseconds: 900);

  /// How long the player has to complete the transfer once the pay step opens.
  static const Duration payWindow = Duration(minutes: 30);

  /// The four one-tap amounts: 10k / 25k / 50k / 100k NSP.
  static final List<Money> quickPicks = <Money>[
    Money.fromMinorString('1000000'),
    Money.fromMinorString('2500000'),
    Money.fromMinorString('5000000'),
    Money.fromMinorString('10000000'),
  ];

  /// The catalogue. Deliberately mixed: two wallets, a bank, a cash office and
  /// a crypto method with NO live destination, so the "nothing to send to"
  /// state is reachable without inventing a fake failure.
  static final List<TopUpMethod> methods = <TopUpMethod>[
    TopUpMethod(
      id: 'pm-syriatel-cash',
      rail: TopUpRail.mobileWallet,
      nameAr: 'سيرياتيل كاش',
      nameEn: 'Syriatel Cash',
      minAmount: Money.fromMinorString('500000'),
      maxAmount: Money.fromMinorString('150000000'),
      feeFixed: Money.zero(),
      requiresReference: true,
      instructionsAr: 'حوّل من تطبيق سيرياتيل كاش إلى الرقم الظاهر، ثم صوّر '
          'شاشة نجاح العملية كاملة.',
      instructionsEn: 'Send from the Syriatel Cash app to the number shown, '
          'then screenshot the whole success screen.',
      reviewMinutes: 10,
      destinations: const <TopUpDestination>[
        TopUpDestination(
          id: 'ds-syr-damascus',
          labelAr: 'محفظة دمشق',
          labelEn: 'Damascus wallet',
          accountNumber: '0933 214 778',
          accountHolder: 'محمد الحلبي',
        ),
        TopUpDestination(
          id: 'ds-syr-aleppo',
          labelAr: 'محفظة حلب',
          labelEn: 'Aleppo wallet',
          accountNumber: '0958 640 132',
          accountHolder: 'رهف العلي',
        ),
      ],
    ),
    TopUpMethod(
      id: 'pm-mtn-cash',
      rail: TopUpRail.mobileWallet,
      nameAr: 'إم تي إن كاش',
      nameEn: 'MTN Cash',
      minAmount: Money.fromMinorString('500000'),
      maxAmount: Money.fromMinorString('100000000'),
      feeFixed: Money.zero(),
      requiresReference: true,
      instructionsAr: 'من قائمة «تحويل الأموال» في تطبيق إم تي إن كاش، أرسل '
          'المبلغ تماماً إلى الرقم الظاهر.',
      instructionsEn: 'From "Transfer money" in the MTN Cash app, send exactly '
          'this amount to the number shown.',
      reviewMinutes: 12,
      destinations: const <TopUpDestination>[
        TopUpDestination(
          id: 'ds-mtn-latakia',
          labelAr: 'محفظة اللاذقية',
          labelEn: 'Latakia wallet',
          accountNumber: '0947 118 205',
          accountHolder: 'عمار خضور',
        ),
      ],
    ),
    TopUpMethod(
      id: 'pm-bemo-bank',
      rail: TopUpRail.bankTransfer,
      nameAr: 'بنك بيمو السعودي الفرنسي',
      nameEn: 'Banque Bemo Saudi Fransi',
      minAmount: Money.fromMinorString('2000000'),
      maxAmount: Money.fromMinorString('500000000'),
      feeFixed: Money.fromMinorString('150000'),
      requiresReference: true,
      instructionsAr: 'الحوالة المصرفية تصل خلال ساعات العمل فقط. اكتب الرقم '
          'المرجعي في خانة البيان.',
      instructionsEn: 'Bank transfers land during business hours only. Put the '
          'reference in the narration field.',
      reviewMinutes: 45,
      destinations: const <TopUpDestination>[
        TopUpDestination(
          id: 'ds-bemo-mazzeh',
          labelAr: 'فرع المزة',
          labelEn: 'Mazzeh branch',
          accountNumber: 'SY86 0011 0000 0000 4471 2093',
          accountHolder: 'لمى الشامي',
        ),
      ],
    ),
    TopUpMethod(
      id: 'pm-haram-office',
      rail: TopUpRail.cashOffice,
      nameAr: 'الهرم للحوالات',
      nameEn: 'Al Haram Exchange',
      minAmount: Money.fromMinorString('1000000'),
      maxAmount: Money.fromMinorString('300000000'),
      feeFixed: Money.fromMinorString('80000'),
      requiresReference: false,
      instructionsAr: 'ادفع نقداً في المكتب باسم المستفيد الظاهر، واحتفظ '
          'بالوصل الورقي وصوّره.',
      instructionsEn: 'Pay cash at the office to the beneficiary shown, keep '
          'the paper slip and photograph it.',
      reviewMinutes: 25,
      destinations: const <TopUpDestination>[
        TopUpDestination(
          id: 'ds-haram-homs',
          labelAr: 'مكتب حمص',
          labelEn: 'Homs office',
          accountNumber: 'HRM-4471',
          accountHolder: 'بشار قاسم',
        ),
        TopUpDestination(
          id: 'ds-haram-tartus',
          labelAr: 'مكتب طرطوس',
          labelEn: 'Tartus office',
          accountNumber: 'HRM-8820',
          accountHolder: 'نور الدين حمدان',
        ),
      ],
    ),
    TopUpMethod(
      id: 'pm-usdt-trc20',
      rail: TopUpRail.crypto,
      nameAr: 'يو إس دي تي (TRC20)',
      nameEn: 'USDT (TRC20)',
      minAmount: Money.fromMinorString('5000000'),
      maxAmount: Money.fromMinorString('2000000000'),
      feeFixed: Money.zero(),
      requiresReference: false,
      instructionsAr: 'لا يوجد عنوان محفظة مفعّل حالياً على هذه الشبكة.',
      instructionsEn: 'No wallet address is live on this network right now.',
      reviewMinutes: 15,
      destinations: const <TopUpDestination>[],
    ),
  ];

  /// The catalogue, after a believable wait. The live repository call goes
  /// here and the widgets do not change.
  static Future<List<TopUpMethod>> loadMethods() async {
    await Future<void>.delayed(catalogueLatency);
    return methods;
  }

  /// Files the deposit request and answers with its short id.
  static Future<String> submitTopUp() async {
    await Future<void>.delayed(submitLatency);
    return newShortId();
  }

  /// A deposit short id in the shape the bot quotes, e.g. `DP-7K4M2Q`.
  static String newShortId() =>
      'DP-${_code(6, DateTime.now().microsecondsSinceEpoch)}';

  /// The reference the player must quote in the transfer note.
  static String newReference() =>
      'TX${_code(8, DateTime.now().microsecondsSinceEpoch ^ 0x5F3A79)}';

  /// A believable receipt file name for the picker placeholder.
  static String newReceiptName() {
    final DateTime now = DateTime.now();
    final String stamp = '${now.year}'
        '${_two(now.month)}${_two(now.day)}_'
        '${_two(now.hour)}${_two(now.minute)}';
    return 'receipt_$stamp.jpg';
  }

  /// Unambiguous alphabet: no `I`, `L`, `O`, `0` or `1`, because these ids are
  /// read aloud to a cashier over Telegram.
  static const String _alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

  static String _code(int length, int seed) {
    final StringBuffer buffer = StringBuffer();
    int value = seed & 0x7FFFFFFF;
    for (int i = 0; i < length; i++) {
      value = (value * 1103515245 + 12345) & 0x7FFFFFFF;
      buffer.write(_alphabet[value % _alphabet.length]);
    }
    return buffer.toString();
  }

  static String _two(int value) => value < 10 ? '0$value' : '$value';
}
