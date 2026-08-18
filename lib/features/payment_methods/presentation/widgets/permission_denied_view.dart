import 'package:flutter/material.dart';
import 'package:manager_bot/core/auth/roles.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';

/// Shown instead of a screen body when the signed-in role cannot use the route.
///
/// This is NOT a substitute for handling a 403: the server re-resolves the role
/// from the database on every request and is always the real answer. It exists
/// so a VIEWER - whom the router will happily route here, because the core
/// capability map lets every role read the admin surface - sees an explanation
/// rather than an inevitable red error.
class PermissionDeniedView extends StatelessWidget {
  const PermissionDeniedView({
    required this.role,
    required this.allowedRoles,
    this.title,
    this.message,
    super.key,
  });

  /// The role actually signed in, or null when there is no session.
  final AdminRole? role;

  /// The roles the backend route accepts.
  final Set<AdminRole> allowedRoles;

  /// Null falls back to the catalogue's generic denial title.
  final String? title;

  /// Null falls back to the generic "these roles are accepted" sentence.
  final String? message;

  /// Role name from the CATALOGUE rather than `AdminRole.label`, so this screen
  /// keeps compiling whatever the auth feature does to that enum.
  static String roleLabel(AdminRole role, AppStrings s) => switch (role) {
        AdminRole.superAdmin => s.roleSuperAdmin,
        AdminRole.financeAdmin => s.roleFinanceAdmin,
        AdminRole.reviewer => s.roleReviewer,
        AdminRole.support => s.roleSupport,
        AdminRole.viewer => s.roleViewer,
      };

  /// The accepted roles as one phrase, highest rank first so the list reads the
  /// same way the backend tuples are written.
  static String roleList(Set<AdminRole> roles, AppStrings s) {
    final List<AdminRole> sorted = roles.toList(growable: false)
      ..sort((AdminRole a, AdminRole b) => b.rank.compareTo(a.rank));
    return sorted
        .map((AdminRole allowed) => roleLabel(allowed, s))
        .join(s.listSeparator);
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final ThemeData theme = Theme.of(context);
    final AdminRole? current = role;
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
              title ?? s.pmPermissionDeniedTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              message ??
                  s.pmPermissionDeniedMessage(
                    roles: roleList(allowedRoles, s),
                    role: current == null
                        ? s.pmNoRole
                        : roleLabel(current, s),
                  ),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
