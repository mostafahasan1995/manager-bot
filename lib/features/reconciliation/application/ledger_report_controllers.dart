import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/logging/app_logger.dart';
import 'package:manager_bot/features/reconciliation/data/ledger_invariant_report.dart';
import 'package:manager_bot/features/reconciliation/data/rail_ageing_report.dart';
import 'package:manager_bot/features/reconciliation/data/reconciliation_repository.dart';

/// `GET /rail-ageing`.
///
/// A plain read, so it may load on first watch. It runs a live raw-SQL
/// aggregate with no cache, which is why nothing polls it - refreshing is an
/// explicit gesture.
final FutureProvider<RailAgeingReport> railAgeingReportProvider =
    FutureProvider<RailAgeingReport>(
  (ref) => ref.watch(reconciliationRepositoryProvider).railAgeing(),
);

/// An invariant sweep plus the local clock time it finished at.
class InvariantRun {
  const InvariantRun({required this.report, required this.ranAt});

  final LedgerInvariantReport report;
  final DateTime ranAt;
}

/// `POST /invariants/run`.
///
/// Never runs on build: it is a POST that repairs the I3 cache and persists a
/// `LEDGER_IMBALANCE` break for every violation, and it does three full ledger
/// aggregates in one transaction. Opening a tab must not trigger that; a human
/// asks for it.
class LedgerInvariantController extends AsyncNotifier<InvariantRun?> {
  bool _running = false;

  @override
  InvariantRun? build() => null;

  bool get isRunning => _running;

  Future<void> run() async {
    if (_running) {
      return;
    }
    _running = true;
    state = const AsyncValue<InvariantRun?>.loading().copyWithPrevious(state);
    state = await AsyncValue.guard<InvariantRun?>(() async {
      final LedgerInvariantReport report =
          await ref.read(reconciliationRepositoryProvider).runInvariants();
      if (!report.isHealthy) {
        AppLogger.warn(
          'Ledger invariants: ${report.violations.length} violation(s)'
          '${report.truncated ? ' (truncated at the row cap)' : ''}',
          scope: 'reconciliation',
        );
      }
      return InvariantRun(report: report, ranAt: DateTime.now());
    });
    _running = false;
  }

  void clear() {
    state = const AsyncValue<InvariantRun?>.data(null);
  }
}

final AsyncNotifierProvider<LedgerInvariantController, InvariantRun?>
    ledgerInvariantProvider =
    AsyncNotifierProvider<LedgerInvariantController, InvariantRun?>(
  LedgerInvariantController.new,
);
