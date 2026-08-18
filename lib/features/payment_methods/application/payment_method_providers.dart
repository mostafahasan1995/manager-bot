/// Read state of the payment-method surface: the list, one method, one method's
/// destinations, the placeholder audit, and the two permission gates.
///
/// Mutations live in `payment_method_actions.dart`, which invalidates the
/// providers here after a successful write.
library;

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/auth/auth_controller.dart';
import 'package:manager_bot/core/auth/roles.dart';
import 'package:manager_bot/core/errors/api_error.dart';
import 'package:manager_bot/core/logging/app_logger.dart';
import 'package:manager_bot/features/payment_methods/data/admin_payment_destination_view.dart';
import 'package:manager_bot/features/payment_methods/data/admin_payment_method_view.dart';
import 'package:manager_bot/features/payment_methods/data/payment_enums.dart';
import 'package:manager_bot/features/payment_methods/data/payment_method_repository.dart';
import 'package:manager_bot/features/payment_methods/data/payment_method_rules.dart';

/// Filter of the method list. Both halves map straight onto query params.
@immutable
class PaymentMethodFilter {
  const PaymentMethodFilter({this.isActive, this.rail});

  /// Null means "no filter" - the admin list returns active AND inactive rows.
  final bool? isActive;

  /// Null means "every rail".
  final PaymentRail? rail;

  bool get isUnfiltered => isActive == null && rail == null;

  /// Explicit setters rather than a `copyWith`, because null here means
  /// "clear the filter" and a copyWith could never express that.
  PaymentMethodFilter withActive(bool? value) =>
      PaymentMethodFilter(isActive: value, rail: rail);

  PaymentMethodFilter withRail(PaymentRail? value) =>
      PaymentMethodFilter(isActive: isActive, rail: value);

  @override
  bool operator ==(Object other) =>
      other is PaymentMethodFilter &&
      other.isActive == isActive &&
      other.rail == rail;

  @override
  int get hashCode => Object.hash(isActive, rail);

  @override
  String toString() =>
      'PaymentMethodFilter(isActive: $isActive, rail: ${rail?.wireName})';
}

/// Holds the list filter. Kept out of the screen's `State` so a rebuild or a
/// navigation away does not silently reset it.
class PaymentMethodFilterController extends Notifier<PaymentMethodFilter> {
  @override
  PaymentMethodFilter build() => const PaymentMethodFilter();

  void setActive(bool? isActive) {
    state = state.withActive(isActive);
  }

  void setRail(PaymentRail? rail) {
    state = state.withRail(rail);
  }

  void clear() {
    state = const PaymentMethodFilter();
  }
}

final NotifierProvider<PaymentMethodFilterController, PaymentMethodFilter>
    paymentMethodFilterProvider =
    NotifierProvider<PaymentMethodFilterController, PaymentMethodFilter>(
  PaymentMethodFilterController.new,
);

/// The method list, already filtered server-side.
///
/// No pagination exists on this endpoint: the whole matching set arrives in one
/// array, ordered by `sortOrder` then `displayName`.
final FutureProvider<List<AdminPaymentMethodView>> paymentMethodListProvider =
    FutureProvider<List<AdminPaymentMethodView>>((ref) {
  final PaymentMethodFilter filter = ref.watch(paymentMethodFilterProvider);
  return ref.watch(paymentMethodRepositoryProvider).listMethods(
        isActive: filter.isActive,
        rail: filter.rail,
      );
});

/// One method by UUID. Used by the detail screen so it stays correct after an
/// edit even when the list is filtered to exclude it.
final AutoDisposeFutureProviderFamily<AdminPaymentMethodView, String>
    paymentMethodProvider =
    FutureProvider.autoDispose.family<AdminPaymentMethodView, String>(
  (ref, String methodId) =>
      ref.watch(paymentMethodRepositoryProvider).getMethod(methodId),
);

/// Family key for [paymentDestinationsProvider].
///
/// `includeInactive` is part of the key because the two lists are genuinely
/// different server-side responses, not a client-side filter.
@immutable
class DestinationQuery {
  const DestinationQuery({
    required this.methodId,
    required this.includeInactive,
  });

  final String methodId;
  final bool includeInactive;

  @override
  bool operator ==(Object other) =>
      other is DestinationQuery &&
      other.methodId == methodId &&
      other.includeInactive == includeInactive;

  @override
  int get hashCode => Object.hash(methodId, includeInactive);

  @override
  String toString() =>
      'DestinationQuery($methodId, includeInactive: $includeInactive)';
}

/// Destinations of one method, ordered `priority` ASC then `id` ASC - the exact
/// order the rotation cursor indexes into.
final AutoDisposeFutureProviderFamily<List<AdminPaymentDestinationView>,
        DestinationQuery> paymentDestinationsProvider =
    FutureProvider.autoDispose
        .family<List<AdminPaymentDestinationView>, DestinationQuery>(
  (ref, DestinationQuery query) =>
      ref.watch(paymentMethodRepositoryProvider).listDestinations(
            query.methodId,
            includeInactive: query.includeInactive,
          ),
);

/// Which methods can still hand a player a PLACEHOLDER account.
///
/// The backend's STATUS.md is blunt about this: "A player who pays 'to' them
/// sends money nowhere." The list endpoint does not carry destinations, so this
/// walks the active methods and asks for each one's ACTIVE destinations. It is
/// deliberately best-effort - a method whose destinations cannot be read is
/// skipped rather than failing the whole audit and hiding the warning for the
/// methods that were readable.
@immutable
class PlaceholderAudit {
  const PlaceholderAudit({
    required this.byMethodId,
    required this.auditedMethodIds,
    required this.skippedMethodIds,
  });

  static const PlaceholderAudit empty = PlaceholderAudit(
    byMethodId: <String, List<AdminPaymentDestinationView>>{},
    auditedMethodIds: <String>{},
    skippedMethodIds: <String>{},
  );

  /// Never walks more than this many methods, so a large configuration cannot
  /// turn one screen open into a request storm.
  static const int maxAuditedMethods = 16;

  /// Method id -> its ACTIVE destinations that look like placeholders.
  final Map<String, List<AdminPaymentDestinationView>> byMethodId;

  /// Methods that were actually checked.
  final Set<String> auditedMethodIds;

  /// Methods whose destinations could not be read (403/404/network).
  final Set<String> skippedMethodIds;

  bool get isClean => byMethodId.isEmpty;

  int get affectedMethodCount => byMethodId.length;

  int get placeholderCount => byMethodId.values
      .fold<int>(0, (int total, List<AdminPaymentDestinationView> rows) => total + rows.length);

  bool hasPlaceholders(String methodId) => byMethodId.containsKey(methodId);
}

final FutureProvider<PlaceholderAudit> placeholderAuditProvider =
    FutureProvider<PlaceholderAudit>((ref) async {
  if (!ref.watch(canViewPaymentMethodsProvider)) {
    return PlaceholderAudit.empty;
  }
  final List<AdminPaymentMethodView> methods =
      await ref.watch(paymentMethodListProvider.future);
  final PaymentMethodRepository repository =
      ref.watch(paymentMethodRepositoryProvider);

  final List<AdminPaymentMethodView> candidates = methods
      .where((AdminPaymentMethodView method) => method.isActive)
      .take(PlaceholderAudit.maxAuditedMethods)
      .toList(growable: false);

  final Map<String, List<AdminPaymentDestinationView>> found =
      <String, List<AdminPaymentDestinationView>>{};
  final Set<String> audited = <String>{};
  final Set<String> skipped = <String>{};

  await Future.wait<void>(
    candidates.map((AdminPaymentMethodView method) async {
      try {
        final List<AdminPaymentDestinationView> destinations =
            await repository.listDestinations(
          method.id,
          includeInactive: false,
        );
        audited.add(method.id);
        final List<AdminPaymentDestinationView> placeholders = destinations
            .where(
              (AdminPaymentDestinationView row) => row.looksLikePlaceholder,
            )
            .toList(growable: false);
        if (placeholders.isNotEmpty) {
          found[method.id] = placeholders;
        }
      } on ApiError catch (error) {
        // Best effort: one unreadable method must not hide the warning for the
        // others. The detail screen will surface the real error.
        skipped.add(method.id);
        AppLogger.warn(
          'placeholder audit skipped ${method.code}: ${error.code}',
          scope: 'payment-methods',
        );
      }
    }),
  );

  return PlaceholderAudit(
    byMethodId: Map<String, List<AdminPaymentDestinationView>>.unmodifiable(found),
    auditedMethodIds: Set<String>.unmodifiable(audited),
    skippedMethodIds: Set<String>.unmodifiable(skipped),
  );
});

/// True when the signed-in role may READ this surface.
///
/// This is NOT `AdminCapability.viewPaymentMethods`: that core gate allows
/// every role (correct for the deposit queue), while
/// `PAYMENT_METHOD_READER_ROLES` excludes VIEWER, who gets a 403 on every route
/// here. The router still routes a VIEWER to the screen, so the screen shows a
/// permission-denied state rather than an inevitable red error.
final Provider<bool> canViewPaymentMethodsProvider = Provider<bool>(
  (ref) => PaymentMethodRoles.canView(ref.watch(currentRoleProvider)),
);

/// True when the signed-in role may CREATE / EDIT / DISABLE here
/// (`PAYMENT_METHOD_MANAGER_ROLES`: SUPER_ADMIN and FINANCE_ADMIN).
final Provider<bool> canManagePaymentMethodsProvider = Provider<bool>((ref) {
  final AdminRole? role = ref.watch(currentRoleProvider);
  return PaymentMethodRoles.canManage(role) &&
      AdminRoles.can(role, AdminCapability.managePaymentDestinations);
});
