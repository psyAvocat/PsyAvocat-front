import 'package:flutter/material.dart';
import '../theme/design_system.dart';

/// Ligne de séparation horizontale, avec un texte optionnel au centre.
///
/// Exemples :
/// - `const AppTextDivider()` : simple ligne ;
/// - `const AppTextDivider(label: 'CONTINUE AVEC')` : ligne — texte — ligne.
class AppTextDivider extends StatelessWidget {
  final String? label;

  const AppTextDivider({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    const line = Expanded(
      child: Divider(color: AppColors.formDivider, thickness: 1),
    );

    if (label == null) {
      return const Row(children: [line]);
    }

    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
          child: Text(
            label!,
            style: AppTypography.miniTexte.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
        line,
      ],
    );
  }
}
