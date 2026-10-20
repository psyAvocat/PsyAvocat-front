import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/user_message.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../data/models/contenu_model.dart';
import '../controllers/contenus_controller.dart';
import '../widgets/publication_image.dart';
import '../widgets/publication_meta.dart';
import '../../../../core/l10n/app_strings.dart';

/// Détail d'un article ou d'un conseil — maquettes « Article » et « Conseil ».
///
/// Si l'auteur désactive ou supprime la publication (même pendant la lecture),
/// l'API répond 404 et l'écran l'indique au lieu d'afficher une vieille copie.
class ContenuDetailScreen extends ConsumerWidget {
  final String contenuId;

  const ContenuDetailScreen({super.key, required this.contenuId});

  void _leave(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(publicationDetailProvider(contenuId));

    return detail.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(leading: const AppBackButton()),
        body: error is NotFoundException
            ? AppEmptyStateView(
                title: tr("Cette ressource n'est plus disponible"),
                message: tr("Elle a été retirée par son auteur."),
                icon: Icons.link_off_rounded,
                actionText: tr('Retour'),
                onAction: () => _leave(context),
              )
            : AppErrorStateView(
                message: userMessageFor(error),
                onRetry: () =>
                    ref.invalidate(publicationDetailProvider(contenuId)),
              ),
      ),
      data: (publication) {
        // Cloisonnement : un article juridique ne s'ouvre pas depuis l'univers
        // Psychologue (lien profond, notification), et inversement.
        final universe = ref.watch(currentUniverseProvider);
        if (publication.isArticle != universe.isLawyer) {
          return Scaffold(
            appBar: AppBar(leading: const AppBackButton()),
            body: AppEmptyStateView(
              title: tr('Publication d’un autre univers'),
              message: publication.isArticle
                  ? tr(
                      'Cet article appartient à l’univers Avocat. Changez d’univers pour le lire.',
                    )
                  : tr(
                      'Ce conseil appartient à l’univers Psychologue. Changez d’univers pour le lire.',
                    ),
              icon: Icons.swap_horiz_rounded,
              actionText: tr('Retour'),
              onAction: () => _leave(context),
            ),
          );
        }
        return publication.isArticle
            ? _ArticleView(
                publication: publication,
                onQuit: () => _leave(context),
              )
            : _ConseilView(
                publication: publication,
                onBack: () => _leave(context),
              );
      },
    );
  }
}

/// Maquette « Article » : image pleine largeur, titre, date, auteur, texte,
/// puis barre d'action avec « Quitter ».
class _ArticleView extends StatelessWidget {
  final Publication publication;
  final VoidCallback onQuit;

  const _ArticleView({required this.publication, required this.onQuit});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pub = publication;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            leading: const AppBackButton(),
            flexibleSpace: FlexibleSpaceBar(
              background: PublicationImage(
                imageUrl: pub.imageUrl,
                borderRadius: BorderRadius.zero,
              ),
            ),
          ),
          SliverPadding(
            padding: AppSpacing.screenPadding,
            sliver: SliverList.list(
              children: [
                Text(pub.titre, style: AppTypography.titreMoyen),
                AppSpacing.vGap12,
                if (pub.datePublication != null)
                  Text(
                    tr('Publié le {date}', {
                      'date': Formatters.formatLongDate(pub.datePublication),
                    }),
                    style: AppTypography.texteSecondaire,
                  ),
                if (pub.auteurDisplayName != null)
                  Text.rich(
                    TextSpan(
                      style: AppTypography.texteSecondaire,
                      children: [
                        TextSpan(text: tr('par ')),
                        TextSpan(
                          text: pub.auteurDisplayName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                AppSpacing.vGap24,
                Text(
                  pub.contenu ?? '',
                  style: AppTypography.texte.copyWith(height: 1.6),
                ),
                AppSpacing.vGap24,
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(AppSpacing.s16),
        child: AppButton(text: tr('Quitter'), onPressed: onQuit),
      ),
    );
  }
}

/// Maquette « Conseil » : barre « Conseil », image arrondie, titre, auteur
/// avec photo, catégorie, date et temps de lecture, puis le texte.
class _ConseilView extends StatelessWidget {
  final Publication publication;
  final VoidCallback onBack;

  const _ConseilView({required this.publication, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final pub = publication;

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(onPressed: onBack),
        title: Text(tr('Conseil')),
      ),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          PublicationImage(
            imageUrl: pub.imageUrl,
            height: 200,
            width: double.infinity,
            borderRadius: AppRadii.r16,
          ),
          AppSpacing.vGap20,
          Text(pub.titre, style: AppTypography.titreMoyen),
          if (pub.auteurDisplayName != null) ...[
            AppSpacing.vGap12,
            Row(
              children: [
                AppAvatar(
                  name: pub.auteurDisplayName!,
                  photoUrl: pub.auteurPhotoUrl,
                  size: 32,
                ),
                AppSpacing.hGap8,
                Expanded(
                  child: Text(
                    tr('Par {auteur}', {'auteur': pub.auteurDisplayName}),
                    style: AppTypography.texteSecondaire,
                  ),
                ),
              ],
            ),
          ],
          AppSpacing.vGap12,
          Wrap(
            spacing: AppSpacing.s12,
            runSpacing: AppSpacing.s8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (pub.specialiteNom != null)
                PublicationCategoryChip(label: pub.specialiteNom!),
              PublicationMetaRow(publication: pub),
            ],
          ),
          AppSpacing.vGap24,
          Text(
            pub.contenu ?? '',
            style: AppTypography.texte.copyWith(height: 1.6),
          ),
          AppSpacing.vGap32,
        ],
      ),
    );
  }
}
