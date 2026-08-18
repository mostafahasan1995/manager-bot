import 'package:manager_bot/core/money/money.dart';
import 'package:manager_bot/features/shell/activity/data/activity_models.dart';

/// THE ONLY FILE IN THIS FEATURE THAT INVENTS CONTENT.
///
/// Every data endpoint on the backend needs a bearer token and the app now
/// opens with no session, so there is nothing real to fetch. The screen is
/// therefore fed from here. Swapping to the live repository is a ONE-LINE
/// change in `activityRepositoryProvider`: nothing outside this file knows
/// where a row came from.
///
/// House rules for the content below:
/// * amounts are exact `BigInt` MINOR units at scale 2 - `50,000.00 NSP` is
///   the string `'5000000'`, never a `double` and never `50000`;
/// * timestamps are relative to an anchor so the ages stay believable however
///   long after the build the app runs;
/// * [ActivityDeposit.methodName], `destinationLabel`, `senderName`,
///   `reference` and `staffNote` are RECORD VALUES, not UI copy - they are the
///   Arabic a Syrian cashier actually types, and they stay Arabic under the
///   English locale exactly as the live API would return them.
abstract final class ActivityDemoData {
  /// The whole history, newest first.
  ///
  /// [now] is the anchor every age is measured back from; pass a fixed value
  /// in a test to get a deterministic list.
  static List<ActivityDeposit> feed({DateTime? now}) {
    final DateTime anchor = now ?? DateTime.now();
    return <ActivityDeposit>[
      ActivityDeposit(
        shortId: 'DP-9F88',
        amount: Money.fromMinorString('5000000'),
        methodName: 'سيرياتيل كاش',
        destinationLabel: '0932 *** 418',
        senderName: 'مصطفى الحلبي',
        reference: 'SYR-8842517',
        status: ActivityStatus.submitted,
        submittedAt: anchor.subtract(const Duration(minutes: 2)),
      ),
      ActivityDeposit(
        shortId: 'DP-9F41',
        amount: Money.fromMinorString('7500000'),
        methodName: 'سيرياتيل كاش',
        destinationLabel: '0932 *** 418',
        senderName: 'مصطفى الحلبي',
        reference: 'SYR-8842190',
        status: ActivityStatus.underReview,
        submittedAt: anchor.subtract(const Duration(minutes: 12)),
        reviewStartedAt: anchor.subtract(const Duration(minutes: 5)),
      ),
      ActivityDeposit(
        shortId: 'DP-9E07',
        amount: Money.fromMinorString('15000000'),
        methodName: 'شام كاش',
        destinationLabel: '0955 *** 073',
        senderName: 'رامي دياب',
        reference: 'SHM-4410772',
        status: ActivityStatus.crediting,
        submittedAt: anchor.subtract(const Duration(minutes: 41)),
        reviewStartedAt: anchor.subtract(const Duration(minutes: 33)),
        decidedAt: anchor.subtract(const Duration(minutes: 28)),
      ),
      ActivityDeposit(
        shortId: 'DP-9D88',
        amount: Money.fromMinorString('5000000'),
        methodName: 'MTN كاش',
        destinationLabel: '0947 *** 612',
        senderName: 'ليلى العلي',
        status: ActivityStatus.credited,
        submittedAt: anchor.subtract(const Duration(hours: 2, minutes: 18)),
        reviewStartedAt: anchor.subtract(const Duration(hours: 2, minutes: 9)),
        decidedAt: anchor.subtract(const Duration(hours: 2, minutes: 4)),
        settledAt: anchor.subtract(const Duration(hours: 2, minutes: 3)),
        credited: Money.fromMinorString('5000000'),
      ),
      ActivityDeposit(
        shortId: 'DP-9C52',
        amount: Money.fromMinorString('25000000'),
        methodName: 'بنك بيمو السعودي الفرنسي',
        destinationLabel: 'حساب 500 *** 129',
        senderName: 'أحمد الخطيب',
        reference: 'BMO-20260817-0442',
        status: ActivityStatus.approved,
        submittedAt: anchor.subtract(const Duration(hours: 4, minutes: 6)),
        reviewStartedAt: anchor.subtract(const Duration(hours: 3, minutes: 52)),
        decidedAt: anchor.subtract(const Duration(hours: 3, minutes: 40)),
      ),
      ActivityDeposit(
        shortId: 'DP-9B10',
        amount: Money.fromMinorString('3750000'),
        methodName: 'الهرم للحوالات',
        destinationLabel: 'فرع الميدان - دمشق',
        senderName: 'نور الدين قاسم',
        reference: 'HRM-771204',
        status: ActivityStatus.rejected,
        submittedAt: anchor.subtract(const Duration(hours: 7, minutes: 22)),
        reviewStartedAt: anchor.subtract(const Duration(hours: 7, minutes: 1)),
        decidedAt: anchor.subtract(const Duration(hours: 6, minutes: 48)),
        staffNote: 'صورة الإيصال غير واضحة؛ أعد التصوير بحيث يظهر رقم الحوالة كاملاً.',
      ),
      ActivityDeposit(
        shortId: 'DP-9A73',
        amount: Money.fromMinorString('10000000'),
        methodName: 'سيرياتيل كاش',
        destinationLabel: '0932 *** 418',
        senderName: 'جمانة الأتاسي',
        reference: 'SYR-8829344',
        status: ActivityStatus.credited,
        submittedAt: anchor.subtract(const Duration(hours: 11, minutes: 4)),
        reviewStartedAt: anchor.subtract(const Duration(hours: 10, minutes: 55)),
        decidedAt: anchor.subtract(const Duration(hours: 10, minutes: 50)),
        settledAt: anchor.subtract(const Duration(hours: 10, minutes: 49)),
        credited: Money.fromMinorString('9800000'),
      ),
      ActivityDeposit(
        shortId: 'DP-98E4',
        amount: Money.fromMinorString('2500000'),
        methodName: 'MTN كاش',
        destinationLabel: '0947 *** 612',
        senderName: 'باسل شاهين',
        status: ActivityStatus.credited,
        submittedAt: anchor.subtract(const Duration(hours: 19, minutes: 37)),
        reviewStartedAt: anchor.subtract(const Duration(hours: 19, minutes: 30)),
        decidedAt: anchor.subtract(const Duration(hours: 19, minutes: 26)),
        settledAt: anchor.subtract(const Duration(hours: 19, minutes: 25)),
        credited: Money.fromMinorString('2500000'),
      ),
      ActivityDeposit(
        shortId: 'DP-9701',
        amount: Money.fromMinorString('50000000'),
        methodName: 'USDT (TRC20)',
        destinationLabel: 'TQm9 *** 4vXe',
        senderName: 'عمر شحادة',
        reference: '0x4f1a *** 9c22',
        status: ActivityStatus.credited,
        submittedAt: anchor.subtract(const Duration(days: 1, hours: 3)),
        reviewStartedAt: anchor.subtract(const Duration(days: 1, hours: 2, minutes: 51)),
        decidedAt: anchor.subtract(const Duration(days: 1, hours: 2, minutes: 44)),
        settledAt: anchor.subtract(const Duration(days: 1, hours: 2, minutes: 43)),
        credited: Money.fromMinorString('49500000'),
      ),
      ActivityDeposit(
        shortId: 'DP-95BC',
        amount: Money.fromMinorString('1200000'),
        methodName: 'شام كاش',
        destinationLabel: '0955 *** 073',
        senderName: 'ياسمين درويش',
        reference: 'SHM-4402118',
        status: ActivityStatus.expired,
        submittedAt: anchor.subtract(const Duration(days: 1, hours: 14)),
        decidedAt: anchor.subtract(const Duration(days: 1, hours: 2)),
        staffNote: 'لم تصل حوالة مطابقة خلال 12 ساعة.',
      ),
      ActivityDeposit(
        shortId: 'DP-943A',
        amount: Money.fromMinorString('8250000'),
        methodName: 'بنك بيبلوس سوريا',
        destinationLabel: 'حساب 331 *** 907',
        senderName: 'حسن العمري',
        reference: 'BYB-0091774',
        status: ActivityStatus.credited,
        submittedAt: anchor.subtract(const Duration(days: 2, hours: 5)),
        reviewStartedAt: anchor.subtract(const Duration(days: 2, hours: 4, minutes: 48)),
        decidedAt: anchor.subtract(const Duration(days: 2, hours: 4, minutes: 39)),
        settledAt: anchor.subtract(const Duration(days: 2, hours: 4, minutes: 38)),
        credited: Money.fromMinorString('8100000'),
      ),
      ActivityDeposit(
        shortId: 'DP-92F6',
        amount: Money.fromMinorString('30000000'),
        methodName: 'الفؤاد للحوالات',
        destinationLabel: 'فرع الحمرا - حلب',
        senderName: 'طارق منصور',
        reference: 'FUA-556301',
        status: ActivityStatus.rejected,
        submittedAt: anchor.subtract(const Duration(days: 2, hours: 21)),
        reviewStartedAt: anchor.subtract(const Duration(days: 2, hours: 20, minutes: 42)),
        decidedAt: anchor.subtract(const Duration(days: 2, hours: 20, minutes: 30)),
        staffNote: 'المبلغ في الإيصال لا يطابق المبلغ المُدخل.',
      ),
      ActivityDeposit(
        shortId: 'DP-9188',
        amount: Money.fromMinorString('5000000'),
        methodName: 'سيرياتيل كاش',
        destinationLabel: '0932 *** 418',
        senderName: 'ديمة الشامي',
        status: ActivityStatus.credited,
        submittedAt: anchor.subtract(const Duration(days: 3, hours: 6)),
        reviewStartedAt: anchor.subtract(const Duration(days: 3, hours: 5, minutes: 52)),
        decidedAt: anchor.subtract(const Duration(days: 3, hours: 5, minutes: 47)),
        settledAt: anchor.subtract(const Duration(days: 3, hours: 5, minutes: 46)),
        credited: Money.fromMinorString('5000000'),
      ),
      ActivityDeposit(
        shortId: 'DP-9044',
        amount: Money.fromMinorString('17500000'),
        methodName: 'MTN كاش',
        destinationLabel: '0947 *** 612',
        senderName: 'غيث الرفاعي',
        reference: 'MTN-7712049',
        status: ActivityStatus.credited,
        submittedAt: anchor.subtract(const Duration(days: 4, hours: 2)),
        reviewStartedAt: anchor.subtract(const Duration(days: 4, hours: 1, minutes: 50)),
        decidedAt: anchor.subtract(const Duration(days: 4, hours: 1, minutes: 44)),
        settledAt: anchor.subtract(const Duration(days: 4, hours: 1, minutes: 43)),
        credited: Money.fromMinorString('17150000'),
      ),
      ActivityDeposit(
        shortId: 'DP-8FD1',
        amount: Money.fromMinorString('2500000'),
        methodName: 'شام كاش',
        destinationLabel: '0955 *** 073',
        senderName: 'وسيم زيدان',
        reference: 'SHM-4388006',
        status: ActivityStatus.credited,
        submittedAt: anchor.subtract(const Duration(days: 5, hours: 9)),
        reviewStartedAt: anchor.subtract(const Duration(days: 5, hours: 8, minutes: 55)),
        decidedAt: anchor.subtract(const Duration(days: 5, hours: 8, minutes: 51)),
        settledAt: anchor.subtract(const Duration(days: 5, hours: 8, minutes: 50)),
        credited: Money.fromMinorString('2500000'),
      ),
      ActivityDeposit(
        shortId: 'DP-8E9C',
        amount: Money.fromMinorString('40000000'),
        methodName: 'بنك بيمو السعودي الفرنسي',
        destinationLabel: 'حساب 500 *** 129',
        senderName: 'هبة قنبر',
        reference: 'BMO-20260812-0117',
        status: ActivityStatus.credited,
        submittedAt: anchor.subtract(const Duration(days: 6, hours: 4)),
        reviewStartedAt: anchor.subtract(const Duration(days: 6, hours: 3, minutes: 30)),
        decidedAt: anchor.subtract(const Duration(days: 6, hours: 3, minutes: 12)),
        settledAt: anchor.subtract(const Duration(days: 6, hours: 3, minutes: 11)),
        credited: Money.fromMinorString('39600000'),
      ),
      ActivityDeposit(
        shortId: 'DP-8D20',
        amount: Money.fromMinorString('6000000'),
        methodName: 'الهرم للحوالات',
        destinationLabel: 'فرع الميدان - دمشق',
        senderName: 'فادي الجندي',
        reference: 'HRM-768842',
        status: ActivityStatus.expired,
        submittedAt: anchor.subtract(const Duration(days: 7, hours: 16)),
        decidedAt: anchor.subtract(const Duration(days: 7, hours: 4)),
        staffNote: 'انتهت مهلة الطلب قبل وصول الحوالة.',
      ),
      ActivityDeposit(
        shortId: 'DP-8C0B',
        amount: Money.fromMinorString('10000000'),
        methodName: 'سيرياتيل كاش',
        destinationLabel: '0932 *** 418',
        senderName: 'رهف الحسن',
        status: ActivityStatus.credited,
        submittedAt: anchor.subtract(const Duration(days: 9, hours: 1)),
        reviewStartedAt: anchor.subtract(const Duration(days: 9, minutes: 48)),
        decidedAt: anchor.subtract(const Duration(days: 9, minutes: 41)),
        settledAt: anchor.subtract(const Duration(days: 9, minutes: 40)),
        credited: Money.fromMinorString('9800000'),
      ),
      ActivityDeposit(
        shortId: 'DP-8AF5',
        amount: Money.fromMinorString('12500000'),
        methodName: 'USDT (TRC20)',
        destinationLabel: 'TQm9 *** 4vXe',
        senderName: 'خالد سلوم',
        reference: '0x77c3 *** 1de9',
        status: ActivityStatus.rejected,
        submittedAt: anchor.subtract(const Duration(days: 11, hours: 3)),
        reviewStartedAt: anchor.subtract(const Duration(days: 11, hours: 2, minutes: 40)),
        decidedAt: anchor.subtract(const Duration(days: 11, hours: 2, minutes: 20)),
        staffNote: 'الشبكة المستخدمة ليست TRC20؛ لا يمكن تأكيد الحوالة.',
      ),
      ActivityDeposit(
        shortId: 'DP-89A2',
        amount: Money.fromMinorString('5000000'),
        methodName: 'MTN كاش',
        destinationLabel: '0947 *** 612',
        senderName: 'مازن العقاد',
        reference: 'MTN-7690311',
        status: ActivityStatus.credited,
        submittedAt: anchor.subtract(const Duration(days: 14, hours: 8)),
        reviewStartedAt: anchor.subtract(const Duration(days: 14, hours: 7, minutes: 50)),
        decidedAt: anchor.subtract(const Duration(days: 14, hours: 7, minutes: 44)),
        settledAt: anchor.subtract(const Duration(days: 14, hours: 7, minutes: 43)),
        credited: Money.fromMinorString('4900000'),
      ),
      ActivityDeposit(
        shortId: 'DP-8811',
        amount: Money.fromMinorString('20000000'),
        methodName: 'بنك بيبلوس سوريا',
        destinationLabel: 'حساب 331 *** 907',
        senderName: 'سامر الحموي',
        reference: 'BYB-0088120',
        status: ActivityStatus.credited,
        submittedAt: anchor.subtract(const Duration(days: 18, hours: 5)),
        reviewStartedAt: anchor.subtract(const Duration(days: 18, hours: 4, minutes: 30)),
        decidedAt: anchor.subtract(const Duration(days: 18, hours: 4, minutes: 18)),
        settledAt: anchor.subtract(const Duration(days: 18, hours: 4, minutes: 17)),
        credited: Money.fromMinorString('19800000'),
      ),
      ActivityDeposit(
        shortId: 'DP-8642',
        amount: Money.fromMinorString('7500000'),
        methodName: 'شام كاش',
        destinationLabel: '0955 *** 073',
        senderName: 'مصطفى الحلبي',
        reference: 'SHM-4321995',
        status: ActivityStatus.credited,
        submittedAt: anchor.subtract(const Duration(days: 23, hours: 2)),
        reviewStartedAt: anchor.subtract(const Duration(days: 23, hours: 1, minutes: 52)),
        decidedAt: anchor.subtract(const Duration(days: 23, hours: 1, minutes: 47)),
        settledAt: anchor.subtract(const Duration(days: 23, hours: 1, minutes: 46)),
        credited: Money.fromMinorString('7500000'),
      ),
      ActivityDeposit(
        shortId: 'DP-8409',
        amount: Money.fromMinorString('35000000'),
        methodName: 'الفؤاد للحوالات',
        destinationLabel: 'فرع الحمرا - حلب',
        senderName: 'أحمد الخطيب',
        reference: 'FUA-540877',
        status: ActivityStatus.credited,
        submittedAt: anchor.subtract(const Duration(days: 29, hours: 6)),
        reviewStartedAt: anchor.subtract(const Duration(days: 29, hours: 5, minutes: 40)),
        decidedAt: anchor.subtract(const Duration(days: 29, hours: 5, minutes: 22)),
        settledAt: anchor.subtract(const Duration(days: 29, hours: 5, minutes: 21)),
        credited: Money.fromMinorString('34650000'),
      ),
    ];
  }
}

/// The demo-backed [ActivityRepository]: local paging, a short artificial
/// latency so the skeleton is actually seen, and an opt-in failure switch so
/// the error branch is reachable without a network.
///
/// The anchor is captured ONCE per instance, so ages do not drift between
/// page 1 and page 3 and `shortId` stays a stable identity across slices.
class ActivityDemoRepository implements ActivityRepository {
  ActivityDemoRepository({
    DateTime? anchor,
    this.latency = const Duration(milliseconds: 420),
    this.failLoads = false,
  }) : _rows = ActivityDemoData.feed(now: anchor);

  /// How long a "request" takes. Zero in tests.
  final Duration latency;

  /// When true every call throws [ActivityUnavailable], which is how the error
  /// state is exercised.
  final bool failLoads;

  final List<ActivityDeposit> _rows;

  @override
  Future<ActivityPage> page({
    required ActivityFilter filter,
    required int offset,
    required int limit,
  }) async {
    await Future<void>.delayed(latency);
    if (failLoads) {
      throw const ActivityUnavailable('ACTIVITY_DEMO_UNAVAILABLE');
    }
    final List<ActivityDeposit> matching = <ActivityDeposit>[
      for (final ActivityDeposit row in _rows)
        if (filter.matches(row.status)) row,
    ];
    final int start = offset < 0 ? 0 : offset;
    if (start >= matching.length) {
      return ActivityPage(
        items: const <ActivityDeposit>[],
        hasMore: false,
        total: matching.length,
      );
    }
    final int end =
        start + limit > matching.length ? matching.length : start + limit;
    return ActivityPage(
      items: List<ActivityDeposit>.unmodifiable(matching.sublist(start, end)),
      hasMore: end < matching.length,
      total: matching.length,
    );
  }

  @override
  Future<ActivitySummary> summary() async {
    await Future<void>.delayed(latency);
    if (failLoads) {
      throw const ActivityUnavailable('ACTIVITY_DEMO_UNAVAILABLE');
    }
    Money credited = Money.zero();
    int open = 0;
    for (final ActivityDeposit row in _rows) {
      final Money? landed = row.credited;
      if (landed != null) {
        credited = credited + landed;
      }
      if (row.status.isOpen) {
        open += 1;
      }
    }
    return ActivitySummary(
      totalCredited: credited,
      openCount: open,
      totalCount: _rows.length,
    );
  }
}
