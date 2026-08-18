import 'package:flutter/material.dart';
import 'package:manager_bot/core/auth/roles.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';

/// The role name from the catalogue.
///
/// Deliberately NOT `AdminRole.label`: the role enum lives in core, and this
/// screen must keep reading correctly whichever way that field is localised.
String _roleLabel(AdminRole role, AppStrings s) => switch (role) {
      AdminRole.superAdmin => s.roleSuperAdmin,
      AdminRole.financeAdmin => s.roleFinanceAdmin,
      AdminRole.reviewer => s.roleReviewer,
      AdminRole.support => s.roleSupport,
      AdminRole.viewer => s.roleViewer,
    };

/// Shown when the signed-in role may not see a surface at all.
///
/// The router already keeps a role out of a screen it cannot use, but a screen
/// must still be able to say so itself: capabilities are re-read from the
/// database on every request, so a demotion can land while the screen is open.
class PermissionDeniedView extends StatelessWidget {
  const PermissionDeniedView({
    required this.title,
    required this.message,
    this.role,
    this.action,
    super.key,
  });

  final String title;
  final String message;

  /// Rendered as "Signed in as Reviewer", so the admin knows what to ask for.
  final AdminRole? role;

  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AdminRole? currentRole = role;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.lock_outline_rounded,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (currentRole != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                context.s.signedInAsRole(
                  role: _roleLabel(currentRole, context.s),
                ),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (action != null) ...<Widget>[
              const SizedBox(height: 18),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
