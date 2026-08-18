import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';

/// Copy-to-clipboard with the app's confirmation, in one place.
///
/// The write itself is fire-and-forget on purpose: the platform channel never
/// fails in a way a player could act on, and blocking the tap on it would make
/// the button feel broken.
abstract final class ProfileClipboard {
  static void copy(
    BuildContext context, {
    required String value,
    required String label,
  }) {
    unawaited(Clipboard.setData(ClipboardData(text: value)));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(context.s.copiedToClipboard(label: label)),
          duration: const Duration(seconds: 2),
        ),
      );
  }
}
