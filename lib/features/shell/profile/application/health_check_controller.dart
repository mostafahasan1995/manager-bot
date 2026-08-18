import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/api/api_client.dart';
import 'package:manager_bot/core/errors/api_error.dart';

/// What the last backend probe knows.
enum HealthPhase {
  /// No probe has finished yet and none is running.
  idle,

  /// A probe is in flight.
  checking,

  /// The last probe answered.
  online,

  /// The last probe failed, timed out or could not reach the host.
  offline,
}

/// The result of the ONE real request the profile tab makes.
///
/// Immutable and cheap to compare, so a rebuild costs nothing while the state
/// is steady.
class HealthProbeState {
  const HealthProbeState({
    this.phase = HealthPhase.idle,
    this.latency,
    this.checkedAt,
    this.failure,
  });

  final HealthPhase phase;

  /// Round trip of the last COMPLETED probe, success or failure.
  final Duration? latency;

  /// When that probe finished. Local time, like every timestamp in this app.
  final DateTime? checkedAt;

  /// Why the last probe failed. Non-null only when [phase] is
  /// [HealthPhase.offline].
  final ApiError? failure;

  /// True while a probe is in flight.
  bool get isBusy => phase == HealthPhase.checking;

  /// Latency in whole milliseconds, for `s.connectionLatencyMs`.
  int? get latencyMs => latency?.inMilliseconds;
}

/// Probes the PUBLIC liveness endpoint through the existing [ApiClient].
///
/// `/health/live` is deliberately unversioned and needs no bearer token, which
/// is why this screen can talk to the real backend while every other endpoint
/// stays out of reach. The first probe runs as soon as the provider is first
/// watched; after that it only runs when the player asks.
class HealthCheckController extends Notifier<HealthProbeState> {
  /// The public liveness route. NO `/v1` prefix - health routes are
  /// deliberately unversioned on this backend.
  static const String healthLivePath = '/health/live';

  @override
  HealthProbeState build() {
    // Runs after this build returns, so the first frame paints "checking"
    // rather than blocking on a socket.
    unawaited(Future<void>.microtask(check));
    return const HealthProbeState();
  }

  /// Runs one probe. Concurrent calls are ignored, so hammering the re-check
  /// button cannot queue a dozen requests.
  Future<void> check() async {
    if (state.phase == HealthPhase.checking) {
      return;
    }
    state = const HealthProbeState(phase: HealthPhase.checking);
    final Stopwatch watch = Stopwatch();
    watch.start();
    try {
      await ref.read(apiClientProvider).get(
            healthLivePath,
            authenticated: false,
          );
      watch.stop();
      state = HealthProbeState(
        phase: HealthPhase.online,
        latency: watch.elapsed,
        checkedAt: DateTime.now(),
      );
    } on ApiError catch (error) {
      // ApiClient guarantees this is the only thing that can escape.
      watch.stop();
      state = HealthProbeState(
        phase: HealthPhase.offline,
        latency: watch.elapsed,
        checkedAt: DateTime.now(),
        failure: error,
      );
    }
  }
}

/// The backend-health state the profile tab shows.
final NotifierProvider<HealthCheckController, HealthProbeState>
    healthCheckControllerProvider =
    NotifierProvider<HealthCheckController, HealthProbeState>(
  HealthCheckController.new,
);
