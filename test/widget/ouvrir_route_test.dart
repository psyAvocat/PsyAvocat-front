import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:psyavocat_front/core/navigation/ouvrir_route.dart';
import 'package:psyavocat_front/core/router/app_routes.dart';

/// Clic sur une notification depuis la page Notifications (au-dessus de la
/// navigation principale) : la destination peut être un onglet ou une page.
void main() {
  GoRouter routeur() => GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => Scaffold(body: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (_, _) => const Text('ACCUEIL'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.rendezVous,
                builder: (_, _) => const Text('MES RENDEZ-VOUS'),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, _) => Scaffold(
          body: Column(
            children: [
              TextButton(
                onPressed: () => ouvrirRoute(context, AppRoutes.rendezVous),
                child: const Text('notif rdv'),
              ),
              TextButton(
                onPressed: () => ouvrirRoute(context, AppRoutes.dossier('d1')),
                child: const Text('notif dossier'),
              ),
            ],
          ),
        ),
      ),
      GoRoute(
        path: '/dossiers/:id',
        builder: (_, state) => Text('DOSSIER ${state.pathParameters['id']}'),
      ),
    ],
  );

  testWidgets('notification de rendez-vous : l’onglet s’ouvre sans exception', (
    tester,
  ) async {
    final router = routeur();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.push(AppRoutes.notifications);
    await tester.pumpAndSettle();

    await tester.tap(find.text('notif rdv'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('MES RENDEZ-VOUS'), findsOneWidget);
  });

  testWidgets(
    'notification de dossier : la page est empilée (retour possible)',
    (tester) async {
      final router = routeur();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      router.push(AppRoutes.notifications);
      await tester.pumpAndSettle();

      await tester.tap(find.text('notif dossier'));
      await tester.pumpAndSettle();
      expect(find.text('DOSSIER d1'), findsOneWidget);

      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('notif dossier'), findsOneWidget);
    },
  );
}
