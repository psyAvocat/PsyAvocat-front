import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../data/models/questionnaire_model.dart';
import '../controllers/orientation_controller.dart';

/// Écran squelette dynamique du questionnaire d'orientation PsyAvocat.
/// Une seule page dont le CONTENU change à chaque étape.
/// Données : MySQL → API Spring Boot → provider Riverpod.
/// Maquette : barre de segments, radio cards, bouton Suivant violet.
class OrientationQuestionnaireScreen extends ConsumerStatefulWidget {
  const OrientationQuestionnaireScreen({super.key});

  @override
  ConsumerState<OrientationQuestionnaireScreen> createState() =>
      _OrientationQuestionnaireScreenState();
}

class _OrientationQuestionnaireScreenState
    extends ConsumerState<OrientationQuestionnaireScreen>
    with SingleTickerProviderStateMixin {

  // Données de secours si l'API est inaccessible
  static final QuestionnaireModel _fallback = QuestionnaireModel(
    id: 'q-juridique-fallback',
    titre: 'Questionnaire d\'orientation',
    type: 'JURIDIQUE',
    questions: [
      QuestionModel(
        id: 'q1',
        texte: 'Quel est votre problème principal ?',
        ordre: 1,
        reponses: [
          ReponseModel(id: 'r1', libelle: 'Famille, mariage, divorce', valeur: 'FAMILLE'),
          ReponseModel(id: 'r2', libelle: 'Travail, licenciement ou contrat de travail', valeur: 'TRAVAIL'),
          ReponseModel(id: 'r3', libelle: 'Terrain, maison ou propriété', valeur: 'IMMOBILIER'),
          ReponseModel(id: 'r4', libelle: 'Infraction, plainte ou problème pénal', valeur: 'PENAL'),
          ReponseModel(id: 'r5', libelle: 'Autre situation', valeur: 'AUTRE'),
        ],
      ),
      QuestionModel(
        id: 'q2',
        texte: 'Qui est principalement concerné par votre problème ?',
        ordre: 2,
        reponses: [
          ReponseModel(id: 'r6', libelle: 'Moi-même', valeur: 'MOI'),
          ReponseModel(id: 'r7', libelle: 'Un membre de ma famille', valeur: 'FAMILLE_PROCHE'),
          ReponseModel(id: 'r8', libelle: 'Mon employeur ou mon entreprise', valeur: 'EMPLOYEUR'),
          ReponseModel(id: 'r9', libelle: 'Une personne ou une organisation avec laquelle j\'ai un conflit', valeur: 'TIERCE'),
        ],
      ),
      QuestionModel(
        id: 'q3',
        texte: 'Quelle situation correspond le mieux à votre problème ?',
        ordre: 3,
        reponses: [
          ReponseModel(id: 'r10', libelle: 'Je suis en conflit avec mon conjoint ou ma famille', valeur: 'CONFLIT_FAMILLE'),
          ReponseModel(id: 'r11', libelle: 'J\'ai un problème avec mon emploi ou mon employeur', valeur: 'CONFLIT_TRAVAIL'),
          ReponseModel(id: 'r12', libelle: 'J\'ai un problème concernant un terrain, une maison ou un bien', valeur: 'CONFLIT_IMMO'),
          ReponseModel(id: 'r13', libelle: 'Je suis concerné par une plainte, une infraction ou une procédure pénale', valeur: 'CONFLIT_PENAL'),
        ],
      ),
    ],
  );

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(orientationControllerProvider.notifier).loadQuestionnaire();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _animateToNext(VoidCallback action) {
    _fadeController.reverse().then((_) {
      action();
      _fadeController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final universe = ref.watch(currentUniverseProvider);
    final primaryColor = universe.primaryColor;
    final orientationState = ref.watch(orientationControllerProvider);

    final questions = (orientationState.questionnaire?.questions.isNotEmpty == true)
        ? orientationState.questionnaire!.questions
        : _fallback.questions;

    final currentIndex = orientationState.currentStep.clamp(0, questions.length - 1);
    final currentQuestion = questions[currentIndex];
    final selectedAnswer = orientationState.answers[currentIndex];
    final isLastQuestion = currentIndex == questions.length - 1;
    final hasSelection = selectedAnswer != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── En-tête : Retour + Ignorer ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Bouton retour circulaire
                  _CircleIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () {
                      final canGoBack = ref
                          .read(orientationControllerProvider.notifier)
                          .previousStep();
                      if (!canGoBack) context.pop();
                    },
                  ),
                  // Bouton Ignorer pill
                  OutlinedButton(
                    onPressed: () => context.go('/home'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      foregroundColor: const Color(0xFF1F2937),
                    ),
                    child: const Text(
                      'Ignorer',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Barre de progression par segments ─────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: List.generate(questions.length, (i) {
                  final filled = i <= currentIndex;
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      height: 7,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: filled ? primaryColor : const Color(0xFFE8EAF0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 32),

            // ── Question + Réponses (zone scrollable avec fade) ───────────────
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Texte de la question
                      Text(
                        currentQuestion.texte,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E2432),
                          fontFamily: 'Montserrat',
                          letterSpacing: -0.3,
                          height: 1.3,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Options radio
                      ...currentQuestion.reponses.map((option) {
                        final isSelected = selectedAnswer?.code == option.id;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _RadioCard(
                            label: option.libelle,
                            isSelected: isSelected,
                            accentColor: primaryColor,
                            onTap: () {
                              ref
                                  .read(orientationControllerProvider.notifier)
                                  .selectAnswer(
                                    step: currentIndex,
                                    questionId: currentQuestion.id,
                                    question: currentQuestion.texte,
                                    label: option.libelle,
                                    reponseId: option.id,
                                  );
                            },
                          ),
                        );
                      }),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),

            // ── Bouton Suivant / Valider ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (hasSelection && !orientationState.isLoading)
                      ? () async {
                          if (!isLastQuestion) {
                            _animateToNext(() {
                              ref
                                  .read(orientationControllerProvider.notifier)
                                  .nextStep(questions.length);
                            });
                          } else {
                            final success = await ref
                                .read(orientationControllerProvider.notifier)
                                .soumettreQuestionnaire();
                            if (context.mounted) {
                              if (success) {
                                context.push('/orientation/recap');
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      orientationState.errorMessage ??
                                          'Erreur lors de la validation',
                                    ),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            }
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B2A5A),
                    disabledBackgroundColor: const Color(0xFFE5E7EB),
                    disabledForegroundColor: const Color(0xFF9CA3AF),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: orientationState.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          isLastQuestion ? 'Voir mon orientation' : 'Suivant',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.2,
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

// ─────────────────────────────────────────────────────────────────────────────
// Widgets internes
// ─────────────────────────────────────────────────────────────────────────────

/// Bouton circulaire avec icône (retour).
class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF1F2937)),
      ),
    );
  }
}

/// Carte radio d'une réponse — style conforme maquette.
class _RadioCard extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _RadioCard({
    required this.label,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accentColor : const Color(0xFFE5E7EB),
            width: isSelected ? 1.8 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Indicateur radio
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? accentColor : const Color(0xFFD1D5DB),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentColor,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFF111827)
                      : const Color(0xFF374151),
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
