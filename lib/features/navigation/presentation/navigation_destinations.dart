import 'package:flutter/material.dart';
import '../../../core/theme/app_universe.dart';
import '../../../core/widgets/navigation/psyavocat_navigation_bar.dart';

/// Onglets de la barre de navigation selon l'univers.
///
/// L'ordre correspond aux branches du `StatefulShellRoute` (app_router.dart) :
/// 0 Accueil · 1 Articles/Conseils · 2 Avocats/Psychologues · 3 Rendez-vous · 4 Profil.
/// La structure est commune ; seuls le contenu et les libellés changent.
List<NavDestination> navigationDestinationsFor(AppUniverse universe) {
  final isPsychologist = universe.isPsychologist;

  return [
    const NavDestination(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Accueil',
    ),
    isPsychologist
        ? const NavDestination(
            icon: Icons.lightbulb_outline_rounded,
            selectedIcon: Icons.lightbulb_rounded,
            label: 'Conseils',
          )
        : const NavDestination(
            icon: Icons.menu_book_outlined,
            selectedIcon: Icons.menu_book_rounded,
            label: 'Articles',
          ),
    isPsychologist
        ? const NavDestination(
            icon: Icons.psychology_rounded,
            selectedIcon: Icons.psychology_rounded,
            label: 'Psychologues',
            isCentral: true,
          )
        : const NavDestination(
            icon: Icons.gavel_rounded,
            selectedIcon: Icons.gavel_rounded,
            label: 'Avocats',
            isCentral: true,
          ),
    const NavDestination(
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month_rounded,
      label: 'Rendez-vous',
    ),
    const NavDestination(
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      label: 'Profil',
    ),
  ];
}
