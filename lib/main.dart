import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/auth/admin_auth_api.dart';
import 'package:manager_bot/core/auth/auth_controller.dart';
import 'package:manager_bot/core/config/app_config.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/locale_controller.dart';
import 'package:manager_bot/core/logging/app_logger.dart';
import 'package:manager_bot/core/theme/neon_theme.dart';
import 'package:manager_bot/router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The language is restored BEFORE the first frame. Doing it inside a provider
  // would paint one Arabic frame at an English operator (or the reverse) and
  // then flip; doing it here means the very first pixel is already correct.
  final Locale locale = await bootstrapLocale();
  runApp(
    ProviderScope(
      overrides: <Override>[initialLocaleProvider.overrideWithValue(locale)],
      child: const ManagerBotApp(),
    ),
  );
}

/// Root widget: locale, theme, router, and the startup banner.
class ManagerBotApp extends ConsumerStatefulWidget {
  const ManagerBotApp({super.key});

  @override
  ConsumerState<ManagerBotApp> createState() => _ManagerBotAppState();
}

class _ManagerBotAppState extends ConsumerState<ManagerBotApp> {
  @override
  void initState() {
    super.initState();
    // Reading the adapter here is what logs which one was bound, exactly like
    // the backend announcing its Ichancy fake at boot. Do not remove: the one
    // thing nobody may be unsure about is whether auth is real.
    final config = ref.read(appConfigProvider);
    final AdminAuthApi authApi = ref.read(adminAuthApiProvider);
    AppLogger.info('manager_bot starting - ${config.describe()}', scope: 'startup');
    AppLogger.info(
      'startup: authAdapter=${authApi.adapterName} isFake=${authApi.isFake} '
      'env=${config.environment.wireName}',
      scope: 'startup',
    );
    AppLogger.info(
      'startup: locale=${AppLocales.tagOf(ref.read(localeControllerProvider))}',
      scope: 'startup',
    );
    if (authApi.isFake && config.isProd) {
      // Belt and braces: AppConfig already forces useFakeAuth off in prod.
      AppLogger.error(
        'FATAL CONFIGURATION: fake auth is bound in a prod build.',
        scope: 'startup',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);
    // Watching the controller is what makes the whole tree - including the
    // Directionality that GlobalWidgetsLocalizations installs - follow the
    // Settings language toggle.
    final Locale locale = ref.watch(localeControllerProvider);
    return MaterialApp.router(
      // Resolved against the app's own Localizations, so the OS task switcher
      // shows the title in the language the operator picked.
      onGenerateTitle: (BuildContext context) => context.s.appTitle,
      debugShowCheckedModeBanner: false,
      // Both slots get the SAME theme on purpose. The player app is a
      // near-black canvas with neon accents by definition; a half-hearted light
      // variant would be a second palette to keep contrast-correct and would
      // make the balance hero unreadable. Pinning `themeMode` as well means a
      // phone in light mode still gets the design that was actually designed.
      theme: NeonTheme.dark(),
      darkTheme: NeonTheme.dark(),
      themeMode: ThemeMode.dark,
      locale: locale,
      supportedLocales: AppLocales.supported,
      localizationsDelegates: AppLocalizationsDelegates.all,
      routerConfig: router,
    );
  }
}
