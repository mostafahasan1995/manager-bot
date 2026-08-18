import 'package:manager_bot/core/auth/roles.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/theme/app_theme.dart';

/// Every operator-facing string this feature renders that is not a sentence
/// belonging to one screen.
///
/// Kept in one place so "FINANCE_ADMIN" is never printed raw at a user, and so
/// the wire name is still shown next to the label wherever an operator might
/// need to quote it to support.
///
/// Nothing here holds a literal any more: every method resolves against the
/// [AppStrings] bundle the caller passes in, so the whole feature follows the
/// language toggle in Settings.
abstract final class AdminLabels {
  /// Local time, because every timestamp the core parses is already local.
  ///
  /// Local, while the bot prints UTC - any screen showing one of these must
  /// also show [AppStrings.timesAreLocalNote].
  static String timestamp(DateTime? value, AppStrings s, String localeTag) =>
      value == null
          ? s.emptyValueDash
          : AppDateFormats.mediumDayTime(value.toLocal(), localeTag);

  /// "3 days ago" / "in 4 minutes", to two significant units at most.
  static String relative(DateTime? value, AppStrings s, {DateTime? now}) {
    if (value == null) {
      return s.emptyValueDash;
    }
    final DateTime reference = now ?? DateTime.now();
    final Duration delta = reference.difference(value);
    final Duration magnitude = delta.isNegative ? -delta : delta;
    final String phrase = switch (magnitude) {
      final Duration d when d.inSeconds < 45 => s.moments,
      final Duration d when d.inMinutes < 60 =>
        s.relativeMinutes(count: d.inMinutes),
      final Duration d when d.inHours < 24 => s.relativeHours(count: d.inHours),
      final Duration d when d.inDays < 31 => s.relativeDays(count: d.inDays),
      final Duration d when d.inDays < 365 =>
        s.relativeMonths(count: d.inDays ~/ 30),
      final Duration d => s.relativeYears(count: d.inDays ~/ 365),
    };
    return delta.isNegative
        ? s.relativeInFuture(phrase: phrase)
        : s.ageAgo(age: phrase);
  }

  /// The role name an operator reads.
  ///
  /// Deliberately NOT `AdminRole.label`, which is a hard-coded English field on
  /// a core enum this feature does not own.
  static String roleLabel(AdminRole role, AppStrings s) => switch (role) {
        AdminRole.superAdmin => s.roleSuperAdmin,
        AdminRole.financeAdmin => s.roleFinanceAdmin,
        AdminRole.reviewer => s.roleReviewer,
        AdminRole.support => s.roleSupport,
        AdminRole.viewer => s.roleViewer,
      };

  /// Role label plus the wire name, e.g. `Finance admin (FINANCE_ADMIN)`. The
  /// wire name is never translated - it is what support asks for.
  static String roleWithWireName(AdminRole role, AppStrings s) =>
      s.roleWithWireName(label: roleLabel(role, s), wireName: role.wireName);

  /// One line explaining what a role is for, shown under the role picker so a
  /// promotion is never a guess.
  static String roleSummary(AdminRole role, AppStrings s) => switch (role) {
        AdminRole.superAdmin => s.roleSummarySuperAdmin,
        AdminRole.financeAdmin => s.roleSummaryFinanceAdmin,
        AdminRole.reviewer => s.roleSummaryReviewer,
        AdminRole.support => s.roleSummarySupport,
        AdminRole.viewer => s.roleSummaryViewer,
      };

  /// A colour cue for the role chip: authority over money reads warmer.
  static StatusTone roleTone(AdminRole role) => switch (role) {
        AdminRole.superAdmin => StatusTone.failed,
        AdminRole.financeAdmin => StatusTone.pending,
        AdminRole.reviewer => StatusTone.info,
        AdminRole.support || AdminRole.viewer => StatusTone.neutral,
      };

  /// Operator-facing name of one capability, for the profile screen.
  static String capability(AdminCapability capability, AppStrings s) =>
      switch (capability) {
        AdminCapability.viewDepositQueue => s.capViewDepositQueue,
        AdminCapability.reviewDeposit => s.capReviewDeposit,
        AdminCapability.secondApproveDeposit => s.capSecondApprove,
        AdminCapability.retryCredit => s.capRetryCredit,
        AdminCapability.viewReconciliation => s.capViewReconciliation,
        AdminCapability.resolveReconciliationBreak => s.capResolveBreak,
        AdminCapability.viewPaymentMethods => s.capViewPaymentMethods,
        AdminCapability.managePaymentDestinations =>
          s.capManagePaymentDestinations,
        AdminCapability.viewAdminUsers => s.capViewAdminUsers,
        AdminCapability.manageAdminUsers => s.capManageAdminUsers,
        AdminCapability.viewLedger => s.capViewLedger,
      };

  /// "12 of 40 administrators" style counters, with the Arabic plural rules
  /// applied by the catalogue.
  static String countOf(int shown, int total, AppStrings s) => shown == total
      ? s.auCountTotal(total: total)
      : s.auCountShownOfTotal(shown: shown, total: total);
}
