import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/router/app_router.dart';

/// The gear that opens Settings from a top app bar.
///
/// Settings is NOT a bottom-nav destination: payment methods, the admin
/// directory, approval ceilings, the language toggle and sign out are rare
/// configuration, not daily work. Put this in the `actions` of every top-level
/// screen's [AppBar], as the LAST action, so the gear is always in the same
/// corner:
///
/// ```dart
/// AppBar(
///   title: Text(context.s.depositQueueTitle),
///   actions: const <Widget>[..., SettingsMenuButton()],
/// )
/// ```
class SettingsMenuButton extends StatelessWidget {
  const SettingsMenuButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: context.s.settingsTooltip,
        icon: const Icon(Icons.settings_outlined),
        // Pushed on the ROOT navigator by the route declaration, so the bottom
        // bar disappears and Back returns to the tab the operator left.
        onPressed: () => unawaited(context.pushNamed<void>(AppRoute.settings)),
      );
}
