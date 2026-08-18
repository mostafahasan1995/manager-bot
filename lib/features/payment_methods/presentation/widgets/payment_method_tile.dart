import 'package:flutter/material.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/theme/app_theme.dart';
import 'package:manager_bot/core/widgets/widgets.dart';
import 'package:manager_bot/features/payment_methods/data/admin_payment_method_view.dart';

/// One row of the payment-method list.
///
/// Deliberately shows the limits as money rather than hiding them behind a tap:
/// min/max are what actually gate a player's deposit, and an operator scanning
/// the list is usually checking exactly those.
class PaymentMethodTile extends StatelessWidget {
  const PaymentMethodTile({
    required this.method,
    required this.onTap,
    this.hasPlaceholderDestination = false,
    super.key,
  });

  final AdminPaymentMethodView method;
  final VoidCallback onTap;

  /// From the placeholder audit: this method can currently hand a player an
  /// account that goes nowhere.
  final bool hasPlaceholderDestination;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final ThemeData theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        // Directional: the tighter inset belongs on the trailing edge (the
        // chevron side), which is the LEFT one under Arabic.
        padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        method.displayName,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        method.code,
                        style: AppTheme.monoStyle(context),
                      ),
                    ],
                  ),
                ),
                StatusChip(
                  label: method.statusLabel(s),
                  tone: method.tone,
                  dense: true,
                ),
                const SizedBox(width: 6),
                // Material ships no direction-aware chevron, so it is picked by
                // hand: it must always point AWAY from the text edge.
                Icon(
                  context.isRtl ? Icons.chevron_left : Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[
                StatusChip(
                  label: method.rail.label(s),
                  tone: StatusTone.info,
                  icon: Icons.account_balance_outlined,
                  dense: true,
                ),
                if (method.railHasNoDriver)
                  StatusChip(
                    label: s.pmNoDriverChip,
                    tone: StatusTone.failed,
                    icon: Icons.block,
                    dense: true,
                  ),
                if (hasPlaceholderDestination)
                  StatusChip(
                    label: s.pmPlaceholderChip,
                    tone: StatusTone.failed,
                    icon: Icons.warning_amber_rounded,
                    dense: true,
                  ),
                if (method.referenceIsMandatory)
                  StatusChip(
                    label: s.referenceRequiredLabel,
                    tone: StatusTone.neutral,
                    icon: Icons.tag,
                    dense: true,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Text(
                  s.pmLimitsChipLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                // Money keeps Western digits in both locales; the Row order
                // follows Directionality on its own.
                MoneyText(method.minAmount, showCurrency: false),
                Text(
                  '-',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                MoneyText(method.maxAmount),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
