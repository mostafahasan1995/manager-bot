import 'package:flutter_test/flutter_test.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/features/shell/profile/application/health_check_controller.dart';
import 'package:manager_bot/features/shell/profile/presentation/widgets/profile_labels.dart';

/// The health probe is the ONE thing on this tab that touches the network, so
/// the state it exposes has to be unambiguous before a widget ever reads it.
void main() {
  group('HealthProbeState', () {
    test('starts idle, with nothing to report', () {
      const HealthProbeState state = HealthProbeState();

      expect(state.phase, HealthPhase.idle);
      expect(state.latency, isNull);
      expect(state.latencyMs, isNull);
      expect(state.checkedAt, isNull);
      expect(state.failure, isNull);
      expect(state.isBusy, isFalse);
    });

    test('reports latency in whole milliseconds', () {
      const HealthProbeState state = HealthProbeState(
        phase: HealthPhase.online,
        latency: Duration(microseconds: 82400),
      );

      expect(state.latencyMs, 82);
      expect(state.isBusy, isFalse);
    });

    test('is busy only while a probe is in flight', () {
      const HealthProbeState state = HealthProbeState(
        phase: HealthPhase.checking,
      );

      expect(state.isBusy, isTrue);
    });
  });

  group('ProfileHealthLabels', () {
    test('idle looks like checking to the pill, never like offline', () {
      expect(
        ProfileHealthLabels.phase(HealthPhase.idle),
        ProfileHealthLabels.phase(HealthPhase.checking),
      );
    });

    test('latency is shown only for a probe that actually answered', () {
      const HealthProbeState offline = HealthProbeState(
        phase: HealthPhase.offline,
        latency: Duration(milliseconds: 9000),
      );
      const HealthProbeState checking = HealthProbeState(
        phase: HealthPhase.checking,
      );

      expect(ProfileHealthLabels.detail(AppStrings.en, offline), isNull);
      expect(ProfileHealthLabels.detail(AppStrings.en, checking), isNull);
    });
  });
}
