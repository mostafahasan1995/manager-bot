import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/api/json.dart';
import 'package:manager_bot/core/errors/api_error.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/money/money.dart';
import 'package:manager_bot/core/theme/app_theme.dart';

/// Renders an [AsyncValue] as loading / error / empty / data, with a retry.
///
/// This is THE way a feature screen renders a provider. It keeps the error
/// presentation (code, correlation id, retryability) identical everywhere,
/// which matters because an admin quoting the wrong id wastes a support cycle.
///
/// ```dart
/// AsyncValueView<CursorPage<AdminDepositView>>(
///   value: ref.watch(depositQueueProvider),
///   onRetry: () => ref.invalidate(depositQueueProvider),
///   isEmpty: (page) => page.isEmpty,
///   emptyTitle: context.s.queueEmptyTitle,
///   emptyMessage: context.s.queueEmptyMessage,
///   builder: (context, page) => ListView(...),
/// )
/// ```
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    required this.value,
    required this.builder,
    this.onRetry,
    this.isEmpty,
    this.emptyTitle,
    this.emptyMessage,
    this.emptyIcon = Icons.inbox_outlined,
    this.emptyAction,
    this.loadingLabel,
    this.skipLoadingOnRefresh = true,
    super.key,
  });

  final AsyncValue<T> value;

  /// Builds the success state.
  final Widget Function(BuildContext context, T data) builder;

  /// Retries the underlying provider. Usually `() => ref.invalidate(p)`.
  final VoidCallback? onRetry;

  /// Returns true when [T] holds no rows, so the empty state shows instead of
  /// an empty list.
  final bool Function(T data)? isEmpty;

  /// Defaults to [AppStrings.emptyDefaultTitle] when null.
  final String? emptyTitle;

  final String? emptyMessage;
  final IconData emptyIcon;
  final Widget? emptyAction;

  /// Optional caption under the spinner (e.g. [AppStrings.loadingQueue]).
  final String? loadingLabel;

  /// Keep showing the previous data while a refresh is in flight.
  final bool skipLoadingOnRefresh;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    return value.when(
      skipLoadingOnRefresh: skipLoadingOnRefresh,
      loading: () => LoadingStateView(label: loadingLabel),
      error: (Object error, StackTrace stackTrace) =>
          ErrorStateView(error: error, onRetry: onRetry),
      data: (T data) {
        if (isEmpty?.call(data) ?? false) {
          return EmptyStateView(
            title: emptyTitle ?? s.emptyDefaultTitle,
            message: emptyMessage,
            icon: emptyIcon,
            action: emptyAction ??
                (onRetry == null
                    ? null
                    : OutlinedButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh),
                        label: Text(s.refresh),
                      )),
          );
        }
        return builder(context, data);
      },
    );
  }
}

/// Centered spinner with an optional caption.
class LoadingStateView extends StatelessWidget {
  const LoadingStateView({this.label, super.key});

  /// Caption under the spinner. Null shows the spinner alone; pass
  /// [AppStrings.loading] for the generic wording.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final caption = label;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          if (caption != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(caption, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

/// Neutral empty state. Not an error - an empty review queue is good news.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
    super.key,
  });

  final String title;
  final String? message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = message;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 40, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            if (body != null) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                body,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (action != null) ...<Widget>[
              const SizedBox(height: 18),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Error state that shows the stable code and the correlation id, and only
/// offers "Try again" when retrying can actually help.
class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    required this.error,
    this.onRetry,
    this.compact = false,
    super.key,
  });

  final Object error;
  final VoidCallback? onRetry;

  /// Inline variant for a card or a sheet rather than a full page.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final AppStrings s = context.s;
    final semantics = AppSemanticColors.of(context);
    final presentation = ErrorPresentation.of(error, s);
    final tone = presentation.isConflict ? semantics.pending : semantics.reject;
    final correlationId = presentation.correlationId;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          compact ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: <Widget>[
        Icon(
          presentation.isConflict
              ? Icons.info_outline
              : Icons.error_outline_rounded,
          color: tone.foreground,
          size: compact ? 22 : 38,
        ),
        SizedBox(height: compact ? 8 : 14),
        Text(
          presentation.title,
          textAlign: compact ? TextAlign.start : TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(color: tone.foreground),
        ),
        const SizedBox(height: 6),
        Text(
          presentation.message,
          textAlign: compact ? TextAlign.start : TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (correlationId != null && correlationId.isNotEmpty) ...<Widget>[
          const SizedBox(height: 10),
          _CorrelationIdChip(correlationId: correlationId, code: presentation.code),
        ],
        if (onRetry != null && presentation.canRetry) ...<Widget>[
          SizedBox(height: compact ? 12 : 18),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(s.tryAgain),
          ),
        ],
      ],
    );

    if (compact) {
      return Padding(padding: const EdgeInsets.all(16), child: content);
    }
    return Center(
      child: Padding(padding: const EdgeInsets.all(32), child: content),
    );
  }
}

class _CorrelationIdChip extends StatelessWidget {
  const _CorrelationIdChip({required this.correlationId, required this.code});

  final String correlationId;
  final String code;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final AppStrings s = context.s;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: '$code $correlationId'));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s.referenceCopied)),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.copy_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                s.correlationChip(code: code, correlationId: correlationId),
                overflow: TextOverflow.ellipsis,
                style: AppTheme.monoStyle(context),
                // A correlation id is Latin/ASCII: never mirror it into the
                // surrounding RTL run.
                textDirection: TextDirection.ltr,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Everything the UI needs to know about a thrown object, in one place.
///
/// Handles [ApiError], [JsonParseException], [MoneyFormatException],
/// [AuthUnsupportedError] and any stray object, so a feature never has to
/// `if (e is ...)` chain by hand.
class ErrorPresentation {
  const ErrorPresentation({
    required this.title,
    required this.message,
    required this.code,
    required this.canRetry,
    required this.isConflict,
    required this.requiresReauth,
    this.correlationId,
  });

  factory ErrorPresentation.of(Object error, AppStrings s) {
    if (error is ApiError) {
      return ErrorPresentation(
        title: _titleFor(error, s),
        message: error.userMessage(s),
        code: error.code,
        correlationId: error.correlationId,
        canRetry: error.isRetryable,
        isConflict: error is ApiConflict,
        requiresReauth: error.requiresReauth,
      );
    }
    if (error is AuthUnsupportedError) {
      // `reason` is deliberately English developer prose: it names the backend
      // file that has to change, and an operator forwards it verbatim.
      return ErrorPresentation(
        title: s.errorTitleSignInAgain,
        message: error.reason,
        code: error.code,
        canRetry: false,
        isConflict: false,
        requiresReauth: true,
      );
    }
    if (error is JsonParseException) {
      return ErrorPresentation(
        title: s.errorTitleUnreadableResponse,
        message: s.errorUnreadableResponseBody(
          path: error.path,
          reason: error.reason,
        ),
        code: ApiErrorCodes.clientMalformedResponse,
        canRetry: true,
        isConflict: false,
        requiresReauth: false,
      );
    }
    if (error is MoneyFormatException) {
      // A money field that cannot be read EXACTLY is never rounded into view:
      // this console exists to reconcile amounts, so a wrong figure is worse
      // than no figure.
      return ErrorPresentation(
        title: s.errorTitleUnreadableAmount,
        message: s.errorUnreadableAmountBody(reason: error.reason),
        code: ApiErrorCodes.clientMalformedResponse,
        canRetry: true,
        isConflict: false,
        requiresReauth: false,
      );
    }
    return ErrorPresentation(
      title: s.errorTitleSomethingWentWrong,
      message: error.toString(),
      code: 'UNKNOWN',
      canRetry: true,
      isConflict: false,
      requiresReauth: false,
    );
  }

  final String title;
  final String message;
  final String code;
  final String? correlationId;
  final bool canRetry;

  /// True for a 409-style "already handled" outcome, which is NORMAL in a
  /// review console and should be styled as information, not as failure.
  final bool isConflict;

  final bool requiresReauth;

  static String _titleFor(ApiError error, AppStrings s) => switch (error) {
        ApiUnauthorized() => s.errorTitleSessionExpired,
        ApiForbidden() => s.errorTitleNotAllowed,
        ApiValidation() => s.errorTitleCheckDetails,
        ApiNotFound() => s.errorTitleNotFound,
        ApiConflict() => s.errorTitleAlreadyHandled,
        ApiBusinessRule() => s.errorTitleCannotDoThat,
        ApiRateLimited() => s.errorTitleTooManyRequests,
        ApiNetworkError() => s.errorTitleNoConnection,
        ApiTimeout() => s.errorTitleTimedOut,
        ApiServerError() => s.errorTitleServerError,
        ApiUnexpected() => s.errorTitleUnexpectedResponse,
      };
}
