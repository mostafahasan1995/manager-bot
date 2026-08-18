/// Every WRITE on the payment-method surface, plus the busy/outcome state a
/// screen needs to render it.
///
/// Writes never throw at the call site: an [ApiError] is turned into a
/// [MutationFailure] so a screen can show a snackbar and (where the server sent
/// `details.field`) highlight the offending input. A contract change is covered
/// too - `ApiClient` runs every `fromJson` inside its own guard, so a parse
/// failure arrives here as `ApiUnexpected` rather than as a raw throw.
library;

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/errors/api_error.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/i18n/locale_controller.dart';
import 'package:manager_bot/features/payment_methods/application/payment_method_providers.dart';
import 'package:manager_bot/features/payment_methods/data/admin_payment_destination_view.dart';
import 'package:manager_bot/features/payment_methods/data/admin_payment_method_view.dart';
import 'package:manager_bot/features/payment_methods/data/payment_method_repository.dart';
import 'package:manager_bot/features/payment_methods/data/payment_method_requests.dart';
import 'package:manager_bot/features/payment_methods/data/payment_method_rules.dart';

/// Outcome of one write. Sealed so a caller cannot forget the failure branch.
sealed class MutationResult<T> {
  const MutationResult();

  bool get isSuccess => this is MutationSuccess<T>;
}

/// The server accepted the write and returned the updated row.
final class MutationSuccess<T> extends MutationResult<T> {
  const MutationSuccess(this.value, {required this.message});

  final T value;

  /// Confirmation line for a snackbar.
  final String message;
}

/// The server refused. Everything the UI needs to explain it is precomputed.
///
/// The wording is resolved ONCE, at the moment of failure, from the
/// [AppStrings] the controller was holding - there is no `BuildContext` down
/// here and a snackbar must not re-resolve a message it is already showing.
final class MutationFailure<T> extends MutationResult<T> {
  factory MutationFailure(ApiError error, AppStrings strings) {
    final List<FieldIssue> issues = _issuesFrom(error, strings);
    final List<String> validation = _validationMessagesFrom(error);
    return MutationFailure<T>._(
      error,
      issues,
      validation,
      _messageFor(error, strings, issues, validation),
    );
  }

  const MutationFailure._(
    this.error,
    this.fieldIssues,
    this.validationMessages,
    this.message,
  );

  final ApiError error;

  /// Zero or one issue keyed to a real WIRE field name, from
  /// `details.field` (`PAYMENT_METHOD_INVALID`, `INVALID_AMOUNT`). Safe to use
  /// for highlighting an input.
  final List<FieldIssue> fieldIssues;

  /// `details.fields` from a DTO rejection. These are HUMAN SENTENCES from
  /// class-validator, NOT field names, so they are shown as text and never used
  /// to key a form field.
  final List<String> validationMessages;

  /// The line to put in a snackbar.
  final String message;

  /// True when the row moved under us and the screen should just reload.
  bool get shouldRefresh => error is ApiConflict || error is ApiNotFound;

  /// True when the operator simply lacks the role. The server is authoritative
  /// even when the UI thought the button was allowed.
  bool get isForbidden => error is ApiForbidden;

  /// Switches on the sealed [ApiError] VARIANT (exhaustive) and only then on
  /// the OPEN `code` string, which is the documented way round.
  static String _messageFor(
    ApiError error,
    AppStrings s,
    List<FieldIssue> fieldIssues,
    List<String> validationMessages,
  ) =>
      switch (error) {
        ApiConflict(code: final String code) => switch (code) {
            'PAYMENT_METHOD_ALREADY_EXISTS' => s.pmCodeConflict,
            'DESTINATION_ALREADY_EXISTS' => s.pdConflict,
            _ => error.userMessage(s),
          },
        ApiBusinessRule(code: final String code) => code == 'RAIL_NOT_SUPPORTED'
            ? s.pmRailNotSupported
            : error.userMessage(s),
        ApiValidation() => _validationMessage(
            error,
            s,
            fieldIssues,
            validationMessages,
          ),
        ApiNotFound(code: final String code) =>
          code == 'DESTINATION_NOT_FOUND' ? s.pdNotFound : s.pmNotFound,
        ApiForbidden() => error.userMessage(s),
        ApiUnauthorized() => error.userMessage(s),
        ApiRateLimited() => error.userMessage(s),
        ApiNetworkError() => error.userMessage(s),
        ApiTimeout() => error.userMessage(s),
        ApiServerError() => error.userMessage(s),
        ApiUnexpected() => error.userMessage(s),
      };

  static String _validationMessage(
    ApiError error,
    AppStrings s,
    List<FieldIssue> fieldIssues,
    List<String> validationMessages,
  ) {
    if (fieldIssues.isNotEmpty) {
      return PaymentMethodRules.describeIssue(fieldIssues.first, s);
    }
    if (validationMessages.isNotEmpty) {
      return validationMessages.join('\n');
    }
    // NOT userMessage: for DUPLICATE_RESOURCE / REFERENCE_CONSTRAINT
    // ApiValidation.userMessage appends raw Prisma column names.
    return error.resolvedMessage(s);
  }

  /// `details.fields` only when it holds class-validator SENTENCES. For
  /// `DUPLICATE_RESOURCE` / `REFERENCE_CONSTRAINT` the same key holds Prisma
  /// COLUMN NAMES instead, which would read like gibberish in a snackbar.
  static List<String> _validationMessagesFrom(ApiError error) {
    if (error is ApiValidation && !error.fieldsAreColumnNames) {
      return error.fieldMessages;
    }
    return const <String>[];
  }

  /// `details.field` (+ optional `details.reason`) as a single [FieldIssue].
  static List<FieldIssue> _issuesFrom(ApiError error, AppStrings s) {
    final String? field = error.detailString('field');
    if (field == null || field.isEmpty) {
      return const <FieldIssue>[];
    }
    final String? reason = error.detailString('reason');
    final String message = reason == null
        ? error.message
        : PaymentMethodRules.messageForMoneyReason(reason, s);
    return List<FieldIssue>.unmodifiable(<FieldIssue>[
      FieldIssue(field, message),
    ]);
  }
}

/// Which rows currently have a write in flight, so their buttons can spin.
@immutable
class PaymentMethodActionState {
  const PaymentMethodActionState({this.busyKeys = const <String>{}});

  /// Method ids, destination ids, or [createKey] while a create is running.
  final Set<String> busyKeys;

  /// Busy key used for a create, which has no id yet.
  static const String createKey = 'create';

  bool isBusy(String key) => busyKeys.contains(key);

  bool get isIdle => busyKeys.isEmpty;

  PaymentMethodActionState withBusy(String key) => PaymentMethodActionState(
        busyKeys: <String>{...busyKeys, key},
      );

  PaymentMethodActionState withoutBusy(String key) => PaymentMethodActionState(
        busyKeys: <String>{
          for (final String existing in busyKeys)
            if (existing != key) existing,
        },
      );

  @override
  bool operator ==(Object other) =>
      other is PaymentMethodActionState &&
      other.busyKeys.length == busyKeys.length &&
      other.busyKeys.containsAll(busyKeys);

  @override
  int get hashCode => Object.hashAllUnordered(busyKeys);
}

/// All writes, funnelled through one notifier so busy state and cache
/// invalidation are impossible to forget.
class PaymentMethodActionsController extends Notifier<PaymentMethodActionState> {
  @override
  PaymentMethodActionState build() => const PaymentMethodActionState();

  PaymentMethodRepository get _repository =>
      ref.read(paymentMethodRepositoryProvider);

  /// The catalogue for the CURRENT locale. Read per write, never cached, so a
  /// language change between two writes is honoured.
  AppStrings get _strings => ref.read(stringsProvider);

  /// `POST /v1/admin/payment-methods`.
  Future<MutationResult<AdminPaymentMethodView>> createMethod(
    CreatePaymentMethodRequest request,
  ) =>
      _run<AdminPaymentMethodView>(
        PaymentMethodActionState.createKey,
        () async {
          final AdminPaymentMethodView created =
              await _repository.createMethod(request);
          _invalidateMethod(created.id);
          return created;
        },
        message: (AdminPaymentMethodView view, AppStrings s) =>
            s.pmCreatedToast(name: view.displayName),
        onStale: _invalidateMethodList,
      );

  /// `PATCH /v1/admin/payment-methods/{id}`.
  Future<MutationResult<AdminPaymentMethodView>> updateMethod(
    String methodId,
    UpdatePaymentMethodRequest request,
  ) =>
      _run<AdminPaymentMethodView>(
        methodId,
        () async {
          final AdminPaymentMethodView updated =
              await _repository.updateMethod(methodId, request);
          _invalidateMethod(methodId);
          return updated;
        },
        message: (AdminPaymentMethodView view, AppStrings s) =>
            s.pmSavedToast(name: view.displayName),
        onStale: () => _invalidateMethod(methodId),
      );

  /// Enable or disable a method.
  ///
  /// Disabling goes through DELETE (which is `update({isActive:false})` and
  /// answers 200 with the row); enabling is a PATCH, because no enable route
  /// exists.
  Future<MutationResult<AdminPaymentMethodView>> setMethodActive(
    String methodId, {
    required bool isActive,
  }) =>
      _run<AdminPaymentMethodView>(
        methodId,
        () async {
          final AdminPaymentMethodView updated = isActive
              ? await _repository.setMethodActive(methodId, isActive: true)
              : await _repository.deactivateMethod(methodId);
          _invalidateMethod(methodId);
          return updated;
        },
        message: (AdminPaymentMethodView view, AppStrings s) => view.isActive
            ? s.pmEnabledToast(name: view.displayName)
            : s.pmDisabledToast(name: view.displayName),
        onStale: () => _invalidateMethod(methodId),
      );

  /// `POST /v1/admin/payment-methods/{methodId}/destinations`.
  Future<MutationResult<AdminPaymentDestinationView>> createDestination(
    String methodId,
    CreatePaymentDestinationRequest request,
  ) =>
      _run<AdminPaymentDestinationView>(
        PaymentMethodActionState.createKey,
        () async {
          final AdminPaymentDestinationView created =
              await _repository.createDestination(methodId, request);
          _invalidateDestinations(methodId);
          return created;
        },
        message: (AdminPaymentDestinationView view, AppStrings s) =>
            s.pdAddedToast(label: view.label),
        onStale: () => _invalidateDestinations(methodId),
      );

  /// `PATCH /v1/admin/payment-destinations/{destinationId}`.
  ///
  /// [methodId] is only used to invalidate the right cached list.
  Future<MutationResult<AdminPaymentDestinationView>> updateDestination({
    required String destinationId,
    required String methodId,
    required UpdatePaymentDestinationRequest request,
  }) =>
      _run<AdminPaymentDestinationView>(
        destinationId,
        () async {
          final AdminPaymentDestinationView updated =
              await _repository.updateDestination(destinationId, request);
          _invalidateDestinations(methodId);
          return updated;
        },
        message: (AdminPaymentDestinationView view, AppStrings s) =>
            s.pdSavedToast(label: view.label),
        onStale: () => _invalidateDestinations(methodId),
      );

  /// Enable or disable a destination.
  Future<MutationResult<AdminPaymentDestinationView>> setDestinationActive({
    required String destinationId,
    required String methodId,
    required bool isActive,
  }) =>
      _run<AdminPaymentDestinationView>(
        destinationId,
        () async {
          final AdminPaymentDestinationView updated = isActive
              ? await _repository.setDestinationActive(
                  destinationId,
                  isActive: true,
                )
              : await _repository.deactivateDestination(destinationId);
          _invalidateDestinations(methodId);
          return updated;
        },
        message: (AdminPaymentDestinationView view, AppStrings s) =>
            view.isActive
                ? s.pdEnabledToast(label: view.label)
                : s.pdDisabledToast(label: view.label),
        onStale: () => _invalidateDestinations(methodId),
      );

  /// Everything a method-level write can stale, minus the row itself. Used on
  /// a create, which has no id yet.
  void _invalidateMethodList() {
    ref
      ..invalidate(paymentMethodListProvider)
      ..invalidate(placeholderAuditProvider);
  }

  void _invalidateMethod(String methodId) {
    _invalidateMethodList();
    ref.invalidate(paymentMethodProvider(methodId));
  }

  void _invalidateDestinations(String methodId) {
    ref
      ..invalidate(
        paymentDestinationsProvider(
          DestinationQuery(methodId: methodId, includeInactive: true),
        ),
      )
      ..invalidate(
        paymentDestinationsProvider(
          DestinationQuery(methodId: methodId, includeInactive: false),
        ),
      )
      ..invalidate(placeholderAuditProvider);
  }

  /// Runs one write, tracks its busy key, and turns an [ApiError] into a
  /// [MutationFailure].
  ///
  /// [onStale] is fired when the failure is a [MutationFailure.shouldRefresh]
  /// one - a 409 because somebody else moved the row first, or a 404 because it
  /// is gone. Without it the snackbar said "Refreshing." while nothing
  /// refreshed, and the screen kept offering a button for a state the server had
  /// already left behind.
  Future<MutationResult<T>> _run<T>(
    String busyKey,
    Future<T> Function() action, {
    required String Function(T value, AppStrings s) message,
    required void Function() onStale,
  }) async {
    final AppStrings strings = _strings;
    state = state.withBusy(busyKey);
    try {
      final T value = await action();
      return MutationSuccess<T>(value, message: message(value, strings));
    } on ApiError catch (error) {
      final MutationFailure<T> failure = MutationFailure<T>(error, strings);
      if (failure.shouldRefresh) {
        onStale();
      }
      return failure;
    } finally {
      state = state.withoutBusy(busyKey);
    }
  }
}

final NotifierProvider<PaymentMethodActionsController, PaymentMethodActionState>
    paymentMethodActionsProvider = NotifierProvider<
        PaymentMethodActionsController, PaymentMethodActionState>(
  PaymentMethodActionsController.new,
);
