import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/universe_provider.dart';
import '../controllers/orientation_controller.dart';

/// Écran Récapitulatif de vos réponses conforme à la maquette Figma.
/// Affiche la liste des choix validés avec coches vertes, le bouton « Reprendre » et la validation du matching.
class OrientationRecapScreen extends ConsumerWidget {
  const OrientationRecapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final universe = ref.watch(currentUniverseProvider);
    final primaryColor = universe.primaryColor;
    final orientationState = ref.watch(orientationControllerProvider);
    final answers = orientationState.answers.values.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFEFF3F8),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // Titre principal
              const Text(
                'Recapitulatif de\nvos reponses',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E2432),
                  fontFamily: 'Montserrat',
                  letterSpacing: -0.5,
                  height: 1.25,
                ),
              ),

              const SizedBox(height: 20),

              // Carte blanche surélevée contenant la liste des réponses
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: answers.isEmpty
                      ? const Center(
                          child: Text(
                            'Aucune réponse enregistrée.',
                            style: TextStyle(color: Color(0xFF6B7280)),
                          ),
                        )
                      : ListView.separated(
                          itemCount: answers.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final ans = answers[index];
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFE5E7EB),
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      ans.label,
                                      style: const TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF374151),
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(
                                    Icons.check_rounded,
                                    color: Color(0xFF16A34A),
                                    size: 24,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // Bouton 1 : Lancer le matching
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => context.push('/orientation/matching'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Trouver mes professionnels',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Bouton 2 : Reprendre (pour modifier les réponses)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(orientationControllerProvider.notifier).reset();
                    context.pop();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(color: primaryColor, width: 1.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text(
                    'Reprendre',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
