/// Domain `error.code` values the reconciliation routes can return.
///
/// `error.code` stays an OPEN string app-wide: these are constants to compare
/// against, never a closed enum. They live beside the shared
/// `ApiErrorCodes` rather than inside it because they belong to one module.
abstract final class ReconciliationErrorCodes {
  /// 404 from `POST /breaks/:id/resolve` only. `GET /breaks/:id` and
  /// `POST /breaks/:id/assign` answer the GENERIC `RESOURCE_NOT_FOUND` for the
  /// very same condition, so "not found" can never be keyed on this code alone.
  static const String breakNotFound = 'BREAK_NOT_FOUND';

  /// 422. The break is already RESOLVED / WRITTEN_OFF / FALSE_POSITIVE.
  /// `details.status` carries the existing terminal status.
  ///
  /// After a `correct-float` that timed out, this code means the correction
  /// PROBABLY SUCCEEDED (the ledger posting is idempotent, the follow-up
  /// resolve is not). Re-fetch the break instead of retrying.
  static const String breakAlreadyResolved = 'BREAK_ALREADY_RESOLVED';

  /// 422 from `correct-float`. The break's delta is null or zero.
  static const String nothingToCorrect = 'NOTHING_TO_CORRECT';

  /// Two very different meanings, distinguished by HTTP status:
  /// * 400 from `resolve` - the status sent was OPEN or INVESTIGATING.
  ///   `details.status` echoes it. This is the one place a domain code rides a
  ///   400 instead of `VALIDATION_FAILED`.
  /// * 422 from `correct-float` - the break does not exist OR is not an
  ///   `AGENT_FLOAT_MISMATCH`. A missing break here is 422, not 404.
  static const String correctionNotAllowed = 'CORRECTION_NOT_ALLOWED';

  /// Declared by the module but never thrown by these endpoints: an unreachable
  /// Ichancy wallet is a 200 with null fields, not an error.
  static const String agentWalletUnavailable = 'AGENT_WALLET_UNAVAILABLE';
}
