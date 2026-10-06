import 'package:flutter/material.dart';
import '../theme/design_system.dart';

/// Grande carte colorée permettant de choisir un univers (Avocat ou Psychologue).
///
/// Contient : une icône dans un carré translucide, une flèche ronde,
/// un cercle décoratif, puis le titre et la description en bas.
///
/// Exemple :
/// ```dart
/// AppUniverseCard(
///   title: 'Avocat',
///   description: 'Conseil juridique et accompagnement',
///   icon: Icons.balance_rounded,
///   gradient: AppColors.lawyerCardGradient,
///   shadowColor: AppColors.lawyer,
///   onTap: () => choose(AppUniverse.lawyer),
/// )
/// ```
class AppUniverseCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Gradient gradient;
  final Color shadowColor;
  final VoidCallback onTap;

  const AppUniverseCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.shadowColor,
    required this.onTap,
  });

  /// Hauteur minimale de la carte dans la maquette.
  static const double _minHeight = 220;

  /// Blanc à ~8 % : fond de l'icône, de la flèche et du cercle décoratif.
  static final Color _translucentWhite = Colors.white.withValues(alpha: 0.08);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: AppRadii.r32,
          boxShadow: AppShadows.universeCard(shadowColor),
        ),
        // Coupe le cercle décoratif qui dépasse de la carte.
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: [
                _buildDecorativeCircle(),
                Padding(
                  padding: AppSpacing.paddingAll24,
                  // Hauteur minimale de la maquette, mais la carte grandit
                  // si le texte est agrandi (accessibilité) : pas d'overflow.
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: _minHeight - 2 * AppSpacing.s24,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildTopRow(),
                          AppSpacing.vGap24,
                          _buildTexts(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Titre et description, en bas de la carte.
  Widget _buildTexts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.titreMoyen.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.textOnColor,
          ),
        ),
        AppSpacing.vGap4,
        Text(
          description,
          style: AppTypography.texte.copyWith(
            fontSize: 15,
            color: AppColors.textOnColor.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }

  /// Icône de l'univers à gauche, flèche ronde à droite.
  Widget _buildTopRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: _translucentWhite,
            borderRadius: AppRadii.r16,
          ),
          child: Icon(
            icon,
            color: AppColors.textOnColor,
            size: AppIcons.sizeLg,
          ),
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _translucentWhite,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textOnColor,
            size: AppIcons.sizeMd,
          ),
        ),
      ],
    );
  }

  /// Grand cercle translucide qui dépasse en bas à droite de la carte.
  Widget _buildDecorativeCircle() {
    return Positioned(
      right: -60,
      bottom: -60,
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: _translucentWhite,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
