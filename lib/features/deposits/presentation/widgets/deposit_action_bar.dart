import 'package:flutter/material.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/theme/app_theme.dart';
import 'package:manager_bot/features/deposits/data/deposit_action_policy.dart';
import 'package:manager_bot/features/deposits/data/deposit_enums.dart';

/// The action strip pinned to the bottom of the detail screen.
///
/// It renders EXACTLY what [DepositActionPolicy.resolve] returned: actions that
/// are illegal from the current status are never drawn, and actions that are
/// legal but blocked (wrong role, someone else's claim) are drawn disabled with
/// the reason underneath - a greyed button with an explanation teaches, a
/// missing button confuses.
class DepositActionBar extends StatelessWidget {
  const DepositActionBar({
    required this.options,
    required this.status,
    required this.onSelected,
    this.pendingAction,
    super.key,
  });

  final List<DepositActionOption> options;
  final DepositStatus status;

  /// Fired only for an enabled option.
  final void Function(DepositAction action) onSelected;

  /// The action currently in flight; every button is locked while it runs.
  final DepositAction? pendingAction;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppStrings s = context.s;

    if (options.isEmpty) {
      return _Surface(
        child: Row(
          children: <Widget>[
            Icon(
              Icons.info_outline,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                DepositActionPolicy.idleReasonFor(status, s),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final bool busy = pendingAction != null;
    final List<String> reasons = <String>[
      for (final DepositActionOption option in options)
        if (!option.enabled && option.blockReason != null)
          s.actionBlockedLine(
            action: option.action.label(s),
            reason: option.blockReason!,
          ),
    ];

    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: options
                .map(
                  (DepositActionOption option) => _ActionButton(
                    option: option,
                    isRunning: pendingAction == option.action,
                    isLocked: busy,
                    onPressed: () => onSelected(option.action),
                  ),
                )
                .toList(growable: false),
          ),
          if (reasons.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            for (final String reason in reasons)
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 2),
                child: Text(
                  reason,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: child,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.option,
    required this.isRunning,
    required this.isLocked,
    required this.onPressed,
  });

  final DepositActionOption option;
  final bool isRunning;

  /// True while ANY action is in flight, so a second tap cannot double-fire.
  final bool isLocked;

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SemanticTone tone =
        AppSemanticColors.of(context).tone(option.action.tone);
    final bool enabled = option.enabled && !isLocked;

    final Widget label = isRunning
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          )
        : Text(option.action.label(context.s));

    // The two money-moving actions get a filled, coloured button; the two
    // reversible ones stay outlined so they never look like a decision.
    if (option.action.isDestructive) {
      return FilledButton(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: tone.foreground,
          foregroundColor: theme.colorScheme.surface,
        ),
        child: label,
      );
    }

    return OutlinedButton(
      onPressed: enabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: tone.foreground,
        side: BorderSide(color: tone.border),
      ),
      child: label,
    );
  }
}
