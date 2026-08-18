import 'package:flutter/material.dart';
import 'package:manager_bot/core/auth/roles.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/features/reconciliation/application/reconciliation_permissions.dart';

/// Shown instead of a panel the signed-in role may not read or act on.
///
/// This is not an error state: nothing failed, the admin simply is not on the
/// route's role list. Firing five requests that all come back 403 would be both
/// noisy and slower than saying so up front.
class ReconciliationDeniedView extends StatelessWidget {
  const ReconciliationDeniedView({
    required this.role,
    required this.allowed,
    this.action,
    super.key,
  });

  /// The role that is actually signed in, or null when signed out.
  final AdminRole? role;

  /// The roles the backend accepts for this route.
  final Set<AdminRole> allowed;

  /// What the admin was trying to do, already localised - e.g.
  /// `context.s.deniedActionOpenBreak`. Defaults to "view reconciliation".
  final String? action;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppStrings s = context.s;
    final AdminRole? current = role;
    final String verb = action ?? s.deniedActionViewReconciliation;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.lock_outline_rounded,
              size: 38,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 14),
            Text(
              s.deniedTitle,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              current == null
                  ? s.deniedSignedOut(action: verb)
                  : s.deniedRoleCannot(
                      role: ReconciliationRoles.roleLabel(current, s),
                      action: verb,
                    ),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              s.deniedAllowedRoles(
                roles: ReconciliationRoles.describe(allowed, s),
              ),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
