import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../../../core/widgets/widgets.dart';
import '../../data/models/contenu_model.dart';
import '../controllers/contenus_controller.dart';
import 'publication_cards.dart';

/// Section d'accueil « Articles populaires » (Avocat) ou « Conseils populaires »
/// (Psychologue) : la publication la plus consultée, issue de l'API.
class PopularPublicationsSection extends ConsumerWidget {
  const PopularPublicationsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final universe = ref.watch(currentUniverseProvider);
    final isLawyer = universe.isLawyer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: isLawyer ? 'Articles populaires' : 'Conseils populaires',
          actionLabel: 'Voir tout',
          onAction: () =>
              context.go(isLawyer ? AppRoutes.articles : AppRoutes.conseils),
        ),
        AppSpacing.vGap8,
        AppAsyncView<List<Publication>>(
          compact: true,
          value: ref.watch(popularPublicationsProvider),
          isEmpty: (list) => list.isEmpty,
          emptyMessage: isLawyer
              ? 'Aucun article publié pour le moment.'
              : 'Aucun conseil publié pour le moment.',
          emptyIcon: isLawyer
              ? Icons.menu_book_outlined
              : Icons.lightbulb_outline_rounded,
          onRetry: () => ref.invalidate(popularPublicationsProvider),
          builder: (list) => PublicationFeatureCard(
            publication: list.first,
            onTap: () => context.push(AppRoutes.contenu(list.first.id)),
          ),
        ),
      ],
    );
  }
}
