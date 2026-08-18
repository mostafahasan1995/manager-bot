import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/auth/auth_controller.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/widgets/widgets.dart';
import 'package:manager_bot/features/payment_methods/application/payment_method_providers.dart';
import 'package:manager_bot/features/payment_methods/data/admin_payment_method_view.dart';
import 'package:manager_bot/features/payment_methods/data/payment_enums.dart';
import 'package:manager_bot/features/payment_methods/data/payment_method_rules.dart';
import 'package:manager_bot/features/payment_methods/presentation/payment_method_detail_screen.dart';
import 'package:manager_bot/features/payment_methods/presentation/payment_method_form_screen.dart';
import 'package:manager_bot/features/payment_methods/presentation/widgets/payment_method_tile.dart';
import 'package:manager_bot/features/payment_methods/presentation/widgets/permission_denied_view.dart';
import 'package:manager_bot/features/payment_methods/presentation/widgets/placeholder_warning.dart';

/// `/payment-methods` - the payment configuration surface.
///
/// Handles all four states the house rules demand: loading, empty (including
/// "empty because of your filter"), error with retry, and permission denied for
/// a VIEWER, who the backend refuses on every route here even though the router
/// will happily bring them.
class PaymentMethodsScreen extends ConsumerWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = context.s;
    final bool canView = ref.watch(canViewPaymentMethodsProvider);
    final bool canManage = ref.watch(canManagePaymentMethodsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.pmScreenTitle),
        actions: <Widget>[
          if (canView)
            IconButton(
              tooltip: s.refresh,
              onPressed: () {
                ref
                  ..invalidate(paymentMethodListProvider)
                  ..invalidate(placeholderAuditProvider);
              },
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      floatingActionButton: canView && canManage
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (BuildContext context) =>
                        const PaymentMethodFormScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: Text(s.pmNewMethodButton),
            )
          : null,
      body: canView
          ? _PaymentMethodsBody(canManage: canManage)
          : PermissionDeniedView(
              role: ref.watch(currentRoleProvider),
              allowedRoles: PaymentMethodRoles.readers,
              message: s.pmReadersDeniedMessage,
            ),
    );
  }
}

class _PaymentMethodsBody extends ConsumerWidget {
  const _PaymentMethodsBody({required this.canManage});

  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = context.s;
    final PaymentMethodFilter filter = ref.watch(paymentMethodFilterProvider);
    final AsyncValue<PlaceholderAudit> audit =
        ref.watch(placeholderAuditProvider);
    final PlaceholderAudit? auditValue = audit.valueOrNull;

    return Column(
      children: <Widget>[
        _FilterBar(filter: filter),
        if (auditValue != null && !auditValue.isClean)
          PlaceholderAuditBanner(audit: auditValue),
        Expanded(
          child: AsyncValueView<List<AdminPaymentMethodView>>(
            value: ref.watch(paymentMethodListProvider),
            onRetry: () => ref.invalidate(paymentMethodListProvider),
            isEmpty: (List<AdminPaymentMethodView> methods) => methods.isEmpty,
            emptyTitle:
                filter.isUnfiltered ? s.pmEmptyTitle : s.pmFilterEmptyTitle,
            emptyMessage: filter.isUnfiltered
                ? canManage
                    ? s.pmEmptyMessageManager
                    : s.pmEmptyMessageReader
                : s.pmFilterEmptyMessage,
            emptyIcon: Icons.account_balance_wallet_outlined,
            loadingLabel: s.pmLoadingList,
            builder: (BuildContext context, List<AdminPaymentMethodView> methods) {
              return RefreshIndicator(
                onRefresh: () async {
                  ref
                    ..invalidate(paymentMethodListProvider)
                    ..invalidate(placeholderAuditProvider);
                  await ref.read(paymentMethodListProvider.future);
                },
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: methods.length,
                  separatorBuilder: (BuildContext context, int index) =>
                      const Divider(height: 1),
                  itemBuilder: (BuildContext context, int index) {
                    final AdminPaymentMethodView method = methods[index];
                    return PaymentMethodTile(
                      method: method,
                      hasPlaceholderDestination:
                          auditValue?.hasPlaceholders(method.id) ?? false,
                      onTap: () async {
                        await Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (BuildContext context) =>
                                PaymentMethodDetailScreen(methodId: method.id),
                          ),
                        );
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Active/disabled and rail filters.
///
/// Both map straight onto query params, and both are validated strictly by the
/// backend: `isActive` accepts ONLY `"true"`/`"false"` and `rail` must be an
/// exact enum spelling, so neither is ever built from free text.
class _FilterBar extends ConsumerWidget {
  const _FilterBar({required this.filter});

  final PaymentMethodFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = context.s;
    final PaymentMethodFilterController controller =
        ref.read(paymentMethodFilterProvider.notifier);
    return Padding(
      // Symmetric horizontally, so it needs no direction of its own.
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          ChoiceChip(
            label: Text(s.filterAll),
            selected: filter.isActive == null,
            onSelected: (bool _) => controller.setActive(null),
          ),
          ChoiceChip(
            label: Text(s.pmStatusActive),
            selected: filter.isActive ?? false,
            onSelected: (bool _) => controller.setActive(true),
          ),
          ChoiceChip(
            label: Text(s.pmStatusDisabled),
            selected: filter.isActive == false,
            onSelected: (bool _) => controller.setActive(false),
          ),
          PopupMenuButton<String>(
            tooltip: s.pmFilterRailTooltip,
            onSelected: (String value) => controller.setRail(
              value.isEmpty ? null : PaymentRail.tryParse(value),
            ),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: '',
                child: Text(s.pmFilterEveryRail),
              ),
              for (final PaymentRail rail in PaymentRail.values)
                PopupMenuItem<String>(
                  value: rail.wireName,
                  child: Text(rail.label(s)),
                ),
            ],
            child: Chip(
              avatar: const Icon(Icons.filter_alt_outlined, size: 18),
              label: Text(filter.rail?.label(s) ?? s.pmFilterEveryRail),
            ),
          ),
        ],
      ),
    );
  }
}
