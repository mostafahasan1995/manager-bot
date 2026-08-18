import 'package:flutter/material.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/theme/app_theme.dart';
import 'package:manager_bot/features/deposits/data/admin_deposit_view.dart';
import 'package:manager_bot/features/deposits/data/deposit_enums.dart';
import 'package:manager_bot/features/deposits/presentation/widgets/deposit_formatting.dart';

/// One dated step in a deposit's life.
class DepositTimelineEvent {
  const DepositTimelineEvent({
    required this.at,
    required this.title,
    required this.icon,
    required this.tone,
    this.subtitle,
  });

  final DateTime at;
  final String title;
  final String? subtitle;
  final IconData icon;
  final StatusTone tone;
}

/// The deposit's history, DERIVED FROM ITS OWN TIMESTAMPS.
///
/// There is deliberately no invented endpoint here: `DepositAdminController`
/// exposes no transition-history route, and `DepositTransition` rows are not
/// published anywhere on the admin surface. Everything below is reconstructed
/// from fields the deposit actually carries (`createdAt`, `submittedAt`,
/// `reviewStartedAt`, `decidedAt`, `creditedAt`, `expiresAt`), so it is honest
/// about what is known rather than pretending to a full audit log.
class DepositTimeline extends StatelessWidget {
  const DepositTimeline({required this.deposit, required this.now, super.key});

  final AdminDepositView deposit;
  final DateTime now;

  /// Builds the event list, newest last, skipping timestamps that are null.
  static List<DepositTimelineEvent> eventsFor(
    AdminDepositView deposit,
    AppStrings s,
  ) {
    final List<DepositTimelineEvent> events = <DepositTimelineEvent>[
      DepositTimelineEvent(
        at: deposit.createdAt,
        title: s.timelineCreated,
        icon: Icons.add_circle_outline,
        tone: StatusTone.neutral,
      ),
    ];

    final DateTime? submitted = deposit.submittedAt;
    if (submitted != null) {
      events.add(
        DepositTimelineEvent(
          at: submitted,
          title: s.timelineSubmitted,
          subtitle: deposit.proofCount == 0
              ? s.timelineNoProofAttached
              : s.timelineProofsAttached(count: deposit.proofCount),
          icon: Icons.upload_file_outlined,
          tone: StatusTone.pending,
        ),
      );
    }

    final DateTime? claimed = deposit.reviewStartedAt;
    if (claimed != null) {
      events.add(
        DepositTimelineEvent(
          at: claimed,
          title: s.timelineClaimed,
          subtitle: deposit.decidedByAdminId == null
              ? null
              : s.timelineAdmin(
                  id: DepositFormat.shortId(deposit.decidedByAdminId, s),
                ),
          icon: Icons.lock_clock,
          tone: StatusTone.info,
        ),
      );
    }

    final DateTime? decided = deposit.decidedAt;
    if (decided != null) {
      events.add(_decisionEvent(deposit, decided, s));
    }

    final DateTime? credited = deposit.creditedAt;
    if (credited != null) {
      events.add(
        DepositTimelineEvent(
          at: credited,
          title: s.timelineCredited,
          subtitle: deposit.creditVerifiedBy?.label(s),
          icon: Icons.check_circle_outline,
          tone: StatusTone.approve,
        ),
      );
    }

    final DateTime? expires = deposit.expiresAt;
    if (expires != null && !deposit.status.isTerminal) {
      events.add(
        DepositTimelineEvent(
          at: expires,
          title: s.timelineExpires,
          icon: Icons.hourglass_bottom,
          tone: StatusTone.neutral,
        ),
      );
    }

    events.sort(
      (DepositTimelineEvent a, DepositTimelineEvent b) => a.at.compareTo(b.at),
    );
    return List<DepositTimelineEvent>.unmodifiable(events);
  }

  static DepositTimelineEvent _decisionEvent(
    AdminDepositView deposit,
    DateTime decided,
    AppStrings s,
  ) {
    switch (deposit.status) {
      case DepositStatus.rejected:
        final String reason = RejectionCode.labelFor(deposit.rejectionCode, s);
        final String? note = deposit.rejectionNote;
        return DepositTimelineEvent(
          at: decided,
          title: s.timelineRejectedWithReason(reason: reason),
          subtitle: note,
          icon: Icons.cancel_outlined,
          tone: StatusTone.reject,
        );
      case DepositStatus.pendingSecondApproval:
        return DepositTimelineEvent(
          at: decided,
          title: s.timelineFirstApproval,
          subtitle: s.timelineFirstApprovalSubtitle,
          icon: Icons.how_to_reg_outlined,
          tone: StatusTone.pending,
        );
      case DepositStatus.draft:
      case DepositStatus.awaitingProof:
      case DepositStatus.submitted:
      case DepositStatus.underReview:
      case DepositStatus.approved:
      case DepositStatus.crediting:
      case DepositStatus.credited:
      case DepositStatus.creditFailed:
      case DepositStatus.needsReconciliation:
      case DepositStatus.expired:
      case DepositStatus.reversed:
        return DepositTimelineEvent(
          at: decided,
          title: s.timelineApproved,
          subtitle: deposit.secondApproverAdminId == null
              ? null
              : s.timelineSecondApprover(
                  id: DepositFormat.shortId(deposit.secondApproverAdminId, s),
                ),
          icon: Icons.verified_outlined,
          tone: StatusTone.approve,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final List<DepositTimelineEvent> events = eventsFor(deposit, s);
    final AppSemanticColors semantics = AppSemanticColors.of(context);
    final ThemeData theme = Theme.of(context);
    final TextStyle? caption = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (int i = 0; i < events.length; i++)
          _TimelineTile(
            event: events[i],
            isLast: i == events.length - 1,
            now: now,
            color: semantics.tone(events[i].tone).foreground,
          ),
        const SizedBox(height: 6),
        Text(s.timelineFooter, style: caption),
        const SizedBox(height: 2),
        // Every stamp above is LOCAL time while the bot prints UTC.
        Text(s.timesAreLocalNote, style: caption),
      ],
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.event,
    required this.isLast,
    required this.now,
    required this.color,
  });

  final DepositTimelineEvent event;
  final bool isLast;
  final DateTime now;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppStrings s = context.s;
    final String localeTag = context.localeTag;
    final bool isFuture = event.at.isAfter(now);
    final String? subtitle = event.subtitle;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Column(
            children: <Widget>[
              Icon(event.icon, size: 18, color: color),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.5,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsetsDirectional.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    event.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isFuture
                        ? s.timelineFuture(
                            timestamp: DepositFormat.timestamp(
                              event.at,
                              s,
                              localeTag,
                            ),
                            timeLeft:
                                DepositFormat.timeLeft(event.at, s, now: now) ??
                                    s.moments,
                          )
                        : DepositFormat.timestampWithAge(
                            event.at,
                            s,
                            localeTag,
                            now: now,
                          ),
                    style: AppTheme.monoStyle(context),
                  ),
                  if (subtitle != null) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
