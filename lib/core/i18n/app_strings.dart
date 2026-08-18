// HAND-WRITTEN LOCALISATION. There is NO code generation in this project:
// no .arb files, no `flutter gen-l10n`, no build_runner. This file IS the
// message catalogue.
//
// WHY AN ABSTRACT CLASS AND NOT A Map<String, String>
// [AppStrings] declares one abstract member per user-facing string, so a
// missing translation is a COMPILE ERROR in [ArStrings] or [EnStrings] rather
// than a blank label an operator discovers at 3am. Adding a key is a three-line
// change: declare it here, implement it twice.
//
// RULES THIS FILE OBEYS
// * Arabic is the DEFAULT locale; English is the toggle. Both bundles are
//   complete by construction, so neither is a "fallback".
// * DIGITS STAY WESTERN (0-9) IN BOTH LOCALES. Every `int` interpolated below
//   renders as ASCII because Dart's `toString()` is locale-independent. Never
//   route a count through `NumberFormat` on the way in.
// * MONEY IS NEVER FORMATTED HERE. `Money.format()` owns that - exact BigInt
//   minor units at scale 2 - and must NOT be handed the active locale: the bot
//   shows `1,500.00 NSP` to Arabic operators and so does this app. Money always
//   arrives here as an already-formatted `String`.
// * `intl` is for DATES and RELATIVE TIMES only. See `AppDateFormats` in
//   `app_localizations_x.dart`.
// * Technical tokens are never translated: NSP, Ichancy, API, JSON, UUID,
//   SHA-256, correlation ids, deposit short ids, method codes, mime types,
//   backend error codes and every enum wire name.
//
// KEYS ARE DEDUPLICATED ACROSS FEATURES: one label is one key even when three
// screens show it. Doc comments marked "DEDUPED" name every sharing call site.

import 'dart:ui' show Locale, TextDirection;

/// Every user-facing string in the console, one abstract member per key.
///
/// Read it through `context.s` (see `app_localizations_x.dart`) or, outside a
/// widget, through `ref.read(stringsProvider)`:
///
/// ```dart
/// Text(context.s.depositQueueTitle);
/// Text(context.s.claimHeldByYou(minutes: 7));
/// ```
///
/// Placeholders are NAMED and REQUIRED, so a call site cannot silently swap two
/// arguments of the same type.
abstract class AppStrings {
  const AppStrings();

  /// The Arabic bundle. The app default.
  static const AppStrings ar = ArStrings();

  /// The English bundle.
  static const AppStrings en = EnStrings();

  /// Picks a bundle for [locale]. Anything that is not English resolves to
  /// Arabic, because Arabic is the default rather than the exception.
  static AppStrings of(Locale locale) => forLanguageTag(locale.languageCode);

  /// Picks a bundle for a BCP-47 language tag such as `en`, `en-GB` or `ar-SY`.
  static AppStrings forLanguageTag(String tag) =>
      tag.trim().toLowerCase().startsWith('en') ? en : ar;

  /// `ar` or `en`. Pass this to `DateFormat` - never to `Money.format`.
  String get localeTag;

  /// Reading direction of this bundle. Arabic is RTL.
  TextDirection get textDirection;

  /// MaterialApp.title and the splash headline.
  String get appTitle;

  /// Bottom-nav tab 1: the deposit review queue.
  String get navQueue;

  /// Bottom-nav tab 2: float + breaks + activity report.
  String get navMoney;

  /// App-bar entry into settings. NOT a bottom-nav destination.
  String get settingsTooltip;

  /// Settings row that opens the Arabic/English toggle.
  String get languageLabel;

  /// Endonym. Identical in both locales on purpose.
  String get languageArabic;

  /// Endonym. Identical in both locales on purpose.
  String get languageEnglish;

  /// api_error.dart _messageForCode - transport failure, no HTTP status.
  String get errorRequestFailed;

  /// api_error.dart _messageForCode when the envelope carried no message.
  /// {code} is a technical constant and is never translated.
  String errorServerReturnedStatus({required int status, required String code});

  /// ApiUnauthorized.userMessage - any 401.
  String get errorSessionNoLongerValid;

  /// ApiForbidden.userMessage, code ADMIN_INACTIVE.
  String get errorAdminDeactivated;

  /// ApiForbidden.userMessage, code ADMIN_NOT_FOUND.
  String get errorAdminNotFound;

  /// ApiForbidden.userMessage, code WRONG_PRINCIPAL.
  String get errorWrongPrincipal;

  /// ApiForbidden.userMessage, code INSUFFICIENT_ROLE.
  String get errorInsufficientRole;

  /// ApiNotFound.userMessage (404).
  String get errorRecordNotFound;

  /// ApiValidation.userMessage. {fields} is pre-joined with "\n- ". For
  /// DUPLICATE_RESOURCE / REFERENCE_CONSTRAINT the items are raw column names
  /// and must NOT be translated.
  String errorValidationWithFields({required String message, required String fields});

  /// ApiConflict.userMessage, IDEMPOTENCY_IN_FLIGHT.
  String get errorRequestStillProcessing;

  /// ApiConflict.userMessage, IDEMPOTENCY_KEY_REUSED.
  String get errorRequestAlreadySubmitted;

  /// ApiConflict.userMessage - the normal two-reviewers-one-deposit outcome.
  String get errorAlreadyHandledByOther;

  /// ApiRateLimited.userMessage (429, no retry-after). Also the admin directory
  /// rate-limit copy (was errRateLimited).
  String get errorTooManyRequests;

  /// ApiRateLimited.userMessage when retry-after is present.
  String errorTooManyRequestsRetryIn({required int seconds});

  /// ApiNetworkError.userMessage when isCancelled.
  String get errorRequestCancelled;

  /// ApiNetworkError.userMessage.
  String get errorCannotReachServer;

  /// ApiTimeout.userMessage.
  String get errorServerTookTooLong;

  /// ApiServerError.userMessage without a correlation id.
  String get errorServerInternal;

  /// ApiServerError.userMessage with a correlation id. The id is never
  /// translated and never localises its digits.
  String errorServerInternalWithRef({required String correlationId});

  /// ApiUnexpected.userMessage.
  String get errorUnreadableFromServer;

  /// ApiError.supportMessage. "مرجع" here is the CORRELATION id; the bot's
  /// "المرجع" is the deposit shortId - keep the two apart.
  String errorSupportLine({required String message, required String code, required String correlationId});

  /// ApiError.supportMessage when there is no correlation id.
  String errorSupportLineShort({required String message, required String code});

  /// api_response.dart decodeEnvelope.
  String get errorEnvelopeMissing;

  /// api_client.dart _malformed. All four values are technical and stay as-is.
  String errorCouldNotReadResponse({required String method, required String path, required String field, required String reason});

  /// api_client.dart _badAmount.
  String errorAmountNotExact({required String method, required String path, required String reason});

  /// api_client.dart _mapDioException, timeout branch.
  String errorRequestTimedOutPath({required String path});

  /// api_client.dart _mapDioException, badCertificate branch.
  String get errorCertificateRejected;

  /// api_client.dart _mapDioException, badResponse branch.
  String errorResponseUndecodable({required String method, required String path});

  /// api_client.dart _mapDioException, connectionError branch.
  String errorCouldNotReachHost({required String baseUrl});

  /// ErrorPresentation._titleFor(ApiUnauthorized). Also the profile chip.
  String get errorTitleSessionExpired;

  /// ErrorPresentation._titleFor(ApiForbidden).
  String get errorTitleNotAllowed;

  /// ErrorPresentation._titleFor(ApiValidation).
  String get errorTitleCheckDetails;

  /// ErrorPresentation._titleFor(ApiNotFound).
  String get errorTitleNotFound;

  /// ErrorPresentation._titleFor(ApiConflict), rendered in the pending tone.
  /// Deliberately NOT "تمت المعالجة", which belongs to BreakStatus.RESOLVED.
  String get errorTitleAlreadyHandled;

  /// ErrorPresentation._titleFor(ApiBusinessRule, 422).
  String get errorTitleCannotDoThat;

  /// ErrorPresentation._titleFor(ApiRateLimited).
  String get errorTitleTooManyRequests;

  /// ErrorPresentation._titleFor(ApiNetworkError).
  String get errorTitleNoConnection;

  /// ErrorPresentation._titleFor(ApiTimeout).
  String get errorTitleTimedOut;

  /// ErrorPresentation._titleFor(ApiServerError).
  String get errorTitleServerError;

  /// ErrorPresentation._titleFor(ApiUnexpected).
  String get errorTitleUnexpectedResponse;

  /// ErrorPresentation.of, AuthUnsupportedError branch.
  String get errorTitleSignInAgain;

  /// ErrorPresentation.of, JsonParseException branch.
  String get errorTitleUnreadableResponse;

  /// ErrorPresentation.of, JsonParseException branch. Both values technical.
  String errorUnreadableResponseBody({required String path, required String reason});

  /// ErrorPresentation.of, MoneyFormatException branch.
  String get errorTitleUnreadableAmount;

  /// ErrorPresentation.of, MoneyFormatException branch. {reason} is a MONEY_*
  /// code.
  String errorUnreadableAmountBody({required String reason});

  /// ErrorPresentation.of fallback for any unknown thrown object.
  String get errorTitleSomethingWentWrong;

  /// ErrorStateView retry button (only when the error is retryable).
  String get tryAgain;

  /// proof_gallery.dart _ProofProblem retry button.
  String get retry;

  /// DEDUPED: AsyncValueView empty-state action, the deposit queue overflow
  /// item and detail tooltip, the break-detail tooltip, the payment-method and
  /// admin-directory reload tooltips.
  String get refresh;

  /// AsyncValueView.emptyTitle default.
  String get emptyDefaultTitle;

  /// LoadingStateView.label / AsyncValueView.loadingLabel default.
  String get loading;

  /// DEDUPED: AsyncValueView doc example and the deposit queue loadingLabel.
  /// "الطابور" is the bot word (/queue "📥 الطابور").
  String get loadingQueue;

  /// DEDUPED: AsyncValueView doc example and the unfiltered deposit queue.
  String get queueEmptyTitle;

  /// VERBATIM from the bot (admin.handlers.ts onQueue). Do not re-word.
  String get queueEmptyMessage;

  /// _CorrelationIdChip snackbar. NOT "تم نسخ المرجع" - "المرجع" is bound to
  /// the deposit shortId in the bot.
  String get referenceCopied;

  /// _CorrelationIdChip label. Never translated, tabular Latin digits.
  String correlationChip({required String code, required String correlationId});

  /// DEDUPED: ConfirmActionSheet.cancelLabel, the deposit filter sheet, both
  /// decision sheets, ResolveBreakSheet, the admin forms.
  String get cancel;

  /// ConfirmActionSheet.noteLabel default - note / rejection reason field.
  String get note;

  /// ConfirmActionSheet note field label when noteRequired is true.
  String noteRequiredSuffix({required String label});

  /// ConfirmActionSheet doc example. {amount} is formatted money, Western
  /// digits.
  String confirmApproveAmountTitle({required String amount});

  /// ConfirmActionSheet doc example. Uses شحن (credit), not إيداع.
  String confirmPlayerWillBeCredited({required String playerId});

  /// DEDUPED: the "Reference required" value and BreakDetail.stringify(true).
  String get yes;

  /// DEDUPED: the "Reference required" value and BreakDetail.stringify(false).
  String get no;

  /// Deposit filter sheet footer - publishes the draft filter.
  String get apply;

  /// DEDUPED: the deposit filter sheet header and the break filter sheet.
  String get resetButton;

  /// DEDUPED: the queue filter IconButton tooltip and the break filter button.
  String get filterLabel;

  /// Break filter bar button when facets are active. {count} is 1..3.
  String filterWithCount({required int count});

  /// DEDUPED: the deposit filter section, the break filter group heading and
  /// the admin detail row label.
  String get statusLabel;

  /// DEDUPED: the deposit filter section and the payment-method record row.
  String get createdLabel;

  /// DEDUPED: payment method header, destination card, admin detail.
  String get editButton;

  /// DEDUPED: the payment-method and destination form app-bar actions.
  String get saveButton;

  /// DEDUPED: the same app-bar actions while a save is in flight.
  String get savingButton;

  /// DEDUPED: the break list footer and the admin directory footer.
  String get loadMore;

  /// admin_profile_view.dart _CopyButton tooltip.
  String get copyTooltip;

  /// admin_profile_view.dart snackbar after copying (no label).
  String get copied;

  /// DEDUPED: deposit _InfoRow._copy and reconciliation KeyValueRow snackbars.
  String copiedToClipboard({required String label});

  /// DEDUPED single placeholder for every missing value (money placeholder,
  /// _InfoRow null value, admin absent()). An EM DASH, not ASCII "-": in an RTL
  /// row a leading hyphen visually reorders.
  String get emptyValueDash;

  /// Caption for any screen that shows a timestamp. Json.dateTime()/ApiMeta
  /// convert to LOCAL time while the bot labels everything UTC - in Damascus
  /// that is a 3-hour discrepancy on the same deposit, so say which is which.
  String get timesAreLocalNote;

  /// DEDUPED: RailAgeingBucket.fromJson and RailAgeingRow.fromJson fallbacks.
  String get unknownPlaceholder;

  /// Separator between the items of an inline list of LOCALISED words - the
  /// accepted-roles phrase in every PermissionDeniedView, the active-status
  /// summary on the deposit queue, the admin-directory filter description.
  ///
  /// Arabic uses the ARABIC COMMA (U+060C), which mirrors correctly in an RTL
  /// run; the Latin comma does not. Do NOT use this to join wire values, rail
  /// account codes or query-string parameters - those stay ASCII ",".
  String get listSeparator;

  /// Money.format - the ONLY money rendering in the app, e.g. "1,500.00 NSP".
  /// NSP stays Latin; digits stay ASCII in BOTH locales by design.
  String moneyAmountWithCurrency({required String amount, required String currency});

  /// The bot's dualNsp() quote. {newAmount} is the major decimal (1,000.00),
  /// {oldAmount} the minor-unit integer (100,000). Recommended for headline
  /// amounts, float and totals; keep the single form for dense list rows.
  String moneyDual({required String newAmount, required String oldAmount});

  /// DEDUPED: MONEY_EMPTY everywhere (money.dart, the deposit filter sheet,
  /// payment_method_rules.dart, money_amount_field.dart).
  String get moneyErrorEmpty;

  /// MONEY_MALFORMED, short form (money.dart _decimalToMinor).
  String get moneyErrorMalformed;

  /// payment_method_rules.dart messageForMoneyReason default. Digits Western.
  String get moneyErrorPlainAmountExample;

  /// money_amount_field.dart describeMoneyReason MONEY_MALFORMED.
  String get moneyErrorDigitsOnly;

  /// MONEY_TOO_MANY_DECIMALS, parameterised form (money.dart). NSP scale is 2.
  String moneyErrorTooManyDecimals({required int scale});

  /// Deposit filter sheet AMOUNT hint and the approve sheet verified-amount
  /// helper.
  String get atMostTwoDecimals;

  /// payment_method_rules.dart MONEY_TOO_MANY_DECIMALS.
  String get moneyErrorScaleTwo;

  /// money_amount_field.dart describeMoneyReason MONEY_TOO_MANY_DECIMALS.
  String get moneyErrorScaleTwoDetailed;

  /// MONEY_CURRENCY_MISMATCH from Money._assertCompatible /
  /// MoneyIterable.totalIn.
  String get moneyErrorCurrencyMismatch;

  /// DEDUPED: the single-field MONEY_CURRENCY_MISMATCH message used by
  /// payment_method_rules.dart and money_amount_field.dart.
  String get moneyErrorOtherCurrency;

  /// DEDUPED: the deposit filter sheet _amountError fallback and
  /// money_amount_field.dart describeMoneyReason default.
  String get moneyErrorInvalid;

  /// AdminRole.superAdmin.label.
  String get roleSuperAdmin;

  /// AdminRole.financeAdmin.label.
  String get roleFinanceAdmin;

  /// AdminRole.reviewer.label.
  String get roleReviewer;

  /// AdminRole.support.label. Deliberately not the bare "الدعم", which is the
  /// player menu's customer support.
  String get roleSupport;

  /// AdminRole.viewer.label.
  String get roleViewer;

  /// admin_labels.dart roleWithWireName. The wire name stays Latin.
  String roleWithWireName({required String label, required String wireName});

  /// AdminSession.fromJson / fromStorageJson displayName fallback.
  String get adminDisplayNameFallback;

  /// AdminSession.fromJson JsonParseException reason; surfaces on the login
  /// screen inside errorUnreadableResponseBody.
  String get errorSessionNoExpiry;

  /// auth_controller.dart signOut default message.
  String get signedOut;

  /// auth_controller.dart markExpired with no previous session. {reason} is one
  /// of the reason* keys below, or a raw code (TOKEN_EXPIRED, SESSION_REVOKED)
  /// which stays untranslated.
  String signInAgainWithReason({required String reason});

  /// auth_controller.dart markExpired default reason.
  String get reasonSessionExpired;

  /// auth_controller.dart _restore, expired keystore session.
  String get reasonStoredSessionExpired;

  /// auth_controller.dart signInWithBotCode, dead token from the server.
  String get reasonTokenAlreadyExpired;

  /// auth_controller.dart tryRefresh, on AuthUnsupportedError.
  String get reasonNoRefresh;

  /// http_admin_auth_api.dart exchangeBotCode validation AND the login screen
  /// TextField errorText - the same sentence in both places.
  String get enterBotCode;

  /// ApiValidation.fieldMessages entry; a bullet under
  /// errorValidationWithFields.
  String get codeMustNotBeEmpty;

  /// fake_admin_auth_api.dart _reject (BOT_CODE_INVALID). The dev-code list
  /// that follows it is developer text and stays English.
  String get botCodeInvalid;

  /// fake_admin_auth_api.dart _displayNameFor - the synthetic AdminSession
  /// displayName a DEV-<ROLE> code produces. It IS user-visible (the login
  /// banner and the profile screen render it), so it is localised even though
  /// it only ever appears in a dev build. {role} is the AdminRole LABEL,
  /// already localised. A `DEV-SUPPORT:Layla` code overrides it entirely.
  String devDisplayName({required String role});

  /// login_screen.dart headline.
  String get loginTitle;

  /// login_screen.dart _headlineFor(AuthInitializing).
  String get loginHeadlineRestoring;

  /// login_screen.dart _headlineFor(AuthUnauthenticated).
  String get loginHeadlineSignIn;

  /// login_screen.dart _headlineFor(AuthAuthenticating).
  String get loginHeadlineChecking;

  /// login_screen.dart _headlineFor(AuthAuthenticated).
  String loginHeadlineSignedInAs({required String name});

  /// login_screen.dart _headlineFor(AuthExpired).
  String get loginHeadlineSessionEnded;

  /// login_screen.dart TextField labelText.
  String get botCodeFieldLabel;

  /// login_screen.dart TextField helperText (2 lines max).
  String get botCodeFieldHelper;

  /// login_screen.dart submit button, idle.
  String get signIn;

  /// login_screen.dart submit button, busy.
  String get signingIn;

  /// login_screen.dart _AuthBanner title for AuthExpired.
  String get sessionEndedTitle;

  /// login_screen.dart _AuthBanner, AuthExpired. Pass the role LABEL as-is - do
  /// not lower-case it, Arabic has no case.
  String sessionEndedBody({required String name, required String role, required String reason});

  /// login_screen.dart _EnvironmentFooter, real-auth build. Never translated.
  String envFooter({required String env, required String baseUrl});

  /// login_screen.dart _EnvironmentFooter, dev build with useFakeAuth.
  String fakeAuthBanner({required String env, required String baseUrl});

  /// login_screen.dart dev-code chip for DEV-REVIEWER:SHORT. The code stays
  /// Latin.
  String get devCodeShortLabel;

  /// login_screen.dart dev-code chip.
  String get devCodeDenyLabel;

  /// login_screen.dart _DevCodeChip snackbar. {code} is a DEV-* literal.
  String copiedCode({required String code});

  /// deposit_queue_screen.dart AppBar title (permitted and denied variants).
  String get depositQueueTitle;

  /// Snackbar after a failed pull-to-refresh. {message} is
  /// ErrorPresentation.of(error).message.
  String queueRefreshFailed({required String message});

  /// deposit_queue_screen.dart PermissionDeniedView title.
  String get queueNoAccessTitle;

  /// deposit_queue_screen.dart PermissionDeniedView message.
  String get queueNoAccessMessage;

  /// deposit_queue_screen.dart PopupMenuButton<DepositSort> tooltip.
  String get sortTooltip;

  /// deposit_queue_screen.dart overflow PopupMenuButton tooltip.
  String get moreTooltip;

  /// Overflow menu item, shown only when a filter is active.
  String get clearFiltersAction;

  /// Overflow menu item, MAINTENANCE_ROLES only.
  String get runSweepAction;

  /// AsyncValueView emptyTitle when a filter is active.
  String get queueNoMatchesTitle;

  /// AsyncValueView emptyMessage when a filter is active.
  String get queueNoMatchesMessage;

  /// _FilterSummaryBar clear-all TextButton.
  String get clearButton;

  /// _FilterSummaryBar._describe when more than two statuses are selected.
  String filterSummaryStatuses({required int count});

  /// _FilterSummaryBar._describe. {shortId} is never translated.
  String filterSummaryShortId({required String shortId});

  /// _FilterSummaryBar._describe.
  String filterSummaryExternalReference({required String reference});

  /// _FilterSummaryBar._describe amount range. Either bound may be
  /// filterSummaryAny.
  String filterSummaryAmountRange({required String min, required String max});

  /// _FilterSummaryBar._describe, substituted for a missing min or max bound.
  String get filterSummaryAny;

  /// _FilterSummaryBar._describe.
  String get filterSummaryDateRange;

  /// _FilterSummaryBar._describe.
  String get filterSummaryOnePlayer;

  /// _FilterSummaryBar._describe.
  String get filterSummaryOneMethod;

  /// _FilterSummaryBar._describe.
  String get filterSummaryUnclaimedOnly;

  /// _FilterSummaryBar._describe fallback when no part matched.
  String get filterSummaryFallback;

  /// _QueueFooter, amount-sort paging refusal. {sort} is DepositSort.label.
  String queuePagingBlockedBySort({required String sort});

  /// _QueueFooter end-of-list line.
  String queueLoadedCount({required int count});

  /// deposit_queue_screen.dart ConfirmActionSheet title.
  String get sweepConfirmTitle;

  /// deposit_queue_screen.dart ConfirmActionSheet message.
  String get sweepConfirmMessage;

  /// deposit_queue_screen.dart ConfirmActionSheet confirmLabel.
  String get sweepConfirmButton;

  /// Snackbar on a failed sweep.
  String sweepFailed({required String message});

  /// SweepReport.summary when total == 0.
  String get sweepNothingToDo;

  /// SweepReport.summary, shown in the sweep snackbar.
  String sweepSummary({required int expired, required int released, required int reaped});

  /// deposit_detail_screen.dart PermissionDeniedView title.
  String get detailNoAccessTitle;

  /// deposit_detail_screen.dart PermissionDeniedView message.
  String get detailNoAccessMessage;

  /// deposit_detail_screen.dart AsyncValueView loadingLabel.
  String detailLoadingLabel({required String shortId});

  /// ConfirmActionSheet before stealing a stale claim.
  String get claimTakeOverTitle;

  /// deposit_detail_screen.dart ConfirmActionSheet message.
  String get claimTakeOverMessage;

  /// deposit_detail_screen.dart ConfirmActionSheet confirmLabel.
  String get claimTakeOverConfirm;

  /// ConfirmActionSheet before releasing a claim.
  String releaseConfirmTitle({required String shortId});

  /// deposit_detail_screen.dart ConfirmActionSheet message.
  String get releaseConfirmMessage;

  /// deposit_detail_screen.dart ConfirmActionSheet confirmLabel.
  String get releaseConfirmButton;

  /// ConfirmActionSheet before retry-credit.
  String get retryCreditConfirmTitle;

  /// ConfirmActionSheet message. {amount} is the credited or claimed Money.
  String retryCreditConfirmMessage({required String amount});

  /// deposit_detail_screen.dart ConfirmActionSheet confirmLabel.
  String get retryCreditConfirmButton;

  /// ConfirmActionSheet noteLabel on retry-credit.
  String get retryCreditReasonLabel;

  /// ConfirmActionSheet noteHint. The bot float term is رصيد الكاشيرة, not رصيد
  /// الوكيل.
  String get retryCreditReasonHint;

  /// deposit_detail_screen.dart _Section title. Do NOT .toUpperCase() in
  /// Arabic.
  String get sectionAmounts;

  /// _MoneyRow label and the approve sheet _AmountBreakdown.
  String get amountPlayerClaimed;

  /// deposit_detail_screen.dart _MoneyRow label.
  String get amountVerifiedByAdmin;

  /// _MoneyRow hint when verified is null.
  String get amountNotVerifiedYet;

  /// _MoneyRow label and the approve sheet _AmountBreakdown.
  String get amountFee;

  /// _MoneyRow label (emphasised row).
  String get amountCreditedToPlayer;

  /// _MoneyRow hint when credited is null.
  String get amountNotCreditedYet;

  /// DEDUPED: the deposit detail _Section title and the break LinksView row.
  String get playerLabel;

  /// _InfoRow label for the @handle. Spelling matches the bot: التيليغرام.
  String get playerTelegram;

  /// DEDUPED: the deposit detail row and the admin identity row. 64-bit id
  /// rendered as a string.
  String get telegramIdLabel;

  /// deposit detail _InfoRow and the deposit filter sheet TextField label.
  String get playerIdLabel;

  /// _Section title above _DestinationBlock.
  String get sectionDestination;

  /// deposit_detail_screen.dart _Section title.
  String get sectionSubmitted;

  /// deposit detail _InfoRow and the filter sheet label. Must NOT be the bare
  /// المرجع - that is bound to the deposit shortId on the bot ops card.
  String get externalReferenceLabel;

  /// deposit_detail_screen.dart _InfoRow error hint (red).
  String get externalReferenceMissingHint;

  /// DEDUPED: the deposit detail row and RailProofField.senderAccount.label.
  String get senderAccountLabel;

  /// DEDUPED: the RiskFlagStrip header in core and the deposit detail _Section
  /// title ("Risk flags").
  String get riskSignals;

  /// Caption under the RiskFlagStrip.
  String get riskFlagsDisclaimer;

  /// _Section title above ProofGallery. {count} is deposit.proofs.length.
  String sectionProof({required int count});

  /// _Section title above DepositTimeline.
  String get sectionHistory;

  /// deposit_detail_screen.dart _Section title.
  String get sectionTechnical;

  /// _InfoRow label (uuid, copyable).
  String get technicalDepositId;

  /// deposit detail _InfoRow and the filter sheet TextField label.
  String get technicalPaymentMethodId;

  /// deposit_detail_screen.dart _InfoRow label.
  String get technicalCreditAttempts;

  /// deposit_detail_screen.dart _InfoRow label.
  String get technicalCreditKeyEpoch;

  /// _InfoRow label; the value is a CreditVerifiedBy label.
  String get technicalCreditVerifiedBy;

  /// deposit_detail_screen.dart _InfoRow label.
  String get technicalDecidedByAdmin;

  /// deposit_detail_screen.dart _InfoRow label.
  String get technicalSecondApprover;

  /// _Headline line under the amount. {age} is DepositFormat.age output.
  String headlineCreatedAgo({required String shortId, required String age});

  /// _Headline note for PENDING_SECOND_APPROVAL.
  String get pendingSecondApprovalNote;

  /// _ClaimBanner, fresh claim held by the signed-in admin.
  String claimHeldByYou({required int minutes});

  /// _ClaimBanner, my claim went stale.
  String get claimExpiredMine;

  /// _ClaimBanner, someone else's stale claim.
  String get claimStaleOther;

  /// _ClaimBanner, someone else's fresh claim.
  String claimHeldByOther({required int minutes});

  /// _ReportBanner third line. Deliberately NOT المرجع: the bot binds that to
  /// the deposit shortId.
  String correlationIdLine({required String correlationId});

  /// _DestinationBlock empty state.
  String get destinationMissing;

  /// DEDUPED: the deposit _DestinationBlock "Method" row and the rail-ageing
  /// KeyValueRow. Singular record field, per the glossary.
  String get paymentMethodLabel;

  /// _DestinationBlock _InfoRow label (e.g. SYRIATEL_CASH; value untranslated).
  String get destinationMethodCode;

  /// _DestinationBlock _InfoRow label.
  String get destinationLabel;

  /// DEDUPED: the deposit _DestinationBlock row and the destination form
  /// section.
  String get accountLabel;

  /// DEDUPED: the deposit _DestinationBlock row and the destination form field.
  String get accountHolderLabel;

  /// DEDUPED: the deposit _DestinationBlock row label (value is yes/no) and the
  /// payment-method tile StatusChip.
  String get referenceRequiredLabel;

  /// DEDUPED: the deposit _DestinationBlock row and the payment-method
  /// instructions field label.
  String get instructionsLabel;

  /// deposit_filter_sheet.dart header.
  String get filterSheetTitle;

  /// deposit_filter_sheet.dart hint under STATUS.
  String get filterStatusHint;

  /// ActionChip preset (SUBMITTED, UNDER_REVIEW, PENDING_SECOND_APPROVAL).
  String get presetReviewable;

  /// ActionChip preset (CREDIT_FAILED + NEEDS_RECONCILIATION).
  String get presetNeedsAttention;

  /// ActionChip preset that clears the status set.
  String get presetAnyStatus;

  /// deposit_filter_sheet.dart _SectionLabel.
  String get filterSectionSort;

  /// Caption under the sort chips when an amount sort is picked.
  String get sortNotPageableHint;

  /// deposit_filter_sheet.dart _SectionLabel.
  String get filterSectionSearch;

  /// deposit_filter_sheet.dart hint under SEARCH.
  String get filterSearchHint;

  /// shortId TextField labelText.
  String get filterShortIdLabel;

  /// shortId TextField hintText: a sample short id. Never translated, never
  /// digit-localised.
  String get filterShortIdHint;

  /// External reference TextField hintText.
  String get filterCaseSensitiveHint;

  /// deposit_filter_sheet.dart _SectionLabel (filters claimedAmountMinor only).
  String get filterSectionAmount;

  /// Min amount TextField label.
  String get filterAmountMin;

  /// Max amount TextField label.
  String get filterAmountMax;

  /// Amount TextField hintText. Western digits in both locales.
  String get amountFieldHintSample;

  /// deposit_filter_sheet.dart hint under CREATED.
  String get filterCreatedHint;

  /// _DateButton label when no date is picked.
  String get dateFrom;

  /// _DateButton label when no date is picked.
  String get dateTo;

  /// deposit_filter_sheet.dart _SectionLabel.
  String get filterSectionIdentifiers;

  /// deposit_filter_sheet.dart hint under IDENTIFIERS.
  String get filterIdentifiersHint;

  /// deposit_filter_sheet.dart SwitchListTile title.
  String get filterUnclaimedOnly;

  /// deposit_filter_sheet.dart SwitchListTile subtitle.
  String get filterUnclaimedOnlySubtitle;

  /// DepositSort.newest.label.
  String get sortNewest;

  /// DepositSort.oldest.label.
  String get sortOldest;

  /// DepositSort.amountDesc.label.
  String get sortAmountDesc;

  /// DepositSort.amountAsc.label.
  String get sortAmountAsc;

  /// deposit_query.dart validate() - the filter sheet _ProblemList.
  String get validationPlayerIdUuid;

  /// deposit_query.dart validate().
  String get validationPaymentMethodIdUuid;

  /// deposit_query.dart validate().
  String get validationReferenceTooLong;

  /// deposit_query.dart validate().
  String get validationShortIdTooLong;

  /// deposit_query.dart validate().
  String get validationMinAboveMax;

  /// deposit_query.dart validate().
  String get validationFromBeforeTo;

  /// deposit_filter_sheet.dart _apply().
  String get validationMinAmountInvalid;

  /// deposit_filter_sheet.dart _apply().
  String get validationMaxAmountInvalid;

  /// DepositStatus.draft.label.
  String get statusDraft;

  /// DepositStatus.awaitingProof.label.
  String get statusAwaitingProof;

  /// DepositStatus.submitted.label. Bot wording, reused verbatim.
  String get statusSubmitted;

  /// DepositStatus.underReview.label.
  String get statusUnderReview;

  /// DepositStatus.pendingSecondApproval.label.
  String get statusPendingSecondApproval;

  /// DepositStatus.approved.label. Distinct from CREDITING here.
  String get statusApproved;

  /// DepositStatus.crediting.label.
  String get statusCrediting;

  /// DepositStatus.credited.label. Not تم الإيداع - the credit verb is شحن.
  String get statusCredited;

  /// DepositStatus.creditFailed.label (bot fragment: 🚨 فشل شحن).
  String get statusCreditFailed;

  /// DepositStatus.needsReconciliation.label. Bot fragment - do NOT coin a
  /// synonym from التسوية.
  String get statusNeedsReconciliation;

  /// DepositStatus.rejected.label.
  String get statusRejected;

  /// DEDUPED: DepositStatus.expired.label and RejectionCode.expired.label.
  String get statusExpired;

  /// DepositStatus.reversed.label.
  String get statusReversed;

  /// RejectionCode.duplicateProof.label.
  String get rejectionDuplicateProof;

  /// DEDUPED: RejectionCode.proofUnreadable.label and RiskFlags
  /// PROOF_UNREADABLE.
  String get rejectionProofUnreadable;

  /// RejectionCode.proofMissing.label.
  String get rejectionProofMissing;

  /// RejectionCode.amountMismatch.label.
  String get rejectionAmountMismatch;

  /// RejectionCode.referenceNotFound.label.
  String get rejectionReferenceNotFound;

  /// RejectionCode.wrongDestination.label.
  String get rejectionWrongDestination;

  /// RejectionCode.senderMismatch.label.
  String get rejectionSenderMismatch;

  /// RejectionCode.suspectedFraud.label.
  String get rejectionSuspectedFraud;

  /// RejectionCode.limitExceeded.label.
  String get rejectionLimitExceeded;

  /// RejectionCode.playerIneligible.label.
  String get rejectionPlayerIneligible;

  /// RejectionCode.other.label.
  String get rejectionOther;

  /// ProofSource.playerUpload.label.
  String get proofSourcePlayerUpload;

  /// ProofSource.adminUpload.label.
  String get proofSourceAdminUpload;

  /// ProofSource.telegramPhoto.label.
  String get proofSourceTelegramPhoto;

  /// ProofSource.telegramDocument.label.
  String get proofSourceTelegramDocument;

  /// ProofSource.systemImport.label.
  String get proofSourceSystemImport;

  /// CreditVerifiedBy.apiOk.label. Ichancy/API stay Latin.
  String get creditVerifiedApiOk;

  /// CreditVerifiedBy.balanceDelta.label.
  String get creditVerifiedBalanceDelta;

  /// CreditVerifiedBy.manual.label.
  String get creditVerifiedManual;

  /// RiskFlags DUPLICATE_PROOF_EXACT. Replaces the manufactured
  /// humanizeWireCode() label - unknown flags fall back to the raw code.
  String get riskDuplicateProofExact;

  /// RiskFlags DUPLICATE_PROOF_SIMILAR.
  String get riskDuplicateProofSimilar;

  /// RiskFlags REFERENCE_REUSED.
  String get riskReferenceReused;

  /// RiskFlags DUPLICATE_PROOF_SAME_PLAYER.
  String get riskDuplicateProofSamePlayer;

  /// RiskFlags RAPID_RESUBMISSION.
  String get riskRapidResubmission;

  /// RiskFlags LARGE_AMOUNT.
  String get riskLargeAmount;

  /// RiskFlags NEW_PLAYER.
  String get riskNewPlayer;

  /// DepositAction.claim.label.
  String get actionClaim;

  /// DepositAction.claim.description.
  String get actionClaimDescription;

  /// DepositAction.release.label.
  String get actionRelease;

  /// DepositAction.release.description.
  String get actionReleaseDescription;

  /// DepositAction.approve.label.
  String get actionApprove;

  /// DepositAction.approve.description.
  String get actionApproveDescription;

  /// DepositAction.reject.label.
  String get actionReject;

  /// DepositAction.reject.description.
  String get actionRejectDescription;

  /// DepositAction.retryCredit.label.
  String get actionRetryCredit;

  /// DepositAction.retryCredit.description.
  String get actionRetryCreditDescription;

  /// deposit_action_policy.dart blockReason under a disabled Retry credit.
  String get blockOnlyFinanceAdminRetry;

  /// deposit_action_policy.dart blockReason; also the ADMIN_NO_APPROVAL_LIMIT
  /// message in deposit_action_report.dart.
  String get blockRoleCannotDecide;

  /// blockReason on Claim when the remaining minutes are known. The English
  /// used to be built by concatenation - it is one whole sentence now.
  String blockClaimedByOther({required int minutes});

  /// blockReason on Claim when the remaining minutes are unknown.
  String get blockClaimedByOtherUnknown;

  /// deposit_action_policy.dart blockReason on Release.
  String get blockNotClaimHolder;

  /// deposit_action_bar.dart composed reason line.
  String actionBlockedLine({required String action, required String reason});

  /// idleReasonFor(DRAFT, AWAITING_PROOF).
  String get idleNotSubmittedYet;

  /// idleReasonFor(APPROVED).
  String get idleApproved;

  /// idleReasonFor(CREDITING).
  String get idleCrediting;

  /// idleReasonFor(CREDITED).
  String get idleCredited;

  /// idleReasonFor(REJECTED).
  String get idleRejected;

  /// idleReasonFor(EXPIRED).
  String get idleExpired;

  /// idleReasonFor(REVERSED).
  String get idleReversed;

  /// idleReasonFor fallback for the reviewable + attention statuses.
  String get idleNoActionForRole;

  /// ApproveDepositSheet title.
  String get approveSheetTitle;

  /// ApproveDepositSheet title when status is PENDING_SECOND_APPROVAL.
  String get approveSheetSecondTitle;

  /// _AmountBreakdown line, only when the amount was corrected.
  String get amountYouVerified;

  /// _AmountBreakdown net line (verified minus fee).
  String get amountPlayerReceives;

  /// ApproveDepositSheet SwitchListTile title.
  String get approveOverrideToggle;

  /// SwitchListTile subtitle when on.
  String get approveOverrideOn;

  /// SwitchListTile subtitle when off.
  String get approveOverrideOff;

  /// Override field labelText. The suffix is the currency code, NSP,
  /// untranslated.
  String get verifiedAmountLabel;

  /// Note TextField labelText on both the approve and the reject sheet.
  String get noteOptionalLabel;

  /// Approve note TextField hintText.
  String get approveNoteHint;

  /// _Advisory on the second-approval variant.
  String get approveAdvisorySecondApproval;

  /// _Advisory on the normal variant.
  String get approveAdvisoryThreshold;

  /// _blockingProblem - disables the approve button.
  String get approveErrorInvalidAmount;

  /// deposit_decision_sheets.dart _blockingProblem.
  String get approveErrorNotPositive;

  /// _blockingProblem. {fee} is formatted Money.
  String approveErrorBelowFee({required String fee});

  /// ApproveDepositSheet primary FilledButton. {amount} is formatted Money.
  String approveButton({required String amount});

  /// Primary FilledButton on the second-approval variant.
  String get approveSecondButton;

  /// RejectDepositSheet title.
  String get rejectSheetTitle;

  /// Mono subtitle under the reject title.
  String rejectSheetSubtitle({required String shortId, required String amount});

  /// Caption under the reject title.
  String get rejectSheetNote;

  /// Label above the RejectionCode chips. NOTE: different from
  /// retryCreditReasonLabel, which is the plain السبب.
  String get rejectReasonLabel;

  /// Reject note TextField hintText.
  String get rejectNoteHint;

  /// Reject button label while no code is selected.
  String get rejectChooseReason;

  /// Reject button once a code is chosen. {reason} is RejectionCode.label.
  String rejectButton({required String reason});

  /// deposit_queue_row.dart fallback when the row has no destination.
  String get unknownMethod;

  /// deposit_queue_row.dart StatusChip when claimMinutes is null.
  String get claimedChip;

  /// deposit_queue_row.dart StatusChip with the remaining claim minutes.
  String claimedChipMinutes({required int minutes});

  /// deposit_queue_row.dart _RiskSummary. {worst} is a RiskFlags label.
  String riskMoreFlags({required String worst, required int count});

  /// deposit_timeline.dart event title from createdAt (a verb, not a field
  /// label).
  String get timelineCreated;

  /// deposit_timeline.dart event title from submittedAt.
  String get timelineSubmitted;

  /// Submitted-event subtitle when proofCount == 0.
  String get timelineNoProofAttached;

  /// deposit_timeline.dart submitted-event subtitle.
  String timelineProofsAttached({required int count});

  /// deposit_timeline.dart event title from reviewStartedAt.
  String get timelineClaimed;

  /// Claimed-event subtitle. {id} is a truncated uuid, never translated.
  String timelineAdmin({required String id});

  /// Decision event for REJECTED; the note is the subtitle.
  String timelineRejectedWithReason({required String reason});

  /// Decision event for PENDING_SECOND_APPROVAL.
  String get timelineFirstApproval;

  /// Subtitle of the first-approval event.
  String get timelineFirstApprovalSubtitle;

  /// Decision event title for every other status.
  String get timelineApproved;

  /// Approved-event subtitle. {id} is a truncated uuid.
  String timelineSecondApprover({required String id});

  /// Event title from creditedAt; the subtitle is the CreditVerifiedBy label.
  String get timelineCredited;

  /// Future event from expiresAt on a non-terminal deposit.
  String get timelineExpires;

  /// _TimelineTile line for an event still in the future.
  String timelineFuture({required String timestamp, required String timeLeft});

  /// DEDUPED: the deposit timeline fallback when timeLeft is null and
  /// admin_labels.dart relative() under 45 seconds.
  String get moments;

  /// Caption under the whole timeline.
  String get timelineFooter;

  /// DEDUPED: DepositFormat.age negative elapsed and ReconciliationFormats
  /// age() under a minute ("just now").
  String get ageNow;

  /// DepositFormat.age under a minute.
  String ageSeconds({required int count});

  /// DEDUPED: DepositFormat.age/timeLeft and ReconciliationFormats.age.
  String ageMinutes({required int count});

  /// DEDUPED: DepositFormat.age/timeLeft and ReconciliationFormats.age.
  String ageHours({required int count});

  /// DEDUPED: DepositFormat.age and ReconciliationFormats.age.
  String ageHoursMinutes({required int hours, required int minutes});

  /// DEDUPED: DepositFormat.age/timeLeft and ReconciliationFormats.age.
  String ageDays({required int count});

  /// DEDUPED: DepositFormat.age and ReconciliationFormats.age.
  String ageDaysHours({required int days, required int hours});

  /// ReconciliationFormats.age() for a negative duration.
  String get ageInFuture;

  /// DEDUPED: ReconciliationFormats.since() and admin_labels.dart relative()
  /// past direction. NOTE the word order flips in Arabic.
  String ageAgo({required String age});

  /// DEDUPED: DepositFormat.timestampWithAge and
  /// ReconciliationFormats.timestampWithAge. {timestamp} must be produced by a
  /// locale-aware DateFormat; see AppDateFormats.
  String timestampWithAge({required String timestamp, required String age});

  /// ProofGallery empty state.
  String get proofNone;

  /// ProofThumbnail caption. {index} is 1-based.
  String proofIndexOfTotal({required int index, required int total});

  /// Second caption line under a thumbnail.
  String proofThumbnailCaption({required String source, required String size});

  /// Image.memory errorBuilder.
  String get proofDecodeFailed;

  /// _ProofViewer AppBar title (full-screen receipt).
  String get proofViewerTitle;

  /// _ProofViewer info IconButton tooltip.
  String get detailsTooltip;

  /// proof_gallery.dart bottom sheet title.
  String get proofDetailsTitle;

  /// _DetailLine label.
  String get proofDetailSource;

  /// _DetailLine label (proof.mimeType).
  String get proofDetailStoredType;

  /// _DetailLine label (sniffed mime type).
  String get proofDetailServedAs;

  /// _DetailLine label.
  String get proofDetailSize;

  /// _DetailLine label, only when width/height are known.
  String get proofDetailDimensions;

  /// _DetailLine label.
  String get proofDetailUploaded;

  /// _DetailLine label. Technical, identical in both locales.
  String get proofDetailSha256;

  /// _DetailLine label.
  String get proofDetailFetchedVia;

  /// "Fetched via" value.
  String get proofViaPresignedUrl;

  /// "Fetched via" value.
  String get proofViaApiStream;

  /// DepositProofView.sizeLabel.
  String sizeBytes({required int count});

  /// DepositProofView.sizeLabel.
  String sizeKilobytes({required int count});

  /// DepositProofView.sizeLabel. {value} is pre-formatted to one decimal with
  /// ASCII digits - do NOT route it through a localised NumberFormat.
  String sizeMegabytes({required String value});

  /// DepositProofView.dimensionLabel.
  String dimensionLabel({required int width, required int height});

  /// deposit_repository.dart loadProofImage - PROOF_NOT_FOUND.
  String get proofGone;

  /// deposit_repository.dart _fetchBytes - non-2xx / empty body / generic Dio.
  String get proofDownloadFailed;

  /// deposit_repository.dart _fetchBytes - DioExceptionType.cancel.
  String get proofDownloadCancelled;

  /// _fetchBytes - PROOF_STREAM_ENVELOPED. JSON stays Latin.
  String get proofEnvelopeInsteadOfBytes;

  /// Detail line under proofEnvelopeInsteadOfBytes.
  String get proofEnvelopeDetail;

  /// _fetchBytes - PROOF_NOT_AN_IMAGE.
  String get proofNotAnImage;

  /// Detail line under proofNotAnImage. {mimeType} is untranslated.
  String proofNotAnImageDetail({required String mimeType, required int bytes});

  /// deposit_action_report.dart ReviewApproved.
  String get reportApproved;

  /// Detail line under reportApproved. {id} is a uuid.
  String reportLedgerTransaction({required String id});

  /// deposit_action_report.dart ReviewAwaitingSecondApproval.
  String get reportAwaitingSecondApproval;

  /// deposit_action_report.dart ReviewRejected.
  String get reportRejected;

  /// deposit_action_report.dart ReviewClaimed.
  String get reportClaimed;

  /// deposit_action_report.dart ReviewReleased.
  String get reportReleased;

  /// ReviewAlreadyHandled with no status.
  String get reportAlreadyHandled;

  /// ReviewAlreadyHandled with a status. Pass DepositStatus.label as-is; drop
  /// the old .toLowerCase().
  String reportAlreadyHandledWithStatus({required String status});

  /// ReviewUnknown. {kind} is the raw wire value, never translated.
  String reportUnknownOutcome({required String kind});

  /// fromError non-ApiError fallback. Pass DepositAction.label as-is.
  String reportActionFailed({required String action});

  /// DEPOSIT_CLAIMED_BY_OTHER, styled as information not an error.
  String get reportClaimedByOther;

  /// deposit_action_report.dart ApiNotFound branch.
  String get reportDepositGone;

  /// _serverErrorMessage(claim). Enum names stay Latin.
  String get reportClaimBackendDefect;

  /// deposit_action_report.dart _serverErrorMessage(retryCredit).
  String get reportRetryCreditBackendDefect;

  /// _forbiddenMessage - ADMIN_LIMIT_EXCEEDED.
  String get reportAboveApprovalLimit;

  /// _forbiddenMessage - SECOND_APPROVER_MUST_DIFFER.
  String get reportSecondApproverMustDiffer;

  /// _businessMessage - VERIFIED_AMOUNT_REQUIRED, only when the server sent
  /// none.
  String get reportVerifiedAmountRequired;

  /// _businessMessage - DEPOSIT_INVALID_STATE.
  String get reportInvalidState;

  /// deposit_detail_controller.dart build() ApiNotFound.
  String detailNotFound({required String shortId});

  /// Guard on every action before the uuid resolves.
  String get detailStillLoading;

  /// deposit_detail_controller.dart _runReview double-fire guard.
  String get detailActionInFlight;

  /// _runReview local legality refusal. The old English built a past tense by
  /// appending "ed" to the lower-cased action label; that is gone.
  String detailIllegalAction({required String status, required String action});

  /// deposit_detail_controller.dart retryCredit, requeued == true.
  String get retryCreditRequeued;

  /// Detail line in the retry-credit banner.
  String retryCreditEpochDetail({required int epoch});

  /// deposit_detail_controller.dart retryCredit, requeued == false.
  String retryCreditNotRequeued({required int epoch});

  /// deposit_detail_controller.dart _settle - the _StaleBanner.
  String get detailStaleWarning;

  /// deposits permission_denied_view.dart footer. {role} is AdminRole.label.
  String signedInAsRole({required String role});

  /// reconciliation_screen.dart AppBar title (granted and denied variants).
  String get reconciliationTitle;

  /// reconciliation_screen.dart AppBar refresh tooltip.
  String get refreshBreaksTooltip;

  /// TabBar tab 1.
  String get tabBreaks;

  /// TabBar tab 2 and the agent_float_panel.dart card title. رصيد الكاشيرة is
  /// the bot term - never رصيد الوكيل.
  String get tabAgentFloat;

  /// TabBar tab 3.
  String get tabRailAgeing;

  /// TabBar tab 4 (short form of قواعد الدفاتر).
  String get tabInvariants;

  /// _AttentionBadge StatusChip in the AppBar.
  String attentionBadge({required int count});

  /// break_detail_screen.dart AppBar title.
  String get breakScreenTitle;

  /// `action` passed to ReconciliationDeniedView.
  String get deniedActionOpenBreak;

  /// break_detail_screen.dart AsyncValueView loadingLabel.
  String get loadingBreak;

  /// ConfirmActionSheet title for the ledger correction. {amount} is a signed
  /// Money.format(alwaysShowSign: true), or correctFloatConfirmTitleFallback.
  String correctFloatConfirmTitle({required String amount});

  /// Substituted for {amount} in correctFloatConfirmTitle when delta is null.
  String get correctFloatConfirmTitleFallback;

  /// break_detail_screen.dart ConfirmActionSheet message.
  String get correctFloatConfirmMessage;

  /// break_detail_screen.dart ConfirmActionSheet confirm button.
  String get correctFloatConfirmLabel;

  /// break_detail_screen.dart ConfirmActionSheet note field label.
  String get correctionNoteLabel;

  /// break_detail_screen.dart ConfirmActionSheet note field hint.
  String get correctionNoteHint;

  /// ReconciliationCard title above BreakDriftView.
  String get cardTheDifference;

  /// ReconciliationCard title above BreakEvidenceView.
  String get cardDetectorEvidence;

  /// Subtitle of the Detector evidence card.
  String get cardDetectorEvidenceSubtitle;

  /// ReconciliationCard title above BreakLinksView.
  String get cardLinkedRecords;

  /// NoticeStrip in the break header card.
  String get breakReopenedNotice;

  /// NoticeStrip when category.hasDetector is false.
  String get breakNoDetectorNotice;

  /// StatusChip in the break header chip row.
  String get chipAssigned;

  /// break_detail_screen.dart and agent_float_panel.dart KeyValueRow.
  String get breakIdLabel;

  /// break header KeyValueRow (value is a UUID).
  String get assignedToAdminLabel;

  /// break header KeyValueRow.
  String get dedupeKeyLabel;

  /// Explanatory line under the dedupe key row.
  String get dedupeKeyHelp;

  /// _ResolutionCard title when the break is terminal.
  String get resolutionCardClosedTitle;

  /// _ResolutionCard title when the break was re-opened.
  String get resolutionCardEarlierTitle;

  /// _ResolutionCard KeyValueRow.
  String get closedAtLabel;

  /// _ResolutionCard KeyValueRow (value is a UUID).
  String get closedByAdminLabel;

  /// _ResolutionCard KeyValueRow label AND the section heading above the
  /// Correct-the-ledger button.
  String get ledgerCorrectionLabel;

  /// _ResolutionCard value when resolutionTxId is null.
  String get ledgerCorrectionNone;

  /// DEDUPED: _BreakActionsCard title and the admin detail DetailSection title.
  String get actionsCardTitle;

  /// _BreakActionsCard body when the role may not act. {roles} is a comma list
  /// of AdminRole labels from ReconciliationRoles.describe.
  String actionsNeedRole({required String roles});

  /// _BreakActionsCard body for a terminal break.
  String actionsBreakClosedNotice({required String status});

  /// Assign button when the break already has an assignee.
  String get takeOverBreak;

  /// Assign button when the break is unassigned.
  String get assignToMe;

  /// Primary FilledButton that opens ResolveBreakSheet.
  String get closeTheBreak;

  /// Text above the Correct-the-ledger button.
  String get ledgerCorrectionExplain;

  /// The destructive FilledButton (red).
  String get correctTheLedger;

  /// breaks_panel.dart AsyncValueView emptyTitle.
  String get emptyBreaksTitle;

  /// breaks_panel.dart AsyncValueView emptyMessage.
  String get emptyBreaksMessage;

  /// breaks_panel.dart AsyncValueView loadingLabel.
  String get loadingBreaks;

  /// breaks_panel.dart emptyAction button.
  String get resetFilterAction;

  /// _BreakListSummary NoticeStrip.
  String get outstandingDriftNotice;

  /// breaks_panel.dart MetricTile label (rows fetched so far).
  String get metricLoaded;

  /// Loaded tile caption when hasMore.
  String get captionMoreAvailable;

  /// Loaded tile caption when the list is exhausted.
  String get captionAllOfThem;

  /// breaks_panel.dart MetricTile label.
  String get metricNeedAttention;

  /// Need attention tile caption when the count is above zero.
  String get captionSevereOrDrifting;

  /// Need attention tile caption when the count is zero.
  String get captionNothingUrgent;

  /// Line under the two metric tiles.
  String get breaksSortHint;

  /// _BreakListFooter LoadingStateView label.
  String get loadingMore;

  /// _BreakListFooter end marker.
  String get endOfList;

  /// Subtitle of the Agent float card.
  String get agentFloatSubtitle;

  /// Shown above the disabled Compare button.
  String floatSyncNeedsRole({required String roles});

  /// Compare button label while the POST is in flight.
  String get comparingFloat;

  /// Compare button idle label.
  String get compareFloatNow;

  /// LoadingStateView under the Agent float card.
  String get readingBothSides;

  /// EmptyStateView title before the first sync.
  String get noFloatReadingTitle;

  /// agent_float_panel.dart EmptyStateView message.
  String get noFloatReadingMessage;

  /// NoticeStrip when result.walletUnavailable.
  String get walletUnavailableNotice;

  /// NoticeStrip when result.belowWatermark. حد الأمان is the bot term. {basis}
  /// is watermarkBasisLedger or watermarkBasisWallet.
  String belowWatermarkNotice({required String amount, required String basis});

  /// {basis} of belowWatermarkNotice when the wallet is unavailable.
  String get watermarkBasisLedger;

  /// {basis} of belowWatermarkNotice on a successful read.
  String get watermarkBasisWallet;

  /// Reading card title. {time} is HH:mm:ss local, from AppDateFormats.
  String floatReadingAt({required String time});

  /// Reading card subtitle. {age} is the ageAgo phrase.
  String floatReadingSubtitle({required String currency, required String age});

  /// MetricTile label; the caption ICHANCY_AGENT_FLOAT stays Latin.
  String get metricOurLedger;

  /// agent_float_panel.dart MetricTile label.
  String get metricIchancyWallet;

  /// MoneyText placeholder for the Ichancy wallet tile.
  String get moneyUnavailable;

  /// Ichancy wallet tile caption. Verbatim from the bot low-float alert.
  String get captionAvailableBalance;

  /// The headline MetricTile. Glossary wording; every OTHER string on this
  /// surface writes Ichancy in Latin - flagged, not decided.
  String get driftMetricLabel;

  /// MoneyText placeholder on the drift tile when delta is null.
  String get moneyNotComputable;

  /// _driftCaption when the wallet read failed.
  String get driftCaptionWalletUnknown;

  /// _driftCaption when the delta is zero.
  String get driftCaptionExact;

  /// _driftCaption, positive delta.
  String get driftCaptionIchancyMore;

  /// _driftCaption, negative delta.
  String get driftCaptionLedgerMore;

  /// Card shown when the sync returned a breakId.
  String get breakOpenedTitle;

  /// Subtitle of the opened-break card.
  String get breakOpenedSubtitle;

  /// Button into BreakDetailScreen.
  String get openTheBreak;

  /// Shown instead of the opened-break card when the wallet was unavailable.
  String get noBreakWalletMissing;

  /// Shown instead of the opened-break card when the delta is zero.
  String get noBreakInAgreement;

  /// rail_ageing_panel.dart AsyncValueView emptyTitle.
  String get emptyRailAgeingTitle;

  /// rail_ageing_panel.dart AsyncValueView emptyMessage.
  String get emptyRailAgeingMessage;

  /// rail_ageing_panel.dart AsyncValueView loadingLabel.
  String get loadingRailAgeing;

  /// rail_ageing_panel.dart NoticeStrip. {codes} is a comma-joined list of
  /// account codes and stays Latin.
  String staleAccountsNotice({required int count, required String codes});

  /// Line above the account cards. {timestamp} is the timestampWithAge phrase.
  String railAgeingGeneratedAt({required String timestamp});

  /// Subtitle of each account card; the title is the raw account code.
  String railRowSubtitle({required String currency, required int count});

  /// StatusChip on an account with a positive 30d+ bucket.
  String get chipStale;

  /// rail_ageing_panel.dart MetricTile label.
  String get metricUnconfirmedBalance;

  /// MetricTile label; the value is an age phrase.
  String get metricOldestEntry;

  /// Oldest entry caption when oldestUnsettledAt is null.
  String get captionNoDatedEntries;

  /// Heading above the bucket strip.
  String get byAge;

  /// rail_ageing_panel.dart and BreakLinksView KeyValueRow (a UUID).
  String get ledgerAccountLabel;

  /// ledger_invariants_panel.dart card title.
  String get ledgerInvariantsTitle;

  /// ledger_invariants_panel.dart card subtitle.
  String get ledgerInvariantsSubtitle;

  /// Shown above the disabled Run button.
  String invariantsNeedRole({required String roles});

  /// Run button label while in flight.
  String get sweeping;

  /// Run button idle label.
  String get runTheSweep;

  /// Line under the Run button.
  String get sweepWarning;

  /// LoadingStateView while the sweep runs.
  String get loadingSweep;

  /// ledger_invariants_panel.dart EmptyStateView title.
  String get notSweptYetTitle;

  /// ledger_invariants_panel.dart EmptyStateView message.
  String get notSweptYetMessage;

  /// Card title on a clean sweep. Rooted in the bot "الحسابات مضبوطة".
  String get ledgerHealthyTitle;

  /// Body of the healthy card.
  String get ledgerHealthyBody;

  /// NoticeStrip above the violation list.
  String violationsFound({required int count});

  /// NoticeStrip when report.truncated.
  String get reportTruncatedNotice;

  /// Line above the violation cards.
  String sweptAt({required String timestamp});

  /// NoticeStrip inside an I1_SINGLE_SIDED violation card.
  String get entryCountsNoticeShort;

  /// KeyValueRow label built from LedgerInvariant.subjectKind (حركة / عملة /
  /// حساب / عنصر).
  String subjectIdLabel({required String subjectKind});

  /// Violation KeyValueRow.
  String get expectedLabel;

  /// Violation KeyValueRow.
  String get actualLabel;

  /// Violation KeyValueRow.
  String get differenceLabel;

  /// break_drift_view.dart fallback when all three money fields are null.
  String get noExpectedActualPair;

  /// break_drift_view.dart MetricTile label.
  String get metricLedgerExpected;

  /// Caption under Ledger (expected).
  String get captionOurBooks;

  /// break_drift_view.dart MetricTile label.
  String get metricObservedActual;

  /// Caption under Observed (actual).
  String get captionTheOtherSide;

  /// The headline signed delta tile.
  String get metricDifferenceActualExpected;

  /// _deltaCaption when delta is null.
  String get deltaCaptionOneSideMissing;

  /// _deltaCaption when delta is zero.
  String get deltaCaptionNoDifference;

  /// _deltaCaption, positive delta.
  String get deltaCaptionOtherSideMore;

  /// _deltaCaption, negative delta.
  String get deltaCaptionOurBooksMore;

  /// NoticeStrip in the I1_SINGLE_SIDED branch.
  String get entryCountsDriftNotice;

  /// MetricTile label, entry-count branch.
  String get metricEntriesRequired;

  /// MetricTile label, entry-count branch.
  String get metricEntriesFound;

  /// Explanation under the two count tiles.
  String entryCountsRawExplain({required String currency});

  /// break_evidence_view.dart empty detail blob.
  String get noDetectorEvidence;

  /// Heading above the bucket strip inside a break's evidence.
  String get ageingAtDetection;

  /// RailAgeingBucketStrip with an empty list.
  String get noEntriesInAnyBucket;

  /// break_evidence_view.dart bucket rows and ledger_invariant_report.dart
  /// expected/actual/delta labels for I1_SINGLE_SIDED.
  String entriesCount({required int count});

  /// BreakLinksView KeyValueRow (UUID).
  String get linkDepositRequest;

  /// BreakLinksView KeyValueRow (UUID).
  String get linkIchancyCall;

  /// BreakLinksView KeyValueRow (UUID of the AGENT_FLOAT_SYNC posting).
  String get linkCorrectionTransaction;

  /// BreakLinksView when every id is null.
  String get noLinkedRecords;

  /// NoticeStrip above the link rows. "بحاجة تدقيق" is the bot
  /// NEEDS_RECONCILIATION wording, used here on purpose.
  String get breakTouchesDepositNotice;

  /// Last line of BreakLinksView.
  String detectedAt({required String timestamp});

  /// BreakFilterSheet title.
  String get breakFilterSheetTitle;

  /// Line under the break filter sheet title.
  String get filterDefaultHint;

  /// break_filter_bar.dart chip group heading.
  String get filterCategoryHeading;

  /// Line under the Category heading.
  String get filterCategoryHint;

  /// break_filter_bar.dart chip group heading.
  String get filterMinSeverityHeading;

  /// DEDUPED: the break severity no-floor ChoiceChip and the payment-method
  /// active/disabled "All" chip.
  String get filterAll;

  /// break_filter_bar.dart sheet confirm button.
  String get filterDone;

  /// break_list_tile.dart headline of an I1_SINGLE_SIDED row instead of money.
  String tileEntriesOfEntries({required int actual, required int expected});

  /// break_list_tile.dart MoneyText placeholder when delta is null.
  String get moneyNoDifferenceRecorded;

  /// break_list_tile.dart last line of a re-opened row.
  String get tileReopenedNote;

  /// resolve_break_sheet.dart title.
  String get closeBreakSheetTitle;

  /// Line under the resolve sheet title.
  String get closeBreakSheetHint;

  /// resolve_break_sheet.dart TextField labelText.
  String get resolutionNoteLabel;

  /// resolve_break_sheet.dart TextField hintText.
  String get resolutionNoteHint;

  /// resolve_break_sheet.dart confirm button; {status} swaps with the radio.
  String closeAsStatus({required String status});

  /// reconciliation permission_denied_view.dart headline.
  String get deniedTitle;

  /// Shown when no role is signed in.
  String deniedSignedOut({required String action});

  /// Shown when the signed-in role is not allowed.
  String deniedRoleCannot({required String role, required String action});

  /// Last line of the reconciliation denial panel.
  String deniedAllowedRoles({required String roles});

  /// Default `action` value, used by the screen-level denial.
  String get deniedActionViewReconciliation;

  /// BreakStatus.open.label.
  String get breakStatusOpen;

  /// BreakStatus.investigating.label.
  String get breakStatusInvestigating;

  /// BreakStatus.resolved.label; also the default radio in ResolveBreakSheet.
  String get breakStatusResolved;

  /// BreakStatus.writtenOff.label.
  String get breakStatusWrittenOff;

  /// BreakStatus.falsePositive.label.
  String get breakStatusFalsePositive;

  /// BreakStatus.unknown.label - a client sentinel. The UI prints statusWire
  /// instead, so this is a safety net.
  String get breakStatusUnknown;

  /// Subtitle of the Resolved radio in ResolveBreakSheet.
  String get closingMeaningResolved;

  /// Subtitle of the Written off radio.
  String get closingMeaningWrittenOff;

  /// Subtitle of the False positive radio.
  String get closingMeaningFalsePositive;

  /// Unreachable today but shipped.
  String get closingMeaningNotClosing;

  /// BreakCategory.agentFloatMismatch.label (AGENT_FLOAT_MISMATCH).
  String get breakCategoryAgentFloatMismatch;

  /// BreakCategory.playerBalanceMismatch.label (no detector writes it).
  String get breakCategoryPlayerBalanceMismatch;

  /// BreakCategory.missingCredit.label.
  String get breakCategoryMissingCredit;

  /// BreakCategory.duplicateCredit.label.
  String get breakCategoryDuplicateCredit;

  /// BreakCategory.unidentifiedReceipt.label.
  String get breakCategoryUnidentifiedReceipt;

  /// BreakCategory.ledgerImbalance.label.
  String get breakCategoryLedgerImbalance;

  /// BreakCategory.orphanIchancyCall.label (no detector writes it).
  String get breakCategoryOrphanIchancyCall;

  /// BreakCategory.stuckDeposit.label (no detector writes it).
  String get breakCategoryStuckDeposit;

  /// BreakCategory.unknown.label - safety net; the UI prints categoryWire.
  String get breakCategoryUnknown;

  /// BreakSeverity.label(1).
  String get severity1;

  /// BreakSeverity.label(2).
  String get severity2;

  /// BreakSeverity.label(3).
  String get severity3;

  /// BreakSeverity.label(4).
  String get severity4;

  /// BreakSeverity.label(5). Avoids النقص, bound to the below-watermark
  /// shortfall in the bot.
  String get severity5;

  /// BreakSeverity.shortLabel - the dense chip. Stays Latin.
  String severityShort({required int n});

  /// BreakDetail.stringify - a JSON array in the evidence blob.
  String detailValueItems({required int count});

  /// BreakDetail.stringify - a nested JSON object in the evidence blob.
  String detailValueFields({required int count});

  /// BreakFilter.describe() when nothing is narrowed.
  String get filterDescribeDefault;

  /// BreakFilter.describe() severity facet. {severity} is S1..S5.
  String filterDescribeSeverity({required String severity});

  /// BreakDetail evidence key `ichancyAvailable`. Replaces the runtime
  /// humanizeKey() transform - fall back to the raw key for unknown ones.
  String get evidenceIchancyAvailable;

  /// BreakDetail evidence key `ichancyBalance`.
  String get evidenceIchancyBalance;

  /// BreakDetail evidence key `ledger`.
  String get evidenceLedger;

  /// BreakDetail evidence key `delta`.
  String get evidenceDelta;

  /// BreakDetail evidence key `accountCode`. The value stays Latin.
  String get evidenceAccountCode;

  /// BreakDetail evidence key `oldestUnsettledAt`.
  String get evidenceOldestUnsettledAt;

  /// BreakDetail evidence key `subject`.
  String get evidenceSubject;

  /// BreakDetail evidence key `truncated`.
  String get evidenceTruncated;

  /// BreakDetail evidence key `invariant`.
  String get evidenceInvariant;

  /// LedgerInvariant.transactionZeroSum.label.
  String get invariantI1TransactionZeroSum;

  /// Violation card subtitle.
  String get invariantI1TransactionZeroSumExplain;

  /// LedgerInvariant.singleSided.label.
  String get invariantI1SingleSided;

  /// Violation card subtitle.
  String get invariantI1SingleSidedExplain;

  /// LedgerInvariant.globalZeroSum.label.
  String get invariantI2GlobalZeroSum;

  /// Violation card subtitle.
  String get invariantI2GlobalZeroSumExplain;

  /// LedgerInvariant.accountBalanceMatchesEntries.label.
  String get invariantI3CachedBalanceDrift;

  /// Violation card subtitle.
  String get invariantI3CachedBalanceDriftExplain;

  /// LedgerInvariant.unknown.label - safety net; the card prints invariantWire.
  String get invariantUnknown;

  /// Violation card subtitle for an unknown invariant.
  String get invariantUnknownExplain;

  /// LedgerInvariant.subjectKind for I1; interpolated into subjectIdLabel.
  String get subjectKindTransaction;

  /// LedgerInvariant.subjectKind for I2.
  String get subjectKindCurrency;

  /// LedgerInvariant.subjectKind for I3.
  String get subjectKindAccount;

  /// LedgerInvariant.subjectKind fallback for an unknown invariant.
  String get subjectKindSubject;

  /// RailAgeingReport.knownLabels chip. The wire value arrives from the API, so
  /// translating means mapping it on render.
  String get bucket0to1d;

  /// RailAgeingReport.knownLabels chip.
  String get bucket1to3d;

  /// RailAgeingReport.knownLabels chip.
  String get bucket3to7d;

  /// RailAgeingReport.knownLabels chip.
  String get bucket7to30d;

  /// The open-ended bucket, rendered in the reject tone.
  String get bucket30dPlus;

  /// reconciliation_repository.dart assign() success snackbar.
  String get actionAssignedToYou;

  /// reconciliation_repository.dart resolve() success snackbar.
  String actionClosedAsStatus({required String status});

  /// resolve() local guard. The three names must stay identical to the
  /// breakStatus* labels.
  String get actionOnlyTerminalStatuses;

  /// reconciliation_repository.dart resolve() local guard.
  String get resolutionNoteRequired;

  /// reconciliation_repository.dart correctFloat() local guard.
  String get correctionNoteRequired;

  /// BreakActionAlreadyClosed.userMessage with no status detail.
  String get breakAlreadyClosedByOther;

  /// BreakActionAlreadyClosed.userMessage with details.status.
  String breakAlreadyClosedAsStatus({required String status});

  /// BreakActionMissing.userMessage - 404 on assign or resolve.
  String get breakNoLongerExists;

  /// CorrectFloatPosted.userMessage - the one action that moves money. {amount}
  /// is Money.format(alwaysShowSign: true).
  String correctionPosted({required String amount});

  /// CorrectFloatAlreadyResolved.userMessage - 422 BREAK_ALREADY_RESOLVED.
  String get correctionAlreadyResolved;

  /// CorrectFloatNothingToCorrect.userMessage - 422 NOTHING_TO_CORRECT.
  String get correctionNothingToCorrect;

  /// CorrectFloatFailed.userMessage for an opaque INTERNAL_ERROR. {reference}
  /// is the correlation id, or correlationIdFallback.
  String ledgerRefusedCorrection({required String reference});

  /// Substituted for {reference} when the server sent no correlation id.
  String get correlationIdFallback;

  /// break_detail_controller.dart assign() local guard.
  String assignWouldReopen({required String status});

  /// break_detail_controller.dart correctFloat() guard.
  String get breakStillLoading;

  /// break_detail_controller.dart correctFloat() guard.
  String get onlyFloatMismatchCorrectable;

  /// The re-entrancy guard on both correctFloat() and _run().
  String get anotherActionRunning;

  /// payment_methods_screen.dart AppBar title. Plural list form.
  String get pmScreenTitle;

  /// payment_methods_screen.dart FAB label.
  String get pmNewMethodButton;

  /// payment_methods_screen.dart PermissionDeniedView message.
  String get pmReadersDeniedMessage;

  /// Empty state title, unfiltered.
  String get pmEmptyTitle;

  /// Empty state title, filtered.
  String get pmFilterEmptyTitle;

  /// Empty message for a manager role.
  String get pmEmptyMessageManager;

  /// Empty message for a read-only role.
  String get pmEmptyMessageReader;

  /// Empty message when filtered.
  String get pmFilterEmptyMessage;

  /// payment_methods_screen.dart loading label.
  String get pmLoadingList;

  /// DEDUPED: the list ChoiceChip, AdminPaymentMethodView.statusLabel and the
  /// form SwitchListTile title. FEMININE (طريقة) - not pdStatusActive.
  String get pmStatusActive;

  /// DEDUPED: the list ChoiceChip and AdminPaymentMethodView.statusLabel.
  /// FEMININE (طريقة).
  String get pmStatusDisabled;

  /// payment_methods_screen.dart PopupMenuButton tooltip.
  String get pmFilterRailTooltip;

  /// Rail menu item and chip fallback.
  String get pmFilterEveryRail;

  /// payment_method_detail_screen.dart AppBar title. Single record = وسيلة.
  String get pmDetailTitle;

  /// payment_method_detail_screen.dart loading label.
  String get pmLoadingMethod;

  /// InfoBanner title.
  String pmNoDriverTitle({required String rail});

  /// payment_method_detail_screen.dart InfoBanner message.
  String get pmNoDriverMessage;

  /// SectionCard title.
  String get pmRecordSection;

  /// Record row label.
  String get pmIdentifierLabel;

  /// Identifier hint.
  String get pmIdentifierHint;

  /// Record row label.
  String get pmLastUpdatedLabel;

  /// Last updated hint.
  String get pmLastUpdatedHint;

  /// _HeaderCard subtitle.
  String pmHeaderSubtitle({required String rail, required String currency});

  /// Detail row, form field and payment_method_rules labelForField("code").
  String get pmMachineCodeLabel;

  /// Machine code hint.
  String get pmMachineCodeHint;

  /// Detail row, form dropdown and labelForField("rail"). Deliberately NOT قناة
  /// الدفع - that would collide with طرق الدفع.
  String get pmRailLabel;

  /// Hint on the Rail and Currency rows.
  String get pmImmutableAfterCreationHint;

  /// DEDUPED: the payment-method row/field and the approval-ceiling form field.
  String get currencyLabel;

  /// Detail row, form field and labelForField("sortOrder").
  String get pmSortOrderLabel;

  /// DEDUPED: the method header button, the destination card and both confirm
  /// sheets.
  String get enableButton;

  /// DEDUPED: the method header button, the destination card and both confirm
  /// sheets.
  String get disableButton;

  /// ConfirmActionSheet title.
  String pmEnableMethodTitle({required String name});

  /// ConfirmActionSheet title.
  String pmDisableMethodTitle({required String name});

  /// Enable confirm message.
  String get pmEnableMethodMessage;

  /// Disable confirm message.
  String get pmDisableMethodMessage;

  /// SectionCard title on both the detail and the form.
  String get pmLimitsSection;

  /// _LimitsCard subtitle.
  String get pmLimitsSubtitle;

  /// Limits row.
  String get pmMinimumLabel;

  /// Minimum hint.
  String get pmMinimumHint;

  /// Limits row.
  String get pmMaximumLabel;

  /// Maximum hint.
  String get pmMaximumHint;

  /// Detail row, form field and labelForField("feeFixed").
  String get pmFixedFeeLabel;

  /// Fixed fee hint.
  String get pmFixedFeeHint;

  /// Limits row.
  String get pmVariableFeeLabel;

  /// Variable fee value.
  String pmVariableFeeValue({required int bps, required String percent});

  /// Variable fee hint.
  String get pmVariableFeeHint;

  /// Computed row.
  String get pmFeeAtMinimumLabel;

  /// Computed row. شحن is the credit verb.
  String get pmCreditedAtMinimumLabel;

  /// Hint when positive.
  String get pmCreditedAtMinimumHintOk;

  /// Hint when zero or negative.
  String get pmCreditedAtMinimumHintBad;

  /// Computed row.
  String get pmFeeAtMaximumLabel;

  /// SectionCard title.
  String get pmVerificationSection;

  /// Verification row label.
  String get pmVerificationModeRowLabel;

  /// Mode hint.
  String get pmVerificationModeHint;

  /// DEDUPED: the payment-method verification row, the Reference SectionCard
  /// title and RailProofField.reference.label. NOT the bare المرجع - that is
  /// bound to the deposit shortId in the bot.
  String get referenceLabel;

  /// Reference value.
  String get pmReferenceRequiredValue;

  /// Reference value.
  String get pmReferenceOptionalValue;

  /// Reference hint when the toggle is moot. {state} is pmStatusActive or
  /// pmStatusDisabled.
  String pmReferenceMootHint({required String rail, required String state});

  /// Reference hint otherwise.
  String get pmReferenceSwitchHint;

  /// Detail row and labelForField("referencePattern").
  String get pmReferencePatternRowLabel;

  /// Reference pattern value when unset.
  String get noneLabel;

  /// Hint when a pattern exists.
  String get pmReferencePatternHint;

  /// Hint when no pattern.
  String get pmReferencePatternNoneHint;

  /// Caption above the proof chips.
  String get pmProofFieldsIntro;

  /// Empty proof list.
  String get pmProofFieldsNone;

  /// InfoBanner title.
  String get pmPatternBrokenTitle;

  /// InfoBanner message. {error} is raw engine text, not translated.
  String pmPatternBrokenMessage({required String error});

  /// InfoBanner title.
  String get pmHumanCheckedTitle;

  /// InfoBanner message with bullets.
  String get pmHumanCheckedMessage;

  /// SectionCard title on both the detail and the form.
  String get pmInstructionsSection;

  /// _InstructionsCard subtitle.
  String get pmInstructionsSubtitle;

  /// Empty instructions.
  String get pmInstructionsEmpty;

  /// Destinations section heading. حساب الاستلام is a coinage - no bot root.
  String get pmDestinationsHeading;

  /// Destinations toggle.
  String get pmHideDisabled;

  /// Destinations toggle.
  String get pmShowAll;

  /// Caption under the destinations heading.
  String get pmDestinationsOrderNote;

  /// LoadingStateView label.
  String get pmLoadingDestinations;

  /// OutlinedButton label.
  String get pmAddDestination;

  /// InfoBanner title.
  String get pmNoDestinationsTitle;

  /// InfoBanner message.
  String get pmNoDestinationsMessage;

  /// InfoBanner title.
  String get pmDisabledHiddenTitle;

  /// InfoBanner message.
  String get pmDisabledHiddenMessage;

  /// InfoBanner title.
  String get pmNoActiveDestinationTitle;

  /// InfoBanner message.
  String get pmNoActiveDestinationMessage;

  /// Destination confirm title.
  String pdEnableTitle({required String label});

  /// Destination confirm title.
  String pdDisableTitle({required String label});

  /// Destination enable confirm.
  String get pdEnableMessage;

  /// Destination disable confirm, last active.
  String get pdDisableLastMessage;

  /// Destination disable confirm, normal.
  String get pdDisableMessage;

  /// AppBar title, edit mode.
  String get pmFormEditTitle;

  /// AppBar title, create mode.
  String get pmFormCreateTitle;

  /// PermissionDeniedView title.
  String get pmManagersDeniedTitle;

  /// PermissionDeniedView message.
  String get pmManagersDeniedMessage;

  /// Local issues banner title on both forms.
  String get pmFixBeforeSaving;

  /// SectionCard title.
  String get pmIdentitySection;

  /// Identity subtitle, edit mode.
  String get pmIdentitySubtitleEdit;

  /// Identity subtitle, create mode.
  String get pmIdentitySubtitleCreate;

  /// Code field helper.
  String get pmMachineCodeHelper;

  /// Rail dropdown helper.
  String get pmRailHelper;

  /// Currency field helper. {currency} is a code such as NSP, never translated.
  String pmCurrencyHelper({required String currency});

  /// DEDUPED: the payment-method form field, labelForField("displayName") and
  /// the admin form field / profile row.
  String get displayNameLabel;

  /// Display name helper.
  String get pmDisplayNameHelper;

  /// Form dropdown label and labelForField("verificationMode").
  String get pmVerificationModeLabel;

  /// Verification dropdown helper.
  String get pmVerificationModeHelper;

  /// Sort order helper.
  String get pmSortOrderHelper;

  /// Active switch subtitle when on.
  String get pmActiveSwitchOn;

  /// Active switch subtitle when off.
  String get pmActiveSwitchOff;

  /// Caption above the rail proof chips on the form.
  String get pmProofFieldsPreview;

  /// Limits section subtitle on the form.
  String get pmLimitsFormSubtitle;

  /// Form field and labelForField("minAmount").
  String get pmMinAmountLabel;

  /// minAmount helper tail.
  String get pmMinAmountHelper;

  /// Form field and labelForField("maxAmount").
  String get pmMaxAmountLabel;

  /// maxAmount helper tail.
  String get pmMaxAmountHelper;

  /// feeFixed helper tail.
  String get pmFeeFixedHelper;

  /// feeBps field label.
  String get pmFeeBpsLabel;

  /// feeBps helper.
  String get pmFeeBpsHelper;

  /// _moneyHelper prefix. {value} is a decimal string with Western digits.
  String pmMoneyWillBeSent({required String value});

  /// Live credit preview.
  String pmCreditPreview({required String min, required String fee, required String credited});

  /// Warning under the credit preview.
  String get pmCreditsNothingWarning;

  /// SwitchListTile title and labelForField("requiresReference").
  String get pmRequiresReferenceSwitch;

  /// Switch subtitle when the rail demands it.
  String pmRequiresReferenceOnRail({required String rail});

  /// Switch subtitle otherwise.
  String get pmRequiresReferenceHint;

  /// Pattern field label.
  String get pmReferencePatternFieldLabel;

  /// Pattern field helper.
  String get pmReferencePatternFieldHelper;

  /// Warning banner title.
  String get pmPatternMayNotWorkTitle;

  /// Probe field label.
  String get pmProbeLabel;

  /// Probe helper before typing.
  String get pmProbeIdleHelper;

  /// Probe helper on match.
  String get pmProbeAccepted;

  /// Probe helper on no match.
  String get pmProbeRejected;

  /// InfoBanner title, edit mode.
  String get pmPatternCannotClearTitle;

  /// InfoBanner message.
  String get pmPatternCannotClearMessage;

  /// Instructions section subtitle on the form.
  String get pmInstructionsFormSubtitle;

  /// Instructions helper.
  String get pmInstructionsFieldHelper;

  /// Local FieldIssue on minAmount.
  String get pmBothLimitsRequired;

  /// AppBar title, edit mode.
  String get pdFormEditTitle;

  /// AppBar title, create mode.
  String get pdFormCreateTitle;

  /// PermissionDeniedView title.
  String get pdManagersDeniedTitle;

  /// PermissionDeniedView message.
  String get pdManagersDeniedMessage;

  /// Crypto InfoBanner title.
  String get pdCryptoChainTitle;

  /// Crypto InfoBanner message. The literal "Network:" prefix is what the
  /// player message prints and stays Latin.
  String pdCryptoChainMessage({required String label});

  /// Account section subtitle.
  String get pdAccountSubtitle;

  /// Rail-dependent label field. {caption} is one of the destCaption* keys.
  String pdLabelFieldLabel({required String caption});

  /// accountIdentifier helper on create.
  String get pdAccountIdentifierHelper;

  /// Read-only accountIdentifier hint on edit.
  String get pdAccountIdentifierImmutableHint;

  /// Live InfoBanner title.
  String get pdPlaceholderTypedTitle;

  /// Live InfoBanner message.
  String get pdPlaceholderTypedMessage;

  /// Helper on crypto.
  String pdAccountHolderIgnoredHelper({required String rail});

  /// Helper on other rails.
  String get pdAccountHolderHelper;

  /// DEDUPED: the destination card StatusChip and the form SwitchListTile
  /// title. MASCULINE (حساب) - not pmStatusActive.
  String get pdStatusActive;

  /// Destination card StatusChip. MASCULINE (حساب).
  String get pdStatusDisabled;

  /// Active switch subtitle when on.
  String get pdActiveSwitchOn;

  /// Active switch subtitle when off.
  String get pdActiveSwitchOff;

  /// SectionCard title.
  String get pdRoutingSection;

  /// Routing subtitle.
  String get pdRoutingSubtitle;

  /// Form field and labelForField("priority").
  String get pdPriorityLabel;

  /// Priority helper.
  String get pdPriorityHelper;

  /// dailyCap field label; labelForField("dailyCap") is the bare السقف اليومي.
  String pdDailyCapLabel({required String currency});

  /// dailyCap helper when empty.
  String get pdDailyCapHelper;

  /// dailyCap helper when parsed.
  String pdDailyCapHelperParsed({required String value});

  /// InfoBanner title.
  String get pdCapCannotBeRemovedTitle;

  /// InfoBanner message.
  String get pdCapCannotBeRemovedMessage;

  /// DEDUPED: the destination Notes SectionCard title, the field label and
  /// labelForField("notes").
  String get notesLabel;

  /// Notes section subtitle.
  String get pdNotesSubtitle;

  /// Notes helper.
  String get pdNotesHelper;

  /// payment_method_rules.dart labelForField("dailyCap") - no currency suffix.
  String get pdDailyCapFieldLabel;

  /// PaymentRail.bankTransfer.label.
  String get railBankTransfer;

  /// PaymentRail.mobileWallet.label.
  String get railMobileWallet;

  /// PaymentRail.cashOffice.label.
  String get railCashOffice;

  /// PaymentRail.crypto.label.
  String get railCrypto;

  /// PaymentRail.internal.label - read-only rows only.
  String get railInternal;

  /// destinationLabelCaption for BANK_TRANSFER; also the card heading.
  String get destCaptionBank;

  /// destinationLabelCaption for MOBILE_WALLET.
  String get destCaptionWallet;

  /// destinationLabelCaption for CASH_OFFICE.
  String get destCaptionOffice;

  /// DEDUPED: destinationLabelCaption for CRYPTO (the chain name) and
  /// RailProofField.network.label.
  String get networkLabel;

  /// destinationLabelCaption for INTERNAL and labelForField("label").
  String get destCaptionLabel;

  /// destinationLabelHint for BANK_TRANSFER.
  String get destHintBank;

  /// destinationLabelHint for MOBILE_WALLET.
  String get destHintWallet;

  /// destinationLabelHint for CASH_OFFICE.
  String get destHintOffice;

  /// destinationLabelHint for CRYPTO.
  String get destHintCrypto;

  /// destinationLabelHint for INTERNAL.
  String get destHintInternal;

  /// accountIdentifierCaption for BANK_TRANSFER.
  String get accountCaptionBank;

  /// accountIdentifierCaption for MOBILE_WALLET.
  String get accountCaptionWallet;

  /// accountIdentifierCaption for CASH_OFFICE.
  String get accountCaptionOffice;

  /// accountIdentifierCaption for CRYPTO.
  String get accountCaptionCrypto;

  /// accountIdentifierCaption for INTERNAL and
  /// labelForField("accountIdentifier").
  String get accountCaptionInternal;

  /// VerificationMode.manualProof.label.
  String get verificationManualProof;

  /// VerificationMode.referenceMatch.label.
  String get verificationReferenceMatch;

  /// VerificationMode.autoStatement.label.
  String get verificationAutoStatement;

  /// VerificationMode.none.label. NOT noneLabel - different Arabic.
  String get verificationNone;

  /// RailProofField.senderName.label.
  String get proofFieldSenderName;

  /// RailProofField.receiptImage.label. The bot proof word is الإيصال.
  String get proofFieldReceiptImage;

  /// RailProofField.txHash.label.
  String get proofFieldTxHash;

  /// payment_method_rules.dart validateCode.
  String get pmCodeRequired;

  /// payment_method_rules.dart validateCode.
  String get pmCodeMalformed;

  /// payment_method_rules.dart validateCurrency.
  String get pmCurrencyInvalid;

  /// payment_method_rules.dart validateDisplayName.
  String get pmDisplayNameRequired;

  /// payment_method_rules.dart validateDestinationLabel.
  String get pmDestLabelRequired;

  /// payment_method_rules.dart validateAccountIdentifier.
  String get pmAccountIdentifierRequired;

  /// payment_method_rules.dart _validateText length branch.
  String pmKeepUnderChars({required int max});

  /// validateAccountHolder.
  String pmAccountHolderTooLong({required int max});

  /// validateNotes.
  String pmNotesTooLong({required int max});

  /// validateInstructions.
  String pmInstructionsTooLong({required int max});

  /// validateFeeBps.
  String pmFeeBpsRange({required int max});

  /// validatePriority.
  String get pmPriorityNegative;

  /// validateReferencePattern.
  String pmPatternTooLong({required int max});

  /// referencePatternWarning. {error} is engine text.
  String pmPatternWarning({required String error});

  /// validateAmounts.
  String get pmMinNotPositive;

  /// DEDUPED: payment_method_rules.dart validateAmounts and
  /// ApprovalLimitProblem.currencyMismatch.
  String get pmAmountsCurrencyMismatch;

  /// validateAmounts.
  String get pmMaxBelowMin;

  /// validateAmounts.
  String get pmFeeNegative;

  /// validateAmounts.
  String get pmFeeNotBelowMin;

  /// validateIntegerInput - empty and unparseable.
  String get pmIntegerRequired;

  /// validateIntegerInput.
  String pmIntegerMin({required int min});

  /// validateIntegerInput.
  String pmIntegerMax({required int max});

  /// labelForField("feeBps") - prefix on a server field error.
  String get pmFieldLabelFeeBps;

  /// DEDUPED: the bullets on both payment forms and
  /// MutationFailure._validationMessage.
  String fieldIssuePrefix({required String field, required String message});

  /// payment_method_actions.dart createMethod success.
  String pmCreatedToast({required String name});

  /// payment_method_actions.dart updateMethod success.
  String pmSavedToast({required String name});

  /// setMethodActive success.
  String pmEnabledToast({required String name});

  /// setMethodActive success.
  String pmDisabledToast({required String name});

  /// createDestination success.
  String pdAddedToast({required String label});

  /// updateDestination success.
  String pdSavedToast({required String label});

  /// setDestinationActive success.
  String pdEnabledToast({required String label});

  /// setDestinationActive success.
  String pdDisabledToast({required String label});

  /// MutationFailure - PAYMENT_METHOD_ALREADY_EXISTS.
  String get pmCodeConflict;

  /// MutationFailure - DESTINATION_ALREADY_EXISTS.
  String get pdConflict;

  /// MutationFailure - RAIL_NOT_SUPPORTED.
  String get pmRailNotSupported;

  /// MutationFailure - DESTINATION_NOT_FOUND.
  String get pdNotFound;

  /// MutationFailure - 404 fallback.
  String get pmNotFound;

  /// mutation_feedback.dart _failureSnackBar diagnostic line. Never translated.
  String pmFailureReference({required String code, required String correlationId});

  /// payment_method_tile.dart StatusChip.
  String get pmNoDriverChip;

  /// payment_method_tile.dart StatusChip from the placeholder audit.
  String get pmPlaceholderChip;

  /// Caption before the min-max money pair.
  String get pmLimitsChipLabel;

  /// payment_destination_card.dart StatusChip.
  String pdPriorityChip({required int priority});

  /// payment_destination_card.dart StatusChip.
  String pdSoftCapChip({required String amount});

  /// payment_destination_card.dart StatusChip on crypto.
  String get pdHolderIgnoredChip;

  /// payment_destination_card.dart StatusChip.
  String pdHolderChip({required String holder});

  /// Caption above the notes text.
  String get pdNotesAppendedNote;

  /// PlaceholderAuditBanner title - list-wide.
  String get pmAuditBannerTitle;

  /// PlaceholderAuditBanner message.
  String pmAuditBannerMessage({required int rows, required int methods});

  /// PlaceholderDestinationBanner title.
  String get pmDormantPlaceholderTitle;

  /// PlaceholderDestinationBanner message.
  String pmDormantPlaceholderMessage({required int count});

  /// PlaceholderDestinationBanner title.
  String get pmLivePlaceholderTitle;

  /// PlaceholderDestinationBanner message. The bullets are "{label} -
  /// {accountIdentifier}" and are not translated.
  String get pmLivePlaceholderMessage;

  /// PlaceholderBadge on an active row.
  String get pdPlaceholderBadgeLive;

  /// PlaceholderBadge on a disabled row.
  String get pdPlaceholderBadge;

  /// placeholderReasons. {prefix} is SEED-PLACEHOLDER, not translated.
  String pdReasonSeedPrefix({required String prefix});

  /// placeholderReasons.
  String get pdReasonMarker;

  /// placeholderReasons.
  String get pdReasonHolder;

  /// placeholderReasons.
  String get pdReasonNotes;

  /// payment_methods permission_denied_view.dart default title.
  String get pmPermissionDeniedTitle;

  /// Default message. {roles} is a comma-joined list of role labels.
  String pmPermissionDeniedMessage({required String roles, required String role});

  /// Fallback when there is no session.
  String get pmNoRole;

  /// admin_users_screen.dart AppBar title.
  String get auScreenTitle;

  /// admin_users_screen.dart FAB label and the create-mode submit label.
  String get auAddButton;

  /// admin_users_screen.dart search field hintText.
  String get auSearchHint;

  /// admin_users_screen.dart search field helperText.
  String get auSearchHelper;

  /// admin_users_screen.dart suffix IconButton tooltip.
  String get auClearSearchTooltip;

  /// admin_users_screen.dart activity ChoiceChip.
  String get auFilterEveryone;

  /// DEDUPED: the directory ChoiceChip, AdminUserView.statusLabel and the admin
  /// form switch title. An ADMINISTRATOR is نشط - not pm/pdStatusActive.
  String get auStatusActive;

  /// DEDUPED: the directory ChoiceChip and AdminUserView.statusLabel.
  String get auStatusDeactivated;

  /// role_selector.dart RoleFilterBar FilterChip.
  String get auAllRoles;

  /// RoleSelector heading and the detail/profile row label.
  String get auRoleFieldLabel;

  /// admin_users_screen.dart empty state title.
  String get auEmptyTitle;

  /// Empty state message. {filter} is AdminUsersFilter.describe().
  String auEmptyMessage({required String filter});

  /// admin_users_screen.dart loading label.
  String get auLoadingDirectory;

  /// Client-side search empty state.
  String get auNoSearchMatchTitle;

  /// Search empty message.
  String auNoSearchMatchMessage({required int count, required String query});

  /// Search empty message tail when hasMore.
  String get auScrollToLoadMore;

  /// Search empty message tail when fully loaded.
  String get auClearSearchToSeeAll;

  /// admin_labels.dart countOf - directory footer.
  String auCountShownOfTotal({required int shown, required int total});

  /// admin_labels.dart countOf when everything is shown.
  String auCountTotal({required int total});

  /// admin_users_screen.dart footer line.
  String auActiveSuperAdmins({required int count});

  /// Footer suffix when exactly one super admin remains. Appended to
  /// auActiveSuperAdmins.
  String get auLastWayBack;

  /// AdminUsersFilter.describe() default.
  String get auFilterDescribeAll;

  /// AdminUsersFilter.describe().
  String get auFilterActiveOnly;

  /// AdminUsersFilter.describe().
  String get auFilterDeactivatedOnly;

  /// AdminUsersFilter.describe().
  String auFilterMatching({required String query});

  /// admin_user_detail_screen.dart AppBar title before the row loads.
  String get auDetailFallbackTitle;

  /// admin_user_detail_screen.dart loading label.
  String get auLoadingAdministrator;

  /// admin_user_detail_screen.dart DetailSection title. NOT pmIdentitySection
  /// (التعريف) - different surface, different Arabic.
  String get auIdentitySection;

  /// admin_user_detail_screen.dart DetailRow label.
  String get auUsernameLabel;

  /// admin_user_detail_screen.dart DetailRow label.
  String get auRowIdLabel;

  /// admin_user_detail_screen.dart DetailSection title.
  String get auAuthoritySection;

  /// admin_user_detail_screen.dart DetailRow label. NOT createdLabel (تاريخ
  /// الإنشاء) - a person is added, a record is created.
  String get auCreatedRowLabel;

  /// admin_user_detail_screen.dart DetailRow label.
  String get auLastSignInLabel;

  /// Last sign-in value.
  String get auNeverSignedInValue;

  /// Created / Last sign-in / Expires values on the detail and profile screens.
  String auTimestampWithRelative({required String timestamp, required String relative});

  /// DetailSection title and approval_limits_screen.dart AppBar title.
  String get alCeilingsSection;

  /// Ceilings section body.
  String get alCeilingsIntro;

  /// admin_user_detail_screen.dart FilledButton.tonalIcon label.
  String get alOpenCeilingsButton;

  /// StatusChip on your own row.
  String get auYouChip;

  /// Detail button, confirm label and AdminMutationAction.deactivate.label.
  String get auDeactivateButton;

  /// Detail button, confirm label and AdminMutationAction.reactivate.label.
  String get auReactivateButton;

  /// ConfirmActionSheet title.
  String auDeactivateConfirmTitle({required String name});

  /// ConfirmActionSheet message.
  String get auDeactivateConfirmMessage;

  /// ConfirmActionSheet title.
  String auReactivateConfirmTitle({required String name});

  /// ConfirmActionSheet message.
  String auReactivateConfirmMessage({required String role});

  /// admin_user_tile.dart subtitle when there is no username.
  String auTileIdOnly({required String id});

  /// admin_user_tile.dart subtitle with a username.
  String auTileHandleAndId({required String handle, required String id});

  /// admin_user_tile.dart subtitle second line.
  String auTileLastSignIn({required String relative});

  /// admin_user_tile.dart subtitle second line.
  String get auTileNeverSignedIn;

  /// AppBar title.
  String get auFormEditTitle;

  /// AppBar title and AdminMutationAction.create.label.
  String get auFormCreateTitle;

  /// Display name helper.
  String get auDisplayNameHelper;

  /// Username field label; the "@" prefix is literal.
  String get auUsernameFieldLabel;

  /// Username helper.
  String get auUsernameHelper;

  /// _TelegramIdField label.
  String get auTelegramIdFieldLabel;

  /// Helper in edit mode.
  String get auTelegramIdHelperLocked;

  /// Helper in create mode.
  String get auTelegramIdHelper;

  /// RoleSelector disabledReason.
  String get auRoleSelfLocked;

  /// Active switch subtitle when on.
  String auActiveOn({required String role});

  /// Active switch subtitle when off.
  String get auActiveOff;

  /// Note under the Active switch.
  String get auCannotDeactivateSelf;

  /// Submit label and AdminMutationAction.update.label.
  String get auSaveChanges;

  /// _BlockedBanner fallback when the gate has no reason.
  String get auChangeNotAllowed;

  /// Info snackbar on an empty patch.
  String get auNothingChanged;

  /// FAB, form submit and ApprovalLimitAction.set.label.
  String get alSetCeilingButton;

  /// approval_limits_screen.dart empty state title.
  String get alEmptyTitle;

  /// approval_limits_screen.dart empty state message.
  String get alEmptyMessage;

  /// approval_limits_screen.dart loading label.
  String get alLoadingHistory;

  /// Banner title for a non-approver role.
  String alRoleMayNeverApproveTitle({required String role});

  /// approval_limits_screen.dart banner message.
  String get alRoleMayNeverApproveMessage;

  /// approval_limits_screen.dart footer note.
  String get alVersioningNote;

  /// Per-currency StatusChip.
  String get alNoActiveChip;

  /// Chip and ApprovalLimit.statusLabel.
  String get alInForceChip;

  /// ApprovalLimit.statusLabel - chip on an old version.
  String get alSupersededChip;

  /// Message under a currency block with no active version.
  String alNoActiveMessage({required String currency});

  /// Money row label.
  String get alSingleApprovalLabel;

  /// Money row label.
  String get alDailyBudgetLabel;

  /// Row label when the global threshold is inherited.
  String get alSecondApprovalLabel;

  /// Value for an inherited threshold.
  String get alInheritsGlobal;

  /// Money row label for an override.
  String get alSecondApprovalAboveLabel;

  /// Row label on a superseded version.
  String get alEndedLabel;

  /// Action on the version in force.
  String get alReplaceButton;

  /// Action on the version in force.
  String get alEndCeilingButton;

  /// ConfirmActionSheet title.
  String alEndConfirmTitle({required String currency});

  /// ConfirmActionSheet message.
  String get alEndConfirmMessage;

  /// confirmLabel and ApprovalLimitAction.end.label.
  String get alEndConfirmLabel;

  /// approval_limit_form_screen.dart AppBar title.
  String get alFormTitle;

  /// approval_limit_form_screen.dart heading.
  String alFormHeading({required String name});

  /// approval_limit_form_screen.dart intro paragraph.
  String get alFormIntro;

  /// Currency helper.
  String get alCurrencyHelper;

  /// MoneyAmountField label.
  String get alMaxSingleLabel;

  /// approval_limit_form_screen.dart helper.
  String get alMaxSingleHelper;

  /// MoneyAmountField label.
  String get alMaxDailyLabel;

  /// approval_limit_form_screen.dart helper.
  String get alMaxDailyHelper;

  /// MoneyAmountField label.
  String get alSecondAboveLabel;

  /// approval_limit_form_screen.dart helper.
  String get alSecondAboveHelper;

  /// _validateCurrency. {currency} is a code such as NSP.
  String alCurrencyThreeLetters({required String currency});

  /// approval_limit_form_screen.dart refusal snackbar.
  String get alAmountNotNumber;

  /// ApprovalLimitProblem.singleNotPositive.
  String get alSingleNotPositive;

  /// ApprovalLimitProblem.dailyNotPositive.
  String get alDailyNotPositive;

  /// ApprovalLimitProblem.singleAboveDaily.
  String get alSingleAboveDaily;

  /// ApprovalLimitProblem.secondApprovalNegative.
  String get alSecondNegative;

  /// admin_profile_view.dart AppBar title - the Settings destination.
  String get profileTitle;

  /// admin_profile_view.dart IconButton tooltip.
  String get profileRefreshTooltip;

  /// admin_profile_view.dart EmptyStateView title.
  String get profileNotSignedInTitle;

  /// admin_profile_view.dart EmptyStateView message.
  String get profileNotSignedInMessage;

  /// admin_profile_view.dart StatusChip.
  String profileSessionExpiresChip({required String relative});

  /// admin_profile_view.dart DetailSection title.
  String get profileSignedInAsSection;

  /// admin_profile_view.dart DetailRow label.
  String get profileAdminIdLabel;

  /// admin_profile_view.dart DetailRow label.
  String get profileIssuedLabel;

  /// admin_profile_view.dart DetailRow label.
  String get profileExpiresLabel;

  /// admin_profile_view.dart DetailSection title.
  String profileCapabilitiesSection({required String role});

  /// Heading above the withheld capabilities.
  String get profileNotAvailableToRole;

  /// Note under the capability list.
  String get profileServerEnforces;

  /// admin_profile_view.dart DetailSection title.
  String get profileBuildSection;

  /// DetailRow label; the value is a URL and is not translated.
  String get profileBaseUrlLabel;

  /// DetailRow label; the value is the raw wire name.
  String get profileEnvironmentLabel;

  /// admin_profile_view.dart DetailRow label.
  String get profileAuthAdapterLabel;

  /// StatusChip next to a fake auth adapter.
  String get profileFakeChip;

  /// admin_profile_view.dart DetailRow label.
  String get profilePageSizeLabel;

  /// DetailRow label; the VALUE is never translated.
  String get profileCorrelationIdLabel;

  /// Warning under the build section.
  String get profileFakeAdapterWarning;

  /// Note under the build section.
  String get profileCorrelationNote;

  /// admin_profile_view.dart DetailSection title.
  String get profileSessionSection;

  /// Note above the sign-out button.
  String get profileSignOutNote;

  /// Button and confirm label.
  String get profileSignOutButton;

  /// admin_profile_view.dart ConfirmActionSheet title.
  String get profileSignOutConfirmTitle;

  /// admin_profile_view.dart ConfirmActionSheet message.
  String get profileSignOutConfirmMessage;

  /// admin_labels.dart relative().
  String relativeMinutes({required int count});

  /// admin_labels.dart relative().
  String relativeHours({required int count});

  /// admin_labels.dart relative().
  String relativeDays({required int count});

  /// admin_labels.dart relative().
  String relativeMonths({required int count});

  /// admin_labels.dart relative().
  String relativeYears({required int count});

  /// admin_labels.dart relative() future direction. The past direction is
  /// ageAgo.
  String relativeInFuture({required String phrase});

  /// admin_labels.dart roleSummary(SUPER_ADMIN).
  String get roleSummarySuperAdmin;

  /// admin_labels.dart roleSummary(FINANCE_ADMIN).
  String get roleSummaryFinanceAdmin;

  /// admin_labels.dart roleSummary(REVIEWER).
  String get roleSummaryReviewer;

  /// admin_labels.dart roleSummary(SUPPORT).
  String get roleSummarySupport;

  /// admin_labels.dart roleSummary(VIEWER).
  String get roleSummaryViewer;

  /// admin_labels.dart capability(AdminCapability.viewDepositQueue).
  String get capViewDepositQueue;

  /// admin_labels.dart capability(reviewDeposit).
  String get capReviewDeposit;

  /// admin_labels.dart capability(secondApproveDeposit).
  String get capSecondApprove;

  /// admin_labels.dart capability(retryCredit). شحن is the bot credit verb.
  String get capRetryCredit;

  /// admin_labels.dart capability(viewReconciliation).
  String get capViewReconciliation;

  /// admin_labels.dart capability(resolveBreak).
  String get capResolveBreak;

  /// admin_labels.dart capability(viewPaymentMethods).
  String get capViewPaymentMethods;

  /// admin_labels.dart capability(managePaymentDestinations).
  String get capManagePaymentDestinations;

  /// admin_labels.dart capability(viewAdminUsers).
  String get capViewAdminUsers;

  /// admin_labels.dart capability(manageAdminUsers).
  String get capManageAdminUsers;

  /// admin_labels.dart capability(viewLedger).
  String get capViewLedger;

  /// admin_user_policy.dart gateViewDirectory.
  String get gateViewDirectoryReason;

  /// admin_user_policy.dart gateManage.
  String get gateManageReason;

  /// gateUpdate and admin_user_error_codes.dart ADMIN_SELF_MODIFICATION.
  String get gateSelfModificationReason;

  /// gateUpdate - ADMIN_LAST_SUPER_ADMIN.
  String get gateLastSuperAdminReason;

  /// admin_user_policy.dart gateDeactivate.
  String get gateAlreadyDeactivated;

  /// admin_user_policy.dart gateReactivate.
  String get gateAlreadyActive;

  /// admin_user_policy.dart identityCacheNotice.
  String get identityCacheNotice;

  /// identity_cache_notice.dart IdentityCacheNotice.compact.
  String get identityCacheNoticeCompact;

  /// admin_users permission_denied_view.dart default title.
  String get auPermissionDeniedTitle;

  /// Fallback when the gate has no reason.
  String get auPermissionDeniedFallback;

  /// Appended to the reason. {role} is roleWithWireName output.
  String auPermissionDeniedSignedInAs({required String role});

  /// admin_user_error_codes.dart ADMIN_NOT_FOUND.
  String get errAdminNotFound;

  /// admin_user_error_codes.dart ADMIN_ALREADY_EXISTS.
  String get errAdminAlreadyExists;

  /// admin_user_error_codes.dart APPROVAL_LIMIT_NOT_FOUND.
  String get errApprovalLimitNotFound;

  /// admin_user_error_codes.dart APPROVAL_LIMIT_INVALID.
  String get errApprovalLimitInvalid;

  /// describeAdminError - ApiForbidden isAdminInactive.
  String get errOwnAccountDeactivated;

  /// describeAdminError - ApiForbidden isInsufficientRole.
  String get errRoleNotAllowed;

  /// describeAdminError - ApiNetworkError / ApiTimeout.
  String get errNetwork;

  /// AdminMutationSucceeded for create. Arabic puts the verb first, so the old
  /// shared "{name} {pastTense}." template is split into one key per action.
  String auCreatedToast({required String name});

  /// AdminMutationSucceeded for update.
  String auUpdatedToast({required String name});

  /// AdminMutationSucceeded for deactivate.
  String auDeactivatedToast({required String name});

  /// AdminMutationSucceeded for reactivate.
  String auReactivatedToast({required String name});

  /// admin_user_mutation_controller.dart create success notice.
  String get auNoticeNewAdminCanSignIn;

  /// admin_user_mutation_controller.dart reactivate success notice.
  String get auNoticeAccessRestored;

  /// ApprovalLimitMutationSucceeded for the set action.
  String get alSavedToast;

  /// ApprovalLimitMutationSucceeded for the end action.
  String get alEndedToast;

  /// ApprovalLimitMutationRaced info snackbar.
  String get alRacedMessage;

  /// approval_limits_controller.dart setLimit success notice.
  String get alSetNotice;

  /// approval_limits_controller.dart endLimit success notice.
  String alEndNotice({required String currency});

  /// AdminUserFieldRules.telegramUserId.
  String get auTelegramIdRequired;

  /// AdminUserFieldRules.telegramUserId.
  String get auTelegramIdMalformed;

  /// AdminUserFieldRules.displayName.
  String get auDisplayNameRequired;

  /// AdminUserFieldRules.displayName / username.
  String auMaxChars({required int max});

  /// AdminUserFieldRules.username.
  String get auUsernameAfterAt;

  /// --- Player shell - bottom navigation. The raised centre action
  /// --- (navTopUp) starts a flow and is not a destination.

  /// Player shell branch 0.
  String get navHome;

  /// Player shell branch 1. DEDUPED with activityTitle.
  String get navActivity;

  /// Raised centre action of the player bar. Not a branch.
  String get navTopUp;

  /// Player shell branch 2.
  String get navMethods;

  /// Player shell branch 3.
  String get navProfile;

  /// --- Connection pill - kit level, shared by the home header and حسابي.

  /// ConnectionPill while the probe is in flight.
  String get connectionChecking;

  /// ConnectionPill, probe succeeded.
  String get connectionOnline;

  /// ConnectionPill, probe failed.
  String get connectionOffline;

  /// Round-trip in whole milliseconds. Western digits in both bundles.
  String connectionLatencyMs({required int ms});

  /// --- Home tab - the player landing screen.

  /// Home header greeting.
  String homeGreeting({required String name});

  /// Home header second line.
  String get homeTagline;

  /// BalanceHero label on home.
  String get homeBalanceLabel;

  /// BalanceHero footnote. {age} arrives pre-rendered as "منذ 4 د" / "4m ago".
  String homeBalanceUpdated({required String age});

  /// BalanceHero status chip. Western digits in both bundles.
  String homeBalancePendingChip({required int count});

  /// BalanceHero eye toggle.
  String get homeBalanceVisibilityTooltip;

  /// Primary call to action on home.
  String get homeTopUpCta;

  /// Quick action 1.
  String get homeQuickTopUp;

  /// Quick action 2.
  String get homeQuickDeposits;

  /// Quick action 3.
  String get homeQuickMethods;

  /// Quick action 4.
  String get homeQuickSupport;

  /// Promo carousel heading.
  String get homePromoSectionTitle;

  /// Promo card action.
  String get homePromoAction;

  /// Promo card 1 title.
  String get homePromoBonusTitle;

  /// Promo card 1 body.
  String get homePromoBonusBody;

  /// Promo card 2 title.
  String get homePromoInstantTitle;

  /// Promo card 2 body.
  String get homePromoInstantBody;

  /// Promo card 3 title.
  String get homePromoRailsTitle;

  /// Promo card 3 body.
  String get homePromoRailsBody;

  /// Recent activity section heading on home.
  String get homeRecentTitle;

  /// Recent activity empty state on home.
  String get homeRecentEmptyMessage;

  /// Home banner, gaming account missing.
  String get homeAccountNotLinkedTitle;

  /// Home banner body, gaming account missing.
  String get homeAccountNotLinkedMessage;

  /// Home banner action, gaming account missing.
  String get homeAccountLinkCta;

  /// Home banner, gaming account linked.
  String get homeAccountLinkedTitle;

  /// Home banner body, gaming account linked.
  String get homeAccountLinkedMessage;

  /// --- إيداعاتي - the player deposit list and its detail sheet.

  /// Activity screen title. DEDUPED with navActivity.
  String get activityTitle;

  /// Filter footer count. Western digits in both bundles.
  String activityShowingCount({required int shown, required int total});

  /// Activity filter chip.
  String get activityFilterInReview;

  /// Activity filter chip.
  String get activityFilterCompleted;

  /// Activity filter chip.
  String get activityFilterRejected;

  /// Activity summary card, credited total.
  String get activitySummaryCreditedLabel;

  /// Activity summary card, open requests. Western digits in both bundles.
  String activityInProgressCount({required int count});

  /// Activity summary card when nothing is open.
  String get activitySummaryAllSettled;

  /// Activity row subtitle.
  String activityViaMethod({required String method});

  /// Activity empty state, no deposits at all.
  String get activityEmptyTitle;

  /// Activity empty state body.
  String get activityEmptyMessage;

  /// Activity empty state action.
  String get activityStartTopUpAction;

  /// Activity empty state under a filter.
  String get activityFilterEmptyTitle;

  /// Activity filter empty body.
  String get activityFilterEmptyMessage;

  /// Clears the activity filter.
  String get activityShowAllAction;

  /// Activity load failure.
  String get activityErrorTitle;

  /// Activity load failure body.
  String get activityErrorMessage;

  /// Activity detail sheet title.
  String get activityDetailTitle;

  /// Activity detail row.
  String get activityDetailAmountLabel;

  /// Activity detail row.
  String get activityDetailCreditedLabel;

  /// Activity detail row.
  String get activityDetailMethodLabel;

  /// Activity detail row.
  String get activityDetailDestinationLabel;

  /// Activity detail row.
  String get activityDetailSenderLabel;

  /// Activity detail row.
  String get activityDetailSubmittedLabel;

  /// Activity detail heading over the forward-looking steps.
  String get activityNextStepHeading;

  /// Activity detail heading over the settled timeline.
  String get activityTimelineHeading;

  /// Activity detail heading over the raw record.
  String get activityRecordHeading;

  /// Activity detail row, deposit shortId.
  String get activityRequestNumberLabel;

  /// Activity detail row, cashier note.
  String get activityStaffNoteLabel;

  /// Badge on the active timeline step.
  String get activityStepNowBadge;

  /// Closes the activity detail sheet.
  String get activityCloseButton;

  /// Timeline step.
  String get activityStepSubmittedTitle;

  /// Timeline step body.
  String get activityStepSubmittedBody;

  /// Timeline step.
  String get activityStepReviewTitle;

  /// Timeline step body.
  String get activityStepReviewBody;

  /// Timeline step.
  String get activityStepApprovedTitle;

  /// Timeline step body.
  String get activityStepApprovedBody;

  /// Timeline step.
  String get activityStepCreditedTitle;

  /// Timeline step body.
  String get activityStepCreditedBody;

  /// Timeline step.
  String get activityStepRejectedTitle;

  /// Timeline step body.
  String get activityStepRejectedBody;

  /// Timeline step.
  String get activityStepExpiredTitle;

  /// Timeline step body.
  String get activityStepExpiredBody;

  /// --- شحن - the five-step player top-up flow.

  /// Top-up flow app bar.
  String get topupTitle;

  /// Closes the top-up flow.
  String get topupCloseTooltip;

  /// Step counter in the app bar. Western digits in both bundles.
  String topupStepOfTotal({required int step, required int total});

  /// Step indicator label 1.
  String get topupStepAmount;

  /// Step indicator label 2.
  String get topupStepMethod;

  /// Step indicator label 3.
  String get topupStepPay;

  /// Step indicator label 4.
  String get topupStepReceipt;

  /// Step indicator label 5.
  String get topupStepDone;

  /// Advances a step.
  String get topupNext;

  /// Returns a step.
  String get topupBack;

  /// Amount step headline.
  String get topupAmountHeadline;

  /// Amount step subhead.
  String get topupAmountSubhead;

  /// Amount field label.
  String get topupAmountFieldLabel;

  /// Amount field hint. Western digits in both.
  String get topupAmountFieldHint;

  /// Amount field helper. Both bounds arrive already formatted by Money.
  String topupAmountHelper({required String min, required String max});

  /// Quick-amount chip row label.
  String get topupQuickPicksLabel;

  /// TopUpAmountIssue.notPositive.
  String get topupAmountErrorNotPositive;

  /// TopUpAmountIssue.belowMinimum.
  String topupAmountErrorBelowMin({required String min});

  /// TopUpAmountIssue.aboveMaximum.
  String topupAmountErrorAboveMax({required String max});

  /// Method step load failure.
  String get topupMethodsLoadFailed;

  /// Method step headline.
  String get topupMethodHeadline;

  /// Method step subhead.
  String get topupMethodSubhead;

  /// Per-method window on the method card. Bounds arrive formatted.
  String topupMethodLimits({required String min, required String max});

  /// Method card badge when the amount is outside its window.
  String get topupMethodNotForAmount;

  /// Method step empty state.
  String get topupNoMethodsTitle;

  /// Method step empty state body.
  String get topupNoMethodsMessage;

  /// Destination picker heading inside the method step.
  String get topupDestinationSectionTitle;

  /// Destination picker empty state.
  String get topupNoDestinationsTitle;

  /// Destination picker empty state body.
  String get topupNoDestinationsMessage;

  /// Marks the chosen method or destination.
  String get topupSelectedBadge;

  /// Review estimate. Western digits in both bundles.
  String topupReviewEta({required int minutes});

  /// Pay step headline.
  String get topupPayHeadline;

  /// Pay step subhead.
  String get topupPaySubhead;

  /// Pay step breakdown row.
  String get topupAmountToSendLabel;

  /// Pay step breakdown row.
  String get topupFeeLabel;

  /// Pay step breakdown row.
  String get topupCreditedLabel;

  /// Pay step reference instruction.
  String get topupReferenceHint;

  /// Pay step window label.
  String get topupDeadlineLabel;

  /// Pay step window, elapsed.
  String get topupDeadlineExpired;

  /// mm:ss countdown, zero padded, Western digits in both bundles.
  String topupCountdown({required int minutes, required int seconds});

  /// Pay step primary action.
  String get topupPaidCta;

  /// Receipt step headline.
  String get topupReceiptHeadline;

  /// Receipt step subhead.
  String get topupReceiptSubhead;

  /// Receipt drop zone, empty.
  String get topupReceiptEmptyTitle;

  /// Receipt drop zone, empty body.
  String get topupReceiptEmptyMessage;

  /// Receipt drop zone action.
  String get topupReceiptPickCta;

  /// Receipt drop zone action once an image exists.
  String get topupReceiptReplaceCta;

  /// Receipt drop zone action once an image exists.
  String get topupReceiptRemoveCta;

  /// No image-picker dependency in this build.
  String get topupReceiptPickerUnavailable;

  /// Sender-name field helper.
  String get topupSenderNameHelper;

  /// Receipt step summary card heading.
  String get topupSummaryTitle;

  /// Receipt step primary action.
  String get topupSubmitCta;

  /// Submit failure.
  String get topupSubmitFailedTitle;

  /// Success step headline.
  String get topupSuccessHeadline;

  /// Success step body.
  String get topupSuccessMessage;

  /// Success step row, deposit shortId.
  String get topupShortIdLabel;

  /// Success step heading.
  String get topupWhatHappensNext;

  /// Success step bullet 1.
  String get topupNextStepReview;

  /// Success step bullet 2.
  String get topupNextStepCredit;

  /// Success step bullet 3.
  String get topupNextStepNotify;

  /// Success step, leaves the flow.
  String get topupDoneCta;

  /// Success step, restarts the flow.
  String get topupAnotherCta;

  /// Demo-data banner. Removed when the server is wired in.
  String get topupDemoNotice;

  /// --- طرق الدفع - the player-facing rail list and its detail sheet.

  /// Methods screen intro line.
  String get methodsIntro;

  /// Methods header chip. Western digits in both bundles.
  String methodsAvailableCount({required int available, required int total});

  /// Methods filter toggle.
  String get methodsFilterAvailableOnly;

  /// Method card badge.
  String get methodsBadgeAvailable;

  /// Method card badge.
  String get methodsBadgeBusy;

  /// Method card badge.
  String get methodsBadgeUnavailable;

  /// Method card badge.
  String get methodsBadgeMostUsed;

  /// Method detail note when the rail is under load.
  String get methodsBusyNote;

  /// Method detail note when the rail is paused.
  String get methodsPausedNote;

  /// Method detail row.
  String get methodsSettlementLabel;

  /// Settlement value. {age} arrives pre-rendered.
  String methodsSettlementWithin({required String age});

  /// Settlement value for an immediate rail.
  String get methodsSettlementInstant;

  /// Fee value when the rail charges nothing.
  String get methodsFeeNone;

  /// Chip pair for the existing referenceRequiredLabel.
  String get methodsReferenceOptionalShort;

  /// Method detail row, freshness of the availability probe.
  String get methodsCheckedLabel;

  /// Methods list section.
  String get methodsSectionFastest;

  /// Methods list section.
  String get methodsSectionOther;

  /// Methods list section.
  String get methodsSectionPaused;

  /// Method detail heading.
  String get methodsHowToTitle;

  /// Method detail heading.
  String get methodsProofTitle;

  /// Method detail heading, singular and player-voiced. The admin console
  /// keeps the plural pmDestinationsHeading.
  String get methodsDestinationTitle;

  /// Clipboard confirmation.
  String get methodsAccountCopied;

  /// Method detail reference guidance.
  String get methodsReferenceHintRequired;

  /// Method detail reference guidance.
  String get methodsReferenceHintOptional;

  /// Method detail primary action.
  String get methodsTopUpNowCta;

  /// Methods list empty state.
  String get methodsEmptyMessage;

  /// --- حسابي - the player profile tab.

  /// Profile section heading.
  String get profileSectionAccount;

  /// Profile row.
  String get profileUsernameLabel;

  /// Profile row, the linked Ichancy account.
  String get profileGamingAccountLabel;

  /// Profile account status.
  String get profileAccountStatusActive;

  /// Profile account status.
  String get profileAccountStatusLimited;

  /// Profile account status.
  String get profileAccountStatusSuspended;

  /// Gaming-account link status.
  String get profileGamingLinked;

  /// Gaming-account link status.
  String get profileGamingPending;

  /// Gaming-account link status.
  String get profileGamingMissing;

  /// Profile stat tile.
  String get profileStatTotalDeposited;

  /// Profile stat tile.
  String get profileStatDepositCount;

  /// Profile stat tile.
  String get profileStatMemberSince;

  /// Profile row.
  String get profileReferralCodeLabel;

  /// Profile row.
  String get profileInviteLinkLabel;

  /// Referral card body.
  String get profileReferralHint;

  /// Toggles masking of the referral identifiers.
  String get profileRevealTooltip;

  /// Profile section heading.
  String get profileSectionConnection;

  /// Health card row.
  String get profileHealthEndpointLabel;

  /// Health card row.
  String get profileLastCheckedLabel;

  /// Re-runs the health probe.
  String get profileRecheckButton;

  /// Profile settings row.
  String get profileTermsLabel;

  /// Terms sheet body.
  String get profileTermsBody;

  /// Profile settings row.
  String get profileSupportLabel;

  /// Support sheet body.
  String get profileSupportBody;

  /// Support sheet row.
  String get profileSupportChannelLabel;

  /// Profile row.
  String get profileAppVersionLabel;

  /// Closes a profile sheet.
  String get profileCloseButton;

  /// Profile empty state.
  String get profileEmptyTitle;

  /// Profile empty state body.
  String get profileEmptyMessage;

  /// Profile load failure.
  String get profileLoadFailedTitle;

}

/// Arabic - the DEFAULT locale of this console.
///
/// Register is MSA throughout, matching the bot's admin/report surface. Wording
/// follows the Telegram bot glossary; the bindings that must not drift are:
/// * `إيداع` is the player's REQUEST, `شحن` is the money landing.
/// * `مرجع الحوالة` is the external bank reference, `مرجع الإيداع` the deposit
///   shortId, `معرّف التتبع` the correlation id. The bare `المرجع` is left
///   unused because the bot binds it to the deposit shortId.
/// * `تمت المعالجة` belongs to BreakStatus.RESOLVED and to nothing else;
///   ApiConflict's "already handled" is `عولج مسبقاً`.
/// * `رصيد الكاشيرة` is the agent float, never `رصيد الوكيل`.
/// * `بحاجة تدقيق` is NEEDS_RECONCILIATION, `فشل الشحن` is CREDIT_FAILED.
/// * `طرق الدفع` is the list, `وسيلة الدفع` one record, `طريقة الدفع`
///   mid-sentence.
class ArStrings extends AppStrings {
  const ArStrings();

  /// Arabic counted-noun selector, CLDR categories.
  ///
  /// `zero` for 0, `one` for 1, `two` for 2, `few` for n%100 in 3..10 and
  /// `many` for everything else. Digits interpolated by the callers stay
  /// Western: the bot prints Western digits and so does this console.
  static String _plural(
    int count, {
    required String zero,
    required String one,
    required String two,
    required String few,
    required String many,
  }) {
    if (count == 0) {
      return zero;
    }
    if (count == 1) {
      return one;
    }
    if (count == 2) {
      return two;
    }
    final int mod100 = count.abs() % 100;
    if (mod100 >= 3 && mod100 <= 10) {
      return few;
    }
    return many;
  }

  @override
  String get localeTag => 'ar';

  @override
  TextDirection get textDirection => TextDirection.rtl;

  @override
  String get appTitle => 'لوحة الإدارة';

  @override
  String get navQueue => 'الإيداعات';

  @override
  String get navMoney => 'المالية';

  @override
  String get settingsTooltip => 'الإعدادات';

  @override
  String get languageLabel => 'اللغة';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get errorRequestFailed => 'تعذّر إتمام الطلب.';

  @override
  String errorServerReturnedStatus({required int status, required String code}) => 'الخادم أرجع $status ($code).';

  @override
  String get errorSessionNoLongerValid => 'انتهت صلاحية جلستك. سجّل الدخول من جديد.';

  @override
  String get errorAdminDeactivated => 'هذا الحساب الإداري معطّل.';

  @override
  String get errorAdminNotFound => 'هذا الحساب الإداري لم يعد موجوداً.';

  @override
  String get errorWrongPrincipal => 'هذا الرمز ليس رمز مدير.';

  @override
  String get errorInsufficientRole => 'صلاحيتك لا تسمح بهذا الإجراء.';

  @override
  String get errorRecordNotFound => 'لم يتم العثور على هذا السجل.';

  @override
  String errorValidationWithFields({required String message, required String fields}) => '$message\n- $fields';

  @override
  String get errorRequestStillProcessing => 'نفس الطلب قيد التنفيذ. أعد المحاولة بعد قليل.';

  @override
  String get errorRequestAlreadySubmitted => 'تم إرسال هذا الطلب سابقاً بتفاصيل مختلفة.';

  @override
  String get errorAlreadyHandledByOther => 'عالجه مشرف آخر قبلك. حدّث لعرض الحالة الحالية.';

  @override
  String get errorTooManyRequests => 'طلبات كثيرة. انتظر قليلاً ثم أعد المحاولة.';

  @override
  String errorTooManyRequestsRetryIn({required int seconds}) => 'طلبات كثيرة. أعد المحاولة بعد $seconds ثانية.';

  @override
  String get errorRequestCancelled => 'تم إلغاء الطلب.';

  @override
  String get errorCannotReachServer => 'تعذّر الوصول إلى الخادم. تحقّق من الاتصال وأعد المحاولة.';

  @override
  String get errorServerTookTooLong => 'الخادم تأخّر بالرد. أعد المحاولة.';

  @override
  String get errorServerInternal => 'حدث خطأ داخلي في الخادم. أعد المحاولة بعد قليل.';

  @override
  String errorServerInternalWithRef({required String correlationId}) => 'حدث خطأ داخلي في الخادم. أعطِ الدعم الرقم المرجعي $correlationId.';

  @override
  String get errorUnreadableFromServer => 'أرسل الخادم رداً لا يستطيع التطبيق قراءته.';

  @override
  String errorSupportLine({required String message, required String code, required String correlationId}) => '$message ($code — مرجع $correlationId)';

  @override
  String errorSupportLineShort({required String message, required String code}) => '$message ($code)';

  @override
  String get errorEnvelopeMissing => 'لم يُرجع الخادم الرد بالصيغة المتوقعة.';

  @override
  String errorCouldNotReadResponse({required String method, required String path, required String field, required String reason}) => 'تعذّرت قراءة رد $method $path ($field: $reason).';

  @override
  String errorAmountNotExact({required String method, required String path, required String reason}) => 'تعذّرت قراءة مبلغ في $method $path بدقة ($reason). لم يُعرض شيء بدل عرض رقم مقرّب.';

  @override
  String errorRequestTimedOutPath({required String path}) => 'انتهت مهلة الطلب إلى $path.';

  @override
  String get errorCertificateRejected => 'تم رفض شهادة الخادم.';

  @override
  String errorResponseUndecodable({required String method, required String path}) => 'تعذّر فك ترميز رد $method $path.';

  @override
  String errorCouldNotReachHost({required String baseUrl}) => 'تعذّر الوصول إلى $baseUrl.';

  @override
  String get errorTitleSessionExpired => 'انتهت الجلسة';

  @override
  String get errorTitleNotAllowed => 'غير مسموح';

  @override
  String get errorTitleCheckDetails => 'تحقّق من البيانات';

  @override
  String get errorTitleNotFound => 'غير موجود';

  @override
  String get errorTitleAlreadyHandled => 'عولج مسبقاً';

  @override
  String get errorTitleCannotDoThat => 'لا يمكن تنفيذ ذلك';

  @override
  String get errorTitleTooManyRequests => 'طلبات كثيرة';

  @override
  String get errorTitleNoConnection => 'لا يوجد اتصال';

  @override
  String get errorTitleTimedOut => 'انتهت المهلة';

  @override
  String get errorTitleServerError => 'خطأ في الخادم';

  @override
  String get errorTitleUnexpectedResponse => 'رد غير متوقع';

  @override
  String get errorTitleSignInAgain => 'سجّل الدخول من جديد';

  @override
  String get errorTitleUnreadableResponse => 'رد غير مقروء';

  @override
  String errorUnreadableResponseBody({required String path, required String reason}) => 'أرسل الخادم بيانات لا يفهمها التطبيق ($path: $reason).';

  @override
  String get errorTitleUnreadableAmount => 'مبلغ غير مقروء';

  @override
  String errorUnreadableAmountBody({required String reason}) => 'تعذّرت قراءة مبلغ في الرد بدقة ($reason). لا يُعرض شيء بدل رقم مقرّب. أبلغ فريق الباك إند.';

  @override
  String get errorTitleSomethingWentWrong => 'حدث خطأ ما';

  @override
  String get tryAgain => 'أعد المحاولة';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get refresh => 'تحديث';

  @override
  String get emptyDefaultTitle => 'لا يوجد شيء بعد';

  @override
  String get loading => 'جارٍ التحميل...';

  @override
  String get loadingQueue => 'جارٍ تحميل الطابور...';

  @override
  String get queueEmptyTitle => 'الطابور فارغ';

  @override
  String get queueEmptyMessage => 'لا يوجد طلبات بانتظار المراجعة.';

  @override
  String get referenceCopied => 'تم نسخ الرقم المرجعي';

  @override
  String correlationChip({required String code, required String correlationId}) => '$code - $correlationId';

  @override
  String get cancel => 'إلغاء';

  @override
  String get note => 'ملاحظة';

  @override
  String noteRequiredSuffix({required String label}) => '$label (مطلوب)';

  @override
  String confirmApproveAmountTitle({required String amount}) => 'الموافقة على $amount؟';

  @override
  String confirmPlayerWillBeCredited({required String playerId}) => 'سيتم شحن رصيد اللاعب $playerId فوراً.';

  @override
  String get yes => 'نعم';

  @override
  String get no => 'لا';

  @override
  String get apply => 'تطبيق';

  @override
  String get resetButton => 'إعادة تعيين';

  @override
  String get filterLabel => 'تصفية';

  @override
  String filterWithCount({required int count}) => 'تصفية ($count)';

  @override
  String get statusLabel => 'الحالة';

  @override
  String get createdLabel => 'تاريخ الإنشاء';

  @override
  String get editButton => 'تعديل';

  @override
  String get saveButton => 'حفظ';

  @override
  String get savingButton => 'جارٍ الحفظ...';

  @override
  String get loadMore => 'تحميل المزيد';

  @override
  String get copyTooltip => 'نسخ';

  @override
  String get copied => 'تم النسخ.';

  @override
  String copiedToClipboard({required String label}) => 'تم نسخ $label';

  @override
  String get emptyValueDash => '—';

  @override
  String get timesAreLocalNote => 'الأوقات معروضة بتوقيت الجهاز المحلي. البوت يعرضها بتوقيت UTC.';

  @override
  String get unknownPlaceholder => '؟';

  @override
  String get listSeparator => '، ';

  @override
  String moneyAmountWithCurrency({required String amount, required String currency}) => '$amount $currency';

  @override
  String moneyDual({required String newAmount, required String oldAmount}) => '$newAmount جديدة | $oldAmount قديمة';

  @override
  String get moneyErrorEmpty => 'أدخل مبلغاً.';

  @override
  String get moneyErrorMalformed => 'أدخل رقماً بسيطاً، مثال: 1500.00';

  @override
  String get moneyErrorPlainAmountExample => 'أدخل مبلغاً بسيطاً مثل 1500.00.';

  @override
  String get moneyErrorDigitsOnly => 'استخدم أرقاماً ونقطة واحدة على الأكثر، مثال 15000.00. بلا مسافات وبلا فواصل آلاف.';

  @override
  String moneyErrorTooManyDecimals({required int scale}) => 'بحد أقصى $scale خانات عشرية.';

  @override
  String get atMostTwoDecimals => 'منزلتان عشريتان كحد أقصى.';

  @override
  String get moneyErrorScaleTwo => 'منزلتان عشريتان كحد أقصى — الخادم يخزّن بمنزلتين.';

  @override
  String get moneyErrorScaleTwoDetailed => 'منزلتان عشريتان كحد أقصى. الخادم يخزّن هذه العملة بمنزلتين ويرفض ما زاد.';

  @override
  String get moneyErrorCurrencyMismatch => 'هذه المبالغ بعملات مختلفة.';

  @override
  String get moneyErrorOtherCurrency => 'هذا المبلغ بعملة مختلفة.';

  @override
  String get moneyErrorInvalid => 'هذا ليس مبلغاً صالحاً.';

  @override
  String get roleSuperAdmin => 'مدير عام';

  @override
  String get roleFinanceAdmin => 'مدير مالي';

  @override
  String get roleReviewer => 'مراجع';

  @override
  String get roleSupport => 'موظف دعم';

  @override
  String get roleViewer => 'مطّلع (قراءة فقط)';

  @override
  String roleWithWireName({required String label, required String wireName}) => '$label ($wireName)';

  @override
  String get adminDisplayNameFallback => 'مشرف';

  @override
  String get errorSessionNoExpiry => 'مطلوب تاريخ ISO-8601؛ لا يمكن الوثوق بجلسة بلا تاريخ انتهاء.';

  @override
  String get signedOut => 'تم تسجيل خروجك.';

  @override
  String signInAgainWithReason({required String reason}) => 'سجّل الدخول من جديد: $reason.';

  @override
  String get reasonSessionExpired => 'انتهت صلاحية الجلسة';

  @override
  String get reasonStoredSessionExpired => 'انتهت صلاحية الجلسة المحفوظة';

  @override
  String get reasonTokenAlreadyExpired => 'الرمز الصادر كان منتهي الصلاحية أصلاً';

  @override
  String get reasonNoRefresh => 'لا يمكن تجديد جلسات المدراء';

  @override
  String get enterBotCode => 'أدخل الرمز الذي أرسله البوت.';

  @override
  String get codeMustNotBeEmpty => 'الرمز مطلوب';

  @override
  String get botCodeInvalid => 'الرمز غير صالح.';

  @override
  String devDisplayName({required String role}) => '$role تجريبي';

  @override
  String get loginTitle => 'لوحة الإدارة';

  @override
  String get loginHeadlineRestoring => 'جارٍ استعادة جلستك...';

  @override
  String get loginHeadlineSignIn => 'سجّل الدخول بالرمز الذي أرسله البوت.';

  @override
  String get loginHeadlineChecking => 'جارٍ التحقق من الرمز مع الخادم...';

  @override
  String loginHeadlineSignedInAs({required String name}) => 'تم تسجيل الدخول باسم $name.';

  @override
  String get loginHeadlineSessionEnded => 'انتهت جلستك. سجّل الدخول من جديد للمتابعة.';

  @override
  String get botCodeFieldLabel => 'رمز البوت';

  @override
  String get botCodeFieldHelper => 'الرمز لمرة واحدة الذي أرسله البوت برسالة خاصة.';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get signingIn => 'جارٍ تسجيل الدخول...';

  @override
  String get sessionEndedTitle => 'انتهت الجلسة';

  @override
  String sessionEndedBody({required String name, required String role, required String reason}) => '$name، انتهت جلستك ($role) — $reason. لا يمكن تجديد الجلسات، اطلب رمزاً جديداً من البوت.';

  @override
  String envFooter({required String env, required String baseUrl}) => '$env - $baseUrl';

  @override
  String fakeAuthBanner({required String env, required String baseUrl}) => 'تسجيل دخول وهمي مفعّل. لا يتم الاتصال بأي خادم ولا تُنشأ جلسة حقيقية. $env - $baseUrl';

  @override
  String get devCodeShortLabel => ':SHORT (دقيقتان)';

  @override
  String get devCodeDenyLabel => 'DEV-DENY (يرفض)';

  @override
  String copiedCode({required String code}) => 'تم نسخ $code';

  @override
  String get depositQueueTitle => 'طابور الإيداعات';

  @override
  String queueRefreshFailed({required String message}) => 'فشل التحديث: $message';

  @override
  String get queueNoAccessTitle => 'لا صلاحية للوصول إلى طابور الإيداعات';

  @override
  String get queueNoAccessMessage => 'دورك لا يسمح بقراءة الإيداعات. اطلب من مدير عام تغييره.';

  @override
  String get sortTooltip => 'ترتيب';

  @override
  String get moreTooltip => 'المزيد';

  @override
  String get clearFiltersAction => 'مسح التصفية';

  @override
  String get runSweepAction => 'تشغيل مهمة الصيانة';

  @override
  String get queueNoMatchesTitle => 'لا نتائج';

  @override
  String get queueNoMatchesMessage => 'لا يوجد إيداع مطابق لهذه التصفية. تذكّر أن مرجع الإيداع ومرجع الحوالة مطابقة تامة.';

  @override
  String get clearButton => 'مسح';

  @override
  String filterSummaryStatuses({required int count}) => _plural(count, zero: 'بلا حالات', one: 'حالة واحدة', two: 'حالتان', few: '$count حالات', many: '$count حالة');

  @override
  String filterSummaryShortId({required String shortId}) => 'مرجع $shortId';

  @override
  String filterSummaryExternalReference({required String reference}) => 'حوالة $reference';

  @override
  String filterSummaryAmountRange({required String min, required String max}) => '$min - $max';

  @override
  String get filterSummaryAny => 'أي';

  @override
  String get filterSummaryDateRange => 'مدة زمنية';

  @override
  String get filterSummaryOnePlayer => 'لاعب واحد';

  @override
  String get filterSummaryOneMethod => 'وسيلة دفع واحدة';

  @override
  String get filterSummaryUnclaimedOnly => 'غير المستلمة فقط';

  @override
  String get filterSummaryFallback => 'مُصفّى';

  @override
  String queuePagingBlockedBySort({required String sort}) => 'توجد إيداعات أخرى مطابقة، لكن «$sort» لا يدعم التصفّح في الخادم. رتّب حسب الأحدث أو الأقدم للتصفّح، أو ضيّق التصفية.';

  @override
  String queueLoadedCount({required int count}) => _plural(count, zero: 'لا إيداعات محمّلة.', one: 'تم تحميل إيداع واحد.', two: 'تم تحميل إيداعين.', few: 'تم تحميل $count إيداعات.', many: 'تم تحميل $count إيداعاً.');

  @override
  String get sweepConfirmTitle => 'تشغيل مهمة الصيانة؟';

  @override
  String get sweepConfirmMessage => 'تُنهي صلاحية المسودات القديمة، وتحرّر الاستلامات الأقدم من 10 دقائق، وتعيد جدولة عمليات الشحن المتوقفة 20 دقيقة. كل تشغيل يعالج 100 صف كحد أقصى لكل مرحلة.';

  @override
  String get sweepConfirmButton => 'تشغيل الصيانة';

  @override
  String sweepFailed({required String message}) => 'فشلت الصيانة: $message';

  @override
  String get sweepNothingToDo => 'لا شيء يحتاج صيانة.';

  @override
  String sweepSummary({required int expired, required int released, required int reaped}) => '$expired انتهت صلاحيتها، $released حُرّرت، $reaped أُعيدت جدولتها.';

  @override
  String get detailNoAccessTitle => 'لا صلاحية للوصول إلى الإيداعات';

  @override
  String get detailNoAccessMessage => 'دورك لا يسمح بقراءة الإيداعات.';

  @override
  String detailLoadingLabel({required String shortId}) => 'جارٍ تحميل $shortId...';

  @override
  String get claimTakeOverTitle => 'استلام هذه المراجعة؟';

  @override
  String get claimTakeOverMessage => 'مراجع آخر استلمها لكن انتهت مهلته. الاستلام الآن ينقلها إليك.';

  @override
  String get claimTakeOverConfirm => 'استلام';

  @override
  String releaseConfirmTitle({required String shortId}) => 'تحرير $shortId؟';

  @override
  String get releaseConfirmMessage => 'سيعود إلى الطابور ليستلمه أي مراجع.';

  @override
  String get releaseConfirmButton => 'تحرير';

  @override
  String get retryCreditConfirmTitle => 'إعادة تشغيل الشحن؟';

  @override
  String retryCreditConfirmMessage({required String amount}) => 'سيعيد عامل الشحن المحاولة بمبلغ $amount. لن يُسجَّل أي قيد جديد في الدفاتر. لا تفعل هذا إلا بعد معالجة سبب الفشل.';

  @override
  String get retryCreditConfirmButton => 'إعادة الشحن';

  @override
  String get retryCreditReasonLabel => 'السبب';

  @override
  String get retryCreditReasonHint => 'مثال: تم شحن رصيد الكاشيرة';

  @override
  String get sectionAmounts => 'المبالغ';

  @override
  String get amountPlayerClaimed => 'المبلغ المُعلن';

  @override
  String get amountVerifiedByAdmin => 'المبلغ المُتحقق';

  @override
  String get amountNotVerifiedYet => 'لم يتم التحقق بعد';

  @override
  String get amountFee => 'العمولة';

  @override
  String get amountCreditedToPlayer => 'المبلغ المشحون';

  @override
  String get amountNotCreditedYet => 'لم يتم الشحن بعد';

  @override
  String get playerLabel => 'اللاعب';

  @override
  String get playerTelegram => 'التيليغرام';

  @override
  String get telegramIdLabel => 'معرّف التيليغرام';

  @override
  String get playerIdLabel => 'ID اللاعب';

  @override
  String get sectionDestination => 'جهة الدفع المطلوبة';

  @override
  String get sectionSubmitted => 'ما أرسله اللاعب';

  @override
  String get externalReferenceLabel => 'مرجع الحوالة';

  @override
  String get externalReferenceMissingHint => 'هذه الوسيلة تتطلب مرجع حوالة ولم يُدخل أي مرجع.';

  @override
  String get senderAccountLabel => 'حساب المُرسِل';

  @override
  String get riskSignals => 'مؤشرات خطر';

  @override
  String get riskFlagsDisclaimer => 'المؤشرات دليل لك وليست حكماً. خلوّ القائمة لا يعني أن الإيداع سليم.';

  @override
  String sectionProof({required int count}) => 'الإيصالات ($count)';

  @override
  String get sectionHistory => 'السجل';

  @override
  String get sectionTechnical => 'معلومات تقنية';

  @override
  String get technicalDepositId => 'معرّف الإيداع';

  @override
  String get technicalPaymentMethodId => 'معرّف وسيلة الدفع';

  @override
  String get technicalCreditAttempts => 'محاولات الشحن';

  @override
  String get technicalCreditKeyEpoch => 'إصدار مفتاح الشحن';

  @override
  String get technicalCreditVerifiedBy => 'تم تأكيد الشحن بواسطة';

  @override
  String get technicalDecidedByAdmin => 'المشرف صاحب القرار';

  @override
  String get technicalSecondApprover => 'الموافق الثاني';

  @override
  String headlineCreatedAgo({required String shortId, required String age}) => '$shortId - أُنشئ منذ $age';

  @override
  String get pendingSecondApprovalNote => 'موقوف بانتظار موافقة ثانية. الموافقة الأولى مسجّلة ولم يُسجَّل شيء في الدفاتر.';

  @override
  String claimHeldByYou({required int minutes}) => 'المراجعة بعهدتك لمدة $minutes د أخرى.';

  @override
  String get claimExpiredMine => 'انتهت مهلة استلامك. يمكن لأي مراجع أخذها الآن.';

  @override
  String get claimStaleOther => 'مراجع آخر استلمها وانتهت مهلته، فيمكن استلامها منه.';

  @override
  String claimHeldByOther({required int minutes}) => 'مراجع آخر يحتفظ بها $minutes د أخرى. الموافقة أو الرفض ما زالا ممكنين — الاستلام إرشادي فقط.';

  @override
  String correlationIdLine({required String correlationId}) => 'معرّف التتبع $correlationId';

  @override
  String get destinationMissing => 'لم تُسجَّل جهة دفع لهذا الإيداع.';

  @override
  String get paymentMethodLabel => 'وسيلة الدفع';

  @override
  String get destinationMethodCode => 'رمز الوسيلة';

  @override
  String get destinationLabel => 'الوجهة';

  @override
  String get accountLabel => 'الحساب';

  @override
  String get accountHolderLabel => 'صاحب الحساب';

  @override
  String get referenceRequiredLabel => 'مرجع الحوالة مطلوب';

  @override
  String get instructionsLabel => 'التعليمات';

  @override
  String get filterSheetTitle => 'تصفية الطابور';

  @override
  String get filterStatusHint => 'عدم اختيار شيء يعني الحالات الثلاث القابلة للمراجعة.';

  @override
  String get presetReviewable => 'قابلة للمراجعة';

  @override
  String get presetNeedsAttention => 'بحاجة انتباه';

  @override
  String get presetAnyStatus => 'أي حالة';

  @override
  String get filterSectionSort => 'الترتيب';

  @override
  String get sortNotPageableHint => 'الترتيب حسب المبلغ لا يدعم التصفّح في الخادم، لذا تُعرض الصفحة الأولى فقط.';

  @override
  String get filterSectionSearch => 'بحث';

  @override
  String get filterSearchHint => 'كلاهما مطابقة تامة — لا يوجد بحث جزئي في هذه الواجهة.';

  @override
  String get filterShortIdLabel => 'مرجع الإيداع';

  @override
  String get filterShortIdHint => 'K7Q2ZP9V3M';

  @override
  String get filterCaseSensitiveHint => 'حساس لحالة الأحرف';

  @override
  String get filterSectionAmount => 'المبلغ المُعلن';

  @override
  String get filterAmountMin => 'الحد الأدنى';

  @override
  String get filterAmountMax => 'الحد الأعلى';

  @override
  String get amountFieldHintSample => '1500.00';

  @override
  String get filterCreatedHint => '«من» شامل و«إلى» غير شامل.';

  @override
  String get dateFrom => 'من';

  @override
  String get dateTo => 'إلى';

  @override
  String get filterSectionIdentifiers => 'المعرّفات';

  @override
  String get filterIdentifiersHint => 'هذان الحقلان يقبلان UUID من الإصدار 4 فقط.';

  @override
  String get filterUnclaimedOnly => 'غير المستلمة فقط';

  @override
  String get filterUnclaimedOnlySubtitle => 'يخفي الإيداعات التي استلمها مراجع آخر.';

  @override
  String get sortNewest => 'الأحدث أولاً';

  @override
  String get sortOldest => 'الأقدم أولاً';

  @override
  String get sortAmountDesc => 'الأكبر مبلغاً';

  @override
  String get sortAmountAsc => 'الأصغر مبلغاً';

  @override
  String get validationPlayerIdUuid => 'ID اللاعب يجب أن يكون UUID من الإصدار 4.';

  @override
  String get validationPaymentMethodIdUuid => 'معرّف وسيلة الدفع يجب أن يكون UUID من الإصدار 4.';

  @override
  String get validationReferenceTooLong => 'مرجع الحوالة لا يتجاوز 120 حرفاً.';

  @override
  String get validationShortIdTooLong => 'مرجع الإيداع لا يتجاوز 32 حرفاً.';

  @override
  String get validationMinAboveMax => 'الحد الأدنى أكبر من الحد الأعلى.';

  @override
  String get validationFromBeforeTo => 'تاريخ «من» يجب أن يسبق تاريخ «إلى».';

  @override
  String get validationMinAmountInvalid => 'الحد الأدنى ليس مبلغاً صالحاً.';

  @override
  String get validationMaxAmountInvalid => 'الحد الأعلى ليس مبلغاً صالحاً.';

  @override
  String get statusDraft => 'مسودة';

  @override
  String get statusAwaitingProof => 'بانتظار الإيصال';

  @override
  String get statusSubmitted => 'بانتظار المراجعة';

  @override
  String get statusUnderReview => 'قيد المراجعة';

  @override
  String get statusPendingSecondApproval => 'بحاجة موافقة ثانية';

  @override
  String get statusApproved => 'تمت الموافقة';

  @override
  String get statusCrediting => 'جاري الشحن';

  @override
  String get statusCredited => 'تم الشحن';

  @override
  String get statusCreditFailed => 'فشل الشحن';

  @override
  String get statusNeedsReconciliation => 'بحاجة تدقيق';

  @override
  String get statusRejected => 'مرفوض';

  @override
  String get statusExpired => 'منتهي الصلاحية';

  @override
  String get statusReversed => 'تم عكس العملية';

  @override
  String get rejectionDuplicateProof => 'إيصال مكرر';

  @override
  String get rejectionProofUnreadable => 'إيصال غير واضح';

  @override
  String get rejectionProofMissing => 'لا يوجد إيصال';

  @override
  String get rejectionAmountMismatch => 'المبلغ غير مطابق';

  @override
  String get rejectionReferenceNotFound => 'مرجع الحوالة غير موجود';

  @override
  String get rejectionWrongDestination => 'وجهة دفع خاطئة';

  @override
  String get rejectionSenderMismatch => 'المُرسِل غير مطابق';

  @override
  String get rejectionSuspectedFraud => 'اشتباه احتيال';

  @override
  String get rejectionLimitExceeded => 'تجاوز الحدود';

  @override
  String get rejectionPlayerIneligible => 'اللاعب غير مؤهل';

  @override
  String get rejectionOther => 'أخرى';

  @override
  String get proofSourcePlayerUpload => 'رفع اللاعب';

  @override
  String get proofSourceAdminUpload => 'رفع المشرف';

  @override
  String get proofSourceTelegramPhoto => 'صورة من التيليغرام';

  @override
  String get proofSourceTelegramDocument => 'ملف من التيليغرام';

  @override
  String get proofSourceSystemImport => 'استيراد من النظام';

  @override
  String get creditVerifiedApiOk => 'أكّدها Ichancy API';

  @override
  String get creditVerifiedBalanceDelta => 'رُصد فرق في الرصيد';

  @override
  String get creditVerifiedManual => 'تأكيد يدوي';

  @override
  String get riskDuplicateProofExact => 'إيصال مكرر تماماً';

  @override
  String get riskDuplicateProofSimilar => 'إيصال مشابه';

  @override
  String get riskReferenceReused => 'مرجع مُعاد استخدامه';

  @override
  String get riskDuplicateProofSamePlayer => 'إيصال مكرر لنفس اللاعب';

  @override
  String get riskRapidResubmission => 'إعادة إرسال سريعة';

  @override
  String get riskLargeAmount => 'مبلغ كبير';

  @override
  String get riskNewPlayer => 'لاعب جديد';

  @override
  String get actionClaim => 'استلام';

  @override
  String get actionClaimDescription => 'أخذ المراجعة بعهدتك';

  @override
  String get actionRelease => 'تحرير';

  @override
  String get actionReleaseDescription => 'إعادته إلى الطابور';

  @override
  String get actionApprove => 'موافقة';

  @override
  String get actionApproveDescription => 'الموافقة والشحن';

  @override
  String get actionReject => 'رفض';

  @override
  String get actionRejectDescription => 'رفض هذا الإيداع';

  @override
  String get actionRetryCredit => 'إعادة الشحن';

  @override
  String get actionRetryCreditDescription => 'إعادة تشغيل الشحن الفاشل';

  @override
  String get blockOnlyFinanceAdminRetry => 'المدير المالي فقط يمكنه إعادة تشغيل الشحن.';

  @override
  String get blockRoleCannotDecide => 'دورك لا يسمح بالبتّ في الإيداعات.';

  @override
  String blockClaimedByOther({required int minutes}) => 'مراجع آخر مستلم هذا الإيداع لمدة $minutes د أخرى.';

  @override
  String get blockClaimedByOtherUnknown => 'مراجع آخر مستلم هذا الإيداع.';

  @override
  String get blockNotClaimHolder => 'المراجع المستلم فقط يمكنه التحرير.';

  @override
  String actionBlockedLine({required String action, required String reason}) => '$action: $reason';

  @override
  String get idleNotSubmittedYet => 'لم يرسل اللاعب هذا الإيداع بعد. لا يحرّكه سوى مهمة انتهاء الصلاحية.';

  @override
  String get idleApproved => 'تمت الموافقة. سيلتقطها عامل الشحن قريباً.';

  @override
  String get idleCrediting => 'الشحن قيد التنفيذ. تُعيد الصيانة جدولته إن توقف 20 دقيقة.';

  @override
  String get idleCredited => 'تم الشحن. انتهى هذا الإيداع.';

  @override
  String get idleRejected => 'مرفوض. انتهى هذا الإيداع.';

  @override
  String get idleExpired => 'منتهي الصلاحية. انتهى هذا الإيداع.';

  @override
  String get idleReversed => 'تم عكس العملية. انتهى هذا الإيداع.';

  @override
  String get idleNoActionForRole => 'لا يوجد إجراء متاح لدورك.';

  @override
  String get approveSheetTitle => 'الموافقة على الإيداع';

  @override
  String get approveSheetSecondTitle => 'منح الموافقة الثانية';

  @override
  String get amountYouVerified => 'تحققت منه';

  @override
  String get amountPlayerReceives => 'يستلم اللاعب';

  @override
  String get approveOverrideToggle => 'تصحيح المبلغ';

  @override
  String get approveOverrideOn => 'المبلغ المصحَّح يُسجَّل كالمبلغ المُتحقق.';

  @override
  String get approveOverrideOff => 'الإيقاف يعني أنك تحققت من المبلغ المُعلن كما هو.';

  @override
  String get verifiedAmountLabel => 'المبلغ المُتحقق';

  @override
  String get noteOptionalLabel => 'ملاحظة (اختياري)';

  @override
  String get approveNoteHint => 'ماذا تحققت منه؟';

  @override
  String get approveAdvisorySecondApproval => 'هذا الإيداع موقوف بانتظار موافقة ثانية. إن كنت صاحب الموافقة الأولى فسيرفض الخادم موافقتك.';

  @override
  String get approveAdvisoryThreshold => 'إذا تجاوز المبلغ حدّ الموافقة المزدوجة، يسجّل الخادم موافقة أولى فقط ولا يتحرك أي مبلغ حتى يوافق مشرف ثانٍ.';

  @override
  String get approveErrorInvalidAmount => 'أدخل مبلغاً صالحاً بمنزلتين عشريتين كحد أقصى.';

  @override
  String get approveErrorNotPositive => 'المبلغ المُتحقق يجب أن يكون أكبر من صفر.';

  @override
  String approveErrorBelowFee({required String fee}) => 'المبلغ المُتحقق لا يغطي عمولة $fee على وسيلة الدفع هذه.';

  @override
  String approveButton({required String amount}) => 'موافقة $amount';

  @override
  String get approveSecondButton => 'منح الموافقة الثانية';

  @override
  String get rejectSheetTitle => 'رفض الإيداع';

  @override
  String rejectSheetSubtitle({required String shortId, required String amount}) => '$shortId - $amount';

  @override
  String get rejectSheetNote => 'الرفض نهائي ولا يُسجَّل شيء في الدفاتر.';

  @override
  String get rejectReasonLabel => 'سبب الرفض';

  @override
  String get rejectNoteHint => 'أي شيء يجب أن يعرفه المراجع التالي';

  @override
  String get rejectChooseReason => 'اختر سبباً';

  @override
  String rejectButton({required String reason}) => 'رفض - $reason';

  @override
  String get unknownMethod => 'وسيلة غير معروفة';

  @override
  String get claimedChip => 'مستلَم';

  @override
  String claimedChipMinutes({required int minutes}) => 'مستلَم $minutes د';

  @override
  String riskMoreFlags({required String worst, required int count}) => '$worst +$count أخرى';

  @override
  String get timelineCreated => 'أُنشئ';

  @override
  String get timelineSubmitted => 'أُرسل للمراجعة';

  @override
  String get timelineNoProofAttached => 'بدون إيصال';

  @override
  String timelineProofsAttached({required int count}) => _plural(count, zero: 'بدون إيصال', one: 'إيصال واحد مرفق', two: 'إيصالان مرفقان', few: '$count إيصالات مرفقة', many: '$count إيصالاً مرفقاً');

  @override
  String get timelineClaimed => 'استُلم للمراجعة';

  @override
  String timelineAdmin({required String id}) => 'المشرف $id';

  @override
  String timelineRejectedWithReason({required String reason}) => 'مرفوض - $reason';

  @override
  String get timelineFirstApproval => 'سُجّلت الموافقة الأولى';

  @override
  String get timelineFirstApprovalSubtitle => 'لم يُسجَّل شيء في الدفاتر بعد.';

  @override
  String get timelineApproved => 'تمت الموافقة';

  @override
  String timelineSecondApprover({required String id}) => 'الموافق الثاني $id';

  @override
  String get timelineCredited => 'تم شحن رصيد اللاعب';

  @override
  String get timelineExpires => 'ينتهي';

  @override
  String timelineFuture({required String timestamp, required String timeLeft}) => '$timestamp (خلال $timeLeft)';

  @override
  String get moments => 'لحظات';

  @override
  String get timelineFooter => 'مُعاد بناؤه من توقيتات هذا الإيداع. الواجهة الإدارية لا تنشر سجل التنقلات.';

  @override
  String get ageNow => 'الآن';

  @override
  String ageSeconds({required int count}) => '$count ث';

  @override
  String ageMinutes({required int count}) => '$count د';

  @override
  String ageHours({required int count}) => '$count س';

  @override
  String ageHoursMinutes({required int hours, required int minutes}) => '$hours س $minutes د';

  @override
  String ageDays({required int count}) => '$count ي';

  @override
  String ageDaysHours({required int days, required int hours}) => '$days ي $hours س';

  @override
  String get ageInFuture => 'في المستقبل';

  @override
  String ageAgo({required String age}) => 'منذ $age';

  @override
  String timestampWithAge({required String timestamp, required String age}) => '$timestamp (منذ $age)';

  @override
  String get proofNone => 'لم يُرفع أي إيصال لهذا الإيداع.';

  @override
  String proofIndexOfTotal({required int index, required int total}) => 'إيصال $index من $total';

  @override
  String proofThumbnailCaption({required String source, required String size}) => '$source - $size';

  @override
  String get proofDecodeFailed => 'تعذّر فك ترميز الصورة.';

  @override
  String get proofViewerTitle => 'الإيصال';

  @override
  String get detailsTooltip => 'التفاصيل';

  @override
  String get proofDetailsTitle => 'تفاصيل الإيصال';

  @override
  String get proofDetailSource => 'المصدر';

  @override
  String get proofDetailStoredType => 'النوع المخزَّن';

  @override
  String get proofDetailServedAs => 'النوع المُرسَل';

  @override
  String get proofDetailSize => 'الحجم';

  @override
  String get proofDetailDimensions => 'الأبعاد';

  @override
  String get proofDetailUploaded => 'تاريخ الرفع';

  @override
  String get proofDetailSha256 => 'SHA-256';

  @override
  String get proofDetailFetchedVia => 'طريقة الجلب';

  @override
  String get proofViaPresignedUrl => 'رابط تخزين موقّع';

  @override
  String get proofViaApiStream => 'بثّ مُوثَّق عبر الواجهة';

  @override
  String sizeBytes({required int count}) => '$count بايت';

  @override
  String sizeKilobytes({required int count}) => '$count كيلوبايت';

  @override
  String sizeMegabytes({required String value}) => '$value ميغابايت';

  @override
  String dimensionLabel({required int width, required int height}) => '$width × $height';

  @override
  String get proofGone => 'هذا الإيصال لم يعد متاحاً.';

  @override
  String get proofDownloadFailed => 'تعذّر تنزيل صورة الإيصال.';

  @override
  String get proofDownloadCancelled => 'أُلغي تنزيل الإيصال.';

  @override
  String get proofEnvelopeInsteadOfBytes => 'أعاد الخادم JSON بدل بيانات الصورة. مسار بثّ الإيصالات يغلّف الملف داخل غلاف الاستجابة.';

  @override
  String get proofEnvelopeDetail => 'أبلغ فريق الخادم — الخلل ليس من التطبيق.';

  @override
  String get proofNotAnImage => 'الملف المُنزَّل ليس صورة قابلة للعرض.';

  @override
  String proofNotAnImageDetail({required String mimeType, required int bytes}) => 'النوع المخزَّن $mimeType، $bytes بايت';

  @override
  String get reportApproved => 'تمت الموافقة. سيُشحن رصيد اللاعب قريباً.';

  @override
  String reportLedgerTransaction({required String id}) => 'قيد الدفاتر $id';

  @override
  String get reportAwaitingSecondApproval => 'سُجّلت كموافقة أولى. يجب أن يوافق مشرف ثانٍ مختلف قبل تحريك أي مبلغ.';

  @override
  String get reportRejected => 'تم الرفض. لم يُسجَّل شيء في الدفاتر.';

  @override
  String get reportClaimed => 'تم الاستلام لمدة 10 دقائق.';

  @override
  String get reportReleased => 'أُعيد إلى الطابور.';

  @override
  String get reportAlreadyHandled => 'عالج شخص آخر هذا الإيداع قبلك.';

  @override
  String reportAlreadyHandledWithStatus({required String status}) => 'عالج شخص آخر هذا الإيداع قبلك — حالته الآن: $status.';

  @override
  String reportUnknownOutcome({required String kind}) => 'أعاد الخادم نتيجة لا يعرفها التطبيق («$kind»). تم تحديث الإيداع.';

  @override
  String reportActionFailed({required String action}) => 'تعذّر إتمام $action.';

  @override
  String get reportClaimedByOther => 'مراجع آخر يعمل على هذا الإيداع الآن.';

  @override
  String get reportDepositGone => 'هذا الإيداع لم يعد موجوداً.';

  @override
  String get reportClaimBackendDefect => 'الاستلام اصطدم بخلل معروف في الخادم: آلة الحالات لا تملك انتقال UNDER_REVIEW ← UNDER_REVIEW، فلا يمكن لهذا الطلب أن ينجح لأي إيداع. الطلب سليم؛ أبلغ فريق الخادم. الموافقة والرفض يعملان بدون استلام.';

  @override
  String get reportRetryCreditBackendDefect => 'إعادة الشحن اصطدمت بخلل معروف في الخادم (آلة الحالات ترفض انتقال إعادة المحاولة). الطلب سليم؛ أبلغ فريق الخادم.';

  @override
  String get reportAboveApprovalLimit => 'المبلغ يتجاوز صلاحيتك، فلم تتم أي موافقة. يجب أن يبتّ فيه مشرف أعلى.';

  @override
  String get reportSecondApproverMustDiffer => 'أنت وافقت على هذا الإيداع سابقاً. يجب أن يمنح الموافقة الثانية مشرف آخر.';

  @override
  String get reportVerifiedAmountRequired => 'المبلغ المُتحقق يجب أن يكون أكبر من صفر وأن يغطي العمولة.';

  @override
  String get reportInvalidState => 'لم تعد حالة هذا الإيداع تسمح بهذا الإجراء.';

  @override
  String detailNotFound({required String shortId}) => 'لا يوجد إيداع بالمرجع $shortId.';

  @override
  String get detailStillLoading => 'الإيداع ما زال قيد التحميل. حاول بعد لحظة.';

  @override
  String get detailActionInFlight => 'هناك إجراء آخر قيد التنفيذ.';

  @override
  String detailIllegalAction({required String status, required String action}) => 'هذا الإيداع $status ولم يعد بالإمكان تنفيذ «$action» عليه.';

  @override
  String get retryCreditRequeued => 'أُعيدت جدولة الشحن. سينفّذه العامل مجدداً.';

  @override
  String retryCreditEpochDetail({required int epoch}) => 'إصدار مفتاح الشحن $epoch';

  @override
  String retryCreditNotRequeued({required int epoch}) => 'لم تُعد جدولة شيء — الإيداع تجاوز هذه المرحلة. الإصدار ما زال $epoch.';

  @override
  String get detailStaleWarning => 'تُعرض آخر حالة معروفة — فشل تحديث الإيداع. اسحب للتحديث.';

  @override
  String signedInAsRole({required String role}) => 'مسجّل الدخول بدور $role.';

  @override
  String get reconciliationTitle => 'التسوية';

  @override
  String get refreshBreaksTooltip => 'تحديث المشاكل';

  @override
  String get tabBreaks => 'المشاكل';

  @override
  String get tabAgentFloat => 'رصيد الكاشيرة';

  @override
  String get tabRailAgeing => 'تقادم التحصيل';

  @override
  String get tabInvariants => 'القواعد';

  @override
  String attentionBadge({required int count}) => '$count بحاجة متابعة';

  @override
  String get breakScreenTitle => 'مشكلة تسوية';

  @override
  String get deniedActionOpenBreak => 'فتح مشكلة تسوية';

  @override
  String get loadingBreak => 'جارٍ تحميل المشكلة...';

  @override
  String correctFloatConfirmTitle({required String amount}) => 'تسجيل $amount في الدفاتر؟';

  @override
  String get correctFloatConfirmTitleFallback => 'الفرق';

  @override
  String get correctFloatConfirmMessage => 'هذا يسجّل حركة AGENT_FLOAT_SYNC تنقل دفاترنا لتطابق رقم Ichancy، ثم يغلق المشكلة كـ«تمت المعالجة». ليس كإغلاق المشكلة يدوياً، ولا يمكن إعادة المحاولة بأمان — إذا انتهت المهلة، أعد فتح هذه الشاشة بدل الضغط مرة ثانية.';

  @override
  String get correctFloatConfirmLabel => 'سجّل التصحيح';

  @override
  String get correctionNoteLabel => 'ملاحظة التصحيح';

  @override
  String get correctionNoteHint => 'لماذا يجب أن تتبع الدفاتر رقم Ichancy';

  @override
  String get cardTheDifference => 'الفرق';

  @override
  String get cardDetectorEvidence => 'أدلة الكشف';

  @override
  String get cardDetectorEvidenceSubtitle => 'نص حر: ما تركه الكاشف الذي فتح هذه المشكلة.';

  @override
  String get cardLinkedRecords => 'السجلات المرتبطة';

  @override
  String get breakReopenedNotice => 'أُغلقت هذه المشكلة مرة ثم أُعيد فتحها بإسناد. حقول الإغلاق أدناه تعود لذلك الإغلاق السابق، لا للوضع الحالي.';

  @override
  String get breakNoDetectorNotice => 'لا يوجد كاشف يكتب هذه الفئة اليوم، فهذا السطر غير معتاد. اقرأه بتمعّن.';

  @override
  String get chipAssigned => 'مُسندة';

  @override
  String get breakIdLabel => 'معرّف المشكلة';

  @override
  String get assignedToAdminLabel => 'مُسندة إلى المسؤول';

  @override
  String get dedupeKeyLabel => 'مفتاح منع التكرار';

  @override
  String get dedupeKeyHelp => 'تُحدَّث المشاكل على هذا المفتاح، فتكرار المشكلة ضمن الفترة نفسها يحدّث هذا السطر بدل إنشاء سطر جديد.';

  @override
  String get resolutionCardClosedTitle => 'كيف أُغلقت';

  @override
  String get resolutionCardEarlierTitle => 'إغلاق سابق';

  @override
  String get closedAtLabel => 'أُغلقت في';

  @override
  String get closedByAdminLabel => 'أغلقها المسؤول';

  @override
  String get ledgerCorrectionLabel => 'تصحيح الدفاتر';

  @override
  String get ledgerCorrectionNone => 'لا يوجد — الإغلاق لا يسجّل شيئاً';

  @override
  String get actionsCardTitle => 'الإجراءات';

  @override
  String actionsNeedRole({required String roles}) => 'الإسناد والإغلاق وتصحيح الدفاتر تحتاج $roles.';

  @override
  String actionsBreakClosedNotice({required String status}) => 'هذه المشكلة مغلقة كـ$status. إسنادها مجدداً يعيد فتحها مع بقاء ملاحظة الإغلاق القديمة، لذلك هذا الإجراء غير متاح عمداً.';

  @override
  String get takeOverBreak => 'استلم هذه المشكلة';

  @override
  String get assignToMe => 'أسندها لي';

  @override
  String get closeTheBreak => 'أغلق المشكلة';

  @override
  String get ledgerCorrectionExplain => 'الإغلاق يسجّل قراراً. التصحيح يسجّل في الدفاتر قيمة الفرق أعلاه ثم يغلق المشكلة كـ«تمت المعالجة». إجراءان مختلفان، وزرّان مختلفان.';

  @override
  String get correctTheLedger => 'صحّح الدفاتر';

  @override
  String get emptyBreaksTitle => 'لا شيء للتسوية';

  @override
  String get emptyBreaksMessage => 'لا مشكلة تطابق هذا الفلتر. وسّعه، أو شغّل مقارنة الرصيد أو فحص القواعد للبحث عن مشاكل جديدة.';

  @override
  String get loadingBreaks => 'جارٍ تحميل المشاكل...';

  @override
  String get resetFilterAction => 'إعادة ضبط الفلتر';

  @override
  String get outstandingDriftNotice => 'هناك مبالغ غير مغطاة الآن: مشكلة مفتوحة واحدة على الأقل ما زالت تحمل فرقاً غير صفري.';

  @override
  String get metricLoaded => 'المحمّلة';

  @override
  String get captionMoreAvailable => 'يوجد المزيد';

  @override
  String get captionAllOfThem => 'كلها';

  @override
  String get metricNeedAttention => 'بحاجة متابعة';

  @override
  String get captionSevereOrDrifting => 'خطيرة أو فيها فرق';

  @override
  String get captionNothingUrgent => 'لا شيء عاجل';

  @override
  String get breaksSortHint => 'الأحدث أولاً، حسب أول ظهور للمشكلة.';

  @override
  String get loadingMore => 'جارٍ تحميل المزيد...';

  @override
  String get endOfList => 'نهاية القائمة.';

  @override
  String get agentFloatSubtitle => 'يقارن حساب ICHANCY_AGENT_FLOAT في الدفاتر مع محفظة وكيل Ichancy. لا سماحية: أي فرق يفتح مشكلة.';

  @override
  String floatSyncNeedsRole({required String roles}) => 'تشغيل المقارنة يكتب في جدول المشاكل، لذلك يحتاج $roles.';

  @override
  String get comparingFloat => 'جارٍ المقارنة...';

  @override
  String get compareFloatNow => 'قارن الرصيد الآن';

  @override
  String get readingBothSides => 'جارٍ قراءة الطرفين...';

  @override
  String get noFloatReadingTitle => 'لا توجد قراءة بعد';

  @override
  String get noFloatReadingMessage => 'مقارنة الرصيد لا تعمل تلقائياً أبداً — فقد تفتح مشكلة. شغّلها عندما تحتاج الصورة الحيّة.';

  @override
  String get walletUnavailableNotice => 'تعذّرت قراءة محفظة Ichancy. هذا رد طبيعي (200) وليس فشلاً — لكن يظهر طرفنا فقط، ولم تُفتح أي مشكلة.';

  @override
  String belowWatermarkNotice({required String amount, required String basis}) => 'تحت حد الأمان: $amount ($basis).';

  @override
  String get watermarkBasisLedger => 'مقيس على دفاترنا، لأن قراءة المحفظة فشلت';

  @override
  String get watermarkBasisWallet => 'مقيس على محفظة Ichancy';

  @override
  String floatReadingAt({required String time}) => 'قراءة الساعة $time';

  @override
  String floatReadingSubtitle({required String currency, required String age}) => '$currency — $age';

  @override
  String get metricOurLedger => 'دفاترنا';

  @override
  String get metricIchancyWallet => 'محفظة Ichancy';

  @override
  String get moneyUnavailable => 'غير متاح';

  @override
  String get captionAvailableBalance => 'الرصيد المتاح';

  @override
  String get driftMetricLabel => 'الفرق (المنصة − دفاترنا)';

  @override
  String get moneyNotComputable => 'غير قابل للحساب';

  @override
  String get driftCaptionWalletUnknown => 'طرف Ichancy غير معروف، فلا يوجد فرق يمكن عرضه.';

  @override
  String get driftCaptionExact => 'متطابقان تماماً.';

  @override
  String get driftCaptionIchancyMore => 'Ichancy يحمل أكثر مما تقوله دفاترنا.';

  @override
  String get driftCaptionLedgerMore => 'دفاترنا تقول أكثر مما يحمله Ichancy.';

  @override
  String get breakOpenedTitle => 'فُتحت مشكلة أو حُدّثت';

  @override
  String get breakOpenedSubtitle => 'تُحدَّث المشاكل لكل عملة ولكل يوم UTC، فنفس الفرق اليوم يعيد استخدام هذا المعرّف.';

  @override
  String get openTheBreak => 'افتح المشكلة';

  @override
  String get noBreakWalletMissing => 'لم تُفتح أي مشكلة: مع غياب أحد الطرفين لا يوجد ما يُقارن.';

  @override
  String get noBreakInAgreement => 'لم تُفتح أي مشكلة: الطرفان متطابقان تماماً.';

  @override
  String get emptyRailAgeingTitle => 'لا أرصدة معلّقة';

  @override
  String get emptyRailAgeingMessage => 'كل حسابات التحصيل فارغة: لا يوجد شحن لم تؤكده جهة التحصيل.';

  @override
  String get loadingRailAgeing => 'جارٍ تجميع قيود الدفاتر...';

  @override
  String staleAccountsNotice({required int count, required String codes}) => '${_plural(count, zero: 'لا حسابات تحمل', one: 'حساب واحد يحمل', two: 'حسابان يحملان', few: '$count حسابات تحمل', many: '$count حساباً يحمل')} مبالغ غير مؤكدة منذ أكثر من ثلاثين يوماً: $codes.';

  @override
  String railAgeingGeneratedAt({required String timestamp}) => 'أُنشئ $timestamp. يُقرأ حيّاً مع كل طلب — لا يوجد تخزين مؤقت.';

  @override
  String railRowSubtitle({required String currency, required int count}) => '$currency — ${_plural(count, zero: 'لا قيود غير مسوّاة', one: 'قيد واحد غير مسوّى', two: 'قيدان غير مسوّيين', few: '$count قيود غير مسوّاة', many: '$count قيداً غير مسوّى')}';

  @override
  String get chipStale => 'متقادم';

  @override
  String get metricUnconfirmedBalance => 'رصيد غير مؤكد';

  @override
  String get metricOldestEntry => 'أقدم قيد';

  @override
  String get captionNoDatedEntries => 'لا قيود مؤرخة';

  @override
  String get byAge => 'حسب العمر';

  @override
  String get ledgerAccountLabel => 'حساب الدفاتر';

  @override
  String get ledgerInvariantsTitle => 'قواعد الدفاتر';

  @override
  String get ledgerInvariantsSubtitle => 'I1 كل حركة متوازنة ولها طرفان. I2 مجموع الدفاتر صفر لكل عملة. I3 الرصيد المخزّن لكل حساب يطابق قيوده.';

  @override
  String invariantsNeedRole({required String roles}) => 'تشغيل الفحص يكتب مشاكل ويصلح الأرصدة المخزّنة، لذلك يحتاج $roles.';

  @override
  String get sweeping => 'جارٍ الفحص...';

  @override
  String get runTheSweep => 'شغّل الفحص';

  @override
  String get sweepWarning => 'قد يستغرق وقتاً على دفاتر كبيرة. كل مخالفة تُكتب أيضاً كمشكلة LEDGER_IMBALANCE.';

  @override
  String get loadingSweep => 'جارٍ تجميع الدفاتر كاملة...';

  @override
  String get notSweptYetTitle => 'لم يُنفَّذ الفحص بعد';

  @override
  String get notSweptYetMessage => 'الفحص لا يعمل تلقائياً أبداً. شغّله عندما تريد التأكد أن الدفاتر ما زالت مضبوطة.';

  @override
  String get ledgerHealthyTitle => 'الدفاتر مضبوطة';

  @override
  String get ledgerHealthyBody => 'لا مخالفة لـ I1 أو I2 أو I3. كل حركة متوازنة، وكل عملة مجموعها صفر، والرصيد المخزّن لكل حساب يطابق قيوده.';

  @override
  String violationsFound({required int count}) => '${_plural(count, zero: 'لا مخالفات', one: 'مخالفة واحدة', two: 'مخالفتان', few: '$count مخالفات', many: '$count مخالفة')}. الدفاتر غير مضبوطة.';

  @override
  String get reportTruncatedNotice => 'بلغ التقرير حدّ المئة سطر: قد تكون هناك مخالفات أكثر مما هو مذكور هنا.';

  @override
  String sweptAt({required String timestamp}) => 'فُحصت $timestamp';

  @override
  String get entryCountsNoticeShort => 'هذه الأرقام الثلاثة عدد قيود، وليست مبالغ.';

  @override
  String subjectIdLabel({required String subjectKind}) => 'معرّف $subjectKind';

  @override
  String get expectedLabel => 'المتوقع';

  @override
  String get actualLabel => 'الفعلي';

  @override
  String get differenceLabel => 'الفرق';

  @override
  String get noExpectedActualPair => 'لا يوجد متوقع/فعلي لهذه المشكلة.';

  @override
  String get metricLedgerExpected => 'الدفاتر (المتوقع)';

  @override
  String get captionOurBooks => 'دفاترنا';

  @override
  String get metricObservedActual => 'المرصود (الفعلي)';

  @override
  String get captionTheOtherSide => 'الطرف الآخر';

  @override
  String get metricDifferenceActualExpected => 'الفرق (الفعلي − المتوقع)';

  @override
  String get deltaCaptionOneSideMissing => 'كان أحد الطرفين مفقوداً وقت كشف هذه المشكلة.';

  @override
  String get deltaCaptionNoDifference => 'لا يوجد فرق قائم.';

  @override
  String get deltaCaptionOtherSideMore => 'الطرف الآخر يحمل أكثر من دفاترنا.';

  @override
  String get deltaCaptionOurBooksMore => 'دفاترنا تحمل أكثر من الطرف الآخر.';

  @override
  String get entryCountsDriftNotice => 'هذه الأرقام عدد قيود، وليست مبالغ. الحركة بطرف واحد فيها قيود أقل مما تتطلبه الدفاتر.';

  @override
  String get metricEntriesRequired => 'القيود المطلوبة';

  @override
  String get metricEntriesFound => 'القيود الموجودة';

  @override
  String entryCountsRawExplain({required String currency}) => 'تُعرض كأعداد خام عمداً: الـ API يهيّئها بمقياس المال، فعدد قيود 2 كان سيُقرأ 0.02 $currency.';

  @override
  String get noDetectorEvidence => 'لم تُرفق أدلة كشف بهذه المشكلة.';

  @override
  String get ageingAtDetection => 'العمر عند الكشف';

  @override
  String get noEntriesInAnyBucket => 'لا قيود في أي شريحة.';

  @override
  String entriesCount({required int count}) => _plural(count, zero: 'لا قيود', one: 'قيد واحد', two: 'قيدان', few: '$count قيود', many: '$count قيداً');

  @override
  String get linkDepositRequest => 'طلب الإيداع';

  @override
  String get linkIchancyCall => 'عملية Ichancy';

  @override
  String get linkCorrectionTransaction => 'حركة التصحيح';

  @override
  String get noLinkedRecords => 'هذه المشكلة غير مرتبطة بإيداع أو لاعب أو حساب.';

  @override
  String get breakTouchesDepositNotice => 'هناك إيداع عالق في هذه المشكلة — بحاجة تدقيق قبل تسوية المبلغ.';

  @override
  String detectedAt({required String timestamp}) => 'كُشفت $timestamp';

  @override
  String get breakFilterSheetTitle => 'تصفية المشاكل';

  @override
  String get filterDefaultHint => 'بدون اختيار حالة، يعرض الخادم المشاكل المفتوحة وقيد التحقيق فقط.';

  @override
  String get filterCategoryHeading => 'الفئة';

  @override
  String get filterCategoryHint => 'فرق رصيد الكاشيرة وإيصال غير معروف وعدم توازن الدفاتر فقط هي ما ينتجه كاشف اليوم.';

  @override
  String get filterMinSeverityHeading => 'أدنى خطورة';

  @override
  String get filterAll => 'الكل';

  @override
  String get filterDone => 'تم';

  @override
  String tileEntriesOfEntries({required int actual, required int expected}) => '$actual من $expected قيد';

  @override
  String get moneyNoDifferenceRecorded => 'لا فرق مسجّل';

  @override
  String get tileReopenedNote => 'أُعيد فتحها بعد إغلاق سابق — ملاحظة الإغلاق القديمة ما زالت مرفقة.';

  @override
  String get closeBreakSheetTitle => 'إغلاق هذه المشكلة';

  @override
  String get closeBreakSheetHint => 'الإغلاق لا يحرّك أي مبلغ. يسجّل قراراً، والملاحظة هي الدليل أن القرار اتُّخذ عن قصد.';

  @override
  String get resolutionNoteLabel => 'ملاحظة الإغلاق (إلزامية)';

  @override
  String get resolutionNoteHint => 'ماذا دقّقت، وما الخلاصة؟';

  @override
  String closeAsStatus({required String status}) => 'أغلق كـ$status';

  @override
  String get deniedTitle => 'ليست صلاحيتك';

  @override
  String deniedSignedOut({required String action}) => 'سجّل الدخول لـ$action.';

  @override
  String deniedRoleCannot({required String role, required String action}) => '$role لا يمكنه $action.';

  @override
  String deniedAllowedRoles({required String roles}) => 'المسموح: $roles';

  @override
  String get deniedActionViewReconciliation => 'عرض التسوية';

  @override
  String get breakStatusOpen => 'مفتوحة';

  @override
  String get breakStatusInvestigating => 'قيد التحقيق';

  @override
  String get breakStatusResolved => 'تمت المعالجة';

  @override
  String get breakStatusWrittenOff => 'مشطوبة';

  @override
  String get breakStatusFalsePositive => 'إنذار خاطئ';

  @override
  String get breakStatusUnknown => 'غير معروفة';

  @override
  String get closingMeaningResolved => 'الفرق كان حقيقياً وعُولج خارج هذه المشكلة.';

  @override
  String get closingMeaningWrittenOff => 'الفرق حقيقي ولن يُسترد، ونقبله كخسارة.';

  @override
  String get closingMeaningFalsePositive => 'لم يكن هناك فرق فعلي؛ الكاشف أخطأ.';

  @override
  String get closingMeaningNotClosing => 'ليست حالة إغلاق.';

  @override
  String get breakCategoryAgentFloatMismatch => 'فرق رصيد الكاشيرة';

  @override
  String get breakCategoryPlayerBalanceMismatch => 'فرق رصيد لاعب';

  @override
  String get breakCategoryMissingCredit => 'شحن مفقود';

  @override
  String get breakCategoryDuplicateCredit => 'شحن مكرر';

  @override
  String get breakCategoryUnidentifiedReceipt => 'إيصال غير معروف';

  @override
  String get breakCategoryLedgerImbalance => 'عدم توازن الدفاتر';

  @override
  String get breakCategoryOrphanIchancyCall => 'عملية Ichancy يتيمة';

  @override
  String get breakCategoryStuckDeposit => 'إيداع عالق';

  @override
  String get breakCategoryUnknown => 'فئة غير معروفة';

  @override
  String get severity1 => 'S1 للعلم';

  @override
  String get severity2 => 'S2 منخفضة';

  @override
  String get severity3 => 'S3 انحراف';

  @override
  String get severity4 => 'S4 خطيرة';

  @override
  String get severity5 => 'S5 مال مفقود';

  @override
  String severityShort({required int n}) => 'S$n';

  @override
  String detailValueItems({required int count}) => _plural(count, zero: 'لا عناصر', one: 'عنصر واحد', two: 'عنصران', few: '$count عناصر', many: '$count عنصراً');

  @override
  String detailValueFields({required int count}) => _plural(count, zero: 'لا حقول', one: 'حقل واحد', two: 'حقلان', few: '$count حقول', many: '$count حقلاً');

  @override
  String get filterDescribeDefault => 'المشاكل غير المغلقة';

  @override
  String filterDescribeSeverity({required String severity}) => 'خطورة $severity فما فوق';

  @override
  String get evidenceIchancyAvailable => 'المتاح لدى Ichancy';

  @override
  String get evidenceIchancyBalance => 'رصيد Ichancy';

  @override
  String get evidenceLedger => 'الدفاتر';

  @override
  String get evidenceDelta => 'الفرق';

  @override
  String get evidenceAccountCode => 'رمز الحساب';

  @override
  String get evidenceOldestUnsettledAt => 'أقدم قيد غير مسوّى';

  @override
  String get evidenceSubject => 'العنصر';

  @override
  String get evidenceTruncated => 'مقتطع';

  @override
  String get evidenceInvariant => 'القاعدة';

  @override
  String get invariantI1TransactionZeroSum => 'I1 توازن الحركة';

  @override
  String get invariantI1TransactionZeroSumExplain => 'حركة في الدفاتر مجموعها لا يساوي صفراً.';

  @override
  String get invariantI1SingleSided => 'I1 حركة بطرف واحد';

  @override
  String get invariantI1SingleSidedExplain => 'حركة في الدفاتر فيها أقل من قيدين.';

  @override
  String get invariantI2GlobalZeroSum => 'I2 التوازن العام';

  @override
  String get invariantI2GlobalZeroSumExplain => 'مجموع الدفاتر كلها لا يساوي صفراً لهذه العملة.';

  @override
  String get invariantI3CachedBalanceDrift => 'I3 انحراف الرصيد المخزّن';

  @override
  String get invariantI3CachedBalanceDriftExplain => 'الرصيد المخزّن للحساب لا يطابق مجموع قيوده.';

  @override
  String get invariantUnknown => 'قاعدة غير معروفة';

  @override
  String get invariantUnknownExplain => 'قاعدة لا يعرفها هذا الإصدار.';

  @override
  String get subjectKindTransaction => 'حركة';

  @override
  String get subjectKindCurrency => 'عملة';

  @override
  String get subjectKindAccount => 'حساب';

  @override
  String get subjectKindSubject => 'عنصر';

  @override
  String get bucket0to1d => '0-1 ي';

  @override
  String get bucket1to3d => '1-3 ي';

  @override
  String get bucket3to7d => '3-7 ي';

  @override
  String get bucket7to30d => '7-30 ي';

  @override
  String get bucket30dPlus => '30 ي+';

  @override
  String get actionAssignedToYou => 'أُسندت إليك.';

  @override
  String actionClosedAsStatus({required String status}) => 'أُغلقت كـ$status.';

  @override
  String get actionOnlyTerminalStatuses => 'لا يمكن إغلاق المشكلة إلا كـ«تمت المعالجة» أو «مشطوبة» أو «إنذار خاطئ».';

  @override
  String get resolutionNoteRequired => 'ملاحظة الإغلاق إلزامية.';

  @override
  String get correctionNoteRequired => 'ملاحظة التصحيح إلزامية.';

  @override
  String get breakAlreadyClosedByOther => 'أغلقها شخص آخر قبلك.';

  @override
  String breakAlreadyClosedAsStatus({required String status}) => 'أُغلقت مسبقاً كـ$status.';

  @override
  String get breakNoLongerExists => 'هذه المشكلة لم تعد موجودة. يجري تحديث القائمة.';

  @override
  String correctionPosted({required String amount}) => 'سُجّل $amount في الدفاتر.';

  @override
  String get correctionAlreadyResolved => 'هذه المشكلة مغلقة أصلاً. إذا انتهت مهلة تصحيح سابق فالأرجح أنه نُفّذ — راجع حركة الدفاتر على المشكلة.';

  @override
  String get correctionNothingToCorrect => 'لا يوجد فرق قائم لتصحيحه في هذه المشكلة.';

  @override
  String ledgerRefusedCorrection({required String reference}) => 'رفضت الدفاتر التصحيح. أعطِ $reference للدعم، وراجع المشكلة قبل إعادة المحاولة.';

  @override
  String get correlationIdFallback => 'معرّف الارتباط';

  @override
  String assignWouldReopen({required String status}) => 'هذه المشكلة مغلقة كـ$status. إسنادها يعيد فتحها ويُبقي ملاحظة الإغلاق القديمة.';

  @override
  String get breakStillLoading => 'المشكلة ما زالت قيد التحميل. حاول بعد قليل.';

  @override
  String get onlyFloatMismatchCorrectable => 'فرق رصيد الكاشيرة فقط يمكن تصحيحه بهذه الطريقة.';

  @override
  String get anotherActionRunning => 'هناك إجراء آخر على هذه المشكلة ما زال يعمل.';

  @override
  String get pmScreenTitle => 'طرق الدفع';

  @override
  String get pmNewMethodButton => 'طريقة دفع جديدة';

  @override
  String get pmReadersDeniedMessage => 'إعدادات الدفع متاحة للقراءة للمدير العام والمدير المالي والمراجع وموظف الدعم. الخادم يرفض كل طلبات هذه الشاشة لدور المطّلع.';

  @override
  String get pmEmptyTitle => 'لا توجد طرق دفع بعد';

  @override
  String get pmFilterEmptyTitle => 'لا شيء يطابق هذا الفلتر';

  @override
  String get pmEmptyMessageManager => 'أنشئ واحدة ليتمكن اللاعبون من الإيداع. لا تنسَ إضافة حساب استلام حقيقي قبل استقبال أي مبلغ.';

  @override
  String get pmEmptyMessageReader => 'لا يوجد أي إعداد بعد.';

  @override
  String get pmFilterEmptyMessage => 'امسح الفلتر لرؤية كل الطرق المُعدّة.';

  @override
  String get pmLoadingList => 'جارٍ تحميل طرق الدفع...';

  @override
  String get pmStatusActive => 'مفعّلة';

  @override
  String get pmStatusDisabled => 'معطّلة';

  @override
  String get pmFilterRailTooltip => 'تصفية حسب نوع التحويل';

  @override
  String get pmFilterEveryRail => 'كل الأنواع';

  @override
  String get pmDetailTitle => 'وسيلة الدفع';

  @override
  String get pmLoadingMethod => 'جارٍ تحميل وسيلة الدفع...';

  @override
  String pmNoDriverTitle({required String rail}) => 'لا يوجد مشغّل لنوع $rail';

  @override
  String get pmNoDriverMessage => 'لم يُرجع الخادم أي حقول إثبات مطلوبة لهذا النوع، أي أنه بلا مشغّل. لا يستطيع اللاعبون الإيداع على هذه الطريقة إطلاقاً، ولا يمكن إنشاء طريقة جديدة على هذا النوع (422 RAIL_NOT_SUPPORTED).';

  @override
  String get pmRecordSection => 'بيانات السجل';

  @override
  String get pmIdentifierLabel => 'المعرّف';

  @override
  String get pmIdentifierHint => 'معرّف UUID تستخدمه كل طلبات هذه الشاشة.';

  @override
  String get pmLastUpdatedLabel => 'آخر تعديل';

  @override
  String get pmLastUpdatedHint => 'كل حفظ يسجّل سطراً في سجل التدقيق، حتى لو كان فارغاً.';

  @override
  String pmHeaderSubtitle({required String rail, required String currency}) => '$rail — $currency';

  @override
  String get pmMachineCodeLabel => 'رمز النظام';

  @override
  String get pmMachineCodeHint => 'لا يتغيّر. البيانات الأولية والتطبيق المصغّر يعتمدان عليه دائماً.';

  @override
  String get pmRailLabel => 'نوع التحويل';

  @override
  String get pmImmutableAfterCreationHint => 'لا يمكن تغييره بعد الإنشاء.';

  @override
  String get currencyLabel => 'العملة';

  @override
  String get pmSortOrderLabel => 'ترتيب العرض';

  @override
  String get enableButton => 'تفعيل';

  @override
  String get disableButton => 'تعطيل';

  @override
  String pmEnableMethodTitle({required String name}) => 'تفعيل $name؟';

  @override
  String pmDisableMethodTitle({required String name}) => 'تعطيل $name؟';

  @override
  String get pmEnableMethodMessage => 'سيتمكن اللاعبون من اختيار هذه الطريقة مجدداً. راجع حسابات الاستلام أولاً — الحساب الوهمي المعطّل لا يحمي أحداً بعد تفعيل الطريقة.';

  @override
  String get pmDisableMethodMessage => 'لن يستطيع اللاعبون بدء إيداع على هذه الطريقة. لا شيء يُحذف: الإيداعات الحالية تبقى مرتبطة بها ويمكنك تفعيلها في أي وقت.';

  @override
  String get pmLimitsSection => 'الحدود والعمولات';

  @override
  String get pmLimitsSubtitle => 'المبالغ محفوظة بالوحدات الصغرى بدقة كاملة؛ هذه الشاشة فقط تنسّقها للعرض.';

  @override
  String get pmMinimumLabel => 'الحد الأدنى';

  @override
  String get pmMinimumHint => 'أي إيداع أقل من هذا يُرفض بالرمز AMOUNT_BELOW_MINIMUM.';

  @override
  String get pmMaximumLabel => 'الحد الأعلى';

  @override
  String get pmMaximumHint => 'فوق هذا الحد يرد النوع بالرمز AMOUNT_ABOVE_MAXIMUM.';

  @override
  String get pmFixedFeeLabel => 'عمولة ثابتة';

  @override
  String get pmFixedFeeHint => 'يجب أن تبقى أقل من الحد الأدنى تماماً، وإلا فأصغر إيداع مسموح لن يشحن شيئاً.';

  @override
  String get pmVariableFeeLabel => 'عمولة نسبية';

  @override
  String pmVariableFeeValue({required int bps, required String percent}) => '$bps نقطة أساس ($percent)';

  @override
  String get pmVariableFeeHint => 'نقاط أساس. 10000 = 100%. التقريب لأقرب أعلى عند النصف.';

  @override
  String get pmFeeAtMinimumLabel => 'العمولة عند الحد الأدنى';

  @override
  String get pmCreditedAtMinimumLabel => 'المشحون عند الحد الأدنى';

  @override
  String get pmCreditedAtMinimumHintOk => 'ما يستلمه فعلياً لاعب يودع الحد الأدنى.';

  @override
  String get pmCreditedAtMinimumHintBad => 'أصغر إيداع مسموح لا يشحن شيئاً. عدّل العمولة.';

  @override
  String get pmFeeAtMaximumLabel => 'العمولة عند الحد الأعلى';

  @override
  String get pmVerificationSection => 'التحقق';

  @override
  String get pmVerificationModeRowLabel => 'الطريقة';

  @override
  String get pmVerificationModeHint => 'بيانات مخزّنة فقط: النسخة الأولى لا تقرأ كشوف الحسابات، وكل الأنواع تُراجع يدوياً مهما كانت هذه القيمة.';

  @override
  String get referenceLabel => 'مرجع الحوالة';

  @override
  String get pmReferenceRequiredValue => 'مطلوب من اللاعب';

  @override
  String get pmReferenceOptionalValue => 'اختياري';

  @override
  String pmReferenceMootHint({required String rail, required String state}) => 'مشغّل $rail يطلب REFERENCE أصلاً، لذلك مفتاح «يتطلب مرجع حوالة» لا يستطيع جعله اختيارياً — هو حالياً $state ولا يغيّر شيئاً.';

  @override
  String get pmReferenceSwitchHint => 'يتحدد بمفتاح «يتطلب مرجع حوالة» في هذه الطريقة.';

  @override
  String get pmReferencePatternRowLabel => 'نمط مرجع الحوالة';

  @override
  String get noneLabel => 'لا يوجد';

  @override
  String get pmReferencePatternHint => 'تعبير نمطي خام، يُطبَّق على ما يكتبه اللاعب بعد حدّ 128 حرفاً.';

  @override
  String get pmReferencePatternNoneHint => 'يُقبل أي مرجع غير فارغ.';

  @override
  String get pmProofFieldsIntro => 'حقول الإثبات التي يطلبها نموذج اللاعب، بالترتيب:';

  @override
  String get pmProofFieldsNone => 'لا يوجد — هذا النوع بلا مشغّل.';

  @override
  String get pmPatternBrokenTitle => 'نمط مرجع الحوالة لا يُترجم برمجياً';

  @override
  String pmPatternBrokenMessage({required String error}) => 'الخادم لا يتحقق أبداً من صحة النمط: يعامل النمط المعطوب كأنه «بلا نمط» بصمت، فلن يبلّغك الخادم بهذا أبداً. ($error)';

  @override
  String get pmHumanCheckedTitle => 'بعض حقول الإثبات يتحقق منها موظف، لا الخادم';

  @override
  String get pmHumanCheckedMessage => 'ما يصل إلى مشغّل النوع هو مرجع الحوالة وحساب المُرسِل وعدد الإيصالات فقط. هذه الحقول تحدد نموذج اللاعب وقائمة تدقيق المراجع، لكن لا شيء يتحقق منها:';

  @override
  String get pmInstructionsSection => 'تعليمات اللاعب';

  @override
  String get pmInstructionsSubtitle => 'تُعرض داخل رسالة التيليغرام التي يقرأها اللاعب.';

  @override
  String get pmInstructionsEmpty => 'لا توجد تعليمات. يرى اللاعب بيانات حساب الاستلام فقط.';

  @override
  String get pmDestinationsHeading => 'حسابات الاستلام';

  @override
  String get pmHideDisabled => 'إخفاء المعطّلة';

  @override
  String get pmShowAll => 'عرض الكل';

  @override
  String get pmDestinationsOrderNote => 'مرتّبة كما يوزّعها المحدّد تماماً: الأولوية تصاعدياً، والأقل يُعرض أولاً.';

  @override
  String get pmLoadingDestinations => 'جارٍ تحميل حسابات الاستلام...';

  @override
  String get pmAddDestination => 'إضافة حساب استلام';

  @override
  String get pmNoDestinationsTitle => 'لا يوجد حساب استلام';

  @override
  String get pmNoDestinationsMessage => 'كل إيداع لاعب على هذه الطريقة سيفشل بالرمز 422 NO_DESTINATION_AVAILABLE حتى تضيف واحداً.';

  @override
  String get pmDisabledHiddenTitle => 'الصفوف المعطّلة مخفية';

  @override
  String get pmDisabledHiddenMessage => 'اضغط «عرض الكل» — قد يكون هنا حساب استلام معطّل.';

  @override
  String get pmNoActiveDestinationTitle => 'لا يوجد حساب استلام مفعّل';

  @override
  String get pmNoActiveDestinationMessage => 'كل إيداع لاعب على هذه الطريقة سيفشل بالرمز 422 NO_DESTINATION_AVAILABLE حتى تفعّل واحداً.';

  @override
  String pdEnableTitle({required String label}) => 'تفعيل $label؟';

  @override
  String pdDisableTitle({required String label}) => 'تعطيل $label؟';

  @override
  String get pdEnableMessage => 'يمكن توجيه اللاعبين الجدد إلى هنا مجدداً. تأكد أن بيانات الحساب حقيقية.';

  @override
  String get pdDisableLastMessage => 'هذا آخر حساب استلام مفعّل. تعطيله يجعل كل إيداعات اللاعبين على هذه الطريقة تفشل بالرمز NO_DESTINATION_AVAILABLE.';

  @override
  String get pdDisableMessage => 'يتوقف توجيه اللاعبين الجدد إليه فوراً. اللاعب الذي طُلب منه الدفع هنا يحتفظ بالتثبيت لمدة 24 ساعة ويمكنه إتمام العملية.';

  @override
  String get pmFormEditTitle => 'تعديل الطريقة';

  @override
  String get pmFormCreateTitle => 'طريقة دفع جديدة';

  @override
  String get pmManagersDeniedTitle => 'لا يمكنك تعديل إعدادات الدفع';

  @override
  String get pmManagersDeniedMessage => 'إنشاء طرق الدفع وتعديلها محصور بالمدير العام والمدير المالي، لأن هذه الإعدادات توجّه أموالاً حقيقية.';

  @override
  String get pmFixBeforeSaving => 'صحّح هذه قبل الحفظ';

  @override
  String get pmIdentitySection => 'التعريف';

  @override
  String get pmIdentitySubtitleEdit => 'رمز النظام ونوع التحويل والعملة غير قابلة للتعديل — نقطة التحديث ترفضها مباشرة.';

  @override
  String get pmIdentitySubtitleCreate => 'هذه الثلاثة لا يمكن تغييرها بعد الحفظ أبداً.';

  @override
  String get pmMachineCodeHelper => 'أحرف كبيرة وشرطة سفلية، 2-48 حرفاً. يُحوّل لأحرف كبيرة عند الحفظ. ثابت للأبد.';

  @override
  String get pmRailHelper => 'يحدد حقول الإثبات التي يطلبها نموذج اللاعب. النوع INTERNAL غير متاح: لا مشغّل له.';

  @override
  String pmCurrencyHelper({required String currency}) => 'ثلاثة أحرف، ويجب أن تكون موجودة في جدول العملات. $currency فقط مضافة.';

  @override
  String get displayNameLabel => 'الاسم الظاهر';

  @override
  String get pmDisplayNameHelper => 'ما يراه اللاعب في قائمة الإيداع.';

  @override
  String get pmVerificationModeLabel => 'طريقة التحقق';

  @override
  String get pmVerificationModeHelper => 'بيانات مخزّنة فقط. النسخة الأولى تراجع كل الأنواع يدوياً مهما كانت القيمة.';

  @override
  String get pmSortOrderHelper => 'تصاعدي، ويقبل السالب. عند التساوي يُرتّب حسب الاسم الظاهر.';

  @override
  String get pmActiveSwitchOn => 'يستطيع اللاعبون اختيار هذه الطريقة.';

  @override
  String get pmActiveSwitchOff => 'مخفية عن اللاعبين. لا شيء يُحذف.';

  @override
  String get pmProofFieldsPreview => 'حقول الإثبات التي سيطلبها هذا النوع:';

  @override
  String get pmLimitsFormSubtitle => 'تُرسل كنص عشري بالوحدة الكبرى بمنزلتين كحد أقصى. تُقرأ هنا كوحدات صغرى دقيقة — بلا أي كسور عائمة.';

  @override
  String get pmMinAmountLabel => 'أقل مبلغ';

  @override
  String get pmMinAmountHelper => 'يجب أن يكون أكبر من صفر.';

  @override
  String get pmMaxAmountLabel => 'أعلى مبلغ';

  @override
  String get pmMaxAmountHelper => 'يجب ألا يقل عن الحد الأدنى.';

  @override
  String get pmFeeFixedHelper => 'اختياري. يجب أن يكون أقل من الحد الأدنى تماماً.';

  @override
  String get pmFeeBpsLabel => 'عمولة نسبية (نقطة أساس)';

  @override
  String get pmFeeBpsHelper => 'من 0 إلى 10000. 10000 = 100%. التقريب لأقرب أعلى عند النصف.';

  @override
  String pmMoneyWillBeSent({required String value}) => 'سيُرسل بالشكل «$value».';

  @override
  String pmCreditPreview({required String min, required String fee, required String credited}) => 'اللاعب الذي يودع الحد الأدنى ($min) يدفع $fee عمولة ويُشحن له $credited.';

  @override
  String get pmCreditsNothingWarning => 'هذا لا يشحن شيئاً. الخادم يرفضه بالرمز PAYMENT_METHOD_INVALID على الحقل feeFixed.';

  @override
  String get pmRequiresReferenceSwitch => 'يتطلب مرجع حوالة';

  @override
  String pmRequiresReferenceOnRail({required String rail}) => 'مشغّل $rail يطلب مرجع الحوالة أصلاً، فإطفاء هذا لا يغيّر شيئاً بالنسبة للاعب.';

  @override
  String get pmRequiresReferenceHint => 'عند تفعيله يصبح مرجع الحوالة مطلوباً عند الإرسال.';

  @override
  String get pmReferencePatternFieldLabel => 'نمط مرجع الحوالة (تعبير نمطي)';

  @override
  String get pmReferencePatternFieldHelper => 'تعبير نمطي خام، بلا شرطات مائلة وبلا رايات، 256 حرفاً كحد أقصى. اتركه فارغاً لقبول أي مرجع.';

  @override
  String get pmPatternMayNotWorkTitle => 'قد لا يعمل هذا النمط';

  @override
  String get pmProbeLabel => 'جرّب مرجعاً على النمط';

  @override
  String get pmProbeIdleHelper => 'الخادم لا يتحقق من هذا النمط أبداً. النمط الخاطئ يرفض كل مراجع الإيداع على هذه الطريقة، ولا يراه إلا اللاعبون.';

  @override
  String get pmProbeAccepted => 'مقبول.';

  @override
  String get pmProbeRejected => 'مرفوض — سيرى اللاعب الرمز REFERENCE_MALFORMED.';

  @override
  String get pmPatternCannotClearTitle => 'لا يمكن مسح النمط نهائياً';

  @override
  String get pmPatternCannotClearMessage => 'نقطة التحديث ترفض القيمة الفارغة وتتجاهل المفتاح المحذوف. حفظ الحقل فارغاً يخزّن نصاً فارغاً يعامله المشغّل كـ«بلا نمط» — وهو أقرب إجراء متاح.';

  @override
  String get pmInstructionsFormSubtitle => '2000 حرف كحد أقصى، تُعرض كـ HTML آمن للتيليغرام.';

  @override
  String get pmInstructionsFieldHelper => 'تُعرض فوق بيانات حساب الاستلام. تُضاف ملاحظات الحساب بعدها حرفياً.';

  @override
  String get pmBothLimitsRequired => 'الحدّان مطلوبان.';

  @override
  String get pdFormEditTitle => 'تعديل حساب الاستلام';

  @override
  String get pdFormCreateTitle => 'حساب استلام جديد';

  @override
  String get pdManagersDeniedTitle => 'لا يمكنك تعديل حسابات الاستلام';

  @override
  String get pdManagersDeniedMessage => 'المدير العام والمدير المالي فقط يمكنهما تغيير وجهة أموال اللاعبين.';

  @override
  String get pdCryptoChainTitle => 'على هذا النوع، الاسم هو الشبكة نفسها';

  @override
  String pdCryptoChainMessage({required String label}) => 'يقرأ اللاعب «Network: $label». اسم شبكة خاطئ يرسل الأموال إلى مكان لا يمكن استرجاعها منه. هذا المشغّل يتجاهل حقل صاحب الحساب.';

  @override
  String get pdAccountSubtitle => 'الحساب الذي يُطلب من اللاعب الدفع إليه.';

  @override
  String pdLabelFieldLabel({required String caption}) => '$caption (الاسم)';

  @override
  String get pdAccountIdentifierHelper => 'يُحفظ كما تكتبه تماماً — تُزال المسافات الطرفية فقط، ولا يُحوّل شيء لأحرف كبيرة. لا يتغيّر بعد الحفظ.';

  @override
  String get pdAccountIdentifierImmutableHint => 'لا يتغيّر: الإيداعات السابقة مرتبطة به وهو نصف مفتاح التفرّد. لتغيير الحساب أضف حساب استلام جديداً وعطّل هذا.';

  @override
  String get pdPlaceholderTypedTitle => 'هذا ما زال يبدو حساباً وهمياً';

  @override
  String get pdPlaceholderTypedMessage => 'اللاعب الذي يدفع إلى حساب وهمي يرسل أمواله إلى لا مكان. أدخل بيانات الحساب الحقيقية.';

  @override
  String pdAccountHolderIgnoredHelper({required String rail}) => 'مشغّل $rail يتجاهله، لكنه يُحفظ لسجلاتك.';

  @override
  String get pdAccountHolderHelper => 'يُعرض للاعب بجانب الحساب.';

  @override
  String get pdStatusActive => 'مفعّل';

  @override
  String get pdStatusDisabled => 'معطّل';

  @override
  String get pdActiveSwitchOn => 'يمكن للمحدّد الدوري توجيه اللاعبين الجدد إليه.';

  @override
  String get pdActiveSwitchOff => 'لا يُعطى لأحد. اللاعبون الذين طُلب منهم الدفع هنا يحتفظون بالتثبيت لمدة 24 ساعة ويمكنهم إتمام العملية.';

  @override
  String get pdRoutingSection => 'التوزيع';

  @override
  String get pdRoutingSubtitle => 'كيف يوزّع المحدّد الحركة بين حسابات الاستلام.';

  @override
  String get pdPriorityLabel => 'الأولوية';

  @override
  String get pdPriorityHelper => 'الأقل يُعرض أولاً. تُقلب إلى وزن دوري بحد أقصى 16، فالقيمتان 0 و4 توزّعان الحركة بنسبة 5:1 تقريباً. ليست علامة «مفضّل».';

  @override
  String pdDailyCapLabel({required String currency}) => 'السقف اليومي ($currency)';

  @override
  String get pdDailyCapHelper => 'سقف مرن اختياري يُحسب على المبالغ المُعلنة. إذا تجاوزت كل الحسابات سقفها، يتجاهل المحدّد السقوف بدل إيقاف اللاعب.';

  @override
  String pdDailyCapHelperParsed({required String value}) => 'سيُرسل بالشكل «$value». سقف مرن: يتجاهله المحدّد عندما تتجاوزه كل الحسابات.';

  @override
  String get pdCapCannotBeRemovedTitle => 'لا يمكن إزالة السقف من هذه الواجهة';

  @override
  String get pdCapCannotBeRemovedMessage => 'نقطة التحديث ترفض القيمة الفارغة، والنص الفارغ يفشل في تنسيق المبلغ، فالسقف يمكن استبداله بمبلغ آخر فقط. مسحه ثغرة في الخادم.';

  @override
  String get notesLabel => 'ملاحظات';

  @override
  String get pdNotesSubtitle => 'تُضاف حرفياً إلى التعليمات التي يقرأها اللاعب.';

  @override
  String get pdNotesHelper => '1000 حرف كحد أقصى. اللاعب يقرأها، فاكتبها تشغيلية لا داخلية.';

  @override
  String get pdDailyCapFieldLabel => 'السقف اليومي';

  @override
  String get railBankTransfer => 'حوالة بنكية';

  @override
  String get railMobileWallet => 'محفظة موبايل';

  @override
  String get railCashOffice => 'مكتب صرافة';

  @override
  String get railCrypto => 'عملات رقمية';

  @override
  String get railInternal => 'داخلي';

  @override
  String get destCaptionBank => 'البنك';

  @override
  String get destCaptionWallet => 'المحفظة';

  @override
  String get destCaptionOffice => 'المكتب';

  @override
  String get networkLabel => 'الشبكة';

  @override
  String get destCaptionLabel => 'الاسم';

  @override
  String get destHintBank => 'اسم البنك، يظهر للاعب';

  @override
  String get destHintWallet => 'اسم مزوّد المحفظة';

  @override
  String get destHintOffice => 'اسم مكتب الصرافة';

  @override
  String get destHintCrypto => 'اسم الشبكة — اللاعب يدفع على هذه الشبكة';

  @override
  String get destHintInternal => 'الاسم الذي يظهر للاعب';

  @override
  String get accountCaptionBank => 'IBAN / رقم الحساب';

  @override
  String get accountCaptionWallet => 'رقم المحفظة (MSISDN)';

  @override
  String get accountCaptionOffice => 'رمز المكتب';

  @override
  String get accountCaptionCrypto => 'عنوان المحفظة';

  @override
  String get accountCaptionInternal => 'معرّف الحساب';

  @override
  String get verificationManualProof => 'إثبات يدوي';

  @override
  String get verificationReferenceMatch => 'مطابقة مرجع الحوالة';

  @override
  String get verificationAutoStatement => 'كشف حساب آلي';

  @override
  String get verificationNone => 'بلا تحقق';

  @override
  String get proofFieldSenderName => 'اسم المُرسِل';

  @override
  String get proofFieldReceiptImage => 'صورة الإيصال';

  @override
  String get proofFieldTxHash => 'بصمة العملية';

  @override
  String get pmCodeRequired => 'رمز النظام مطلوب.';

  @override
  String get pmCodeMalformed => 'استخدم أحرفاً كبيرة وشرطة سفلية، 2-48 حرفاً، تبدأ بحرف.';

  @override
  String get pmCurrencyInvalid => 'استخدم رمز عملة من ثلاثة أحرف موجوداً في جدول العملات.';

  @override
  String get pmDisplayNameRequired => 'الاسم الظاهر مطلوب.';

  @override
  String get pmDestLabelRequired => 'الاسم مطلوب.';

  @override
  String get pmAccountIdentifierRequired => 'معرّف الحساب مطلوب.';

  @override
  String pmKeepUnderChars({required int max}) => 'اجعله أقل من $max حرفاً.';

  @override
  String pmAccountHolderTooLong({required int max}) => 'اجعل اسم صاحب الحساب أقل من $max حرفاً.';

  @override
  String pmNotesTooLong({required int max}) => 'اجعل الملاحظات أقل من $max حرفاً.';

  @override
  String pmInstructionsTooLong({required int max}) => 'اجعل التعليمات أقل من $max حرفاً.';

  @override
  String pmFeeBpsRange({required int max}) => 'نقاط الأساس يجب أن تكون بين 0 و$max (10000 = 100%).';

  @override
  String get pmPriorityNegative => 'الأولوية لا يمكن أن تكون سالبة.';

  @override
  String pmPatternTooLong({required int max}) => 'اجعل النمط أقل من $max حرفاً.';

  @override
  String pmPatternWarning({required String error}) => 'هذا النمط لا يُترجم برمجياً هنا ($error). الخادم سيعامله كـ«بلا نمط» بصمت.';

  @override
  String get pmMinNotPositive => 'الحد الأدنى يجب أن يكون أكبر من صفر.';

  @override
  String get pmAmountsCurrencyMismatch => 'المبالغ الثلاثة يجب أن تكون بالعملة نفسها.';

  @override
  String get pmMaxBelowMin => 'الحد الأعلى لا يمكن أن يكون أقل من الحد الأدنى.';

  @override
  String get pmFeeNegative => 'العمولة الثابتة لا يمكن أن تكون سالبة.';

  @override
  String get pmFeeNotBelowMin => 'العمولة الثابتة يجب أن تكون أقل من الحد الأدنى تماماً، وإلا فأصغر إيداع مسموح لن يشحن شيئاً.';

  @override
  String get pmIntegerRequired => 'أدخل رقماً صحيحاً.';

  @override
  String pmIntegerMin({required int min}) => 'يجب ألا يقل عن $min.';

  @override
  String pmIntegerMax({required int max}) => 'يجب ألا يزيد عن $max.';

  @override
  String get pmFieldLabelFeeBps => 'نقاط أساس العمولة';

  @override
  String fieldIssuePrefix({required String field, required String message}) => '$field: $message';

  @override
  String pmCreatedToast({required String name}) => 'تم إنشاء $name.';

  @override
  String pmSavedToast({required String name}) => 'تم حفظ $name.';

  @override
  String pmEnabledToast({required String name}) => '$name مفعّلة من جديد.';

  @override
  String pmDisabledToast({required String name}) => '$name معطّلة. لم يعد بإمكان اللاعبين اختيارها.';

  @override
  String pdAddedToast({required String label}) => 'تمت إضافة $label. تحقق من الحساب قبل أي إيداع حقيقي.';

  @override
  String pdSavedToast({required String label}) => 'تم حفظ $label.';

  @override
  String pdEnabledToast({required String label}) => '$label يُعرض على اللاعبين من جديد.';

  @override
  String pdDisabledToast({required String label}) => '$label لن يُعطى للاعبين الجدد.';

  @override
  String get pmCodeConflict => 'توجد طريقة دفع بهذا الرمز مسبقاً.';

  @override
  String get pdConflict => 'هذا الحساب مُعدّ مسبقاً لطريقة الدفع هذه.';

  @override
  String get pmRailNotSupported => 'لا يوجد مشغّل لهذا النوع، فلا يمكن تشغيل طريقة عليه.';

  @override
  String get pdNotFound => 'هذا الحساب لم يعد موجوداً. جارٍ التحديث.';

  @override
  String get pmNotFound => 'طريقة الدفع هذه لم تعد موجودة. جارٍ التحديث.';

  @override
  String pmFailureReference({required String code, required String correlationId}) => '$code — ref $correlationId';

  @override
  String get pmNoDriverChip => 'بلا مشغّل — غير قابلة للاستخدام';

  @override
  String get pmPlaceholderChip => 'حساب استلام وهمي';

  @override
  String get pmLimitsChipLabel => 'الحدود';

  @override
  String pdPriorityChip({required int priority}) => 'الأولوية $priority';

  @override
  String pdSoftCapChip({required String amount}) => 'سقف مرن $amount';

  @override
  String get pdHolderIgnoredChip => 'صاحب الحساب متجاهَل على هذا النوع';

  @override
  String pdHolderChip({required String holder}) => 'صاحب الحساب: $holder';

  @override
  String get pdNotesAppendedNote => 'تُضاف حرفياً إلى تعليمات اللاعب:';

  @override
  String get pmAuditBannerTitle => 'الأموال المدفوعة إلى هذه الحسابات تذهب إلى لا مكان';

  @override
  String pmAuditBannerMessage({required int rows, required int methods}) => '${_plural(rows, zero: 'لا حسابات استلام مفعّلة', one: 'حساب استلام مفعّل واحد', two: 'حسابا استلام مفعّلان', few: '$rows حسابات استلام مفعّلة', many: '$rows حساب استلام مفعّل')} على ${_plural(methods, zero: 'لا طرق دفع', one: 'طريقة دفع واحدة', two: 'طريقتَي دفع', few: '$methods طرق دفع', many: '$methods طريقة دفع')} ما زالت تبدو حسابات وهمية من البيانات الأولية. استبدلها قبل أي إيداع حقيقي — افتح الطريقة لمعرفة أيها.';

  @override
  String get pmDormantPlaceholderTitle => 'ما زالت هناك حسابات وهمية معطّلة';

  @override
  String pmDormantPlaceholderMessage({required int count}) => '${_plural(count, zero: 'لا حسابات استلام وهمية', one: 'حساب استلام وهمي واحد', two: 'حسابا استلام وهميان', few: '$count حسابات استلام وهمية', many: '$count حساب استلام وهمي')} ما زال على هذه الطريقة لكنه معطّل، فلا يُوجَّه إليه أي لاعب.';

  @override
  String get pmLivePlaceholderTitle => 'هذه الطريقة قد تعطي اللاعب حساباً وهمياً';

  @override
  String get pmLivePlaceholderMessage => 'اللاعب الذي يدفع إلى أحدها يرسل أمواله إلى لا مكان. أضف الحساب الحقيقي ثم عطّل الوهمي.';

  @override
  String get pdPlaceholderBadgeLive => 'حساب وهمي — مفعّل';

  @override
  String get pdPlaceholderBadge => 'حساب وهمي';

  @override
  String pdReasonSeedPrefix({required String prefix}) => 'معرّف الحساب ما زال الحساب الوهمي الأولي («$prefix-...»).';

  @override
  String get pdReasonMarker => 'معرّف الحساب ما زال يحتوي على علامة حساب وهمي.';

  @override
  String get pdReasonHolder => 'لم يُملأ اسم صاحب الحساب بعد.';

  @override
  String get pdReasonNotes => 'الملاحظات ما زالت تقول إن هذا السطر من البيانات الأولية.';

  @override
  String get pmPermissionDeniedTitle => 'لا يمكنك فتح هذه الشاشة';

  @override
  String pmPermissionDeniedMessage({required String roles, required String role}) => 'طلبات إعدادات الدفع تقبل: $roles. أنت مسجّل الدخول كـ$role.';

  @override
  String get pmNoRole => 'بلا دور';

  @override
  String get auScreenTitle => 'المشرفون';

  @override
  String get auAddButton => 'إضافة';

  @override
  String get auSearchHint => 'الاسم أو @المعرّف أو رقم التيليغرام';

  @override
  String get auSearchHelper => 'يصفّي الصفوف المحمّلة فقط — لا يوجد بحث نصي في الخادم.';

  @override
  String get auClearSearchTooltip => 'مسح البحث';

  @override
  String get auFilterEveryone => 'الجميع';

  @override
  String get auStatusActive => 'نشط';

  @override
  String get auStatusDeactivated => 'موقوف';

  @override
  String get auAllRoles => 'كل الأدوار';

  @override
  String get auRoleFieldLabel => 'الدور';

  @override
  String get auEmptyTitle => 'لا يوجد مشرف مطابق';

  @override
  String auEmptyMessage({required String filter}) => 'لا شيء في الدليل يطابق $filter. امسح الفلاتر لرؤية الجميع.';

  @override
  String get auLoadingDirectory => 'جارٍ تحميل دليل المشرفين...';

  @override
  String get auNoSearchMatchTitle => 'لا تطابق في الصفوف المحمّلة';

  @override
  String auNoSearchMatchMessage({required int count, required String query}) => 'لا يطابق «$query» ${_plural(count, zero: 'أي مشرف محمّل', one: 'المشرف الوحيد المحمّل', two: 'أياً من المشرفَين المحمّلَين', few: 'أياً من المشرفين الـ$count المحمّلين', many: 'أياً من المشرفين الـ$count المحمّلين')} حتى الآن.';

  @override
  String get auScrollToLoadMore => 'مرّر لتحميل المزيد، أو امسح البحث.';

  @override
  String get auClearSearchToSeeAll => 'امسح البحث لرؤية الجميع.';

  @override
  String auCountShownOfTotal({required int shown, required int total}) => '$shown من ${_plural(total, zero: 'لا مشرفين', one: 'مشرف واحد', two: 'مشرفَين', few: '$total مشرفين', many: '$total مشرفاً')}';

  @override
  String auCountTotal({required int total}) => _plural(total, zero: 'لا مشرفين', one: 'مشرف واحد', two: 'مشرفان', few: '$total مشرفين', many: '$total مشرفاً');

  @override
  String auActiveSuperAdmins({required int count}) => _plural(count, zero: 'لا مدراء عامون نشطون', one: 'مدير عام نشط واحد', two: 'مديران عامان نشطان', few: '$count مدراء عامون نشطون', many: '$count مديراً عاماً نشطاً');

  @override
  String get auLastWayBack => ' — آخر طريق للعودة إلى النظام.';

  @override
  String get auFilterDescribeAll => 'كل المشرفين';

  @override
  String get auFilterActiveOnly => 'النشطون فقط';

  @override
  String get auFilterDeactivatedOnly => 'الموقوفون فقط';

  @override
  String auFilterMatching({required String query}) => 'المطابق لـ«$query»';

  @override
  String get auDetailFallbackTitle => 'مشرف';

  @override
  String get auLoadingAdministrator => 'جارٍ تحميل بيانات المشرف...';

  @override
  String get auIdentitySection => 'الهوية';

  @override
  String get auUsernameLabel => 'المعرّف';

  @override
  String get auRowIdLabel => 'معرّف السجل';

  @override
  String get auAuthoritySection => 'الصلاحيات';

  @override
  String get auCreatedRowLabel => 'تاريخ الإضافة';

  @override
  String get auLastSignInLabel => 'آخر دخول';

  @override
  String get auNeverSignedInValue => 'لم يدخل أبداً';

  @override
  String auTimestampWithRelative({required String timestamp, required String relative}) => '$timestamp  ($relative)';

  @override
  String get alCeilingsSection => 'سقوف الموافقة';

  @override
  String get alCeilingsIntro => 'كم يستطيع هذا المشرف أن يوافق عليه بمفرده، وفوق أي مبلغ تصبح الموافقة الثانية مطلوبة. المشرف بلا سقف فعّال تُرفض كل موافقاته — النظام يرفض عند الشك.';

  @override
  String get alOpenCeilingsButton => 'فتح السقوف';

  @override
  String get auYouChip => 'أنت';

  @override
  String get auDeactivateButton => 'إيقاف';

  @override
  String get auReactivateButton => 'إعادة تفعيل';

  @override
  String auDeactivateConfirmTitle({required String name}) => 'إيقاف $name؟';

  @override
  String get auDeactivateConfirmMessage => 'يبقى ظاهراً على كل إيداع قرّره — هذا إيقاف وليس حذفاً. تُلغى صلاحيته في الدليل فوراً، لكن ذاكرة الهوية تحتفظ بالجواب السابق حتى 60 ثانية، فافترض أنه قادر على التصرف لدقيقة إضافية.';

  @override
  String auReactivateConfirmTitle({required String name}) => 'إعادة تفعيل $name؟';

  @override
  String auReactivateConfirmMessage({required String role}) => 'يستعيد كل صلاحيات $role فور تحديث ذاكرة الهوية — خلال 60 ثانية.';

  @override
  String auTileIdOnly({required String id}) => 'رقم $id';

  @override
  String auTileHandleAndId({required String handle, required String id}) => '$handle  —  رقم $id';

  @override
  String auTileLastSignIn({required String relative}) => 'آخر دخول $relative';

  @override
  String get auTileNeverSignedIn => 'لم يسجّل دخولاً أبداً';

  @override
  String get auFormEditTitle => 'تعديل مشرف';

  @override
  String get auFormCreateTitle => 'إضافة مشرف';

  @override
  String get auDisplayNameHelper => 'يظهر على كل إيداع يقرّره هذا الشخص.';

  @override
  String get auUsernameFieldLabel => 'معرّف التيليغرام (اختياري)';

  @override
  String get auUsernameHelper => 'اختياري، وفريد على مستوى الدليل.';

  @override
  String get auTelegramIdFieldLabel => 'رقم مستخدم التيليغرام';

  @override
  String get auTelegramIdHelperLocked => 'ثابت بعد الإنشاء — الرقم هو هوية الحساب نفسه.';

  @override
  String get auTelegramIdHelper => 'أرقام فقط، حتى 19 خانة. هذا رقم 64-بت وليس معرّف مستخدم.';

  @override
  String get auRoleSelfLocked => 'لا يمكنك تغيير دورك. هذه أسرع طريقة لإزالة الشخص الوحيد القادر على التراجع.';

  @override
  String auActiveOn({required String role}) => 'يستطيع تسجيل الدخول والتصرف بصلاحيات $role.';

  @override
  String get auActiveOff => 'لا يستطيع تسجيل الدخول. السجل يبقى، مرتبطاً بكل إيداع قرّره.';

  @override
  String get auCannotDeactivateSelf => 'لا يمكنك إيقاف نفسك.';

  @override
  String get auSaveChanges => 'حفظ التعديلات';

  @override
  String get auChangeNotAllowed => 'هذا التغيير غير مسموح.';

  @override
  String get auNothingChanged => 'لم يتغيّر شيء.';

  @override
  String get alSetCeilingButton => 'تعيين سقف';

  @override
  String get alEmptyTitle => 'لم يُعيَّن أي سقف';

  @override
  String get alEmptyMessage => 'المشرف بلا سقف فعّال تُرفض كل موافقاته — النظام يرفض عند الشك، فجدول سقوف فارغ لا يمنح أحداً شيئاً.';

  @override
  String get alLoadingHistory => 'جارٍ تحميل سجل السقوف...';

  @override
  String alRoleMayNeverApproveTitle({required String role}) => '$role لا يوافق أبداً';

  @override
  String get alRoleMayNeverApproveMessage => 'أي دور خارج SUPER_ADMIN وFINANCE_ADMIN وREVIEWER يُرفض قبل مراجعة أي سقف. السقف المعيَّن هنا لن يكون له أثر حتى يتغيّر الدور.';

  @override
  String get alVersioningNote => 'السقوف تُحفظ بنسخ ولا تُعدَّل. الميزانية اليومية تُصفَّر عند 00:00 UTC وتحسب القرار الأول والموافقة الثانية معاً.';

  @override
  String get alNoActiveChip => 'لا يوجد سقف فعّال';

  @override
  String get alInForceChip => 'ساري';

  @override
  String get alSupersededChip => 'مُستبدل';

  @override
  String alNoActiveMessage({required String currency}) => 'كل موافقة بعملة $currency مرفوضة لهذا المشرف حتى يُعيَّن سقف جديد.';

  @override
  String get alSingleApprovalLabel => 'الموافقة الواحدة';

  @override
  String get alDailyBudgetLabel => 'الميزانية اليومية';

  @override
  String get alSecondApprovalLabel => 'الموافقة الثانية';

  @override
  String get alInheritsGlobal => 'يرث حد الموافقة المزدوجة العام';

  @override
  String get alSecondApprovalAboveLabel => 'موافقة ثانية فوق';

  @override
  String get alEndedLabel => 'انتهى في';

  @override
  String get alReplaceButton => 'استبدال';

  @override
  String get alEndCeilingButton => 'إنهاء هذا السقف';

  @override
  String alEndConfirmTitle({required String currency}) => 'إنهاء سقف $currency؟';

  @override
  String get alEndConfirmMessage => 'هذا ينهي النسخة دون استبدالها. يبقى المشرف بلا سقف فعّال، وهو ما يقرأه النظام كرفض — يسحب الصلاحية ولا يمنحها. عيّن سقفاً جديداً إن كنت تقصد تعديل المبالغ.';

  @override
  String get alEndConfirmLabel => 'إنهاء السقف';

  @override
  String get alFormTitle => 'تعيين سقف موافقة';

  @override
  String alFormHeading({required String name}) => 'سقف جديد لـ$name';

  @override
  String get alFormIntro => 'تُغلق النسخة السارية في اللحظة نفسها التي تبدأ فيها هذه، فلا فجوة يبقى فيها المشرف بلا سقف ولا تداخل بين نسختين.';

  @override
  String get alCurrencyHelper => 'ثلاثة أحرف. السقوف لكل عملة على حدة.';

  @override
  String get alMaxSingleLabel => 'أعلى موافقة واحدة';

  @override
  String get alMaxSingleHelper => 'حد مطلق. فوقه لا يستطيع المشرف اعتماد المبلغ إطلاقاً، ولا تنفع موافقة ثانية.';

  @override
  String get alMaxDailyLabel => 'أعلى موافقة يومية';

  @override
  String get alMaxDailyHelper => 'ميزانية اليوم بتوقيت UTC، تحسب القرار الأول والموافقة الثانية معاً.';

  @override
  String get alSecondAboveLabel => 'موافقة ثانية فوق (اختياري)';

  @override
  String get alSecondAboveHelper => 'اتركه فارغاً ليرث حد الموافقة المزدوجة العام. الفارغ والصفر نيتان مختلفتان.';

  @override
  String alCurrencyThreeLetters({required String currency}) => 'ثلاثة أحرف بالضبط، مثال $currency.';

  @override
  String get alAmountNotNumber => 'أحد المبالغ ليس رقماً.';

  @override
  String get alSingleNotPositive => 'سقف الموافقة الواحدة يجب أن يكون أكبر من صفر.';

  @override
  String get alDailyNotPositive => 'السقف اليومي يجب أن يكون أكبر من صفر.';

  @override
  String get alSingleAboveDaily => 'سقف الموافقة الواحدة لا يمكن أن يتجاوز السقف اليومي. بالشكل الحالي، أول موافقة في اليوم سترفض دائماً.';

  @override
  String get alSecondNegative => 'حد الموافقة الثانية لا يمكن أن يكون سالباً.';

  @override
  String get profileTitle => 'الحساب والإعدادات';

  @override
  String get profileRefreshTooltip => 'تحديث بيانات التشخيص';

  @override
  String get profileNotSignedInTitle => 'غير مسجّل الدخول';

  @override
  String get profileNotSignedInMessage => 'تعرض هذه الشاشة المشرف المسجّل دخوله. سجّل الدخول برمز البوت لعرضها.';

  @override
  String profileSessionExpiresChip({required String relative}) => 'تنتهي $relative';

  @override
  String get profileSignedInAsSection => 'مسجّل الدخول باسم';

  @override
  String get profileAdminIdLabel => 'معرّف المشرف';

  @override
  String get profileIssuedLabel => 'تاريخ الإصدار';

  @override
  String get profileExpiresLabel => 'تنتهي في';

  @override
  String profileCapabilitiesSection({required String role}) => 'ماذا يستطيع $role';

  @override
  String get profileNotAvailableToRole => 'غير متاح لهذا الدور';

  @override
  String get profileServerEnforces => 'الخادم يطبّق هذا كله بشكل مستقل. أي زر تركته هذه اللوحة مفعّلاً بالخطأ سيحصل على 403.';

  @override
  String get profileBuildSection => 'هذه النسخة';

  @override
  String get profileBaseUrlLabel => 'عنوان الواجهة';

  @override
  String get profileEnvironmentLabel => 'البيئة';

  @override
  String get profileAuthAdapterLabel => 'موصّل الدخول';

  @override
  String get profileFakeChip => 'وهمي';

  @override
  String get profilePageSizeLabel => 'حجم الصفحة';

  @override
  String get profileCorrelationIdLabel => 'آخر معرّف تتبع';

  @override
  String get profileFakeAdapterWarning => 'موصّل دخول وهمي مفعّل: الجلسات تُنشأ محلياً ولا يُتحقق من أي رمز بوت لدى الخادم. لا تنشر نسخة بهذه الحالة أبداً.';

  @override
  String get profileCorrelationNote => 'الدعم يبحث عن الطلبات بمعرّف التتبع — كل رد يحمل واحداً، حتى الأخطاء.';

  @override
  String get profileSessionSection => 'الجلسة';

  @override
  String get profileSignOutNote => 'تسجيل الخروج يمسح الجلسة المحفوظة من مخزن مفاتيح الجهاز ويعود إلى شاشة رمز البوت.';

  @override
  String get profileSignOutButton => 'تسجيل الخروج';

  @override
  String get profileSignOutConfirmTitle => 'تسجيل الخروج؟';

  @override
  String get profileSignOutConfirmMessage => 'تُمسح الجلسة المحفوظة من هذا الجهاز.';

  @override
  String relativeMinutes({required int count}) => '$count دقيقة';

  @override
  String relativeHours({required int count}) => '$count ساعة';

  @override
  String relativeDays({required int count}) => '$count يوم';

  @override
  String relativeMonths({required int count}) => '$count شهر';

  @override
  String relativeYears({required int count}) => '$count سنة';

  @override
  String relativeInFuture({required String phrase}) => 'خلال $phrase';

  @override
  String get roleSummarySuperAdmin => 'كل شيء، بما فيه إضافة المشرفين وتعيين سقوف الموافقة. الدور الوحيد الذي يمنح غيره صلاحية تحريك الأموال.';

  @override
  String get roleSummaryFinanceAdmin => 'يراجع الإيداعات ويمنح الموافقة الثانية، يعيد محاولات الشحن، يعالج مشاكل التسوية، يدير حسابات الاستلام، ويقرأ دليل المشرفين.';

  @override
  String get roleSummaryReviewer => 'يراجع الإيداعات في الطابور. لا يمنح موافقة ثانية ولا يعدّل إعدادات الدفع.';

  @override
  String get roleSummarySupport => 'قراءة فقط على السطح التشغيلي: الطابور والتسوية وطرق الدفع. لا يقرر شيئاً.';

  @override
  String get roleSummaryViewer => 'قراءة فقط. أدنى صلاحية تقدمها اللوحة.';

  @override
  String get capViewDepositQueue => 'رؤية طابور الإيداعات';

  @override
  String get capReviewDeposit => 'الموافقة على إيداع أو رفضه';

  @override
  String get capSecondApprove => 'منح موافقة ثانية';

  @override
  String get capRetryCredit => 'إعادة محاولة شحن فاشل';

  @override
  String get capViewReconciliation => 'رؤية مشاكل التسوية';

  @override
  String get capResolveBreak => 'معالجة مشكلة تسوية';

  @override
  String get capViewPaymentMethods => 'رؤية طرق الدفع';

  @override
  String get capManagePaymentDestinations => 'إدارة حسابات الاستلام';

  @override
  String get capViewAdminUsers => 'رؤية دليل المشرفين';

  @override
  String get capManageAdminUsers => 'إدارة المشرفين والسقوف';

  @override
  String get capViewLedger => 'قراءة دفتر الحسابات';

  @override
  String get gateViewDirectoryReason => 'دليل المشرفين محصور بالمدير العام والمدير المالي.';

  @override
  String get gateManageReason => 'المدير العام وحده يستطيع إضافة المشرفين أو تعديلهم أو إيقافهم. إنشاء مشرف أو تغيير دور هو الإجراء الوحيد الذي يمنح غيرك صلاحية تحريك الأموال.';

  @override
  String get gateSelfModificationReason => 'لا يمكنك تغيير دورك أو إيقاف نفسك. اطلب من مدير عام آخر أن يفعلها.';

  @override
  String get gateLastSuperAdminReason => 'هذا آخر مدير عام نشط. رقِّ غيره أولاً، وإلا لن يستطيع أحد التراجع.';

  @override
  String get gateAlreadyDeactivated => 'هذا المشرف موقوف أصلاً.';

  @override
  String get gateAlreadyActive => 'هذا المشرف نشط أصلاً.';

  @override
  String get identityCacheNotice => 'تُلغى الصلاحية في الدليل فوراً، لكن ذاكرة الهوية تحتفظ بالجواب السابق حتى 60 ثانية. افترض أن هذا الشخص قادر على التصرف لدقيقة إضافية.';

  @override
  String get identityCacheNoticeCompact => 'يسري في الدليل الآن؛ ذاكرة الهوية تُحدَّث خلال 60 ثانية.';

  @override
  String get auPermissionDeniedTitle => 'غير متاح لدورك';

  @override
  String get auPermissionDeniedFallback => 'دورك لا يسمح بهذا.';

  @override
  String auPermissionDeniedSignedInAs({required String role}) => 'أنت مسجّل الدخول كـ$role.';

  @override
  String get errAdminNotFound => 'هذا المشرف لم يعد موجوداً. تغيّر الدليل منذ فتح هذه الشاشة.';

  @override
  String get errAdminAlreadyExists => 'يوجد مشرف بهذا الرقم أو المعرّف مسبقاً.';

  @override
  String get errApprovalLimitNotFound => 'نسخة سقف الموافقة هذه لم تعد موجودة.';

  @override
  String get errApprovalLimitInvalid => 'سقوف الموافقة غير متسقة، أو أن النسخة انتهت مسبقاً.';

  @override
  String get errOwnAccountDeactivated => 'حسابك كمشرف موقوف.';

  @override
  String get errRoleNotAllowed => 'دورك لا يسمح بهذا الإجراء.';

  @override
  String get errNetwork => 'تعذّر الوصول إلى الخادم. تحقق من الاتصال وأعد المحاولة.';

  @override
  String auCreatedToast({required String name}) => 'تمت إضافة $name.';

  @override
  String auUpdatedToast({required String name}) => 'تم تحديث $name.';

  @override
  String auDeactivatedToast({required String name}) => 'تم إيقاف $name.';

  @override
  String auReactivatedToast({required String name}) => 'تم تفعيل $name.';

  @override
  String get auNoticeNewAdminCanSignIn => 'يستطيع المشرف الجديد تسجيل الدخول فور تحديث ذاكرة الهوية — خلال 60 ثانية.';

  @override
  String get auNoticeAccessRestored => 'تعود الصلاحية بعد تحديث ذاكرة الهوية — خلال 60 ثانية.';

  @override
  String get alSavedToast => 'تم حفظ سقف الموافقة.';

  @override
  String get alEndedToast => 'تم إنهاء سقف الموافقة.';

  @override
  String get alRacedMessage => 'كان هذا السقف يُعدَّل في اللحظة نفسها. أُعيد تحميل السجل — راجعه وأعد تعيين السقف إذا لزم.';

  @override
  String get alSetNotice => 'أُغلقت النسخة السابقة في اللحظة نفسها التي بدأت فيها هذه، فلا فجوة بقي فيها المشرف بلا سقف.';

  @override
  String alEndNotice({required String currency}) => 'لم يعد لهذا المشرف سقف فعّال بعملة $currency، وهو ما يعامله نظام الموافقات كرفض. عيّن سقفاً جديداً لإعادة صلاحيته.';

  @override
  String get auTelegramIdRequired => 'أدخل رقم مستخدم التيليغرام.';

  @override
  String get auTelegramIdMalformed => 'أرقام فقط، حتى 19 خانة. بلا @ وبلا فواصل.';

  @override
  String get auDisplayNameRequired => 'أدخل اسماً ظاهراً.';

  @override
  String auMaxChars({required int max}) => '$max حرفاً كحد أقصى.';

  @override
  String get auUsernameAfterAt => 'اكتب المعرّف بعد @، أو اترك الحقل فارغاً.';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navActivity => 'إيداعاتي';

  @override
  String get navTopUp => 'شحن';

  @override
  String get navMethods => 'طرق الدفع';

  @override
  String get navProfile => 'حسابي';

  @override
  String get connectionChecking => 'جارٍ التحقق…';

  @override
  String get connectionOnline => 'متصل';

  @override
  String get connectionOffline => 'غير متصل';

  @override
  String connectionLatencyMs({required int ms}) => '$ms ms';

  @override
  String homeGreeting({required String name}) => 'أهلاً، $name';

  @override
  String get homeTagline => 'اشحن رصيدك بأمان وبسرعة';

  @override
  String get homeBalanceLabel => 'رصيدك في الكازينو';

  @override
  String homeBalanceUpdated({required String age}) => 'آخر تحديث $age';

  @override
  String homeBalancePendingChip({required int count}) => '$count قيد المراجعة';

  @override
  String get homeBalanceVisibilityTooltip => 'إظهار أو إخفاء الرصيد';

  @override
  String get homeTopUpCta => 'اشحن الآن';

  @override
  String get homeQuickTopUp => 'شحن';

  @override
  String get homeQuickDeposits => 'إيداعاتي';

  @override
  String get homeQuickMethods => 'طرق الدفع';

  @override
  String get homeQuickSupport => 'الدعم';

  @override
  String get homePromoSectionTitle => 'عروض وإعلانات';

  @override
  String get homePromoAction => 'اعرف أكثر';

  @override
  String get homePromoBonusTitle => 'مكافأة أول إيداع';

  @override
  String get homePromoBonusBody => 'اشحن لأول مرة واحصل على مكافأة تُضاف إلى رصيدك مباشرة.';

  @override
  String get homePromoInstantTitle => 'شحن خلال دقائق';

  @override
  String get homePromoInstantBody => 'أغلب الإيداعات تُراجع وتُضاف إلى رصيدك خلال دقائق من رفع الإيصال.';

  @override
  String get homePromoRailsTitle => 'قنوات دفع موثوقة';

  @override
  String get homePromoRailsBody => 'حوالات بنكية ومحافظ إلكترونية وكريبتو، كلها معتمدة من الكاشيرة.';

  @override
  String get homeRecentTitle => 'آخر العمليات';

  @override
  String get homeRecentEmptyMessage => 'اشحن رصيدك وستظهر عمليتك هنا مباشرة.';

  @override
  String get homeAccountNotLinkedTitle => 'حساب الكازينو غير مربوط بعد';

  @override
  String get homeAccountNotLinkedMessage => 'أرسل اسم المستخدم الخاص بك في Ichancy إلى الدعم داخل البوت ليتم ربطه، وبعدها يصل كل شحن إلى رصيدك مباشرة.';

  @override
  String get homeAccountLinkCta => 'اربط حسابي';

  @override
  String get homeAccountLinkedTitle => 'حسابك مربوط';

  @override
  String get homeAccountLinkedMessage => 'كل عملية شحن تصل إلى رصيدك في Ichancy مباشرة.';

  @override
  String get activityTitle => 'إيداعاتي';

  @override
  String activityShowingCount({required int shown, required int total}) => '$shown من $total';

  @override
  String get activityFilterInReview => 'قيد المراجعة';

  @override
  String get activityFilterCompleted => 'مكتملة';

  @override
  String get activityFilterRejected => 'مرفوضة';

  @override
  String get activitySummaryCreditedLabel => 'إجمالي ما تم شحنه';

  @override
  String activityInProgressCount({required int count}) => _plural(
        count,
        zero: 'لا شيء قيد المعالجة',
        one: 'طلب واحد قيد المعالجة',
        two: 'طلبان قيد المعالجة',
        few: '$count طلبات قيد المعالجة',
        many: '$count طلباً قيد المعالجة',
      );

  @override
  String get activitySummaryAllSettled => 'لا شيء معلّق';

  @override
  String activityViaMethod({required String method}) => 'عبر $method';

  @override
  String get activityEmptyTitle => 'لا توجد إيداعات بعد';

  @override
  String get activityEmptyMessage => 'ابدأ أول عملية شحن وستظهر هنا فور إرسالها.';

  @override
  String get activityStartTopUpAction => 'ابدأ الشحن';

  @override
  String get activityFilterEmptyTitle => 'لا شيء ضمن هذا التصنيف';

  @override
  String get activityFilterEmptyMessage => 'جرّب تصنيفاً آخر أو اعرض الكل.';

  @override
  String get activityShowAllAction => 'عرض الكل';

  @override
  String get activityErrorTitle => 'تعذّر تحميل إيداعاتك';

  @override
  String get activityErrorMessage => 'تحقّق من اتصالك ثم أعد المحاولة.';

  @override
  String get activityDetailTitle => 'تفاصيل الإيداع';

  @override
  String get activityDetailAmountLabel => 'المبلغ المُرسل';

  @override
  String get activityDetailCreditedLabel => 'المبلغ المُضاف إلى رصيدك';

  @override
  String get activityDetailMethodLabel => 'طريقة الدفع';

  @override
  String get activityDetailDestinationLabel => 'الحساب المستلم';

  @override
  String get activityDetailSenderLabel => 'اسم المُرسل';

  @override
  String get activityDetailSubmittedLabel => 'وقت الإرسال';

  @override
  String get activityNextStepHeading => 'ماذا بعد';

  @override
  String get activityTimelineHeading => 'ماذا حدث';

  @override
  String get activityRecordHeading => 'تفاصيل العملية';

  @override
  String get activityRequestNumberLabel => 'رقم الطلب';

  @override
  String get activityStaffNoteLabel => 'ملاحظة الفريق';

  @override
  String get activityStepNowBadge => 'الآن';

  @override
  String get activityCloseButton => 'إغلاق';

  @override
  String get activityStepSubmittedTitle => 'أرسلتَ الإيصال';

  @override
  String get activityStepSubmittedBody => 'وصل طلبك إلى فريق الكاشير.';

  @override
  String get activityStepReviewTitle => 'المراجعة';

  @override
  String get activityStepReviewBody => 'موظف يطابق إيصالك مع الحوالة الواردة. عادةً خلال دقائق.';

  @override
  String get activityStepApprovedTitle => 'الموافقة';

  @override
  String get activityStepApprovedBody => 'تمت الموافقة على المبلغ وهو في طريقه إلى حسابك.';

  @override
  String get activityStepCreditedTitle => 'إضافة الرصيد';

  @override
  String get activityStepCreditedBody => 'أصبح المبلغ متاحاً في رصيدك.';

  @override
  String get activityStepRejectedTitle => 'رُفض الطلب';

  @override
  String get activityStepRejectedBody => 'لم يطابق الإيصال الحوالة. اقرأ ملاحظة الفريق ثم أعد المحاولة بإيصال أوضح.';

  @override
  String get activityStepExpiredTitle => 'انتهت مهلة الطلب';

  @override
  String get activityStepExpiredBody => 'لم تصل حوالة مطابقة ضمن المهلة، فأُغلق الطلب. يمكنك بدء طلب جديد.';

  @override
  String get topupTitle => 'شحن الرصيد';

  @override
  String get topupCloseTooltip => 'إغلاق';

  @override
  String topupStepOfTotal({required int step, required int total}) => 'الخطوة $step من $total';

  @override
  String get topupStepAmount => 'المبلغ';

  @override
  String get topupStepMethod => 'طريقة الدفع';

  @override
  String get topupStepPay => 'التحويل';

  @override
  String get topupStepReceipt => 'الإيصال';

  @override
  String get topupStepDone => 'تم';

  @override
  String get topupNext => 'التالي';

  @override
  String get topupBack => 'رجوع';

  @override
  String get topupAmountHeadline => 'كم تريد أن تشحن؟';

  @override
  String get topupAmountSubhead => 'اختر مبلغاً جاهزاً أو اكتب المبلغ بنفسك.';

  @override
  String get topupAmountFieldLabel => 'المبلغ بالليرة السورية';

  @override
  String get topupAmountFieldHint => '50000';

  @override
  String topupAmountHelper({required String min, required String max}) => 'من $min إلى $max';

  @override
  String get topupQuickPicksLabel => 'مبالغ سريعة';

  @override
  String get topupAmountErrorNotPositive => 'يجب أن يكون المبلغ أكبر من صفر.';

  @override
  String topupAmountErrorBelowMin({required String min}) => 'أقل من الحد الأدنى $min.';

  @override
  String topupAmountErrorAboveMax({required String max}) => 'أعلى من الحد الأقصى $max.';

  @override
  String get topupMethodsLoadFailed => 'تعذّر تحميل طرق الدفع.';

  @override
  String get topupMethodHeadline => 'كيف ستدفع؟';

  @override
  String get topupMethodSubhead => 'اختر القناة، ثم الحساب الذي ستحوّل إليه.';

  @override
  String topupMethodLimits({required String min, required String max}) => 'من $min إلى $max';

  @override
  String get topupMethodNotForAmount => 'لا تناسب هذا المبلغ';

  @override
  String get topupNoMethodsTitle => 'لا توجد طريقة دفع متاحة';

  @override
  String get topupNoMethodsMessage => 'أعد المحاولة بعد قليل أو تواصل مع الدعم.';

  @override
  String get topupDestinationSectionTitle => 'الحساب المستلم';

  @override
  String get topupNoDestinationsTitle => 'لا يوجد حساب مفعّل لهذه الطريقة';

  @override
  String get topupNoDestinationsMessage => 'اختر طريقة دفع أخرى.';

  @override
  String get topupSelectedBadge => 'مختار';

  @override
  String topupReviewEta({required int minutes}) => 'تُراجع عادةً خلال $minutes دقيقة.';

  @override
  String get topupPayHeadline => 'حوّل المبلغ الآن';

  @override
  String get topupPaySubhead => 'أرسل المبلغ بالضبط إلى الحساب التالي، واحتفظ بالإيصال.';

  @override
  String get topupAmountToSendLabel => 'المبلغ المطلوب تحويله';

  @override
  String get topupFeeLabel => 'العمولة';

  @override
  String get topupCreditedLabel => 'سيُضاف إلى رصيدك';

  @override
  String get topupReferenceHint => 'اكتب الرقم المرجعي في خانة الملاحظة عند التحويل، وإلا تأخّرت المطابقة.';

  @override
  String get topupDeadlineLabel => 'تنتهي المهلة في';

  @override
  String get topupDeadlineExpired => 'انتهت المهلة';

  @override
  String topupCountdown({required int minutes, required int seconds}) =>
      '${_pad2(minutes)}:${_pad2(seconds)}';

  @override
  String get topupPaidCta => 'حوّلت المبلغ';

  @override
  String get topupReceiptHeadline => 'ارفع صورة الإيصال';

  @override
  String get topupReceiptSubhead => 'صورة واضحة تُظهر المبلغ والتاريخ ورقم العملية.';

  @override
  String get topupReceiptEmptyTitle => 'لا توجد صورة بعد';

  @override
  String get topupReceiptEmptyMessage => 'اضغط هنا لاختيار صورة من معرضك.';

  @override
  String get topupReceiptPickCta => 'اختيار صورة';

  @override
  String get topupReceiptReplaceCta => 'تغيير الصورة';

  @override
  String get topupReceiptRemoveCta => 'إزالة';

  @override
  String get topupReceiptPickerUnavailable => 'اختيار الصور غير مفعّل في هذه النسخة بعد.';

  @override
  String get topupSenderNameHelper => 'الاسم الظاهر على الحساب الذي حوّلت منه.';

  @override
  String get topupSummaryTitle => 'ملخّص الطلب';

  @override
  String get topupSubmitCta => 'إرسال الطلب';

  @override
  String get topupSubmitFailedTitle => 'تعذّر إرسال الطلب';

  @override
  String get topupSuccessHeadline => 'تم استلام طلبك';

  @override
  String get topupSuccessMessage => 'سيراجع الكاشير الإيصال، ويُضاف الرصيد فور الموافقة.';

  @override
  String get topupShortIdLabel => 'رقم الطلب';

  @override
  String get topupWhatHappensNext => 'ماذا بعد؟';

  @override
  String get topupNextStepReview => 'يراجع الكاشير الإيصال ويطابق المبلغ.';

  @override
  String get topupNextStepCredit => 'يُضاف المبلغ إلى رصيدك في الكازينو.';

  @override
  String get topupNextStepNotify => 'تجد النتيجة في «إيداعاتي».';

  @override
  String get topupDoneCta => 'تمام';

  @override
  String get topupAnotherCta => 'شحن آخر';

  @override
  String get topupDemoNotice => 'بيانات تجريبية — سيُربط الخادم لاحقاً.';

  @override
  String get methodsIntro => 'اختر الوسيلة التي تناسبك وابدأ الشحن بخطوات واضحة.';

  @override
  String methodsAvailableCount({required int available, required int total}) => '$available من $total متاحة الآن';

  @override
  String get methodsFilterAvailableOnly => 'المتاحة الآن';

  @override
  String get methodsBadgeAvailable => 'متاحة';

  @override
  String get methodsBadgeBusy => 'ضغط عالٍ';

  @override
  String get methodsBadgeUnavailable => 'متوقفة مؤقتاً';

  @override
  String get methodsBadgeMostUsed => 'الأكثر استخداماً';

  @override
  String get methodsBusyNote => 'الضغط مرتفع على هذه الوسيلة، وقد يستغرق التأكيد وقتاً أطول من المعتاد.';

  @override
  String get methodsPausedNote => 'هذه الوسيلة متوقفة مؤقتاً. اختر وسيلة أخرى أو عد لاحقاً.';

  @override
  String get methodsSettlementLabel => 'مدة التنفيذ';

  @override
  String methodsSettlementWithin({required String age}) => 'خلال $age';

  @override
  String get methodsSettlementInstant => 'فوري';

  @override
  String get methodsFeeNone => 'بدون عمولة';

  @override
  String get methodsReferenceOptionalShort => 'مرجع اختياري';

  @override
  String get methodsCheckedLabel => 'آخر تحقّق';

  @override
  String get methodsSectionFastest => 'الأسرع لك الآن';

  @override
  String get methodsSectionOther => 'وسائل أخرى';

  @override
  String get methodsSectionPaused => 'متوقفة الآن';

  @override
  String get methodsHowToTitle => 'كيف تدفع';

  @override
  String get methodsProofTitle => 'الإثبات المطلوب';

  @override
  String get methodsDestinationTitle => 'حساب الاستلام';

  @override
  String get methodsAccountCopied => 'تم نسخ رقم الحساب';

  @override
  String get methodsReferenceHintRequired => 'أدخل رقم مرجع الحوالة عند رفع الإيصال.';

  @override
  String get methodsReferenceHintOptional => 'رقم المرجع اختياري هنا، لكنه يسرّع المراجعة.';

  @override
  String get methodsTopUpNowCta => 'شحن الآن';

  @override
  String get methodsEmptyMessage => 'لا توجد طرق دفع متاحة الآن. حاول التحديث بعد قليل.';

  @override
  String get profileSectionAccount => 'بيانات الحساب';

  @override
  String get profileUsernameLabel => 'اسم المستخدم';

  @override
  String get profileGamingAccountLabel => 'حساب اللعب';

  @override
  String get profileAccountStatusActive => 'حساب نشِط';

  @override
  String get profileAccountStatusLimited => 'حساب مقيّد';

  @override
  String get profileAccountStatusSuspended => 'حساب موقوف';

  @override
  String get profileGamingLinked => 'مرتبط';

  @override
  String get profileGamingPending => 'قيد الربط';

  @override
  String get profileGamingMissing => 'غير مرتبط';

  @override
  String get profileStatTotalDeposited => 'إجمالي الإيداعات';

  @override
  String get profileStatDepositCount => 'عدد الإيداعات';

  @override
  String get profileStatMemberSince => 'عضو منذ';

  @override
  String get profileReferralCodeLabel => 'رمز الإحالة';

  @override
  String get profileInviteLinkLabel => 'رابط الدعوة';

  @override
  String get profileReferralHint => 'شارك رابطك: تحصل على مكافأة عند أول شحن لصديقك.';

  @override
  String get profileRevealTooltip => 'إظهار أو إخفاء المعرّفات';

  @override
  String get profileSectionConnection => 'الاتصال بالخادم';

  @override
  String get profileHealthEndpointLabel => 'نقطة الفحص';

  @override
  String get profileLastCheckedLabel => 'آخر فحص';

  @override
  String get profileRecheckButton => 'إعادة الفحص';

  @override
  String get profileTermsLabel => 'الشروط والأحكام';

  @override
  String get profileTermsBody => 'الشحن يتم عبر كاشير معتمد. أرفق إيصالاً واضحاً يظهر فيه المبلغ ورقم العملية ووقتها. تُراجَع كل عملية يدوياً وقد تُرفض إن لم يطابق الإيصال المبلغ المُعلن. المبالغ بالليرة السورية (NSP) ولا تُقرَّب أبداً.';

  @override
  String get profileSupportLabel => 'الدعم والمساعدة';

  @override
  String get profileSupportBody => 'راسل الكاشير على تيليغرام. أرفق رقم الإيداع ووقت التحويل ليصل الرد أسرع.';

  @override
  String get profileSupportChannelLabel => 'قناة الدعم';

  @override
  String get profileAppVersionLabel => 'إصدار التطبيق';

  @override
  String get profileCloseButton => 'إغلاق';

  @override
  String get profileEmptyTitle => 'لا يوجد ملف حساب بعد';

  @override
  String get profileEmptyMessage => 'ابدأ أول عملية شحن وسيُنشأ ملفك تلقائياً.';

  @override
  String get profileLoadFailedTitle => 'تعذّر تحميل حسابك';

  /// Zero-pads one countdown component to two Western digits.
  static String _pad2(int value) => value.toString().padLeft(2, '0');

}

/// English - reachable from the Settings language toggle.
class EnStrings extends AppStrings {
  const EnStrings();

  @override
  String get localeTag => 'en';

  @override
  TextDirection get textDirection => TextDirection.ltr;

  @override
  String get appTitle => 'Manager console';

  @override
  String get navQueue => 'Queue';

  @override
  String get navMoney => 'Money';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get errorRequestFailed => 'The request could not be completed.';

  @override
  String errorServerReturnedStatus({required int status, required String code}) => 'The server returned $status ($code).';

  @override
  String get errorSessionNoLongerValid => 'Your admin session is no longer valid. Sign in again.';

  @override
  String get errorAdminDeactivated => 'This admin account has been deactivated.';

  @override
  String get errorAdminNotFound => 'This admin account no longer exists.';

  @override
  String get errorWrongPrincipal => 'This token is not an admin token.';

  @override
  String get errorInsufficientRole => 'Your role does not allow this action.';

  @override
  String get errorRecordNotFound => 'That record could not be found.';

  @override
  String errorValidationWithFields({required String message, required String fields}) => '$message\n- $fields';

  @override
  String get errorRequestStillProcessing => 'The same request is still being processed. Try again in a moment.';

  @override
  String get errorRequestAlreadySubmitted => 'This request was already submitted with different details.';

  @override
  String get errorAlreadyHandledByOther => 'This item was already handled by someone else. Refresh to see the current state.';

  @override
  String get errorTooManyRequests => 'Too many requests. Wait a moment and try again.';

  @override
  String errorTooManyRequestsRetryIn({required int seconds}) => 'Too many requests. Try again in ${seconds}s.';

  @override
  String get errorRequestCancelled => 'Request cancelled.';

  @override
  String get errorCannotReachServer => 'Cannot reach the server. Check the connection and try again.';

  @override
  String get errorServerTookTooLong => 'The server took too long to answer. Try again.';

  @override
  String get errorServerInternal => 'The server hit an internal error. Try again shortly.';

  @override
  String errorServerInternalWithRef({required String correlationId}) => 'The server hit an internal error. Quote reference $correlationId to support.';

  @override
  String get errorUnreadableFromServer => 'The server sent something this app could not read.';

  @override
  String errorSupportLine({required String message, required String code, required String correlationId}) => '$message ($code - ref $correlationId)';

  @override
  String errorSupportLineShort({required String message, required String code}) => '$message ($code)';

  @override
  String get errorEnvelopeMissing => 'The server did not return the standard response envelope.';

  @override
  String errorCouldNotReadResponse({required String method, required String path, required String field, required String reason}) => 'Could not read the response of $method $path ($field: $reason).';

  @override
  String errorAmountNotExact({required String method, required String path, required String reason}) => 'An amount on $method $path could not be read exactly ($reason). Nothing was shown rather than showing a rounded figure.';

  @override
  String errorRequestTimedOutPath({required String path}) => 'The request to $path timed out.';

  @override
  String get errorCertificateRejected => 'The server certificate was rejected.';

  @override
  String errorResponseUndecodable({required String method, required String path}) => 'The response of $method $path could not be decoded.';

  @override
  String errorCouldNotReachHost({required String baseUrl}) => 'Could not reach $baseUrl.';

  @override
  String get errorTitleSessionExpired => 'Session expired';

  @override
  String get errorTitleNotAllowed => 'Not allowed';

  @override
  String get errorTitleCheckDetails => 'Check the details';

  @override
  String get errorTitleNotFound => 'Not found';

  @override
  String get errorTitleAlreadyHandled => 'Already handled';

  @override
  String get errorTitleCannotDoThat => 'Cannot do that';

  @override
  String get errorTitleTooManyRequests => 'Too many requests';

  @override
  String get errorTitleNoConnection => 'No connection';

  @override
  String get errorTitleTimedOut => 'Timed out';

  @override
  String get errorTitleServerError => 'Server error';

  @override
  String get errorTitleUnexpectedResponse => 'Unexpected response';

  @override
  String get errorTitleSignInAgain => 'Sign in again';

  @override
  String get errorTitleUnreadableResponse => 'Unreadable response';

  @override
  String errorUnreadableResponseBody({required String path, required String reason}) => 'The server sent a payload this app does not understand ($path: $reason).';

  @override
  String get errorTitleUnreadableAmount => 'Unreadable amount';

  @override
  String errorUnreadableAmountBody({required String reason}) => 'An amount in the response could not be read exactly ($reason). Nothing is shown rather than a rounded figure. Report it to the backend team.';

  @override
  String get errorTitleSomethingWentWrong => 'Something went wrong';

  @override
  String get tryAgain => 'Try again';

  @override
  String get retry => 'Retry';

  @override
  String get refresh => 'Refresh';

  @override
  String get emptyDefaultTitle => 'Nothing here yet';

  @override
  String get loading => 'Loading...';

  @override
  String get loadingQueue => 'Loading queue...';

  @override
  String get queueEmptyTitle => 'Queue is clear';

  @override
  String get queueEmptyMessage => 'No deposits are waiting for review.';

  @override
  String get referenceCopied => 'Reference copied';

  @override
  String correlationChip({required String code, required String correlationId}) => '$code - $correlationId';

  @override
  String get cancel => 'Cancel';

  @override
  String get note => 'Note';

  @override
  String noteRequiredSuffix({required String label}) => '$label (required)';

  @override
  String confirmApproveAmountTitle({required String amount}) => 'Approve $amount?';

  @override
  String confirmPlayerWillBeCredited({required String playerId}) => 'Player $playerId will be credited immediately.';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get apply => 'Apply';

  @override
  String get resetButton => 'Reset';

  @override
  String get filterLabel => 'Filter';

  @override
  String filterWithCount({required int count}) => 'Filter ($count)';

  @override
  String get statusLabel => 'Status';

  @override
  String get createdLabel => 'Created';

  @override
  String get editButton => 'Edit';

  @override
  String get saveButton => 'Save';

  @override
  String get savingButton => 'Saving...';

  @override
  String get loadMore => 'Load more';

  @override
  String get copyTooltip => 'Copy';

  @override
  String get copied => 'Copied.';

  @override
  String copiedToClipboard({required String label}) => '$label copied';

  @override
  String get emptyValueDash => '—';

  @override
  String get timesAreLocalNote => "Times are shown in this device's local time. The bot prints UTC.";

  @override
  String get unknownPlaceholder => '?';

  @override
  String get listSeparator => ', ';

  @override
  String moneyAmountWithCurrency({required String amount, required String currency}) => '$amount $currency';

  @override
  String moneyDual({required String newAmount, required String oldAmount}) => '$newAmount new | $oldAmount old';

  @override
  String get moneyErrorEmpty => 'Enter an amount.';

  @override
  String get moneyErrorMalformed => 'Enter a plain number, e.g. 1500.00';

  @override
  String get moneyErrorPlainAmountExample => 'Enter a plain amount such as 1500.00.';

  @override
  String get moneyErrorDigitsOnly => 'Use digits and at most one dot, for example 15000.00. No spaces, no thousands separators.';

  @override
  String moneyErrorTooManyDecimals({required int scale}) => 'At most $scale decimal places.';

  @override
  String get atMostTwoDecimals => 'At most 2 decimals.';

  @override
  String get moneyErrorScaleTwo => 'Use at most 2 decimals - the backend stores this at scale 2.';

  @override
  String get moneyErrorScaleTwoDetailed => 'At most two decimal places. The server stores this currency at scale 2 and rejects anything finer.';

  @override
  String get moneyErrorCurrencyMismatch => 'These amounts are in different currencies.';

  @override
  String get moneyErrorOtherCurrency => 'That amount is in a different currency.';

  @override
  String get moneyErrorInvalid => 'That is not a valid amount.';

  @override
  String get roleSuperAdmin => 'Super admin';

  @override
  String get roleFinanceAdmin => 'Finance admin';

  @override
  String get roleReviewer => 'Reviewer';

  @override
  String get roleSupport => 'Support';

  @override
  String get roleViewer => 'Viewer';

  @override
  String roleWithWireName({required String label, required String wireName}) => '$label ($wireName)';

  @override
  String get adminDisplayNameFallback => 'Admin';

  @override
  String get errorSessionNoExpiry => 'expected an ISO-8601 timestamp; a session with no stated expiry cannot be trusted';

  @override
  String get signedOut => 'You have signed out.';

  @override
  String signInAgainWithReason({required String reason}) => 'Sign in again: $reason.';

  @override
  String get reasonSessionExpired => 'the session expired';

  @override
  String get reasonStoredSessionExpired => 'the stored session expired';

  @override
  String get reasonTokenAlreadyExpired => 'the issued token was already expired';

  @override
  String get reasonNoRefresh => 'admin sessions cannot be refreshed';

  @override
  String get enterBotCode => 'Enter the code the bot sent you.';

  @override
  String get codeMustNotBeEmpty => 'code must not be empty';

  @override
  String get botCodeInvalid => 'That code is not valid.';

  @override
  String devDisplayName({required String role}) => 'Dev $role';

  @override
  String get loginTitle => 'Manager console';

  @override
  String get loginHeadlineRestoring => 'Restoring your session...';

  @override
  String get loginHeadlineSignIn => 'Sign in with the code the bot sent you.';

  @override
  String get loginHeadlineChecking => 'Checking that code with the server...';

  @override
  String loginHeadlineSignedInAs({required String name}) => 'Signed in as $name.';

  @override
  String get loginHeadlineSessionEnded => 'Your session ended. Sign in again to carry on.';

  @override
  String get botCodeFieldLabel => 'Bot code';

  @override
  String get botCodeFieldHelper => 'The one-time code the bot sent you in a direct message.';

  @override
  String get signIn => 'Sign in';

  @override
  String get signingIn => 'Signing in...';

  @override
  String get sessionEndedTitle => 'Session ended';

  @override
  String sessionEndedBody({required String name, required String role, required String reason}) => '$name, your $role session ended ($reason). Admin sessions cannot be refreshed, so ask the bot for a new code.';

  @override
  String envFooter({required String env, required String baseUrl}) => '$env - $baseUrl';

  @override
  String fakeAuthBanner({required String env, required String baseUrl}) => 'FAKE AUTH IS BOUND. No server is contacted and no real session is created. $env - $baseUrl';

  @override
  String get devCodeShortLabel => ':SHORT (2 min)';

  @override
  String get devCodeDenyLabel => 'DEV-DENY (rejects)';

  @override
  String copiedCode({required String code}) => 'Copied $code';

  @override
  String get depositQueueTitle => 'Deposit queue';

  @override
  String queueRefreshFailed({required String message}) => 'Refresh failed: $message';

  @override
  String get queueNoAccessTitle => 'No access to the deposit queue';

  @override
  String get queueNoAccessMessage => 'Your role cannot read deposits. Ask a super admin to change it.';

  @override
  String get sortTooltip => 'Sort';

  @override
  String get moreTooltip => 'More';

  @override
  String get clearFiltersAction => 'Clear filters';

  @override
  String get runSweepAction => 'Run maintenance sweep';

  @override
  String get queueNoMatchesTitle => 'No matches';

  @override
  String get queueNoMatchesMessage => 'No deposit matches these filters. Remember that the short id and the external reference are exact matches.';

  @override
  String get clearButton => 'Clear';

  @override
  String filterSummaryStatuses({required int count}) => count == 1 ? '1 status' : '$count statuses';

  @override
  String filterSummaryShortId({required String shortId}) => 'ref $shortId';

  @override
  String filterSummaryExternalReference({required String reference}) => 'external $reference';

  @override
  String filterSummaryAmountRange({required String min, required String max}) => '$min - $max';

  @override
  String get filterSummaryAny => 'any';

  @override
  String get filterSummaryDateRange => 'date range';

  @override
  String get filterSummaryOnePlayer => 'one player';

  @override
  String get filterSummaryOneMethod => 'one method';

  @override
  String get filterSummaryUnclaimedOnly => 'unclaimed only';

  @override
  String get filterSummaryFallback => 'Filtered';

  @override
  String queuePagingBlockedBySort({required String sort}) => 'More deposits match, but "$sort" cannot be paged by the backend. Sort by newest or oldest to page through them, or narrow the filters.';

  @override
  String queueLoadedCount({required int count}) => count == 1 ? '1 deposit loaded.' : '$count deposits loaded.';

  @override
  String get sweepConfirmTitle => 'Run the maintenance sweep?';

  @override
  String get sweepConfirmMessage => 'Expires stale drafts, releases claims older than 10 minutes and re-queues credits stuck for 20 minutes. Each pass handles at most 100 rows per phase.';

  @override
  String get sweepConfirmButton => 'Run sweep';

  @override
  String sweepFailed({required String message}) => 'Sweep failed: $message';

  @override
  String get sweepNothingToDo => 'Nothing needed sweeping.';

  @override
  String sweepSummary({required int expired, required int released, required int reaped}) => '$expired expired, $released released, $reaped re-queued.';

  @override
  String get detailNoAccessTitle => 'No access to deposits';

  @override
  String get detailNoAccessMessage => 'Your role cannot read deposits.';

  @override
  String detailLoadingLabel({required String shortId}) => 'Loading $shortId...';

  @override
  String get claimTakeOverTitle => 'Take over this review?';

  @override
  String get claimTakeOverMessage => 'Another reviewer claimed it but let it go stale. Claiming now moves it to you.';

  @override
  String get claimTakeOverConfirm => 'Take over';

  @override
  String releaseConfirmTitle({required String shortId}) => 'Release $shortId?';

  @override
  String get releaseConfirmMessage => 'It goes back to the queue for anyone to pick up.';

  @override
  String get releaseConfirmButton => 'Release';

  @override
  String get retryCreditConfirmTitle => 'Re-run the credit?';

  @override
  String retryCreditConfirmMessage({required String amount}) => 'The credit worker runs again for $amount. Nothing is re-posted to the ledger. Do this only after the reason for the failure is fixed.';

  @override
  String get retryCreditConfirmButton => 'Re-run credit';

  @override
  String get retryCreditReasonLabel => 'Reason';

  @override
  String get retryCreditReasonHint => 'e.g. agent float topped up';

  @override
  String get sectionAmounts => 'Amounts';

  @override
  String get amountPlayerClaimed => 'Player claimed';

  @override
  String get amountVerifiedByAdmin => 'Verified by an admin';

  @override
  String get amountNotVerifiedYet => 'Not verified yet';

  @override
  String get amountFee => 'Fee';

  @override
  String get amountCreditedToPlayer => 'Credited to the player';

  @override
  String get amountNotCreditedYet => 'Not credited yet';

  @override
  String get playerLabel => 'Player';

  @override
  String get playerTelegram => 'Telegram';

  @override
  String get telegramIdLabel => 'Telegram id';

  @override
  String get playerIdLabel => 'Player id';

  @override
  String get sectionDestination => 'Where they were told to pay';

  @override
  String get sectionSubmitted => 'What they submitted';

  @override
  String get externalReferenceLabel => 'External reference';

  @override
  String get externalReferenceMissingHint => 'This method requires a reference and none was given.';

  @override
  String get senderAccountLabel => 'Sender account';

  @override
  String get riskSignals => 'Risk signals';

  @override
  String get riskFlagsDisclaimer => 'Flags are evidence for you, not a verdict. An empty list is not proof of a clean deposit.';

  @override
  String sectionProof({required int count}) => 'Proof ($count)';

  @override
  String get sectionHistory => 'History';

  @override
  String get sectionTechnical => 'Technical';

  @override
  String get technicalDepositId => 'Deposit id';

  @override
  String get technicalPaymentMethodId => 'Payment method id';

  @override
  String get technicalCreditAttempts => 'Credit attempts';

  @override
  String get technicalCreditKeyEpoch => 'Credit key epoch';

  @override
  String get technicalCreditVerifiedBy => 'Credit verified by';

  @override
  String get technicalDecidedByAdmin => 'Decided by admin';

  @override
  String get technicalSecondApprover => 'Second approver';

  @override
  String headlineCreatedAgo({required String shortId, required String age}) => '$shortId - created $age ago';

  @override
  String get pendingSecondApprovalNote => 'Parked for dual control. The first approval is recorded and nothing has been posted to the ledger.';

  @override
  String claimHeldByYou({required int minutes}) => 'You hold this review for another ${minutes}m.';

  @override
  String get claimExpiredMine => 'Your claim has expired. Anyone can take it now.';

  @override
  String get claimStaleOther => 'Another reviewer claimed this but let it go stale, so it can be taken over.';

  @override
  String claimHeldByOther({required int minutes}) => 'Another reviewer holds this for another ${minutes}m. Approving or rejecting anyway still works - the claim is advisory.';

  @override
  String correlationIdLine({required String correlationId}) => 'Reference $correlationId';

  @override
  String get destinationMissing => 'No destination was recorded for this deposit.';

  @override
  String get paymentMethodLabel => 'Payment method';

  @override
  String get destinationMethodCode => 'Method code';

  @override
  String get destinationLabel => 'Destination';

  @override
  String get accountLabel => 'Account';

  @override
  String get accountHolderLabel => 'Account holder';

  @override
  String get referenceRequiredLabel => 'Reference required';

  @override
  String get instructionsLabel => 'Instructions';

  @override
  String get filterSheetTitle => 'Filter the queue';

  @override
  String get filterStatusHint => 'Nothing selected means the three reviewable statuses.';

  @override
  String get presetReviewable => 'Reviewable';

  @override
  String get presetNeedsAttention => 'Needs attention';

  @override
  String get presetAnyStatus => 'Any status';

  @override
  String get filterSectionSort => 'Sort';

  @override
  String get sortNotPageableHint => 'Amount sorts cannot be paged by the backend, so only the first page is shown.';

  @override
  String get filterSectionSearch => 'Search';

  @override
  String get filterSearchHint => 'Both are EXACT matches - there is no substring search on this endpoint.';

  @override
  String get filterShortIdLabel => 'Deposit reference (short id)';

  @override
  String get filterShortIdHint => 'K7Q2ZP9V3M';

  @override
  String get filterCaseSensitiveHint => 'Case sensitive';

  @override
  String get filterSectionAmount => 'Amount claimed';

  @override
  String get filterAmountMin => 'Minimum';

  @override
  String get filterAmountMax => 'Maximum';

  @override
  String get amountFieldHintSample => '1500.00';

  @override
  String get filterCreatedHint => 'From is inclusive, to is exclusive.';

  @override
  String get dateFrom => 'From';

  @override
  String get dateTo => 'To';

  @override
  String get filterSectionIdentifiers => 'Identifiers';

  @override
  String get filterIdentifiersHint => 'Version-4 UUIDs only on these two filters.';

  @override
  String get filterUnclaimedOnly => 'Unclaimed only';

  @override
  String get filterUnclaimedOnlySubtitle => 'Hides deposits another reviewer has claimed.';

  @override
  String get sortNewest => 'Newest first';

  @override
  String get sortOldest => 'Oldest first';

  @override
  String get sortAmountDesc => 'Largest amount';

  @override
  String get sortAmountAsc => 'Smallest amount';

  @override
  String get validationPlayerIdUuid => 'Player id must be a version-4 UUID.';

  @override
  String get validationPaymentMethodIdUuid => 'Payment method id must be a version-4 UUID.';

  @override
  String get validationReferenceTooLong => 'Reference cannot be longer than 120 characters.';

  @override
  String get validationShortIdTooLong => 'Short id cannot be longer than 32 characters.';

  @override
  String get validationMinAboveMax => 'The minimum amount is above the maximum.';

  @override
  String get validationFromBeforeTo => 'The "from" date must be before the "to" date.';

  @override
  String get validationMinAmountInvalid => 'The minimum amount is not a valid value.';

  @override
  String get validationMaxAmountInvalid => 'The maximum amount is not a valid value.';

  @override
  String get statusDraft => 'Draft';

  @override
  String get statusAwaitingProof => 'Awaiting proof';

  @override
  String get statusSubmitted => 'Submitted';

  @override
  String get statusUnderReview => 'Under review';

  @override
  String get statusPendingSecondApproval => 'Second approval';

  @override
  String get statusApproved => 'Approved';

  @override
  String get statusCrediting => 'Crediting';

  @override
  String get statusCredited => 'Credited';

  @override
  String get statusCreditFailed => 'Credit failed';

  @override
  String get statusNeedsReconciliation => 'Needs reconciliation';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get statusExpired => 'Expired';

  @override
  String get statusReversed => 'Reversed';

  @override
  String get rejectionDuplicateProof => 'Duplicate proof';

  @override
  String get rejectionProofUnreadable => 'Proof unreadable';

  @override
  String get rejectionProofMissing => 'Proof missing';

  @override
  String get rejectionAmountMismatch => 'Amount mismatch';

  @override
  String get rejectionReferenceNotFound => 'Reference not found';

  @override
  String get rejectionWrongDestination => 'Wrong destination';

  @override
  String get rejectionSenderMismatch => 'Sender mismatch';

  @override
  String get rejectionSuspectedFraud => 'Suspected fraud';

  @override
  String get rejectionLimitExceeded => 'Limit exceeded';

  @override
  String get rejectionPlayerIneligible => 'Player ineligible';

  @override
  String get rejectionOther => 'Other';

  @override
  String get proofSourcePlayerUpload => 'Player upload';

  @override
  String get proofSourceAdminUpload => 'Admin upload';

  @override
  String get proofSourceTelegramPhoto => 'Telegram photo';

  @override
  String get proofSourceTelegramDocument => 'Telegram document';

  @override
  String get proofSourceSystemImport => 'System import';

  @override
  String get creditVerifiedApiOk => 'Ichancy API confirmed';

  @override
  String get creditVerifiedBalanceDelta => 'Balance delta observed';

  @override
  String get creditVerifiedManual => 'Confirmed manually';

  @override
  String get riskDuplicateProofExact => 'Duplicate proof exact';

  @override
  String get riskDuplicateProofSimilar => 'Duplicate proof similar';

  @override
  String get riskReferenceReused => 'Reference reused';

  @override
  String get riskDuplicateProofSamePlayer => 'Duplicate proof same player';

  @override
  String get riskRapidResubmission => 'Rapid resubmission';

  @override
  String get riskLargeAmount => 'Large amount';

  @override
  String get riskNewPlayer => 'New player';

  @override
  String get actionClaim => 'Claim';

  @override
  String get actionClaimDescription => 'Take the review claim';

  @override
  String get actionRelease => 'Release';

  @override
  String get actionReleaseDescription => 'Return to the queue';

  @override
  String get actionApprove => 'Approve';

  @override
  String get actionApproveDescription => 'Approve and credit';

  @override
  String get actionReject => 'Reject';

  @override
  String get actionRejectDescription => 'Reject this deposit';

  @override
  String get actionRetryCredit => 'Retry credit';

  @override
  String get actionRetryCreditDescription => 'Re-run the failed credit';

  @override
  String get blockOnlyFinanceAdminRetry => 'Only a finance admin can re-run a credit.';

  @override
  String get blockRoleCannotDecide => 'Your role cannot decide deposits.';

  @override
  String blockClaimedByOther({required int minutes}) => 'Another reviewer holds this claim for another ${minutes}m.';

  @override
  String get blockClaimedByOtherUnknown => 'Another reviewer holds this claim.';

  @override
  String get blockNotClaimHolder => 'Only the reviewer holding the claim can release it.';

  @override
  String actionBlockedLine({required String action, required String reason}) => '$action: $reason';

  @override
  String get idleNotSubmittedYet => 'The player has not submitted this deposit yet. Only the expiry sweep can move it.';

  @override
  String get idleApproved => 'Approved. The credit worker will pick it up shortly.';

  @override
  String get idleCrediting => 'The credit is in flight. The sweep re-queues it if it stalls for 20 minutes.';

  @override
  String get idleCredited => 'Credited. This deposit is finished.';

  @override
  String get idleRejected => 'Rejected. This deposit is finished.';

  @override
  String get idleExpired => 'Expired. This deposit is finished.';

  @override
  String get idleReversed => 'Reversed. This deposit is finished.';

  @override
  String get idleNoActionForRole => 'No action is available to your role.';

  @override
  String get approveSheetTitle => 'Approve deposit';

  @override
  String get approveSheetSecondTitle => 'Give the second approval';

  @override
  String get amountYouVerified => 'You verified';

  @override
  String get amountPlayerReceives => 'Player receives';

  @override
  String get approveOverrideToggle => 'Correct the amount';

  @override
  String get approveOverrideOn => 'The corrected amount is recorded as the verified amount.';

  @override
  String get approveOverrideOff => 'Off means you verified exactly what the player claimed.';

  @override
  String get verifiedAmountLabel => 'Verified amount';

  @override
  String get noteOptionalLabel => 'Note (optional)';

  @override
  String get approveNoteHint => 'What did you check?';

  @override
  String get approveAdvisorySecondApproval => 'This deposit is parked for dual control. If you are the admin who gave the first approval, the server will refuse this one.';

  @override
  String get approveAdvisoryThreshold => 'If this amount is above your dual-control threshold, the server records a FIRST approval instead and no money moves until a second admin approves.';

  @override
  String get approveErrorInvalidAmount => 'Enter a valid amount with at most 2 decimals.';

  @override
  String get approveErrorNotPositive => 'The verified amount must be greater than zero.';

  @override
  String approveErrorBelowFee({required String fee}) => 'The verified amount does not cover the $fee fee on this payment method.';

  @override
  String approveButton({required String amount}) => 'Approve $amount';

  @override
  String get approveSecondButton => 'Give second approval';

  @override
  String get rejectSheetTitle => 'Reject deposit';

  @override
  String rejectSheetSubtitle({required String shortId, required String amount}) => '$shortId - $amount';

  @override
  String get rejectSheetNote => 'Rejection is terminal and posts nothing to the ledger.';

  @override
  String get rejectReasonLabel => 'Reason';

  @override
  String get rejectNoteHint => 'Anything the next reviewer should know';

  @override
  String get rejectChooseReason => 'Choose a reason';

  @override
  String rejectButton({required String reason}) => 'Reject - $reason';

  @override
  String get unknownMethod => 'Unknown method';

  @override
  String get claimedChip => 'Claimed';

  @override
  String claimedChipMinutes({required int minutes}) => 'Claimed ${minutes}m';

  @override
  String riskMoreFlags({required String worst, required int count}) => '$worst +$count more';

  @override
  String get timelineCreated => 'Created';

  @override
  String get timelineSubmitted => 'Submitted for review';

  @override
  String get timelineNoProofAttached => 'No proof attached';

  @override
  String timelineProofsAttached({required int count}) => count == 1 ? '1 proof attached' : '$count proofs attached';

  @override
  String get timelineClaimed => 'Claimed for review';

  @override
  String timelineAdmin({required String id}) => 'Admin $id';

  @override
  String timelineRejectedWithReason({required String reason}) => 'Rejected - $reason';

  @override
  String get timelineFirstApproval => 'First approval recorded';

  @override
  String get timelineFirstApprovalSubtitle => 'Nothing has been posted to the ledger yet.';

  @override
  String get timelineApproved => 'Approved';

  @override
  String timelineSecondApprover({required String id}) => 'Second approver $id';

  @override
  String get timelineCredited => 'Credited to the player';

  @override
  String get timelineExpires => 'Expires';

  @override
  String timelineFuture({required String timestamp, required String timeLeft}) => '$timestamp (in $timeLeft)';

  @override
  String get moments => 'moments';

  @override
  String get timelineFooter => "Reconstructed from this deposit's timestamps. The API publishes no transition log on the admin surface.";

  @override
  String get ageNow => 'now';

  @override
  String ageSeconds({required int count}) => '${count}s';

  @override
  String ageMinutes({required int count}) => '${count}m';

  @override
  String ageHours({required int count}) => '${count}h';

  @override
  String ageHoursMinutes({required int hours, required int minutes}) => '${hours}h ${minutes}m';

  @override
  String ageDays({required int count}) => '${count}d';

  @override
  String ageDaysHours({required int days, required int hours}) => '${days}d ${hours}h';

  @override
  String get ageInFuture => 'in the future';

  @override
  String ageAgo({required String age}) => '$age ago';

  @override
  String timestampWithAge({required String timestamp, required String age}) => '$timestamp ($age ago)';

  @override
  String get proofNone => 'No proof was uploaded for this deposit.';

  @override
  String proofIndexOfTotal({required int index, required int total}) => 'Proof $index of $total';

  @override
  String proofThumbnailCaption({required String source, required String size}) => '$source - $size';

  @override
  String get proofDecodeFailed => 'The image could not be decoded.';

  @override
  String get proofViewerTitle => 'Proof';

  @override
  String get detailsTooltip => 'Details';

  @override
  String get proofDetailsTitle => 'Proof details';

  @override
  String get proofDetailSource => 'Source';

  @override
  String get proofDetailStoredType => 'Stored type';

  @override
  String get proofDetailServedAs => 'Served as';

  @override
  String get proofDetailSize => 'Size';

  @override
  String get proofDetailDimensions => 'Dimensions';

  @override
  String get proofDetailUploaded => 'Uploaded';

  @override
  String get proofDetailSha256 => 'SHA-256';

  @override
  String get proofDetailFetchedVia => 'Fetched via';

  @override
  String get proofViaPresignedUrl => 'Presigned storage URL';

  @override
  String get proofViaApiStream => 'Authenticated API stream';

  @override
  String sizeBytes({required int count}) => '$count B';

  @override
  String sizeKilobytes({required int count}) => '$count KB';

  @override
  String sizeMegabytes({required String value}) => '$value MB';

  @override
  String dimensionLabel({required int width, required int height}) => '$width x $height';

  @override
  String get proofGone => 'This proof is no longer available.';

  @override
  String get proofDownloadFailed => 'The proof image could not be downloaded.';

  @override
  String get proofDownloadCancelled => 'The proof download was cancelled.';

  @override
  String get proofEnvelopeInsteadOfBytes => 'The server returned JSON instead of image bytes. The proof streaming route is wrapping the file in the response envelope.';

  @override
  String get proofEnvelopeDetail => 'Report this to the backend team; it is not a client fault.';

  @override
  String get proofNotAnImage => 'The downloaded proof is not a readable image.';

  @override
  String proofNotAnImageDetail({required String mimeType, required int bytes}) => 'stored type $mimeType, $bytes bytes';

  @override
  String get reportApproved => 'Approved. The player will be credited shortly.';

  @override
  String reportLedgerTransaction({required String id}) => 'Ledger transaction $id';

  @override
  String get reportAwaitingSecondApproval => 'Recorded as the first approval. A second, different administrator must approve before any money moves.';

  @override
  String get reportRejected => 'Rejected. Nothing was posted to the ledger.';

  @override
  String get reportClaimed => 'Claimed for the next 10 minutes.';

  @override
  String get reportReleased => 'Released back to the queue.';

  @override
  String get reportAlreadyHandled => 'Someone else already handled this deposit.';

  @override
  String reportAlreadyHandledWithStatus({required String status}) => 'Someone else already handled this deposit - it is now $status.';

  @override
  String reportUnknownOutcome({required String kind}) => 'The server reported an outcome this app does not know ("$kind"). The deposit has been refreshed.';

  @override
  String reportActionFailed({required String action}) => 'The $action could not be completed.';

  @override
  String get reportClaimedByOther => 'Another reviewer is already looking at this deposit.';

  @override
  String get reportDepositGone => 'This deposit no longer exists.';

  @override
  String get reportClaimBackendDefect => 'Claiming hit a known backend defect: the deposit state machine has no UNDER_REVIEW -> UNDER_REVIEW step, so this call cannot succeed for any deposit. The request was well formed; report it to the backend team. Approve and reject still work without a claim.';

  @override
  String get reportRetryCreditBackendDefect => 'Retrying the credit hit a known backend defect (the deposit state machine rejects its own retry transition). The request was well formed; report it to the backend team.';

  @override
  String get reportAboveApprovalLimit => 'This amount is above your approval authority, so nothing was approved. A more senior admin must decide it.';

  @override
  String get reportSecondApproverMustDiffer => 'You already approved this deposit. A second, different administrator has to give the other approval.';

  @override
  String get reportVerifiedAmountRequired => 'The verified amount must be greater than zero and must cover the fee.';

  @override
  String get reportInvalidState => 'This deposit is no longer in a state that allows that action.';

  @override
  String detailNotFound({required String shortId}) => 'No deposit matches the reference $shortId.';

  @override
  String get detailStillLoading => 'The deposit is still loading. Try again in a moment.';

  @override
  String get detailActionInFlight => 'Another action is still running.';

  @override
  String detailIllegalAction({required String status, required String action}) => 'This deposit is $status, so "$action" is no longer possible.';

  @override
  String get retryCreditRequeued => 'Credit re-queued. The worker will run it again.';

  @override
  String retryCreditEpochDetail({required int epoch}) => 'Credit key epoch $epoch';

  @override
  String retryCreditNotRequeued({required int epoch}) => 'Nothing was re-queued - the deposit had already moved on. Epoch is still $epoch.';

  @override
  String get detailStaleWarning => 'Showing the last known state - refreshing the deposit failed. Pull to refresh.';

  @override
  String signedInAsRole({required String role}) => 'Signed in as $role.';

  @override
  String get reconciliationTitle => 'Reconciliation';

  @override
  String get refreshBreaksTooltip => 'Refresh breaks';

  @override
  String get tabBreaks => 'Breaks';

  @override
  String get tabAgentFloat => 'Agent float';

  @override
  String get tabRailAgeing => 'Rail ageing';

  @override
  String get tabInvariants => 'Invariants';

  @override
  String attentionBadge({required int count}) => '$count need attention';

  @override
  String get breakScreenTitle => 'Break';

  @override
  String get deniedActionOpenBreak => 'open a reconciliation break';

  @override
  String get loadingBreak => 'Loading the break...';

  @override
  String correctFloatConfirmTitle({required String amount}) => 'Post $amount to the ledger?';

  @override
  String get correctFloatConfirmTitleFallback => 'the difference';

  @override
  String get correctFloatConfirmMessage => 'This writes an AGENT_FLOAT_SYNC transaction that moves our books to match the Ichancy figure, then closes the break as Resolved. It is not the same as closing the break by hand, and it cannot be retried safely - if it times out, re-open this screen instead of pressing again.';

  @override
  String get correctFloatConfirmLabel => 'Post the correction';

  @override
  String get correctionNoteLabel => 'Correction note';

  @override
  String get correctionNoteHint => 'Why the ledger should follow the Ichancy figure';

  @override
  String get cardTheDifference => 'The difference';

  @override
  String get cardDetectorEvidence => 'Detector evidence';

  @override
  String get cardDetectorEvidenceSubtitle => 'Free-form: whatever opened this break left it here.';

  @override
  String get cardLinkedRecords => 'Linked records';

  @override
  String get breakReopenedNotice => 'This break was closed once and then re-opened by an assignment. The resolution fields below belong to that earlier closure, not to the current state.';

  @override
  String get breakNoDetectorNotice => 'No detector in the backend writes this category today, so this row is unusual. Read it carefully.';

  @override
  String get chipAssigned => 'assigned';

  @override
  String get breakIdLabel => 'Break id';

  @override
  String get assignedToAdminLabel => 'Assigned to admin';

  @override
  String get dedupeKeyLabel => 'Dedupe key';

  @override
  String get dedupeKeyHelp => 'Breaks are upserted on this key, so a recurrence within the same window refreshes this row instead of creating a new one.';

  @override
  String get resolutionCardClosedTitle => 'How it was closed';

  @override
  String get resolutionCardEarlierTitle => 'Earlier closure';

  @override
  String get closedAtLabel => 'Closed at';

  @override
  String get closedByAdminLabel => 'Closed by admin';

  @override
  String get ledgerCorrectionLabel => 'Ledger correction';

  @override
  String get ledgerCorrectionNone => 'none - closing posts nothing';

  @override
  String get actionsCardTitle => 'Actions';

  @override
  String actionsNeedRole({required String roles}) => 'Assigning, closing and correcting a break need $roles.';

  @override
  String actionsBreakClosedNotice({required String status}) => 'This break is closed as $status. Assigning it again would re-open it while keeping the old resolution note, so that action is deliberately not offered.';

  @override
  String get takeOverBreak => 'Take over this break';

  @override
  String get assignToMe => 'Assign to me';

  @override
  String get closeTheBreak => 'Close the break';

  @override
  String get ledgerCorrectionExplain => 'Closing records a decision. Correcting POSTS TO THE LEDGER for the difference above and then closes the break as Resolved. Two different acts, two different buttons.';

  @override
  String get correctTheLedger => 'Correct the ledger';

  @override
  String get emptyBreaksTitle => 'Nothing to reconcile';

  @override
  String get emptyBreaksMessage => 'No break matches this filter. Widen it, or run a float sync or an invariant sweep to look for new ones.';

  @override
  String get loadingBreaks => 'Loading breaks...';

  @override
  String get resetFilterAction => 'Reset filter';

  @override
  String get outstandingDriftNotice => 'Money is unaccounted for right now: at least one open break still carries a non-zero difference.';

  @override
  String get metricLoaded => 'Loaded';

  @override
  String get captionMoreAvailable => 'more available';

  @override
  String get captionAllOfThem => 'all of them';

  @override
  String get metricNeedAttention => 'Need attention';

  @override
  String get captionSevereOrDrifting => 'severe or drifting';

  @override
  String get captionNothingUrgent => 'nothing urgent';

  @override
  String get breaksSortHint => 'Newest first, by the moment the problem first appeared.';

  @override
  String get loadingMore => 'Loading more...';

  @override
  String get endOfList => 'End of the list.';

  @override
  String get agentFloatSubtitle => 'Compares the ICHANCY_AGENT_FLOAT ledger account with the Ichancy agent wallet. Tolerance is zero: any difference opens a break.';

  @override
  String floatSyncNeedsRole({required String roles}) => 'Running a comparison writes to the break table, so it needs $roles.';

  @override
  String get comparingFloat => 'Comparing...';

  @override
  String get compareFloatNow => 'Compare float now';

  @override
  String get readingBothSides => 'Reading both sides...';

  @override
  String get noFloatReadingTitle => 'No reading yet';

  @override
  String get noFloatReadingMessage => 'The float comparison is never run automatically - it can open a break. Run it when you need the live picture.';

  @override
  String get walletUnavailableNotice => 'The Ichancy wallet could not be read. This is a normal 200 answer, not a failure - but only our side is shown, and no break was opened.';

  @override
  String belowWatermarkNotice({required String amount, required String basis}) => 'Below the low watermark: $amount ($basis).';

  @override
  String get watermarkBasisLedger => 'measured against our ledger, because the wallet read failed';

  @override
  String get watermarkBasisWallet => 'measured against the Ichancy wallet';

  @override
  String floatReadingAt({required String time}) => 'Reading at $time';

  @override
  String floatReadingSubtitle({required String currency, required String age}) => '$currency - $age';

  @override
  String get metricOurLedger => 'Our ledger';

  @override
  String get metricIchancyWallet => 'Ichancy wallet';

  @override
  String get moneyUnavailable => 'unavailable';

  @override
  String get captionAvailableBalance => 'available balance';

  @override
  String get driftMetricLabel => 'Drift (Ichancy - ledger)';

  @override
  String get moneyNotComputable => 'not computable';

  @override
  String get driftCaptionWalletUnknown => 'The Ichancy side is unknown, so no difference exists to report.';

  @override
  String get driftCaptionExact => 'Exactly in agreement.';

  @override
  String get driftCaptionIchancyMore => 'Ichancy holds more than our books say.';

  @override
  String get driftCaptionLedgerMore => 'Our books say more than Ichancy holds.';

  @override
  String get breakOpenedTitle => 'A break was opened or refreshed';

  @override
  String get breakOpenedSubtitle => 'Breaks are upserted per currency per UTC day, so the same drift today reuses this id.';

  @override
  String get openTheBreak => 'Open the break';

  @override
  String get noBreakWalletMissing => 'No break was opened: with one side missing there is nothing to compare.';

  @override
  String get noBreakInAgreement => 'No break was opened: the two sides agree exactly.';

  @override
  String get emptyRailAgeingTitle => 'No clearing balances';

  @override
  String get emptyRailAgeingMessage => 'Every rail clearing account is empty: nothing has been credited that the rail has not confirmed.';

  @override
  String get loadingRailAgeing => 'Aggregating ledger entries...';

  @override
  String staleAccountsNotice({required int count, required String codes}) => count == 1 ? '1 account holds money that has been unconfirmed for over thirty days: $codes.' : '$count accounts hold money that has been unconfirmed for over thirty days: $codes.';

  @override
  String railAgeingGeneratedAt({required String timestamp}) => 'Generated $timestamp. Read live on every request - there is no cache.';

  @override
  String railRowSubtitle({required String currency, required int count}) => count == 1 ? '$currency - 1 unsettled entry' : '$currency - $count unsettled entries';

  @override
  String get chipStale => 'stale';

  @override
  String get metricUnconfirmedBalance => 'Unconfirmed balance';

  @override
  String get metricOldestEntry => 'Oldest entry';

  @override
  String get captionNoDatedEntries => 'no dated entries';

  @override
  String get byAge => 'By age';

  @override
  String get ledgerAccountLabel => 'Ledger account';

  @override
  String get ledgerInvariantsTitle => 'Ledger invariants';

  @override
  String get ledgerInvariantsSubtitle => 'I1 every transaction balances and has two sides. I2 the ledger sums to zero per currency. I3 each account cache matches its entries.';

  @override
  String invariantsNeedRole({required String roles}) => 'Running the sweep writes breaks and repairs caches, so it needs $roles.';

  @override
  String get sweeping => 'Sweeping...';

  @override
  String get runTheSweep => 'Run the sweep';

  @override
  String get sweepWarning => 'Can take a while on a large ledger. Every violation is also written as a LEDGER_IMBALANCE break.';

  @override
  String get loadingSweep => 'Aggregating the whole ledger...';

  @override
  String get notSweptYetTitle => 'Not swept yet';

  @override
  String get notSweptYetMessage => 'The sweep is never run automatically. Run it when you need to know the books still add up.';

  @override
  String get ledgerHealthyTitle => 'The ledger adds up';

  @override
  String get ledgerHealthyBody => 'No violation of I1, I2 or I3. Every transaction balances, every currency sums to zero, and every account cache matches its entries.';

  @override
  String violationsFound({required int count}) => count == 1 ? '1 violation found. The books do not add up.' : '$count violations found. The books do not add up.';

  @override
  String get reportTruncatedNotice => 'The report hit its hundred-row cap: there may be MORE violations than are listed here.';

  @override
  String sweptAt({required String timestamp}) => 'Swept $timestamp';

  @override
  String get entryCountsNoticeShort => 'These three figures are ENTRY COUNTS, not money.';

  @override
  String subjectIdLabel({required String subjectKind}) => '$subjectKind id';

  @override
  String get expectedLabel => 'Expected';

  @override
  String get actualLabel => 'Actual';

  @override
  String get differenceLabel => 'Difference';

  @override
  String get noExpectedActualPair => 'This break carries no expected/actual pair.';

  @override
  String get metricLedgerExpected => 'Ledger (expected)';

  @override
  String get captionOurBooks => 'our books';

  @override
  String get metricObservedActual => 'Observed (actual)';

  @override
  String get captionTheOtherSide => 'the other side';

  @override
  String get metricDifferenceActualExpected => 'Difference (actual - expected)';

  @override
  String get deltaCaptionOneSideMissing => 'One side was missing when this break was detected.';

  @override
  String get deltaCaptionNoDifference => 'No outstanding difference.';

  @override
  String get deltaCaptionOtherSideMore => 'The other side holds more than our books.';

  @override
  String get deltaCaptionOurBooksMore => 'Our books hold more than the other side.';

  @override
  String get entryCountsDriftNotice => 'These figures are ENTRY COUNTS, not money. A single-sided transaction has fewer entries than the ledger requires.';

  @override
  String get metricEntriesRequired => 'Entries required';

  @override
  String get metricEntriesFound => 'Entries found';

  @override
  String entryCountsRawExplain({required String currency}) => 'Shown as raw counts on purpose: the API formats them at money scale, so an entry count of 2 would otherwise read as 0.02 $currency.';

  @override
  String get noDetectorEvidence => 'No detector evidence was attached to this break.';

  @override
  String get ageingAtDetection => 'Ageing at detection';

  @override
  String get noEntriesInAnyBucket => 'No entries in any bucket.';

  @override
  String entriesCount({required int count}) => count == 1 ? '1 entry' : '$count entries';

  @override
  String get linkDepositRequest => 'Deposit request';

  @override
  String get linkIchancyCall => 'Ichancy call';

  @override
  String get linkCorrectionTransaction => 'Correction transaction';

  @override
  String get noLinkedRecords => 'This break is not linked to a deposit, player or account.';

  @override
  String get breakTouchesDepositNotice => 'A deposit is caught in this break - it needs reconciliation before that money is settled.';

  @override
  String detectedAt({required String timestamp}) => 'Detected $timestamp';

  @override
  String get breakFilterSheetTitle => 'Filter breaks';

  @override
  String get filterDefaultHint => 'With no status selected the server shows open and investigating breaks only.';

  @override
  String get filterCategoryHeading => 'Category';

  @override
  String get filterCategoryHint => 'Only agent float mismatch, unidentified receipt and ledger imbalance are produced by a detector today.';

  @override
  String get filterMinSeverityHeading => 'Minimum severity';

  @override
  String get filterAll => 'All';

  @override
  String get filterDone => 'Done';

  @override
  String tileEntriesOfEntries({required int actual, required int expected}) => '$actual of $expected entries';

  @override
  String get moneyNoDifferenceRecorded => 'no difference recorded';

  @override
  String get tileReopenedNote => 'Re-opened after a previous closure - the old resolution note is still attached.';

  @override
  String get closeBreakSheetTitle => 'Close this break';

  @override
  String get closeBreakSheetHint => 'Closing does NOT move any money. It records a decision, and the note is the evidence that the decision was taken deliberately.';

  @override
  String get resolutionNoteLabel => 'Resolution note (required)';

  @override
  String get resolutionNoteHint => 'What did you check, and what is the conclusion?';

  @override
  String closeAsStatus({required String status}) => 'Close as $status';

  @override
  String get deniedTitle => 'Not your desk';

  @override
  String deniedSignedOut({required String action}) => 'Sign in to $action.';

  @override
  String deniedRoleCannot({required String role, required String action}) => 'A $role cannot $action.';

  @override
  String deniedAllowedRoles({required String roles}) => 'Allowed: $roles';

  @override
  String get deniedActionViewReconciliation => 'view reconciliation';

  @override
  String get breakStatusOpen => 'Open';

  @override
  String get breakStatusInvestigating => 'Investigating';

  @override
  String get breakStatusResolved => 'Resolved';

  @override
  String get breakStatusWrittenOff => 'Written off';

  @override
  String get breakStatusFalsePositive => 'False positive';

  @override
  String get breakStatusUnknown => 'Unknown';

  @override
  String get closingMeaningResolved => 'The difference was real and has been dealt with outside this break.';

  @override
  String get closingMeaningWrittenOff => 'The difference is real, will not be recovered, and is accepted as a loss.';

  @override
  String get closingMeaningFalsePositive => 'There was never a real difference; the detector was wrong.';

  @override
  String get closingMeaningNotClosing => 'Not a closing status.';

  @override
  String get breakCategoryAgentFloatMismatch => 'Agent float mismatch';

  @override
  String get breakCategoryPlayerBalanceMismatch => 'Player balance mismatch';

  @override
  String get breakCategoryMissingCredit => 'Missing credit';

  @override
  String get breakCategoryDuplicateCredit => 'Duplicate credit';

  @override
  String get breakCategoryUnidentifiedReceipt => 'Unidentified receipt';

  @override
  String get breakCategoryLedgerImbalance => 'Ledger imbalance';

  @override
  String get breakCategoryOrphanIchancyCall => 'Orphan Ichancy call';

  @override
  String get breakCategoryStuckDeposit => 'Stuck deposit';

  @override
  String get breakCategoryUnknown => 'Unknown category';

  @override
  String get severity1 => 'S1 informational';

  @override
  String get severity2 => 'S2 low';

  @override
  String get severity3 => 'S3 drift';

  @override
  String get severity4 => 'S4 serious';

  @override
  String get severity5 => 'S5 money missing';

  @override
  String severityShort({required int n}) => 'S$n';

  @override
  String detailValueItems({required int count}) => count == 1 ? '1 item' : '$count items';

  @override
  String detailValueFields({required int count}) => count == 1 ? '1 field' : '$count fields';

  @override
  String get filterDescribeDefault => 'Unresolved breaks';

  @override
  String filterDescribeSeverity({required String severity}) => 'severity $severity+';

  @override
  String get evidenceIchancyAvailable => 'Ichancy available';

  @override
  String get evidenceIchancyBalance => 'Ichancy balance';

  @override
  String get evidenceLedger => 'Ledger';

  @override
  String get evidenceDelta => 'Delta';

  @override
  String get evidenceAccountCode => 'Account code';

  @override
  String get evidenceOldestUnsettledAt => 'Oldest unsettled at';

  @override
  String get evidenceSubject => 'Subject';

  @override
  String get evidenceTruncated => 'Truncated';

  @override
  String get evidenceInvariant => 'Invariant';

  @override
  String get invariantI1TransactionZeroSum => 'I1 transaction zero sum';

  @override
  String get invariantI1TransactionZeroSumExplain => 'A ledger transaction does not sum to zero.';

  @override
  String get invariantI1SingleSided => 'I1 single sided';

  @override
  String get invariantI1SingleSidedExplain => 'A ledger transaction has fewer than two entries.';

  @override
  String get invariantI2GlobalZeroSum => 'I2 global zero sum';

  @override
  String get invariantI2GlobalZeroSumExplain => 'The whole ledger does not sum to zero for this currency.';

  @override
  String get invariantI3CachedBalanceDrift => 'I3 cached balance drift';

  @override
  String get invariantI3CachedBalanceDriftExplain => 'An account cache disagrees with the sum of its entries.';

  @override
  String get invariantUnknown => 'Unknown invariant';

  @override
  String get invariantUnknownExplain => 'An invariant this build does not know.';

  @override
  String get subjectKindTransaction => 'Transaction';

  @override
  String get subjectKindCurrency => 'Currency';

  @override
  String get subjectKindAccount => 'Account';

  @override
  String get subjectKindSubject => 'Subject';

  @override
  String get bucket0to1d => '0-1d';

  @override
  String get bucket1to3d => '1-3d';

  @override
  String get bucket3to7d => '3-7d';

  @override
  String get bucket7to30d => '7-30d';

  @override
  String get bucket30dPlus => '30d+';

  @override
  String get actionAssignedToYou => 'Assigned to you.';

  @override
  String actionClosedAsStatus({required String status}) => 'Closed as $status.';

  @override
  String get actionOnlyTerminalStatuses => 'A break can only be closed as Resolved, Written off or False positive.';

  @override
  String get resolutionNoteRequired => 'A resolution note is required.';

  @override
  String get correctionNoteRequired => 'A correction note is required.';

  @override
  String get breakAlreadyClosedByOther => 'This break was already closed by someone else.';

  @override
  String breakAlreadyClosedAsStatus({required String status}) => 'This break was already closed as $status.';

  @override
  String get breakNoLongerExists => 'That break no longer exists. Refreshing the list.';

  @override
  String correctionPosted({required String amount}) => 'Posted $amount to the ledger.';

  @override
  String get correctionAlreadyResolved => 'This break is already closed. If a correction timed out, it most likely went through - check the ledger transaction on the break.';

  @override
  String get correctionNothingToCorrect => 'This break has no outstanding difference to correct.';

  @override
  String ledgerRefusedCorrection({required String reference}) => 'The ledger refused the correction. Quote $reference to support, and re-check the break before retrying.';

  @override
  String get correlationIdFallback => 'the correlation id';

  @override
  String assignWouldReopen({required String status}) => 'This break is already closed as $status. Assigning it would re-open it and keep the old resolution note.';

  @override
  String get breakStillLoading => 'The break is still loading. Try again in a moment.';

  @override
  String get onlyFloatMismatchCorrectable => 'Only an agent float mismatch can be corrected this way.';

  @override
  String get anotherActionRunning => 'Another action on this break is still running.';

  @override
  String get pmScreenTitle => 'Payment methods';

  @override
  String get pmNewMethodButton => 'New method';

  @override
  String get pmReadersDeniedMessage => 'Payment configuration is readable by Super admin, Finance admin, Reviewer and Support. The backend refuses every route on this screen for a Viewer.';

  @override
  String get pmEmptyTitle => 'No payment methods yet';

  @override
  String get pmFilterEmptyTitle => 'Nothing matches this filter';

  @override
  String get pmEmptyMessageManager => 'Create one to let players deposit. Remember to add a real destination before taking money.';

  @override
  String get pmEmptyMessageReader => 'Nothing is configured yet.';

  @override
  String get pmFilterEmptyMessage => 'Clear the filter to see every configured method.';

  @override
  String get pmLoadingList => 'Loading payment methods...';

  @override
  String get pmStatusActive => 'Active';

  @override
  String get pmStatusDisabled => 'Disabled';

  @override
  String get pmFilterRailTooltip => 'Filter by rail';

  @override
  String get pmFilterEveryRail => 'Every rail';

  @override
  String get pmDetailTitle => 'Payment method';

  @override
  String get pmLoadingMethod => 'Loading payment method...';

  @override
  String pmNoDriverTitle({required String rail}) => 'No driver implements $rail';

  @override
  String get pmNoDriverMessage => 'The backend reported no required proof fields for this rail, which means no driver exists. Players cannot deposit on this method at all, and a new method can never be created on this rail (422 RAIL_NOT_SUPPORTED).';

  @override
  String get pmRecordSection => 'Record';

  @override
  String get pmIdentifierLabel => 'Identifier';

  @override
  String get pmIdentifierHint => 'UUID used by every route on this screen.';

  @override
  String get pmLastUpdatedLabel => 'Last updated';

  @override
  String get pmLastUpdatedHint => 'Every save writes an audit row, including an empty one.';

  @override
  String pmHeaderSubtitle({required String rail, required String currency}) => '$rail - $currency';

  @override
  String get pmMachineCodeLabel => 'Machine code';

  @override
  String get pmMachineCodeHint => 'Immutable. Seeds and the mini app reference it forever.';

  @override
  String get pmRailLabel => 'Rail';

  @override
  String get pmImmutableAfterCreationHint => 'Immutable after creation.';

  @override
  String get currencyLabel => 'Currency';

  @override
  String get pmSortOrderLabel => 'Sort order';

  @override
  String get enableButton => 'Enable';

  @override
  String get disableButton => 'Disable';

  @override
  String pmEnableMethodTitle({required String name}) => 'Enable $name?';

  @override
  String pmDisableMethodTitle({required String name}) => 'Disable $name?';

  @override
  String get pmEnableMethodMessage => 'Players will be able to pick this method again. Check its destinations first - a disabled placeholder does not protect anyone once the method is live.';

  @override
  String get pmDisableMethodMessage => 'Players can no longer start a deposit on this method. Nothing is deleted: existing deposits keep pointing at it and you can re-enable it at any time.';

  @override
  String get pmLimitsSection => 'Limits and fees';

  @override
  String get pmLimitsSubtitle => 'Amounts are exact minor units end to end; only this screen formats them.';

  @override
  String get pmMinimumLabel => 'Minimum';

  @override
  String get pmMinimumHint => 'A deposit below this is refused with AMOUNT_BELOW_MINIMUM.';

  @override
  String get pmMaximumLabel => 'Maximum';

  @override
  String get pmMaximumHint => 'Above this the rail answers AMOUNT_ABOVE_MAXIMUM.';

  @override
  String get pmFixedFeeLabel => 'Fixed fee';

  @override
  String get pmFixedFeeHint => 'Must stay strictly below the minimum, or the smallest allowed deposit credits nothing.';

  @override
  String get pmVariableFeeLabel => 'Variable fee';

  @override
  String pmVariableFeeValue({required int bps, required String percent}) => '$bps bps ($percent)';

  @override
  String get pmVariableFeeHint => 'Basis points. 10000 bps = 100%. Rounded half-up.';

  @override
  String get pmFeeAtMinimumLabel => 'Fee at minimum';

  @override
  String get pmCreditedAtMinimumLabel => 'Credited at minimum';

  @override
  String get pmCreditedAtMinimumHintOk => 'What a player depositing the minimum actually receives.';

  @override
  String get pmCreditedAtMinimumHintBad => 'The smallest allowed deposit credits nothing. Fix the fee.';

  @override
  String get pmFeeAtMaximumLabel => 'Fee at maximum';

  @override
  String get pmVerificationSection => 'Verification';

  @override
  String get pmVerificationModeRowLabel => 'Mode';

  @override
  String get pmVerificationModeHint => 'Stored metadata only: v1 has no statement ingestion and every rail is reviewed by hand regardless of this value.';

  @override
  String get referenceLabel => 'Reference';

  @override
  String get pmReferenceRequiredValue => 'Required from the player';

  @override
  String get pmReferenceOptionalValue => 'Optional';

  @override
  String pmReferenceMootHint({required String rail, required String state}) => 'The $rail driver already lists REFERENCE, so the "requires reference" switch cannot make it optional - it is currently $state and changes nothing.';

  @override
  String get pmReferenceSwitchHint => 'Driven by the "requires reference" switch on this method.';

  @override
  String get pmReferencePatternRowLabel => 'Reference pattern';

  @override
  String get noneLabel => 'None';

  @override
  String get pmReferencePatternHint => 'Raw regex source, run against player input after a 128-character guard.';

  @override
  String get pmReferencePatternNoneHint => 'Any non-empty reference is accepted.';

  @override
  String get pmProofFieldsIntro => 'Proof fields the player form asks for, in order:';

  @override
  String get pmProofFieldsNone => 'None - this rail has no driver.';

  @override
  String get pmPatternBrokenTitle => 'This reference pattern does not compile';

  @override
  String pmPatternBrokenMessage({required String error}) => 'The backend never checks that a pattern compiles: it silently treats a broken one as "no pattern", so nothing on the server will ever report this. ($error)';

  @override
  String get pmHumanCheckedTitle => 'Some proof fields are checked by a human, not the server';

  @override
  String get pmHumanCheckedMessage => 'The submission the rail driver sees carries only a reference, a sender account and a proof count. These fields shape the player form and the reviewer checklist, but nothing validates them:';

  @override
  String get pmInstructionsSection => 'Player instructions';

  @override
  String get pmInstructionsSubtitle => 'Rendered into the Telegram message the player reads.';

  @override
  String get pmInstructionsEmpty => 'None set. The player sees only the destination details.';

  @override
  String get pmDestinationsHeading => 'Destinations';

  @override
  String get pmHideDisabled => 'Hide disabled';

  @override
  String get pmShowAll => 'Show all';

  @override
  String get pmDestinationsOrderNote => 'Ordered exactly as the picker rotates them: priority ascending, lower offered first.';

  @override
  String get pmLoadingDestinations => 'Loading destinations...';

  @override
  String get pmAddDestination => 'Add destination';

  @override
  String get pmNoDestinationsTitle => 'No destinations configured';

  @override
  String get pmNoDestinationsMessage => 'Every player deposit on this method fails with 422 NO_DESTINATION_AVAILABLE until one exists.';

  @override
  String get pmDisabledHiddenTitle => 'Disabled rows are hidden';

  @override
  String get pmDisabledHiddenMessage => 'Tap "Show all" - a disabled destination may still be configured here.';

  @override
  String get pmNoActiveDestinationTitle => 'No ACTIVE destination';

  @override
  String get pmNoActiveDestinationMessage => 'Every player deposit on this method fails with 422 NO_DESTINATION_AVAILABLE until one is enabled.';

  @override
  String pdEnableTitle({required String label}) => 'Enable $label?';

  @override
  String pdDisableTitle({required String label}) => 'Disable $label?';

  @override
  String get pdEnableMessage => 'New players can be routed here again. Make sure the account details are real.';

  @override
  String get pdDisableLastMessage => 'This is the LAST ACTIVE destination. Disabling it makes every player deposit on this method fail with NO_DESTINATION_AVAILABLE.';

  @override
  String get pdDisableMessage => 'It stops being handed to new players immediately. A player already told to pay here keeps their 24h stickiness and can still reconcile.';

  @override
  String get pmFormEditTitle => 'Edit method';

  @override
  String get pmFormCreateTitle => 'New payment method';

  @override
  String get pmManagersDeniedTitle => 'You cannot change payment configuration';

  @override
  String get pmManagersDeniedMessage => 'Creating and editing payment methods is limited to Super admin and Finance admin, because this configuration routes real money.';

  @override
  String get pmFixBeforeSaving => 'Fix these before saving';

  @override
  String get pmIdentitySection => 'Identity';

  @override
  String get pmIdentitySubtitleEdit => 'Machine code, rail and currency are immutable - the update endpoint rejects them outright.';

  @override
  String get pmIdentitySubtitleCreate => 'These three can never be changed once saved.';

  @override
  String get pmMachineCodeHelper => 'SCREAMING_SNAKE_CASE, 2-48 characters. Uppercased on save. Stable forever.';

  @override
  String get pmRailHelper => 'Decides which proof fields the player form asks for. INTERNAL is not offered: no driver implements it.';

  @override
  String pmCurrencyHelper({required String currency}) => 'Three letters, and it must already exist in the currencies table. Only $currency is seeded.';

  @override
  String get displayNameLabel => 'Display name';

  @override
  String get pmDisplayNameHelper => 'What the player sees in the deposit menu.';

  @override
  String get pmVerificationModeLabel => 'Verification mode';

  @override
  String get pmVerificationModeHelper => 'Stored metadata. v1 reviews every rail by hand no matter what this says.';

  @override
  String get pmSortOrderHelper => 'Ascending; may be negative. Ties break on display name.';

  @override
  String get pmActiveSwitchOn => 'Players can pick this method.';

  @override
  String get pmActiveSwitchOff => 'Hidden from players. Nothing is deleted.';

  @override
  String get pmProofFieldsPreview => 'Proof fields this rail will ask for:';

  @override
  String get pmLimitsFormSubtitle => 'Sent as major-unit decimal strings with at most two decimals. Parsed here as exact minor units - no floating point anywhere.';

  @override
  String get pmMinAmountLabel => 'Minimum amount';

  @override
  String get pmMinAmountHelper => 'Must be greater than zero.';

  @override
  String get pmMaxAmountLabel => 'Maximum amount';

  @override
  String get pmMaxAmountHelper => 'Must be at least the minimum.';

  @override
  String get pmFeeFixedHelper => 'Optional. Must be strictly below the minimum.';

  @override
  String get pmFeeBpsLabel => 'Variable fee (basis points)';

  @override
  String get pmFeeBpsHelper => '0-10000. 10000 bps = 100%. Rounded half-up.';

  @override
  String pmMoneyWillBeSent({required String value}) => 'Will be sent as "$value".';

  @override
  String pmCreditPreview({required String min, required String fee, required String credited}) => 'A player depositing the minimum ($min) pays $fee in fees and is credited $credited.';

  @override
  String get pmCreditsNothingWarning => 'That credits nothing. The backend refuses this with PAYMENT_METHOD_INVALID on feeFixed.';

  @override
  String get pmRequiresReferenceSwitch => 'Requires a reference';

  @override
  String pmRequiresReferenceOnRail({required String rail}) => 'The $rail driver already demands a reference, so turning this off changes nothing for the player.';

  @override
  String get pmRequiresReferenceHint => 'A reference is demanded at submit time when this is on.';

  @override
  String get pmReferencePatternFieldLabel => 'Reference pattern (regex source)';

  @override
  String get pmReferencePatternFieldHelper => 'Raw regex, no slashes and no flags, max 256 characters. Leave blank to accept any reference.';

  @override
  String get pmPatternMayNotWorkTitle => 'This pattern may not work';

  @override
  String get pmProbeLabel => 'Test a reference against the pattern';

  @override
  String get pmProbeIdleHelper => 'The backend never validates this pattern. A wrong one rejects every deposit reference on this method, and only players ever see it.';

  @override
  String get pmProbeAccepted => 'Accepted.';

  @override
  String get pmProbeRejected => 'Rejected - the player would see REFERENCE_MALFORMED.';

  @override
  String get pmPatternCannotClearTitle => 'A pattern cannot be cleared to null';

  @override
  String get pmPatternCannotClearMessage => 'The update endpoint rejects null and ignores an omitted key. Saving an empty box stores an empty string, which the driver treats as "no pattern" - the closest available action.';

  @override
  String get pmInstructionsFormSubtitle => 'Max 2000 characters, rendered as Telegram-safe HTML.';

  @override
  String get pmInstructionsFieldHelper => 'Shown above the destination details. Destination notes are appended to it verbatim.';

  @override
  String get pmBothLimitsRequired => 'Both limits are required.';

  @override
  String get pdFormEditTitle => 'Edit destination';

  @override
  String get pdFormCreateTitle => 'New destination';

  @override
  String get pdManagersDeniedTitle => 'You cannot change payment destinations';

  @override
  String get pdManagersDeniedMessage => 'Only Super admin and Finance admin may change where player money is sent.';

  @override
  String get pdCryptoChainTitle => 'On this rail the label IS the chain';

  @override
  String pdCryptoChainMessage({required String label}) => 'The player reads "Network: $label". A wrong chain name sends funds somewhere they cannot be recovered from. The account holder field is ignored by this driver.';

  @override
  String get pdAccountSubtitle => 'What the player is told to pay into.';

  @override
  String pdLabelFieldLabel({required String caption}) => '$caption (label)';

  @override
  String get pdAccountIdentifierHelper => 'Stored EXACTLY as typed - only outer spaces are trimmed, nothing is uppercased. Immutable once saved.';

  @override
  String get pdAccountIdentifierImmutableHint => 'Immutable: historical deposits point at it and it is half of the uniqueness key. To change the account, add a new destination and disable this one.';

  @override
  String get pdPlaceholderTypedTitle => 'That still looks like a placeholder';

  @override
  String get pdPlaceholderTypedMessage => 'A player who pays into a placeholder account sends money nowhere. Enter the real account details.';

  @override
  String pdAccountHolderIgnoredHelper({required String rail}) => 'Ignored by the $rail driver, but kept for your own records.';

  @override
  String get pdAccountHolderHelper => 'Shown to the player next to the account.';

  @override
  String get pdStatusActive => 'Active';

  @override
  String get pdStatusDisabled => 'Disabled';

  @override
  String get pdActiveSwitchOn => 'Can be handed to new players by the rotation picker.';

  @override
  String get pdActiveSwitchOff => 'Never handed out. Players already told to pay here keep their 24h stickiness and can still reconcile.';

  @override
  String get pdRoutingSection => 'Routing';

  @override
  String get pdRoutingSubtitle => 'How the picker spreads volume across destinations.';

  @override
  String get pdPriorityLabel => 'Priority';

  @override
  String get pdPriorityHelper => 'LOWER IS OFFERED FIRST. It is inverted into a rotation weight capped at 16, so 0 and 4 split traffic about 5:1. Not a "preferred" flag.';

  @override
  String pdDailyCapLabel({required String currency}) => 'Daily cap ($currency)';

  @override
  String get pdDailyCapHelper => 'Optional SOFT cap measured against claimed amounts. If every destination is over cap the picker ignores caps rather than blocking the player.';

  @override
  String pdDailyCapHelperParsed({required String value}) => 'Will be sent as "$value". Soft cap: the picker ignores it when every destination is over.';

  @override
  String get pdCapCannotBeRemovedTitle => 'A cap cannot be removed through this API';

  @override
  String get pdCapCannotBeRemovedMessage => 'The update endpoint rejects null and an empty string fails the money format, so a cap can only be overwritten with another amount. Clearing it is a backend gap.';

  @override
  String get notesLabel => 'Notes';

  @override
  String get pdNotesSubtitle => 'Appended VERBATIM to the player-facing instructions.';

  @override
  String get pdNotesHelper => 'Max 1000 characters. The player reads this, so keep it operational, not internal.';

  @override
  String get pdDailyCapFieldLabel => 'Daily cap';

  @override
  String get railBankTransfer => 'Bank transfer';

  @override
  String get railMobileWallet => 'Mobile wallet';

  @override
  String get railCashOffice => 'Cash office';

  @override
  String get railCrypto => 'Crypto';

  @override
  String get railInternal => 'Internal';

  @override
  String get destCaptionBank => 'Bank';

  @override
  String get destCaptionWallet => 'Wallet';

  @override
  String get destCaptionOffice => 'Office';

  @override
  String get networkLabel => 'Network';

  @override
  String get destCaptionLabel => 'Label';

  @override
  String get destHintBank => 'Bank name, shown to the player';

  @override
  String get destHintWallet => 'Wallet provider name';

  @override
  String get destHintOffice => 'Cash office name';

  @override
  String get destHintCrypto => 'CHAIN NAME - the player pays on this network';

  @override
  String get destHintInternal => 'Label shown to the player';

  @override
  String get accountCaptionBank => 'IBAN / account number';

  @override
  String get accountCaptionWallet => 'Wallet number (MSISDN)';

  @override
  String get accountCaptionOffice => 'Office code';

  @override
  String get accountCaptionCrypto => 'Wallet address';

  @override
  String get accountCaptionInternal => 'Account identifier';

  @override
  String get verificationManualProof => 'Manual proof';

  @override
  String get verificationReferenceMatch => 'Reference match';

  @override
  String get verificationAutoStatement => 'Automatic statement';

  @override
  String get verificationNone => 'None';

  @override
  String get proofFieldSenderName => 'Sender name';

  @override
  String get proofFieldReceiptImage => 'Receipt image';

  @override
  String get proofFieldTxHash => 'Transaction hash';

  @override
  String get pmCodeRequired => 'A machine code is required.';

  @override
  String get pmCodeMalformed => 'Use SCREAMING_SNAKE_CASE, 2-48 characters, starting with a letter.';

  @override
  String get pmCurrencyInvalid => 'Use a 3-letter currency code that exists in the currencies table.';

  @override
  String get pmDisplayNameRequired => 'A display name is required.';

  @override
  String get pmDestLabelRequired => 'A label is required.';

  @override
  String get pmAccountIdentifierRequired => 'An account identifier is required.';

  @override
  String pmKeepUnderChars({required int max}) => 'Keep it under $max characters.';

  @override
  String pmAccountHolderTooLong({required int max}) => 'Keep the account holder under $max characters.';

  @override
  String pmNotesTooLong({required int max}) => 'Keep notes under $max characters.';

  @override
  String pmInstructionsTooLong({required int max}) => 'Keep instructions under $max characters.';

  @override
  String pmFeeBpsRange({required int max}) => 'Basis points must be between 0 and $max (10000 = 100%).';

  @override
  String get pmPriorityNegative => 'Priority cannot be negative.';

  @override
  String pmPatternTooLong({required int max}) => 'Keep the pattern under $max characters.';

  @override
  String pmPatternWarning({required String error}) => 'This pattern does not compile here ($error). The backend will silently treat it as "no pattern".';

  @override
  String get pmMinNotPositive => 'The minimum must be greater than zero.';

  @override
  String get pmAmountsCurrencyMismatch => 'All three amounts must be in the same currency.';

  @override
  String get pmMaxBelowMin => 'The maximum cannot be below the minimum.';

  @override
  String get pmFeeNegative => 'The fixed fee cannot be negative.';

  @override
  String get pmFeeNotBelowMin => 'The fixed fee must be strictly below the minimum, or the smallest allowed deposit credits nothing.';

  @override
  String get pmIntegerRequired => 'Enter a whole number.';

  @override
  String pmIntegerMin({required int min}) => 'Must be at least $min.';

  @override
  String pmIntegerMax({required int max}) => 'Must be at most $max.';

  @override
  String get pmFieldLabelFeeBps => 'Fee basis points';

  @override
  String fieldIssuePrefix({required String field, required String message}) => '$field: $message';

  @override
  String pmCreatedToast({required String name}) => '$name created.';

  @override
  String pmSavedToast({required String name}) => '$name saved.';

  @override
  String pmEnabledToast({required String name}) => '$name is live again.';

  @override
  String pmDisabledToast({required String name}) => '$name is disabled. Players can no longer pick it.';

  @override
  String pdAddedToast({required String label}) => '$label added. Verify the account before real deposits.';

  @override
  String pdSavedToast({required String label}) => '$label saved.';

  @override
  String pdEnabledToast({required String label}) => '$label is being offered again.';

  @override
  String pdDisabledToast({required String label}) => '$label will not be handed to new players.';

  @override
  String get pmCodeConflict => 'A payment method with that machine code already exists.';

  @override
  String get pdConflict => 'That account is already configured for this payment method.';

  @override
  String get pmRailNotSupported => 'No driver implements that rail, so a method cannot run on it.';

  @override
  String get pdNotFound => 'That destination no longer exists. Refreshing.';

  @override
  String get pmNotFound => 'That payment method no longer exists. Refreshing.';

  @override
  String pmFailureReference({required String code, required String correlationId}) => '$code - ref $correlationId';

  @override
  String get pmNoDriverChip => 'No driver - unusable';

  @override
  String get pmPlaceholderChip => 'Placeholder destination';

  @override
  String get pmLimitsChipLabel => 'Limits';

  @override
  String pdPriorityChip({required int priority}) => 'Priority $priority';

  @override
  String pdSoftCapChip({required String amount}) => 'Soft cap $amount';

  @override
  String get pdHolderIgnoredChip => 'Holder ignored on this rail';

  @override
  String pdHolderChip({required String holder}) => 'Holder: $holder';

  @override
  String get pdNotesAppendedNote => 'Appended to the player instructions verbatim:';

  @override
  String get pmAuditBannerTitle => 'Money paid to these accounts goes nowhere';

  @override
  String pmAuditBannerMessage({required int rows, required int methods}) => '${rows == 1 ? '1 active destination' : '$rows active destinations'} on ${methods == 1 ? '1 payment method' : '$methods payment methods'} still look like the seeded placeholders. Replace them before any real player deposits - open the method to see which.';

  @override
  String get pmDormantPlaceholderTitle => 'Disabled placeholder rows are still here';

  @override
  String pmDormantPlaceholderMessage({required int count}) => count == 1 ? '1 placeholder destination remains on this method but is disabled, so no player is sent there.' : '$count placeholder destinations remain on this method but are disabled, so no player is sent there.';

  @override
  String get pmLivePlaceholderTitle => 'This method can hand a player a placeholder account';

  @override
  String get pmLivePlaceholderMessage => 'A player who pays into one of these sends money nowhere. Add the real account, then disable the placeholder.';

  @override
  String get pdPlaceholderBadgeLive => 'PLACEHOLDER - LIVE';

  @override
  String get pdPlaceholderBadge => 'Placeholder';

  @override
  String pdReasonSeedPrefix({required String prefix}) => 'The account identifier is still the seeded placeholder ("$prefix-...").';

  @override
  String get pdReasonMarker => 'The account identifier still contains a placeholder marker.';

  @override
  String get pdReasonHolder => 'The account holder has not been filled in yet.';

  @override
  String get pdReasonNotes => 'The notes still say this row came from the seed.';

  @override
  String get pmPermissionDeniedTitle => 'You cannot open this screen';

  @override
  String pmPermissionDeniedMessage({required String roles, required String role}) => 'Payment configuration routes accept $roles. You are signed in as $role.';

  @override
  String get pmNoRole => 'no role';

  @override
  String get auScreenTitle => 'Administrators';

  @override
  String get auAddButton => 'Add';

  @override
  String get auSearchHint => 'Name, @username or Telegram id';

  @override
  String get auSearchHelper => 'Filters the rows already loaded - the endpoint has no text search.';

  @override
  String get auClearSearchTooltip => 'Clear search';

  @override
  String get auFilterEveryone => 'Everyone';

  @override
  String get auStatusActive => 'Active';

  @override
  String get auStatusDeactivated => 'Deactivated';

  @override
  String get auAllRoles => 'All roles';

  @override
  String get auRoleFieldLabel => 'Role';

  @override
  String get auEmptyTitle => 'No administrators match';

  @override
  String auEmptyMessage({required String filter}) => 'Nothing in the directory matches $filter. Clear the filters to see everyone.';

  @override
  String get auLoadingDirectory => 'Loading the staff directory...';

  @override
  String get auNoSearchMatchTitle => 'No match in the loaded rows';

  @override
  String auNoSearchMatchMessage({required int count, required String query}) => count == 1 ? 'The 1 administrator loaded so far does not match "$query".' : 'None of the $count administrators loaded so far match "$query".';

  @override
  String get auScrollToLoadMore => 'Scroll to load more, or clear the search.';

  @override
  String get auClearSearchToSeeAll => 'Clear the search to see everyone.';

  @override
  String auCountShownOfTotal({required int shown, required int total}) => '$shown of ${total == 1 ? '1 administrator' : '$total administrators'}';

  @override
  String auCountTotal({required int total}) => total == 1 ? '1 administrator' : '$total administrators';

  @override
  String auActiveSuperAdmins({required int count}) => count == 1 ? '1 active super administrator' : '$count active super administrators';

  @override
  String get auLastWayBack => ' - the last way back into the system.';

  @override
  String get auFilterDescribeAll => 'all administrators';

  @override
  String get auFilterActiveOnly => 'active only';

  @override
  String get auFilterDeactivatedOnly => 'deactivated only';

  @override
  String auFilterMatching({required String query}) => 'matching "$query"';

  @override
  String get auDetailFallbackTitle => 'Administrator';

  @override
  String get auLoadingAdministrator => 'Loading administrator...';

  @override
  String get auIdentitySection => 'Identity';

  @override
  String get auUsernameLabel => 'Username';

  @override
  String get auRowIdLabel => 'Row id';

  @override
  String get auAuthoritySection => 'Authority';

  @override
  String get auCreatedRowLabel => 'Created';

  @override
  String get auLastSignInLabel => 'Last sign-in';

  @override
  String get auNeverSignedInValue => 'Never';

  @override
  String auTimestampWithRelative({required String timestamp, required String relative}) => '$timestamp  ($relative)';

  @override
  String get alCeilingsSection => 'Approval ceilings';

  @override
  String get alCeilingsIntro => 'How much this administrator may release on their own, and above what amount a second pair of eyes is required. An administrator with no active ceiling is denied every approval - the evaluator fails closed.';

  @override
  String get alOpenCeilingsButton => 'Open ceilings';

  @override
  String get auYouChip => 'You';

  @override
  String get auDeactivateButton => 'Deactivate';

  @override
  String get auReactivateButton => 'Reactivate';

  @override
  String auDeactivateConfirmTitle({required String name}) => 'Deactivate $name?';

  @override
  String get auDeactivateConfirmMessage => 'They keep appearing on every deposit they ever decided - this is a soft delete, not a removal. Access is revoked in the directory immediately, but the identity cache holds the previous answer for up to 60 seconds, so assume they can still act for one more minute.';

  @override
  String auReactivateConfirmTitle({required String name}) => 'Reactivate $name?';

  @override
  String auReactivateConfirmMessage({required String role}) => 'They regain every power of $role as soon as the identity cache refreshes - within 60 seconds.';

  @override
  String auTileIdOnly({required String id}) => 'id $id';

  @override
  String auTileHandleAndId({required String handle, required String id}) => '$handle  -  id $id';

  @override
  String auTileLastSignIn({required String relative}) => 'Last sign-in $relative';

  @override
  String get auTileNeverSignedIn => 'Has never signed in';

  @override
  String get auFormEditTitle => 'Edit administrator';

  @override
  String get auFormCreateTitle => 'Add administrator';

  @override
  String get auDisplayNameHelper => 'Shown on every deposit this person decides.';

  @override
  String get auUsernameFieldLabel => 'Telegram username (optional)';

  @override
  String get auUsernameHelper => 'Optional, and unique across the directory.';

  @override
  String get auTelegramIdFieldLabel => 'Telegram user id';

  @override
  String get auTelegramIdHelperLocked => 'Fixed once created - the id is who this account IS.';

  @override
  String get auTelegramIdHelper => 'Digits only, up to 19. This is a 64-bit id, not a username.';

  @override
  String get auRoleSelfLocked => 'You cannot change your own role. That is the fastest way to remove the only person who could undo it.';

  @override
  String auActiveOn({required String role}) => 'Can sign in and act with the powers of $role.';

  @override
  String get auActiveOff => 'Cannot sign in. The row stays, referenced by every deposit they ever decided.';

  @override
  String get auCannotDeactivateSelf => 'You cannot deactivate yourself.';

  @override
  String get auSaveChanges => 'Save changes';

  @override
  String get auChangeNotAllowed => 'This change is not allowed.';

  @override
  String get auNothingChanged => 'Nothing changed.';

  @override
  String get alSetCeilingButton => 'Set ceiling';

  @override
  String get alEmptyTitle => 'No ceiling has ever been set';

  @override
  String get alEmptyMessage => 'An administrator with no active ceiling is denied every approval - the evaluator fails closed, so an empty limits table grants nobody anything.';

  @override
  String get alLoadingHistory => 'Loading ceiling history...';

  @override
  String alRoleMayNeverApproveTitle({required String role}) => '$role may never approve';

  @override
  String get alRoleMayNeverApproveMessage => 'A role outside SUPER_ADMIN, FINANCE_ADMIN and REVIEWER is denied before any ceiling is consulted. A ceiling set here would have no effect until the role changes.';

  @override
  String get alVersioningNote => 'Ceilings are versioned, never edited. The daily budget resets at 00:00 UTC and counts both first decisions and second approvals.';

  @override
  String get alNoActiveChip => 'No active ceiling';

  @override
  String get alInForceChip => 'In force';

  @override
  String get alSupersededChip => 'Superseded';

  @override
  String alNoActiveMessage({required String currency}) => 'Every approval in $currency is denied for this administrator until a new ceiling is set.';

  @override
  String get alSingleApprovalLabel => 'Single approval';

  @override
  String get alDailyBudgetLabel => 'Daily budget';

  @override
  String get alSecondApprovalLabel => 'Second approval';

  @override
  String get alInheritsGlobal => 'Inherits the global dual-approval threshold';

  @override
  String get alSecondApprovalAboveLabel => 'Second approval above';

  @override
  String get alEndedLabel => 'Ended';

  @override
  String get alReplaceButton => 'Replace';

  @override
  String get alEndCeilingButton => 'End this ceiling';

  @override
  String alEndConfirmTitle({required String currency}) => 'End the $currency ceiling?';

  @override
  String get alEndConfirmMessage => 'This ends the version WITHOUT replacing it. The administrator is then left with no active ceiling, which the evaluator reads as DENIED - it revokes authority, it never grants it. Set a new ceiling instead if you meant to change the amounts.';

  @override
  String get alEndConfirmLabel => 'End ceiling';

  @override
  String get alFormTitle => 'Set approval ceiling';

  @override
  String alFormHeading({required String name}) => 'New ceiling for $name';

  @override
  String get alFormIntro => 'The version in force is closed at the same instant this one starts, so there is no gap in which this administrator has no ceiling and no overlap in which two apply.';

  @override
  String get alCurrencyHelper => 'Three letters. Ceilings are per currency.';

  @override
  String get alMaxSingleLabel => 'Maximum single approval';

  @override
  String get alMaxSingleHelper => 'Absolute. Above this the administrator may not authorise the amount at all - a second approver does not help.';

  @override
  String get alMaxDailyLabel => 'Maximum daily approval';

  @override
  String get alMaxDailyHelper => 'Budget per UTC day, counting both first decisions and second approvals.';

  @override
  String get alSecondAboveLabel => 'Second approval above (optional)';

  @override
  String get alSecondAboveHelper => 'Leave empty to inherit the global dual-approval threshold. Empty and zero are different intentions.';

  @override
  String alCurrencyThreeLetters({required String currency}) => 'Exactly three letters, for example $currency.';

  @override
  String get alAmountNotNumber => 'One of the amounts is not a number.';

  @override
  String get alSingleNotPositive => 'Single-approval ceiling must be greater than zero.';

  @override
  String get alDailyNotPositive => 'Daily ceiling must be greater than zero.';

  @override
  String get alSingleAboveDaily => 'The single-approval ceiling cannot exceed the daily ceiling. As written, the first approval of the day would always be denied.';

  @override
  String get alSecondNegative => 'The second-approval threshold cannot be negative.';

  @override
  String get profileTitle => 'Profile and settings';

  @override
  String get profileRefreshTooltip => 'Refresh diagnostics';

  @override
  String get profileNotSignedInTitle => 'Not signed in';

  @override
  String get profileNotSignedInMessage => 'This screen shows the signed-in administrator. Sign in with a bot code to see it.';

  @override
  String profileSessionExpiresChip({required String relative}) => 'Expires $relative';

  @override
  String get profileSignedInAsSection => 'Signed in as';

  @override
  String get profileAdminIdLabel => 'Administrator id';

  @override
  String get profileIssuedLabel => 'Issued';

  @override
  String get profileExpiresLabel => 'Expires';

  @override
  String profileCapabilitiesSection({required String role}) => 'What $role can do';

  @override
  String get profileNotAvailableToRole => 'Not available to this role';

  @override
  String get profileServerEnforces => 'The server enforces all of this independently. A control this console leaves enabled by mistake still gets a 403.';

  @override
  String get profileBuildSection => 'This build';

  @override
  String get profileBaseUrlLabel => 'API base URL';

  @override
  String get profileEnvironmentLabel => 'Environment';

  @override
  String get profileAuthAdapterLabel => 'Auth adapter';

  @override
  String get profileFakeChip => 'FAKE';

  @override
  String get profilePageSizeLabel => 'Page size';

  @override
  String get profileCorrelationIdLabel => 'Last correlation id';

  @override
  String get profileFakeAdapterWarning => 'A FAKE auth adapter is active: sessions are minted locally and no bot code is ever checked against the backend. Never ship a build in this state.';

  @override
  String get profileCorrelationNote => 'Support looks requests up by correlation id - every response carries one, including failures.';

  @override
  String get profileSessionSection => 'Session';

  @override
  String get profileSignOutNote => 'Signing out clears the stored session from the device keystore and returns to the bot-code screen.';

  @override
  String get profileSignOutButton => 'Sign out';

  @override
  String get profileSignOutConfirmTitle => 'Sign out?';

  @override
  String get profileSignOutConfirmMessage => 'The stored session is cleared from this device.';

  @override
  String relativeMinutes({required int count}) => '$count min';

  @override
  String relativeHours({required int count}) => '$count h';

  @override
  String relativeDays({required int count}) => '$count d';

  @override
  String relativeMonths({required int count}) => '$count mo';

  @override
  String relativeYears({required int count}) => '$count y';

  @override
  String relativeInFuture({required String phrase}) => 'in $phrase';

  @override
  String get roleSummarySuperAdmin => 'Everything, including adding administrators and setting approval ceilings. The only role that can grant somebody the power to move money.';

  @override
  String get roleSummaryFinanceAdmin => 'Reviews and second-approves deposits, retries credits, works reconciliation breaks, manages payment destinations, and reads the staff directory.';

  @override
  String get roleSummaryReviewer => 'Reviews deposits in the queue. Cannot second-approve and cannot change payment configuration.';

  @override
  String get roleSummarySupport => 'Read-only across the operational surface: the queue, reconciliation and payment methods. Decides nothing.';

  @override
  String get roleSummaryViewer => 'Read-only. The least authority the console offers.';

  @override
  String get capViewDepositQueue => 'See the deposit queue';

  @override
  String get capReviewDeposit => 'Approve or reject a deposit';

  @override
  String get capSecondApprove => 'Give a second approval';

  @override
  String get capRetryCredit => 'Retry a failed credit';

  @override
  String get capViewReconciliation => 'See reconciliation breaks';

  @override
  String get capResolveBreak => 'Resolve a break';

  @override
  String get capViewPaymentMethods => 'See payment methods';

  @override
  String get capManagePaymentDestinations => 'Manage payment destinations';

  @override
  String get capViewAdminUsers => 'See the staff directory';

  @override
  String get capManageAdminUsers => 'Manage administrators and ceilings';

  @override
  String get capViewLedger => 'Read the ledger';

  @override
  String get gateViewDirectoryReason => 'The staff directory is limited to super administrators and finance administrators.';

  @override
  String get gateManageReason => 'Only a super administrator may add, edit or deactivate administrators. Creating an admin or changing a role is the one operation that can grant somebody the power to move money.';

  @override
  String get gateSelfModificationReason => 'You cannot change your own role or deactivate yourself. Ask another super administrator to do it.';

  @override
  String get gateLastSuperAdminReason => 'This is the last active super administrator. Promote another one first, or nobody will be able to undo this.';

  @override
  String get gateAlreadyDeactivated => 'This administrator is already deactivated.';

  @override
  String get gateAlreadyActive => 'This administrator is already active.';

  @override
  String get identityCacheNotice => 'Access is revoked in the directory immediately, but the identity cache holds the previous answer for up to 60 seconds. Assume this person can still act for one more minute.';

  @override
  String get identityCacheNoticeCompact => 'Takes effect in the directory now; the identity cache clears within 60 seconds.';

  @override
  String get auPermissionDeniedTitle => 'Not available to your role';

  @override
  String get auPermissionDeniedFallback => 'Your role does not allow this.';

  @override
  String auPermissionDeniedSignedInAs({required String role}) => 'You are signed in as $role.';

  @override
  String get errAdminNotFound => 'That administrator no longer exists. The directory has moved on since this screen was opened.';

  @override
  String get errAdminAlreadyExists => 'An administrator with that Telegram id or username already exists.';

  @override
  String get errApprovalLimitNotFound => 'That approval limit version no longer exists.';

  @override
  String get errApprovalLimitInvalid => 'The approval ceilings are not coherent, or the version has already ended.';

  @override
  String get errOwnAccountDeactivated => 'Your own administrator account has been deactivated.';

  @override
  String get errRoleNotAllowed => 'Your role is not allowed to do this.';

  @override
  String get errNetwork => 'The console could not reach the server. Check the connection and retry.';

  @override
  String auCreatedToast({required String name}) => '$name added.';

  @override
  String auUpdatedToast({required String name}) => '$name updated.';

  @override
  String auDeactivatedToast({required String name}) => '$name deactivated.';

  @override
  String auReactivatedToast({required String name}) => '$name reactivated.';

  @override
  String get auNoticeNewAdminCanSignIn => 'The new administrator can sign in as soon as the identity cache refreshes - within 60 seconds.';

  @override
  String get auNoticeAccessRestored => 'Access is restored once the identity cache refreshes - within 60 seconds.';

  @override
  String get alSavedToast => 'Approval ceiling saved.';

  @override
  String get alEndedToast => 'Approval ceiling ended.';

  @override
  String get alRacedMessage => 'This ceiling was being changed at the same moment. The history has been reloaded - check it and set the ceiling again if needed.';

  @override
  String get alSetNotice => 'The previous version was closed at the same instant this one started, so there is no gap in which this administrator had no ceiling.';

  @override
  String alEndNotice({required String currency}) => 'This administrator now has no active ceiling in $currency, which the approval evaluator treats as DENIED. Set a new ceiling to restore their authority.';

  @override
  String get auTelegramIdRequired => 'Enter the Telegram user id.';

  @override
  String get auTelegramIdMalformed => 'Digits only, up to 19 of them. No @handle, no separators.';

  @override
  String get auDisplayNameRequired => 'Enter a display name.';

  @override
  String auMaxChars({required int max}) => 'At most $max characters.';

  @override
  String get auUsernameAfterAt => 'Enter the username after the @, or leave the field empty.';

  @override
  String get navHome => 'Home';

  @override
  String get navActivity => 'My deposits';

  @override
  String get navTopUp => 'Top up';

  @override
  String get navMethods => 'Payment methods';

  @override
  String get navProfile => 'My account';

  @override
  String get connectionChecking => 'Checking…';

  @override
  String get connectionOnline => 'Online';

  @override
  String get connectionOffline => 'Offline';

  @override
  String connectionLatencyMs({required int ms}) => '$ms ms';

  @override
  String homeGreeting({required String name}) => 'Hi, $name';

  @override
  String get homeTagline => 'Top up your balance, fast and safe';

  @override
  String get homeBalanceLabel => 'Your casino balance';

  @override
  String homeBalanceUpdated({required String age}) => 'Last updated $age';

  @override
  String homeBalancePendingChip({required int count}) => '$count under review';

  @override
  String get homeBalanceVisibilityTooltip => 'Show or hide the balance';

  @override
  String get homeTopUpCta => 'Top up now';

  @override
  String get homeQuickTopUp => 'Top up';

  @override
  String get homeQuickDeposits => 'My deposits';

  @override
  String get homeQuickMethods => 'Payment methods';

  @override
  String get homeQuickSupport => 'Support';

  @override
  String get homePromoSectionTitle => 'Offers & announcements';

  @override
  String get homePromoAction => 'Learn more';

  @override
  String get homePromoBonusTitle => 'First deposit bonus';

  @override
  String get homePromoBonusBody => 'Make your first top-up and get a bonus credited straight to your balance.';

  @override
  String get homePromoInstantTitle => 'Credited in minutes';

  @override
  String get homePromoInstantBody => 'Most deposits are reviewed and credited within minutes of uploading the receipt.';

  @override
  String get homePromoRailsTitle => 'Trusted payment rails';

  @override
  String get homePromoRailsBody => 'Bank transfers, e-wallets and crypto, all approved by the cashier.';

  @override
  String get homeRecentTitle => 'Recent activity';

  @override
  String get homeRecentEmptyMessage => 'Top up and your request shows up here right away.';

  @override
  String get homeAccountNotLinkedTitle => "Your casino account isn't linked yet";

  @override
  String get homeAccountNotLinkedMessage => 'Send your Ichancy username to support inside the bot to get it linked. After that every top-up lands straight in your balance.';

  @override
  String get homeAccountLinkCta => 'Link my account';

  @override
  String get homeAccountLinkedTitle => 'Your account is linked';

  @override
  String get homeAccountLinkedMessage => 'Every top-up lands straight in your Ichancy balance.';

  @override
  String get activityTitle => 'My deposits';

  @override
  String activityShowingCount({required int shown, required int total}) => '$shown of $total';

  @override
  String get activityFilterInReview => 'In review';

  @override
  String get activityFilterCompleted => 'Completed';

  @override
  String get activityFilterRejected => 'Rejected';

  @override
  String get activitySummaryCreditedLabel => 'Total credited';

  @override
  String activityInProgressCount({required int count}) => '$count in progress';

  @override
  String get activitySummaryAllSettled => 'Nothing pending';

  @override
  String activityViaMethod({required String method}) => 'via $method';

  @override
  String get activityEmptyTitle => 'No deposits yet';

  @override
  String get activityEmptyMessage => 'Start your first top-up and it will appear here the moment you send it.';

  @override
  String get activityStartTopUpAction => 'Start a top-up';

  @override
  String get activityFilterEmptyTitle => 'Nothing in this filter';

  @override
  String get activityFilterEmptyMessage => 'Try another filter, or show everything.';

  @override
  String get activityShowAllAction => 'Show all';

  @override
  String get activityErrorTitle => 'Could not load your deposits';

  @override
  String get activityErrorMessage => 'Check your connection, then try again.';

  @override
  String get activityDetailTitle => 'Deposit details';

  @override
  String get activityDetailAmountLabel => 'Amount sent';

  @override
  String get activityDetailCreditedLabel => 'Credited to your balance';

  @override
  String get activityDetailMethodLabel => 'Payment method';

  @override
  String get activityDetailDestinationLabel => 'Receiving account';

  @override
  String get activityDetailSenderLabel => 'Sender name';

  @override
  String get activityDetailSubmittedLabel => 'Sent at';

  @override
  String get activityNextStepHeading => 'What happens next';

  @override
  String get activityTimelineHeading => 'What happened';

  @override
  String get activityRecordHeading => 'The record';

  @override
  String get activityRequestNumberLabel => 'Request no.';

  @override
  String get activityStaffNoteLabel => 'Staff note';

  @override
  String get activityStepNowBadge => 'Now';

  @override
  String get activityCloseButton => 'Close';

  @override
  String get activityStepSubmittedTitle => 'You sent the receipt';

  @override
  String get activityStepSubmittedBody => 'Your request reached the cashier team.';

  @override
  String get activityStepReviewTitle => 'Review';

  @override
  String get activityStepReviewBody => 'A cashier is matching your receipt against the incoming transfer. Usually a few minutes.';

  @override
  String get activityStepApprovedTitle => 'Approval';

  @override
  String get activityStepApprovedBody => 'The amount was approved and is on its way to your account.';

  @override
  String get activityStepCreditedTitle => 'Balance credited';

  @override
  String get activityStepCreditedBody => 'The money is available in your balance.';

  @override
  String get activityStepRejectedTitle => 'Request rejected';

  @override
  String get activityStepRejectedBody => 'The receipt did not match the transfer. Read the staff note, then try again with a clearer receipt.';

  @override
  String get activityStepExpiredTitle => 'Request expired';

  @override
  String get activityStepExpiredBody => 'No matching transfer arrived in time, so the request was closed. You can start a new one.';

  @override
  String get topupTitle => 'Top up';

  @override
  String get topupCloseTooltip => 'Close';

  @override
  String topupStepOfTotal({required int step, required int total}) => 'Step $step of $total';

  @override
  String get topupStepAmount => 'Amount';

  @override
  String get topupStepMethod => 'Method';

  @override
  String get topupStepPay => 'Pay';

  @override
  String get topupStepReceipt => 'Receipt';

  @override
  String get topupStepDone => 'Done';

  @override
  String get topupNext => 'Next';

  @override
  String get topupBack => 'Back';

  @override
  String get topupAmountHeadline => 'How much do you want to top up?';

  @override
  String get topupAmountSubhead => 'Pick a ready amount or type your own.';

  @override
  String get topupAmountFieldLabel => 'Amount in NSP';

  @override
  String get topupAmountFieldHint => '50000';

  @override
  String topupAmountHelper({required String min, required String max}) => 'From $min to $max';

  @override
  String get topupQuickPicksLabel => 'Quick amounts';

  @override
  String get topupAmountErrorNotPositive => 'The amount must be greater than zero.';

  @override
  String topupAmountErrorBelowMin({required String min}) => 'Below the minimum of $min.';

  @override
  String topupAmountErrorAboveMax({required String max}) => 'Above the maximum of $max.';

  @override
  String get topupMethodsLoadFailed => 'Payment methods could not be loaded.';

  @override
  String get topupMethodHeadline => 'How will you pay?';

  @override
  String get topupMethodSubhead => 'Choose the rail, then the account you will transfer to.';

  @override
  String topupMethodLimits({required String min, required String max}) => '$min to $max';

  @override
  String get topupMethodNotForAmount => 'Does not fit this amount';

  @override
  String get topupNoMethodsTitle => 'No payment method available';

  @override
  String get topupNoMethodsMessage => 'Try again shortly, or contact support.';

  @override
  String get topupDestinationSectionTitle => 'Receiving account';

  @override
  String get topupNoDestinationsTitle => 'No live account on this method';

  @override
  String get topupNoDestinationsMessage => 'Choose another payment method.';

  @override
  String get topupSelectedBadge => 'Selected';

  @override
  String topupReviewEta({required int minutes}) => 'Usually reviewed within $minutes minutes.';

  @override
  String get topupPayHeadline => 'Send the money now';

  @override
  String get topupPaySubhead => 'Send exactly this amount to the account below and keep the receipt.';

  @override
  String get topupAmountToSendLabel => 'Amount to send';

  @override
  String get topupFeeLabel => 'Fee';

  @override
  String get topupCreditedLabel => 'Credited to your balance';

  @override
  String get topupReferenceHint => 'Put the reference in the transfer note, otherwise matching is delayed.';

  @override
  String get topupDeadlineLabel => 'Window closes at';

  @override
  String get topupDeadlineExpired => 'Window closed';

  @override
  String topupCountdown({required int minutes, required int seconds}) =>
      '${_pad2(minutes)}:${_pad2(seconds)}';

  @override
  String get topupPaidCta => 'I have sent it';

  @override
  String get topupReceiptHeadline => 'Upload the receipt';

  @override
  String get topupReceiptSubhead => 'A clear photo showing the amount, the date and the transaction number.';

  @override
  String get topupReceiptEmptyTitle => 'No image yet';

  @override
  String get topupReceiptEmptyMessage => 'Tap here to pick an image from your gallery.';

  @override
  String get topupReceiptPickCta => 'Pick an image';

  @override
  String get topupReceiptReplaceCta => 'Replace image';

  @override
  String get topupReceiptRemoveCta => 'Remove';

  @override
  String get topupReceiptPickerUnavailable => 'Image picking is not enabled in this build yet.';

  @override
  String get topupSenderNameHelper => 'The name on the account you sent from.';

  @override
  String get topupSummaryTitle => 'Request summary';

  @override
  String get topupSubmitCta => 'Submit the request';

  @override
  String get topupSubmitFailedTitle => 'The request could not be sent';

  @override
  String get topupSuccessHeadline => 'Your request is in';

  @override
  String get topupSuccessMessage => 'A cashier will check the receipt; your balance is credited on approval.';

  @override
  String get topupShortIdLabel => 'Request id';

  @override
  String get topupWhatHappensNext => 'What happens next';

  @override
  String get topupNextStepReview => 'A cashier checks the receipt and matches the amount.';

  @override
  String get topupNextStepCredit => 'The amount is credited to your casino balance.';

  @override
  String get topupNextStepNotify => 'You will find the result in My deposits.';

  @override
  String get topupDoneCta => 'Done';

  @override
  String get topupAnotherCta => 'Another top-up';

  @override
  String get topupDemoNotice => 'Demo data - the server is wired in later.';

  @override
  String get methodsIntro => 'Pick the rail that suits you and start a top-up in a few clear steps.';

  @override
  String methodsAvailableCount({required int available, required int total}) => '$available of $total available now';

  @override
  String get methodsFilterAvailableOnly => 'Available now';

  @override
  String get methodsBadgeAvailable => 'Available';

  @override
  String get methodsBadgeBusy => 'Busy';

  @override
  String get methodsBadgeUnavailable => 'Temporarily unavailable';

  @override
  String get methodsBadgeMostUsed => 'Most used';

  @override
  String get methodsBusyNote => 'This method is under heavy load, so confirmation may take longer than usual.';

  @override
  String get methodsPausedNote => 'This method is paused right now. Pick another one or check back later.';

  @override
  String get methodsSettlementLabel => 'Settlement time';

  @override
  String methodsSettlementWithin({required String age}) => 'Within $age';

  @override
  String get methodsSettlementInstant => 'Instant';

  @override
  String get methodsFeeNone => 'No fee';

  @override
  String get methodsReferenceOptionalShort => 'Reference optional';

  @override
  String get methodsCheckedLabel => 'Last checked';

  @override
  String get methodsSectionFastest => 'Fastest for you right now';

  @override
  String get methodsSectionOther => 'More methods';

  @override
  String get methodsSectionPaused => 'Paused right now';

  @override
  String get methodsHowToTitle => 'How to pay';

  @override
  String get methodsProofTitle => 'Required proof';

  @override
  String get methodsDestinationTitle => 'Destination account';

  @override
  String get methodsAccountCopied => 'Account number copied';

  @override
  String get methodsReferenceHintRequired => 'Enter the transfer reference when you upload the receipt.';

  @override
  String get methodsReferenceHintOptional => 'The reference is optional here, but it speeds up the review.';

  @override
  String get methodsTopUpNowCta => 'Top up now';

  @override
  String get methodsEmptyMessage => 'No payment methods are available right now. Try refreshing in a moment.';

  @override
  String get profileSectionAccount => 'Account details';

  @override
  String get profileUsernameLabel => 'Username';

  @override
  String get profileGamingAccountLabel => 'Gaming account';

  @override
  String get profileAccountStatusActive => 'Active';

  @override
  String get profileAccountStatusLimited => 'Limited';

  @override
  String get profileAccountStatusSuspended => 'Suspended';

  @override
  String get profileGamingLinked => 'Linked';

  @override
  String get profileGamingPending => 'Being linked';

  @override
  String get profileGamingMissing => 'Not linked';

  @override
  String get profileStatTotalDeposited => 'Total deposited';

  @override
  String get profileStatDepositCount => 'Deposits';

  @override
  String get profileStatMemberSince => 'Member since';

  @override
  String get profileReferralCodeLabel => 'Referral code';

  @override
  String get profileInviteLinkLabel => 'Invite link';

  @override
  String get profileReferralHint => "Share your link - you earn a bonus on your friend's first top-up.";

  @override
  String get profileRevealTooltip => 'Show or hide identifiers';

  @override
  String get profileSectionConnection => 'Server connection';

  @override
  String get profileHealthEndpointLabel => 'Health endpoint';

  @override
  String get profileLastCheckedLabel => 'Last checked';

  @override
  String get profileRecheckButton => 'Re-check';

  @override
  String get profileTermsLabel => 'Terms and conditions';

  @override
  String get profileTermsBody => 'Top-ups go through an approved cashier. Attach a clear receipt showing the amount, the reference and the time. Every request is reviewed by a human and may be rejected if the receipt does not match the amount claimed. Amounts are in NSP and are never rounded.';

  @override
  String get profileSupportLabel => 'Help and support';

  @override
  String get profileSupportBody => 'Message the cashier on Telegram. Include the deposit reference and the transfer time so the reply comes faster.';

  @override
  String get profileSupportChannelLabel => 'Support channel';

  @override
  String get profileAppVersionLabel => 'App version';

  @override
  String get profileCloseButton => 'Close';

  @override
  String get profileEmptyTitle => 'No profile yet';

  @override
  String get profileEmptyMessage => 'Start your first top-up and your profile is created automatically.';

  @override
  String get profileLoadFailedTitle => 'Could not load your account';

  /// Zero-pads one countdown component to two Western digits.
  static String _pad2(int value) => value.toString().padLeft(2, '0');

}
