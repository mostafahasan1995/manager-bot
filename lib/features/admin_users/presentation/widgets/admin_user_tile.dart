import 'package:flutter/material.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/theme/app_theme.dart';
import 'package:manager_bot/core/widgets/widgets.dart';
import 'package:manager_bot/features/admin_users/data/admin_user.dart';
import 'package:manager_bot/features/admin_users/presentation/widgets/admin_labels.dart';
import 'package:manager_bot/features/admin_users/presentation/widgets/role_selector.dart';

/// One row of the staff directory.
///
/// Shows role and activation on the same line as the name, because "who is this
/// and what can they do" is the only question this list is ever opened to
/// answer. Deactivated rows are dimmed but never hidden - they still appear on
/// every deposit they ever decided.
class AdminUserTile extends StatelessWidget {
  const AdminUserTile({required this.admin, this.onTap, super.key});

  final AdminUserView admin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppStrings s = context.s;
    final String? handle = admin.atHandle;

    return Opacity(
      opacity: admin.isActive ? 1 : 0.62,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: admin.isActive
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          foregroundColor: admin.isActive
              ? theme.colorScheme.onPrimaryContainer
              : theme.colorScheme.onSurfaceVariant,
          child: Text(admin.initials, style: theme.textTheme.labelLarge),
        ),
        title: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                admin.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
            ),
            if (!admin.isActive) ...<Widget>[
              const SizedBox(width: 8),
              StatusChip(
                label: admin.statusLabel(s),
                tone: admin.statusTone,
                dense: true,
              ),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                handle == null
                    ? s.auTileIdOnly(id: admin.telegramUserIdString)
                    : s.auTileHandleAndId(
                        handle: handle,
                        id: admin.telegramUserIdString,
                      ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.monoStyle(context),
              ),
              const SizedBox(height: 2),
              Text(
                admin.hasSignedIn
                    ? s.auTileLastSignIn(
                        relative: AdminLabels.relative(admin.lastLoginAt, s),
                      )
                    : s.auTileNeverSignedIn,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        trailing: RoleChip(role: admin.role, dense: true),
        isThreeLine: true,
      ),
    );
  }
}

/// A labelled read-only fact, used all over the detail and profile screens.
class DetailRow extends StatelessWidget {
  const DetailRow({
    required this.label,
    required this.value,
    this.mono = false,
    this.trailing,
    super.key,
  });

  final String label;
  final String value;
  final bool mono;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 132,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: mono
                  ? AppTheme.monoStyle(context)
                  : theme.textTheme.bodyMedium,
            ),
          ),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// A titled group of [DetailRow]s.
class DetailSection extends StatelessWidget {
  const DetailSection({
    required this.title,
    required this.children,
    this.trailing,
    super.key,
  });

  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 6),
            ...children,
          ],
        ),
      ),
    );
  }
}
