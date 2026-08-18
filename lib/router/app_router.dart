import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manager_bot/core/config/app_config.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/ui/ui.dart';
// -----------------------------------------------------------------------------
// STAFF ADMIN CONSOLE screens. Still registered, still reachable by path, no
// longer the entry point. Untouched by this phase.
// -----------------------------------------------------------------------------
import 'package:manager_bot/features/admin_users/presentation/admin_profile_view.dart';
import 'package:manager_bot/features/admin_users/presentation/admin_users_screen.dart';
import 'package:manager_bot/features/auth/presentation/login_screen.dart';
import 'package:manager_bot/features/deposits/presentation/deposit_detail_screen.dart';
import 'package:manager_bot/features/deposits/presentation/deposit_queue_screen.dart';
import 'package:manager_bot/features/home/presentation/self_approval_limits_screen.dart';
import 'package:manager_bot/features/home/presentation/settings_screen.dart';
import 'package:manager_bot/features/money/presentation/money_screen.dart';
import 'package:manager_bot/features/payment_methods/presentation/payment_methods_screen.dart';
import 'package:manager_bot/features/reconciliation/presentation/reconciliation_screen.dart';
// -----------------------------------------------------------------------------
// PLAYER APP screens - the five destinations of the shell. Each file exports
// exactly the class named below and owns no navigation of its own: every way
// out is a callback wired here, so the router stays the single place that knows
// where a tap goes.
// -----------------------------------------------------------------------------
import 'package:manager_bot/features/shell/activity/presentation/activity_screen.dart';
import 'package:manager_bot/features/shell/home/presentation/home_screen.dart';
import 'package:manager_bot/features/shell/methods/presentation/methods_screen.dart';
import 'package:manager_bot/features/shell/presentation/app_shell.dart';
import 'package:manager_bot/features/shell/profile/presentation/profile_screen.dart';
import 'package:manager_bot/features/shell/topup/topup.dart';
import 'package:manager_bot/router/admin_console_shell.dart';
import 'package:manager_bot/router/splash_screen.dart';

/// Route names and paths. Navigate BY NAME so a path change never breaks a
/// screen:
///
/// ```dart
/// context.goNamed(AppRoute.activity);
/// context.pushNamed(AppRoute.topUp);
/// ```
///
/// SHAPE - the player app is the app; the console is a wing of it:
///
/// ```text
/// PLAYER (the entry point, NO login gate)
/// shell -+- /              الرئيسية   home + balance          branch 0
///        +- /activity      إيداعاتي   deposits / activity     branch 1
///        +- /methods       طرق الدفع  payment methods         branch 2
///        +- /account       حسابي      profile + settings      branch 3
/// /top-up                  [ + شحن ]  RAISED CENTRE ACTION - pushed full
///                                     height onto the ROOT navigator, so the
///                                     bar goes away and Back returns to the
///                                     tab the player came from.
///
/// STAFF ADMIN CONSOLE (registered, reachable by path, not linked from the bar)
/// /splash                  boot screen for the keystore read
/// /login                   bot-code sign in
/// shell -+- /deposits      the review queue
///        |    /deposits/:shortId
///        +- /money
///             /money/reconciliation
/// /settings
///   /settings/profile
///   /settings/payment-methods
///   /settings/admin-users
///   /settings/approval-limits
/// ```
///
/// There is NO redirect anywhere in this router. The owner asked for the entry
/// code to be taken out of the way, so the app opens straight onto الرئيسية and
/// every console route stays addressable; the screens behind them show their
/// own signed-out state rather than being bounced to a login they cannot pass.
/// `core/auth` is untouched and still bound - it is simply not in the way.
abstract final class AppRoute {
  // ---------------------------------------------------------------------------
  // PLAYER APP
  // ---------------------------------------------------------------------------

  /// الرئيسية - the landing screen and the app's entry point.
  static const String home = 'home';
  static const String homePath = '/';

  /// إيداعاتي - the player's own top-up history.
  static const String activity = 'activity';
  static const String activityPath = '/activity';

  /// طرق الدفع - the rails a player can pay over.
  static const String methods = 'methods';
  static const String methodsPath = '/methods';

  /// حسابي. Named `account`, not `profile`: the console already owns
  /// `profile` at `/settings/profile` and route names must stay unique.
  static const String account = 'account';
  static const String accountPath = '/account';

  /// شحن - the raised centre action's flow. A push, not a tab.
  static const String topUp = 'topUp';
  static const String topUpPath = '/top-up';

  /// The shell's branch paths, in branch order. `AppShell.tabs` carries the
  /// same order and the router test asserts the two never drift apart.
  static const List<String> shellBranchPaths = <String>[
    homePath,
    activityPath,
    methodsPath,
    accountPath,
  ];

  // ---------------------------------------------------------------------------
  // STAFF ADMIN CONSOLE
  // ---------------------------------------------------------------------------

  /// Boot screen shown while the keystore is read. Never linked to directly.
  static const String splash = 'splash';
  static const String splashPath = '/splash';

  static const String login = 'login';
  static const String loginPath = '/login';

  static const String depositQueue = 'depositQueue';
  static const String depositQueuePath = '/deposits';

  /// Path parameter carrying the human-facing deposit reference.
  /// The backend normalises it server-side (uppercases, O->0, I/L->1, strips
  /// separators), so `k7q2-zp9v3m` is accepted as-is.
  static const String shortIdParam = 'shortId';
  static const String depositDetail = 'depositDetail';
  static const String depositDetailPath = '/deposits/:$shortIdParam';

  /// Console tab 2: float, breaks and the activity report on ONE screen.
  static const String money = 'money';
  static const String moneyPath = '/money';

  /// The four-panel reconciliation workbench, a push off the Money tab.
  static const String reconciliation = 'reconciliation';
  static const String reconciliationPath = '/money/reconciliation';

  static const String settings = 'settings';
  static const String settingsPath = '/settings';

  /// Who am I / what can this role do / what is this build pointed at.
  static const String profile = 'profile';
  static const String profilePath = '/settings/profile';

  /// Rare configuration, reached from Settings.
  static const String paymentMethods = 'paymentMethods';
  static const String paymentMethodsPath = '/settings/payment-methods';

  static const String adminUsers = 'adminUsers';
  static const String adminUsersPath = '/settings/admin-users';

  /// The signed-in administrator's own approval ceilings. Another admin's
  /// ceilings are still reached through the directory.
  static const String approvalLimits = 'approvalLimits';
  static const String approvalLimitsPath = '/settings/approval-limits';

  /// Builds the location of a deposit detail without hard-coding the path.
  static String depositDetailLocation(String shortId) =>
      '$depositQueuePath/${Uri.encodeComponent(shortId)}';
}

final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

/// The app router.
final Provider<GoRouter> goRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoute.homePath,
    debugLogDiagnostics: ref.watch(appConfigProvider).isDev,
    routes: <RouteBase>[
      // -----------------------------------------------------------------------
      // THE PLAYER SHELL. `indexedStack` is what preserves each tab's scroll
      // position, filter state and in-flight requests across a tab switch, and
      // each branch is a real navigator so a detail pushed inside a tab
      // survives a round trip through the others.
      // -----------------------------------------------------------------------
      StatefulShellRoute.indexedStack(
        builder: (
          BuildContext context,
          GoRouterState state,
          StatefulNavigationShell navigationShell,
        ) =>
            AppShell(
          navigationShell: navigationShell,
          onOpenTopUp: () => _openTopUp(context),
        ),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                name: AppRoute.home,
                path: AppRoute.homePath,
                builder: (BuildContext context, GoRouterState state) =>
                    HomeScreen(
                  onStartTopUp: () => _openTopUp(context),
                  onOpenDeposits: () => context.goNamed(AppRoute.activity),
                  onOpenPaymentMethods: () => context.goNamed(AppRoute.methods),
                  // Support and account linking both live in the bot; حسابي is
                  // where their links are, so that is where the player goes.
                  onOpenSupport: () => context.goNamed(AppRoute.account),
                  onOpenProfile: () => context.goNamed(AppRoute.account),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                name: AppRoute.activity,
                path: AppRoute.activityPath,
                builder: (BuildContext context, GoRouterState state) =>
                    ActivityScreen(onStartTopUp: () => _openTopUp(context)),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                name: AppRoute.methods,
                path: AppRoute.methodsPath,
                builder: (BuildContext context, GoRouterState state) =>
                    MethodsScreen(onStartTopUp: () => _openTopUp(context)),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                name: AppRoute.account,
                path: AppRoute.accountPath,
                builder: (BuildContext context, GoRouterState state) =>
                    const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      // -----------------------------------------------------------------------
      // THE RAISED CENTRE ACTION's flow. On the ROOT navigator, so it covers
      // the nav bar; `TopUpScreen` therefore needs no `bottomInset`, and its
      // own close button pops this route.
      // -----------------------------------------------------------------------
      GoRoute(
        name: AppRoute.topUp,
        path: AppRoute.topUpPath,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            CustomTransitionPage<void>(
          key: state.pageKey,
          fullscreenDialog: true,
          transitionDuration: AppMotion.slow,
          reverseTransitionDuration: AppMotion.medium,
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) =>
              SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: AppMotion.emphasized,
                reverseCurve: AppMotion.exit,
              ),
            ),
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: const TopUpScreen(),
        ),
      ),
      // -----------------------------------------------------------------------
      // STAFF ADMIN CONSOLE. Kept whole, kept addressable, kept out of the bar.
      // -----------------------------------------------------------------------
      GoRoute(
        name: AppRoute.splash,
        path: AppRoute.splashPath,
        builder: (BuildContext context, GoRouterState state) =>
            const SplashScreen(),
      ),
      GoRoute(
        name: AppRoute.login,
        path: AppRoute.loginPath,
        builder: (BuildContext context, GoRouterState state) =>
            const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (
          BuildContext context,
          GoRouterState state,
          StatefulNavigationShell navigationShell,
        ) =>
            AdminConsoleShell(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                name: AppRoute.depositQueue,
                path: AppRoute.depositQueuePath,
                builder: (BuildContext context, GoRouterState state) =>
                    const DepositQueueScreen(),
                routes: <RouteBase>[
                  GoRoute(
                    name: AppRoute.depositDetail,
                    path: ':${AppRoute.shortIdParam}',
                    builder: (BuildContext context, GoRouterState state) =>
                        DepositDetailScreen(
                      shortId: state.pathParameters[AppRoute.shortIdParam] ?? '',
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                name: AppRoute.money,
                path: AppRoute.moneyPath,
                builder: (BuildContext context, GoRouterState state) =>
                    const MoneyScreen(),
                routes: <RouteBase>[
                  GoRoute(
                    name: AppRoute.reconciliation,
                    path: 'reconciliation',
                    builder: (BuildContext context, GoRouterState state) =>
                        const ReconciliationScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        name: AppRoute.settings,
        path: AppRoute.settingsPath,
        builder: (BuildContext context, GoRouterState state) =>
            const SettingsScreen(),
        routes: <RouteBase>[
          GoRoute(
            name: AppRoute.profile,
            path: 'profile',
            builder: (BuildContext context, GoRouterState state) =>
                const AdminProfileView(),
          ),
          GoRoute(
            name: AppRoute.paymentMethods,
            path: 'payment-methods',
            builder: (BuildContext context, GoRouterState state) =>
                const PaymentMethodsScreen(),
          ),
          GoRoute(
            name: AppRoute.adminUsers,
            path: 'admin-users',
            builder: (BuildContext context, GoRouterState state) =>
                const AdminUsersScreen(),
          ),
          GoRoute(
            name: AppRoute.approvalLimits,
            path: 'approval-limits',
            builder: (BuildContext context, GoRouterState state) =>
                const SelfApprovalLimitsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (BuildContext context, GoRouterState state) {
      final AppStrings s = context.s;
      return Scaffold(
        backgroundColor: AppPalette.canvas,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
              child: ErrorState(
                title: s.errorTitleNotFound,
                message: s.errorRecordNotFound,
                icon: Icons.explore_off_rounded,
                details: state.uri.toString(),
                retryLabel: s.navHome,
                onRetry: () => context.goNamed(AppRoute.home),
              ),
            ),
          ),
        ),
      );
    },
  );

  ref.onDispose(router.dispose);
  return router;
});

/// Pushes the شحن flow onto the root navigator.
///
/// A push and not a `go`, so the player's tab, its scroll offset and anything
/// they had pushed inside it are all still there when the sheet closes.
void _openTopUp(BuildContext context) {
  // The route completes with nothing: the draft lives in `topUpDraftProvider`,
  // not in a pop result.
  unawaited(context.pushNamed<void>(AppRoute.topUp));
}
