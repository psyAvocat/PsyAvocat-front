import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:psyavocat_front/core/theme/app_theme.dart';
import 'package:psyavocat_front/core/widgets/app_back_button.dart';

/// Onglets comme l'application (un navigateur par onglet) : l'onglet B a une
/// sous-page « recherche » qui ouvre une fiche plein écran (au-dessus des onglets).
GoRouter _routeur() => GoRouter(
  initialLocation: '/b',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => shell,
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/a',
              builder: (_, _) => const Scaffold(body: Text('ACCUEIL')),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/b',
              builder: (_, _) => const Scaffold(body: Text('LISTE')),
              routes: [
                GoRoute(
                  path: 'recherche',
                  builder: (context, _) => Scaffold(
                    body: Center(
                      child: TextButton(
                        onPressed: () => context.push('/fiche'),
                        child: const Text('RECHERCHE'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/fiche',
      builder: (_, _) => const Scaffold(body: Text('FICHE')),
    ),
  ],
);

/// Geste de retour Android (retour « prédictif ») : début, glissement, validation.
Future<void> _gesteRetour(WidgetTester tester) async {
  Future<void> envoyer(MethodCall appel) =>
      tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/backgesture',
        const StandardMethodCodec().encodeMethodCall(appel),
        (_) {},
      );
  await envoyer(
    const MethodCall('startBackGesture', <String, dynamic>{
      'touchOffset': <double>[5.0, 300.0],
      'progress': 0.0,
      'swipeEdge': 0,
    }),
  );
  await tester.pump();
  await envoyer(
    const MethodCall('updateBackGestureProgress', <String, dynamic>{
      'touchOffset': <double>[100.0, 300.0],
      'progress': 0.4,
      'swipeEdge': 0,
    }),
  );
  await tester.pump();
  await envoyer(const MethodCall('commitBackGesture'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'geste de retour depuis une fiche : seule la fiche se ferme, l’app reste utilisable',
    (tester) async {
      final routeur = _routeur();
      await tester.pumpWidget(
        MaterialApp.router(
          theme: ThemeData(pageTransitionsTheme: AppTheme.pageTransitions),
          routerConfig: routeur,
        ),
      );
      routeur.go('/b/recherche');
      await tester.pumpAndSettle();
      await tester.tap(find.text('RECHERCHE'));
      await tester.pumpAndSettle();
      expect(find.text('FICHE'), findsOneWidget);

      await _gesteRetour(tester);

      // Avant correction, la page de l'onglet se fermait aussi (retour à LISTE).
      expect(find.text('FICHE'), findsNothing);
      expect(find.text('RECHERCHE'), findsOneWidget);
      expect(
        tester
            .stateList<NavigatorState>(
              find.byType(Navigator, skipOffstage: false),
            )
            .where((n) => n.userGestureInProgress),
        isEmpty,
      );
      // Pas de blocage : les appuis fonctionnent toujours.
      await tester.tap(find.text('RECHERCHE'));
      await tester.pumpAndSettle();
      expect(find.text('FICHE'), findsOneWidget);
    },
    variant: const TargetPlatformVariant({TargetPlatform.android}),
  );

  testWidgets(
    'Android : l’application garde la main sur le retour, même sans page à dépiler',
    (tester) async {
      final appels = <bool>[];
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (appel) async {
          if (appel.method == 'SystemNavigator.setFrameworkHandlesBack') {
            appels.add(appel.arguments as bool);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final routeur = GoRouter(
        initialLocation: '/profil',
        routes: [
          GoRoute(
            path: '/profil',
            builder: (_, _) => const Scaffold(body: Text('PROFIL')),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: routeur,
          onNavigationNotification: garderLaMainSurLeRetour,
        ),
      );
      await tester.pumpAndSettle();

      // Sans cela, Android fermerait l'app au lieu de revenir à l'accueil.
      expect(appels, isNotEmpty);
      expect(appels, everyElement(isTrue));
    },
    variant: const TargetPlatformVariant({TargetPlatform.android}),
  );
}
