import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/services/app_preferences_service.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/theme/universe_provider.dart';

/// Contrôle l'affichage du tutoriel guidé de première utilisation.
/// Par défaut, s'affiche automatiquement si `hasSeenTutorial()` est `false`.
class TutorialVisibilityNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(appPreferencesServiceProvider);
    return !prefs.hasSeenTutorial();
  }

  /// Lance ou relance manuellement le tutoriel depuis le début.
  Future<void> startTutorial() async {
    await ref.read(appPreferencesServiceProvider).setHasSeenTutorial(false);
    state = true;
  }

  /// Ferme le tutoriel et mémorise qu'il a été complété/passé.
  Future<void> completeTutorial() async {
    await ref.read(appPreferencesServiceProvider).setHasSeenTutorial(true);
    state = false;
  }
}

final showTutorialOverlayProvider =
    NotifierProvider<TutorialVisibilityNotifier, bool>(
      TutorialVisibilityNotifier.new,
    );

class _TutorialStepData {
  final String badge;
  final String title;
  final String description;
  final List<String> highlights;
  final IconData icon;
  final int targetTabIndex;

  const _TutorialStepData({
    required this.badge,
    required this.title,
    required this.description,
    required this.highlights,
    required this.icon,
    required this.targetTabIndex,
  });
}

/// Surcouche interactive de tutoriel de première utilisation en 5 étapes.
/// Présente pas à pas les fonctionnalités de PsyAvocat et fait défiler
/// les onglets correspondants en arrière-plan pour guider l'utilisateur.
class FirstUseTutorialOverlay extends ConsumerStatefulWidget {
  final ValueChanged<int>? onSelectTab;

  const FirstUseTutorialOverlay({super.key, this.onSelectTab});

  @override
  ConsumerState<FirstUseTutorialOverlay> createState() =>
      _FirstUseTutorialOverlayState();
}

class _FirstUseTutorialOverlayState
    extends ConsumerState<FirstUseTutorialOverlay> {
  int _currentStep = 0;

  List<_TutorialStepData> _buildSteps(AppUniverse universe) {
    final isPsy = universe.isPsychologist;
    return [
      _TutorialStepData(
        badge: tr('ÉTAPE 1 SUR 5 · BIENVENUE'),
        title: tr('Deux univers complémentaires'),
        description: tr(
          'Bienvenue sur PsyAvocat ! Depuis la barre supérieure de l’accueil, vous pouvez basculer à tout moment entre l’espace Psychologue et l’espace Avocat, et accéder à votre Messagerie ainsi qu’à vos Notifications.',
        ),
        highlights: [
          tr('Changement d’univers en 1 clic'),
          tr('Messagerie directe avec vos praticiens'),
          tr('Alertes et rappels en temps réel'),
        ],
        icon: Icons.swap_horiz_rounded,
        targetTabIndex: 0,
      ),
      _TutorialStepData(
        badge: isPsy
            ? tr('ÉTAPE 2 SUR 5 · ESPACE PSYCHOLOGUE')
            : tr('ÉTAPE 2 SUR 5 · ESPACE AVOCAT'),
        title: isPsy
            ? tr('Orientation & Suivi psychologique')
            : tr('Dossier juridique confidentiel'),
        description: isPsy
            ? tr(
                'Répondez au questionnaire d’orientation interactif pour être guidé vers le psychologue adapté à votre besoin, et renseignez votre fiche patient en toute confidentialité.',
              )
            : tr(
                'Soumettez votre dossier juridique avec vos pièces justificatives. Les avocats vérifiés étudient votre demande et vous transmettent leur proposition d’honoraires.',
              ),
        highlights: isPsy
            ? [
                tr('Questionnaire d’orientation guidé'),
                tr('Recommandation personnalisée'),
                tr('Fiche patient sécurisée'),
              ]
            : [
                tr('Dépôt de dossier en plusieurs étapes'),
                tr('Ajout de pièces jointes'),
                tr('Propositions d’honoraires claires'),
              ],
        icon: isPsy
            ? Icons.psychology_alt_rounded
            : Icons.folder_shared_rounded,
        targetTabIndex: 0,
      ),
      _TutorialStepData(
        badge: tr('ÉTAPE 3 SUR 5 · PRATICIENS'),
        title: tr('Trouvez votre professionnel & Réservez'),
        description: tr(
          'Explorez la liste des psychologues et avocats vérifiés par l’administration. Filtrez par spécialité, consultez leurs tarifs et choisissez votre créneau disponible.',
        ),
        highlights: [
          tr('Profils et diplômes vérifiés'),
          tr('Choix du créneau en temps réel'),
          tr('Acompte légal sécurisé de 20 %'),
        ],
        icon: Icons.person_search_rounded,
        targetTabIndex: 2,
      ),
      _TutorialStepData(
        badge: tr('ÉTAPE 4 SUR 5 · RENDEZ-VOUS & VISIO'),
        title: tr('Consultations au Cabinet ou en Visio'),
        description: tr(
          'Retrouvez tous vos rendez-vous confirmés. Pour une consultation à distance (Visio), un lien de salle vidéo PsyAvocat vous est envoyé automatiquement avec l’heure dans vos Rendez-vous, votre Messagerie et vos Notifications.',
        ),
        highlights: [
          tr('Bouton « Rejoindre la visioconférence »'),
          tr('Déplacement ou annulation facile'),
          tr('Contact automatique dans la messagerie'),
        ],
        icon: Icons.videocam_rounded,
        targetTabIndex: 3,
      ),
      _TutorialStepData(
        badge: tr('ÉTAPE 5 SUR 5 · CONTENUS & PROFIL'),
        title: tr('Publications vérifiées & Espace Profil'),
        description: tr(
          'Lisez gratuitement les conseils psychologiques et articles juridiques publiés par les praticiens. Dans votre Profil, gérez vos paiements, la langue, le thème et relancez ce tutoriel quand vous le souhaitez.',
        ),
        highlights: [
          tr('Articles juridiques & Conseils psy'),
          tr('Historique des acomptes et paiements'),
          tr('Option « Revoir le tutoriel » dans Paramètres'),
        ],
        icon: Icons.menu_book_rounded,
        targetTabIndex: 1,
      ),
    ];
  }

  void _goToStep(int index, List<_TutorialStepData> steps) {
    setState(() => _currentStep = index);
    widget.onSelectTab?.call(steps[index].targetTabIndex);
  }

  Future<void> _finish() async {
    widget.onSelectTab?.call(0);
    await ref.read(showTutorialOverlayProvider.notifier).completeTutorial();
  }

  @override
  Widget build(BuildContext context) {
    final universe = ref.watch(currentUniverseProvider);
    final steps = _buildSteps(universe);
    final step = steps[_currentStep];
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isLast = _currentStep == steps.length - 1;

    return Material(
      color: Colors.black.withValues(alpha: 0.68),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // Barre supérieure : Titre + bouton Passer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          size: 15,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          tr('Guide de première utilisation'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _finish,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.14),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: Text(
                      tr('Passer'),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Carte centrale animée du tutoriel
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.96, end: 1.0).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                    child: child,
                  ),
                ),
                child: Container(
                  key: ValueKey<int>(_currentStep),
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: context.palette.card,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.28),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icône + Badge d'étape
                      Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  primaryColor,
                                  primaryColor.withValues(alpha: 0.78),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              step.icon,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  step.badge,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                    color: primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  step.title,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: context.palette.textStrong,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Text(
                        step.description,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.48,
                          color: context.palette.text,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Points clés de l'étape
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: primaryColor.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (int i = 0; i < step.highlights.length; i++) ...[
                              if (i > 0) const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    size: 17,
                                    color: primaryColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      step.highlights[i],
                                      style: TextStyle(
                                        fontSize: 12.8,
                                        fontWeight: FontWeight.w600,
                                        color: context.palette.textStrong,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Indicateurs de progression (points)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(steps.length, (index) {
                          final active = index == _currentStep;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: active ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: active
                                  ? primaryColor
                                  : primaryColor.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 20),

                      // Boutons Précédent / Suivant ou Terminer
                      Row(
                        children: [
                          if (_currentStep > 0) ...[
                            Expanded(
                              flex: 2,
                              child: OutlinedButton(
                                onPressed: () =>
                                    _goToStep(_currentStep - 1, steps),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: primaryColor,
                                  side: BorderSide(color: primaryColor),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 13,
                                  ),
                                  shape: const StadiumBorder(),
                                ),
                                child: Text(
                                  tr('Précédent'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            flex: 3,
                            child: ElevatedButton(
                              onPressed: () {
                                if (isLast) {
                                  _finish();
                                } else {
                                  _goToStep(_currentStep + 1, steps);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: const StadiumBorder(),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    isLast
                                        ? tr('Commencer à utiliser l’appli')
                                        : tr('Suivant'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    isLast
                                        ? Icons.check_rounded
                                        : Icons.arrow_forward_rounded,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

