import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/auth/roles.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/widgets/widgets.dart';
import 'package:manager_bot/features/admin_users/application/admin_directory_controller.dart';
import 'package:manager_bot/features/admin_users/application/admin_user_mutation_controller.dart';
import 'package:manager_bot/features/admin_users/application/admin_user_policy.dart';
import 'package:manager_bot/features/admin_users/application/admin_users_providers.dart';
import 'package:manager_bot/features/admin_users/data/admin_user.dart';
import 'package:manager_bot/features/admin_users/presentation/admin_user_detail_screen.dart';
import 'package:manager_bot/features/admin_users/presentation/admin_user_form_screen.dart';
import 'package:manager_bot/features/admin_users/presentation/widgets/admin_feedback.dart';
import 'package:manager_bot/features/admin_users/presentation/widgets/admin_labels.dart';
import 'package:manager_bot/features/admin_users/presentation/widgets/admin_user_tile.dart';
import 'package:manager_bot/features/admin_users/presentation/widgets/permission_denied_view.dart';
import 'package:manager_bot/features/admin_users/presentation/widgets/role_selector.dart';

/// The staff directory.
///
/// Reachable by SUPER_ADMIN and FINANCE_ADMIN; only SUPER_ADMIN sees the write
/// controls, because creating an administrator or changing a role is the one
/// operation that can grant somebody the power to move money.
///
/// Routed as `AppRoute.adminUsers` (`/settings/admin-users`).
class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final TextEditingController _search = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) {
      return;
    }
    final ScrollPosition position = _scroll.position;
    if (position.pixels >= position.maxScrollExtent - 320) {
      unawaited(ref.read(adminDirectoryProvider.notifier).loadMore());
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final AdminActionGate viewGate = ref.watch(adminDirectoryGateProvider);
    final AdminActionGate manageGate = ref.watch(adminManageGateProvider);
    final AdminRole? role = ref.watch(adminActorRoleProvider);

    _listenToMutations();

    return Scaffold(
      appBar: AppBar(
        title: Text(s.auScreenTitle),
        actions: <Widget>[
          if (viewGate.isAllowed)
            IconButton(
              tooltip: s.refresh,
              icon: const Icon(Icons.refresh),
              onPressed: () => unawaited(
                ref.read(adminDirectoryProvider.notifier).refresh(),
              ),
            ),
        ],
      ),
      floatingActionButton: !viewGate.isAllowed || manageGate.isBlocked
          ? null
          : FloatingActionButton.extended(
              onPressed: () => unawaited(_openCreateForm()),
              icon: const Icon(Icons.person_add_alt_1),
              label: Text(s.auAddButton),
            ),
      body: viewGate.isBlocked
          ? PermissionDeniedView(gate: viewGate, currentRole: role)
          : _DirectoryBody(
              search: _search,
              scroll: _scroll,
              onOpen: _openDetail,
            ),
    );
  }

  /// Surfaces the outcome of every write started from this screen or from the
  /// forms it pushes. Doing it here means a success snackbar survives the form
  /// popping itself.
  void _listenToMutations() {
    ref.listen<AdminMutationState>(adminUserMutationProvider,
        (AdminMutationState? previous, AdminMutationState next) {
      if (!mounted) {
        return;
      }
      switch (next) {
        case AdminMutationIdle():
        case AdminMutationRunning():
          break;
        case final AdminMutationSucceeded success:
          AdminFeedback.success(
            context,
            success.message,
            notice: success.notice,
          );
        case final AdminMutationFailed failure:
          AdminFeedback.refusal(context, failure.message);
      }
    });
  }

  Future<void> _openCreateForm() async {
    final AdminUserView? created = await Navigator.of(context).push<AdminUserView>(
      MaterialPageRoute<AdminUserView>(
        builder: (BuildContext context) => const AdminUserFormScreen(),
      ),
    );
    if (!mounted || created == null) {
      return;
    }
    await _openDetail(created);
  }

  Future<void> _openDetail(AdminUserView admin) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            AdminUserDetailScreen(adminUserId: admin.id, initial: admin),
      ),
    );
  }
}

class _DirectoryBody extends ConsumerWidget {
  const _DirectoryBody({
    required this.search,
    required this.scroll,
    required this.onOpen,
  });

  final TextEditingController search;
  final ScrollController scroll;
  final Future<void> Function(AdminUserView admin) onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = context.s;
    final AdminUsersFilter filter = ref.watch(adminUsersFilterProvider);

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: TextField(
            controller: search,
            textInputAction: TextInputAction.search,
            onChanged: (String value) =>
                ref.read(adminUsersFilterProvider.notifier).setSearch(value),
            decoration: InputDecoration(
              isDense: true,
              prefixIcon: const Icon(Icons.search),
              hintText: s.auSearchHint,
              helperText: s.auSearchHelper,
              helperMaxLines: 2,
              border: const OutlineInputBorder(),
              suffixIcon: !filter.hasSearch
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: s.auClearSearchTooltip,
                      onPressed: () {
                        search.clear();
                        ref
                            .read(adminUsersFilterProvider.notifier)
                            .setSearch('');
                      },
                    ),
            ),
          ),
        ),
        RoleFilterBar(
          selected: filter.role,
          onChanged: (AdminRole? role) =>
              ref.read(adminUsersFilterProvider.notifier).setRole(role),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: <Widget>[
              _ActivityFilterChip(
                label: s.auFilterEveryone,
                selected: filter.isActive == null,
                value: null,
              ),
              const SizedBox(width: 8),
              _ActivityFilterChip(
                label: s.auStatusActive,
                selected: filter.isActive == true,
                value: true,
              ),
              const SizedBox(width: 8),
              _ActivityFilterChip(
                label: s.auStatusDeactivated,
                selected: filter.isActive == false,
                value: false,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: AsyncValueView<AdminDirectoryState>(
            value: ref.watch(adminDirectoryProvider),
            onRetry: () => ref.invalidate(adminDirectoryProvider),
            isEmpty: (AdminDirectoryState state) => state.isEmpty,
            emptyTitle: s.auEmptyTitle,
            emptyMessage: s.auEmptyMessage(filter: filter.describe(s)),
            emptyIcon: Icons.people_outline,
            loadingLabel: s.auLoadingDirectory,
            builder: (BuildContext context, AdminDirectoryState state) =>
                _DirectoryList(state: state, scroll: scroll, onOpen: onOpen),
          ),
        ),
      ],
    );
  }
}

class _ActivityFilterChip extends ConsumerWidget {
  const _ActivityFilterChip({
    required this.label,
    required this.selected,
    required this.value,
  });

  final String label;
  final bool selected;
  final bool? value;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) =>
            ref.read(adminUsersFilterProvider.notifier).setIsActive(value),
      );
}

class _DirectoryList extends ConsumerWidget {
  const _DirectoryList({
    required this.state,
    required this.scroll,
    required this.onOpen,
  });

  final AdminDirectoryState state;
  final ScrollController scroll;
  final Future<void> Function(AdminUserView admin) onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = context.s;
    final List<AdminUserView> visible = state.visible;

    if (visible.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => ref.read(adminDirectoryProvider.notifier).refresh(),
        child: ListView(
          children: <Widget>[
            const SizedBox(height: 48),
            EmptyStateView(
              title: s.auNoSearchMatchTitle,
              message: '${s.auNoSearchMatchMessage(
                count: state.admins.length,
                query: state.filter.search.trim(),
              )} '
                  '${state.hasMore ? s.auScrollToLoadMore : s.auClearSearchToSeeAll}',
              icon: Icons.search_off,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(adminDirectoryProvider.notifier).refresh(),
      child: ListView.separated(
        controller: scroll,
        itemCount: visible.length + 1,
        separatorBuilder: (BuildContext context, int index) =>
            const Divider(height: 1, indent: 72),
        itemBuilder: (BuildContext context, int index) {
          if (index == visible.length) {
            return _DirectoryFooter(state: state);
          }
          final AdminUserView admin = visible[index];
          return AdminUserTile(
            admin: admin,
            onTap: () => unawaited(onOpen(admin)),
          );
        },
      ),
    );
  }
}

class _DirectoryFooter extends ConsumerWidget {
  const _DirectoryFooter({required this.state});

  final AdminDirectoryState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AppStrings s = context.s;
    final int? supers = state.knownActiveSuperAdmins;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        children: <Widget>[
          if (state.pageError != null) ...<Widget>[
            ErrorStateView(
              error: state.pageError!,
              compact: true,
              // retryLoadMore, not loadMore: the controller refuses to page
              // while pageError is set, which is what stops the scroll listener
              // from re-firing a failed request on every tick.
              onRetry: () => unawaited(
                ref.read(adminDirectoryProvider.notifier).retryLoadMore(),
              ),
            ),
            const SizedBox(height: 12),
          ] else if (state.isLoadingMore)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (state.hasMore)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextButton.icon(
                onPressed: () => unawaited(
                  ref.read(adminDirectoryProvider.notifier).loadMore(),
                ),
                icon: const Icon(Icons.expand_more),
                label: Text(s.loadMore),
              ),
            ),
          Text(
            AdminLabels.countOf(state.visible.length, state.total, s),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (supers != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                supers == 1
                    ? '${s.auActiveSuperAdmins(count: supers)}${s.auLastWayBack}'
                    : '${s.auActiveSuperAdmins(count: supers)}.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
