/// The single place where home DATA becomes home LOOK AND WORDS.
///
/// Keeping the three mappings together - status to tone, status to glyph, slot
/// to copy - means one idea is always one colour and one sentence across the
/// screen, and a new status is a compile error here rather than a grey chip in
/// production.
library;

import 'package:flutter/material.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/ui/ui.dart';
import 'package:manager_bot/features/shell/home/data/home_models.dart';

abstract final class HomeLabels {
  /// Already-localised status text. Reuses the catalogue's existing deposit
  /// vocabulary - the player and the cashier read the same words.
  static String depositStatus(AppStrings s, HomeDepositStatus status) =>
      switch (status) {
        HomeDepositStatus.submitted => s.statusSubmitted,
        HomeDepositStatus.underReview => s.statusUnderReview,
        HomeDepositStatus.approved => s.statusApproved,
        HomeDepositStatus.credited => s.statusCredited,
        HomeDepositStatus.rejected => s.statusRejected,
      };

  /// Semantic colour for a status. Money in is green, waiting is amber,
  /// refused is red - the same everywhere in the app.
  static AppTone depositTone(HomeDepositStatus status) => switch (status) {
        HomeDepositStatus.submitted => AppTone.pending,
        HomeDepositStatus.underReview => AppTone.pending,
        HomeDepositStatus.approved => AppTone.approved,
        HomeDepositStatus.credited => AppTone.credited,
        HomeDepositStatus.rejected => AppTone.rejected,
      };

  /// Glyph for the avatar ring on a deposit row.
  static IconData depositIcon(HomeDepositStatus status) => switch (status) {
        HomeDepositStatus.submitted => Icons.schedule_rounded,
        HomeDepositStatus.underReview => Icons.hourglass_bottom_rounded,
        HomeDepositStatus.approved => Icons.verified_rounded,
        HomeDepositStatus.credited => Icons.check_circle_rounded,
        HomeDepositStatus.rejected => Icons.cancel_rounded,
      };

  /// Ring gradient for a deposit row, matched to the tone rather than to the
  /// brand: a refused row must not look celebratory.
  static LinearGradient depositGradient(HomeDepositStatus status) =>
      switch (status) {
        HomeDepositStatus.submitted => AppPalette.gradientNeon,
        HomeDepositStatus.underReview => AppPalette.gradientNeon,
        HomeDepositStatus.approved => AppPalette.gradientNeon,
        HomeDepositStatus.credited => AppPalette.gradientCredited,
        HomeDepositStatus.rejected => AppPalette.gradientSunset,
      };

  /// The gradient behind a promo accent hint.
  static LinearGradient accent(HomeAccent accent) => switch (accent) {
        HomeAccent.signature => AppPalette.gradientSignature,
        HomeAccent.neon => AppPalette.gradientNeon,
        HomeAccent.hot => AppPalette.gradientHot,
        HomeAccent.sunset => AppPalette.gradientSunset,
      };

  /// Glyph for a promo card.
  static IconData promoIcon(HomePromoSlot slot) => switch (slot) {
        HomePromoSlot.welcomeBonus => Icons.card_giftcard_rounded,
        HomePromoSlot.instantCredit => Icons.bolt_rounded,
        HomePromoSlot.trustedRails => Icons.verified_user_rounded,
      };

  /// Already-localised promo headline.
  static String promoTitle(AppStrings s, HomePromoSlot slot) => switch (slot) {
        HomePromoSlot.welcomeBonus => s.homePromoBonusTitle,
        HomePromoSlot.instantCredit => s.homePromoInstantTitle,
        HomePromoSlot.trustedRails => s.homePromoRailsTitle,
      };

  /// Already-localised promo body copy.
  static String promoBody(AppStrings s, HomePromoSlot slot) => switch (slot) {
        HomePromoSlot.welcomeBonus => s.homePromoBonusBody,
        HomePromoSlot.instantCredit => s.homePromoInstantBody,
        HomePromoSlot.trustedRails => s.homePromoRailsBody,
      };

  /// Already-localised label for the backend health pill.
  static String connection(AppStrings s, ConnectionPhase phase) =>
      switch (phase) {
        ConnectionPhase.checking => s.connectionChecking,
        ConnectionPhase.online => s.connectionOnline,
        ConnectionPhase.offline => s.connectionOffline,
      };
}
