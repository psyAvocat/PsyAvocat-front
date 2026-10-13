import 'package:flutter/material.dart';
import '../../../core/theme/app_universe.dart';
import '../../../core/widgets/navigation/psyavocat_navigation_bar.dart';
import '../../../core/l10n/app_strings.dart';

/// Onglets de la barre de navigation selon l'univers.
///
/// L'ordre correspond aux branches du `StatefulShellRoute` (app_router.dart) :
/// 0 Accueil · 1 Articles/Conseils · 2 Avocats/Psychologues · 3 Rendez-vous · 4 Profil.
/// La structure est commune ; seuls le contenu et les libellés changent.
List<NavDestination> navigationDestinationsFor(AppUniverse universe) {
  final isPsychologist = universe.isPsychologist;

  return [
    NavDestination(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: tr('Accueil'),
    ),
    isPsychologist
        ? NavDestination(
            icon: Icons.lightbulb_outline_rounded,
            selectedIcon: Icons.lightbulb_rounded,
            label: tr('Conseils'),
          )
        : NavDestination(
            icon: Icons.menu_book_outlined,
            selectedIcon: Icons.menu_book_rounded,
            label: tr('Articles'),
          ),
    isPsychologist
        ? NavDestination(
            icon: Icons.psychology_rounded,
            selectedIcon: Icons.psychology_rounded,
            label: tr('Psychologues'),
            isCentral: true,
          )
        : NavDestination(
            icon: Icons.gavel_rounded,
            selectedIcon: Icons.gavel_rounded,
            label: tr('Avocats'),
            isCentral: true,
          ),
    NavDestination(
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month_rounded,
      label: tr('Rendez-vous'),
    ),
    NavDestination(
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      label: tr('Profil'),
    ),
  ];
}
