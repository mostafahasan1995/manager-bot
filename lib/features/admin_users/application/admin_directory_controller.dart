import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/api/api_response.dart';
import 'package:manager_bot/core/auth/roles.dart';
import 'package:manager_bot/core/errors/api_error.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/logging/app_logger.dart';
import 'package:manager_bot/features/admin_users/data/admin_user.dart';
import 'package:manager_bot/features/admin_users/data/admin_users_repository.dart';
import 'package:manager_bot/features/admin_users/presentation/widgets/admin_labels.dart';

/// Server-side filters for the staff directory.
///
/// `role` and `isActive` are real query parameters on `GET /v1/admin/admins`.
/// [search] is NOT - the endpoint has no text search, so it is applied
/// client-side over the rows that have been loaded. That difference is visible
/// in the UI: the search box says how many of the loaded rows it matched.
class AdminUsersFilter {
  const AdminUsersFilter({this.role, this.isActive, this.search = ''});

  final AdminRole? role;
  final bool? isActive;
  final String search;

  bool get hasServerFilter => role != null || isActive != null;

  bool get hasSearch => search.trim().isNotEmpty;

  bool get isUnfiltered => !hasServerFilter && !hasSearch;

  /// A short human summary for the "showing ..." line.
  String describe(AppStrings s) {
    final List<String> parts = <String>[
      if (role != null) AdminLabels.roleLabel(role!, s),
      if (isActive == true) s.auFilterActiveOnly,
      if (isActive == false) s.auFilterDeactivatedOnly,
      if (hasSearch) s.auFilterMatching(query: search.trim()),
    ];
    return parts.isEmpty ? s.auFilterDescribeAll : parts.join(s.listSeparator);
  }

  AdminUsersFilter withRole(AdminRole? value) =>
      AdminUsersFilter(role: value, isActive: isActive, search: search);

  AdminUsersFilter withIsActive(bool? value) =>
      AdminUsersFilter(role: role, isActive: value, search: search);

  AdminUsersFilter withSearch(String value) =>
      AdminUsersFilter(role: role, isActive: isActive, search: value);

  /// Does this row survive the client-side text filter?
  bool matches(AdminUserView admin) {
    final String needle = search.trim().toLowerCase();
    if (needle.isEmpty) {
      return true;
    }
    return admin.displayName.toLowerCase().contains(needle) ||
        (admin.username?.toLowerCase().contains(needle) ?? false) ||
        admin.telegramUserIdString.contains(needle);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminUsersFilter &&
          other.role == role &&
          other.isActive == isActive &&
          other.search == search;

  @override
  int get hashCode => Object.hash(role, isActive, search);
}

/// Holds the directory filters. Changing a SERVER filter re-runs the query;
/// changing the search text only re-renders.
class AdminUsersFilterController extends Notifier<AdminUsersFilter> {
  @override
  AdminUsersFilter build() => const AdminUsersFilter();

  void setRole(AdminRole? role) => state = state.withRole(role);

  void setIsActive(bool? isActive) => state = state.withIsActive(isActive);

  void setSearch(String search) => state = state.withSearch(search);

  void clear() => state = const AdminUsersFilter();
}

final NotifierProvider<AdminUsersFilterController, AdminUsersFilter>
    adminUsersFilterProvider =
    NotifierProvider<AdminUsersFilterController, AdminUsersFilter>(
  AdminUsersFilterController.new,
);

/// One accumulated, offset-paginated view of the staff directory.
class AdminDirectoryState {
  const AdminDirectoryState({
    required this.admins,
    required this.filter,
    required this.total,
    required this.hasMore,
    this.isLoadingMore = false,
    this.pageError,
  });

  /// Every row loaded so far, in server order, across all pages fetched.
  final List<AdminUserView> admins;

  /// The filter these rows were fetched with.
  final AdminUsersFilter filter;

  /// `meta.total` from the last page - how many rows match on the SERVER.
  final int total;

  final bool hasMore;

  final bool isLoadingMore;

  /// Failure of an incremental page load. The rows already on screen stay put;
  /// only the footer turns red.
  ///
  /// Typed [Object] rather than [ApiError]: a row the parser rejects (a null
  /// `displayName`, an unreadable amount) is not an [ApiError] at the throw
  /// site, and a narrower type meant such a failure could never be published -
  /// leaving the footer spinning and every later `loadMore` a silent no-op.
  final Object? pageError;

  /// Rows that also survive the client-side search box.
  List<AdminUserView> get visible =>
      admins.where(filter.matches).toList(growable: false);

  bool get isEmpty => admins.isEmpty;

  bool get hasHiddenBySearch => filter.hasSearch && visible.length < admins.length;

  int get nextOffset => admins.length;

  /// How many active super administrators the client can actually SEE.
  ///
  /// Only meaningful when the whole unfiltered directory has been loaded -
  /// otherwise the answer would be a guess, and guessing wrong here means
  /// either blocking a legal action or promising one the server will refuse.
  /// Null means "do not apply the last-super-admin rule on the client".
  int? get knownActiveSuperAdmins {
    if (hasMore || filter.hasServerFilter) {
      return null;
    }
    return admins
        .where((AdminUserView admin) => admin.isActive && admin.isSuperAdmin)
        .length;
  }

  /// True when a "load more" would actually be sent.
  ///
  /// The `pageError == null` half is what stops a request storm: the scroll
  /// listener fires on EVERY tick within 320px of the bottom, so a page that
  /// failed with a timeout would otherwise be re-requested dozens of times a
  /// second while the operator scrolls down to read the error.
  bool get canLoadMore => hasMore && !isLoadingMore && pageError == null;

  AdminDirectoryState copyWith({
    List<AdminUserView>? admins,
    AdminUsersFilter? filter,
    int? total,
    bool? hasMore,
    bool? isLoadingMore,
    Object? pageError,
    bool clearPageError = false,
  }) =>
      AdminDirectoryState(
        admins: admins ?? this.admins,
        filter: filter ?? this.filter,
        total: total ?? this.total,
        hasMore: hasMore ?? this.hasMore,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        pageError: clearPageError ? null : (pageError ?? this.pageError),
      );

  /// Replaces one row in place after a mutation, without refetching the page.
  AdminDirectoryState withUpdated(AdminUserView updated) {
    final int index =
        admins.indexWhere((AdminUserView admin) => admin.id == updated.id);
    if (index < 0) {
      return this;
    }
    final List<AdminUserView> next = List<AdminUserView>.of(admins);
    next[index] = updated;
    return copyWith(admins: next);
  }
}

/// Loads the staff directory, page by page.
///
/// Offset pagination is what the endpoint offers (`total`, `limit`, `offset`,
/// `hasMore` merged into `meta`); the directory is small and rarely written, so
/// unlike the deposit queue it does not need a cursor.
class AdminDirectoryController extends AsyncNotifier<AdminDirectoryState> {
  static const String _scope = 'admin_users.directory';

  @override
  Future<AdminDirectoryState> build() async {
    final AdminUsersFilter filter = ref.watch(adminUsersFilterProvider);
    final AdminUsersRepository repository = ref.watch(adminUsersRepositoryProvider);
    final OffsetPage<AdminUserView> page = await repository.list(
      role: filter.role,
      isActive: filter.isActive,
    );
    AppLogger.debug(
      // Wire values, not the operator-facing summary: a debug line must read the
      // same whatever language the console is in.
      'loaded ${page.items.length}/${page.total} administrators '
      '(role: ${filter.role?.wireName ?? 'any'}, '
      'isActive: ${filter.isActive ?? 'any'}, '
      'search: ${filter.search.trim().isEmpty ? 'none' : 'yes'})',
      scope: _scope,
    );
    return AdminDirectoryState(
      admins: page.items,
      filter: filter,
      total: page.total,
      hasMore: page.hasMore,
    );
  }

  /// Discards everything and refetches from offset 0. The returned future
  /// completes when the first page has landed, so a pull-to-refresh spinner
  /// stays up for as long as the request does.
  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await future;
    } on Object {
      // The failure is already this provider's state and AsyncValueView renders
      // it with a retry. Rethrowing here would only produce an unhandled async
      // error behind a pull-to-refresh gesture.
    }
  }

  /// Appends the next page. Safe to call repeatedly from a scroll listener:
  /// it is a no-op while a page is in flight, exhausted, or already failed.
  Future<void> loadMore() async {
    final AdminDirectoryState? current = state.valueOrNull;
    if (current == null || !current.canLoadMore) {
      return;
    }

    state = AsyncValue<AdminDirectoryState>.data(
      current.copyWith(isLoadingMore: true, clearPageError: true),
    );

    try {
      final OffsetPage<AdminUserView> page =
          await ref.read(adminUsersRepositoryProvider).list(
                role: current.filter.role,
                isActive: current.filter.isActive,
                offset: current.nextOffset,
              );
      state = AsyncValue<AdminDirectoryState>.data(
        current.copyWith(
          admins: <AdminUserView>[...current.admins, ...page.items],
          total: page.total,
          hasMore: page.hasMore,
          isLoadingMore: false,
          clearPageError: true,
        ),
      );
    } on Object catch (error, stackTrace) {
      // Catching only ApiError left `isLoadingMore: true` published forever
      // whenever AdminUserView.fromJson rejected a row, which wedged the pager
      // AND the search box (it only searches the rows already loaded).
      AppLogger.error(
        'failed to load administrators at offset ${current.nextOffset}: '
        '${error is ApiError ? error.code : error.runtimeType}',
        scope: _scope,
        error: error,
        stackTrace: stackTrace,
      );
      state = AsyncValue<AdminDirectoryState>.data(
        current.copyWith(isLoadingMore: false, pageError: error),
      );
    }
  }

  /// Clears the tail error and tries the same page again.
  ///
  /// The footer's "Load more" / "Try again" must come through here: [loadMore]
  /// refuses while [AdminDirectoryState.pageError] is set, which is exactly
  /// what keeps the scroll listener from re-firing a failed request.
  Future<void> retryLoadMore() async {
    final AdminDirectoryState? current = state.valueOrNull;
    if (current == null || current.isLoadingMore) {
      return;
    }
    if (current.pageError != null) {
      state = AsyncValue<AdminDirectoryState>.data(
        current.copyWith(clearPageError: true),
      );
    }
    await loadMore();
  }

  /// Writes one changed row straight into the loaded page so the list matches
  /// the detail screen without a refetch. A full refresh still happens on pull.
  void applyLocalUpdate(AdminUserView updated) {
    final AdminDirectoryState? current = state.valueOrNull;
    if (current == null) {
      return;
    }
    state = AsyncValue<AdminDirectoryState>.data(current.withUpdated(updated));
  }
}

final AsyncNotifierProvider<AdminDirectoryController, AdminDirectoryState>
    adminDirectoryProvider =
    AsyncNotifierProvider<AdminDirectoryController, AdminDirectoryState>(
  AdminDirectoryController.new,
);
