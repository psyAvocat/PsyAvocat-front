import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../contenus/presentation/widgets/popular_publications_section.dart';
import 'home_action_card.dart';
import 'home_cards.dart';
import 'home_top_bar.dart';

/// Accueil de l'univers Psychologue — maquette « Accueil psychologue ».
class PsychologistHomeView extends StatelessWidget {
  const PsychologistHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      // Marge basse : la barre de navigation flotte au-dessus du contenu.
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s20,
        AppSpacing.s16,
        AppSpacing.s20,
        120,
      ),
      children: [
        const HomeTopBar(),
        AppSpacing.vGap16,
        // La recherche ouvre l'écran de recherche des psychologues.
        SearchBar(
          hintText: 'Rechercher un psychologue, une spécialité…',
          leading: const Icon(Icons.search_rounded),
          elevation: const WidgetStatePropertyAll(0),
          onTap: () => context.go(AppRoutes.professionnelsRecherche),
          readOnly: true,
        ),
        AppSpacing.vGap20,
        const _WellbeingBanner(),
        AppSpacing.vGap20,
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: HomeActionCard(
                  icon: Icons.psychology_outlined,
                  title: 'Trouver un psychologue',
                  subtitle: 'Trouvez le professionnel qui vous correspond',
                  highlighted: true,
                  onTap: () => context.go(AppRoutes.professionnels),
                ),
              ),
              AppSpacing.hGap12,
              Expanded(
                child: HomeActionCard(
                  icon: Icons.assignment_turned_in_outlined,
                  title: 'Consulter les conseils',
                  subtitle: 'Des conseils d’experts pour mieux vivre',
                  onTap: () => context.go(AppRoutes.conseils),
                ),
              ),
            ],
          ),
        ),
        AppSpacing.vGap24,
        const AppSectionHeader(title: 'Votre prochain rendez-vous'),
        AppSpacing.vGap8,
        const NextAppointmentCard(),
        AppSpacing.vGap24,
        const PopularPublicationsSection(),
      ],
    );
  }
}

/// Bannière « Prenez soin de votre santé mentale » : photo de l'onboarding
/// assombrie par un voile de la couleur de l'univers.
class _WellbeingBanner extends StatelessWidget {
  const _WellbeingBanner();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: AppRadii.r16,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/psychologist_1.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          Positioned.fill(
            child: ColoredBox(color: scheme.primary.withValues(alpha: 0.72)),
          ),
          Padding(
            padding: AppSpacing.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSpacing.vGap16,
                Text(
                  'Prenez soin\nde votre santé mentale',
                  style: AppTypography.petitTitre.copyWith(
                    color: scheme.onPrimary,
                  ),
                ),
                AppSpacing.vGap8,
                Text(
                  'Un accompagnement bienveillant pour avancer sereinement.',
                  style: AppTypography.texteSecondaire.copyWith(
                    color: scheme.onPrimary,
                  ),
                ),
                AppSpacing.vGap16,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
