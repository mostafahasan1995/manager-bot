import 'package:flutter/material.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/theme/app_theme.dart';

/// The 60-second warning that has to be on screen wherever authority changes.
///
/// `AdminIdentityService` caches the Telegram-id -> administrator lookup for 60
/// seconds, negative results included. Every write invalidates the entry, but a
/// replica that already answered from cache keeps the previous answer until it
/// expires. So "deactivated" in this directory and "cannot act any more" are up
/// to a minute apart, and during an urgent offboarding that minute is the whole
/// point.
///
/// Shown as an INFO tone, not a warning: this is how the system is designed to
/// behave, and dressing a documented latency as an alarm teaches operators to
/// ignore alarms.
class IdentityCacheNotice extends StatelessWidget {
  const IdentityCacheNotice({
    this.compact = false,
    this.tone = StatusTone.info,
    this.icon = Icons.schedule_outlined,
    super.key,
  });

  /// The variant used inside a confirmation sheet, where space is tight.
  const IdentityCacheNotice.compact({Key? key}) : this(compact: true, key: key);

  /// True for the short wording; the text itself comes from the catalogue so it
  /// follows the language toggle.
  final bool compact;
  final StatusTone tone;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SemanticTone colors = AppSemanticColors.of(context).tone(tone);
    final String message = compact
        ? context.s.identityCacheNoticeCompact
        : context.s.identityCacheNotice;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.background,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: colors.foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(color: colors.foreground),
            ),
          ),
        ],
      ),
    );
  }
}
