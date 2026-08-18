import 'package:flutter_test/flutter_test.dart';
import 'package:manager_bot/core/auth/roles.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/features/deposits/data/deposit_action_policy.dart';
import 'package:manager_bot/features/deposits/data/deposit_enums.dart';

/// Labels and block reasons come from the catalogue; the English bundle keeps
/// these expectations readable.
const AppStrings _en = AppStrings.en;

/// The legal-action matrix, straight from the backend's ALLOWED_TRANSITIONS
/// plus each service's `from` set. If the backend changes, this table is the
/// first thing that must change with it.
const Map<DepositStatus, Set<DepositAction>> _expected =
    <DepositStatus, Set<DepositAction>>{
  DepositStatus.draft: <DepositAction>{},
  DepositStatus.awaitingProof: <DepositAction>{},
  DepositStatus.submitted: <DepositAction>{
    DepositAction.claim,
    DepositAction.approve,
    DepositAction.reject,
  },
  DepositStatus.underReview: <DepositAction>{
    DepositAction.claim,
    DepositAction.release,
    DepositAction.approve,
    DepositAction.reject,
  },
  DepositStatus.pendingSecondApproval: <DepositAction>{
    DepositAction.approve,
    DepositAction.reject,
  },
  DepositStatus.approved: <DepositAction>{},
  DepositStatus.crediting: <DepositAction>{},
  DepositStatus.credited: <DepositAction>{},
  DepositStatus.creditFailed: <DepositAction>{DepositAction.retryCredit},
  DepositStatus.needsReconciliation: <DepositAction>{
    DepositAction.retryCredit,
  },
  DepositStatus.rejected: <DepositAction>{},
  DepositStatus.expired: <DepositAction>{},
  DepositStatus.reversed: <DepositAction>{},
};

const String _me = 'admin-me';
const String _other = 'admin-other';

void main() {
  group('DepositStatus', () {
    test('covers all 13 wire values with exact spelling', () {
      expect(DepositStatus.values, hasLength(13));
      expect(
        DepositStatus.values.map((DepositStatus s) => s.wireName).toSet(),
        <String>{
          'DRAFT',
          'AWAITING_PROOF',
          'SUBMITTED',
          'UNDER_REVIEW',
          'PENDING_SECOND_APPROVAL',
          'APPROVED',
          'CREDITING',
          'CREDITED',
          'CREDIT_FAILED',
          'NEEDS_RECONCILIATION',
          'REJECTED',
          'EXPIRED',
          'REVERSED',
        },
      );
    });

    test('tryParse is case- and whitespace-tolerant, null for unknown', () {
      expect(DepositStatus.tryParse(' under_review '), DepositStatus.underReview);
      expect(DepositStatus.tryParse('CREDIT_FAILED'), DepositStatus.creditFailed);
      expect(DepositStatus.tryParse('NOT_A_STATUS'), isNull);
      expect(DepositStatus.tryParse(null), isNull);
    });

    test('reviewable and terminal sets match the backend constants', () {
      expect(DepositStatus.reviewable, <DepositStatus>{
        DepositStatus.submitted,
        DepositStatus.underReview,
        DepositStatus.pendingSecondApproval,
      });
      expect(DepositStatus.terminal, <DepositStatus>{
        DepositStatus.rejected,
        DepositStatus.expired,
        DepositStatus.reversed,
        DepositStatus.credited,
      });
    });
  });

  group('RejectionCode', () {
    test('covers all 12 wire values', () {
      expect(RejectionCode.values, hasLength(12));
      expect(
        RejectionCode.tryParse('suspected_fraud'),
        RejectionCode.suspectedFraud,
      );
    });

    test('labelFor degrades gracefully for an unknown code', () {
      expect(RejectionCode.labelFor('AMOUNT_MISMATCH', _en), 'Amount mismatch');
      expect(
        RejectionCode.labelFor('AMOUNT_MISMATCH', AppStrings.ar),
        AppStrings.ar.rejectionAmountMismatch,
      );
      // An unknown code keeps its RAW wire value rather than being dressed up
      // as a translated sentence.
      expect(RejectionCode.labelFor('BRAND_NEW_CODE', _en), 'BRAND_NEW_CODE');
      expect(RejectionCode.labelFor(null, _en), _en.emptyValueDash);
    });

    test('every code has a label in both bundles', () {
      for (final RejectionCode code in RejectionCode.values) {
        expect(code.label(_en), isNotEmpty, reason: code.wireName);
        expect(code.label(AppStrings.ar), isNotEmpty, reason: code.wireName);
      }
    });
  });

  group('DepositActionPolicy.legalActionsFor', () {
    test('matches the backend transition matrix for every status', () {
      for (final DepositStatus status in DepositStatus.values) {
        expect(
          DepositActionPolicy.legalActionsFor(status).toSet(),
          _expected[status],
          reason: 'wrong action set for ${status.wireName}',
        );
      }
    });

    test('no action is ever legal from a terminal status', () {
      for (final DepositStatus status in DepositStatus.terminal) {
        expect(DepositActionPolicy.legalActionsFor(status), isEmpty);
      }
    });

    test('release is legal only from UNDER_REVIEW', () {
      for (final DepositStatus status in DepositStatus.values) {
        expect(
          DepositActionPolicy.isLegalFrom(DepositAction.release, status),
          status == DepositStatus.underReview,
          reason: status.wireName,
        );
      }
    });

    test('claim is not legal from PENDING_SECOND_APPROVAL', () {
      expect(
        DepositActionPolicy.isLegalFrom(
          DepositAction.claim,
          DepositStatus.pendingSecondApproval,
        ),
        isFalse,
      );
    });
  });

  group('DepositActionPolicy.capabilityFor', () {
    test('the four review actions need reviewDeposit', () {
      for (final DepositAction action in <DepositAction>[
        DepositAction.claim,
        DepositAction.release,
        DepositAction.approve,
        DepositAction.reject,
      ]) {
        expect(
          DepositActionPolicy.capabilityFor(action),
          AdminCapability.reviewDeposit,
        );
      }
    });

    test('retry-credit needs retryCredit, which excludes REVIEWER', () {
      expect(
        DepositActionPolicy.capabilityFor(DepositAction.retryCredit),
        AdminCapability.retryCredit,
      );
      expect(
        AdminRoles.can(AdminRole.reviewer, AdminCapability.retryCredit),
        isFalse,
      );
      expect(
        AdminRoles.can(AdminRole.financeAdmin, AdminCapability.retryCredit),
        isTrue,
      );
    });
  });

  group('DepositActionPolicy.claim TTL', () {
    final DateTime now = DateTime(2026, 8, 16, 12);

    test('a claim younger than 10 minutes is fresh', () {
      expect(
        DepositActionPolicy.claimIsFresh(
          now.subtract(const Duration(minutes: 9, seconds: 59)),
          now,
        ),
        isTrue,
      );
    });

    test('a claim at or past 10 minutes is stealable', () {
      expect(
        DepositActionPolicy.claimIsFresh(
          now.subtract(const Duration(minutes: 10)),
          now,
        ),
        isFalse,
      );
      expect(DepositActionPolicy.claimIsFresh(null, now), isFalse);
    });

    test('minutes remaining never rounds down to zero while fresh', () {
      expect(
        DepositActionPolicy.claimMinutesRemaining(
          now.subtract(const Duration(minutes: 9, seconds: 30)),
          now,
        ),
        1,
      );
      expect(
        DepositActionPolicy.claimMinutesRemaining(
          now.subtract(const Duration(minutes: 2)),
          now,
        ),
        8,
      );
      expect(
        DepositActionPolicy.claimMinutesRemaining(
          now.subtract(const Duration(minutes: 30)),
          now,
        ),
        isNull,
      );
    });
  });

  group('DepositActionPolicy.resolve', () {
    final DateTime now = DateTime(2026, 8, 16, 12);

    List<DepositActionOption> resolve({
      required DepositStatus status,
      required AdminRole? role,
      String? decidedByAdminId,
      DateTime? reviewStartedAt,
    }) =>
        DepositActionPolicy.resolve(
          status: status,
          role: role,
          now: now,
          strings: _en,
          currentAdminUserId: _me,
          decidedByAdminId: decidedByAdminId,
          reviewStartedAt: reviewStartedAt,
        );

    test('a reviewer on an unclaimed SUBMITTED row gets everything enabled', () {
      final List<DepositActionOption> options = resolve(
        status: DepositStatus.submitted,
        role: AdminRole.reviewer,
      );

      expect(options.map((DepositActionOption o) => o.action), <DepositAction>[
        DepositAction.claim,
        DepositAction.approve,
        DepositAction.reject,
      ]);
      expect(options.every((DepositActionOption o) => o.enabled), isTrue);
    });

    test('a VIEWER sees the legal actions but cannot fire them', () {
      final List<DepositActionOption> options = resolve(
        status: DepositStatus.submitted,
        role: AdminRole.viewer,
      );

      expect(options, hasLength(3));
      expect(options.every((DepositActionOption o) => o.enabled), isFalse);
      expect(
        options.every(
          (DepositActionOption o) => o.block == DepositActionBlock.role,
        ),
        isTrue,
      );
      expect(options.first.blockReason, isNotNull);
    });

    test('a REVIEWER cannot retry a credit but a FINANCE_ADMIN can', () {
      final List<DepositActionOption> reviewerOptions = resolve(
        status: DepositStatus.creditFailed,
        role: AdminRole.reviewer,
      );
      expect(reviewerOptions, hasLength(1));
      expect(reviewerOptions.single.enabled, isFalse);
      expect(reviewerOptions.single.block, DepositActionBlock.role);

      final List<DepositActionOption> financeOptions = resolve(
        status: DepositStatus.creditFailed,
        role: AdminRole.financeAdmin,
      );
      expect(financeOptions.single.enabled, isTrue);
    });

    test('claiming is blocked while another admin holds a FRESH claim', () {
      final List<DepositActionOption> options = resolve(
        status: DepositStatus.underReview,
        role: AdminRole.reviewer,
        decidedByAdminId: _other,
        reviewStartedAt: now.subtract(const Duration(minutes: 3)),
      );

      final DepositActionOption claim = options.firstWhere(
        (DepositActionOption o) => o.action == DepositAction.claim,
      );
      expect(claim.enabled, isFalse);
      expect(claim.block, DepositActionBlock.claimedByOther);
      // One whole catalogue sentence now, not English built by concatenation.
      expect(claim.blockReason, _en.blockClaimedByOther(minutes: 7));

      // The claim is advisory - approve and reject stay available.
      expect(
        options
            .firstWhere((DepositActionOption o) => o.action == DepositAction.approve)
            .enabled,
        isTrue,
      );
      expect(
        options
            .firstWhere((DepositActionOption o) => o.action == DepositAction.reject)
            .enabled,
        isTrue,
      );
    });

    test('a STALE claim held by another admin can be taken over', () {
      final List<DepositActionOption> options = resolve(
        status: DepositStatus.underReview,
        role: AdminRole.reviewer,
        decidedByAdminId: _other,
        reviewStartedAt: now.subtract(const Duration(minutes: 15)),
      );

      expect(
        options
            .firstWhere((DepositActionOption o) => o.action == DepositAction.claim)
            .enabled,
        isTrue,
      );
    });

    test('re-claiming my own fresh claim is allowed', () {
      final List<DepositActionOption> options = resolve(
        status: DepositStatus.underReview,
        role: AdminRole.reviewer,
        decidedByAdminId: _me,
        reviewStartedAt: now.subtract(const Duration(minutes: 2)),
      );

      expect(
        options
            .firstWhere((DepositActionOption o) => o.action == DepositAction.claim)
            .enabled,
        isTrue,
      );
    });

    test('release is offered only to the admin holding the claim', () {
      final DepositActionOption mine = resolve(
        status: DepositStatus.underReview,
        role: AdminRole.reviewer,
        decidedByAdminId: _me,
        reviewStartedAt: now.subtract(const Duration(minutes: 2)),
      ).firstWhere((DepositActionOption o) => o.action == DepositAction.release);
      expect(mine.enabled, isTrue);

      final DepositActionOption theirs = resolve(
        status: DepositStatus.underReview,
        role: AdminRole.reviewer,
        decidedByAdminId: _other,
        reviewStartedAt: now.subtract(const Duration(minutes: 2)),
      ).firstWhere((DepositActionOption o) => o.action == DepositAction.release);
      expect(theirs.enabled, isFalse);
      expect(theirs.block, DepositActionBlock.notClaimHolder);
    });

    test('a terminal deposit offers nothing at all, whatever the role', () {
      for (final DepositStatus status in DepositStatus.terminal) {
        expect(
          resolve(status: status, role: AdminRole.superAdmin),
          isEmpty,
          reason: status.wireName,
        );
      }
    });

    test('a null role (signed out) can fire nothing', () {
      final List<DepositActionOption> options = resolve(
        status: DepositStatus.submitted,
        role: null,
      );
      expect(options.every((DepositActionOption o) => o.enabled), isFalse);
    });
  });

  group('DepositAction metadata', () {
    test('the money-moving actions are marked destructive', () {
      expect(DepositAction.approve.isDestructive, isTrue);
      expect(DepositAction.reject.isDestructive, isTrue);
      expect(DepositAction.retryCredit.isDestructive, isTrue);
      expect(DepositAction.claim.isDestructive, isFalse);
      expect(DepositAction.release.isDestructive, isFalse);
    });
  });

  group('RiskFlags', () {
    test('sorts by declared severity and keeps unknown flags last', () {
      expect(
        RiskFlags.sorted(<String>['NEW_PLAYER', 'REFERENCE_REUSED', 'ZZZ']),
        <String>['REFERENCE_REUSED', 'NEW_PLAYER', 'ZZZ'],
      );
      expect(RiskFlags.sorted(const <String>[]), isEmpty);
    });

    test('labels every known flag and falls back to the raw wire code', () {
      for (final String flag in RiskFlags.severityOrder) {
        expect(RiskFlags.label(flag, _en), isNotEmpty, reason: flag);
        expect(RiskFlags.label(flag, AppStrings.ar), isNotEmpty, reason: flag);
        // A translated flag never leaks the SCREAMING_SNAKE wire value.
        expect(RiskFlags.label(flag, _en), isNot(flag), reason: flag);
      }
      expect(RiskFlags.label('WHO_KNOWS', _en), 'WHO_KNOWS');
    });

    test('ranks an unknown flag last without throwing', () {
      expect(RiskFlags.rankOf('DUPLICATE_PROOF_EXACT'), 0);
      expect(
        RiskFlags.rankOf('WHO_KNOWS'),
        RiskFlags.severityOrder.length,
      );
    });
  });
}
