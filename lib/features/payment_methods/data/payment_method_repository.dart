import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/api/api_client.dart';
import 'package:manager_bot/core/api/api_response.dart';
import 'package:manager_bot/core/api/json.dart';
import 'package:manager_bot/features/payment_methods/data/admin_payment_destination_view.dart';
import 'package:manager_bot/features/payment_methods/data/admin_payment_method_view.dart';
import 'package:manager_bot/features/payment_methods/data/payment_enums.dart';
import 'package:manager_bot/features/payment_methods/data/payment_method_requests.dart';

/// Every call the admin payment-method surface can make.
///
/// Things this class encodes so no screen has to remember them:
///
/// * NO PAGINATION anywhere here. Both lists return the whole matching set as a
///   plain array, so these are `List`s and not `CursorPage`/`OffsetPage`.
/// * TWO PATH ROOTS for destinations: create/list are nested under the METHOD
///   id, update/deactivate are flat under the DESTINATION id. Mixing them up
///   yields a 404, not a 400.
/// * DELETE MEANS DISABLE and answers 200 WITH A BODY (the updated row), never
///   204. Re-enabling is a PATCH `{isActive: true}`; there is no enable route.
/// * The two boolean query params are validated DIFFERENTLY on purpose:
///   `isActive` accepts only `"true"`/`"false"`, while `includeInactive` also
///   accepts `"1"`/`"0"` but the handler only honours the literal `"true"`. One
///   shared serializer would be wrong, so each is written out here.
/// * NO idempotency key and NO rate limit on this surface. A repeated POST is a
///   409, not a replay.
///
/// Every failure is already an [ApiError]; a `DioException` cannot reach a
/// caller.
class PaymentMethodRepository {
  const PaymentMethodRepository(this._client);

  /// `/v1/admin/payment-methods`. There is no global `/api` prefix.
  static const String methodsPath = '/v1/admin/payment-methods';

  /// `/v1/admin/payment-destinations` - the FLAT root, for update/deactivate.
  static const String destinationsPath = '/v1/admin/payment-destinations';

  final ApiClient _client;

  /// `GET /v1/admin/payment-methods`.
  ///
  /// Ordered by `sortOrder` ASC then `displayName` ASC, server-side and stable.
  /// Unlike the player list this includes rails with no driver, so an
  /// `INTERNAL` row with an empty `requiredProofFields` can appear.
  Future<List<AdminPaymentMethodView>> listMethods({
    bool? isActive,
    PaymentRail? rail,
  }) async {
    final ApiResponse<Object?> response = await _client.get(
      methodsPath,
      query: <String, Object?>{
        // ONLY the exact strings 'true'/'false' pass this DTO's transform.
        if (isActive != null) 'isActive': isActive ? 'true' : 'false',
        if (rail != null) 'rail': rail.wireName,
      },
    );
    return Json.list<AdminPaymentMethodView>(
      response.data,
      AdminPaymentMethodView.fromJson,
      path: methodsPath,
    );
  }

  /// `GET /v1/admin/payment-methods/{id}`. 404 `PAYMENT_METHOD_NOT_FOUND`
  /// arrives as [ApiNotFound].
  Future<AdminPaymentMethodView> getMethod(String id) =>
      _client.getObject<AdminPaymentMethodView>(
        '$methodsPath/$id',
        fromJson: AdminPaymentMethodView.fromJson,
      );

  /// `POST /v1/admin/payment-methods` -> 201 with the created row.
  ///
  /// 409 `PAYMENT_METHOD_ALREADY_EXISTS` (duplicate code) and 422
  /// `RAIL_NOT_SUPPORTED` (a rail with no driver) both reach the caller as
  /// typed errors.
  Future<AdminPaymentMethodView> createMethod(
    CreatePaymentMethodRequest request,
  ) =>
      _client.postObject<AdminPaymentMethodView>(
        methodsPath,
        fromJson: AdminPaymentMethodView.fromJson,
        body: request.toJson(),
      );

  /// `PATCH /v1/admin/payment-methods/{id}` -> the full post-update row.
  ///
  /// Coherence is re-checked against the MERGED values, so a partial edit can
  /// still be refused because of a field it did not send.
  Future<AdminPaymentMethodView> updateMethod(
    String id,
    UpdatePaymentMethodRequest request,
  ) =>
      _client.patchObject<AdminPaymentMethodView>(
        '$methodsPath/$id',
        fromJson: AdminPaymentMethodView.fromJson,
        body: request.toJson(),
      );

  /// `DELETE /v1/admin/payment-methods/{id}` - DEACTIVATES, never deletes.
  ///
  /// Answers 200 with the updated row (`isActive == false`) and is idempotent.
  /// Historical deposits and the RAIL_CLEARING ledger account reference the row
  /// with `onDelete: Restrict`, so it can never actually be removed.
  Future<AdminPaymentMethodView> deactivateMethod(String id) async {
    final ApiResponse<Object?> response =
        await _client.delete('$methodsPath/$id');
    return AdminPaymentMethodView.fromJson(
      Json.asObject(response.data, path: '$methodsPath/$id'),
    );
  }

  /// Re-enable. There is no dedicated route: it is a PATCH.
  Future<AdminPaymentMethodView> setMethodActive(
    String id, {
    required bool isActive,
  }) =>
      updateMethod(id, UpdatePaymentMethodRequest.activation(isActive: isActive));

  /// `GET /v1/admin/payment-methods/{id}/destinations`.
  ///
  /// [methodId] is the METHOD id. Ordered by `priority` ASC then `id` ASC - the
  /// rotation cursor indexes into exactly this order. 404
  /// `PAYMENT_METHOD_NOT_FOUND` when the method does not exist.
  Future<List<AdminPaymentDestinationView>> listDestinations(
    String methodId, {
    required bool includeInactive,
  }) async {
    final String path = '$methodsPath/$methodId/destinations';
    final ApiResponse<Object?> response = await _client.get(
      path,
      query: <String, Object?>{
        // The handler tests `=== 'true'`, so only this literal works. '1'
        // validates and then behaves as false, which is worse than useless.
        if (includeInactive) 'includeInactive': 'true',
      },
    );
    return Json.list<AdminPaymentDestinationView>(
      response.data,
      AdminPaymentDestinationView.fromJson,
      path: path,
    );
  }

  /// `POST /v1/admin/payment-methods/{id}/destinations` -> 201.
  ///
  /// The method id comes from the PATH; putting it in the body is a 400. A
  /// repeat with the same `accountIdentifier` is 409
  /// `DESTINATION_ALREADY_EXISTS`, NOT an idempotent replay.
  Future<AdminPaymentDestinationView> createDestination(
    String methodId,
    CreatePaymentDestinationRequest request,
  ) =>
      _client.postObject<AdminPaymentDestinationView>(
        '$methodsPath/$methodId/destinations',
        fromJson: AdminPaymentDestinationView.fromJson,
        body: request.toJson(),
      );

  /// `PATCH /v1/admin/payment-destinations/{id}` - note the FLAT root and that
  /// [destinationId] is the DESTINATION id, not the method id.
  Future<AdminPaymentDestinationView> updateDestination(
    String destinationId,
    UpdatePaymentDestinationRequest request,
  ) =>
      _client.patchObject<AdminPaymentDestinationView>(
        '$destinationsPath/$destinationId',
        fromJson: AdminPaymentDestinationView.fromJson,
        body: request.toJson(),
      );

  /// `DELETE /v1/admin/payment-destinations/{id}` - DEACTIVATES and answers 200
  /// with the row. Idempotent.
  ///
  /// Deactivating does NOT clear the 24h per-player Redis stickiness: a player
  /// already told to pay here can still reconcile, but no new player is sent to
  /// it.
  Future<AdminPaymentDestinationView> deactivateDestination(
    String destinationId,
  ) async {
    final String path = '$destinationsPath/$destinationId';
    final ApiResponse<Object?> response = await _client.delete(path);
    return AdminPaymentDestinationView.fromJson(
      Json.asObject(response.data, path: path),
    );
  }

  /// Re-enable a destination. Again a PATCH; there is no enable route.
  Future<AdminPaymentDestinationView> setDestinationActive(
    String destinationId, {
    required bool isActive,
  }) =>
      updateDestination(
        destinationId,
        UpdatePaymentDestinationRequest.activation(isActive: isActive),
      );
}

/// The repository, wired to the app-wide [ApiClient].
final Provider<PaymentMethodRepository> paymentMethodRepositoryProvider =
    Provider<PaymentMethodRepository>(
  (ref) => PaymentMethodRepository(ref.watch(apiClientProvider)),
);
