import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/universe_provider.dart';

import '../controllers/professionnels_controller.dart';

/// Écran officiel listant les professionnels recommandés après le questionnaire d'orientation.
/// Conforme à la maquette Figma : Titre "Nos avocats pour vous / Profils correspondants à votre besoin".
/// Les données proviennent directement de MySQL via l'API Spring Boot.
class ProfessionnelsListScreen extends ConsumerWidget {
  const ProfessionnelsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final universe = ref.watch(currentUniverseProvider);
    final primaryColor = universe.primaryColor;
    final isAvocat = universe.isLawyer || universe.isNeutral;
    final prosAsync = ref.watch(professionnelsListProvider(isAvocat));

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Barre supérieure : Bouton retour & Ignorer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            color: Colors.white,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                            color: const Color(0xFF1F2937),
                            onPressed: () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go('/home');
                              }
                            },
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () => context.go('/home'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                          child: const Text(
                            'Ignorer',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Titre principal conforme à la maquette
                    Text(
                      isAvocat ? 'Nos avocats\npour vous' : 'Nos psychologues\npour vous',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                        fontFamily: 'Montserrat',
                        height: 1.2,
                        letterSpacing: -0.6,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Profils correspondants à votre besoin',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4B5563),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // En-tête de section "Avocats recommandés / Voir tout"
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isAvocat ? 'Avocats recommandés' : 'Psychologues recommandés',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        Text(
                          'Voir tout',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Liste des cartes professionnels synchronisée avec MySQL / API Spring Boot
            prosAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                      child: Center(
                        child: Text(
                          isAvocat
                              ? 'Aucun avocat disponible pour le moment'
                              : 'Aucun psychologue disponible pour le moment',
                          style: const TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
                        ),
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 100.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final pro = list[index];
                        final specialiteText = pro.specialitePrincipale;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  context.push('/professionnels/${pro.id}');
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: const EdgeInsets.all(14.0),
                                  child: Row(
                                    children: [
                                      // Photo carrée arrondie
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: Image.asset(
                                          pro.imagePath,
                                          width: 68,
                                          height: 68,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            width: 68,
                                            height: 68,
                                            color: primaryColor.withValues(alpha: 0.1),
                                            child: Icon(
                                              isAvocat ? Icons.gavel_rounded : Icons.psychology_rounded,
                                              color: primaryColor,
                                            ),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(width: 16),

                                      // Infos : Nom, Spécialité, Ville
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              pro.nom,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF111827),
                                                letterSpacing: -0.2,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              specialiteText,
                                              style: TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w600,
                                                color: primaryColor,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              pro.ville,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w400,
                                                color: Color(0xFF6B7280),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Chevron droit
                                      const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 16,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: list.length,
                    ),
                  ),
                );
              },
              loading: () => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40.0),
                  child: Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  ),
                ),
              ),
              error: (err, stack) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 36),
                        const SizedBox(height: 12),
                        const Text('Erreur de chargement des professionnels'),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => ref.invalidate(professionnelsListProvider(isAvocat)),
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
