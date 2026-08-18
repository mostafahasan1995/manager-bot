import 'package:manager_bot/core/money/money.dart';

/// Where one top-up stands right now, in the PLAYER's language.
///
/// Deliberately shorter than the admin console's `DepositStatus`: a player
/// never needs to hear about second approvals, reconciliation holds or credit
/// epochs, so those collapse into [underReview] and [crediting]. When the live
/// repository is wired in, mapping the wire enum onto this one is the only
/// translation the screen needs.
enum ActivityStatus {
  /// The receipt was uploaded and is queued for a human.
  submitted,

  /// A cashier is looking at it right now.
  underReview,

  /// A human said yes; the casino balance has not moved yet.
  approved,

  /// The credit is being pushed to the casino account.
  crediting,

  /// The money is in the casino balance. Terminal, happy.
  credited,

  /// Refused. Terminal, with a staff note explaining why.
  rejected,

  /// No matching transfer arrived in time. Terminal, no money moved.
  expired;

  /// True while the request can still change on its own.
  bool get isOpen => switch (this) {
        ActivityStatus.submitted => true,
        ActivityStatus.underReview => true,
        ActivityStatus.approved => true,
        ActivityStatus.crediting => true,
        ActivityStatus.credited => false,
        ActivityStatus.rejected => false,
        ActivityStatus.expired => false,
      };

  /// True when the request ended without the balance moving.
  bool get isUnsuccessful =>
      this == ActivityStatus.rejected || this == ActivityStatus.expired;
}

/// The four chips across the top of إيداعاتي.
///
/// The mapping lives here, not in the screen, so the same rule is used by the
/// list, by the counters and by any test.
enum ActivityFilter {
  /// الكل
  all,

  /// قيد المراجعة - everything still moving.
  inReview,

  /// مكتملة - money landed.
  completed,

  /// مرفوضة - refused or expired.
  rejected;

  /// Whether a row with [status] belongs under this chip.
  bool matches(ActivityStatus status) => switch (this) {
        ActivityFilter.all => true,
        ActivityFilter.inReview => status.isOpen,
        ActivityFilter.completed => status == ActivityStatus.credited,
        ActivityFilter.rejected => status.isUnsuccessful,
      };
}

/// One rung of the "what happened / what comes next" ladder.
enum ActivityStepKind {
  /// The player uploaded the receipt.
  submitted,

  /// Staff are matching the receipt against the incoming transfer.
  review,

  /// A cashier decided.
  decision,

  /// The casino balance moved.
  credited,

  /// Terminal: refused.
  rejected,

  /// Terminal: timed out.
  expired,
}

/// How far along one [ActivityStepKind] is.
enum ActivityStepState {
  /// Already behind us.
  done,

  /// Happening now. At most one step is ever in this state.
  current,

  /// Still ahead.
  upcoming,

  /// This is where the request stopped for a bad reason.
  failed,
}

/// A single rung, with the moment it happened when that moment is known.
class ActivityStep {
  const ActivityStep({required this.kind, required this.state, this.at});

  final ActivityStepKind kind;
  final ActivityStepState state;

  /// Local time, or null for a step that has not happened yet.
  final DateTime? at;
}

/// One row of the player's deposit history.
///
/// Every amount is [Money] - exact `BigInt` minor units at scale 2 - and every
/// timestamp is local time, so the screen must show `AppStrings.timesAreLocalNote`
/// somewhere. Nothing here is localised copy: [methodName], [destinationLabel],
/// [senderName], [reference] and [staffNote] are RECORD VALUES that the live API
/// would return exactly as written.
class ActivityDeposit {
  const ActivityDeposit({
    required this.shortId,
    required this.amount,
    required this.methodName,
    required this.destinationLabel,
    required this.senderName,
    required this.status,
    required this.submittedAt,
    this.reviewStartedAt,
    this.decidedAt,
    this.settledAt,
    this.reference,
    this.credited,
    this.staffNote,
  });

  /// Short, human-quotable id, e.g. `DP-9F41`. Stable across pages.
  final String shortId;

  /// What the player says they sent.
  final Money amount;

  /// Payment method display name as the backend stores it.
  final String methodName;

  /// The account or wallet the money was sent to, already masked.
  final String destinationLabel;

  /// Name on the transfer.
  final String senderName;

  final ActivityStatus status;

  /// When the receipt was uploaded.
  final DateTime submittedAt;

  /// When a cashier picked it up.
  final DateTime? reviewStartedAt;

  /// When a cashier approved or refused it.
  final DateTime? decidedAt;

  /// When the casino balance actually moved.
  final DateTime? settledAt;

  /// Transfer reference the player typed, when the rail requires one.
  final String? reference;

  /// What actually landed. Differs from [amount] when the rail charges a fee.
  final Money? credited;

  /// Free text a cashier attached, most often the rejection reason.
  final String? staffNote;

  /// The newest moment on this record - what the row's relative age counts from.
  DateTime get lastEventAt =>
      settledAt ?? decidedAt ?? reviewStartedAt ?? submittedAt;

  /// The rungs to draw, in order, for this record's status.
  ///
  /// A refused or expired request replaces the last two rungs with a single
  /// failed one: showing a greyed-out "credited" step under a rejection reads
  /// as "it might still happen", which is a lie.
  List<ActivityStep> get timeline => switch (status) {
        ActivityStatus.submitted => <ActivityStep>[
            ActivityStep(
              kind: ActivityStepKind.submitted,
              state: ActivityStepState.done,
              at: submittedAt,
            ),
            const ActivityStep(
              kind: ActivityStepKind.review,
              state: ActivityStepState.current,
            ),
            const ActivityStep(
              kind: ActivityStepKind.decision,
              state: ActivityStepState.upcoming,
            ),
            const ActivityStep(
              kind: ActivityStepKind.credited,
              state: ActivityStepState.upcoming,
            ),
          ],
        ActivityStatus.underReview => <ActivityStep>[
            ActivityStep(
              kind: ActivityStepKind.submitted,
              state: ActivityStepState.done,
              at: submittedAt,
            ),
            ActivityStep(
              kind: ActivityStepKind.review,
              state: ActivityStepState.current,
              at: reviewStartedAt,
            ),
            const ActivityStep(
              kind: ActivityStepKind.decision,
              state: ActivityStepState.upcoming,
            ),
            const ActivityStep(
              kind: ActivityStepKind.credited,
              state: ActivityStepState.upcoming,
            ),
          ],
        ActivityStatus.approved => <ActivityStep>[
            ActivityStep(
              kind: ActivityStepKind.submitted,
              state: ActivityStepState.done,
              at: submittedAt,
            ),
            ActivityStep(
              kind: ActivityStepKind.review,
              state: ActivityStepState.done,
              at: reviewStartedAt,
            ),
            ActivityStep(
              kind: ActivityStepKind.decision,
              state: ActivityStepState.done,
              at: decidedAt,
            ),
            const ActivityStep(
              kind: ActivityStepKind.credited,
              state: ActivityStepState.current,
            ),
          ],
        ActivityStatus.crediting => <ActivityStep>[
            ActivityStep(
              kind: ActivityStepKind.submitted,
              state: ActivityStepState.done,
              at: submittedAt,
            ),
            ActivityStep(
              kind: ActivityStepKind.review,
              state: ActivityStepState.done,
              at: reviewStartedAt,
            ),
            ActivityStep(
              kind: ActivityStepKind.decision,
              state: ActivityStepState.done,
              at: decidedAt,
            ),
            const ActivityStep(
              kind: ActivityStepKind.credited,
              state: ActivityStepState.current,
            ),
          ],
        ActivityStatus.credited => <ActivityStep>[
            ActivityStep(
              kind: ActivityStepKind.submitted,
              state: ActivityStepState.done,
              at: submittedAt,
            ),
            ActivityStep(
              kind: ActivityStepKind.review,
              state: ActivityStepState.done,
              at: reviewStartedAt,
            ),
            ActivityStep(
              kind: ActivityStepKind.decision,
              state: ActivityStepState.done,
              at: decidedAt,
            ),
            ActivityStep(
              kind: ActivityStepKind.credited,
              state: ActivityStepState.done,
              at: settledAt,
            ),
          ],
        ActivityStatus.rejected => <ActivityStep>[
            ActivityStep(
              kind: ActivityStepKind.submitted,
              state: ActivityStepState.done,
              at: submittedAt,
            ),
            ActivityStep(
              kind: ActivityStepKind.review,
              state: ActivityStepState.done,
              at: reviewStartedAt,
            ),
            ActivityStep(
              kind: ActivityStepKind.rejected,
              state: ActivityStepState.failed,
              at: decidedAt,
            ),
          ],
        ActivityStatus.expired => <ActivityStep>[
            ActivityStep(
              kind: ActivityStepKind.submitted,
              state: ActivityStepState.done,
              at: submittedAt,
            ),
            ActivityStep(
              kind: ActivityStepKind.expired,
              state: ActivityStepState.failed,
              at: decidedAt,
            ),
          ],
      };

  /// The rung the player is waiting on, or null once the record is terminal.
  ActivityStep? get currentStep {
    for (final ActivityStep step in timeline) {
      if (step.state == ActivityStepState.current) {
        return step;
      }
    }
    return null;
  }

  /// The rung that ended the record badly, or null.
  ActivityStep? get failedStep {
    for (final ActivityStep step in timeline) {
      if (step.state == ActivityStepState.failed) {
        return step;
      }
    }
    return null;
  }
}

/// One locally-paged slice of the history.
class ActivityPage {
  const ActivityPage({
    required this.items,
    required this.hasMore,
    required this.total,
  });

  /// Rows in this slice, newest first.
  final List<ActivityDeposit> items;

  /// Another slice exists after this one.
  final bool hasMore;

  /// How many rows match the filter in total, across every slice.
  final int total;
}

/// The numbers the header strip shows. Computed over the WHOLE history, not
/// over the loaded page, so scrolling never changes them.
class ActivitySummary {
  const ActivitySummary({
    required this.totalCredited,
    required this.openCount,
    required this.totalCount,
  });

  /// Sum of every amount that actually landed in the casino balance.
  final Money totalCredited;

  /// How many requests are still moving.
  final int openCount;

  /// How many requests exist at all.
  final int totalCount;
}

/// Thrown when the history cannot be read.
///
/// The demo source only raises it when explicitly told to, but the screen
/// renders the error branch from it either way, so the shape is already right
/// when the bearer-token repository replaces the demo one.
class ActivityUnavailable implements Exception {
  const ActivityUnavailable(this.reason);

  /// Machine reason code, shown as the small dim detail line.
  final String reason;

  @override
  String toString() => 'ActivityUnavailable($reason)';
}

/// The seam. Swap the single implementation registered in
/// `activityRepositoryProvider` and every screen below keeps working.
abstract class ActivityRepository {
  /// One slice of the filtered history, newest first.
  Future<ActivityPage> page({
    required ActivityFilter filter,
    required int offset,
    required int limit,
  });

  /// Totals over the whole history, unfiltered.
  Future<ActivitySummary> summary();
}
