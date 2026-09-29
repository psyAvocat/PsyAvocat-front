import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/floating_navbar.dart';

/// Shell de navigation principal enveloppant les onglets de l'application avec la navbar flottante.
class MainNavigationShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainNavigationShell({
    super.key,
    required this.navigationShell,
  });

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: FloatingNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: _onTap,
      ),
      extendBody: true,
    );
  }
}
