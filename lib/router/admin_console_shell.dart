import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manager_bot/core/auth/auth_controller.dart';
import 'package:manager_bot/core/auth/roles.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';

/// Bottom navigation for the STAFF ADMIN CONSOLE, around its two top-level
/// sections.
///
/// This is no longer the app's entry point. The player app owns
/// `features/shell/presentation/app_shell.dart` and lives at `/`; the console
/// stays registered under `/deposits`, `/money` and `/settings` so no existing
/// link 404s and its screens keep working the day a staff session returns. It
/// was called `AppShell` until the player shell took that name; nothing about
/// its behaviour changed with the rename.
///
/// The bot has exactly two daily jobs and so does this console:
///
/// * **Queue** - the deposit review backlog. The landing screen, and where the
///   overwhelming majority of an operator's time goes.
/// * **Money** - agent float, unresolved breaks and the activity report on one
///   health screen.
///
/// Everything else - payment methods, the admin directory, approval ceilings,
/// the profile, the language toggle, sign out - is rare configuration and lives
/// behind the gear in the app bar, never in this bar. A destination the
/// signed-in role cannot use is hidden, and the branch index is recomputed from
/// the visible list so hiding one never selects the wrong tab. The router still
/// guards the routes themselves.
class AdminConsoleShell extends ConsumerWidget {
  const AdminConsoleShell({required this.navigationShell, super.key});

  /// Provided by `StatefulShellRoute.indexedStack`.
  final StatefulNavigationShell navigationShell;

  /// Branch order MUST match the order of `branches` in app_router.dart.
  static const List<ShellDestination> destinations = <ShellDestination>[
    ShellDestination(
      branchIndex: 0,
      icon: Icons.inbox_outlined,
      selectedIcon: Icons.inbox_rounded,
      capability: AdminCapability.viewDepositQueue,
    ),
    ShellDestination(
      branchIndex: 1,
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet_rounded,
      capability: AdminCapability.viewReconciliation,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = context.s;
    final AdminRole? role = ref.watch(currentRoleProvider);
    final List<ShellDestination> visible = destinations
        .where((ShellDestination destination) =>
            destination.capability == null ||
            AdminRoles.can(role, destination.capability!))
        .toList(growable: false);

    if (visible.length < 2) {
      return Scaffold(body: navigationShell);
    }

    int selected = visible.indexWhere(
      (ShellDestination destination) =>
          destination.branchIndex == navigationShell.currentIndex,
    );
    if (selected < 0) {
      selected = 0;
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (int index) => navigationShell.goBranch(
          visible[index].branchIndex,
          // Tapping the tab you are already on returns to its root, which is
          // how an operator gets out of a deposit without hunting for Back.
          initialLocation:
              visible[index].branchIndex == navigationShell.currentIndex,
        ),
        destinations: visible
            .map(
              (ShellDestination destination) => NavigationDestination(
                icon: Icon(destination.icon),
                selectedIcon: Icon(destination.selectedIcon),
                label: destination.label(s),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

/// One bottom-nav destination.
class ShellDestination {
  const ShellDestination({
    required this.branchIndex,
    required this.icon,
    required this.selectedIcon,
    required this.capability,
  });

  final int branchIndex;
  final IconData icon;
  final IconData selectedIcon;

  /// Null means "any signed-in admin".
  final AdminCapability? capability;

  /// Resolved against the active language, so the bar follows the Settings
  /// toggle without the shell holding any English of its own.
  String label(AppStrings s) => switch (branchIndex) {
        0 => s.navQueue,
        _ => s.navMoney,
      };
}
