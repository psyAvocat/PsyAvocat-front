import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/universe_provider.dart';

/// Barre de navigation flottante moderne (« Floating Capsule ») conforme à la maquette Figma.
/// 5 branches : Accueil (0), Professionnels (1), Rendez-vous central (2), Mes dossiers (3), Profil (4).
class FloatingNavBar extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final universe = ref.watch(currentUniverseProvider);
    final primaryColor = universe.primaryColor;

    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding > 0 ? bottomPadding + 6 : 16),
      child: SizedBox(
        height: 72,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // Corps principal de la barre flottante en pilule
            Container(
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(36),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(
                  color: const Color(0xFFEFF0F6),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // 0. Accueil
                  _buildNavItem(
                    index: 0,
                    label: 'Accueil',
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    isActive: currentIndex == 0,
                    activeColor: primaryColor,
                  ),

                  // 1. Professionnels
                  _buildNavItem(
                    index: 1,
                    label: 'Professionnels',
                    icon: Icons.search_rounded,
                    activeIcon: Icons.search_rounded,
                    isActive: currentIndex == 1,
                    activeColor: primaryColor,
                  ),

                  // Espace réservé pour le bouton central surélevé (2 = Rendez-vous)
                  const SizedBox(width: 58),

                  // 3. Mes dossiers
                  _buildNavItem(
                    index: 3,
                    label: 'Mes dossiers',
                    icon: Icons.folder_outlined,
                    activeIcon: Icons.folder_rounded,
                    isActive: currentIndex == 3,
                    activeColor: primaryColor,
                  ),

                  // 4. Profil
                  _buildNavItem(
                    index: 4,
                    label: 'Profil',
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    isActive: currentIndex == 4,
                    activeColor: primaryColor,
                  ),
                ],
              ),
            ),

            // 2. Bouton central « Rendez-vous » surélevé
            Positioned(
              top: -14,
              child: GestureDetector(
                onTap: () => onTap(2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor,
                        border: Border.all(
                          color: Colors.white,
                          width: 3.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Rendez-vous',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: currentIndex == 2 ? FontWeight.w800 : FontWeight.w600,
                        color: currentIndex == 2 ? primaryColor : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
    required bool isActive,
    required Color activeColor,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isActive ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: Icon(
                isActive ? activeIcon : icon,
                size: 22,
                color: isActive ? activeColor : const Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? activeColor : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
