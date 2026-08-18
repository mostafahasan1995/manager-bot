import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/auth/auth_controller.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/money/money.dart';
import 'package:manager_bot/core/theme/app_theme.dart';
import 'package:manager_bot/core/widgets/widgets.dart';
import 'package:manager_bot/features/payment_methods/application/payment_method_actions.dart';
import 'package:manager_bot/features/payment_methods/application/payment_method_providers.dart';
import 'package:manager_bot/features/payment_methods/data/admin_payment_destination_view.dart';
import 'package:manager_bot/features/payment_methods/data/admin_payment_method_view.dart';
import 'package:manager_bot/features/payment_methods/data/payment_enums.dart';
import 'package:manager_bot/features/payment_methods/data/payment_method_rules.dart';
import 'package:manager_bot/features/payment_methods/presentation/payment_destination_form_screen.dart';
import 'package:manager_bot/features/payment_methods/presentation/payment_method_form_screen.dart';
import 'package:manager_bot/features/payment_methods/presentation/widgets/mutation_feedback.dart';
import 'package:manager_bot/features/payment_methods/presentation/widgets/payment_destination_card.dart';
import 'package:manager_bot/features/payment_methods/presentation/widgets/permission_denied_view.dart';
import 'package:manager_bot/features/payment_methods/presentation/widgets/placeholder_warning.dart';
import 'package:manager_bot/features/payment_methods/presentation/widgets/section_card.dart';

/// One payment method, its configuration, and its destinations.
///
/// Reached with a plain `Navigator.push` rather than a named route: the router
/// only owns `/payment-methods`, and this screen is a drill-down inside the
/// shell branch rather than a linkable destination.
class PaymentMethodDetailScreen extends ConsumerWidget {
  const PaymentMethodDetailScreen({required this.methodId, super.key});

  /// UUID of the method.
  final String methodId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = context.s;
    final bool canView = ref.watch(canViewPaymentMethodsProvider);
    if (!canView) {
      return Scaffold(
        appBar: AppBar(title: Text(s.pmDetailTitle)),
        body: PermissionDeniedView(
          role: ref.watch(currentRoleProvider),
          allowedRoles: PaymentMethodRoles.readers,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(s.pmDetailTitle),
        actions: <Widget>[
          IconButton(
            tooltip: s.refresh,
            onPressed: () => ref.invalidate(paymentMethodProvider(methodId)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: AsyncValueView<AdminPaymentMethodView>(
        value: ref.watch(paymentMethodProvider(methodId)),
        onRetry: () => ref.invalidate(paymentMethodProvider(methodId)),
        loadingLabel: s.pmLoadingMethod,
        builder: (BuildContext context, AdminPaymentMethodView method) =>
            _MethodBody(method: method),
      ),
    );
  }
}

class _MethodBody extends ConsumerWidget {
  const _MethodBody({required this.method});

  final AdminPaymentMethodView method;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = context.s;
    final ThemeData theme = Theme.of(context);
    final String localeTag = context.localeTag;
    final bool canManage = ref.watch(canManagePaymentMethodsProvider);
    final bool isBusy = ref
        .watch(paymentMethodActionsProvider)
        .isBusy(method.id);

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: <Widget>[
        _HeaderCard(method: method, canManage: canManage, isBusy: isBusy),
        if (method.railHasNoDriver)
          InfoBanner(
            title: s.pmNoDriverTitle(rail: method.rail.label(s)),
            tone: StatusTone.failed,
            icon: Icons.block,
            message: s.pmNoDriverMessage,
          ),
        _LimitsCard(method: method),
        _VerificationCard(method: method),
        _InstructionsCard(method: method),
        _DestinationsSection(method: method),
        SectionCard(
          title: s.pmRecordSection,
          children: <Widget>[
            DetailRow.text(
              label: s.pmIdentifierLabel,
              value: method.id,
              monospace: true,
              hint: s.pmIdentifierHint,
            ),
            DetailRow.text(
              label: s.createdLabel,
              // Dates are the ONLY thing on this screen that sees the locale,
              // and AppDateFormats maps Arabic-Indic digits back to ASCII.
              value: AppDateFormats.mediumDayTime(method.createdAt, localeTag),
            ),
            DetailRow.text(
              label: s.pmLastUpdatedLabel,
              value: AppDateFormats.mediumDayTime(method.updatedAt, localeTag),
              hint: s.pmLastUpdatedHint,
            ),
            const SizedBox(height: 6),
            // Both timestamps above are LOCAL time while the bot prints UTC.
            Text(
              s.timesAreLocalNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeaderCard extends ConsumerWidget {
  const _HeaderCard({
    required this.method,
    required this.canManage,
    required this.isBusy,
  });

  final AdminPaymentMethodView method;
  final bool canManage;
  final bool isBusy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = context.s;
    final ThemeData theme = Theme.of(context);
    return SectionCard(
      title: method.displayName,
      subtitle: s.pmHeaderSubtitle(
        rail: method.rail.label(s),
        currency: method.currencyCode,
      ),
      trailing: StatusChip(label: method.statusLabel(s), tone: method.tone),
      children: <Widget>[
        DetailRow.text(
          label: s.pmMachineCodeLabel,
          value: method.code,
          monospace: true,
          hint: s.pmMachineCodeHint,
        ),
        DetailRow.text(
          label: s.pmRailLabel,
          value: method.rail.label(s),
          hint: s.pmImmutableAfterCreationHint,
        ),
        DetailRow.text(
          label: s.currencyLabel,
          value: method.currencyCode,
          hint: s.pmImmutableAfterCreationHint,
        ),
        // An int renders as ASCII in both locales - never route it through
        // NumberFormat.
        DetailRow.text(label: s.pmSortOrderLabel, value: '${method.sortOrder}'),
        if (canManage) ...<Widget>[
          const SizedBox(height: 8),
          Row(
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
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isBusy
                      ? null
                      : () async {
                          await Navigator.of(context).push<bool>(
                            MaterialPageRoute<bool>(
                              builder: (BuildContext context) =>
                                  PaymentMethodFormScreen(method: method),
                            ),
                          );
                        },
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(s.editButton),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: method.isActive
                        ? AppSemanticColors.of(context).reject.foreground
                        : AppSemanticColors.of(context).approve.foreground,
                    foregroundColor: theme.colorScheme.surface,
                  ),
                  onPressed: isBusy
                      ? null
                      : () async {
                          await _toggleActive(context, ref);
                        },
                  icon: Icon(
                    method.isActive
                        ? Icons.pause_circle_outline
                        : Icons.play_circle_outline,
                    size: 18,
                  ),
                  label: Text(
                    method.isActive ? s.disableButton : s.enableButton,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _toggleActive(BuildContext context, WidgetRef ref) async {
    final AppStrings s = context.s;
    final bool next = !method.isActive;
    final ConfirmActionResult? confirmation = await ConfirmActionSheet.show(
      context,
      title: next
          ? s.pmEnableMethodTitle(name: method.displayName)
          : s.pmDisableMethodTitle(name: method.displayName),
      message: next ? s.pmEnableMethodMessage : s.pmDisableMethodMessage,
      confirmLabel: next ? s.enableButton : s.disableButton,
      cancelLabel: s.cancel,
      tone: next ? StatusTone.approve : StatusTone.reject,
    );
    if (!(confirmation?.confirmed ?? false)) {
      return;
    }
    final MutationResult<AdminPaymentMethodView> result = await ref
        .read(paymentMethodActionsProvider.notifier)
        .setMethodActive(method.id, isActive: next);
    if (!context.mounted) {
      return;
    }
    showMutationResult<AdminPaymentMethodView>(context, result);
  }
}

class _LimitsCard extends StatelessWidget {
  const _LimitsCard({required this.method});

  final AdminPaymentMethodView method;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final Money feeAtMinimum = method.feeFor(method.minAmount);
    final Money feeAtMaximum = method.feeFor(method.maxAmount);
    final Money creditedAtMinimum = method.creditedAtMinimum;

    return SectionCard(
      title: s.pmLimitsSection,
      subtitle: s.pmLimitsSubtitle,
      children: <Widget>[
        DetailRow(
          label: s.pmMinimumLabel,
          value: MoneyText(method.minAmount),
          hint: s.pmMinimumHint,
        ),
        DetailRow(
          label: s.pmMaximumLabel,
          value: MoneyText(method.maxAmount),
          hint: s.pmMaximumHint,
        ),
        DetailRow(
          label: s.pmFixedFeeLabel,
          value: MoneyText(method.feeFixed),
          hint: s.pmFixedFeeHint,
        ),
        DetailRow.text(
          label: s.pmVariableFeeLabel,
          // The percentage is computed in integer arithmetic - no double ever
          // touches a fee.
          value: s.pmVariableFeeValue(
            bps: method.feeBps,
            percent: _percent(method.feeBps),
          ),
          hint: s.pmVariableFeeHint,
        ),
        const Divider(height: 24),
        DetailRow(
          label: s.pmFeeAtMinimumLabel,
          value: MoneyText(feeAtMinimum),
        ),
        DetailRow(
          label: s.pmCreditedAtMinimumLabel,
          value: MoneyText(
            creditedAtMinimum,
            colorBySign: true,
          ),
          hint: creditedAtMinimum.isPositive
              ? s.pmCreditedAtMinimumHintOk
              : s.pmCreditedAtMinimumHintBad,
        ),
        DetailRow(
          label: s.pmFeeAtMaximumLabel,
          value: MoneyText(feeAtMaximum),
        ),
      ],
    );
  }

  static String _percent(int feeBps) {
    final String whole = (feeBps ~/ 100).toString();
    final String fraction = (feeBps % 100).toString().padLeft(2, '0');
    return '$whole.$fraction%';
  }
}

class _VerificationCard extends StatelessWidget {
  const _VerificationCard({required this.method});

  final AdminPaymentMethodView method;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final ThemeData theme = Theme.of(context);
    final String? patternError = method.referencePatternCompileError;
    final List<String> unenforceable = method.unenforceableProofFields;

    return Column(
      children: <Widget>[
        SectionCard(
          title: s.pmVerificationSection,
          children: <Widget>[
            DetailRow.text(
              label: s.pmVerificationModeRowLabel,
              value: method.verificationMode.label(s),
              hint: s.pmVerificationModeHint,
            ),
            DetailRow.text(
              label: s.referenceLabel,
              value: method.referenceIsMandatory
                  ? s.pmReferenceRequiredValue
                  : s.pmReferenceOptionalValue,
              hint: method.requiresReferenceToggleIsMoot
                  ? s.pmReferenceMootHint(
                      rail: method.rail.label(s),
                      state: method.requiresReference
                          ? s.pmStatusActive
                          : s.pmStatusDisabled,
                    )
                  : s.pmReferenceSwitchHint,
            ),
            DetailRow.text(
              label: s.pmReferencePatternRowLabel,
              value: method.hasReferencePattern
                  ? method.referencePattern!
                  : s.noneLabel,
              monospace: method.hasReferencePattern,
              hint: method.hasReferencePattern
                  ? s.pmReferencePatternHint
                  : s.pmReferencePatternNoneHint,
            ),
            const SizedBox(height: 6),
            Text(
              s.pmProofFieldsIntro,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            if (method.requiredProofFields.isEmpty)
              Text(
                s.pmProofFieldsNone,
                style: theme.textTheme.bodyMedium,
              )
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: <Widget>[
                  for (final String field in method.requiredProofFields)
                    StatusChip(
                      label: RailProofField.labelFor(field, s),
                      tone: RailProofField.isMachineEnforced(field)
                          ? StatusTone.info
                          : StatusTone.pending,
                      icon: RailProofField.isMachineEnforced(field)
                          ? Icons.verified_outlined
                          : Icons.visibility_outlined,
                      dense: true,
                    ),
                ],
              ),
          ],
        ),
        if (patternError != null)
          InfoBanner(
            title: s.pmPatternBrokenTitle,
            tone: StatusTone.failed,
            icon: Icons.code_off,
            // The regex engine's own message is untranslatable machine output.
            message: s.pmPatternBrokenMessage(error: patternError),
          ),
        if (unenforceable.isNotEmpty)
          InfoBanner(
            title: s.pmHumanCheckedTitle,
            tone: StatusTone.pending,
            icon: Icons.visibility_outlined,
            message: s.pmHumanCheckedMessage,
            bullets: unenforceable
                .map((String field) => RailProofField.labelFor(field, s))
                .toList(growable: false),
          ),
      ],
    );
  }
}

class _InstructionsCard extends StatelessWidget {
  const _InstructionsCard({required this.method});

  final AdminPaymentMethodView method;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final ThemeData theme = Theme.of(context);
    final String? instructions = method.instructions;
    return SectionCard(
      title: s.pmInstructionsSection,
      subtitle: s.pmInstructionsSubtitle,
      children: <Widget>[
        if (instructions == null || instructions.trim().isEmpty)
          Text(
            s.pmInstructionsEmpty,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          SelectableText(instructions, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

/// The destinations sub-resource.
///
/// Its own async state, because it is a separate endpoint from the method and
/// must be able to fail, retry and reload without taking the method with it.
class _DestinationsSection extends ConsumerStatefulWidget {
  const _DestinationsSection({required this.method});

  final AdminPaymentMethodView method;

  @override
  ConsumerState<_DestinationsSection> createState() =>
      _DestinationsSectionState();
}

class _DestinationsSectionState extends ConsumerState<_DestinationsSection> {
  bool _includeInactive = true;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final ThemeData theme = Theme.of(context);
    final bool canManage = ref.watch(canManagePaymentMethodsProvider);
    final DestinationQuery query = DestinationQuery(
      methodId: widget.method.id,
      includeInactive: _includeInactive,
    );
    final AsyncValue<List<AdminPaymentDestinationView>> destinations =
        ref.watch(paymentDestinationsProvider(query));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          // Directional so the heading keeps its wider margin on the reading
          // edge and the button its tighter one under RTL.
          padding: const EdgeInsetsDirectional.fromSTEB(16, 18, 12, 0),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  s.pmDestinationsHeading,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              TextButton.icon(
                onPressed: () =>
                    setState(() => _includeInactive = !_includeInactive),
                icon: Icon(
                  _includeInactive
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                ),
                label: Text(
                  _includeInactive ? s.pmHideDisabled : s.pmShowAll,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
          child: Text(
            s.pmDestinationsOrderNote,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        destinations.when(
          loading: () => Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: LoadingStateView(label: s.pmLoadingDestinations),
          ),
          error: (Object error, StackTrace stackTrace) => ErrorStateView(
            error: error,
            compact: true,
            onRetry: () => ref.invalidate(paymentDestinationsProvider(query)),
          ),
          data: (List<AdminPaymentDestinationView> rows) =>
              _buildRows(context, rows, canManage: canManage),
        ),
        if (canManage)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
            child: OutlinedButton.icon(
              onPressed: () async {
                await Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (BuildContext context) =>
                        PaymentDestinationFormScreen(method: widget.method),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: Text(s.pmAddDestination),
            ),
          ),
      ],
    );
  }

  Widget _buildRows(
    BuildContext context,
    List<AdminPaymentDestinationView> rows, {
    required bool canManage,
  }) {
    final AppStrings s = context.s;
    final int activeCount = rows
        .where((AdminPaymentDestinationView row) => row.isActive)
        .length;
    final PaymentMethodActionState actions =
        ref.watch(paymentMethodActionsProvider);

    if (rows.isEmpty) {
      return Column(
        children: <Widget>[
          InfoBanner(
            title: s.pmNoDestinationsTitle,
            tone: StatusTone.failed,
            icon: Icons.wrong_location_outlined,
            message: s.pmNoDestinationsMessage,
          ),
          if (!_includeInactive)
            InfoBanner(
              title: s.pmDisabledHiddenTitle,
              tone: StatusTone.neutral,
              icon: Icons.visibility_off_outlined,
              message: s.pmDisabledHiddenMessage,
            ),
        ],
      );
    }

    return Column(
      children: <Widget>[
        PlaceholderDestinationBanner(destinations: rows),
        if (activeCount == 0)
          InfoBanner(
            title: s.pmNoActiveDestinationTitle,
            tone: StatusTone.failed,
            icon: Icons.wrong_location_outlined,
            message: s.pmNoActiveDestinationMessage,
          ),
        for (final AdminPaymentDestinationView row in rows)
          PaymentDestinationCard(
            destination: row,
            rail: widget.method.rail,
            currencyCode: widget.method.currencyCode,
            canManage: canManage,
            isBusy: actions.isBusy(row.id),
            onEdit: () async {
              await Navigator.of(context).push<bool>(
                MaterialPageRoute<bool>(
                  builder: (BuildContext context) =>
                      PaymentDestinationFormScreen(
                    method: widget.method,
                    destination: row,
                  ),
                ),
              );
            },
            onToggleActive: () async {
              await _toggleDestination(
                row,
                isLastActive: row.isActive && activeCount == 1,
              );
            },
          ),
      ],
    );
  }

  Future<void> _toggleDestination(
    AdminPaymentDestinationView destination, {
    required bool isLastActive,
  }) async {
    final AppStrings s = context.s;
    final bool next = !destination.isActive;
    final String message = next
        ? s.pdEnableMessage
        : isLastActive
            ? s.pdDisableLastMessage
            : s.pdDisableMessage;
    final ConfirmActionResult? confirmation = await ConfirmActionSheet.show(
      context,
      title: next
          ? s.pdEnableTitle(label: destination.label)
          : s.pdDisableTitle(label: destination.label),
      message: message,
      confirmLabel: next ? s.enableButton : s.disableButton,
      cancelLabel: s.cancel,
      tone: next ? StatusTone.approve : StatusTone.reject,
    );
    if (!(confirmation?.confirmed ?? false)) {
      return;
    }
    final MutationResult<AdminPaymentDestinationView> result = await ref
        .read(paymentMethodActionsProvider.notifier)
        .setDestinationActive(
          destinationId: destination.id,
          methodId: widget.method.id,
          isActive: next,
        );
    if (!mounted) {
      return;
    }
    showMutationResult<AdminPaymentDestinationView>(context, result);
  }
}
