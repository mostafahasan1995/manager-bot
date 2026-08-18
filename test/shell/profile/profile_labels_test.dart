import 'package:flutter_test/flutter_test.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/ui/ui.dart';
import 'package:manager_bot/features/shell/profile/data/profile_demo_data.dart';
import 'package:manager_bot/features/shell/profile/presentation/widgets/profile_labels.dart';

/// The mapping layer is the only logic on this tab, so it is the only thing
/// worth a unit test: a status must never be unlabelled, and an age must never
/// come out in Arabic-Indic digits.
void main() {
  group('ProfileLabels account status', () {
    test('every status has a label in both bundles', () {
      for (final PlayerAccountStatus status in PlayerAccountStatus.values) {
        expect(ProfileLabels.accountStatus(AppStrings.ar, status), isNotEmpty);
        expect(ProfileLabels.accountStatus(AppStrings.en, status), isNotEmpty);
      }
    });

    test('a healthy account never wears a failure colour', () {
      expect(
        ProfileLabels.accountTone(PlayerAccountStatus.active),
        AppTone.credited,
      );
      expect(
        ProfileLabels.accountTone(PlayerAccountStatus.suspended),
        AppTone.rejected,
      );
      expect(
        ProfileLabels.accountTone(PlayerAccountStatus.limited),
        isNot(ProfileLabels.accountTone(PlayerAccountStatus.active)),
      );
    });
  });

  group('ProfileLabels gaming account', () {
    test('every state has a label and a tone', () {
      for (final GamingAccountState state in GamingAccountState.values) {
        expect(ProfileLabels.gamingAccount(AppStrings.ar, state), isNotEmpty);
        expect(ProfileLabels.gamingAccount(AppStrings.en, state), isNotEmpty);
      }
      expect(
        ProfileLabels.gamingTone(GamingAccountState.linked),
        AppTone.approved,
      );
      expect(
        ProfileLabels.gamingTone(GamingAccountState.pending),
        AppTone.pending,
      );
    });
  });

  group('ProfileLabels.age', () {
    test('picks the coarsest unit that still says something', () {
      expect(ProfileLabels.age(AppStrings.en, Duration.zero), 'now');
      expect(
        ProfileLabels.age(AppStrings.en, const Duration(seconds: 42)),
        '42s',
      );
      expect(
        ProfileLabels.age(AppStrings.en, const Duration(minutes: 12)),
        '12m',
      );
      expect(ProfileLabels.age(AppStrings.en, const Duration(hours: 4)), '4h');
      expect(
        ProfileLabels.age(AppStrings.en, const Duration(days: 287)),
        '287d',
      );
    });

    test('renders Western digits under Arabic too', () {
      expect(
        ProfileLabels.age(AppStrings.ar, const Duration(minutes: 12)),
        contains('12'),
      );
      expect(
        ProfileLabels.ago(AppStrings.ar, const Duration(minutes: 12)),
        contains('12'),
      );
      expect(
        ProfileLabels.ago(AppStrings.en, const Duration(minutes: 12)),
        '12m ago',
      );
    });

    test('a clock skew into the future does not print a negative age', () {
      expect(
        ProfileLabels.age(AppStrings.en, const Duration(minutes: -5)),
        AppStrings.en.ageInFuture,
      );
    });
  });

  group('ProfileLabels.masked', () {
    test('keeps the last four characters and hides the rest', () {
      expect(ProfileLabels.masked('704218935'), '•••••8935');
      expect(ProfileLabels.masked('704218935').length, 9);
    });

    test('leaves a value that is already short alone', () {
      expect(ProfileLabels.masked('42'), '42');
      expect(ProfileLabels.masked('4218'), '4218');
    });
  });
}
