import 'package:flutter/widgets.dart';

/// Destination de navigation pour [PsyAvocatNavigationBar].
class NavDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String? tooltip;
  final bool isCentral;

  const NavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.tooltip,
    this.isCentral = false,
  });
}
