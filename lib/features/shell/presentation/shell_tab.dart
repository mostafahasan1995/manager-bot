import 'package:flutter/widgets.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';

/// One of the four NORMAL destinations in the bottom bar.
///
/// The raised centre action is deliberately NOT a [ShellTab]: it is not a
/// destination, it starts a flow, and it has its own shape, its own gradient
/// and its own slot. Modelling it as a fifth tab is what makes those bars look
/// cheap - the centre would inherit tab sizing and lose its authority.
///
/// [branchIndex] is the index of the matching `StatefulShellBranch` in
/// `app_router.dart`. The two orders must agree; `AppRoute.shellBranchPaths`
/// documents the paths in the same order and the router test asserts it.
///
/// [accent] is the colour the destination lights up in when selected. Each
/// destination owns one accent so the bar reads as a spectrum rather than four
/// identical glyphs, and every accent here passes `isReadableOnCanvas`.
@immutable
class ShellTab {
  const ShellTab({
    required this.branchIndex,
    required this.icon,
    required this.selectedIcon,
    required this.accent,
  });

  /// Index of this destination's branch in the router.
  final int branchIndex;

  /// Drawn when the destination is not selected: an outline weight.
  final IconData icon;

  /// Drawn when it is: the filled, rounded weight.
  final IconData selectedIcon;

  /// The selected glow and icon colour.
  final Color accent;

  /// Resolved against the active language, so the bar follows the language
  /// toggle in حسابي without the shell holding any Arabic of its own.
  String label(AppStrings s) => switch (branchIndex) {
        0 => s.navHome,
        1 => s.navActivity,
        2 => s.navMethods,
        _ => s.navProfile,
      };
}
