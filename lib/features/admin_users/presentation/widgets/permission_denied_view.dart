import 'package:flutter/material.dart';
import 'package:manager_bot/core/auth/roles.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/widgets/widgets.dart';
import 'package:manager_bot/features/admin_users/application/admin_user_policy.dart';
import 'package:manager_bot/features/admin_users/presentation/widgets/admin_labels.dart';

/// What a screen shows when the signed-in role may not see it.
///
/// Deliberately NOT an error state: a support user landing on the staff
/// directory has done nothing wrong, and a red panel with a retry button would
/// invite them to hammer an endpoint that will refuse them every time. It says
/// what the role is, what the surface needs, and stops.
class PermissionDeniedView extends StatelessWidget {
  const PermissionDeniedView({
    required this.gate,
    this.currentRole,
    this.title,
    this.icon = Icons.lock_outline,
    this.action,
    super.key,
  });

  final AdminActionGate gate;
  final AdminRole? currentRole;

  /// Null resolves to [AppStrings.auPermissionDeniedTitle].
  final String? title;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final String reason = gate.reason ?? s.auPermissionDeniedFallback;
    final AdminRole? role = currentRole;
    final String message = role == null
        ? reason
        : '$reason\n\n'
            '${s.auPermissionDeniedSignedInAs(role: AdminLabels.roleWithWireName(role, s))}';

    return EmptyStateView(
      title: title ?? s.auPermissionDeniedTitle,
      message: message,
      icon: icon,
      action: action,
    );
  }
}

/// The same refusal, inline, for a single disabled control.
///
/// Used under a greyed-out button so the operator can see WHY without opening a
/// dialog: an unexplained disabled button is indistinguishable from a bug.
class PermissionDeniedHint extends StatelessWidget {
  const PermissionDeniedHint({required this.gate, this.icon, super.key});

  final AdminActionGate gate;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final String? reason = gate.reason;
    if (reason == null) {
      return const SizedBox.shrink();
    }
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            icon ?? Icons.info_outline,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              reason,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
