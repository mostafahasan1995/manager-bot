import 'package:flutter_test/flutter_test.dart';
import 'package:manager_bot/core/auth/roles.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/features/admin_users/data/admin_user.dart';

const AppStrings _s = EnStrings();

/// A full row exactly as `AdminUserView` emits it.
Map<String, Object?> _wire({
  Object? username = 'nadia_ops',
  Object? lastLoginAt = '2026-08-16T09:11:02.114Z',
  Object? role = 'FINANCE_ADMIN',
  Object? isActive = true,
}) =>
    <String, Object?>{
      'id': '0f6a4d8e-2b1c-4f3a-9e77-1a2b3c4d5e6f',
      // 19 digits: comfortably past 2^53, which is the whole point.
      'telegramUserId': '7412998301234567890',
      'username': username,
      'displayName': 'Nadia Haddad',
      'role': role,
      'isActive': isActive,
      'lastLoginAt': lastLoginAt,
      'createdAt': '2026-05-02T08:00:00.000Z',
    };

void main() {
  group('AdminUserView.fromJson', () {
    test('parses the telegram id as BigInt without losing precision', () {
      final AdminUserView admin = AdminUserView.fromJson(_wire());

      expect(admin.telegramUserId, BigInt.parse('7412998301234567890'));
      expect(admin.telegramUserIdString, '7412998301234567890');
      // The failure this guards against: a double round trip silently rewriting
      // the last digits and creating a DIFFERENT person.
      expect(admin.telegramUserId > (BigInt.one << 53), isTrue);
      expect(
        BigInt.from(admin.telegramUserId.toDouble()),
        isNot(admin.telegramUserId),
      );
    });

    test('parses every scalar field', () {
      final AdminUserView admin = AdminUserView.fromJson(_wire());

      expect(admin.id, '0f6a4d8e-2b1c-4f3a-9e77-1a2b3c4d5e6f');
      expect(admin.displayName, 'Nadia Haddad');
      expect(admin.username, 'nadia_ops');
      expect(admin.atHandle, '@nadia_ops');
      expect(admin.role, AdminRole.financeAdmin);
      expect(admin.isActive, isTrue);
      expect(admin.hasSignedIn, isTrue);
      expect(admin.isSuperAdmin, isFalse);
      expect(admin.statusLabel(_s), 'Active');
    });

    test('accepts an absent username and an admin who never signed in', () {
      final AdminUserView admin = AdminUserView.fromJson(
        _wire(username: null, lastLoginAt: null),
      );

      expect(admin.username, isNull);
      expect(admin.atHandle, isNull);
      expect(admin.lastLoginAt, isNull);
      expect(admin.hasSignedIn, isFalse);
    });

    test('an unknown role degrades to the least authority, not a crash', () {
      final AdminUserView admin =
          AdminUserView.fromJson(_wire(role: 'GALACTIC_OVERLORD'));

      expect(admin.role, AdminRole.viewer);
    });

    test('a deactivated row still parses and keeps its neutral tone', () {
      final AdminUserView admin = AdminUserView.fromJson(_wire(isActive: false));

      expect(admin.isActive, isFalse);
      expect(admin.statusLabel(_s), 'Deactivated');
    });

    test('round-trips through toJson', () {
      final AdminUserView first = AdminUserView.fromJson(_wire());
      final AdminUserView second = AdminUserView.fromJson(first.toJson());

      expect(second, first);
      expect(second.hashCode, first.hashCode);
      expect(second.toJson(), first.toJson());
    });

    test('round-trips with every nullable field absent', () {
      final AdminUserView first =
          AdminUserView.fromJson(_wire(username: null, lastLoginAt: null));
      final AdminUserView second = AdminUserView.fromJson(first.toJson());

      expect(second, first);
    });
  });

  group('AdminUserView.initials', () {
    test('takes one letter from each of the first two words', () {
      expect(AdminUserView.fromJson(_wire()).initials, 'NH');
    });

    test('falls back to two letters of a single-word name', () {
      final Map<String, Object?> json = _wire();
      json['displayName'] = 'Nadia';
      expect(AdminUserView.fromJson(json).initials, 'NA');
    });

    test('handles a one-character name', () {
      final Map<String, Object?> json = _wire();
      json['displayName'] = 'N';
      expect(AdminUserView.fromJson(json).initials, 'N');
    });
  });

  group('CreateAdminUserRequest.toJson', () {
    test('sends the id as a decimal string, never a number', () {
      final CreateAdminUserRequest request = CreateAdminUserRequest(
        telegramUserId: BigInt.parse('7412998301234567890'),
        displayName: 'Nadia',
        role: AdminRole.reviewer,
      );

      final Map<String, Object?> body = request.toJson();
      expect(body['telegramUserId'], '7412998301234567890');
      expect(body['telegramUserId'], isA<String>());
      expect(body['role'], 'REVIEWER');
      expect(body.containsKey('username'), isFalse);
    });

    test('includes the username when one was given', () {
      final CreateAdminUserRequest request = CreateAdminUserRequest(
        telegramUserId: BigInt.two,
        displayName: 'Nadia',
        role: AdminRole.viewer,
        username: 'nadia_ops',
      );

      expect(request.toJson()['username'], 'nadia_ops');
    });
  });

  group('UpdateAdminUserRequest.diff', () {
    final AdminUserView before = AdminUserView.fromJson(_wire());

    test('sends nothing when nothing changed', () {
      final UpdateAdminUserRequest patch = UpdateAdminUserRequest.diff(
        before: before,
        displayName: before.displayName,
        role: before.role,
        isActive: before.isActive,
        username: before.username,
      );

      expect(patch.isEmpty, isTrue);
      expect(patch.toJson(), isEmpty);
      expect(patch.changesAuthority, isFalse);
    });

    test('sends only the changed keys', () {
      final UpdateAdminUserRequest patch = UpdateAdminUserRequest.diff(
        before: before,
        displayName: 'Nadia H.',
        role: before.role,
        isActive: before.isActive,
        username: before.username,
      );

      expect(patch.toJson(), <String, Object?>{'displayName': 'Nadia H.'});
      expect(patch.changesAuthority, isFalse);
    });

    test('flags a role change as an authority change', () {
      final UpdateAdminUserRequest patch = UpdateAdminUserRequest.diff(
        before: before,
        displayName: before.displayName,
        role: AdminRole.viewer,
        isActive: before.isActive,
        username: before.username,
      );

      expect(patch.changesAuthority, isTrue);
      expect(patch.toJson(), <String, Object?>{'role': 'VIEWER'});
    });

    test('flags a deactivation as an authority change', () {
      final UpdateAdminUserRequest patch = UpdateAdminUserRequest.diff(
        before: before,
        displayName: before.displayName,
        role: before.role,
        isActive: false,
        username: before.username,
      );

      expect(patch.changesAuthority, isTrue);
      expect(patch.toJson(), <String, Object?>{'isActive': false});
    });

    test('never emits a null - the server rejects null on optional strings', () {
      final UpdateAdminUserRequest patch = UpdateAdminUserRequest.diff(
        before: before,
        displayName: before.displayName,
        role: before.role,
        isActive: before.isActive,
      );

      expect(patch.toJson().values, isNot(contains(null)));
    });
  });

  group('AdminUserFieldRules', () {
    test('accepts 1 to 19 digits and nothing else', () {
      expect(AdminUserFieldRules.telegramUserId('7', _s), isNull);
      expect(AdminUserFieldRules.telegramUserId('7412998301234567890', _s), isNull);
      expect(AdminUserFieldRules.telegramUserId(' 7412998301 ', _s), isNull);
      expect(AdminUserFieldRules.telegramUserId('', _s), isNotNull);
      expect(AdminUserFieldRules.telegramUserId('@nadia', _s), isNotNull);
      expect(AdminUserFieldRules.telegramUserId('-1001', _s), isNotNull);
      expect(AdminUserFieldRules.telegramUserId('1_000', _s), isNotNull);
      expect(
        AdminUserFieldRules.telegramUserId('12345678901234567890', _s),
        isNotNull,
      );
    });

    test('requires a display name of at most 120 characters', () {
      expect(AdminUserFieldRules.displayName('Nadia', _s), isNull);
      expect(AdminUserFieldRules.displayName('   ', _s), isNotNull);
      expect(AdminUserFieldRules.displayName('x' * 120, _s), isNull);
      expect(AdminUserFieldRules.displayName('x' * 121, _s), isNotNull);
    });

    test('treats an empty username as valid and strips a leading @', () {
      expect(AdminUserFieldRules.username('', _s), isNull);
      expect(AdminUserFieldRules.username('@nadia_ops', _s), isNull);
      expect(AdminUserFieldRules.username('@', _s), isNotNull);
      expect(AdminUserFieldRules.username('x' * 65, _s), isNotNull);

      expect(AdminUserFieldRules.normaliseUsername('@nadia_ops'), 'nadia_ops');
      expect(AdminUserFieldRules.normaliseUsername(' nadia_ops '), 'nadia_ops');
      expect(AdminUserFieldRules.normaliseUsername('  '), isNull);
    });
  });
}
