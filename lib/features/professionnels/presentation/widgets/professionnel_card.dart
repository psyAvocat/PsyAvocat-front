import 'package:flutter/material.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/widgets/widgets.dart';
import '../../data/models/professionnel_summary.dart';

/// Ligne d'un professionnel — maquettes « Avocats » et « Psychologues » :
/// photo ronde, nom, spécialité, mode de consultation, ville.
///
/// Seules les informations fournies par l'API sont affichées
/// (aucun âge, statut ou ville par défaut).
class ProfessionnelCard extends StatelessWidget {
  final ProfessionnelSummary professionnel;
  final VoidCallback onTap;

  const ProfessionnelCard({
    super.key,
    required this.professionnel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pro = professionnel;
    final details = [
      if (pro.modeConsultationLabel != null) pro.modeConsultationLabel!,
      if (pro.ville != null && pro.ville!.isNotEmpty) pro.ville!,
    ].join(' · ');

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.r16,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppAvatar(name: pro.fullName, photoUrl: pro.photoUrl, size: 64),
            AppSpacing.hGap16,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          pro.displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.texteSemiBold,
                        ),
                      ),
                      // Information réelle du backend (`enLigne`).
                      if (pro.enLigne) ...[
                        AppSpacing.hGap8,
                        const AppBadge.success(label: 'En ligne'),
                      ],
                    ],
                  ),
                  if (pro.specialites.isNotEmpty) ...[
                    AppSpacing.vGap4,
                    Text(
                      pro.specialites.join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.texteSecondaire.copyWith(
                        color: scheme.primary,
                      ),
                    ),
                  ],
                  if (details.isNotEmpty) ...[
                    AppSpacing.vGap4,
                    Text(
                      details,
                      style: AppTypography.miniTexte.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (pro.hasRating) ...[
                    AppSpacing.vGap4,
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: scheme.primary,
                        ),
                        AppSpacing.hGap4,
                        Text(
                          '${pro.noteMoyenne!.toStringAsFixed(1)} (${pro.nombreAvis} avis)',
                          style: AppTypography.miniTexte,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
