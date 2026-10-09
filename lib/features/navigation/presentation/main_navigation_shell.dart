import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final universe = ref.watch(currentUniverseProvider);

    return Scaffold(
      body: navigationShell,
      // La barre flotte au-dessus du contenu (capsule de la maquette).
      extendBody: true,
      bottomNavigationBar: PsyAvocatNavigationBar(
        destinations: navigationDestinationsFor(universe),
        currentIndex: navigationShell.currentIndex,
        onDestinationSelected: _onDestinationSelected,
      ),
    );
  }
}
