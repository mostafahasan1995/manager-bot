/// The شحن الرصيد destination, in one import.
///
/// ```dart
/// import 'package:manager_bot/features/shell/topup/topup.dart';
/// ...
/// TopUpScreen(onClose: () => shell.goHome())
/// ```
///
/// The shell only ever needs [TopUpScreen]. The providers are exported so a
/// badge elsewhere in the app (a "you have an unfinished top-up" hint, say) can
/// watch the draft without reaching into the feature's internals.
library;

export 'package:manager_bot/features/shell/topup/application/topup_amount_rules.dart';
export 'package:manager_bot/features/shell/topup/application/topup_providers.dart';
export 'package:manager_bot/features/shell/topup/data/topup_models.dart';
export 'package:manager_bot/features/shell/topup/presentation/topup_screen.dart';
