import 'package:flutter/material.dart';
import '../../../../core/theme/design_system.dart';
import '../../data/models/contenu_model.dart';
import 'publication_image.dart';
import 'publication_meta.dart';

/// Carte horizontale d'une publication (maquettes « Articles » et « Conseils ») :
/// image à gauche, catégorie, titre, auteur, résumé, date et temps de lecture.
class PublicationListCard extends StatelessWidget {
  final Publication publication;
  final VoidCallback onTap;

  const PublicationListCard({
    super.key,
    required this.publication,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pub = publication;

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: AppSpacing.paddingAll12,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PublicationImage(imageUrl: pub.imageUrl, width: 96, height: 104),
              AppSpacing.hGap12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (pub.specialiteNom != null) ...[
                      PublicationCategoryChip(label: pub.specialiteNom!),
                      AppSpacing.vGap8,
                    ],
                    Text(
                      pub.titre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.texteSemiBold.copyWith(height: 1.25),
                    ),
                    if (pub.auteurDisplayName != null) ...[
                      AppSpacing.vGap4,
                      Text(
                        'Par ${pub.auteurDisplayName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.miniTexte.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (pub.description != null &&
                        pub.description!.isNotEmpty) ...[
                      AppSpacing.vGap4,
                      Text(
                        pub.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.miniTexte.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    AppSpacing.vGap8,
                    PublicationMetaRow(publication: pub),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// Carte « à la une » (maquette « Accueil » : Articles / Conseils populaires) :
/// image en haut, catégorie posée dessus, titre, résumé et temps de lecture.
class PublicationFeatureCard extends StatelessWidget {
  final Publication publication;
  final VoidCallback onTap;

  const PublicationFeatureCard({
    super.key,
    required this.publication,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pub = publication;

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                PublicationImage(
                  imageUrl: pub.imageUrl,
                  height: 140,
                  width: double.infinity,
                  borderRadius: BorderRadius.zero,
                ),
                if (pub.specialiteNom != null)
                  Positioned(
                    left: AppSpacing.s12,
                    bottom: AppSpacing.s8,
                    child: PublicationCategoryChip(label: pub.specialiteNom!),
                  ),
              ],
            ),
            Padding(
              padding: AppSpacing.cardPaddingCompact,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          pub.titre,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.texteSemiBold,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: scheme.onSurface,
                      ),
                    ],
                  ),
                  if (pub.description != null &&
                      pub.description!.isNotEmpty) ...[
                    AppSpacing.vGap4,
                    Text(
                      pub.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.miniTexte.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  AppSpacing.vGap8,
                  PublicationMetaRow(publication: pub, showDate: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
