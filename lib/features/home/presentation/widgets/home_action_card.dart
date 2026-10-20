import 'package:flutter/material.dart';
import '../../../../core/theme/design_system.dart';

/// Carte d'action rapide de l'accueil (« Voir les professionnels »,
/// « Consulter les conseils »…).
///
/// [highlighted] : fond plein couleur de l'univers (action principale) ;
/// sinon fond clair teinté avec contour (action secondaire).
/// [icon] : pictogramme de l'action, en haut de la carte.
class HomeActionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final bool highlighted;
  final VoidCallback onTap;

  const HomeActionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.subtitle,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = highlighted ? scheme.onPrimary : scheme.primary;

    return Card(
      color: highlighted ? scheme.primary : scheme.secondaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.r16,
        side: highlighted
            ? BorderSide.none
            : BorderSide(color: scheme.primary.withValues(alpha: 0.25)),
      ),
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 120),
          child: Padding(
            padding: AppSpacing.cardPaddingCompact,
            // Pictogramme en haut, libellés en bas (hauteur commune des cartes).
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: highlighted
                            ? scheme.onPrimary.withValues(alpha: 0.16)
                            : scheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, size: 22, color: foreground),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: foreground.withValues(alpha: 0.7),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.s12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.texteSemiBold.copyWith(
                          color: foreground,
                          height: 1.25,
                        ),
                      ),
                      if (subtitle != null) ...[
                        AppSpacing.vGap4,
                        Text(
                          subtitle!,
                          style: AppTypography.miniTexte.copyWith(
                            color: foreground.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
