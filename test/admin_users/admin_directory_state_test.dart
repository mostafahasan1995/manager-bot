import 'package:flutter_test/flutter_test.dart';
import 'package:manager_bot/core/auth/roles.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/features/admin_users/application/admin_directory_controller.dart';
import 'package:manager_bot/features/admin_users/data/admin_user.dart';

const AppStrings _s = EnStrings();

AdminUserView _admin({
  required String id,
  required String displayName,
  String? username,
  String telegramUserId = '7412998301234567890',
  AdminRole role = AdminRole.reviewer,
  bool isActive = true,
}) =>
    AdminUserView(
      id: id,
      telegramUserId: BigInt.parse(telegramUserId),
      displayName: displayName,
      role: role,
      isActive: isActive,
      createdAt: DateTime.utc(2026, 5, 2),
      username: username,
    );

AdminDirectoryState _state({
  required List<AdminUserView> admins,
  AdminUsersFilter filter = const AdminUsersFilter(),
  bool hasMore = false,
  int? total,
}) =>
    AdminDirectoryState(
      admins: admins,
      filter: filter,
      total: total ?? admins.length,
      hasMore: hasMore,
    );

void main() {
  final AdminUserView nadia = _admin(
    id: 'a',
    displayName: 'Nadia Haddad',
    username: 'nadia_ops',
    role: AdminRole.superAdmin,
  );
  final AdminUserView omar = _admin(
    id: 'b',
    displayName: 'Omar Said',
    telegramUserId: '5550001111',
    role: AdminRole.financeAdmin,
  );
  final AdminUserView dormant = _admin(
    id: 'c',
    displayName: 'Rita Kaz',
    role: AdminRole.superAdmin,
    isActive: false,
  );

  group('AdminUsersFilter', () {
    test('an empty search matches everything', () {
      const AdminUsersFilter filter = AdminUsersFilter();

      expect(filter.matches(nadia), isTrue);
      expect(filter.hasSearch, isFalse);
      expect(filter.isUnfiltered, isTrue);
    });

    test('search is case-insensitive across name, username and id', () {
      expect(const AdminUsersFilter(search: 'nadia').matches(nadia), isTrue);
      expect(const AdminUsersFilter(search: 'HADDAD').matches(nadia), isTrue);
      expect(const AdminUsersFilter(search: 'nadia_ops').matches(nadia), isTrue);
      expect(const AdminUsersFilter(search: '74129983').matches(nadia), isTrue);
      expect(const AdminUsersFilter(search: 'omar').matches(nadia), isFalse);
    });

    test('a row with no username is not matched by a username search', () {
      expect(const AdminUsersFilter(search: 'nadia_ops').matches(omar), isFalse);
      expect(const AdminUsersFilter(search: 'omar').matches(omar), isTrue);
    });

    test('with* returns a new filter and can clear a value', () {
      const AdminUsersFilter base = AdminUsersFilter(
        role: AdminRole.reviewer,
        isActive: true,
        search: 'x',
      );

      expect(base.withRole(null).role, isNull);
      expect(base.withRole(null).isActive, isTrue);
      expect(base.withIsActive(null).isActive, isNull);
      expect(base.withSearch('').hasSearch, isFalse);
      expect(base.hasServerFilter, isTrue);
      expect(base.withRole(null).withIsActive(null).hasServerFilter, isFalse);
    });

    test('describe names the active filters', () {
      expect(const AdminUsersFilter().describe(_s), 'all administrators');
      expect(
        const AdminUsersFilter(isActive: false).describe(_s),
        contains('deactivated only'),
      );
      expect(
        const AdminUsersFilter(search: ' nadia ').describe(_s),
        contains('matching "nadia"'),
      );
    });

    test('equality is by value, so a rebuild does not refetch', () {
      expect(
        const AdminUsersFilter(role: AdminRole.viewer),
        const AdminUsersFilter(role: AdminRole.viewer),
      );
      expect(
        const AdminUsersFilter(role: AdminRole.viewer).hashCode,
        const AdminUsersFilter(role: AdminRole.viewer).hashCode,
      );
    });
  });

  group('AdminDirectoryState', () {
    test('visible applies the client-side search only', () {
      final AdminDirectoryState state = _state(
        admins: <AdminUserView>[nadia, omar, dormant],
        filter: const AdminUsersFilter(search: 'omar'),
      );

      expect(state.visible, <AdminUserView>[omar]);
      expect(state.admins.length, 3);
      expect(state.hasHiddenBySearch, isTrue);
      expect(state.nextOffset, 3);
    });

    test('counts active super administrators once everything is loaded', () {
      final AdminDirectoryState state =
          _state(admins: <AdminUserView>[nadia, omar, dormant]);

      // nadia is an ACTIVE super admin; dormant is a super admin but inactive.
      expect(state.knownActiveSuperAdmins, 1);
    });

    test('refuses to count while more pages are outstanding', () {
      final AdminDirectoryState state = _state(
        admins: <AdminUserView>[nadia],
        hasMore: true,
        total: 40,
      );

      expect(state.knownActiveSuperAdmins, isNull);
    });

    test('refuses to count while a server-side filter is applied', () {
      final AdminDirectoryState state = _state(
        admins: <AdminUserView>[nadia],
        filter: const AdminUsersFilter(role: AdminRole.superAdmin),
      );

      expect(state.knownActiveSuperAdmins, isNull);
    });

    test('a client-side search alone does not stop the count', () {
      final AdminDirectoryState state = _state(
        admins: <AdminUserView>[nadia, omar, dormant],
        filter: const AdminUsersFilter(search: 'zzz'),
      );

      expect(state.knownActiveSuperAdmins, 1);
      expect(state.visible, isEmpty);
    });

    test('withUpdated replaces one row in place and leaves the rest alone', () {
      final AdminDirectoryState state =
          _state(admins: <AdminUserView>[nadia, omar, dormant]);
      final AdminUserView demoted = nadia.copyWith(role: AdminRole.viewer);

      final AdminDirectoryState next = state.withUpdated(demoted);

      expect(next.admins[0].role, AdminRole.viewer);
      expect(next.admins[1], omar);
      expect(next.admins[2], dormant);
      expect(next.knownActiveSuperAdmins, 0);
      // The original is untouched.
      expect(state.admins[0].role, AdminRole.superAdmin);
    });

    test('withUpdated is a no-op for a row that is not loaded', () {
      final AdminDirectoryState state = _state(admins: <AdminUserView>[nadia]);
      final AdminUserView stranger =
          _admin(id: 'zzz', displayName: 'Stranger');

      expect(state.withUpdated(stranger).admins, <AdminUserView>[nadia]);
    });

    test('copyWith can clear a page error without touching the rows', () {
      final AdminDirectoryState state = _state(admins: <AdminUserView>[nadia])
          .copyWith(isLoadingMore: true);

      expect(state.isLoadingMore, isTrue);
      expect(state.pageError, isNull);
      expect(
        state.copyWith(isLoadingMore: false, clearPageError: true).pageError,
        isNull,
      );
      expect(state.admins, <AdminUserView>[nadia]);
    });
  });
}
