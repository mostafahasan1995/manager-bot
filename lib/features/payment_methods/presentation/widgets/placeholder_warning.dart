import 'package:flutter/material.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/theme/app_theme.dart';
import 'package:manager_bot/core/widgets/widgets.dart';
import 'package:manager_bot/features/payment_methods/application/payment_method_providers.dart';
import 'package:manager_bot/features/payment_methods/data/admin_payment_destination_view.dart';
import 'package:manager_bot/features/payment_methods/presentation/widgets/section_card.dart';

/// The single most important warning on this screen.
///
/// The backend seeds PLACEHOLDER destinations so a fresh install can render a
/// deposit flow, and STATUS.md says plainly: "A player who pays 'to' them sends
/// money nowhere." An operator who does not notice one ships a payment method
/// that silently eats deposits, so the console says it loudly, in three places:
/// a list-wide banner, a per-method banner, and a badge on the row itself.
class PlaceholderAuditBanner extends StatelessWidget {
  const PlaceholderAuditBanner({required this.audit, super.key});

  final PlaceholderAudit audit;

  @override
  Widget build(BuildContext context) {
    if (audit.isClean) {
      return const SizedBox.shrink();
    }
    final AppStrings s = context.s;
    return InfoBanner(
      title: s.pmAuditBannerTitle,
      tone: StatusTone.failed,
      icon: Icons.report_gmailerrorred_outlined,
      // Arabic pluralises BOTH counts inside the catalogue; no ternary here.
      message: s.pmAuditBannerMessage(
        rows: audit.placeholderCount,
        methods: audit.affectedMethodCount,
      ),
    );
  }
}

/// Per-method banner listing exactly which destinations look unfinished.
class PlaceholderDestinationBanner extends StatelessWidget {
  const PlaceholderDestinationBanner({required this.destinations, super.key});

  /// The method's destinations, active and inactive.
  final List<AdminPaymentDestinationView> destinations;

  @override
  Widget build(BuildContext context) {
    final List<AdminPaymentDestinationView> live = destinations
        .where((AdminPaymentDestinationView row) => row.isLivePlaceholder)
        .toList(growable: false);
    final List<AdminPaymentDestinationView> dormant = destinations
        .where(
          (AdminPaymentDestinationView row) =>
              row.looksLikePlaceholder && !row.isActive,
        )
        .toList(growable: false);

    if (live.isEmpty && dormant.isEmpty) {
      return const SizedBox.shrink();
    }
    final AppStrings s = context.s;
    if (live.isEmpty) {
      return InfoBanner(
        title: s.pmDormantPlaceholderTitle,
        tone: StatusTone.pending,
        icon: Icons.history_toggle_off,
        message: s.pmDormantPlaceholderMessage(count: dormant.length),
      );
    }
    return InfoBanner(
      title: s.pmLivePlaceholderTitle,
      tone: StatusTone.failed,
      icon: Icons.report_gmailerrorred_outlined,
      message: s.pmLivePlaceholderMessage,
      // Two raw values (label, account identifier) joined by a dash: both are
      // operator data, neither is prose, so nothing here is translated.
      bullets: live
          .map(
            (AdminPaymentDestinationView row) =>
                '${row.label} - ${row.accountIdentifier}',
          )
          .toList(growable: false),
    );
  }
}

/// Small badge for a destination row that looks like a placeholder.
class PlaceholderBadge extends StatelessWidget {
  const PlaceholderBadge({required this.destination, super.key});

  final AdminPaymentDestinationView destination;

  @override
  Widget build(BuildContext context) {
    if (!destination.looksLikePlaceholder) {
      return const SizedBox.shrink();
    }
    return StatusChip(
      label: destination.isActive
          ? context.s.pdPlaceholderBadgeLive
          : context.s.pdPlaceholderBadge,
      tone: destination.isActive ? StatusTone.failed : StatusTone.pending,
      icon: Icons.warning_amber_rounded,
      dense: true,
    );
  }
}
