import 'package:flutter_test/flutter_test.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/theme/app_theme.dart';
import 'package:manager_bot/features/reconciliation/data/break_view.dart';

/// A full `BreakView` as the backend emits it, with the money pair present.
Map<String, Object?> _agentFloatBreak({
  String status = 'OPEN',
  Object? resolvedAt,
  Object? assignedToAdminId,
}) {
  return <String, Object?>{
    'id': '2f3d5a1c-0000-4000-8000-000000000001',
    'category': 'AGENT_FLOAT_MISMATCH',
    'status': status,
    'severity': 4,
    'currencyCode': 'NSP',
    'expected': <String, Object?>{'minor': '150000', 'amount': '1500.00'},
    'actual': <String, Object?>{'minor': '140000', 'amount': '1400.00'},
    'delta': <String, Object?>{'minor': '-10000', 'amount': '-100.00'},
    'depositRequestId': null,
    'playerId': null,
    'ledgerAccountId': '2f3d5a1c-0000-4000-8000-0000000000aa',
    'ichancyCallId': null,
    'detail': <String, Object?>{
      'ledgerMinor': '150000',
      'ichancyAvailableMinor': '140000',
      'ichancyBalanceMinor': '141000',
      'deltaMinor': '-10000',
      'hint': 'Check the last agent top-up.',
    },
    'dedupeKey': 'agent-float:NSP:2026-08-16',
    'detectedAt': '2026-08-16T10:04:11.512Z',
    'assignedToAdminId': assignedToAdminId,
    'resolvedAt': resolvedAt,
    'resolvedByAdminId': null,
    'resolutionNote': null,
    'resolutionTxId': null,
  };
}

void main() {
  group('BreakView.fromJson', () {
    test('parses money as exact minor units, never as a double', () {
      final BreakView view = BreakView.fromJson(_agentFloatBreak());

      expect(view.expected?.minor, BigInt.from(150000));
      expect(view.actual?.minor, BigInt.from(140000));
      expect(view.delta?.minor, BigInt.from(-10000));
      expect(view.delta?.currency, 'NSP');
      expect(view.delta?.toDecimalString(), '-100.00');
      expect(view.hasDrift, isTrue);
    });

    test('keeps 64-bit money that exceeds 2^53 exactly', () {
      final Map<String, Object?> json = _agentFloatBreak();
      json['delta'] = <String, Object?>{
        'minor': '9007199254740993',
        'amount': '90071992547409.93',
      };

      final BreakView view = BreakView.fromJson(json);

      expect(view.delta?.minor, BigInt.parse('9007199254740993'));
      expect(view.delta?.toMinorString(), '9007199254740993');
    });

    test('treats a null money object as absent, not as zero', () {
      final Map<String, Object?> json = _agentFloatBreak();
      json['expected'] = null;
      json['actual'] = null;
      json['delta'] = null;

      final BreakView view = BreakView.fromJson(json);

      expect(view.expected, isNull);
      expect(view.delta, isNull);
      expect(view.hasDrift, isFalse);
      expect(view.canCorrectFloat, isFalse);
    });

    test('falls back to the formatted amount when minor is missing', () {
      final Map<String, Object?> json = _agentFloatBreak();
      json['delta'] = <String, Object?>{'amount': '-12.34'};

      final BreakView view = BreakView.fromJson(json);

      expect(view.delta?.minor, BigInt.from(-1234));
    });

    test('maps unknown enum members to a sentinel and keeps the wire value', () {
      final Map<String, Object?> json = _agentFloatBreak();
      json['status'] = 'SOMETHING_NEW';
      json['category'] = 'ALSO_NEW';

      final BreakView view = BreakView.fromJson(json);

      expect(view.status, BreakStatus.unknown);
      expect(view.statusWire, 'SOMETHING_NEW');
      expect(view.category, BreakCategory.unknown);
      expect(view.categoryWire, 'ALSO_NEW');
    });

    test('clamps severity into 1..5', () {
      final Map<String, Object?> json = _agentFloatBreak();
      json['severity'] = 99;

      expect(BreakView.fromJson(json).severity, 5);
    });

    test('parses detectedAt into local time and keeps the instant', () {
      final BreakView view = BreakView.fromJson(_agentFloatBreak());

      expect(
        view.detectedAt.toUtc().toIso8601String(),
        '2026-08-16T10:04:11.512Z',
      );
    });

    test('reads the detail blob null-safely', () {
      final BreakView view = BreakView.fromJson(_agentFloatBreak());

      expect(view.detail.hint, 'Check the last agent top-up.');
      expect(view.detail.money('ledgerMinor')?.minor, BigInt.from(150000));
      expect(view.detail.string('nope'), isNull);
      expect(view.detail.money('nope'), isNull);
      expect(view.detail.invariant, isNull);
    });

    test('survives a detail blob that is not an object', () {
      final Map<String, Object?> json = _agentFloatBreak();
      json['detail'] = <Object?>['not', 'an', 'object'];

      final BreakView view = BreakView.fromJson(json);

      expect(view.detail.isEmpty, isTrue);
      expect(view.detail.entries(AppStrings.en), isEmpty);
    });

    test('renders detail entries with money formatted and keys localised', () {
      final BreakView view = BreakView.fromJson(_agentFloatBreak());
      final List<BreakDetailEntry> entries =
          view.detail.entries(AppStrings.en);

      final BreakDetailEntry ledger =
          entries.firstWhere((BreakDetailEntry e) => e.key == 'ledgerMinor');
      expect(ledger.isMoney, isTrue);
      expect(ledger.label, 'Ledger');
      // Money keeps Western digits whatever the bundle is.
      expect(ledger.value, contains('1,500.00'));

      final BreakDetailEntry available = entries
          .firstWhere((BreakDetailEntry e) => e.key == 'ichancyAvailableMinor');
      expect(available.label, 'Ichancy available');

      final BreakDetailEntry ledgerAr = view.detail
          .entries(AppStrings.ar)
          .firstWhere((BreakDetailEntry e) => e.key == 'ledgerMinor');
      expect(ledgerAr.label, AppStrings.ar.evidenceLedger);
      expect(ledgerAr.value, contains('1,500.00'));
    });

    test('an unknown detector key falls back to the raw wire key', () {
      expect(
        BreakDetail.labelForKey('somethingNewMinor', AppStrings.en),
        'somethingNewMinor',
      );
      expect(
        BreakDetail.labelForKey('somethingNew', AppStrings.ar),
        'somethingNew',
      );
    });
  });

  group('the I1_SINGLE_SIDED entry-count trap', () {
    test('flags a break whose money pair is really a count of entries', () {
      final Map<String, Object?> json = _agentFloatBreak();
      json['category'] = 'LEDGER_IMBALANCE';
      json['severity'] = 5;
      json['expected'] = <String, Object?>{'minor': '2', 'amount': '0.02'};
      json['actual'] = <String, Object?>{'minor': '1', 'amount': '0.01'};
      json['delta'] = <String, Object?>{'minor': '-1', 'amount': '-0.01'};
      json['detail'] = <String, Object?>{
        'invariant': 'I1_SINGLE_SIDED',
        'subject': '2f3d5a1c-0000-4000-8000-0000000000bb',
        'message': 'Transaction has 1 entry',
        'truncated': false,
      };

      final BreakView view = BreakView.fromJson(json);

      expect(view.amountsAreEntryCounts, isTrue);
      expect(view.expectedCount, BigInt.two);
      expect(view.actualCount, BigInt.one);
      // The amount is still parsed exactly - it is the RENDERING that must not
      // treat it as currency.
      expect(view.expected?.toDecimalString(), '0.02');
    });

    test('leaves a real money break alone', () {
      expect(
        BreakView.fromJson(_agentFloatBreak()).amountsAreEntryCounts,
        isFalse,
      );
    });
  });

  group('transition and gating logic', () {
    test('an open float mismatch with drift can be assigned and corrected', () {
      final BreakView view = BreakView.fromJson(_agentFloatBreak());

      expect(view.canAssign, isTrue);
      expect(view.canResolve, isTrue);
      expect(view.canCorrectFloat, isTrue);
      expect(view.needsAttention, isTrue);
    });

    test('a closed break offers nothing, because assign would re-open it', () {
      for (final String status in <String>[
        'RESOLVED',
        'WRITTEN_OFF',
        'FALSE_POSITIVE',
      ]) {
        final BreakView view = BreakView.fromJson(
          _agentFloatBreak(status: status, resolvedAt: '2026-08-17T09:00:00Z'),
        );

        expect(view.isTerminal, isTrue, reason: status);
        expect(view.canAssign, isFalse, reason: status);
        expect(view.canResolve, isFalse, reason: status);
        expect(view.canCorrectFloat, isFalse, reason: status);
        expect(view.isReopenedAfterClosure, isFalse, reason: status);
      }
    });

    test('a zero delta cannot be corrected on the ledger', () {
      final Map<String, Object?> json = _agentFloatBreak();
      json['delta'] = <String, Object?>{'minor': '0', 'amount': '0.00'};

      final BreakView view = BreakView.fromJson(json);

      expect(view.hasDrift, isFalse);
      expect(view.canCorrectFloat, isFalse);
      expect(view.canResolve, isTrue);
    });

    test('only an agent float mismatch can be corrected on the ledger', () {
      final Map<String, Object?> json = _agentFloatBreak();
      json['category'] = 'UNIDENTIFIED_RECEIPT';

      expect(BreakView.fromJson(json).canCorrectFloat, isFalse);
    });

    test('detects the state assign can produce on a closed break', () {
      final BreakView view = BreakView.fromJson(
        _agentFloatBreak(
          status: 'INVESTIGATING',
          resolvedAt: '2026-08-17T09:00:00Z',
          assignedToAdminId: '2f3d5a1c-0000-4000-8000-0000000000cc',
        ),
      );

      expect(view.isReopenedAfterClosure, isTrue);
      expect(view.isAssigned, isTrue);
    });
  });

  group('BreakStatus', () {
    test('exposes exactly the three terminal outcomes resolve accepts', () {
      expect(
        BreakStatus.terminal,
        <BreakStatus>[
          BreakStatus.resolved,
          BreakStatus.writtenOff,
          BreakStatus.falsePositive,
        ],
      );
      for (final BreakStatus status in BreakStatus.terminal) {
        expect(status.isTerminal, isTrue);
      }
      expect(BreakStatus.open.isTerminal, isFalse);
      expect(BreakStatus.investigating.isTerminal, isFalse);
    });

    test('mirrors the server default filter', () {
      expect(
        BreakStatus.serverDefaultFilter,
        <BreakStatus>{BreakStatus.open, BreakStatus.investigating},
      );
    });

    test('parses case-insensitively and rejects nonsense', () {
      expect(BreakStatus.tryParse('written_off'), BreakStatus.writtenOff);
      expect(BreakStatus.tryParse(' RESOLVED '), BreakStatus.resolved);
      expect(BreakStatus.tryParse('NOPE'), isNull);
      expect(BreakStatus.tryParse(null), isNull);
    });

    test('colours terminal success and refusal differently', () {
      expect(BreakStatus.resolved.tone, StatusTone.approve);
      expect(BreakStatus.writtenOff.tone, StatusTone.reject);
      expect(BreakStatus.open.tone, StatusTone.failed);
    });
  });

  group('BreakCategory', () {
    test('knows which categories a detector actually writes', () {
      final List<BreakCategory> produced = BreakCategory.values
          .where((BreakCategory category) => category.hasDetector)
          .toList();

      expect(
        produced,
        <BreakCategory>[
          BreakCategory.agentFloatMismatch,
          BreakCategory.unidentifiedReceipt,
          BreakCategory.ledgerImbalance,
        ],
      );
    });

    test('only the float mismatch supports a ledger correction', () {
      for (final BreakCategory category in BreakCategory.values) {
        expect(
          category.supportsFloatCorrection,
          category == BreakCategory.agentFloatMismatch,
          reason: category.wireName,
        );
      }
    });
  });

  group('BreakSeverity', () {
    test('clamps out-of-range values', () {
      expect(BreakSeverity.clamp(0), 1);
      expect(BreakSeverity.clamp(3), 3);
      expect(BreakSeverity.clamp(9), 5);
    });

    test('escalates tone with severity', () {
      expect(BreakSeverity.tone(1), StatusTone.neutral);
      expect(BreakSeverity.tone(5), StatusTone.reject);
    });

    test('labels come from the bundle, and the short chip stays Latin', () {
      expect(BreakSeverity.label(5, AppStrings.en), AppStrings.en.severity5);
      expect(BreakSeverity.label(5, AppStrings.ar), AppStrings.ar.severity5);
      expect(BreakSeverity.label(9, AppStrings.en), AppStrings.en.severity5);
      expect(BreakSeverity.shortLabel(4, AppStrings.en), 'S4');
      expect(BreakSeverity.shortLabel(9, AppStrings.ar), 'S5');
    });
  });

  group('enum labels', () {
    test('every status and category resolves in both bundles', () {
      for (final BreakStatus status in BreakStatus.values) {
        expect(status.label(AppStrings.en), isNotEmpty, reason: status.wireName);
        expect(status.label(AppStrings.ar), isNotEmpty, reason: status.wireName);
        expect(
          status.closingMeaning(AppStrings.ar),
          isNotEmpty,
          reason: status.wireName,
        );
      }
      for (final BreakCategory category in BreakCategory.values) {
        expect(
          category.label(AppStrings.en),
          isNotEmpty,
          reason: category.wireName,
        );
        expect(
          category.label(AppStrings.ar),
          isNotEmpty,
          reason: category.wireName,
        );
      }
    });
  });
}
