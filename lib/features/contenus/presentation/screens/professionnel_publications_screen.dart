import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../../../core/widgets/app_async_view.dart';
import '../../data/models/contenu_model.dart';
import '../controllers/contenus_controller.dart';
import '../widgets/publication_cards.dart';
import '../../../../core/l10n/app_strings.dart';

/// Articles (avocat) ou conseils (psychologue) publiés par un professionnel,
/// ouverts depuis le bouton « Voir les articles » de sa fiche.
class ProfessionnelPublicationsScreen extends ConsumerWidget {
  final String professionnelId;

  /// Nom affiché sous le titre (« Me Traoré ») ; facultatif.
  final String? professionnelNom;

  const ProfessionnelPublicationsScreen({
    super.key,
    required this.professionnelId,
    this.professionnelNom,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final universe = ref.watch(currentUniverseProvider);
    final label = publicationsLabelFor(universe);
    final publications = ref.watch(
      professionnelPublicationsProvider(professionnelId),
    );

    return Scaffold(
      backgroundColor: context.palette.page,
      appBar: AppBar(
        backgroundColor: context.palette.card,
        surfaceTintColor: context.palette.card,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.petitTitre),
            if (professionnelNom != null)
              Text(professionnelNom!, style: AppTypography.texteSecondaire),
          ],
        ),
      ),
      body: AppAsyncView<List<Publication>>(
        value: publications,
        isEmpty: (list) => list.isEmpty,
        emptyTitle: universe.isLawyer
            ? tr('Aucun article publié')
            : tr('Aucun conseil publié'),
        emptyMessage: tr(
          'Ce professionnel n’a encore rien publié. Revenez plus tard.',
        ),
        emptyIcon: universe.isLawyer
            ? Icons.menu_book_outlined
            : Icons.lightbulb_outline_rounded,
        onRetry: () =>
            ref.invalidate(professionnelPublicationsProvider(professionnelId)),
        builder: (list) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(
            professionnelPublicationsProvider(professionnelId),
          ),
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.s16),
            itemCount: list.length,
            separatorBuilder: (_, _) => AppSpacing.vGap12,
            itemBuilder: (context, index) => PublicationListCard(
              publication: list[index],
              onTap: () => context.push(AppRoutes.contenu(list[index].id)),
            ),
          ),
        ),
      ),
    );
  }
}
