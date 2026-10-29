import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../router/app_routes.dart';

/// Ouvre une destination interne (lien de notification, raccourci…).
///
/// Les pages racines des onglets sont rejointes avec `go` : les empiler avec
/// `push` recréerait la navigation principale par-dessus elle-même (clés de
/// navigation en double → exception). Les autres pages sont empilées avec
/// `push`, pour que le retour ramène à la page de départ.
void ouvrirRoute(BuildContext context, String route) {
  final chemin = Uri.tryParse(route)?.path ?? route;
  if (AppRoutes.ongletsPrincipaux.contains(chemin)) {
    context.go(route);
  } else {
    context.push(route);
  }
}
