import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/theme/app_theme.dart';
import 'package:manager_bot/core/widgets/widgets.dart';
import 'package:manager_bot/features/reconciliation/application/ledger_report_controllers.dart';
import 'package:manager_bot/features/reconciliation/data/rail_ageing_report.dart';
import 'package:manager_bot/features/reconciliation/presentation/widgets/break_evidence_view.dart';
import 'package:manager_bot/features/reconciliation/presentation/widgets/reconciliation_card.dart';
import 'package:manager_bot/features/reconciliation/presentation/widgets/reconciliation_formats.dart';

/// Rail ageing: money credited to players that the rail has not confirmed.
///
/// Fresh balances are normal - rails take hours. A balance that keeps ageing is
/// the earliest signal of a fake receipt that got accepted, or of a rail whose
/// statements stopped importing, which is why the open-ended bucket is the one
/// rendered loudest.
class RailAgeingPanel extends ConsumerWidget {
  const RailAgeingPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = context.s;
    final AsyncValue<RailAgeingReport> value =
        ref.watch(railAgeingReportProvider);

    return AsyncValueView<RailAgeingReport>(
      value: value,
      onRetry: () => ref.invalidate(railAgeingReportProvider),
      isEmpty: (RailAgeingReport report) => report.isEmpty,
      emptyTitle: s.emptyRailAgeingTitle,
      emptyMessage: s.emptyRailAgeingMessage,
      emptyIcon: Icons.verified_outlined,
      loadingLabel: s.loadingRailAgeing,
      builder: (BuildContext context, RailAgeingReport report) {
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(railAgeingReportProvider),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: <Widget>[
              if (report.hasStaleAccounts)
                NoticeStrip(
                  message: s.staleAccountsNotice(
                    count: report.staleAccountCodes.length,
                    codes: report.staleAccountCodes.join(', '),
                  ),
                  tone: StatusTone.failed,
                ),
              if (report.hasStaleAccounts) const SizedBox(height: 14),
              Text(
                s.railAgeingGeneratedAt(
                  timestamp: ReconciliationFormats.timestampWithAge(
                    report.generatedAt,
                    s,
                    context.localeTag,
                  ),
                ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 14),
              for (final RailAgeingRow row in report.rowsWorstFirst) ...<Widget>[
                _RailAgeingRowCard(row: row, isStale: report.isStale(row.accountCode)),
                const SizedBox(height: 12),
              ],
              Text(
                s.timesAreLocalNote,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RailAgeingRowCard extends StatelessWidget {
  const _RailAgeingRowCard({required this.row, required this.isStale});

  final RailAgeingRow row;
  final bool isStale;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppStrings s = context.s;
    final DateTime? oldest = row.oldestUnsettledAt;

    return ReconciliationCard(
      title: row.accountCode,
      subtitle: s.railRowSubtitle(
        currency: row.currencyCode,
        count: row.entryCount,
      ),
      icon: Icons.hourglass_bottom_outlined,
      tone: isStale ? StatusTone.failed : null,
      trailing: isStale
          ? StatusChip(
              label: s.chipStale,
              tone: StatusTone.failed,
              dense: true,
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: MetricTile(
                  label: s.metricUnconfirmedBalance,
                  tone: isStale ? StatusTone.failed : null,
                  value: MoneyText(
                    row.balance,
                    colorBySign: true,
                    style: AppTheme.moneyStyle(context, fontSize: 17),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MetricTile(
                  label: s.metricOldestEntry,
                  value: Text(
                    oldest == null
                        ? s.emptyValueDash
                        : ReconciliationFormats.age(
                            DateTime.now().difference(oldest),
                            s,
                          ),
                    style: AppTheme.moneyStyle(context, fontSize: 17),
                  ),
                  caption: oldest == null
                      ? s.captionNoDatedEntries
                      : ReconciliationFormats.day(oldest, context.localeTag),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(s.byAge, style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          RailAgeingBucketStrip(buckets: row.buckets),
          const SizedBox(height: 6),
          KeyValueRow(
            label: s.ledgerAccountLabel,
            value: row.accountId,
            mono: true,
            copyable: true,
          ),
          if (row.paymentMethodId != null)
            KeyValueRow(
              label: s.paymentMethodLabel,
              value: row.paymentMethodId,
              mono: true,
              copyable: true,
            ),
        ],
      ),
    );
  }
}
