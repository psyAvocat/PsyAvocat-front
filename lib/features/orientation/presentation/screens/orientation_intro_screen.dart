import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/router/app_routes.dart';

/// Étape préalable bienveillante avant le questionnaire d'orientation psychologique.
///
/// Permet au patient de choisir s'il souhaite être guidé par le questionnaire
/// ou explorer directement l'espace psychologique sans être bloqué.
/// Totalement responsive et exempt de débordement sur petits écrans.
class OrientationIntroScreen extends ConsumerWidget {
  const OrientationIntroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Retour',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => context.go(AppRoutes.home),
            child: const Text('Passer'),
          ),
          AppSpacing.hGap8,
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: AppSpacing.screenPadding,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Spacer(),
                      // Icône emblème Psychologie
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          gradient: AppColors.psychologistCardGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.psychologist.withValues(
                                alpha: 0.35,
                              ),
                              blurRadius: 28,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.psychology_rounded,
                          size: 46,
                          color: Colors.white,
                        ),
                      ),
                      AppSpacing.vGap24,
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.secondaryContainer,
                          borderRadius: AppRadii.pill,
                        ),
                        child: Text(
                          'Orientation personnalisée',
                          style: AppTypography.badgeTexte.copyWith(
                            color: scheme.primary,
                          ),
                        ),
                      ),
                      AppSpacing.vGap16,
                      // Question claire et bienveillante exigée par le cahier des charges
                      Text(
                        'Souhaitez-vous répondre à quelques questions pour nous aider à vous orienter vers un psychologue ?',
                        textAlign: TextAlign.center,
                        style: AppTypography.titreMoyen.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                      AppSpacing.vGap12,
                      Text(
                        'Ce court questionnaire confidentiel (moins de 2 minutes) analyse votre situation '
                        'pour vous recommander les professionnels les plus qualifiés.',
                        textAlign: TextAlign.center,
                        style: AppTypography.texteSecondaire.copyWith(
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                      const Spacer(),
                      AppSpacing.vGap24,
                      // Action 1 : Oui, commencer
                      AppPrimaryButton(
                        label: 'Oui, commencer',
                        trailingIcon: Icons.arrow_forward_rounded,
                        onPressed: () => context.go(AppRoutes.orientation),
                      ),
                      AppSpacing.vGap12,
                      // Action 2 : Pas maintenant / Non
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => context.go(AppRoutes.home),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                              color: scheme.outline.withValues(alpha: 0.5),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadii.r12,
                            ),
                          ),
                          child: Text(
                            'Pas maintenant',
                            style: AppTypography.texteMedium.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      AppSpacing.vGap8,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
