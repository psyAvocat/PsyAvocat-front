import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../contenus/presentation/widgets/popular_publications_section.dart';
import 'home_action_card.dart';
import 'home_cards.dart';
import '../../../auth/presentation/controllers/session_controller.dart';
import '../utils/home_greeting.dart';
import '../../../../core/l10n/app_strings.dart';

/// Accueil de l'univers Avocat — maquette « Accueil ».
///
/// La section « Communauté » de la maquette n'est pas affichée :
/// aucune donnée réelle ne l'alimente aujourd'hui.
class LawyerHomeView extends ConsumerWidget {
  const LawyerHomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salut = lawyerGreeting(
      ref.watch(sessionControllerProvider).user?.prenom,
    );
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      // Défilement même si le contenu est court : « tirer pour rafraîchir ».
      physics: const AlwaysScrollableScrollPhysics(),
      // Marge basse : la barre de navigation flotte au-dessus du contenu.
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s20,
        AppSpacing.s8,
        AppSpacing.s20,
        120,
      ),
      children: [
        Text(
          salut.titre,
          style: AppTypography.titreMoyen.copyWith(color: scheme.onSurface),
        ),
        AppSpacing.vGap4,
        Text(
          salut.phrase,
          style: AppTypography.texte.copyWith(color: scheme.onSurfaceVariant),
        ),
        AppSpacing.vGap20,
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: HomeActionCard(
                  title: tr('Voir les professionnels'),
                  highlighted: true,
                  onTap: () => context.go(AppRoutes.professionnels),
                ),
              ),
              AppSpacing.hGap12,
              Expanded(
                child: HomeActionCard(
                  title: tr('Voir mes dossiers'),
                  onTap: () => context.push(AppRoutes.dossiers),
                ),
              ),
            ],
          ),
        ),
        AppSpacing.vGap24,
        AppSectionHeader(title: tr('Votre prochain rendez-vous')),
        AppSpacing.vGap8,
        const NextAppointmentCard(),
        AppSpacing.vGap24,
        const PopularPublicationsSection(),
      ],
    );
  }
}
