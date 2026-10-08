import 'package:flutter/material.dart';
import '../theme/design_system.dart';

/// Phrase grise suivie d'un lien souligné, centrée.
///
/// Exemple : `AppInlineLink(text: 'Pas encore de compte ?', linkText: "S'inscrire", onTap: ...)`
/// affiche « Pas encore de compte ? S'inscrire ».
class AppInlineLink extends StatelessWidget {
  final String text;
  final String linkText;
  final VoidCallback onTap;

  const AppInlineLink({
    super.key,
    required this.text,
    required this.linkText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Wrap : sur un petit écran (ou police agrandie), le lien passe
    // à la ligne au lieu de déborder.
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            '$text ',
            style: AppTypography.texte.copyWith(color: AppColors.formHint),
          ),
          InkWell(
            onTap: onTap,
            child: Text(
              linkText,
              style: AppTypography.texteSemiBold.copyWith(
                color: AppColors.brandPurple,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.brandPurple,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
