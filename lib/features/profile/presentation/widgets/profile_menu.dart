import 'package:flutter/material.dart';
import '../../../../core/theme/design_system.dart';

/// Ligne du menu : icône dans un carré bleu clair, libellé, chevron, et une
/// fine ligne de séparation en dessous (maquette « Profil utilisateur »).
class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  /// Valeur courante affichée avant le chevron (« Sombre », « English »…).
  final String? value;

  /// Élément à droite à la place du chevron (interrupteur…).
  final Widget? trailing;

  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: palette.border)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: palette.iconTile,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: palette.onIconTile),
            ),
            AppSpacing.hGap16,
            Expanded(
              child: Text(
                label,
                style: AppTypography.texteMedium.copyWith(
                  fontSize: 15,
                  color: palette.textStrong,
                ),
              ),
            ),
            if (value != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  value!,
                  style: AppTypography.texte.copyWith(
                    fontSize: 14,
                    color: palette.textMuted,
                  ),
                ),
              ),
            trailing ??
                Icon(Icons.chevron_right_rounded, color: palette.textMuted),
          ],
        ),
      ),
    );
  }
}

/// Titre de section dans les sous-pages du profil.
class ProfileSectionTitle extends StatelessWidget {
  final String title;

  const ProfileSectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 4),
      child: Text(
        title,
        style: AppTypography.texteSemiBold.copyWith(
          fontSize: 13,
          color: context.palette.textMuted,
        ),
      ),
    );
  }
}
