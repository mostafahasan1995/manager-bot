import 'package:flutter/material.dart';
import 'package:manager_bot/core/theme/app_theme.dart';

/// Snackbars for this feature, with the semantic tone applied consistently.
///
/// A refusal from the server (`ADMIN_SELF_MODIFICATION`, `ADMIN_LAST_SUPER_ADMIN`)
/// is a normal outcome of a correct system defending itself, so it is shown in
/// the reject tone with a long enough duration to actually be read - not as a
/// red crash banner.
abstract final class AdminFeedback {
  static const Duration _short = Duration(seconds: 4);
  static const Duration _long = Duration(seconds: 8);

  static void success(BuildContext context, String message, {String? notice}) {
    _show(
      context,
      message: message,
      detail: notice,
      tone: StatusTone.approve,
      icon: Icons.check_circle_outline,
      duration: notice == null ? _short : _long,
    );
  }

  static void refusal(BuildContext context, String message) {
    _show(
      context,
      message: message,
      tone: StatusTone.reject,
      icon: Icons.block_outlined,
      duration: _long,
    );
  }

  static void info(BuildContext context, String message) {
    _show(
      context,
      message: message,
      tone: StatusTone.info,
      icon: Icons.info_outline,
      duration: _short,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required StatusTone tone,
    required IconData icon,
    required Duration duration,
    String? detail,
  }) {
    final SemanticTone colors = AppSemanticColors.of(context).tone(tone);
    final ThemeData theme = Theme.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: duration,
          backgroundColor: colors.background,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: colors.border),
            borderRadius: BorderRadius.circular(10),
          ),
          content: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(icon, size: 18, color: colors.foreground),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      message,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: colors.foreground),
                    ),
                    if (detail != null) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        detail,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: colors.foreground),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }
}
