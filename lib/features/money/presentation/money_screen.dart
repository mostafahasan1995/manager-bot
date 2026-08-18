import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/auth/auth_controller.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/theme/app_theme.dart';
import 'package:manager_bot/core/widgets/widgets.dart';
import 'package:manager_bot/features/home/presentation/settings_menu_button.dart';
import 'package:manager_bot/features/money/presentation/sections/activity_report_section.dart';
import 'package:manager_bot/features/money/presentation/sections/agent_float_section.dart';
import 'package:manager_bot/features/money/presentation/sections/breaks_section.dart';
import 'package:manager_bot/features/reconciliation/application/break_list_controller.dart';
import 'package:manager_bot/features/reconciliation/application/ledger_report_controllers.dart';
import 'package:manager_bot/features/reconciliation/application/reconciliation_permissions.dart';
import 'package:manager_bot/features/reconciliation/presentation/widgets/permission_denied_view.dart';

/// Tab 2: is the money where it should be?
///
/// ONE scrollable health screen, in the order a problem is actually noticed:
///
/// 1. **Agent float** - our ledger against Ichancy, with the drift shouting
///    when it is not zero.
/// 2. **Breaks** - what is still unresolved, worst first, tapping through to
///    the break detail that already exists.
/// 3. **Activity** - rail ageing and the ledger invariant sweep.
///
/// This replaces the old Reconciliation tab as a DESTINATION, not as a screen:
/// the four-panel workbench is still there, one tap away, for the filtering and
/// paging a summary has no business doing. Each section watches its own provider
/// and renders its own loading/error state, so one failing call never blanks the
/// other two.
class MoneyScreen extends ConsumerWidget {
  const MoneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = context.s;
    final bool canView = ref.watch(canViewReconciliationProvider);

    if (!canView) {
      // SUPPORT passes the router's capability guard (the shared set includes
      // it) but is refused by the reconciliation controller itself. Saying so
      // once beats three requests that all come back 403.
      return Scaffold(
        appBar: AppBar(
          title: Text(s.navMoney),
          actions: const <Widget>[SettingsMenuButton()],
        ),
        body: ReconciliationDeniedView(
          role: ref.watch(currentRoleProvider),
          allowed: ReconciliationRoles.viewRoles,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(s.navMoney),
        actions: <Widget>[
          const _AttentionBadge(),
          IconButton(
            tooltip: s.refresh,
            onPressed: () => _refreshReads(ref),
            icon: const Icon(Icons.refresh),
          ),
          const SettingsMenuButton(),
        ],
      ),
      body: RefreshIndicator(
        // Only the two READS are refreshed. The float comparison and the
        // invariant sweep are POSTs that can open breaks, and a pull gesture
        // must never write.
        onRefresh: () async {
          _refreshReads(ref);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: <Widget>[
            const AgentFloatSection(),
            const SizedBox(height: 24),
            const BreaksSection(),
            const SizedBox(height: 24),
            const ActivityReportSection(),
            const SizedBox(height: 20),
            Text(
              s.timesAreLocalNote,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _refreshReads(WidgetRef ref) {
    ref.invalidate(breakListProvider);
    ref.invalidate(railAgeingReportProvider);
  }
}

/// How many loaded breaks are severe or still drifting. Silent when clean.
class _AttentionBadge extends ConsumerWidget {
  const _AttentionBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BreakListState? state = ref.watch(breakListProvider).valueOrNull;
    if (state == null || state.attentionCount == 0) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Center(
        child: StatusChip(
          label: context.s.attentionBadge(count: state.attentionCount),
          tone: StatusTone.failed,
          icon: Icons.priority_high,
          dense: true,
        ),
      ),
    );
  }
}
