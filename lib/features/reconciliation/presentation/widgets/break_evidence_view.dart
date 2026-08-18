import 'package:flutter/material.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/theme/app_theme.dart';
import 'package:manager_bot/core/widgets/widgets.dart';
import 'package:manager_bot/features/reconciliation/data/break_view.dart';
import 'package:manager_bot/features/reconciliation/data/rail_ageing_report.dart';
import 'package:manager_bot/features/reconciliation/presentation/widgets/reconciliation_card.dart';
import 'package:manager_bot/features/reconciliation/presentation/widgets/reconciliation_formats.dart';

/// Renders `BreakView.detail`, the free-form blob a detector left behind.
///
/// Nothing validates that column server-side and each detector writes its own
/// shape, so this widget assumes NOTHING: the known keys (`hint`, `message`,
/// `invariant`, `buckets`) get a first-class rendering and everything else is
/// listed as label/value. A future detector adding a key degrades to one more
/// row rather than to a crash.
class BreakEvidenceView extends StatelessWidget {
  const BreakEvidenceView({required this.breakView, super.key});

  final BreakView breakView;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppStrings s = context.s;
    final BreakDetail detail = breakView.detail;

    if (detail.isEmpty) {
      return Text(
        s.noDetectorEvidence,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    // `message` and `hint` are sentences the DETECTOR wrote; they are shown
    // verbatim because the client cannot translate free-form server prose.
    final String? message = detail.message;
    final String? hint = detail.hint;
    final List<RailAgeingBucket> buckets =
        detail.buckets(currency: breakView.currencyCode);
    final List<BreakDetailEntry> entries =
        detail.entries(s, currency: breakView.currencyCode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (message != null) ...<Widget>[
          Text(message, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 12),
        ],
        if (hint != null) ...<Widget>[
          NoticeStrip(
            message: hint,
            tone: StatusTone.info,
            icon: Icons.lightbulb_outline,
          ),
          const SizedBox(height: 12),
        ],
        if (buckets.isNotEmpty) ...<Widget>[
          Text(s.ageingAtDetection, style: theme.textTheme.labelLarge),
          const SizedBox(height: 6),
          RailAgeingBucketStrip(buckets: buckets),
          const SizedBox(height: 12),
        ],
        for (final BreakDetailEntry entry in entries)
          if (entry.key != 'hint' && entry.key != 'message' && entry.key != 'buckets')
            KeyValueRow(
              label: entry.label,
              value: entry.value,
              mono: !entry.isMoney,
            ),
      ],
    );
  }
}

/// The age buckets of one rail clearing account, youngest first.
///
/// The list is SPARSE - only buckets with entries are sent - so nothing here
/// indexes by position; each bucket carries its own label and bounds.
class RailAgeingBucketStrip extends StatelessWidget {
  const RailAgeingBucketStrip({required this.buckets, super.key});

  final List<RailAgeingBucket> buckets;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppStrings s = context.s;
    if (buckets.isEmpty) {
      return Text(
        s.noEntriesInAnyBucket,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }
    return Column(
      children: <Widget>[
        for (final RailAgeingBucket bucket in buckets)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 62,
                  child: StatusChip(
                    label: bucket.displayLabel(s),
                    tone: bucket.isOpenEnded
                        ? StatusTone.reject
                        : (bucket.isAgeing ? StatusTone.pending : StatusTone.neutral),
                    dense: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: MoneyText(
                    bucket.net,
                    alwaysShowSign: true,
                    colorBySign: true,
                    style: AppTheme.moneyStyle(context, fontSize: 14),
                  ),
                ),
                Text(
                  s.entriesCount(count: bucket.entryCount),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The ids a break links to. They are UUIDs, not human references: there is no
/// admin endpoint that turns a `depositRequestId` into a deposit shortId, so
/// they are shown as copyable evidence rather than as navigation.
class BreakLinksView extends StatelessWidget {
  const BreakLinksView({required this.breakView, super.key});

  final BreakView breakView;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppStrings s = context.s;
    final List<Widget> rows = <Widget>[
      if (breakView.depositRequestId != null)
        KeyValueRow(
          label: s.linkDepositRequest,
          value: breakView.depositRequestId,
          mono: true,
          copyable: true,
        ),
      if (breakView.playerId != null)
        KeyValueRow(
          label: s.playerLabel,
          value: breakView.playerId,
          mono: true,
          copyable: true,
        ),
      if (breakView.ledgerAccountId != null)
        KeyValueRow(
          label: s.ledgerAccountLabel,
          value: breakView.ledgerAccountId,
          mono: true,
          copyable: true,
        ),
      if (breakView.ichancyCallId != null)
        KeyValueRow(
          label: s.linkIchancyCall,
          value: breakView.ichancyCallId,
          mono: true,
          copyable: true,
        ),
      if (breakView.resolutionTxId != null)
        KeyValueRow(
          label: s.linkCorrectionTransaction,
          value: breakView.resolutionTxId,
          mono: true,
          copyable: true,
        ),
    ];

    if (rows.isEmpty) {
      return Text(
        s.noLinkedRecords,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (breakView.touchesDeposit) ...<Widget>[
          NoticeStrip(
            message: s.breakTouchesDepositNotice,
            tone: StatusTone.failed,
            icon: Icons.receipt_long_outlined,
          ),
          const SizedBox(height: 10),
        ],
        ...rows,
        const SizedBox(height: 4),
        Text(
          s.detectedAt(
            timestamp: ReconciliationFormats.timestampWithAge(
              breakView.detectedAt,
              s,
              context.localeTag,
            ),
          ),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
