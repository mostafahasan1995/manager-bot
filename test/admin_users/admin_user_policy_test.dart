import 'package:flutter_test/flutter_test.dart';
import 'package:manager_bot/core/auth/roles.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/features/admin_users/application/admin_user_policy.dart';
import 'package:manager_bot/features/admin_users/data/admin_user.dart';
import 'package:manager_bot/features/admin_users/data/admin_user_error_codes.dart';

/// The gates take a string bundle; English keeps these assertions readable.
const AppStrings _s = EnStrings();

AdminUserView _admin({
  String id = 'target-id',
  AdminRole role = AdminRole.reviewer,
  bool isActive = true,
}) =>
    AdminUserView(
      id: id,
      telegramUserId: BigInt.parse('7412998301234567890'),
      displayName: 'Nadia',
      role: role,
      isActive: isActive,
      createdAt: DateTime.utc(2026, 5, 2),
    );

void main() {
  group('role gates', () {
    test('only a super administrator may write to the directory', () {
      expect(AdminUserPolicy.gateManage(AdminRole.superAdmin, _s).isAllowed, isTrue);
      expect(
        AdminUserPolicy.gateManage(AdminRole.financeAdmin, _s).isBlocked,
        isTrue,
      );
      expect(AdminUserPolicy.gateManage(AdminRole.reviewer, _s).isBlocked, isTrue);
      expect(AdminUserPolicy.gateManage(AdminRole.support, _s).isBlocked, isTrue);
      expect(AdminUserPolicy.gateManage(AdminRole.viewer, _s).isBlocked, isTrue);
      expect(AdminUserPolicy.gateManage(null, _s).isBlocked, isTrue);
    });

    test('a blocked gate always carries a reason and a code', () {
      final AdminActionGate gate = AdminUserPolicy.gateManage(AdminRole.viewer, _s);

      expect(gate.reason, isNotNull);
      expect(gate.code, AdminUserPolicy.insufficientRoleCode);
    });

    test('an allowed gate carries neither', () {
      final AdminActionGate gate =
          AdminUserPolicy.gateManage(AdminRole.superAdmin, _s);

      expect(gate.reason, isNull);
      expect(gate.code, isNull);
      expect(gate, isA<AdminActionAllowed>());
    });

    test('a super administrator may hand out every role', () {
      expect(
        AdminUserPolicy.assignableRoles(AdminRole.superAdmin),
        AdminRoles.all,
      );
      expect(AdminUserPolicy.assignableRoles(AdminRole.financeAdmin), isEmpty);
      expect(AdminUserPolicy.assignableRoles(null), isEmpty);
    });

    test('viewing the directory is not the same gate as writing to it', () {
      expect(
        AdminUserPolicy.gateViewDirectory(AdminRole.superAdmin, _s).isAllowed,
        isTrue,
      );
      expect(AdminUserPolicy.gateViewDirectory(null, _s).isBlocked, isTrue);
    });
  });

  group('changesAuthority', () {
    final AdminUserView target =
        _admin();

    test('a name-only edit does not touch authority', () {
      expect(AdminUserPolicy.changesAuthority(target: target), isFalse);
    });

    test('setting the same values is not a change', () {
      expect(
        AdminUserPolicy.changesAuthority(
          target: target,
          newRole: AdminRole.reviewer,
          newIsActive: true,
        ),
        isFalse,
      );
    });

    test('a different role or a flipped activation is a change', () {
      expect(
        AdminUserPolicy.changesAuthority(
          target: target,
          newRole: AdminRole.financeAdmin,
        ),
        isTrue,
      );
      expect(
        AdminUserPolicy.changesAuthority(target: target, newIsActive: false),
        isTrue,
      );
    });
  });

  group('self-modification guard', () {
    test('nobody may demote themselves', () {
      final AdminUserView me = _admin(id: 'me', role: AdminRole.superAdmin);
      final AdminActionGate gate = AdminUserPolicy.gateUpdate(
        actorRole: AdminRole.superAdmin,
        strings: _s,
        actorAdminUserId: 'me',
        target: me,
        newRole: AdminRole.viewer,
      );

      expect(gate.isBlocked, isTrue);
      expect(gate.code, AdminUserErrorCodes.adminSelfModification);
    });

    test('nobody may deactivate themselves', () {
      final AdminUserView me = _admin(id: 'me', role: AdminRole.superAdmin);
      final AdminActionGate gate = AdminUserPolicy.gateDeactivate(
        actorRole: AdminRole.superAdmin,
        strings: _s,
        actorAdminUserId: 'me',
        target: me,
      );

      expect(gate.isBlocked, isTrue);
      expect(gate.code, AdminUserErrorCodes.adminSelfModification);
    });

    test('renaming yourself is allowed - it touches no authority', () {
      final AdminUserView me = _admin(id: 'me', role: AdminRole.superAdmin);
      final AdminActionGate gate = AdminUserPolicy.gateUpdate(
        actorRole: AdminRole.superAdmin,
        strings: _s,
        actorAdminUserId: 'me',
        target: me,
      );

      expect(gate.isAllowed, isTrue);
    });

    test('changing somebody else is not self-modification', () {
      final AdminActionGate gate = AdminUserPolicy.gateUpdate(
        actorRole: AdminRole.superAdmin,
        strings: _s,
        actorAdminUserId: 'me',
        target: _admin(id: 'someone-else'),
        newRole: AdminRole.viewer,
      );

      expect(gate.isAllowed, isTrue);
    });
  });

  group('last-super-admin guard', () {
    final AdminUserView lastSuper =
        _admin(id: 'last-super', role: AdminRole.superAdmin);

    test('refuses to deactivate the only active super administrator', () {
      final AdminActionGate gate = AdminUserPolicy.gateDeactivate(
        actorRole: AdminRole.superAdmin,
        strings: _s,
        actorAdminUserId: 'someone-else',
        target: lastSuper,
        knownActiveSuperAdmins: 1,
      );

      expect(gate.isBlocked, isTrue);
      expect(gate.code, AdminUserErrorCodes.adminLastSuperAdmin);
    });

    test('refuses to demote the only active super administrator', () {
      final AdminActionGate gate = AdminUserPolicy.gateUpdate(
        actorRole: AdminRole.superAdmin,
        strings: _s,
        actorAdminUserId: 'someone-else',
        target: lastSuper,
        newRole: AdminRole.financeAdmin,
        knownActiveSuperAdmins: 1,
      );

      expect(gate.isBlocked, isTrue);
      expect(gate.code, AdminUserErrorCodes.adminLastSuperAdmin);
    });

    test('allows it when another active super administrator remains', () {
      final AdminActionGate gate = AdminUserPolicy.gateDeactivate(
        actorRole: AdminRole.superAdmin,
        strings: _s,
        actorAdminUserId: 'someone-else',
        target: lastSuper,
        knownActiveSuperAdmins: 2,
      );

      expect(gate.isAllowed, isTrue);
    });

    test('defers to the server when the client cannot see the whole list', () {
      final AdminActionGate gate = AdminUserPolicy.gateDeactivate(
        actorRole: AdminRole.superAdmin,
        strings: _s,
        actorAdminUserId: 'someone-else',
        target: lastSuper,
      );

      expect(gate.isAllowed, isTrue);
    });

    test('renaming the last super administrator is still fine', () {
      final AdminActionGate gate = AdminUserPolicy.gateUpdate(
        actorRole: AdminRole.superAdmin,
        strings: _s,
        actorAdminUserId: 'someone-else',
        target: lastSuper,
        knownActiveSuperAdmins: 1,
      );

      expect(gate.isAllowed, isTrue);
    });

    test('promoting somebody TO super admin is never blocked by the rule', () {
      final AdminActionGate gate = AdminUserPolicy.gateUpdate(
        actorRole: AdminRole.superAdmin,
        strings: _s,
        actorAdminUserId: 'someone-else',
        target: _admin(id: 'other'),
        newRole: AdminRole.superAdmin,
        knownActiveSuperAdmins: 1,
      );

      expect(gate.isAllowed, isTrue);
    });

    test('an already-inactive super admin cannot trip the rule', () {
      final AdminActionGate gate = AdminUserPolicy.gateUpdate(
        actorRole: AdminRole.superAdmin,
        strings: _s,
        actorAdminUserId: 'someone-else',
        target: _admin(
          id: 'dormant',
          role: AdminRole.superAdmin,
          isActive: false,
        ),
        newRole: AdminRole.viewer,
        knownActiveSuperAdmins: 1,
      );

      expect(gate.isAllowed, isTrue);
    });
  });

  group('activation gates', () {
    test('deactivating an already-deactivated admin is refused locally', () {
      final AdminActionGate gate = AdminUserPolicy.gateDeactivate(
        actorRole: AdminRole.superAdmin,
        strings: _s,
        actorAdminUserId: 'me',
        target: _admin(id: 'other', isActive: false),
      );

      expect(gate.isBlocked, isTrue);
      expect(gate.code, 'ALREADY_DEACTIVATED');
    });

    test('reactivating an active admin is refused locally', () {
      final AdminActionGate gate = AdminUserPolicy.gateReactivate(
        actorRole: AdminRole.superAdmin,
        strings: _s,
        actorAdminUserId: 'me',
        target: _admin(id: 'other'),
      );

      expect(gate.isBlocked, isTrue);
      expect(gate.code, 'ALREADY_ACTIVE');
    });

    test('reactivation never consults the last-super-admin rule', () {
      final AdminActionGate gate = AdminUserPolicy.gateReactivate(
        actorRole: AdminRole.superAdmin,
        strings: _s,
        actorAdminUserId: 'me',
        target: _admin(
          id: 'other',
          role: AdminRole.superAdmin,
          isActive: false,
        ),
      );

      expect(gate.isAllowed, isTrue);
    });

    test('a non-manager is blocked before any domain rule is consulted', () {
      final AdminActionGate gate = AdminUserPolicy.gateDeactivate(
        actorRole: AdminRole.financeAdmin,
        strings: _s,
        actorAdminUserId: 'me',
        target: _admin(id: 'other'),
      );

      expect(gate.isBlocked, isTrue);
      expect(gate.code, AdminUserPolicy.insufficientRoleCode);
    });
  });

  test('the identity-cache TTL is stated, not assumed', () {
    expect(AdminUserPolicy.identityCacheTtl, const Duration(seconds: 60));
    expect(_s.identityCacheNotice, contains('60 seconds'));
  });
}
