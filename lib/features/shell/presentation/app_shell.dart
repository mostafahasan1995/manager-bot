import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/ui/ui.dart';
import 'package:manager_bot/features/shell/presentation/shell_tab.dart';
import 'package:manager_bot/features/shell/presentation/widgets/neon_nav_bar.dart';

/// The player app's home. FIVE slots, four of them destinations:
///
/// ```text
///   الرئيسية      إيداعاتي      [ + شحن ]      طرق الدفع      حسابي
///   branch 0      branch 1     a FLOW, not    branch 2      branch 3
///                              a destination
/// ```
///
/// Under Arabic - the default locale - the `Row` inside the bar orders itself
/// from `Directionality`, so الرئيسية sits on the RIGHT and حسابي on the left.
/// Nothing here passes a `textDirection`.
///
/// ## State preservation
///
/// The body is `StatefulShellRoute.indexedStack`'s shell, which is literally an
/// `IndexedStack` over one `Navigator` per branch. Every tab therefore keeps
/// its scroll offset, its filter chips, its expanded rows and its in-flight
/// requests when you leave and come back - and because each branch is a real
/// navigator, a detail pushed inside a tab survives a round trip through the
/// other tabs too.
///
/// ## The centre action
///
/// شحن is NOT a branch. It pushes the top-up flow onto the ROOT navigator as a
/// full-height route, which is what makes the bar disappear under it and Back
/// return the player to exactly the tab they started from. The shell does not
/// know how that push happens: [onOpenTopUp] is handed in by the router, so the
/// shell can be pumped in a widget test with a spy and no router at all.
///
/// ## What the shell deliberately does NOT do
///
/// No auth. No redirect. No capability filtering. There is no session in this
/// build and the four destinations render from demo data, so a shell that asked
/// "may this player see this tab?" would have nothing to ask.
class AppShell extends StatelessWidget {
  const AppShell({
    required this.navigationShell,
    required this.onOpenTopUp,
    super.key,
  });

  /// Provided by `StatefulShellRoute.indexedStack`.
  final StatefulNavigationShell navigationShell;

  /// Opens the شحن flow. Wired by the router to a root-navigator push.
  final VoidCallback onOpenTopUp;

  /// The four normal destinations, in branch order.
  ///
  /// This order MUST match `branches` in `app_router.dart`;
  /// `AppRoute.shellBranchPaths` lists the paths in the same order and
  /// `test/router/navigation_shape_test.dart` asserts the two agree.
  static const List<ShellTab> tabs = <ShellTab>[
    ShellTab(
      branchIndex: 0,
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      accent: AppPalette.accentCyan,
    ),
    ShellTab(
      branchIndex: 1,
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long_rounded,
      accent: AppPalette.accentViolet,
    ),
    ShellTab(
      branchIndex: 2,
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet_rounded,
      accent: AppPalette.accentMagenta,
    ),
    ShellTab(
      branchIndex: 3,
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      accent: AppPalette.accentAmber,
    ),
  ];

  /// Slot the raised centre action occupies, counted across all five slots.
  static const int centreSlot = 2;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppPalette.canvas,
        // The bar floats OVER the tab bodies. Every destination pads its scroll
        // body with `AppSpacing.pagePadding` (bottom `navClearance`, 108) so
        // the last row clears the raised centre action with room to spare.
        extendBody: true,
        body: navigationShell,
        bottomNavigationBar: NeonNavBar(
          tabs: tabs,
          currentIndex: navigationShell.currentIndex,
          centreLabel: context.s.navTopUp,
          onSelect: _select,
          onCentre: onOpenTopUp,
        ),
      );

  /// Switching branches. Re-tapping the tab you are already on returns it to
  /// its root, which is how a player gets out of a pushed detail without
  /// hunting for Back.
  void _select(int branchIndex) => navigationShell.goBranch(
        branchIndex,
        initialLocation: branchIndex == navigationShell.currentIndex,
      );
}
