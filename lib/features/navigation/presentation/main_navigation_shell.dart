import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/universe_provider.dart';
import '../../../core/widgets/widgets.dart';
import 'navigation_destinations.dart';

/// Shell de navigation principal : contenu de l'onglet actif + [PsyAvocatNavigationBar].
///
/// Les onglets sont des branches d'un `StatefulShellRoute.indexedStack` :
/// chaque onglet garde son état (scroll, sous-pages) quand on change d'onglet,
/// rien n'est reconstruit inutilement.
class MainNavigationShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainNavigationShell({super.key, required this.navigationShell});

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      // Re-taper l'onglet actif revient à sa page racine.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  /// Pages principales des onglets : seules pages où la barre est affichée.
  /// Les sous-pages (recherche…) l'occultent pour laisser toute la place au contenu.
  static const _pagesAvecBarre = {
    AppRoutes.home,
    AppRoutes.articles,
    AppRoutes.conseils,
    AppRoutes.professionnels,
    AppRoutes.rendezVous,
    AppRoutes.profil,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final universe = ref.watch(currentUniverseProvider);
    final afficherBarre = _pagesAvecBarre.contains(
      GoRouterState.of(context).uri.path,
    );

    return Scaffold(
      body: navigationShell,
      // La barre flotte au-dessus du contenu (capsule de la maquette).
      extendBody: true,
      bottomNavigationBar: afficherBarre
          ? PsyAvocatNavigationBar(
              destinations: navigationDestinationsFor(universe),
              currentIndex: navigationShell.currentIndex,
              onDestinationSelected: _onDestinationSelected,
            )
          : null,
    );
  }
}
