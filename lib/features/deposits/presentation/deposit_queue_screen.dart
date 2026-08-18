import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/theme/app_theme.dart';
import 'package:manager_bot/core/widgets/widgets.dart';
import 'package:manager_bot/features/deposits/application/deposit_permissions.dart';
import 'package:manager_bot/features/deposits/application/deposit_queue_controller.dart';
import 'package:manager_bot/features/deposits/data/admin_deposit_view.dart';
import 'package:manager_bot/features/deposits/data/deposit_enums.dart';
import 'package:manager_bot/features/deposits/data/deposit_query.dart';
import 'package:manager_bot/features/deposits/data/deposit_repository.dart';
import 'package:manager_bot/features/deposits/data/deposit_results.dart';
import 'package:manager_bot/features/deposits/presentation/widgets/deposit_filter_sheet.dart';
import 'package:manager_bot/features/deposits/presentation/widgets/deposit_queue_row.dart';
import 'package:manager_bot/features/deposits/presentation/widgets/permission_denied_view.dart';
import 'package:manager_bot/features/home/presentation/settings_menu_button.dart';
import 'package:manager_bot/router/app_router.dart';

/// The review queue - the primary screen of the console.
///
/// Cursor-paginated with infinite scroll, pull to refresh, a full filter sheet
/// and a sort toggle. Every state is handled: loading, empty, error-with-retry
/// and permission-denied.
class DepositQueueScreen extends ConsumerStatefulWidget {
  const DepositQueueScreen({super.key});

  @override
  ConsumerState<DepositQueueScreen> createState() => _DepositQueueScreenState();
}

class _DepositQueueScreenState extends ConsumerState<DepositQueueScreen> {
  final ScrollController _scrollController = ScrollController();

  /// One clock for the whole list, ticked so ages and claim countdowns stay
  /// honest without every row owning a timer.
  Timer? _clock;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _clock = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        if (mounted) {
          setState(() => _now = DateTime.now());
        }
      },
    );
  }

  @override
  void dispose() {
    _clock?.cancel();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final double remaining = _scrollController.position.maxScrollExtent -
        _scrollController.position.pixels;
    if (remaining < 400) {
      unawaited(ref.read(depositQueueProvider.notifier).loadMore());
    }
  }

  Future<void> _refresh() async {
    setState(() => _now = DateTime.now());
    await ref.read(depositQueueProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final DepositPermissions permissions = ref.watch(depositPermissionsProvider);
    final DepositQueueFilter filter = ref.watch(depositFilterProvider);
    final AsyncValue<DepositQueueState> queue = ref.watch(depositQueueProvider);

    // A refresh failure keeps the stale rows on screen and speaks up once.
    ref.listen<AsyncValue<DepositQueueState>>(
      depositQueueProvider,
      (AsyncValue<DepositQueueState>? previous, AsyncValue<DepositQueueState> next) {
        final Object? error = next.valueOrNull?.refreshError;
        if (error == null) {
          return;
        }
        final ErrorPresentation presentation = ErrorPresentation.of(error, s);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.queueRefreshFailed(message: presentation.message)),
          ),
        );
        ref.read(depositQueueProvider.notifier).acknowledgeRefreshError();
      },
    );

    if (!permissions.canViewQueue) {
      return Scaffold(
        appBar: AppBar(title: Text(s.depositQueueTitle)),
        body: PermissionDeniedView(
          title: s.queueNoAccessTitle,
          message: s.queueNoAccessMessage,
          role: permissions.role,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(s.depositQueueTitle),
        actions: <Widget>[
          IconButton(
            tooltip: s.filterLabel,
            onPressed: () => unawaited(_openFilterSheet(filter)),
            icon: _FilterIcon(activeCount: filter.activeCount),
          ),
          PopupMenuButton<DepositSort>(
            tooltip: s.sortTooltip,
            icon: const Icon(Icons.swap_vert_rounded),
            initialValue: filter.sort,
            onSelected: (DepositSort sort) =>
                ref.read(depositFilterProvider.notifier).setSort(sort),
            itemBuilder: (BuildContext context) => DepositSort.values
                .map(
                  (DepositSort sort) => PopupMenuItem<DepositSort>(
                    value: sort,
                    child: Text(sort.label(s)),
                  ),
                )
                .toList(growable: false),
          ),
          PopupMenuButton<_QueueMenuAction>(
            tooltip: s.moreTooltip,
            onSelected: _onMenuAction,
            itemBuilder: (BuildContext context) => <PopupMenuEntry<_QueueMenuAction>>[
              PopupMenuItem<_QueueMenuAction>(
                value: _QueueMenuAction.refresh,
                child: Text(s.refresh),
              ),
              if (filter.isActive)
                PopupMenuItem<_QueueMenuAction>(
                  value: _QueueMenuAction.clearFilters,
                  child: Text(s.clearFiltersAction),
                ),
              if (permissions.canRunSweep)
                PopupMenuItem<_QueueMenuAction>(
                  value: _QueueMenuAction.sweep,
                  child: Text(s.runSweepAction),
                ),
            ],
          ),
          // Always the LAST action, so the gear sits in the same corner on
          // every top-level screen.
          const SettingsMenuButton(),
        ],
        bottom: filter.isActive
            ? _FilterSummaryBar(
                filter: filter,
                onClear: () => ref.read(depositFilterProvider.notifier).reset(),
              )
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final Widget content = AsyncValueView<DepositQueueState>(
              value: queue,
              onRetry: () => ref.invalidate(depositQueueProvider),
              isEmpty: (DepositQueueState state) => state.isEmpty,
              emptyTitle:
                  filter.isActive ? s.queueNoMatchesTitle : s.queueEmptyTitle,
              emptyMessage: filter.isActive
                  ? s.queueNoMatchesMessage
                  : s.queueEmptyMessage,
              emptyIcon: filter.isActive
                  ? Icons.filter_alt_off_outlined
                  : Icons.inbox_outlined,
              loadingLabel: s.loadingQueue,
              builder: _buildList,
            );

            final bool hasRows = queue.valueOrNull?.items.isNotEmpty ?? false;
            if (hasRows) {
              return content;
            }
            // Keep pull-to-refresh alive on the empty, loading and error
            // states, which are not scrollable on their own.
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: content,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, DepositQueueState state) {
    final bool hasFooter = state.isLoadingMore ||
        state.loadMoreError != null ||
        state.pagingBlockedBySort ||
        (!state.hasMore && state.items.isNotEmpty);

    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: state.items.length + (hasFooter ? 1 : 0),
      separatorBuilder: (BuildContext context, int index) =>
          const Divider(height: 1),
      itemBuilder: (BuildContext context, int index) {
        if (index >= state.items.length) {
          return _QueueFooter(
            state: state,
            onRetry: () {
              ref.read(depositQueueProvider.notifier).retryLoadMore();
              unawaited(ref.read(depositQueueProvider.notifier).loadMore());
            },
          );
        }
        final AdminDepositView deposit = state.items[index];
        return DepositQueueRow(
          deposit: deposit,
          now: _now,
          onTap: () => context.pushNamed(
            AppRoute.depositDetail,
            pathParameters: <String, String>{
              AppRoute.shortIdParam: deposit.shortId,
            },
          ),
        );
      },
    );
  }

  Future<void> _openFilterSheet(DepositQueueFilter current) async {
    final DepositQueueFilter? updated =
        await DepositFilterSheet.show(context, initial: current);
    if (updated == null || !mounted) {
      return;
    }
    ref.read(depositFilterProvider.notifier).apply(updated);
  }

  void _onMenuAction(_QueueMenuAction action) {
    switch (action) {
      case _QueueMenuAction.refresh:
        unawaited(_refresh());
      case _QueueMenuAction.clearFilters:
        ref.read(depositFilterProvider.notifier).reset();
      case _QueueMenuAction.sweep:
        unawaited(_runSweep());
    }
  }

  /// Runs the expiry / stale-claim / stuck-credit sweep on demand.
  ///
  /// Bounded to 100 rows per phase server-side, so the result says whether it
  /// is worth running again.
  Future<void> _runSweep() async {
    final AppStrings s = context.s;
    final ConfirmActionResult? confirmation = await ConfirmActionSheet.show(
      context,
      title: s.sweepConfirmTitle,
      message: s.sweepConfirmMessage,
      confirmLabel: s.sweepConfirmButton,
      cancelLabel: s.cancel,
    );
    if (!(confirmation?.confirmed ?? false)) {
      return;
    }
    if (!mounted) {
      return;
    }

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      final SweepReport report =
          await ref.read(depositRepositoryProvider).sweep();
      await ref.read(depositQueueProvider.notifier).refresh();
      messenger.showSnackBar(SnackBar(content: Text(report.summary(s))));
    } on Object catch (error) {
      final ErrorPresentation presentation = ErrorPresentation.of(error, s);
      messenger.showSnackBar(
        SnackBar(content: Text(s.sweepFailed(message: presentation.message))),
      );
    }
  }
}

enum _QueueMenuAction { refresh, clearFilters, sweep }

/// Filter icon with a count badge, so an admin can never wonder why the queue
/// looks short.
class _FilterIcon extends StatelessWidget {
  const _FilterIcon({required this.activeCount});

  final int activeCount;

  @override
  Widget build(BuildContext context) {
    if (activeCount == 0) {
      return const Icon(Icons.filter_list_rounded);
    }
    final ThemeData theme = Theme.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        const Icon(Icons.filter_list_rounded),
        // Directional so the badge hugs the trailing corner in Arabic too.
        PositionedDirectional(
          end: -6,
          top: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$activeCount',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A one-line reminder of what is being filtered, with a clear-all.
class _FilterSummaryBar extends StatelessWidget implements PreferredSizeWidget {
  const _FilterSummaryBar({required this.filter, required this.onClear});

  final DepositQueueFilter filter;
  final VoidCallback onClear;

  @override
  Size get preferredSize => const Size.fromHeight(40);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppStrings s = context.s;
    return SizedBox(
      height: 40,
      child: Row(
        children: <Widget>[
          const SizedBox(width: 16),
          Icon(
            Icons.filter_alt_outlined,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _describe(filter, s),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(onPressed: onClear, child: Text(s.clearButton)),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  static String _describe(DepositQueueFilter filter, AppStrings s) {
    final List<String> parts = <String>[];
    if (filter.statuses.isNotEmpty) {
      parts.add(
        filter.statuses.length <= 2
            ? filter.statuses
                .map((DepositStatus status) => status.label(s))
                .join(s.listSeparator)
            : s.filterSummaryStatuses(count: filter.statuses.length),
      );
    }
    final String? shortId = filter.shortId;
    if (shortId != null) {
      parts.add(s.filterSummaryShortId(shortId: shortId));
    }
    final String? reference = filter.externalReference;
    if (reference != null) {
      parts.add(s.filterSummaryExternalReference(reference: reference));
    }
    if (filter.minAmount != null || filter.maxAmount != null) {
      // Money keeps its Western digits and is never routed through the
      // catalogue's number handling.
      final String min = filter.minAmount?.format(withCurrency: false) ??
          s.filterSummaryAny;
      final String max = filter.maxAmount?.format(withCurrency: false) ??
          s.filterSummaryAny;
      parts.add(s.filterSummaryAmountRange(min: min, max: max));
    }
    if (filter.createdFrom != null || filter.createdTo != null) {
      parts.add(s.filterSummaryDateRange);
    }
    if (filter.playerId != null) {
      parts.add(s.filterSummaryOnePlayer);
    }
    if (filter.paymentMethodId != null) {
      parts.add(s.filterSummaryOneMethod);
    }
    if (filter.unclaimedOnly) {
      parts.add(s.filterSummaryUnclaimedOnly);
    }
    return parts.isEmpty ? s.filterSummaryFallback : parts.join(' - ');
  }
}

/// End-of-list affordance: spinner, inline retry, "that's everything", or the
/// explanation for why an amount sort refuses to page.
class _QueueFooter extends StatelessWidget {
  const _QueueFooter({required this.state, required this.onRetry});

  final DepositQueueState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppStrings s = context.s;

    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    final Object? error = state.loadMoreError;
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ErrorStateView(error: error, onRetry: onRetry, compact: true),
      );
    }

    if (state.pagingBlockedBySort) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          children: <Widget>[
            Icon(
              Icons.info_outline,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              s.queuePagingBlockedBySort(sort: state.filter.sort.label(s)),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
      child: Center(
        child: Text(
          s.queueLoadedCount(count: state.items.length),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontFeatures: AppTheme.numericFeatures,
          ),
        ),
      ),
    );
  }
}
