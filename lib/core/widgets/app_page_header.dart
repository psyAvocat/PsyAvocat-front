import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router/app_routes.dart';
import '../theme/design_system.dart';
import '../../core/l10n/app_strings.dart';

/// En-tête des pages empilées (maquettes « Mes dossiers », « Mon dossier ») :
/// bouton retour rond, titre à gauche, élément facultatif à droite (avatar),
/// fine ligne de séparation en bas.
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
  Size get preferredSize => const Size.fromHeight(72);

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleColor = color ?? context.colors.primary;
    final palette = context.palette;
    return Material(
      color: palette.card,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: preferredSize.height,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: palette.border)),
          ),
          child: Row(
            children: [
              Semantics(
                button: true,
                label: tr('Retour'),
                child: InkWell(
                  onTap: () => _back(context),
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: palette.borderStrong),
                    ),
                    child: Icon(
                      Icons.chevron_left_rounded,
                      size: 22,
                      color: titleColor,
                    ),
                  ),
                ),
              ),
              AppSpacing.hGap16,
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titreMoyen.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}
