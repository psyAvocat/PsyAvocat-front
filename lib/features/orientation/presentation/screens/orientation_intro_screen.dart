import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/l10n/app_strings.dart';
import '../widgets/plant_illustration.dart';

/// Proposition du questionnaire d'orientation, juste après le choix de
/// l'univers Psychologue : facultatif, l'utilisateur peut le passer.
/// (Depuis l'accueil, le bouton « Faire le test » ouvre directement les questions.)
class OrientationIntroScreen extends ConsumerWidget {
  const OrientationIntroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Stack(
        children: [
          const Positioned.fill(child: AmbientParticles()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: AppSpacing.screenPadding,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - AppSpacing.s48,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Spacer(),
                        const Center(child: PlantIllustration(size: 190)),
                        AppSpacing.vGap24,
                        Text(
                          tr('Trouvons le bon psychologue'),
                          textAlign: TextAlign.center,
                          style: AppTypography.grandTitre.copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                        AppSpacing.vGap12,
                        Text(
                          tr(
                            'Répondez à quelques questions simples : nous vous '
                            'orientons vers le professionnel qui vous correspond.',
                          ),
                          textAlign: TextAlign.center,
                          style: AppTypography.texte.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                        AppSpacing.vGap24,
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: AppSpacing.s8,
                          runSpacing: AppSpacing.s8,
                          children: [
                            _InfoPill(
                              icon: Icons.schedule_rounded,
                              label: tr('Moins de 2 min'),
                            ),
                            _InfoPill(
                              icon: Icons.lock_outline_rounded,
                              label: tr('Confidentiel'),
                            ),
                            _InfoPill(
                              icon: Icons.favorite_border_rounded,
                              label: tr('Pas un diagnostic'),
                            ),
                          ],
                        ),
                        const Spacer(flex: 2),
                        AppSpacing.vGap24,
                        AppButton(
                          text: tr('Commencer'),
                          onPressed: () => context.go(AppRoutes.orientation),
                        ),
                        AppSpacing.vGap8,
                        Center(
                          child: AppButton.ghost(
                            text: tr('Plus tard'),
                            onPressed: () => context.go(AppRoutes.home),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Petite étiquette d'information (icône + texte) sous le titre.
class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.miniTexte.copyWith(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
