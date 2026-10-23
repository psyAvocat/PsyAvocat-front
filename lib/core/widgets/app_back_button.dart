import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_strings.dart';
import '../router/app_routes.dart';

/// Retour standard de l'application : page précédente s'il y en a une, sinon
/// accueil de l'univers courant (jamais d'écran bloqué ni de fermeture de l'app).
void retourOuAccueil(BuildContext context) {
  if (GoRouter.of(context).canPop()) {
    context.pop();
  } else {
    context.go(AppRoutes.home);
  }
}

/// Bouton retour Android sur la dernière page de la pile : destination à ouvrir,
/// ou `null` pour le comportement normal (page/dialogue fermé, ou sortie de l'app
/// depuis l'accueil et les écrans d'entrée).
String? destinationRetourSysteme({
  required String chemin,
  required bool peutRevenir,
}) {
  if (peutRevenir) return null;
  if (chemin == AppRoutes.home ||
      chemin == AppRoutes.universeSelection ||
      AppRoutes.entryRoutes.contains(chemin)) {
    return null;
  }
  return AppRoutes.home;
}

/// Bouton retour unique de l'application (même icône et même taille partout).
///
/// Exemple : `AppBar(leading: const AppBackButton(), title: Text(tr('Paiements')))`
class AppBackButton extends StatelessWidget {
  /// Couleur de l'icône (par défaut : celle de la barre d'en-tête).
  final Color? color;

  /// Action propre à l'écran (ex. confirmation avant de quitter un formulaire).
  final VoidCallback? onPressed;

  const AppBackButton({super.key, this.color, this.onPressed});

  /// Icône commune, reprise par les boutons retour automatiques du thème.
  static const icon = Icons.arrow_back_ios_new_rounded;
  static const iconSize = 20.0;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tr('Retour'),
      icon: Icon(icon, size: iconSize, color: color),
      onPressed: onPressed ?? () => retourOuAccueil(context),
    );
  }
}
