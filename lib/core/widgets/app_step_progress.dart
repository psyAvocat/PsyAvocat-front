import 'package:flutter/material.dart';
import '../theme/design_system.dart';

/// Progression d'un parcours en plusieurs étapes : « Question 3 / 20 » + barre.
///
/// La valeur est calculée à partir de [currentStep] (commence à 1) et [totalSteps] :
/// aucune étape n'est codée en dur.
///
/// Exemple : `AppStepProgress(currentStep: 3, totalSteps: 20, label: 'Question')`
class AppStepProgress extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final String label;

  const AppStepProgress({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.label = 'Étape',
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalSteps == 0 ? 0.0 : currentStep / totalSteps;
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      label: '$label $currentStep sur $totalSteps',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label $currentStep / $totalSteps',
            style: AppTypography.texteSecondaire.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.primary,
            ),
          ),
          AppSpacing.vGap8,
          // La barre glisse doucement vers sa nouvelle valeur.
          TweenAnimationBuilder<double>(
            tween: Tween(end: progress),
            duration: const Duration(milliseconds: 300),
            builder: (context, value, _) =>
                LinearProgressIndicator(value: value),
          ),
        ],
      ),
    );
  }
}
