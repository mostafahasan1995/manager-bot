import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/auth/auth_controller.dart';
import 'package:manager_bot/core/config/app_config.dart';
import 'package:manager_bot/core/errors/api_error.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/widgets/widgets.dart';

/// The only way into the console.
///
/// The backend has NO admin login endpoint yet (see
/// `lib/core/auth/http_admin_auth_api.dart`), so in dev this screen talks to
/// `FakeAdminAuthApi` and accepts the documented `DEV-<ROLE>` codes. The screen
/// itself does not care which adapter is bound: it calls
/// [AuthController.signInWithBotCode] and renders whatever [AuthState] comes
/// back.
///
/// Routed as `AppRoute.login` (`/login`). The router sends every
/// non-authenticated state here, so this is also where an expired session lands
/// - which is why [AuthExpired] gets a banner naming the admin whose session
/// died rather than a bare "signed out".
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _code = TextEditingController();
  final FocusNode _codeFocus = FocusNode();

  /// True once the operator has tried at least once, so the empty-field hint
  /// does not shout at somebody who has not typed anything yet.
  bool _submitted = false;

  @override
  void dispose() {
    _code.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String code = _code.text.trim();
    setState(() => _submitted = true);
    if (code.isEmpty) {
      return;
    }
    _codeFocus.unfocus();
    // signInWithBotCode never throws: every failure lands in the auth state.
    await ref.read(authControllerProvider.notifier).signInWithBotCode(code);
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    final AuthState auth = ref.watch(authControllerProvider);
    final AppConfig config = ref.watch(appConfigProvider);
    final ThemeData theme = Theme.of(context);
    final bool busy = auth.isBusy;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Icon(
                    Icons.verified_user_outlined,
                    size: 44,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    s.loginTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _headlineFor(auth, s),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _AuthBanner(state: auth),
                  TextField(
                    controller: _code,
                    focusNode: _codeFocus,
                    enabled: !busy,
                    autocorrect: false,
                    enableSuggestions: false,
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.go,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.deny(RegExp(r'\s')),
                      LengthLimitingTextInputFormatter(128),
                    ],
                    onChanged: (String _) {
                      if (_submitted) {
                        setState(() => _submitted = false);
                      }
                    },
                    onSubmitted: (String _) => unawaited(_submit()),
                    decoration: InputDecoration(
                      labelText: s.botCodeFieldLabel,
                      hintText: config.useFakeAuth ? 'DEV-REVIEWER' : null,
                      prefixIcon: const Icon(Icons.key_outlined),
                      border: const OutlineInputBorder(),
                      helperText: s.botCodeFieldHelper,
                      helperMaxLines: 2,
                      errorText: _submitted && _code.text.trim().isEmpty
                          ? s.enterBotCode
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: busy ? null : () => unawaited(_submit()),
                    icon: busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login),
                    label: Text(busy ? s.signingIn : s.signIn),
                  ),
                  const SizedBox(height: 20),
                  _EnvironmentFooter(config: config),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _headlineFor(AuthState state, AppStrings s) => switch (state) {
        AuthInitializing() => s.loginHeadlineRestoring,
        AuthUnauthenticated() => s.loginHeadlineSignIn,
        AuthAuthenticating() => s.loginHeadlineChecking,
        AuthAuthenticated(session: final session) =>
          s.loginHeadlineSignedInAs(name: session.displayName),
        AuthExpired() => s.loginHeadlineSessionEnded,
      };
}

/// The one place the sealed [AuthState] is rendered as a message.
///
/// Nothing is invented here: an [AuthUnauthenticated.error] is handed to
/// [ErrorStateView] so the code and the correlation id stay quotable, and an
/// [AuthExpired] names the admin and the reason rather than pretending a
/// refresh is possible (admin tokens have no refresh token).
class _AuthBanner extends StatelessWidget {
  const _AuthBanner({required this.state});

  final AuthState state;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    return switch (state) {
      AuthInitializing() ||
      AuthAuthenticating() ||
      AuthAuthenticated() =>
        const SizedBox.shrink(),
      AuthUnauthenticated(:final error, :final message) =>
        _signedOut(error, message),
      // The role LABEL is passed as-is: Arabic has no letter case, so
      // lower-casing it here would only mangle the English bundle's noun.
      AuthExpired(:final previous, :final reason) => _NoticeCard(
          icon: Icons.timer_off_outlined,
          title: s.sessionEndedTitle,
          message: s.sessionEndedBody(
            name: previous.displayName,
            role: previous.role.label(s),
            reason: reason,
          ),
        ),
    };
  }

  /// The last sign-in attempt failed, or the admin signed out.
  ///
  /// A real [ApiError] goes through [ErrorStateView] so the stable code and the
  /// correlation id stay quotable; the plain-text [AuthUnauthenticated.message]
  /// is shown as-is.
  static Widget _signedOut(ApiError? error, String? message) {
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Card(
          margin: EdgeInsets.zero,
          child: ErrorStateView(error: error, compact: true),
        ),
      );
    }
    if (message == null || message.isEmpty) {
      return const SizedBox.shrink();
    }
    // No title: this same field carries both "You have signed out." and the
    // `AuthUnsupportedError` reason when the backend has no login endpoint, and
    // inventing a heading for either would misdescribe the other.
    return _NoticeCard(icon: Icons.info_outline, message: message);
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.icon,
    required this.message,
    this.title,
  });

  final IconData icon;

  /// Optional heading. Omitted when the message is the whole story.
  final String? title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? heading = title;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (heading != null) ...<Widget>[
                      Text(heading, style: theme.textTheme.titleSmall),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Which backend this build talks to, and - when the fake adapter is bound -
/// exactly which codes it accepts.
///
/// This is shown on purpose: an operator must never be in doubt about whether
/// the session they are about to create is real.
class _EnvironmentFooter extends StatelessWidget {
  const _EnvironmentFooter({required this.config});

  final AppConfig config;

  /// The codes `FakeAdminAuthApi` accepts, kept in step with its doc comment.
  static const List<String> devCodes = <String>[
    'DEV-SUPER_ADMIN',
    'DEV-FINANCE_ADMIN',
    'DEV-REVIEWER',
    'DEV-SUPPORT',
    'DEV-VIEWER',
  ];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppStrings s = context.s;
    final TextStyle? caption = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    if (!config.useFakeAuth) {
      return Text(
        s.envFooter(
          env: config.environment.wireName,
          baseUrl: config.baseUrl,
        ),
        textAlign: TextAlign.center,
        style: caption,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          s.fakeAuthBanner(
            env: config.environment.wireName,
            baseUrl: config.baseUrl,
          ),
          textAlign: TextAlign.center,
          style: caption,
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: <Widget>[
            for (final String code in devCodes)
              _DevCodeChip(code: code, label: code),
            _DevCodeChip(
              code: 'DEV-REVIEWER:SHORT',
              label: s.devCodeShortLabel,
            ),
            _DevCodeChip(code: 'DEV-DENY', label: s.devCodeDenyLabel),
          ],
        ),
      ],
    );
  }
}

/// Tapping a chip copies the code, so a dev code never has to be typed by hand
/// on a handset keyboard.
class _DevCodeChip extends StatelessWidget {
  const _DevCodeChip({required this.code, required this.label});

  final String code;
  final String label;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;
    return ActionChip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      onPressed: () async {
        await Clipboard.setData(ClipboardData(text: code));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s.copiedCode(code: code))),
          );
        }
      },
    );
  }
}
