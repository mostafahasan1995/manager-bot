import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/auth/auth_controller.dart';
import 'package:manager_bot/core/config/app_config.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';

/// Shown only while the keystore is being read at launch.
///
/// It exists so the app never flashes the login screen at an admin who is in
/// fact still signed in. The router redirects away as soon as auth resolves.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watching the controller is what starts it, and therefore what starts the
    // session restore.
    final auth = ref.watch(authControllerProvider);
    final config = ref.watch(appConfigProvider);
    final theme = Theme.of(context);
    final AppStrings s = context.s;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.verified_user_outlined,
              size: 44,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(s.appTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 24),
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            if (config.isDev) ...<Widget>[
              const SizedBox(height: 24),
              Text(
                // Dev-only diagnostics: the env line goes through the
                // catalogue, the AuthState class name stays a Dart symbol.
                '${s.envFooter(env: config.environment.wireName, baseUrl: config.baseUrl)}\n'
                '${auth.runtimeType}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
