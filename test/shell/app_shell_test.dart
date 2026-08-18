import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/i18n/locale_controller.dart';
import 'package:manager_bot/core/theme/neon_theme.dart';
import 'package:manager_bot/core/ui/dimens.dart';
import 'package:manager_bot/features/shell/presentation/app_shell.dart';
import 'package:manager_bot/features/shell/presentation/widgets/neon_nav_bar.dart';

/// The bar is the most-seen component in the app, so it is pumped for real.
///
/// The four destinations are replaced with long, identifiable lists: the real
/// screens hit their demo repositories and this file is about the SHELL - that
/// the five slots render, that Arabic puts الرئيسية on the right, that the
/// raised centre action is a callback rather than a branch, and that switching
/// tabs keeps each list exactly where the player left it.
void main() {
  const List<String> paths = <String>['/', '/activity', '/methods', '/account'];

  /// A stand-in router with the same shape as the real one.
  GoRouter buildRouter(void Function() onCentre) => GoRouter(
        initialLocation: paths.first,
        routes: <RouteBase>[
          StatefulShellRoute.indexedStack(
            builder: (
              BuildContext context,
              GoRouterState state,
              StatefulNavigationShell shell,
            ) =>
                AppShell(navigationShell: shell, onOpenTopUp: onCentre),
            branches: <StatefulShellBranch>[
              for (final String path in paths)
                StatefulShellBranch(
                  routes: <RouteBase>[
                    GoRoute(
                      path: path,
                      builder: (BuildContext context, GoRouterState state) =>
                          ListView.builder(
                        itemCount: 60,
                        itemBuilder: (BuildContext context, int index) =>
                            SizedBox(
                          height: 48,
                          child: Text('$path row $index'),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      );

  Widget host(GoRouter router, Locale locale) => MaterialApp.router(
        theme: NeonTheme.dark(),
        locale: locale,
        supportedLocales: AppLocales.supported,
        localizationsDelegates: AppLocalizationsDelegates.all,
        routerConfig: router,
      );

  for (final Locale locale in AppLocales.supported) {
    final AppStrings s =
        locale == AppLocales.english ? AppStrings.en : AppStrings.ar;

    testWidgets('all five slots render in ${locale.languageCode}',
        (WidgetTester tester) async {
      await tester.pumpWidget(host(buildRouter(() {}), locale));
      await tester.pumpAndSettle();

      expect(find.text(s.navHome), findsOneWidget);
      expect(find.text(s.navActivity), findsOneWidget);
      expect(find.text(s.navTopUp), findsOneWidget);
      expect(find.text(s.navMethods), findsOneWidget);
      expect(find.text(s.navProfile), findsOneWidget);
      expect(find.text('/ row 0'), findsOneWidget);
    });

    testWidgets('tapping a destination switches branch in '
        '${locale.languageCode}', (WidgetTester tester) async {
      await tester.pumpWidget(host(buildRouter(() {}), locale));
      await tester.pumpAndSettle();

      await tester.tap(find.text(s.navMethods));
      await tester.pumpAndSettle();
      expect(find.text('/methods row 0'), findsOneWidget);

      await tester.tap(find.text(s.navProfile));
      await tester.pumpAndSettle();
      expect(find.text('/account row 0'), findsOneWidget);
    });
  }

  testWidgets('the centre action is a flow, not a branch',
      (WidgetTester tester) async {
    int taps = 0;
    await tester.pumpWidget(
      host(buildRouter(() => taps++), AppLocales.arabic),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.ar.navTopUp));
    await tester.pumpAndSettle();

    expect(taps, 1);
    // Still on الرئيسية: the centre never changes the selected destination.
    expect(find.text('/ row 0'), findsOneWidget);
  });

  testWidgets('the centre action breaks the plane of the bar',
      (WidgetTester tester) async {
    await tester.pumpWidget(host(buildRouter(() {}), AppLocales.arabic));
    await tester.pumpAndSettle();

    final Rect centre = tester.getRect(find.byIcon(Icons.add_rounded));
    final Rect homeIcon = tester.getRect(find.byIcon(Icons.home_rounded));

    expect(
      centre.top,
      lessThan(homeIcon.top),
      reason: 'the raised action must rise above the normal destinations',
    );
    final double viewportWidth =
        tester.view.physicalSize.width / tester.view.devicePixelRatio;
    expect(
      (centre.center.dx - viewportWidth / 2).abs(),
      lessThan(1),
      reason: 'it owns the middle slot, so it is centred in the viewport',
    );
  });

  testWidgets('Arabic puts the first destination on the RIGHT',
      (WidgetTester tester) async {
    await tester.pumpWidget(host(buildRouter(() {}), AppLocales.arabic));
    await tester.pumpAndSettle();

    final double home = tester.getCenter(find.text(AppStrings.ar.navHome)).dx;
    final double activity =
        tester.getCenter(find.text(AppStrings.ar.navActivity)).dx;
    final double methods =
        tester.getCenter(find.text(AppStrings.ar.navMethods)).dx;
    final double profile =
        tester.getCenter(find.text(AppStrings.ar.navProfile)).dx;

    expect(home, greaterThan(activity));
    expect(activity, greaterThan(methods));
    expect(methods, greaterThan(profile));
  });

  testWidgets('English puts the first destination on the LEFT',
      (WidgetTester tester) async {
    await tester.pumpWidget(host(buildRouter(() {}), AppLocales.english));
    await tester.pumpAndSettle();

    final double home = tester.getCenter(find.text(AppStrings.en.navHome)).dx;
    final double profile =
        tester.getCenter(find.text(AppStrings.en.navProfile)).dx;

    expect(home, lessThan(profile));
  });

  testWidgets('each tab keeps its scroll position across a switch',
      (WidgetTester tester) async {
    await tester.pumpWidget(host(buildRouter(() {}), AppLocales.arabic));
    await tester.pumpAndSettle();

    await tester.drag(find.text('/ row 1'), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('/ row 0'), findsNothing);

    await tester.tap(find.text(AppStrings.ar.navMethods));
    await tester.pumpAndSettle();
    expect(find.text('/methods row 0'), findsOneWidget);

    await tester.tap(find.text(AppStrings.ar.navHome));
    await tester.pumpAndSettle();
    expect(
      find.text('/ row 0'),
      findsNothing,
      reason: 'the IndexedStack must not have rebuilt the home list',
    );
  });

  testWidgets('re-tapping the selected destination is harmless',
      (WidgetTester tester) async {
    await tester.pumpWidget(host(buildRouter(() {}), AppLocales.arabic));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.ar.navHome));
    await tester.pumpAndSettle();

    expect(find.text('/ row 0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the bar survives a 320dp phone without overflowing',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(960, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host(buildRouter(() {}), AppLocales.arabic));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.ar.navMethods), findsOneWidget);
  });

  testWidgets('the bar is exactly as tall as it advertises',
      (WidgetTester tester) async {
    await tester.pumpWidget(host(buildRouter(() {}), AppLocales.arabic));
    await tester.pumpAndSettle();

    final Size bar = tester.getSize(find.byType(NeonNavBar));
    expect(bar.height, NeonNavBar.contentHeight);
    expect(
      bar.height,
      lessThan(AppSpacing.navClearance),
      reason: 'screens pad their scroll bodies by navClearance to clear it',
    );
  });
}
