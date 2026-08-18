import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/money/money.dart';
import 'package:manager_bot/core/theme/app_theme.dart';
import 'package:manager_bot/core/widgets/widgets.dart';
import 'package:manager_bot/features/money/presentation/money_formats.dart';
import 'package:manager_bot/features/reconciliation/application/agent_float_controller.dart';
import 'package:manager_bot/features/reconciliation/application/reconciliation_permissions.dart';
import 'package:manager_bot/features/reconciliation/data/float_sync_result.dart';
import 'package:manager_bot/features/reconciliation/presentation/break_detail_screen.dart';
import 'package:manager_bot/features/reconciliation/presentation/widgets/reconciliation_card.dart';

/// Agent float: our ledger against the Ichancy agent wallet, and the drift.
///
/// Reuses [agentFloatProvider] exactly as the reconciliation workbench does -
/// including the rule that the comparison NEVER runs by itself. It is a POST
/// that can open a break, and opening a tab must not write to the break table.
///
/// The section owns its own loading and error states, so a float failure leaves
/// the breaks and activity sections on screen.
class AgentFloatSection extends ConsumerWidget {
  const AgentFloatSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = context.s;
    final ThemeData theme = Theme.of(context);
    final bool canAct = ref.watch(canActOnReconciliationProvider);
    final AsyncValue<AgentFloatSnapshot?> value = ref.watch(agentFloatProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ReconciliationCard(
          title: s.tabAgentFloat,
          subtitle: s.agentFloatSubtitle,
          icon: Icons.account_balance_wallet_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (!canAct) ...<Widget>[
                Text(
                  s.floatSyncNeedsRole(
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
                        unawaited(ref.read(agentFloatProvider.notifier).sync()),
                icon: const Icon(Icons.sync),
                label: Text(
                  value.isLoading ? s.comparingFloat : s.compareFloatNow,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        value.when(
          loading: () => Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: LoadingStateView(label: s.readingBothSides),
          ),
          error: (Object error, StackTrace stackTrace) => ErrorStateView(
            error: error,
            compact: true,
            onRetry: () =>
                unawaited(ref.read(agentFloatProvider.notifier).sync()),
          ),
          data: (AgentFloatSnapshot? snapshot) {
            if (snapshot == null) {
              return EmptyStateView(
                title: s.noFloatReadingTitle,
                message: s.noFloatReadingMessage,
                icon: Icons.speed_outlined,
              );
            }
            return _FloatReading(snapshot: snapshot);
          },
        ),
      ],
    );
  }
}

class _FloatReading extends StatelessWidget {
  const _FloatReading({required this.snapshot});

  final AgentFloatSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final ThemeData theme = Theme.of(context);
    final FloatSyncResult result = snapshot.result;
    final Money? delta = result.delta;
    final String? breakId = result.breakId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (result.walletUnavailable) ...<Widget>[
          NoticeStrip(
            message: s.walletUnavailableNotice,
            tone: StatusTone.pending,
            icon: Icons.cloud_off_outlined,
          ),
          const SizedBox(height: 12),
        ],
        if (result.belowWatermark) ...<Widget>[
          NoticeStrip(
            message: s.belowWatermarkNotice(
              amount: result.watermarkSubject.format(),
              basis: result.walletUnavailable
                  ? s.watermarkBasisLedger
                  : s.watermarkBasisWallet,
            ),
            tone: StatusTone.failed,
            icon: Icons.battery_alert_outlined,
          ),
          const SizedBox(height: 12),
        ],
        ReconciliationCard(
          title: s.floatReadingAt(
            time: AppDateFormats.timeOfDay(snapshot.readAt, context.localeTag),
          ),
          subtitle: s.floatReadingSubtitle(
            currency: result.currencyCode,
            age: MoneyFormats.since(snapshot.readAt, s),
          ),
          icon: Icons.compare_arrows,
          // The whole card shouts when money is missing, not just one tile.
          tone: result.hasDrift ? StatusTone.failed : null,
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: MetricTile(
                      label: s.metricOurLedger,
                      value: MoneyText(
                        result.ledger,
                        style: AppTheme.moneyStyle(context, fontSize: 17),
                      ),
                      caption: 'ICHANCY_AGENT_FLOAT',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: MetricTile(
                      label: s.metricIchancyWallet,
                      tone: result.walletUnavailable ? StatusTone.pending : null,
                      value: MoneyText(
                        result.ichancy,
                        style: AppTheme.moneyStyle(context, fontSize: 17),
                        placeholder: s.moneyUnavailable,
                      ),
                      caption: s.captionAvailableBalance,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              MetricTile(
                label: s.driftMetricLabel,
                tone: result.hasDrift
                    ? StatusTone.failed
                    : (result.inTolerance
                        ? StatusTone.approve
                        : StatusTone.neutral),
                value: MoneyText(
                  delta,
                  alwaysShowSign: true,
                  colorBySign: true,
                  emphasise: true,
                  placeholder: s.moneyNotComputable,
                ),
                caption: _driftCaption(result, s),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (breakId != null)
          ReconciliationCard(
            title: s.breakOpenedTitle,
            subtitle: s.breakOpenedSubtitle,
            icon: Icons.report_gmailerrorred_outlined,
            tone: StatusTone.failed,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                KeyValueRow(
                  label: s.breakIdLabel,
                  value: breakId,
                  mono: true,
                  copyable: true,
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: () =>
                      unawaited(BreakDetailScreen.open(context, breakId)),
                  icon: const Icon(Icons.open_in_new),
                  label: Text(s.openTheBreak),
                ),
              ],
            ),
          )
        else
          Text(
            result.walletUnavailable
                ? s.noBreakWalletMissing
                : s.noBreakInAgreement,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  static String _driftCaption(FloatSyncResult result, AppStrings s) {
    if (result.walletUnavailable) {
      return s.driftCaptionWalletUnknown;
    }
    if (result.inTolerance) {
      return s.driftCaptionExact;
    }
    return result.ichancyHoldsMore
        ? s.driftCaptionIchancyMore
        : s.driftCaptionLedgerMore;
  }
}
