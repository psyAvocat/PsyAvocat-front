import 'package:flutter/material.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/widgets/widgets.dart';
import '../../data/models/professionnel_summary.dart';

/// Carte d'un professionnel : photo, nom, spécialités, ville, note, mode.
/// Les informations absentes de l'API ne sont simplement pas affichées.
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

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: AppSpacing.cardPaddingCompact,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppAvatar(name: pro.fullName, photoUrl: pro.photoUrl),
              AppSpacing.hGap16,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pro.fullName,
                      style: AppTypography.texteSemiBold,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (pro.specialites.isNotEmpty) ...[
                      AppSpacing.vGap4,
                      Text(
                        pro.specialites.join(' · '),
                        style: AppTypography.texteSecondaire.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    AppSpacing.vGap8,
                    // Wrap : les informations passent à la ligne au lieu de déborder.
                    Wrap(
                      spacing: AppSpacing.s12,
                      runSpacing: AppSpacing.s4,
                      children: [
                        if (pro.ville != null && pro.ville!.isNotEmpty)
                          _Info(icon: Icons.place_outlined, text: pro.ville!),
                        if (pro.hasRating)
                          _Info(
                            icon: Icons.star_rounded,
                            text:
                                '${pro.noteMoyenne!.toStringAsFixed(1)} (${pro.nombreAvis} avis)',
                          ),
                        if (pro.modeConsultationLabel != null)
                          _Info(
                            icon: Icons.videocam_outlined,
                            text: pro.modeConsultationLabel!,
                          ),
                      ],
                    ),
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

class _Info extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Info({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppIcons.sizeXs + 2, color: color),
        AppSpacing.hGap4,
        Flexible(
          child: Text(
            text,
            style: AppTypography.miniTexte.copyWith(color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
