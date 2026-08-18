import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manager_bot/features/shell/topup/application/topup_providers.dart';
import 'package:manager_bot/features/shell/topup/data/topup_demo_data.dart';
import 'package:manager_bot/features/shell/topup/data/topup_models.dart';

void main() {
  ProviderContainer makeContainer() {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  group('TopUpController', () {
    test('starts empty on the amount step', () {
      final ProviderContainer container = makeContainer();
      final TopUpDraft draft = container.read(topUpDraftProvider);
      expect(draft.step, TopUpStep.amount);
      expect(draft.amountInput, isEmpty);
      expect(draft.amount, isNull);
      expect(draft.hasProof, isFalse);
    });

    test('stepping back never loses what was entered', () {
      final ProviderContainer container = makeContainer();
      final TopUpController controller =
          container.read(topUpDraftProvider.notifier);

      controller.setAmountInput('50,000');
      controller.advance();
      controller.selectMethod('pm-syriatel-cash');
      controller.selectDestination('ds-syr-aleppo');
      controller.advance();
      controller.back();
      controller.back();

      final TopUpDraft draft = container.read(topUpDraftProvider);
      expect(draft.step, TopUpStep.amount);
      expect(draft.amountInput, '50,000');
      expect(draft.methodId, 'pm-syriatel-cash');
      expect(draft.destinationId, 'ds-syr-aleppo');
      expect(draft.amount?.toMinorString(), '5000000');
    });

    test('changing the method drops the destination it belonged to', () {
      final ProviderContainer container = makeContainer();
      final TopUpController controller =
          container.read(topUpDraftProvider.notifier);

      controller.selectMethod('pm-syriatel-cash');
      controller.selectDestination('ds-syr-damascus');
      controller.selectMethod('pm-haram-office');

      final TopUpDraft draft = container.read(topUpDraftProvider);
      expect(draft.methodId, 'pm-haram-office');
      expect(draft.destinationId, isNull);
    });

    test('the reference and deadline are minted once, not on every pass', () {
      final ProviderContainer container = makeContainer();
      final TopUpController controller =
          container.read(topUpDraftProvider.notifier);

      controller.setAmountInput('25000');
      controller.advance();
      controller.selectMethod('pm-mtn-cash');
      controller.selectDestination('ds-mtn-latakia');
      controller.advance();

      final TopUpDraft first = container.read(topUpDraftProvider);
      expect(first.step, TopUpStep.pay);
      expect(first.reference, isNotNull);
      expect(first.deadline, isNotNull);

      controller.back();
      controller.advance();

      final TopUpDraft second = container.read(topUpDraftProvider);
      expect(second.reference, first.reference);
      expect(second.deadline, first.deadline);
    });

    test('a receipt plus a sender name is what unlocks submission', () {
      final ProviderContainer container = makeContainer();
      final TopUpController controller =
          container.read(topUpDraftProvider.notifier);

      expect(container.read(topUpDraftProvider).hasProof, isFalse);
      controller.attachReceipt('receipt_20260817_1432.jpg');
      expect(container.read(topUpDraftProvider).hasProof, isFalse);
      controller.setSenderName('محمد الحلبي');
      expect(container.read(topUpDraftProvider).hasProof, isTrue);
      controller.removeReceipt();
      expect(container.read(topUpDraftProvider).hasProof, isFalse);
    });

    test('submitting lands on success with a short id', () async {
      final ProviderContainer container = makeContainer();
      final TopUpController controller =
          container.read(topUpDraftProvider.notifier);

      controller.setAmountInput('50000');
      controller.selectMethod('pm-syriatel-cash');
      controller.selectDestination('ds-syr-damascus');
      controller.attachReceipt(TopUpDemoData.newReceiptName());
      controller.setSenderName('رهف العلي');

      await controller.submit();

      final TopUpDraft draft = container.read(topUpDraftProvider);
      expect(draft.step, TopUpStep.success);
      expect(draft.submitting, isFalse);
      expect(draft.submitFailed, isFalse);
      expect(draft.shortId, isNotNull);
      expect(draft.shortId?.startsWith('DP-'), isTrue);
    });

    test('reset clears everything back to step one', () {
      final ProviderContainer container = makeContainer();
      final TopUpController controller =
          container.read(topUpDraftProvider.notifier);

      controller.setAmountInput('100000');
      controller.selectMethod('pm-bemo-bank');
      controller.advance();
      controller.reset();

      expect(container.read(topUpDraftProvider), const TopUpDraft());
    });
  });

  group('selectedTopUpMethodProvider', () {
    test('resolves once the catalogue has arrived', () async {
      final ProviderContainer container = makeContainer();
      container
          .read(topUpDraftProvider.notifier)
          .selectMethod('pm-bemo-bank');

      expect(container.read(selectedTopUpMethodProvider), isNull);
      await container.read(topUpMethodsProvider.future);

      final TopUpMethod? method = container.read(selectedTopUpMethodProvider);
      expect(method, isNotNull);
      expect(method?.rail, TopUpRail.bankTransfer);
      expect(container.read(topUpLimitsProvider), isNotNull);
    });
  });
}
