/// Screen state for the الرئيسية destination.
///
/// Everything the home tab remembers between rebuilds lives here rather than in
/// a `State`: which demo shape to render, whether the balance is masked, which
/// promo page is showing, and the result of the backend health probe. The
/// widgets stay dumb, and a pull-to-refresh is one `ref.invalidate`.
///
/// This is the ONLY file in the feature that names `HomeDemoData`. Swapping the
/// demo source for a live repository is a change to
/// [homeSnapshotProvider] alone.
library;

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/api/api_client.dart';
import 'package:manager_bot/core/errors/api_error.dart';
import 'package:manager_bot/core/ui/connection_pill.dart';
import 'package:manager_bot/features/shell/home/data/home_demo_data.dart';
import 'package:manager_bot/features/shell/home/data/home_models.dart';

/// Unversioned health route. The backend has no global prefix and the health
/// endpoints deliberately sit outside `/v1`.
const String kHomeHealthPath = '/health/live';

/// Holds the demo shape the home tab renders.
///
/// Defaults to [HomeDemoMode.content]. A widget test overrides or drives this
/// to reach the empty and error layouts, which must stay correct for the day
/// the API is wired in.
class HomeDemoModeController extends Notifier<HomeDemoMode> {
  @override
  HomeDemoMode build() => HomeDemoMode.content;

  void select(HomeDemoMode mode) {
    state = mode;
  }
}

final NotifierProvider<HomeDemoModeController, HomeDemoMode>
    homeDemoModeProvider =
    NotifierProvider<HomeDemoModeController, HomeDemoMode>(
  HomeDemoModeController.new,
);

/// Everything the home tab paints, as one `AsyncValue`.
///
/// The artificial delay is what gives the skeleton something to do; the live
/// repository will supply a real one.
final FutureProvider<HomeSnapshot> homeSnapshotProvider =
    FutureProvider<HomeSnapshot>((ref) async {
  final HomeDemoMode mode = ref.watch(homeDemoModeProvider);
  await Future<void>.delayed(HomeDemoData.loadDelay);
  return switch (mode) {
    HomeDemoMode.content => HomeDemoData.snapshot(),
    HomeDemoMode.empty => HomeDemoData.emptySnapshot(),
    HomeDemoMode.unavailable => throw const ApiNetworkError(message: ''),
  };
});

/// Whether the balance digits are masked.
///
/// `BalanceHero` owns the eye button's own state; this provider is what makes
/// the choice survive a rebuild, seeded back in through `initiallyHidden`.
class HomeBalanceHiddenController extends Notifier<bool> {
  @override
  bool build() => false;

  void setHidden(bool hidden) {
    state = hidden;
  }

  void toggle() {
    state = !state;
  }
}

final NotifierProvider<HomeBalanceHiddenController, bool>
    homeBalanceHiddenProvider =
    NotifierProvider<HomeBalanceHiddenController, bool>(
  HomeBalanceHiddenController.new,
);

/// Which announcement page is showing.
///
/// Auto-advance is deliberately OFF - a carousel that moves on its own fights
/// the reader and costs a timer - so this only ever changes from a swipe.
class HomePromoIndexController extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) {
    state = index < 0 ? 0 : index;
  }
}

final NotifierProvider<HomePromoIndexController, int> homePromoIndexProvider =
    NotifierProvider<HomePromoIndexController, int>(
  HomePromoIndexController.new,
);

/// What the last `/health/live` probe found.
///
/// The only network call this feature makes. It is unauthenticated by design:
/// there is no session, and the pill exists so a player can tell "the app is
/// quiet" from "the server is down".
@immutable
class HomeConnection {
  const HomeConnection({required this.phase, this.latencyMs});

  const HomeConnection.checking()
      : phase = ConnectionPhase.checking,
        latencyMs = null;

  const HomeConnection.offline()
      : phase = ConnectionPhase.offline,
        latencyMs = null;

  const HomeConnection.online(this.latencyMs) : phase = ConnectionPhase.online;

  final ConnectionPhase phase;

  /// Round-trip in milliseconds, null unless [phase] is online.
  final int? latencyMs;

  @override
  bool operator ==(Object other) =>
      other is HomeConnection &&
      other.phase == phase &&
      other.latencyMs == latencyMs;

  @override
  int get hashCode => Object.hash(phase, latencyMs);

  @override
  String toString() => 'HomeConnection(${phase.name}, ${latencyMs}ms)';
}

/// Probes the backend once per invalidation. Never throws: an unreachable
/// server IS the answer, so the pill simply turns red.
final FutureProvider<HomeConnection> homeConnectionProvider =
    FutureProvider<HomeConnection>((ref) async {
  final ApiClient client = ref.watch(apiClientProvider);
  final Stopwatch clock = Stopwatch();
  clock.start();
  try {
    await client.get(kHomeHealthPath, authenticated: false);
    clock.stop();
    return HomeConnection.online(clock.elapsedMilliseconds);
  } on Object {
    clock.stop();
    return const HomeConnection.offline();
  }
});
