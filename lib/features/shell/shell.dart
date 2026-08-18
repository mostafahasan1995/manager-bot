/// The player app's shell, in one import.
///
/// ```dart
/// import 'package:manager_bot/features/shell/shell.dart';
/// ```
///
/// The five destinations themselves are NOT re-exported here: each one is its
/// own feature under `features/shell/<name>/` and the router imports them
/// directly, so adding a destination never widens this barrel.
library;

export 'package:manager_bot/features/shell/presentation/app_shell.dart';
export 'package:manager_bot/features/shell/presentation/shell_tab.dart';
export 'package:manager_bot/features/shell/presentation/widgets/neon_nav_bar.dart';
