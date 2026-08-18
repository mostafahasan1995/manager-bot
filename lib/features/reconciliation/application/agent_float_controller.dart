import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/logging/app_logger.dart';
import 'package:manager_bot/features/reconciliation/data/float_sync_result.dart';
import 'package:manager_bot/features/reconciliation/data/reconciliation_repository.dart';

/// A float reading plus the local clock time it was taken at.
///
/// The endpoint returns no timestamp of its own, and "how old is this number"
/// is the first question anyone asks of a float comparison, so the moment of
/// the read is recorded here rather than invented inside the parser.
class AgentFloatSnapshot {
  const AgentFloatSnapshot({required this.result, required this.readAt});

  final FloatSyncResult result;
  final DateTime readAt;

  Duration ageFrom(DateTime now) => now.difference(readAt);
}

/// Agent float panel state.
///
/// The comparison is a POST with a side effect (it can open or refresh an
/// `AGENT_FLOAT_MISMATCH` break), so it is NEVER run automatically on build -
/// an admin opening a tab must not write to the break table. The initial state
/// is deliberately "no reading yet".
class AgentFloatController extends AsyncNotifier<AgentFloatSnapshot?> {
  bool _running = false;

  @override
  AgentFloatSnapshot? build() => null;

  bool get isRunning => _running;

  /// Runs `POST /agent-float/sync`.
  ///
  /// A failed Ichancy read is NOT an error here: it comes back as a 200 whose
  /// ichancy/delta/breakId are null, which the UI renders as "one side only".
  Future<void> sync() async {
    if (_running) {
      return;
    }
    _running = true;
    state = const AsyncValue<AgentFloatSnapshot?>.loading()
        .copyWithPrevious(state);
    state = await AsyncValue.guard<AgentFloatSnapshot?>(() async {
      final FloatSyncResult result = await ref
          .read(reconciliationRepositoryProvider)
          .syncAgentFloat();
      AppLogger.info(
        'Agent float ${result.currencyCode}: ledger=${result.ledger.toMinorString()} '
        'ichancy=${result.ichancy?.toMinorString() ?? 'unavailable'} '
        'delta=${result.delta?.toMinorString() ?? 'n/a'} '
        'break=${result.breakId ?? 'none'}',
        scope: 'reconciliation',
      );
      return AgentFloatSnapshot(result: result, readAt: DateTime.now());
    });
    _running = false;
  }

  /// Drops the reading without touching the server.
  void clear() {
    state = const AsyncValue<AgentFloatSnapshot?>.data(null);
  }
}

final AsyncNotifierProvider<AgentFloatController, AgentFloatSnapshot?>
    agentFloatProvider =
    AsyncNotifierProvider<AgentFloatController, AgentFloatSnapshot?>(
  AgentFloatController.new,
);
