import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:psyavocat_front/core/router/app_routes.dart';
import 'package:psyavocat_front/core/widgets/app_back_button.dart';

/// Routeur réduit : accueil, liste des professionnels et fiche d'un professionnel.
GoRouter _routeur(String depart) => GoRouter(
  initialLocation: depart,
  routes: [
    GoRoute(
      path: AppRoutes.home,
      builder: (_, _) => const Scaffold(body: Text('ACCUEIL')),
    ),
    GoRoute(
      path: AppRoutes.professionnels,
      builder: (context, _) => Scaffold(
        body: TextButton(
          onPressed: () => context.push(AppRoutes.professionnel('p1')),
          child: const Text('LISTE'),
        ),
      ),
    ),
    GoRoute(
      path: '${AppRoutes.professionnels}/:id',
      builder: (_, _) => Scaffold(
        appBar: AppBar(leading: const AppBackButton()),
        body: const Text('FICHE'),
      ),
    ),
  ],
);

void main() {
  group('Retour Android sur la dernière page', () {
    test('accueil et écrans d’entrée : comportement normal (sortie)', () {
      for (final chemin in [
        AppRoutes.home,
        AppRoutes.login,
        AppRoutes.splash,
      ]) {
        expect(
          destinationRetourSysteme(chemin: chemin, peutRevenir: false),
          isNull,
          reason: chemin,
        );
      }
    });

    test('autre page sans page précédente : retour à l’accueil', () {
      expect(
        destinationRetourSysteme(
          chemin: AppRoutes.professionnel('p1'),
          peutRevenir: false,
        ),
        AppRoutes.home,
      );
      expect(
        destinationRetourSysteme(
          chemin: AppRoutes.rendezVous,
          peutRevenir: false,
        ),
        AppRoutes.home,
      );
    });

    test('page précédente disponible : retour normal', () {
      expect(
        destinationRetourSysteme(
          chemin: AppRoutes.professionnel('p1'),
          peutRevenir: true,
        ),
        isNull,
      );
    });
  });

  group('AppBackButton', () {
    testWidgets(
      'fiche ouverte directement (notification) : retour à l’accueil',
      (tester) async {
        final routeur = _routeur(AppRoutes.professionnel('p1'));
        await tester.pumpWidget(MaterialApp.router(routerConfig: routeur));
        await tester.pumpAndSettle();
        expect(find.text('FICHE'), findsOneWidget);

        await tester.tap(find.byType(AppBackButton));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('ACCUEIL'), findsOneWidget);
      },
    );

    testWidgets('fiche ouverte depuis la liste : retour à la liste', (
      tester,
    ) async {
      final routeur = _routeur(AppRoutes.professionnels);
      await tester.pumpWidget(MaterialApp.router(routerConfig: routeur));
      await tester.pumpAndSettle();
      await tester.tap(find.text('LISTE'));
      await tester.pumpAndSettle();
      expect(find.text('FICHE'), findsOneWidget);

      await tester.tap(find.byType(AppBackButton));
      await tester.pumpAndSettle();

      expect(find.text('LISTE'), findsOneWidget);
    });
  });
}
