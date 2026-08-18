import 'package:flutter/material.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/ui/ui.dart';
import 'package:manager_bot/features/shell/profile/application/health_check_controller.dart';
import 'package:manager_bot/features/shell/profile/data/profile_demo_data.dart';

/// Maps the profile's enums onto already-localised text, a semantic tone and a
/// glyph.
///
/// Nothing here paints and nothing here formats an amount: a widget asks for a
/// label, never for a colour of its own, so the same idea is always the same
/// colour across the tab.
abstract final class ProfileLabels {
  static String accountStatus(AppStrings s, PlayerAccountStatus status) =>
      switch (status) {
        PlayerAccountStatus.active => s.profileAccountStatusActive,
        PlayerAccountStatus.limited => s.profileAccountStatusLimited,
        PlayerAccountStatus.suspended => s.profileAccountStatusSuspended,
      };

  static AppTone accountTone(PlayerAccountStatus status) => switch (status) {
        PlayerAccountStatus.active => AppTone.credited,
        PlayerAccountStatus.limited => AppTone.attention,
        PlayerAccountStatus.suspended => AppTone.rejected,
      };

  static IconData accountIcon(PlayerAccountStatus status) => switch (status) {
        PlayerAccountStatus.active => Icons.verified_rounded,
        PlayerAccountStatus.limited => Icons.error_outline_rounded,
        PlayerAccountStatus.suspended => Icons.block_rounded,
      };

  static String gamingAccount(AppStrings s, GamingAccountState state) =>
      switch (state) {
        GamingAccountState.linked => s.profileGamingLinked,
        GamingAccountState.pending => s.profileGamingPending,
        GamingAccountState.missing => s.profileGamingMissing,
      };

  static AppTone gamingTone(GamingAccountState state) => switch (state) {
        GamingAccountState.linked => AppTone.approved,
        GamingAccountState.pending => AppTone.pending,
        GamingAccountState.missing => AppTone.neutral,
      };

  static IconData gamingIcon(GamingAccountState state) => switch (state) {
        GamingAccountState.linked => Icons.link_rounded,
        GamingAccountState.pending => Icons.hourglass_bottom_rounded,
        GamingAccountState.missing => Icons.link_off_rounded,
      };

  /// A coarse age - "12 د", "4 س", "287 ي" - built from the age keys the app
  /// already ships, so a duration reads the same here as on a deposit card.
  static String age(AppStrings s, Duration value) {
    if (value.isNegative) {
      return s.ageInFuture;
    }
    if (value.inSeconds < 5) {
      return s.ageNow;
    }
    if (value.inMinutes < 1) {
      return s.ageSeconds(count: value.inSeconds);
    }
    if (value.inHours < 1) {
      return s.ageMinutes(count: value.inMinutes);
    }
    if (value.inDays < 1) {
      return s.ageHours(count: value.inHours);
    }
    return s.ageDays(count: value.inDays);
  }

  /// The same age as "منذ ..." / "... ago".
  static String ago(AppStrings s, Duration value) =>
      s.ageAgo(age: age(s, value));

  /// Hides everything but the last [visible] characters of an identifier.
  ///
  /// Purely a glyph swap: the characters that survive are untouched, so a
  /// revealed id still reads exactly as the bot printed it.
  static String masked(String value, {int visible = 4}) {
    if (value.length <= visible) {
      return value;
    }
    final int hidden = value.length - visible;
    return '${'•' * hidden}${value.substring(hidden)}';
  }
}

/// Maps the probe state onto the kit's [ConnectionPill] vocabulary.
abstract final class ProfileHealthLabels {
  static ConnectionPhase phase(HealthPhase value) => switch (value) {
        HealthPhase.idle || HealthPhase.checking => ConnectionPhase.checking,
        HealthPhase.online => ConnectionPhase.online,
        HealthPhase.offline => ConnectionPhase.offline,
      };

  static String label(AppStrings s, HealthPhase value) => switch (value) {
        HealthPhase.idle || HealthPhase.checking => s.connectionChecking,
        HealthPhase.online => s.connectionOnline,
        HealthPhase.offline => s.connectionOffline,
      };

  /// The pre-formatted latency the pill shows, or null when there is nothing
  /// trustworthy to show yet.
  static String? detail(AppStrings s, HealthProbeState state) {
    final int? ms = state.latencyMs;
    if (state.phase != HealthPhase.online || ms == null) {
      return null;
    }
    return s.connectionLatencyMs(ms: ms);
  }
}
