import 'package:flutter/material.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/ui/ui.dart';
import 'package:manager_bot/features/shell/activity/data/activity_models.dart';

/// The one place a deposit status becomes a colour, a glyph and a word.
///
/// Keeping the mapping here means the chip in the list, the ring on the row and
/// the header of the detail sheet can never disagree about what "قيد المراجعة"
/// looks like.
abstract final class ActivityStatusStyle {
  /// Already-localised status word.
  static String label(AppStrings s, ActivityStatus status) => switch (status) {
        ActivityStatus.submitted => s.statusSubmitted,
        ActivityStatus.underReview => s.statusUnderReview,
        ActivityStatus.approved => s.statusApproved,
        ActivityStatus.crediting => s.statusCrediting,
        ActivityStatus.credited => s.statusCredited,
        ActivityStatus.rejected => s.statusRejected,
        ActivityStatus.expired => s.statusExpired,
      };

  /// Semantic tone driving every colour the row uses.
  static AppTone tone(ActivityStatus status) => switch (status) {
        ActivityStatus.submitted => AppTone.pending,
        ActivityStatus.underReview => AppTone.pending,
        ActivityStatus.approved => AppTone.approved,
        ActivityStatus.crediting => AppTone.info,
        ActivityStatus.credited => AppTone.credited,
        ActivityStatus.rejected => AppTone.rejected,
        ActivityStatus.expired => AppTone.neutral,
      };

  /// The glyph inside the row's avatar ring.
  static IconData icon(ActivityStatus status) => switch (status) {
        ActivityStatus.submitted => Icons.upload_file_rounded,
        ActivityStatus.underReview => Icons.hourglass_bottom_rounded,
        ActivityStatus.approved => Icons.verified_rounded,
        ActivityStatus.crediting => Icons.bolt_rounded,
        ActivityStatus.credited => Icons.check_circle_rounded,
        ActivityStatus.rejected => Icons.block_rounded,
        ActivityStatus.expired => Icons.timer_off_rounded,
      };

  /// The ring gradient. Terminal-unhappy rows get no gradient at all - see
  /// [isRingActive] - so celebration is reserved for money that landed.
  static LinearGradient gradient(ActivityStatus status) => switch (status) {
        ActivityStatus.submitted => AppPalette.gradientSunset,
        ActivityStatus.underReview => AppPalette.gradientSunset,
        ActivityStatus.approved => AppPalette.gradientNeon,
        ActivityStatus.crediting => AppPalette.gradientHot,
        ActivityStatus.credited => AppPalette.gradientCredited,
        ActivityStatus.rejected => AppPalette.gradientGlitch,
        ActivityStatus.expired => AppPalette.gradientSurface,
      };

  /// False draws a flat outline ring instead of the gradient one.
  static bool isRingActive(ActivityStatus status) =>
      status != ActivityStatus.expired;
}

/// Labels, tones and glyphs for the four chips across the top.
abstract final class ActivityFilterStyle {
  /// Chip order, start to end. `ActivityFilter.values` already reads correctly.
  static const List<ActivityFilter> ordered = ActivityFilter.values;

  static String label(AppStrings s, ActivityFilter filter) => switch (filter) {
        ActivityFilter.all => s.filterAll,
        ActivityFilter.inReview => s.activityFilterInReview,
        ActivityFilter.completed => s.activityFilterCompleted,
        ActivityFilter.rejected => s.activityFilterRejected,
      };

  /// Tone of the SELECTED chip. An unselected chip is always neutral.
  static AppTone tone(ActivityFilter filter) => switch (filter) {
        ActivityFilter.all => AppTone.info,
        ActivityFilter.inReview => AppTone.pending,
        ActivityFilter.completed => AppTone.credited,
        ActivityFilter.rejected => AppTone.rejected,
      };

  static IconData icon(ActivityFilter filter) => switch (filter) {
        ActivityFilter.all => Icons.all_inclusive_rounded,
        ActivityFilter.inReview => Icons.hourglass_bottom_rounded,
        ActivityFilter.completed => Icons.check_circle_rounded,
        ActivityFilter.rejected => Icons.block_rounded,
      };
}

/// Plain-language copy for one rung of the timeline.
///
/// The whole point of the detail sheet is that a player reads it and knows
/// what happened and what is about to happen, without a glossary.
abstract final class ActivityStepCopy {
  static String title(AppStrings s, ActivityStepKind kind) => switch (kind) {
        ActivityStepKind.submitted => s.activityStepSubmittedTitle,
        ActivityStepKind.review => s.activityStepReviewTitle,
        ActivityStepKind.decision => s.activityStepApprovedTitle,
        ActivityStepKind.credited => s.activityStepCreditedTitle,
        ActivityStepKind.rejected => s.activityStepRejectedTitle,
        ActivityStepKind.expired => s.activityStepExpiredTitle,
      };

  static String body(AppStrings s, ActivityStepKind kind) => switch (kind) {
        ActivityStepKind.submitted => s.activityStepSubmittedBody,
        ActivityStepKind.review => s.activityStepReviewBody,
        ActivityStepKind.decision => s.activityStepApprovedBody,
        ActivityStepKind.credited => s.activityStepCreditedBody,
        ActivityStepKind.rejected => s.activityStepRejectedBody,
        ActivityStepKind.expired => s.activityStepExpiredBody,
      };

  static IconData icon(ActivityStepKind kind) => switch (kind) {
        ActivityStepKind.submitted => Icons.upload_file_rounded,
        ActivityStepKind.review => Icons.visibility_rounded,
        ActivityStepKind.decision => Icons.verified_rounded,
        ActivityStepKind.credited => Icons.account_balance_wallet_rounded,
        ActivityStepKind.rejected => Icons.block_rounded,
        ActivityStepKind.expired => Icons.timer_off_rounded,
      };

  /// Tone of one rung, given how far along it is.
  static AppTone tone(ActivityStepState state, AppTone statusTone) =>
      switch (state) {
        ActivityStepState.done => AppTone.credited,
        ActivityStepState.current => statusTone,
        ActivityStepState.upcoming => AppTone.neutral,
        ActivityStepState.failed => AppTone.rejected,
      };
}

/// Relative ages, in the same words the admin console already uses.
///
/// Digits stay Western in both locales because `AppStrings.age*` interpolates
/// them directly - the same rule every amount in this app follows.
abstract final class ActivityAge {
  /// "منذ 12 د" / "12m ago", or "الآن" / "now" under 45 seconds.
  static String relative(AppStrings s, DateTime moment, {DateTime? now}) {
    final DateTime reference = now ?? DateTime.now();
    final Duration delta = reference.difference(moment);
    if (delta.isNegative) {
      return s.ageInFuture;
    }
    if (delta.inSeconds < 45) {
      return s.ageNow;
    }
    if (delta.inMinutes < 60) {
      return s.ageAgo(age: s.ageMinutes(count: delta.inMinutes));
    }
    if (delta.inHours < 24) {
      return s.ageAgo(age: s.ageHours(count: delta.inHours));
    }
    return s.ageAgo(age: s.ageDays(count: delta.inDays));
  }
}
