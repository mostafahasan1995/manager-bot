/// The player app's visual language, in one import.
///
/// ```dart
/// import 'package:manager_bot/core/ui/ui.dart';
/// ```
///
/// What lives here: colour (`AppPalette`), shape and spacing (`AppSpacing`,
/// `AppRadii`, `AppShadows`, `NeonFonts`), motion (`AppMotion`, `AppEntrance`),
/// the theme (`NeonTheme`) and the component kit.
///
/// What does NOT live here: strings (they come from `AppStrings` via
/// `context.s`), money maths (`core/money`), and anything that talks to the
/// network. A widget in this directory never fetches, never localises and
/// never formats an amount by hand - it is handed finished values.
///
/// NOTE ON `StatusChip`: the admin console has its own `StatusChip` in
/// `core/widgets/status_chip.dart`, driven by `StatusTone`. They are different
/// widgets for different apps. Never import both into one file.
library;

export 'package:manager_bot/core/theme/neon_theme.dart';
export 'package:manager_bot/core/ui/amount_text.dart';
export 'package:manager_bot/core/ui/app_button.dart';
export 'package:manager_bot/core/ui/app_card.dart';
export 'package:manager_bot/core/ui/app_text_field.dart';
export 'package:manager_bot/core/ui/avatar_ring.dart';
export 'package:manager_bot/core/ui/balance_hero.dart';
export 'package:manager_bot/core/ui/connection_pill.dart';
export 'package:manager_bot/core/ui/dimens.dart';
export 'package:manager_bot/core/ui/directional.dart';
export 'package:manager_bot/core/ui/gradient_text.dart';
export 'package:manager_bot/core/ui/motion.dart';
export 'package:manager_bot/core/ui/palette.dart';
export 'package:manager_bot/core/ui/shimmer_box.dart';
export 'package:manager_bot/core/ui/state_views.dart';
export 'package:manager_bot/core/ui/status_chip.dart';
export 'package:manager_bot/core/ui/story_strip.dart';
