import 'package:flutter/material.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/theme/app_theme.dart';
import 'package:manager_bot/features/payment_methods/application/payment_method_actions.dart';

/// Shows the outcome of a write as a snackbar.
///
/// A failure keeps the diagnostics visible: the message is already the server's
/// own wording, and the stable code plus the correlation id are printed under
/// it so an operator can quote them to support without leaving the screen.
void showMutationResult<T>(BuildContext context, MutationResult<T> result) {
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  final SnackBar snackBar = switch (result) {
    final MutationSuccess<T> success =>
      SnackBar(content: Text(success.message)),
    final MutationFailure<T> failure => _failureSnackBar(context, failure),
  };
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(snackBar);
}

SnackBar _failureSnackBar<T>(BuildContext context, MutationFailure<T> failure) {
  final AppSemanticColors semantics = AppSemanticColors.of(context);
  final String? correlationId = failure.error.correlationId;
  // The code and the correlation id are IDENTIFIERS: never translated, never
  // reordered, so an operator can quote them verbatim to support.
  final String reference = correlationId == null || correlationId.isEmpty
      ? failure.error.code
      : context.s.pmFailureReference(
          code: failure.error.code,
          correlationId: correlationId,
        );
  // "The row moved under us" is a NORMAL outcome in a console two people share:
  // a 409 or a 404 means somebody else changed the same method, and the
  // controller has already invalidated the caches, so it is styled as
  // information rather than as a red failure - the same call the deposit
  // surface makes for DepositActionAlreadyHandled.
  final SemanticTone tone =
      failure.shouldRefresh ? semantics.pending : semantics.reject;
  return SnackBar(
    duration: const Duration(seconds: 6),
    backgroundColor: tone.background,
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // The foreground is taken from the same tone as the background, so the
        // text stays legible now that the background is not always the red one.
        Text(failure.message, style: TextStyle(color: tone.foreground)),
        const SizedBox(height: 4),
        Text(
          reference,
          style: AppTheme.monoStyle(context).copyWith(color: tone.foreground),
        ),
      ],
    ),
  );
}
