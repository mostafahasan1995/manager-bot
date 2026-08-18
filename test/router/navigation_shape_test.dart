import 'package:flutter_test/flutter_test.dart';
import 'package:manager_bot/core/auth/roles.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/ui/palette.dart';
import 'package:manager_bot/features/shell/presentation/app_shell.dart';
import 'package:manager_bot/features/shell/presentation/shell_tab.dart';
import 'package:manager_bot/router/admin_console_shell.dart';
import 'package:manager_bot/router/app_router.dart';

/// The navigation shape is a product decision, not an implementation detail.
///
/// The player app has FOUR bottom destinations plus a raised centre action that
/// is a FLOW, not a fifth tab; it opens on الرئيسية with no login gate; and the
/// staff console keeps every path it had. These assertions exist so a later
/// "just one more tab", a stray redirect, or a quietly deleted console route
/// cannot land without someone deciding to.
void main() {
  group('player bottom navigation', () {
    test('has exactly four normal destinations', () {
      expect(AppShell.tabs, hasLength(4));
    });

    test('the centre action sits in the middle of five slots', () {
      // Four tabs plus the centre makes five slots; the centre is slot 2, so
      // there are exactly two destinations on each side of it.
      expect(AppShell.centreSlot, AppShell.tabs.length ~/ 2);
    });

    test('branch indices match the router branch order', () {
      expect(
        AppShell.tabs.map((ShellTab t) => t.branchIndex).toList(growable: false),
        <int>[0, 1, 2, 3],
      );
    });

    test('there is one branch path per destination, in the same order', () {
      expect(AppRoute.shellBranchPaths, hasLength(AppShell.tabs.length));
      expect(AppRoute.shellBranchPaths, <String>[
        AppRoute.homePath,
        AppRoute.activityPath,
        AppRoute.methodsPath,
        AppRoute.accountPath,
      ]);
    });

    test('labels come from the catalogue, in both languages', () {
      final List<AppStrings> catalogues = <AppStrings>[
        AppStrings.ar,
        AppStrings.en,
      ];
      for (final AppStrings s in catalogues) {
        expect(
          AppShell.tabs.map((ShellTab t) => t.label(s)).toList(growable: false),
          <String>[s.navHome, s.navActivity, s.navMethods, s.navProfile],
        );
      }
    });

    test('every label is distinct, so no two tabs read the same', () {
      for (final AppStrings s in <AppStrings>[AppStrings.ar, AppStrings.en]) {
        final Set<String> labels =
            AppShell.tabs.map((ShellTab t) => t.label(s)).toSet();
        expect(labels, hasLength(AppShell.tabs.length));
        expect(labels.contains(s.navTopUp), isFalse,
            reason: 'the centre action is not a destination');
      }
    });

    test('every selected accent is legible on the canvas', () {
      for (final ShellTab tab in AppShell.tabs) {
        expect(
          AppPalette.isReadableOnCanvas(tab.accent),
          isTrue,
          reason: 'branch ${tab.branchIndex} lights up in an unreadable colour',
        );
      }
    });

    test('each destination owns its own accent', () {
      expect(
        AppShell.tabs.map((ShellTab t) => t.accent).toSet(),
        hasLength(AppShell.tabs.length),
      );
    });

    test('selected and unselected icons differ on every destination', () {
      for (final ShellTab tab in AppShell.tabs) {
        expect(tab.icon, isNot(tab.selectedIcon));
      }
    });
  });

  group('player routes', () {
    test('the app opens on the home tab, not on a login or a splash', () {
      expect(AppRoute.homePath, '/');
      expect(AppRoute.shellBranchPaths.first, AppRoute.homePath);
      expect(AppRoute.loginPath, isNot(AppRoute.homePath));
      expect(AppRoute.splashPath, isNot(AppRoute.homePath));
    });

    test('the top-up flow is not one of the shell branches', () {
      expect(AppRoute.shellBranchPaths.contains(AppRoute.topUpPath), isFalse);
    });

    test('the account tab does not collide with the console profile', () {
      expect(AppRoute.account, isNot(AppRoute.profile));
      expect(AppRoute.accountPath, isNot(AppRoute.profilePath));
    });
  });

  group('staff admin console', () {
    test('still has its two destinations', () {
      expect(AdminConsoleShell.destinations, hasLength(2));
      expect(
        AdminConsoleShell.destinations
            .map((ShellDestination d) => d.branchIndex)
            .toList(growable: false),
        <int>[0, 1],
      );
    });

    test('queue is first and money second, in both languages', () {
      final ShellDestination queue = AdminConsoleShell.destinations.first;
      final ShellDestination money = AdminConsoleShell.destinations.last;

      expect(queue.label(AppStrings.en), AppStrings.en.navQueue);
      expect(queue.label(AppStrings.ar), AppStrings.ar.navQueue);
      expect(money.label(AppStrings.en), AppStrings.en.navMoney);
      expect(money.label(AppStrings.ar), AppStrings.ar.navMoney);
    });

    test('both console tabs are readable by every role that can read it', () {
      for (final ShellDestination destination
          in AdminConsoleShell.destinations) {
        final AdminCapability? capability = destination.capability;
        expect(capability, isNotNull);
        expect(AdminRoles.can(AdminRole.viewer, capability!), isTrue);
      }
    });

    test('its landing route is still the deposit queue', () {
      expect(AppRoute.depositQueuePath, '/deposits');
    });

    test('configuration hangs off /settings, not off a tab', () {
      for (final String path in <String>[
        AppRoute.profilePath,
        AppRoute.paymentMethodsPath,
        AppRoute.adminUsersPath,
        AppRoute.approvalLimitsPath,
      ]) {
        expect(path.startsWith('${AppRoute.settingsPath}/'), isTrue,
            reason: '$path must be a child of ${AppRoute.settingsPath}');
      }
    });

    test('the reconciliation workbench hangs off the money tab', () {
      expect(
        AppRoute.reconciliationPath.startsWith('${AppRoute.moneyPath}/'),
        isTrue,
      );
    });

    test('deposit detail locations are escaped', () {
      expect(
        AppRoute.depositDetailLocation('k7q2 zp9'),
        '/deposits/k7q2%20zp9',
      );
    });
  });

  group('routes overall', () {
    test('every route name is unique', () {
      const List<String> names = <String>[
        AppRoute.home,
        AppRoute.activity,
        AppRoute.methods,
        AppRoute.account,
        AppRoute.topUp,
        AppRoute.splash,
        AppRoute.login,
        AppRoute.depositQueue,
        AppRoute.depositDetail,
        AppRoute.money,
        AppRoute.reconciliation,
        AppRoute.settings,
        AppRoute.profile,
        AppRoute.paymentMethods,
        AppRoute.adminUsers,
        AppRoute.approvalLimits,
      ];
      expect(names.toSet(), hasLength(names.length));
    });

    test('every top-level path is unique', () {
      const List<String> paths = <String>[
        AppRoute.homePath,
        AppRoute.activityPath,
        AppRoute.methodsPath,
        AppRoute.accountPath,
        AppRoute.topUpPath,
        AppRoute.splashPath,
        AppRoute.loginPath,
        AppRoute.depositQueuePath,
        AppRoute.moneyPath,
        AppRoute.settingsPath,
      ];
      expect(paths.toSet(), hasLength(paths.length));
    });
  });
}
