import 'package:flutter/material.dart';
import '../theme/design_system.dart';
import 'app_back_button.dart';

/// En-tête des pages empilées (maquettes « Mes dossiers », « Mon dossier ») :
/// bouton retour commun, titre centré (comme les AppBar du thème), élément
/// facultatif à droite (avatar), fine ligne de séparation en bas.
///
/// Exemple : `appBar: AppPageHeader(title: 'Mes dossiers', trailing: CurrentUserAvatar())`
class AppPageHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? trailing;
  final Color? color;

  const AppPageHeader({
    super.key,
    required this.title,
    this.trailing,
    this.color,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final titleColor = color ?? palette.textStrong;
    // Même bouton, même hauteur et même titre que les barres AppBar des autres pages.
    return Material(
      color: palette.card,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: preferredSize.height,
          padding: const EdgeInsets.only(right: AppSpacing.s16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: palette.border)),
          ),
          // Même disposition qu'une AppBar : titre centré sur la largeur de l'écran.
          child: NavigationToolbar(
            centerMiddle: true,
            middleSpacing: AppSpacing.s16,
            leading: SizedBox(
              width: kToolbarHeight,
              child: AppBackButton(color: titleColor),
            ),
            middle: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.titrePage.copyWith(color: titleColor),
            ),
            trailing: trailing,
          ),
        ),
      ),
    );
  }
}
