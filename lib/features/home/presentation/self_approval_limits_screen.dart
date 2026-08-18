import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/auth/admin_auth_api.dart';
import 'package:manager_bot/core/auth/auth_controller.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/widgets/widgets.dart';
import 'package:manager_bot/features/admin_users/presentation/approval_limits_screen.dart';

/// The signed-in administrator's own approval ceilings, opened from Settings.
///
/// A thin adapter, not a second implementation: [ApprovalLimitsScreen] needs
/// the administrator it is showing, and a `GoRoute` builder has no `WidgetRef`
/// to read the session from. Another administrator's ceilings are still reached
/// the way they always were - through the staff directory.
class SelfApprovalLimitsScreen extends ConsumerWidget {
  const SelfApprovalLimitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = context.s;
    final AdminSession? session = ref.watch(currentSessionProvider);

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: Text(s.alCeilingsSection)),
        body: EmptyStateView(
          title: s.profileNotSignedInTitle,
          message: s.profileNotSignedInMessage,
          icon: Icons.badge_outlined,
        ),
      );
    }

    return ApprovalLimitsScreen(
      adminUserId: session.adminUserId,
      adminDisplayName: session.displayName,
      adminRole: session.role,
    );
  }
}
