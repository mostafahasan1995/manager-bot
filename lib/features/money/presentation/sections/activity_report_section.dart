import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/theme/app_theme.dart';
import 'package:manager_bot/core/widgets/widgets.dart';
import 'package:manager_bot/features/money/presentation/money_formats.dart';
import 'package:manager_bot/features/reconciliation/application/ledger_report_controllers.dart';
import 'package:manager_bot/features/reconciliation/application/reconciliation_permissions.dart';
import 'package:manager_bot/features/reconciliation/data/ledger_invariant_report.dart';
import 'package:manager_bot/features/reconciliation/data/rail_ageing_report.dart';
import 'package:manager_bot/features/reconciliation/presentation/widgets/reconciliation_card.dart';
import 'package:manager_bot/router/app_router.dart';

/// The activity summary: what the money has been doing, in two readings.
///
/// * **Rail ageing** - money credited to players that the rail has not
///   confirmed. A plain GET, so it loads with the screen.
/// * **Ledger invariants** - do the books still add up. A POST that writes
///   breaks and repairs caches, so it only ever runs when somebody asks.
///
/// Both are the existing reconciliation providers; the depth (per-bucket
/// ageing, per-violation cards) stays in the workbench behind "Reconciliation".
class ActivityReportSection extends StatelessWidget {
  const ActivityReportSection({super.key});

  /// Accounts shown before the summary stops being one.
  static const int previewCount = 3;

  @override
  Widget build(BuildContext context) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _RailAgeingCard(),
          SizedBox(height: 12),
          _InvariantsCard(),
        ],
      );
}

class _RailAgeingCard extends ConsumerWidget {
  const _RailAgeingCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = context.s;
    final AsyncValue<RailAgeingReport> value =
        ref.watch(railAgeingReportProvider);

    return value.when(
      loading: () => ReconciliationCard(
        title: s.tabRailAgeing,
        icon: Icons.hourglass_bottom_outlined,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: LoadingStateView(label: s.loadingRailAgeing),
        ),
      ),
      error: (Object error, StackTrace stackTrace) => ReconciliationCard(
        title: s.tabRailAgeing,
        icon: Icons.hourglass_bottom_outlined,
        child: ErrorStateView(
          error: error,
          compact: true,
          onRetry: () => ref.invalidate(railAgeingReportProvider),
        ),
      ),
      data: (RailAgeingReport report) => _RailAgeingBody(report: report),
    );
  }
}

class _RailAgeingBody extends StatelessWidget {
  const _RailAgeingBody({required this.report});

  final RailAgeingReport report;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final ThemeData theme = Theme.of(context);
    final List<RailAgeingRow> preview = report.rowsWorstFirst
        .take(ActivityReportSection.previewCount)
        .toList(growable: false);

    return ReconciliationCard(
      title: s.tabRailAgeing,
      subtitle: s.railAgeingGeneratedAt(
        timestamp: MoneyFormats.timestampWithAge(
          report.generatedAt,
          s,
          context.localeTag,
        ),
      ),
      icon: Icons.hourglass_bottom_outlined,
      tone: report.hasStaleAccounts ? StatusTone.failed : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (report.hasStaleAccounts) ...<Widget>[
            NoticeStrip(
              message: s.staleAccountsNotice(
                count: report.staleAccountCodes.length,
                codes: report.staleAccountCodes.join(', '),
              ),
              tone: StatusTone.failed,
            ),
            const SizedBox(height: 12),
          ],
          if (report.isEmpty)
            Text(
              s.emptyRailAgeingMessage,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          for (final RailAgeingRow row in preview)
            _RailAgeingRowLine(
              row: row,
              isStale: report.isStale(row.accountCode),
            ),
        ],
      ),
    );
  }
}

class _RailAgeingRowLine extends StatelessWidget {
  const _RailAgeingRowLine({required this.row, required this.isStale});

  final RailAgeingRow row;
  final bool isStale;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final ThemeData theme = Theme.of(context);
    final Duration? oldest = row.ageOfOldest();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        row.accountCode,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.monoStyle(context),
                      ),
                    ),
                    if (isStale) ...<Widget>[
                      const SizedBox(width: 6),
                      StatusChip(
                        label: s.chipStale,
                        tone: StatusTone.failed,
                        dense: true,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  s.railRowSubtitle(
                    currency: row.currencyCode,
                    count: row.entryCount,
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              MoneyText(
                row.balance,
                colorBySign: true,
                style: AppTheme.moneyStyle(context, fontSize: 16),
              ),
              const SizedBox(height: 2),
              Text(
                oldest == null
                    ? s.captionNoDatedEntries
                    : s.ageAgo(age: MoneyFormats.age(oldest, s)),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InvariantsCard extends ConsumerWidget {
  const _InvariantsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = context.s;
    final ThemeData theme = Theme.of(context);
    final bool canAct = ref.watch(canActOnReconciliationProvider);
    final AsyncValue<InvariantRun?> value = ref.watch(ledgerInvariantProvider);

    return ReconciliationCard(
      title: s.ledgerInvariantsTitle,
      subtitle: s.ledgerInvariantsSubtitle,
      icon: Icons.rule_folder_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (!canAct) ...<Widget>[
            Text(
              s.invariantsNeedRole(
                roles: ReconciliationRoles.describe(
                  ReconciliationRoles.actRoles,
                  s,
                ),
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
          ],
          FilledButton.icon(
            onPressed: !canAct || value.isLoading
                ? null
                : () =>
                    unawaited(ref.read(ledgerInvariantProvider.notifier).run()),
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(value.isLoading ? s.sweeping : s.runTheSweep),
          ),
          const SizedBox(height: 10),
          value.when(
            loading: () => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: LoadingStateView(label: s.loadingSweep),
            ),
            error: (Object error, StackTrace stackTrace) => ErrorStateView(
              error: error,
              compact: true,
              onRetry: () =>
                  unawaited(ref.read(ledgerInvariantProvider.notifier).run()),
            ),
            data: (InvariantRun? run) => run == null
                ? Text(
                    s.notSweptYetMessage,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                : _InvariantOutcome(run: run),
          ),
        ],
      ),
    );
  }
}

class _InvariantOutcome extends StatelessWidget {
  const _InvariantOutcome({required this.run});

  final InvariantRun run;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final ThemeData theme = Theme.of(context);
    final LedgerInvariantReport report = run.report;
    final String swept = s.sweptAt(
      timestamp: MoneyFormats.timestampWithAge(
        report.checkedAt,
        s,
        context.localeTag,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (report.isHealthy)
          NoticeStrip(
            message: s.ledgerHealthyTitle,
            tone: StatusTone.approve,
            icon: Icons.verified_outlined,
          )
        else ...<Widget>[
          NoticeStrip(
            message: s.violationsFound(count: report.violations.length),
            tone: StatusTone.reject,
          ),
          if (report.truncated) ...<Widget>[
            const SizedBox(height: 10),
            NoticeStrip(
              message: s.reportTruncatedNotice,
              tone: StatusTone.pending,
            ),
          ],
          const SizedBox(height: 6),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () => context.goNamed(AppRoute.reconciliation),
              icon: const Icon(Icons.open_in_new),
              label: Text(s.reconciliationTitle),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          swept,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
