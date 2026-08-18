/// State for the guided top-up flow.
///
/// The whole draft lives in ONE notifier, deliberately: stepping backwards must
/// never lose what the player already typed, so no step keeps the truth in its
/// own `State`. A `TextEditingController` inside a step is only ever a mirror
/// of [TopUpDraft.amountInput] / [TopUpDraft.senderName].
library;

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/money/money.dart';
import 'package:manager_bot/features/shell/topup/data/topup_demo_data.dart';
import 'package:manager_bot/features/shell/topup/data/topup_models.dart';

/// The five stops of the flow, in order.
enum TopUpStep {
  /// How much.
  amount,

  /// Which rail, then which account.
  method,

  /// The account details, the reference and the countdown.
  pay,

  /// The receipt photo and the sender name.
  receipt,

  /// Filed. Short id and what happens next.
  success,
}

/// Everything the player has entered so far.
@immutable
class TopUpDraft {
  const TopUpDraft({
    this.step = TopUpStep.amount,
    this.amountInput = '',
    this.methodId,
    this.destinationId,
    this.reference,
    this.deadline,
    this.receiptName,
    this.senderName = '',
    this.shortId,
    this.submitting = false,
    this.submitFailed = false,
  });

  /// Which step is on screen.
  final TopUpStep step;

  /// Raw text exactly as typed. Parsed on demand, never stored as a number.
  final String amountInput;

  final String? methodId;
  final String? destinationId;

  /// Minted once, when the pay step is first reached.
  final String? reference;

  /// Local time the transfer window closes. Minted with [reference].
  final DateTime? deadline;

  /// File name of the attached receipt. Null means nothing attached yet.
  final String? receiptName;

  /// Name on the sending account, as the player typed it.
  final String senderName;

  /// Short id the backend answered with. Only set on [TopUpStep.success].
  final String? shortId;

  final bool submitting;
  final bool submitFailed;

  /// The typed amount, or null when it is not a valid NSP figure yet.
  Money? get amount => Money.tryParseUserInput(amountInput);

  /// True when a receipt and a sender name are both present.
  bool get hasProof => receiptName != null && senderName.trim().isNotEmpty;

  TopUpDraft copyWith({
    TopUpStep? step,
    String? amountInput,
    String? methodId,
    String? destinationId,
    String? reference,
    DateTime? deadline,
    String? receiptName,
    String? senderName,
    String? shortId,
    bool? submitting,
    bool? submitFailed,
    bool clearMethod = false,
    bool clearDestination = false,
    bool clearReceipt = false,
  }) =>
      TopUpDraft(
        step: step ?? this.step,
        amountInput: amountInput ?? this.amountInput,
        methodId: clearMethod ? null : (methodId ?? this.methodId),
        destinationId: clearMethod || clearDestination
            ? null
            : (destinationId ?? this.destinationId),
        reference: reference ?? this.reference,
        deadline: deadline ?? this.deadline,
        receiptName: clearReceipt ? null : (receiptName ?? this.receiptName),
        senderName: senderName ?? this.senderName,
        shortId: shortId ?? this.shortId,
        submitting: submitting ?? this.submitting,
        submitFailed: submitFailed ?? this.submitFailed,
      );

  @override
  bool operator ==(Object other) =>
      other is TopUpDraft &&
      other.step == step &&
      other.amountInput == amountInput &&
      other.methodId == methodId &&
      other.destinationId == destinationId &&
      other.reference == reference &&
      other.deadline == deadline &&
      other.receiptName == receiptName &&
      other.senderName == senderName &&
      other.shortId == shortId &&
      other.submitting == submitting &&
      other.submitFailed == submitFailed;

  @override
  int get hashCode => Object.hash(
        step,
        amountInput,
        methodId,
        destinationId,
        reference,
        deadline,
        receiptName,
        senderName,
        shortId,
        submitting,
        submitFailed,
      );

  @override
  String toString() =>
      'TopUpDraft(step: $step, amount: "$amountInput", method: $methodId, '
      'destination: $destinationId, receipt: $receiptName)';
}

/// Drives [TopUpDraft]. Every mutation is a whole-state replacement, so a
/// rebuild can never see a half-applied step change.
class TopUpController extends Notifier<TopUpDraft> {
  bool _disposed = false;

  @override
  TopUpDraft build() {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
    });
    return const TopUpDraft();
  }

  /// Records the raw text of the amount field.
  void setAmountInput(String value) {
    if (value != state.amountInput) {
      state = state.copyWith(amountInput: value);
    }
  }

  /// Picks a method. Changing it drops the destination, because a destination
  /// only ever belongs to one method.
  void selectMethod(String methodId) {
    if (methodId == state.methodId) {
      return;
    }
    state = state.copyWith(methodId: methodId, clearDestination: true);
  }

  void selectDestination(String destinationId) {
    if (destinationId != state.destinationId) {
      state = state.copyWith(destinationId: destinationId);
    }
  }

  void setSenderName(String value) {
    if (value != state.senderName) {
      state = state.copyWith(senderName: value);
    }
  }

  /// Attaches the picked receipt. Today the picker is a placeholder, so the
  /// name comes from the demo source; wiring a real picker changes only the
  /// caller.
  void attachReceipt(String fileName) {
    state = state.copyWith(receiptName: fileName, submitFailed: false);
  }

  void removeReceipt() {
    state = state.copyWith(clearReceipt: true);
  }

  /// Moves one step forward. Entering [TopUpStep.pay] mints the reference and
  /// the deadline ONCE, so going back and forward does not restart the clock.
  void advance() {
    final TopUpDraft current = state;
    if (current.step == TopUpStep.amount) {
      state = current.copyWith(step: TopUpStep.method);
      return;
    }
    if (current.step == TopUpStep.method) {
      state = current.copyWith(
        step: TopUpStep.pay,
        reference: current.reference ?? TopUpDemoData.newReference(),
        deadline:
            current.deadline ?? DateTime.now().add(TopUpDemoData.payWindow),
      );
      return;
    }
    if (current.step == TopUpStep.pay) {
      state = current.copyWith(step: TopUpStep.receipt);
    }
  }

  /// Moves one step back. Nothing entered is discarded.
  void back() {
    final TopUpStep current = state.step;
    if (current == TopUpStep.method) {
      state = state.copyWith(step: TopUpStep.amount);
      return;
    }
    if (current == TopUpStep.pay) {
      state = state.copyWith(step: TopUpStep.method);
      return;
    }
    if (current == TopUpStep.receipt) {
      state = state.copyWith(step: TopUpStep.pay);
    }
  }

  /// Files the request and lands on [TopUpStep.success].
  Future<void> submit() async {
    if (state.submitting) {
      return;
    }
    state = state.copyWith(submitting: true, submitFailed: false);
    try {
      final String shortId = await TopUpDemoData.submitTopUp();
      if (_disposed) {
        return;
      }
      state = state.copyWith(
        step: TopUpStep.success,
        shortId: shortId,
        submitting: false,
      );
    } on Object {
      if (_disposed) {
        return;
      }
      state = state.copyWith(submitting: false, submitFailed: true);
    }
  }

  /// Back to an empty draft on the first step - "another top-up".
  void reset() {
    state = const TopUpDraft();
  }
}

/// The draft. Watched by every step.
final NotifierProvider<TopUpController, TopUpDraft> topUpDraftProvider =
    NotifierProvider<TopUpController, TopUpDraft>(TopUpController.new);

/// The payment-method catalogue. One demo source today, one repository later.
final FutureProvider<List<TopUpMethod>> topUpMethodsProvider =
    FutureProvider<List<TopUpMethod>>((ref) => TopUpDemoData.loadMethods());

/// The method the draft points at, or null while nothing is chosen or the
/// catalogue has not arrived.
final Provider<TopUpMethod?> selectedTopUpMethodProvider =
    Provider<TopUpMethod?>((ref) {
  final String? methodId = ref.watch(topUpDraftProvider).methodId;
  if (methodId == null) {
    return null;
  }
  final List<TopUpMethod> methods =
      ref.watch(topUpMethodsProvider).valueOrNull ?? const <TopUpMethod>[];
  for (final TopUpMethod method in methods) {
    if (method.id == methodId) {
      return method;
    }
  }
  return null;
});

/// The union amount window across the catalogue, or null while it loads.
final Provider<TopUpLimits?> topUpLimitsProvider = Provider<TopUpLimits?>((ref) {
  final List<TopUpMethod>? methods =
      ref.watch(topUpMethodsProvider).valueOrNull;
  if (methods == null) {
    return null;
  }
  return TopUpLimits.across(methods);
});
