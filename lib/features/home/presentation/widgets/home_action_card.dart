import 'package:flutter/material.dart';
import '../../../../core/theme/design_system.dart';

/// Carte d'action rapide de l'accueil (« Voir les professionnels »,
/// « Consulter les conseils »…).
///
/// [highlighted] : fond plein couleur de l'univers (action principale) ;
/// sinon fond clair teinté avec contour (action secondaire).
class HomeActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool highlighted;
  final VoidCallback onTap;

  const HomeActionCard({
    super.key,
    required this.icon,
    required this.title,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: foreground, size: AppIcons.sizeLg),
                AppSpacing.vGap16,
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.texteSemiBold.copyWith(
                          color: foreground,
                          height: 1.25,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: foreground,
                      size: 20,
                    ),
                  ],
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
        ),
      ),
    );
  }
}
