import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/design_system.dart';

/// Logo « G » de Google (quatre couleurs officielles).
const _logoGoogle = '''
<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/>
  <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/>
  <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.06H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.94l2.85-2.22.81-.63z" fill="#FBBC05"/>
  <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.66 2.84c.87-2.6 3.3-4.52 6.16-4.52z" fill="#EA4335"/>
</svg>
''';

/// Bouton « Continuer avec Google » (connexion et inscription), précédé d'un
/// séparateur « ou » quand [avecSeparateur] est vrai. [compact] : version
/// resserrée pour les écrans peu hauts.
class BoutonGoogle extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool avecSeparateur;
  final bool compact;

  const BoutonGoogle({
    super.key,
    required this.onPressed,
    this.avecSeparateur = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final bouton = SizedBox(
      width: double.infinity,
      height: compact ? 46 : 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: palette.card,
          foregroundColor: palette.textStrong,
          side: BorderSide(color: palette.borderStrong),
          shape: const StadiumBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.string(_logoGoogle, width: 20, height: 20),
            AppSpacing.hGap12,
            // Petits écrans, grande taille de texte : libellé raccourci, jamais de débordement.
            Flexible(
              child: Text(
                tr('Continuer avec Google'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.texteSemiBold.copyWith(
                  color: palette.textStrong,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (!avecSeparateur) return bouton;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: palette.border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
              child: Text(tr('ou'), style: AppTypography.texteSecondaire),
            ),
            Expanded(child: Divider(color: palette.border)),
          ],
        ),
        compact ? AppSpacing.vGap8 : AppSpacing.vGap16,
        bouton,
      ],
    );
  }
}
