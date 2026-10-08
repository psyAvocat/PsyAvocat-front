import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/user_message.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/widgets/widgets.dart';
import '../controllers/universe_selection_controller.dart';

/// Choix de l'univers Avocat ou Psychologue — maquette Figma « category-selection ».
///
/// Après le choix : profil créé si besoin, thème adapté, puis questionnaire
/// d'orientation de l'univers choisi.
class SelectionUniversScreen extends ConsumerWidget {
  const SelectionUniversScreen({super.key});

  Future<void> _select(
    BuildContext context,
    WidgetRef ref,
    AppUniverse universe,
  ) async {
    final success = await ref
        .read(universeSelectionControllerProvider.notifier)
        .select(universe);
    if (success && context.mounted) {
      // Règle 10 & 11 : Aucun questionnaire pour l'avocat ; étape préalable pour le psychologue
      if (universe.isPsychologist) {
        context.go('/orientation/intro');
      } else {
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(universeSelectionControllerProvider);

    ref.listen<AsyncValue<void>>(universeSelectionControllerProvider, (
      _,
      next,
    ) {
      if (next.hasError && !next.isLoading) {
        AppNotification.showError(context, userMessageFor(next.error!));
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundLavender,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSpacing.vGap32,
              Text(
                'Quel professionnel recherchez-vous ?',
                style: AppTypography.grandTitre.copyWith(
                  color: AppColors.lawyer,
                ),
              ),
              AppSpacing.vGap16,
              Text(
                'Choisissez la catégorie qui correspond à votre besoin.',
                style: AppTypography.petitTitre.copyWith(
                  color: AppColors.subtitleSlate,
                ),
              ),
              AppSpacing.vGap32,
              // Les cartes sont désactivées pendant l'enregistrement du choix.
              AbsorbPointer(
                absorbing: state.isLoading,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: state.isLoading ? 0.6 : 1,
                  child: Column(
                    children: [
                      AppUniverseCard(
                        title: 'Avocat',
                        description: 'Conseil juridique et accompagnement',
                        icon: Icons.balance_rounded,
                        gradient: AppColors.lawyerCardGradient,
                        shadowColor: AppColors.lawyer,
                        onTap: () => _select(context, ref, AppUniverse.lawyer),
                      ),
                      AppSpacing.vGap20,
                      AppUniverseCard(
                        title: 'Psychologue',
                        description: 'Écoute et soutien psychologique',
                        icon: Icons.psychology_outlined,
                        gradient: AppColors.psychologistCardGradient,
                        shadowColor: AppColors.psychologist,
                        onTap: () =>
                            _select(context, ref, AppUniverse.psychologist),
                      ),
                    ],
                  ),
                ),
              ),
              if (state.isLoading) ...[
                AppSpacing.vGap24,
                const Center(child: CircularProgressIndicator()),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
