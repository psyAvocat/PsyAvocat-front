import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../contenus/presentation/widgets/popular_publications_section.dart';
import 'home_action_card.dart';
import 'home_cards.dart';
import 'home_top_bar.dart';

/// Accueil de l'univers Avocat — maquette « Accueil ».
///
/// La section « Communauté » de la maquette n'est pas affichée :
/// aucune donnée réelle ne l'alimente aujourd'hui.
class LawyerHomeView extends StatelessWidget {
  const LawyerHomeView({super.key});

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
        AppSpacing.vGap24,
        Text(
          'Bonjour,\nComment pourrons-nous vous aider aujourd’hui ?',
          style: AppTypography.titreMoyen,
        ),
        AppSpacing.vGap20,
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: HomeActionCard(
                  icon: Icons.balance_rounded,
                  title: 'Voir les professionnels',
                  highlighted: true,
                  onTap: () => context.go(AppRoutes.professionnels),
                ),
              ),
              AppSpacing.hGap12,
              Expanded(
                child: HomeActionCard(
                  icon: Icons.description_outlined,
                  title: 'Voir mes dossiers',
                  onTap: () => context.push(AppRoutes.dossiers),
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
