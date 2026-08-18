import 'package:flutter_test/flutter_test.dart';
import 'package:manager_bot/core/auth/roles.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/features/reconciliation/application/reconciliation_permissions.dart';
import 'package:manager_bot/features/reconciliation/data/break_action_result.dart';
import 'package:manager_bot/features/reconciliation/data/break_view.dart';

void main() {
  group('ReconciliationRoles', () {
    test('SUPPORT may not read reconciliation, unlike the shared capability',
        () {
      expect(ReconciliationRoles.canView(AdminRole.support), isFalse);
      // The shared capability map is wider; that mismatch is exactly why this
      // feature keeps its own set and shows a denied panel.
      expect(
        AdminRoles.can(AdminRole.support, AdminCapability.viewReconciliation),
        isTrue,
      );
    });

    test('the four view roles match the controller decorator', () {
      expect(ReconciliationRoles.canView(AdminRole.superAdmin), isTrue);
      expect(ReconciliationRoles.canView(AdminRole.financeAdmin), isTrue);
      expect(ReconciliationRoles.canView(AdminRole.reviewer), isTrue);
      expect(ReconciliationRoles.canView(AdminRole.viewer), isTrue);
      expect(ReconciliationRoles.canView(null), isFalse);
    });

    test('only finance-grade roles may write', () {
      expect(ReconciliationRoles.canAct(AdminRole.superAdmin), isTrue);
      expect(ReconciliationRoles.canAct(AdminRole.financeAdmin), isTrue);
      expect(ReconciliationRoles.canAct(AdminRole.reviewer), isFalse);
      expect(ReconciliationRoles.canAct(AdminRole.viewer), isFalse);
      expect(ReconciliationRoles.canAct(AdminRole.support), isFalse);
      expect(ReconciliationRoles.canAct(null), isFalse);
    });

    test('agrees with the shared capability for the write side', () {
      for (final AdminRole role in AdminRoles.all) {
        expect(
          ReconciliationRoles.canAct(role),
          AdminRoles.can(role, AdminCapability.resolveReconciliationBreak),
          reason: role.wireName,
        );
      }
    });

    test('describes an allowed set in privilege order', () {
      expect(
        ReconciliationRoles.describe(ReconciliationRoles.actRoles, AppStrings.en),
        'Super admin, Finance admin',
      );
    });

    test('the role names come from the bundle, not from AdminRole.label', () {
      expect(
        ReconciliationRoles.roleLabel(AdminRole.superAdmin, AppStrings.ar),
        AppStrings.ar.roleSuperAdmin,
      );
      expect(
        ReconciliationRoles.describe(
          ReconciliationRoles.actRoles,
          AppStrings.ar,
        ),
        // The Arabic bundle joins an inline list with the ARABIC COMMA, so the
        // separator comes from the catalogue too, not from a Latin literal.
        '${AppStrings.ar.roleSuperAdmin}'
        '${AppStrings.ar.listSeparator}'
        '${AppStrings.ar.roleFinanceAdmin}',
      );
    });
  });

  group('action outcomes', () {
    test('an already-closed answer names the status and asks for a refresh',
        () {
      const BreakActionResult result = BreakActionAlreadyClosed(
        existingStatus: BreakStatus.writtenOff,
      );

      expect(result.shouldRefresh, isTrue);
      expect(result.userMessage(AppStrings.en), contains('Written off'));
      expect(
        result.userMessage(AppStrings.ar),
        contains(AppStrings.ar.breakStatusWrittenOff),
      );
    });

    test('a missing break asks for a refresh too', () {
      const BreakActionResult result = BreakActionMissing();

      expect(result.shouldRefresh, isTrue);
      expect(result.userMessage(AppStrings.en), contains('no longer exists'));
    });

    test('a local guard says why without inventing a sentence', () {
      const BreakActionResult result = BreakActionRejected.wouldReopen(
        BreakStatus.resolved,
      );

      expect(
        result.userMessage(AppStrings.en),
        AppStrings.en.assignWouldReopen(status: 'Resolved'),
      );
      expect(
        const BreakActionRejected.onlyTerminalStatuses()
            .userMessage(AppStrings.ar),
        AppStrings.ar.actionOnlyTerminalStatuses,
      );
    });

    test('the re-entrancy guard is one sentence, not a built-up one', () {
      const BreakActionResult busy = BreakActionRejected.busy();

      expect(
        busy.userMessage(AppStrings.en),
        AppStrings.en.anotherActionRunning,
      );
      expect(
        const CorrectFloatRejected.busy().userMessage(AppStrings.ar),
        AppStrings.ar.anotherActionRunning,
      );
    });

    test('correct-float "already resolved" reads as probably-succeeded', () {
      const CorrectFloatResult result = CorrectFloatAlreadyResolved(
        existingStatus: BreakStatus.resolved,
      );

      expect(result.shouldRefresh, isTrue);
      expect(result.userMessage(AppStrings.en), contains('most likely'));
    });

    test('nothing-to-correct is a plain statement, not an alarm', () {
      const CorrectFloatResult result = CorrectFloatNothingToCorrect();

      expect(
        result.userMessage(AppStrings.en),
        contains('no outstanding difference'),
      );
      expect(
        result.userMessage(AppStrings.ar),
        AppStrings.ar.correctionNothingToCorrect,
      );
    });
  });
}
