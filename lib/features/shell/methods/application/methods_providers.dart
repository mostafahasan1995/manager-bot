/// Screen state for the طرق الدفع destination: the catalogue, the filter and
/// the currently opened method.
///
/// Nothing here talks to the network. `methodsSourceProvider` is the ONE seam
/// to the outside world - override it and the whole destination runs against
/// something else, which is exactly how the live repository will arrive.
library;

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/features/shell/methods/data/payment_method_demo_models.dart';
import 'package:manager_bot/features/shell/methods/data/payment_methods_demo_data.dart';

/// What the player has narrowed the list down to.
@immutable
class MethodsFilter {
  const MethodsFilter({this.rail, this.availableOnly = false});

  /// Null means "every rail".
  final MethodRail? rail;

  /// Hides anything a top-up cannot be started on right now.
  final bool availableOnly;

  bool get isUnfiltered => rail == null && !availableOnly;

  /// Explicit setters rather than `copyWith`, because null here means "clear
  /// the rail filter" and a `copyWith` could never express that.
  MethodsFilter withRail(MethodRail? value) =>
      MethodsFilter(rail: value, availableOnly: availableOnly);

  MethodsFilter withAvailableOnly(bool value) =>
      MethodsFilter(rail: rail, availableOnly: value);

  /// True when [method] survives this filter.
  bool allows(PlayerPaymentMethod method) =>
      method.matchesRail(rail) && (!availableOnly || method.acceptsTopUp);

  @override
  bool operator ==(Object other) =>
      other is MethodsFilter &&
      other.rail == rail &&
      other.availableOnly == availableOnly;

  @override
  int get hashCode => Object.hash(rail, availableOnly);

  @override
  String toString() =>
      'MethodsFilter(rail: ${rail?.name}, availableOnly: $availableOnly)';
}

/// Holds the filter outside the widget's `State`, so scrolling away or opening
/// a detail sheet never silently resets it.
class MethodsFilterController extends Notifier<MethodsFilter> {
  @override
  MethodsFilter build() => const MethodsFilter();

  /// Passing the rail that is already selected clears it, which is what a
  /// player expects from a chip they tap twice.
  void toggleRail(MethodRail rail) {
    state = state.withRail(state.rail == rail ? null : rail);
  }

  void setRail(MethodRail? rail) {
    state = state.withRail(rail);
  }

  void setAvailableOnly(bool value) {
    state = state.withAvailableOnly(value);
  }

  void toggleAvailableOnly() {
    state = state.withAvailableOnly(!state.availableOnly);
  }

  void clear() {
    state = const MethodsFilter();
  }
}

final NotifierProvider<MethodsFilterController, MethodsFilter>
    methodsFilterProvider =
    NotifierProvider<MethodsFilterController, MethodsFilter>(
  MethodsFilterController.new,
);

/// The only seam to the data source. Override this in a test - or replace its
/// body with the live repository - and nothing else in the feature changes.
final Provider<PaymentMethodsDemoSource> methodsSourceProvider =
    Provider<PaymentMethodsDemoSource>(
  (ref) => const PaymentMethodsDemoSource(),
);

/// The raw catalogue, unfiltered. Invalidate it to refresh.
final FutureProvider<List<PlayerPaymentMethod>> methodsCatalogProvider =
    FutureProvider<List<PlayerPaymentMethod>>(
  (ref) => ref.watch(methodsSourceProvider).load(),
);

/// The catalogue split into the sections the screen actually paints.
///
/// Pure and synchronous, so it can be unit-tested without a widget tree.
@immutable
class MethodsBoard {
  const MethodsBoard({
    required this.featured,
    required this.open,
    required this.paused,
    required this.availableCount,
    required this.totalCount,
    required this.isFiltered,
  });

  /// Derives the board from a catalogue and a filter.
  ///
  /// The featured card is the popular method, but ONLY while a top-up can
  /// actually be started on it: promoting a paused rail into the hero slot
  /// would be the worst possible place to disappoint a player.
  factory MethodsBoard.from({
    required List<PlayerPaymentMethod> catalogue,
    required MethodsFilter filter,
  }) {
    final List<PlayerPaymentMethod> visible = catalogue
        .where((PlayerPaymentMethod method) => filter.allows(method))
        .toList(growable: false);

    PlayerPaymentMethod? hero;
    for (final PlayerPaymentMethod method in visible) {
      if (method.popular && method.acceptsTopUp) {
        hero = method;
        break;
      }
    }

    final List<PlayerPaymentMethod> open = <PlayerPaymentMethod>[];
    final List<PlayerPaymentMethod> paused = <PlayerPaymentMethod>[];
    for (final PlayerPaymentMethod method in visible) {
      if (identical(method, hero)) {
        continue;
      }
      if (method.acceptsTopUp) {
        open.add(method);
      } else {
        paused.add(method);
      }
    }

    return MethodsBoard(
      featured: hero,
      open: List<PlayerPaymentMethod>.unmodifiable(open),
      paused: List<PlayerPaymentMethod>.unmodifiable(paused),
      availableCount: catalogue
          .where((PlayerPaymentMethod method) => method.acceptsTopUp)
          .length,
      totalCount: catalogue.length,
      isFiltered: !filter.isUnfiltered,
    );
  }

  /// The hero card, or null when nothing qualifies.
  final PlayerPaymentMethod? featured;

  /// Everything else a top-up can start on.
  final List<PlayerPaymentMethod> open;

  /// Temporarily unavailable rails, kept visible but visually demoted.
  final List<PlayerPaymentMethod> paused;

  /// How many rails in the WHOLE catalogue accept a top-up right now.
  final int availableCount;

  /// Size of the whole catalogue, filter ignored.
  final int totalCount;

  /// True when a filter is narrowing the list.
  final bool isFiltered;

  /// True when the filter matched nothing.
  bool get isEmpty => featured == null && open.isEmpty && paused.isEmpty;

  /// True when the catalogue itself came back empty.
  bool get catalogueIsEmpty => totalCount == 0;
}

/// The board, carrying loading and error through unchanged.
final Provider<AsyncValue<MethodsBoard>> methodsBoardProvider =
    Provider<AsyncValue<MethodsBoard>>((ref) {
  final MethodsFilter filter = ref.watch(methodsFilterProvider);
  return ref.watch(methodsCatalogProvider).whenData(
        (List<PlayerPaymentMethod> catalogue) =>
            MethodsBoard.from(catalogue: catalogue, filter: filter),
      );
});

/// Id of the method whose detail sheet is open, or was opened last.
///
/// Kept in Riverpod rather than in the screen so the card stays highlighted
/// while the sheet is up and settles back correctly afterwards.
class MethodsSelectionController extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String id) {
    state = id;
  }

  void clear() {
    state = null;
  }
}

final NotifierProvider<MethodsSelectionController, String?>
    methodsSelectionProvider =
    NotifierProvider<MethodsSelectionController, String?>(
  MethodsSelectionController.new,
);
