import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/errors/api_error.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/ui/ui.dart';
import 'package:manager_bot/features/shell/profile/application/health_check_controller.dart';
import 'package:manager_bot/features/shell/profile/application/profile_controller.dart';
import 'package:manager_bot/features/shell/profile/data/profile_demo_data.dart';
import 'package:manager_bot/features/shell/profile/presentation/widgets/profile_detail_card.dart';
import 'package:manager_bot/features/shell/profile/presentation/widgets/profile_header_card.dart';
import 'package:manager_bot/features/shell/profile/presentation/widgets/profile_health_card.dart';
import 'package:manager_bot/features/shell/profile/presentation/widgets/profile_labels.dart';
import 'package:manager_bot/features/shell/profile/presentation/widgets/profile_settings_cards.dart';
import 'package:manager_bot/features/shell/profile/presentation/widgets/profile_skeleton.dart';
import 'package:manager_bot/features/shell/profile/presentation/widgets/profile_stat_tiles.dart';

/// حسابي - the fifth destination: who the player is, and every setting they
/// own.
///
/// Two things are real here and everything else is local sample content:
/// the LANGUAGE TOGGLE, which drives the app-wide locale controller and
/// persists to the keystore, and the CONNECTION CHECK, which probes the public
/// `GET /health/live` through the app's own `ApiClient`. There is no session in
/// this build, so no other endpoint has anything to say.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = context.s;
    final AsyncValue<PlayerProfile?> profile =
        ref.watch(profileControllerProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppPalette.accentCyan,
          backgroundColor: AppPalette.surface2,
          onRefresh: () async {
            await ref.read(profileControllerProvider.notifier).reload();
            await ref.read(healthCheckControllerProvider.notifier).check();
          },
          child: ListView(
            padding: AppSpacing.pagePadding,
            physics: const AlwaysScrollableScrollPhysics(),
            children: <Widget>[
              const _ProfileTopBar(),
              const SizedBox(height: AppSpacing.lg),
              ...profile.when(
                data: (PlayerProfile? value) => value == null
                    ? <Widget>[
                        EmptyState(
                          title: s.profileEmptyTitle,
                          message: s.profileEmptyMessage,
                          icon: Icons.person_outline_rounded,
                        ),
                      ]
                    : _sections(s, value),
                loading: () => const <Widget>[ProfileSkeleton()],
                error: (Object error, StackTrace stackTrace) => <Widget>[
                  ErrorState(
                    title: s.profileLoadFailedTitle,
                    message: error is ApiError
                        ? error.userMessage(s)
                        : s.errorRequestFailed,
                    details: error is ApiError ? error.correlationId : null,
                    retryLabel: s.retry,
                    onRetry: () => unawaited(
                      ref.read(profileControllerProvider.notifier).reload(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The loaded tab, staggered so it assembles itself instead of snapping in.
  List<Widget> _sections(AppStrings s, PlayerProfile profile) =>
      AppEntrance.stagger(<Widget>[
        ProfileHeaderCard(profile: profile),
        const SizedBox(height: AppSpacing.md),
        ProfileStatTiles(profile: profile),
        SectionHeader(
          title: s.profileSectionAccount,
          icon: Icons.badge_outlined,
        ),
        ProfileDetailCard(profile: profile),
        SectionHeader(
          title: s.settingsTooltip,
          icon: Icons.tune_rounded,
        ),
        const ProfileLanguageCard(),
        const SizedBox(height: AppSpacing.md),
        const ProfileHealthCard(),
        const SizedBox(height: AppSpacing.md),
        ProfileAboutCard(profile: profile),
      ]);
}

/// Brand line plus the live backend badge. Tapping the badge probes again.
class _ProfileTopBar extends ConsumerWidget {
  const _ProfileTopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = context.s;
    final HealthProbeState probe = ref.watch(healthCheckControllerProvider);
    return Row(
      children: <Widget>[
        Expanded(
          child: GradientText(
            s.profileTitle,
            style: Theme.of(context).textTheme.headlineSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        ConnectionPill(
          phase: ProfileHealthLabels.phase(probe.phase),
          label: ProfileHealthLabels.label(s, probe.phase),
          detail: ProfileHealthLabels.detail(s, probe),
          dense: true,
          onTap: () => unawaited(
            ref.read(healthCheckControllerProvider.notifier).check(),
          ),
        ),
      ],
    );
  }
}
