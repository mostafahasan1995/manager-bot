import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/theme/app_theme.dart';
import 'package:manager_bot/core/widgets/widgets.dart';
import 'package:manager_bot/features/reconciliation/application/ledger_report_controllers.dart';
import 'package:manager_bot/features/reconciliation/application/reconciliation_permissions.dart';
import 'package:manager_bot/features/reconciliation/data/ledger_invariant_report.dart';
import 'package:manager_bot/features/reconciliation/presentation/widgets/reconciliation_card.dart';
import 'package:manager_bot/features/reconciliation/presentation/widgets/reconciliation_formats.dart';

/// Ledger invariants I1/I2/I3, run on demand.
///
/// The sweep is a POST: it repairs the I3 cache and persists a
/// `LEDGER_IMBALANCE` break for every violation, so it is never fired by simply
/// opening the tab. It is also the slowest call in the module - three full
/// aggregates in one transaction.
class LedgerInvariantsPanel extends ConsumerWidget {
  const LedgerInvariantsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AppStrings s = context.s;
    final bool canAct = ref.watch(canActOnReconciliationProvider);
    final AsyncValue<InvariantRun?> value = ref.watch(ledgerInvariantProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: <Widget>[
        ReconciliationCard(
          title: s.ledgerInvariantsTitle,
          subtitle: s.ledgerInvariantsSubtitle,
          icon: Icons.rule_folder_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (!canAct)
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
              if (!canAct) const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: !canAct || value.isLoading
                    ? null
                    : () => unawaited(
                          ref.read(ledgerInvariantProvider.notifier).run(),
                        ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(value.isLoading ? s.sweeping : s.runTheSweep),
              ),
              const SizedBox(height: 8),
              Text(
                s.sweepWarning,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        value.when(
          loading: () => Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: LoadingStateView(label: s.loadingSweep),
          ),
          error: (Object error, StackTrace stackTrace) => ErrorStateView(
            error: error,
            compact: true,
            onRetry: () =>
                unawaited(ref.read(ledgerInvariantProvider.notifier).run()),
          ),
          data: (InvariantRun? run) {
            if (run == null) {
              return EmptyStateView(
                title: s.notSweptYetTitle,
                message: s.notSweptYetMessage,
                icon: Icons.fact_check_outlined,
              );
            }
            return _InvariantReportView(run: run);
          },
        ),
        // The sweep timestamp is the device's local clock; the bot prints UTC.
        if (value.valueOrNull != null) ...<Widget>[
          const SizedBox(height: 16),
          Text(
            s.timesAreLocalNote,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _InvariantReportView extends StatelessWidget {
  const _InvariantReportView({required this.run});

  final InvariantRun run;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppStrings s = context.s;
    final LedgerInvariantReport report = run.report;
    final String checkedAt = ReconciliationFormats.timestampWithAge(
      report.checkedAt,
      s,
      context.localeTag,
    );

    if (report.isHealthy) {
      return ReconciliationCard(
        title: s.ledgerHealthyTitle,
        subtitle: checkedAt,
        icon: Icons.verified_outlined,
        tone: StatusTone.approve,
        child: Text(
          s.ledgerHealthyBody,
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
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
        const SizedBox(height: 12),
        Text(
          s.sweptAt(timestamp: checkedAt),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        for (final LedgerInvariantViolation violation
            in report.violationsWorstFirst) ...<Widget>[
          _ViolationCard(violation: violation),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _ViolationCard extends StatelessWidget {
  const _ViolationCard({required this.violation});

  final LedgerInvariantViolation violation;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppStrings s = context.s;

    return ReconciliationCard(
      title: violation.invariant == LedgerInvariant.unknown
          ? violation.invariantWire
          : violation.invariant.label(s),
      subtitle: violation.invariant.explanation(s),
      icon: Icons.error_outline,
      tone: violation.invariant.tone,
      trailing: StatusChip(
        label: violation.currencyCode,
        tone: StatusTone.neutral,
        dense: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(violation.detail, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 12),
          if (violation.valuesAreEntryCounts)
            NoticeStrip(
              message: s.entryCountsNoticeShort,
              tone: StatusTone.info,
              icon: Icons.info_outline,
            ),
          if (violation.valuesAreEntryCounts) const SizedBox(height: 10),
          KeyValueRow(
            label: s.subjectIdLabel(
              subjectKind: violation.invariant.subjectKind(s),
            ),
            value: violation.subject,
            mono: true,
            copyable: true,
          ),
          KeyValueRow(
            label: s.expectedLabel,
            value: violation.expectedLabel(s),
          ),
          KeyValueRow(label: s.actualLabel, value: violation.actualLabel(s)),
          KeyValueRow(
            label: s.differenceLabel,
            value: violation.deltaLabel(s),
          ),
        ],
      ),
    );
  }
}
