import 'package:flutter/material.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/money/money.dart';
import 'package:manager_bot/core/theme/app_theme.dart';
import 'package:manager_bot/core/widgets/widgets.dart';
import 'package:manager_bot/features/payment_methods/data/admin_payment_destination_view.dart';
import 'package:manager_bot/features/payment_methods/data/payment_enums.dart';
import 'package:manager_bot/features/payment_methods/presentation/widgets/placeholder_warning.dart';

/// One destination: the account a player is actually told to pay into.
///
/// The captions are rail-dependent on purpose. On CRYPTO the `label` is printed
/// to the player as `Network: {label}` - it is the CHAIN, and a wrong chain
/// makes funds unrecoverable - while `accountHolder` is ignored entirely.
class PaymentDestinationCard extends StatelessWidget {
  const PaymentDestinationCard({
    required this.destination,
    required this.rail,
    required this.currencyCode,
    required this.canManage,
    required this.isBusy,
    required this.onEdit,
    required this.onToggleActive,
    super.key,
  });

  final AdminPaymentDestinationView destination;

  /// Rail of the OWNING method; drives the captions.
  final PaymentRail rail;

  /// Currency of the owning method - the destination payload does not carry
  /// one, so the daily cap is restated in it.
  final String currencyCode;

  final bool canManage;
  final bool isBusy;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final ThemeData theme = Theme.of(context);
    final Money? cap = destination.dailyCapIn(currencyCode);
    final String? holder = destination.accountHolder;
    final String? notes = destination.notes;

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Text(
                    '${rail.destinationLabelCaption(s)}: ${destination.label}',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                StatusChip(
                  // A DESTINATION is مفعّل/معطّل - a different pair from the
                  // method's مفعّلة/معطّلة. Never merge the two.
                  label: destination.isActive
                      ? s.pdStatusActive
                      : s.pdStatusDisabled,
                  tone: destination.isActive
                      ? StatusTone.approve
                      : StatusTone.neutral,
                  dense: true,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              rail.accountIdentifierCaption(s),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            SelectableText(
              destination.accountIdentifier,
              style: AppTheme.monoStyle(context),
            ),
            if (destination.looksLikePlaceholder) ...<Widget>[
              const SizedBox(height: 8),
              PlaceholderBadge(destination: destination),
              const SizedBox(height: 4),
              for (final String reason in destination.placeholderReasons(s))
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(reason, style: theme.textTheme.bodySmall),
                ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                StatusChip(
                  label: s.pdPriorityChip(priority: destination.priority),
                  tone: StatusTone.info,
                  icon: Icons.low_priority,
                  dense: true,
                ),
                if (cap != null)
                  StatusChip(
                    // Money arrives already formatted; the catalogue only lays
                    // it out.
                    label: s.pdSoftCapChip(amount: cap.format()),
                    tone: StatusTone.neutral,
                    icon: Icons.speed_outlined,
                    dense: true,
                  ),
                if (holder != null && holder.trim().isNotEmpty)
                  StatusChip(
                    label: rail.ignoresAccountHolder
                        ? s.pdHolderIgnoredChip
                        : s.pdHolderChip(holder: holder),
                    tone: rail.ignoresAccountHolder
                        ? StatusTone.neutral
                        : StatusTone.info,
                    icon: Icons.person_outline,
                    dense: true,
                  ),
              ],
            ),
            if (notes != null && notes.trim().isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                s.pdNotesAppendedNote,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(notes, style: theme.textTheme.bodyMedium),
            ],
            if (canManage) ...<Widget>[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  if (isBusy)
                    const Padding(
                      padding: EdgeInsetsDirectional.only(end: 12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  TextButton.icon(
                    onPressed: isBusy ? null : onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(s.editButton),
                  ),
                  const SizedBox(width: 4),
                  TextButton.icon(
                    onPressed: isBusy ? null : onToggleActive,
                    icon: Icon(
                      destination.isActive
                          ? Icons.pause_circle_outline
                          : Icons.play_circle_outline,
                      size: 18,
                    ),
                    label: Text(
                      destination.isActive ? s.disableButton : s.enableButton,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
