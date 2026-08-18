/// Presentation-only mappings for the طرق الدفع destination.
///
/// The data layer names an INTENT (`MethodAccent.hot`, `MethodRail.crypto`) and
/// this file turns it into paint. Nothing here formats an amount: `AmountText`
/// owns that, exactly and over `BigInt`.
library;

import 'package:flutter/material.dart';
import 'package:manager_bot/core/errors/api_error.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/ui/ui.dart';
import 'package:manager_bot/features/shell/methods/data/payment_method_demo_models.dart';

abstract final class MethodsFormats {
  /// The brand gradient a method wears.
  static LinearGradient gradientOf(MethodAccent accent) => switch (accent) {
        MethodAccent.signature => AppPalette.gradientSignature,
        MethodAccent.neon => AppPalette.gradientNeon,
        MethodAccent.hot => AppPalette.gradientHot,
        MethodAccent.sunset => AppPalette.gradientSunset,
        MethodAccent.glitch => AppPalette.gradientGlitch,
        MethodAccent.credited => AppPalette.gradientCredited,
      };

  /// A rail's glyph. Deliberately generic shapes - these stand in for brand
  /// logos that do not exist as assets yet.
  static IconData railIcon(MethodRail rail) => switch (rail) {
        MethodRail.bankTransfer => Icons.account_balance_rounded,
        MethodRail.mobileWallet => Icons.smartphone_rounded,
        MethodRail.cashOffice => Icons.store_rounded,
        MethodRail.crypto => Icons.monetization_on_rounded,
        MethodRail.internal => Icons.swap_horiz_rounded,
      };

  /// Money semantics of a rail's health. A paused rail is NEUTRAL rather than
  /// rejected: nothing has failed, it is simply switched off.
  static AppTone availabilityTone(MethodAvailability availability) =>
      switch (availability) {
        MethodAvailability.available => AppTone.credited,
        MethodAvailability.busy => AppTone.pending,
        MethodAvailability.unavailable => AppTone.neutral,
      };

  static IconData availabilityIcon(MethodAvailability availability) =>
      switch (availability) {
        MethodAvailability.available => Icons.bolt_rounded,
        MethodAvailability.busy => Icons.hourglass_empty_rounded,
        MethodAvailability.unavailable => Icons.pause_rounded,
      };

  static String availabilityLabel(
    MethodAvailability availability,
    AppStrings s,
  ) =>
      switch (availability) {
        MethodAvailability.available => s.methodsBadgeAvailable,
        MethodAvailability.busy => s.methodsBadgeBusy,
        MethodAvailability.unavailable => s.methodsBadgeUnavailable,
      };

  /// The one-line caution under a card, or null when there is nothing to warn
  /// about. Never invent noise for a healthy rail.
  static String? availabilityNote(
    MethodAvailability availability,
    AppStrings s,
  ) =>
      switch (availability) {
        MethodAvailability.available => null,
        MethodAvailability.busy => s.methodsBusyNote,
        MethodAvailability.unavailable => s.methodsPausedNote,
      };

  /// Coarse duration phrase built from the catalogue's own age nouns, so it
  /// reads "12 د" under Arabic and "12m" under English - Western digits in
  /// both, like every other number in this app.
  static String duration(Duration value, AppStrings s) {
    if (value.inMinutes < 1) {
      return s.ageNow;
    }
    if (value.inHours < 1) {
      return s.ageMinutes(count: value.inMinutes);
    }
    if (value.inDays < 1) {
      final int hours = value.inHours;
      final int minutes = value.inMinutes - hours * 60;
      return minutes == 0
          ? s.ageHours(count: hours)
          : s.ageHoursMinutes(hours: hours, minutes: minutes);
    }
    final int days = value.inDays;
    final int hours = value.inHours - days * 24;
    return hours == 0
        ? s.ageDays(count: days)
        : s.ageDaysHours(days: days, hours: hours);
  }

  /// "خلال 10 د" / "Within 10m", or the instant phrase for a zero wait.
  static String settlement(Duration value, AppStrings s) =>
      value <= Duration.zero
          ? s.methodsSettlementInstant
          : s.methodsSettlementWithin(age: duration(value, s));

  /// "منذ 4 د" / "4m ago".
  static String checked(Duration ago, AppStrings s) =>
      s.ageAgo(age: duration(ago, s));

  /// Title for the error shape. Exhaustive over the sealed [ApiError] tree, so
  /// a new wire failure mode cannot slip through untranslated.
  static String errorTitle(Object error, AppStrings s) {
    if (error is! ApiError) {
      return s.errorTitleUnexpectedResponse;
    }
    return switch (error) {
      ApiUnauthorized() => s.errorTitleSessionExpired,
      ApiForbidden() => s.errorTitleNotAllowed,
      ApiValidation() => s.errorTitleCheckDetails,
      ApiNotFound() => s.errorTitleNotFound,
      ApiConflict() => s.errorTitleAlreadyHandled,
      ApiBusinessRule() => s.errorTitleCannotDoThat,
      ApiRateLimited() => s.errorTitleTooManyRequests,
      ApiNetworkError() => s.errorTitleNoConnection,
      ApiTimeout() => s.errorTitleTimedOut,
      ApiServerError() => s.errorTitleServerError,
      ApiUnexpected() => s.errorTitleUnexpectedResponse,
    };
  }

  /// Body for the error shape.
  static String errorMessage(Object error, AppStrings s) =>
      error is ApiError ? error.userMessage(s) : s.errorRequestFailed;

  /// The wire code, rendered dim and tabular under the message so a player can
  /// quote it to support. Null when there is nothing quotable.
  static String? errorDetails(Object error) =>
      error is ApiError ? error.code : null;
}
