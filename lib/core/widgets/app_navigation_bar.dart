import 'package:flutter/material.dart';
import '../theme/app_universe.dart';

/// Barre de navigation principale (Material 3 [NavigationBar]) à 5 onglets.
///
/// L'ordre des onglets correspond aux branches du `StatefulShellRoute` (app_router.dart) :
/// 0 Accueil · 1 Articles · 2 Avocats/Psychologues · 3 Rendez-vous · 4 Profil.
///
/// Le 3e onglet change de libellé et d'icône selon l'[universe] :
/// une seule barre pour les deux univers.
class AppNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final AppUniverse universe;

  const AppNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.universe,
  });

  @override
  Widget build(BuildContext context) {
    final isPsychologist = universe.isPsychologist;

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Accueil',
        ),
        const NavigationDestination(
          icon: Icon(Icons.article_outlined),
          selectedIcon: Icon(Icons.article_rounded),
          label: 'Articles',
        ),
        NavigationDestination(
          icon: Icon(
            isPsychologist ? Icons.psychology_outlined : Icons.balance_outlined,
          ),
          selectedIcon: Icon(isPsychologist ? Icons.psychology : Icons.balance),
          label: isPsychologist ? 'Psychologues' : 'Avocats',
        ),
        const NavigationDestination(
          icon: Icon(Icons.event_outlined),
          selectedIcon: Icon(Icons.event),
          label: 'Rendez-vous',
        ),
        const NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Profil',
        ),
      ],
    );
  }
}
