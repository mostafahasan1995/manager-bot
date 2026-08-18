/// THE ONE FILE that fabricates طرق الدفع content.
///
/// Every data endpoint on the backend needs a bearer token and the entry code
/// has been removed for now, so there is no session and nothing real to fetch.
/// The whole destination therefore reads from here.
///
/// SWAPPING IN THE LIVE API IS A ONE-FILE CHANGE: give
/// `methodsSourceProvider` (application/methods_providers.dart) something else
/// that exposes `Future<List<PlayerPaymentMethod>> load()`, and delete this
/// file. No widget, no provider and no model changes.
///
/// Amounts are `BigInt` minor units at scale 2 - `'2500000'` is 25,000.00 NSP.
library;

import 'package:flutter/foundation.dart' show immutable;
import 'package:manager_bot/core/errors/api_error.dart';
import 'package:manager_bot/core/money/money.dart';
import 'package:manager_bot/features/shell/methods/data/payment_method_demo_models.dart';

/// Which shape the demo source answers with.
///
/// The screen must render loading, empty and error correctly long before the
/// API exists, so all three are reachable by overriding
/// `methodsSourceProvider` in a test or a debug build.
enum MethodsDemoOutcome {
  /// The full catalogue below.
  data,

  /// A well-formed but empty catalogue.
  empty,

  /// A transport failure, so the error shape can be exercised.
  failure,
}

/// Stand-in for `PaymentMethodRepository`.
@immutable
class PaymentMethodsDemoSource {
  const PaymentMethodsDemoSource({
    this.latency = const Duration(milliseconds: 420),
    this.outcome = MethodsDemoOutcome.data,
  });

  /// Fake round-trip, so the shimmer is actually seen during development.
  final Duration latency;

  final MethodsDemoOutcome outcome;

  /// Same signature a real repository method would have.
  Future<List<PlayerPaymentMethod>> load() async {
    if (latency > Duration.zero) {
      await Future<void>.delayed(latency);
    }
    return switch (outcome) {
      MethodsDemoOutcome.data => PaymentMethodsDemoData.methods(),
      MethodsDemoOutcome.empty => const <PlayerPaymentMethod>[],
      MethodsDemoOutcome.failure => throw const ApiNetworkError(
          message: 'demo: no session, no network call was made',
        ),
    };
  }
}

/// The sample catalogue: Syrian rails, Syrian account holders, NSP amounts.
abstract final class PaymentMethodsDemoData {
  /// Built fresh on each call because [Money] holds a `BigInt`, which no
  /// `const` expression can produce. The list itself is immutable in spirit -
  /// nothing mutates it.
  static List<PlayerPaymentMethod> methods() => <PlayerPaymentMethod>[
        PlayerPaymentMethod(
          id: 'syriatel-cash',
          name: const LocalizedText('سيريتل كاش', 'Syriatel Cash'),
          monogram: 'SC',
          rail: MethodRail.mobileWallet,
          accent: MethodAccent.signature,
          minAmount: Money.fromMinorString('2500000'),
          maxAmount: Money.fromMinorString('300000000'),
          fixedFee: Money.zero(),
          settlement: const Duration(minutes: 10),
          requiresReference: true,
          availability: MethodAvailability.available,
          checkedAgo: const Duration(minutes: 4),
          destinationAccount: '0932 118 470',
          destinationHolder: const LocalizedText('محمد الخطيب', 'Mohammad Al-Khatib'),
          popular: true,
          steps: const <LocalizedText>[
            LocalizedText(
              'افتح تطبيق سيريتل كاش واختر «تحويل إلى محفظة».',
              'Open the Syriatel Cash app and choose "Transfer to wallet".',
            ),
            LocalizedText(
              'أدخل رقم المحفظة الظاهر أعلاه والمبلغ الذي تريد شحنه.',
              'Enter the wallet number shown above and the amount you want to top up.',
            ),
            LocalizedText(
              'أكّد التحويل واحتفظ برسالة التأكيد التي تصلك.',
              'Confirm the transfer and keep the confirmation message you receive.',
            ),
            LocalizedText(
              'ارجع إلى التطبيق، ارفع صورة الرسالة وأدخل رقم العملية.',
              'Come back here, upload a screenshot of the message and enter the operation number.',
            ),
          ],
          proofItems: const <LocalizedText>[
            LocalizedText(
              'صورة واضحة لرسالة التأكيد يظهر فيها المبلغ والتاريخ.',
              'A clear screenshot of the confirmation message showing the amount and the date.',
            ),
            LocalizedText(
              'رقم العملية كما ورد في الرسالة، بدون مسافات.',
              'The operation number exactly as it appears in the message, with no spaces.',
            ),
          ],
        ),
        PlayerPaymentMethod(
          id: 'mtn-cash',
          name: const LocalizedText('MTN كاش', 'MTN Cash'),
          monogram: 'MTN',
          rail: MethodRail.mobileWallet,
          accent: MethodAccent.hot,
          minAmount: Money.fromMinorString('2500000'),
          maxAmount: Money.fromMinorString('200000000'),
          fixedFee: Money.fromMinorString('250000'),
          settlement: const Duration(minutes: 15),
          requiresReference: true,
          availability: MethodAvailability.available,
          checkedAgo: const Duration(minutes: 12),
          destinationAccount: '0947 602 355',
          destinationHolder: const LocalizedText('ريم العلي', 'Reem Al-Ali'),
          steps: const <LocalizedText>[
            LocalizedText(
              'اطلب ‎*111#‎ أو افتح تطبيق MTN كاش.',
              'Dial *111# or open the MTN Cash app.',
            ),
            LocalizedText(
              'اختر «تحويل أموال» وأدخل الرقم الظاهر أعلاه.',
              'Choose "Send money" and enter the number shown above.',
            ),
            LocalizedText(
              'أدخل المبلغ، ثم أكّد بكلمة المرور الخاصة بك.',
              'Enter the amount, then confirm with your PIN.',
            ),
            LocalizedText(
              'ارفع صورة رسالة التأكيد مع رقم العملية.',
              'Upload the confirmation message together with the operation number.',
            ),
          ],
          proofItems: const <LocalizedText>[
            LocalizedText(
              'رسالة التأكيد الأصلية من MTN، غير مقصوصة.',
              'The original MTN confirmation message, not cropped.',
            ),
            LocalizedText(
              'رقم العملية المكوّن من عشر خانات.',
              'The ten-digit operation number.',
            ),
          ],
        ),
        PlayerPaymentMethod(
          id: 'bemo-bank',
          name: const LocalizedText(
            'بنك بيمو السعودي الفرنسي',
            'Banque Bemo Saudi Fransi',
          ),
          monogram: 'BSF',
          rail: MethodRail.bankTransfer,
          accent: MethodAccent.neon,
          minAmount: Money.fromMinorString('10000000'),
          maxAmount: Money.fromMinorString('2500000000'),
          fixedFee: Money.zero(),
          settlement: const Duration(hours: 3),
          requiresReference: true,
          availability: MethodAvailability.busy,
          checkedAgo: const Duration(minutes: 27),
          destinationAccount: 'SY52 0021 0000 0000 4417 8290',
          destinationHolder: const LocalizedText('أحمد حجازي', 'Ahmad Hijazi'),
          steps: const <LocalizedText>[
            LocalizedText(
              'نفّذ حوالة داخلية إلى رقم الحساب الظاهر أعلاه.',
              'Make an internal transfer to the account number shown above.',
            ),
            LocalizedText(
              'اكتب اسم المستخدم الخاص بك في خانة البيان.',
              'Write your username in the transfer note field.',
            ),
            LocalizedText(
              'احتفظ بإشعار الحوالة الورقي أو الإلكتروني.',
              'Keep the paper or electronic transfer advice.',
            ),
            LocalizedText(
              'ارفع صورة الإشعار وأدخل رقم الحوالة.',
              'Upload a photo of the advice and enter the transfer number.',
            ),
          ],
          proofItems: const <LocalizedText>[
            LocalizedText(
              'إشعار الحوالة كاملاً مع ختم الفرع أو ترويسة البنك.',
              'The full transfer advice with the branch stamp or the bank header.',
            ),
            LocalizedText(
              'رقم الحوالة كما هو مطبوع على الإشعار.',
              'The transfer number exactly as printed on the advice.',
            ),
            LocalizedText(
              'اسم المرسل مطابق لاسم صاحب الحساب.',
              'A sender name that matches the account holder.',
            ),
          ],
        ),
        PlayerPaymentMethod(
          id: 'al-haram',
          name: const LocalizedText('الهرم للتحويلات', 'Al Haram Exchange'),
          monogram: 'HRM',
          rail: MethodRail.cashOffice,
          accent: MethodAccent.sunset,
          minAmount: Money.fromMinorString('5000000'),
          maxAmount: Money.fromMinorString('1000000000'),
          fixedFee: Money.fromMinorString('500000'),
          settlement: const Duration(minutes: 45),
          requiresReference: false,
          availability: MethodAvailability.available,
          checkedAgo: const Duration(minutes: 21),
          destinationAccount: '0114 55 227',
          destinationHolder: const LocalizedText('لينا شعبان', 'Lina Shaaban'),
          steps: const <LocalizedText>[
            LocalizedText(
              'توجّه إلى أقرب فرع للهرم واطلب حوالة داخلية.',
              'Go to the nearest Al Haram branch and ask for an internal transfer.',
            ),
            LocalizedText(
              'أعطِ الموظف اسم المستلم ورقم المكتب الظاهر أعلاه.',
              'Give the clerk the recipient name and the office number shown above.',
            ),
            LocalizedText(
              'استلم الوصل الورقي قبل مغادرة الفرع.',
              'Take the paper receipt before you leave the branch.',
            ),
            LocalizedText(
              'صوّر الوصل كاملاً وارفعه من شاشة الشحن.',
              'Photograph the whole receipt and upload it from the top-up screen.',
            ),
          ],
          proofItems: const <LocalizedText>[
            LocalizedText(
              'صورة للوصل الورقي كاملاً، بإضاءة كافية.',
              'A well-lit photo of the entire paper receipt.',
            ),
            LocalizedText(
              'اسم المرسل واضح على الوصل.',
              'A sender name that is legible on the receipt.',
            ),
          ],
        ),
        PlayerPaymentMethod(
          id: 'usdt-trc20',
          name: const LocalizedText('USDT — شبكة TRC-20', 'USDT — TRC-20'),
          monogram: 'USDT',
          rail: MethodRail.crypto,
          accent: MethodAccent.credited,
          minAmount: Money.fromMinorString('15000000'),
          maxAmount: Money.fromMinorString('4000000000'),
          fixedFee: Money.zero(),
          settlement: const Duration(minutes: 25),
          requiresReference: true,
          availability: MethodAvailability.available,
          checkedAgo: const Duration(minutes: 2),
          destinationAccount: 'TQ5n8xPmVd4Kb2rWc9Ua7Yh3Jf6Ng1Ls4',
          destinationHolder: const LocalizedText(
            'محفظة الكاشير — TRC-20',
            'Cashier wallet — TRC-20',
          ),
          steps: const <LocalizedText>[
            LocalizedText(
              'انسخ عنوان المحفظة أعلاه وتأكّد أن الشبكة TRC-20.',
              'Copy the wallet address above and make sure the network is TRC-20.',
            ),
            LocalizedText(
              'أرسل المبلغ من محفظتك، وتحمّل أنت رسوم الشبكة.',
              'Send the amount from your wallet and cover the network fee yourself.',
            ),
            LocalizedText(
              'انسخ معرّف العملية (TxID) بعد تأكيد الشبكة.',
              'Copy the transaction hash (TxID) once the network confirms it.',
            ),
            LocalizedText(
              'ارفع لقطة الشاشة وأدخل معرّف العملية كمرجع.',
              'Upload the screenshot and enter the TxID as the reference.',
            ),
          ],
          proofItems: const <LocalizedText>[
            LocalizedText(
              'لقطة شاشة تُظهر المبلغ وعنوان المستلم والشبكة.',
              'A screenshot showing the amount, the destination address and the network.',
            ),
            LocalizedText(
              'معرّف العملية (TxID) كاملاً.',
              'The complete transaction hash (TxID).',
            ),
          ],
        ),
        PlayerPaymentMethod(
          id: 'sham-cash',
          name: const LocalizedText('شام كاش', 'Sham Cash'),
          monogram: 'SHM',
          rail: MethodRail.mobileWallet,
          accent: MethodAccent.glitch,
          minAmount: Money.fromMinorString('2000000'),
          maxAmount: Money.fromMinorString('150000000'),
          fixedFee: Money.zero(),
          settlement: const Duration(minutes: 8),
          requiresReference: true,
          availability: MethodAvailability.unavailable,
          checkedAgo: const Duration(minutes: 38),
          destinationAccount: '4419 8827 0031',
          destinationHolder: const LocalizedText('سامر ديب', 'Samer Deeb'),
          steps: const <LocalizedText>[
            LocalizedText(
              'افتح تطبيق شام كاش واختر «تحويل».',
              'Open the Sham Cash app and choose "Transfer".',
            ),
            LocalizedText(
              'أدخل رقم المحفظة الظاهر أعلاه والمبلغ.',
              'Enter the wallet number shown above and the amount.',
            ),
            LocalizedText(
              'ارفع إشعار التحويل مع رقم العملية.',
              'Upload the transfer notice together with the operation number.',
            ),
          ],
          proofItems: const <LocalizedText>[
            LocalizedText(
              'إشعار التحويل داخل التطبيق.',
              'The in-app transfer notice.',
            ),
            LocalizedText('رقم العملية.', 'The operation number.'),
          ],
        ),
        PlayerPaymentMethod(
          id: 'al-fouad',
          name: const LocalizedText('الفؤاد للحوالات', 'Al Fouad Transfers'),
          monogram: 'FOU',
          rail: MethodRail.cashOffice,
          accent: MethodAccent.sunset,
          minAmount: Money.fromMinorString('7500000'),
          maxAmount: Money.fromMinorString('800000000'),
          fixedFee: Money.fromMinorString('750000'),
          settlement: const Duration(hours: 1, minutes: 30),
          requiresReference: false,
          availability: MethodAvailability.unavailable,
          checkedAgo: const Duration(hours: 2, minutes: 10),
          destinationAccount: '0332 91 604',
          destinationHolder: const LocalizedText('نور الدين قاسم', 'Nour Aldin Kassem'),
          steps: const <LocalizedText>[
            LocalizedText(
              'توجّه إلى فرع الفؤاد واطلب حوالة داخلية.',
              'Go to an Al Fouad branch and ask for an internal transfer.',
            ),
            LocalizedText(
              'أعطِ الموظف اسم المستلم ورقم المكتب.',
              'Give the clerk the recipient name and the office number.',
            ),
            LocalizedText(
              'صوّر الوصل وارفعه من شاشة الشحن.',
              'Photograph the receipt and upload it from the top-up screen.',
            ),
          ],
          proofItems: const <LocalizedText>[
            LocalizedText(
              'صورة للوصل الورقي كاملاً.',
              'A photo of the entire paper receipt.',
            ),
          ],
        ),
      ];
}
