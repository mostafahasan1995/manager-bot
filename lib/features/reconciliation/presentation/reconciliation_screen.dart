import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/auth/auth_controller.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/theme/app_theme.dart';
import 'package:manager_bot/core/widgets/widgets.dart';
import 'package:manager_bot/features/reconciliation/application/break_list_controller.dart';
import 'package:manager_bot/features/reconciliation/application/reconciliation_permissions.dart';
import 'package:manager_bot/features/reconciliation/presentation/panels/agent_float_panel.dart';
import 'package:manager_bot/features/reconciliation/presentation/panels/breaks_panel.dart';
import 'package:manager_bot/features/reconciliation/presentation/panels/ledger_invariants_panel.dart';
import 'package:manager_bot/features/reconciliation/presentation/panels/rail_ageing_panel.dart';
import 'package:manager_bot/features/reconciliation/presentation/widgets/permission_denied_view.dart';

/// Where an admin finds stuck money.
///
/// Four surfaces, in the order a problem is usually worked:
/// 1. Breaks    - the queue of findings, filterable, cursor paged.
/// 2. Float     - our agent float against Ichancy's, on demand.
/// 3. Ageing    - money credited but never confirmed by a rail.
/// 4. Invariants- does the ledger still add up.
///
/// The two POST-backed tabs never fire on open: both write (a break row, a
/// cache repair), and opening a tab must not change data.
class ReconciliationScreen extends ConsumerWidget {
  const ReconciliationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = context.s;
    final bool canView = ref.watch(canViewReconciliationProvider);

    if (!canView) {
      return Scaffold(
        appBar: AppBar(title: Text(s.reconciliationTitle)),
        body: ReconciliationDeniedView(
          role: ref.watch(currentRoleProvider),
          allowed: ReconciliationRoles.viewRoles,
        ),
      );
    }

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.reconciliationTitle),
          actions: <Widget>[
            const _AttentionBadge(),
            IconButton(
              tooltip: s.refreshBreaksTooltip,
              onPressed: () => ref.invalidate(breakListProvider),
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: <Widget>[
              Tab(
                text: s.tabBreaks,
                icon: const Icon(Icons.report_outlined, size: 18),
              ),
              Tab(
                text: s.tabAgentFloat,
                icon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
              ),
              Tab(
                text: s.tabRailAgeing,
                icon: const Icon(Icons.hourglass_bottom_outlined, size: 18),
              ),
              Tab(
                text: s.tabInvariants,
                icon: const Icon(Icons.rule_folder_outlined, size: 18),
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: <Widget>[
            BreaksPanel(),
            AgentFloatPanel(),
            RailAgeingPanel(),
            LedgerInvariantsPanel(),
          ],
        ),
      ),
    );
  }
}

/// How many loaded breaks are severe or still drifting. Silent when clean.
class _AttentionBadge extends ConsumerWidget {
  const _AttentionBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<BreakListState> value = ref.watch(breakListProvider);
    final BreakListState? state = value.valueOrNull;
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
