import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/config/app_config.dart';
import 'package:manager_bot/core/errors/api_error.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/ui/ui.dart';
import 'package:manager_bot/features/shell/profile/application/health_check_controller.dart';
import 'package:manager_bot/features/shell/profile/presentation/widgets/profile_labels.dart';
import 'package:manager_bot/features/shell/profile/presentation/widgets/profile_rows.dart';

/// The one card on this tab that talks to the real backend.
///
/// It probes the PUBLIC `GET /health/live` through the app's `ApiClient` and
/// shows the answer, the round trip and the base URL the build points at, plus
/// a manual re-check. Everything else on the profile tab is local sample data.
class ProfileHealthCard extends ConsumerWidget {
  const ProfileHealthCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = context.s;
    final ThemeData theme = Theme.of(context);
    final HealthProbeState probe = ref.watch(healthCheckControllerProvider);
    final AppConfig config = ref.watch(appConfigProvider);
    final ApiError? failure = probe.failure;
    final DateTime? checkedAt = probe.checkedAt;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.wifi_tethering_rounded,
                size: 20,
                color: AppPalette.accentCyan,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  s.profileSectionConnection,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              ConnectionPill(
                phase: ProfileHealthLabels.phase(probe.phase),
                label: ProfileHealthLabels.label(s, probe.phase),
                detail: ProfileHealthLabels.detail(s, probe),
                dense: true,
              ),
            ],
          ),
          const Divider(height: AppSpacing.xl),
          ProfileDetailRow(
            label: s.profileBaseUrlLabel,
            child: ProfileValueText(config.baseUrl, tabular: true),
          ),
          ProfileDetailRow(
            label: s.profileHealthEndpointLabel,
            child: const ProfileValueText(
              HealthCheckController.healthLivePath,
              tabular: true,
            ),
          ),
          ProfileDetailRow(
            label: s.profileEnvironmentLabel,
            child: ProfileValueText(config.environment.wireName.toUpperCase()),
          ),
          ProfileDetailRow(
            label: s.profileLastCheckedLabel,
            child: ProfileValueText(
              checkedAt == null
                  ? s.emptyValueDash
                  : AppDateFormats.timeOfDay(checkedAt, context.localeTag),
              tabular: true,
            ),
          ),
          if (failure != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(
              failure.userMessage(s),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppPalette.tone(AppTone.rejected).foreground,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: s.profileRecheckButton,
            variant: AppButtonVariant.tonal,
            icon: Icons.refresh_rounded,
            loading: probe.isBusy,
            expand: true,
            onPressed: () => unawaited(
              ref.read(healthCheckControllerProvider.notifier).check(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            s.timesAreLocalNote,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppPalette.textDisabled,
            ),
          ),
        ],
      ),
    );
  }
}
