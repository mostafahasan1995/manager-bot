import 'package:flutter/material.dart';
import 'package:manager_bot/core/auth/roles.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/theme/app_theme.dart';
import 'package:manager_bot/core/widgets/widgets.dart';
import 'package:manager_bot/features/admin_users/presentation/widgets/admin_labels.dart';

/// A role, rendered the same way everywhere in the console.
class RoleChip extends StatelessWidget {
  const RoleChip({required this.role, this.dense = false, super.key});

  final AdminRole role;
  final bool dense;

  @override
  Widget build(BuildContext context) => StatusChip(
        label: AdminLabels.roleLabel(role, context.s),
        tone: AdminLabels.roleTone(role),
        dense: dense,
      );
}

/// Picks the role to grant.
///
/// Radio rows rather than a dropdown, and every row carries the one-line summary
/// of what the role can do: granting FINANCE_ADMIN instead of REVIEWER is the
/// difference between somebody who can release money and somebody who cannot,
/// and that must not be hidden behind a collapsed picker.
///
/// [options] normally comes from `assignableRolesProvider`. When [enabled] is
/// false the current value is still shown - a disabled picker that also hides
/// the value tells the operator nothing.
class RoleSelector extends StatelessWidget {
  const RoleSelector({
    required this.value,
    required this.options,
    required this.onChanged,
    this.enabled = true,
    this.disabledReason,
    super.key,
  });

  final AdminRole value;
  final List<AdminRole> options;
  final ValueChanged<AdminRole> onChanged;
  final bool enabled;
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppStrings s = context.s;
    final List<AdminRole> shown =
        options.isEmpty ? <AdminRole>[value] : options;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(s.auRoleFieldLabel, style: theme.textTheme.labelLarge),
        const SizedBox(height: 4),
        ...shown.map((AdminRole role) {
          final bool selected = role == value;
          return Opacity(
            opacity: enabled || selected ? 1 : 0.5,
            child: Card(
              margin: const EdgeInsets.only(bottom: 8),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: enabled && !selected ? () => onChanged(role) : null,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(
                        selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: selected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    AdminLabels.roleLabel(role, s),
                                    style: theme.textTheme.titleSmall,
                                  ),
                                ),
                                Text(
                                  role.wireName,
                                  style: AppTheme.monoStyle(context),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AdminLabels.roleSummary(role, s),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        if (!enabled && disabledReason != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.lock_outline,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    disabledReason!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Filters the directory by role. A null selection means "every role".
class RoleFilterBar extends StatelessWidget {
  const RoleFilterBar({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final AdminRole? selected;
  final ValueChanged<AdminRole?> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: <Widget>[
          FilterChip(
            label: Text(s.auAllRoles),
            selected: selected == null,
            onSelected: (_) => onChanged(null),
          ),
          for (final AdminRole role in AdminRoles.all) ...<Widget>[
            const SizedBox(width: 8),
            FilterChip(
              label: Text(AdminLabels.roleLabel(role, s)),
              selected: selected == role,
              onSelected: (bool value) => onChanged(value ? role : null),
            ),
          ],
        ],
      ),
    );
  }
}
