import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_universe.dart';
import '../../../../core/theme/universe_provider.dart';

/// Écran officiel de Choix de l'univers : Avocat ou Psychologue.
/// Conforme à 100% à la maquette Figma.
/// Au clic, l'application bascule immédiatement son thème dynamique vers l'univers choisi.
class SelectionUniversScreen extends ConsumerWidget {
  const SelectionUniversScreen({super.key});

  void _selectUniverse(BuildContext context, WidgetRef ref, AppUniverse universe) {
    ref.read(currentUniverseProvider.notifier).setUniverse(universe);
    context.go('/home');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Titre principal
              const Text(
                'Quel professionnel\nrecherchez-vous ?',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F2648),
                  height: 1.25,
                  letterSpacing: -0.6,
                  fontFamily: 'Montserrat',
                ),
              ),

              const SizedBox(height: 14),

              // Sous-titre
              const Text(
                'Choisissez la catégorie qui\ncorrespond à votre besoin.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF4B5563),
                  height: 1.45,
                ),
              ),

              const SizedBox(height: 36),

              // Carte 1 : Univers AVOCAT (Bleu Nuit)
              Expanded(
                child: _buildUniverseCard(
                  title: 'Avocat',
                  description: 'Conseil juridique et accompagnement',
                  icon: Icons.balance_rounded,
                  gradientColors: const [
                    Color(0xFF0C244F),
                    Color(0xFF143B7B),
                  ],
                  circleColor: const Color(0xFF1B4996).withValues(alpha: 0.35),
                  badgeBg: Colors.white.withValues(alpha: 0.12),
                  onTap: () => _selectUniverse(context, ref, AppUniverse.lawyer),
                ),
              ),

              const SizedBox(height: 24),

              // Carte 2 : Univers PSYCHOLOGUE (Violet)
              Expanded(
                child: _buildUniverseCard(
                  title: 'Psychologue',
                  description: 'Écoute et soutien psychologique',
                  icon: Icons.psychology_rounded,
                  gradientColors: const [
                    Color(0xFF4A0082),
                    Color(0xFF6B11B2),
                  ],
                  circleColor: const Color(0xFF8620D6).withValues(alpha: 0.35),
                  badgeBg: Colors.white.withValues(alpha: 0.12),
                  onTap: () => _selectUniverse(context, ref, AppUniverse.psychologist),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUniverseCard({
    required String title,
    required String description,
    required IconData icon,
    required List<Color> gradientColors,
    required Color circleColor,
    required Color badgeBg,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.32),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(
              children: [
                // Cercles d'ambiance organiques en fond de carte
                Positioned(
                  right: -40,
                  bottom: -40,
                  child: Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: circleColor,
                    ),
                  ),
                ),

                // Contenu de la carte
                Padding(
                  padding: const EdgeInsets.all(22.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Ligne supérieure : Icône dans badge et chevron
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              icon,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.16),
                            ),
                            child: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ],
                      ),

                      // Section inférieure : Titre et description
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3,
                              fontFamily: 'Montserrat',
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withValues(alpha: 0.88),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
