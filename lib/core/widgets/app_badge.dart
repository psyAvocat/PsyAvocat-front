import 'package:flutter/material.dart';
import '../theme/design_system.dart';

/// Type sémantique du badge.
enum AppBadgeType {
  success,
  warning,
  danger,
  info,
  neutral,
  psychologist,
  lawyer,
}

/// Badge / Étiquette de statut accessible et moderne.
///
/// Respecte les règles d'accessibilité et de contraste :
/// - Fond doux teinté pour ne pas agresser visuellement.
/// - Texte et icônes à fort contraste.
/// - Ne surcharge pas l'interface avec des couleurs vives pures.
class AppBadge extends StatelessWidget {
  final String label;
  final AppBadgeType type;
  final IconData? icon;
  final bool showDot;
  final bool isPill;
  final VoidCallback? onTap;

  const AppBadge({
    super.key,
    required this.label,
    this.type = AppBadgeType.neutral,
    this.icon,
    this.showDot = false,
    this.isPill = true,
    this.onTap,
  });

  /// Constructeur de succès (#4BD418)
  const AppBadge.success({
    super.key,
    required this.label,
    this.icon,
    this.showDot = false,
    this.isPill = true,
    this.onTap,
  }) : type = AppBadgeType.success;

  /// Constructeur d'avertissement (#F2C121)
  const AppBadge.warning({
    super.key,
    required this.label,
    this.icon,
    this.showDot = false,
    this.isPill = true,
    this.onTap,
  }) : type = AppBadgeType.warning;

  /// Constructeur d'erreur critique (#FB1216)
  const AppBadge.danger({
    super.key,
    required this.label,
    this.icon,
    this.showDot = false,
    this.isPill = true,
    this.onTap,
  }) : type = AppBadgeType.danger;

  /// Constructeur pour l'univers Psychologue (#45088E)
  const AppBadge.psychologist({
    super.key,
    required this.label,
    this.icon = Icons.psychology_rounded,
    this.showDot = false,
    this.isPill = true,
    this.onTap,
  }) : type = AppBadgeType.psychologist;

  /// Constructeur pour l'univers Avocat (#0C2659)
  const AppBadge.lawyer({
    super.key,
    required this.label,
    this.icon = Icons.gavel_rounded,
    this.showDot = false,
    this.isPill = true,
    this.onTap,
  }) : type = AppBadgeType.lawyer;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    Color borderColor;

    switch (type) {
      case AppBadgeType.success:
        backgroundColor = AppColors.successSurface;
        textColor = AppColors.successText;
        borderColor = AppColors.successBorder;
        break;
      case AppBadgeType.warning:
        backgroundColor = AppColors.warningSurface;
        textColor = AppColors.warningText;
        borderColor = AppColors.warningBorder;
        break;
      case AppBadgeType.danger:
        backgroundColor = AppColors.dangerSurface;
        textColor = AppColors.dangerText;
        borderColor = AppColors.dangerBorder;
        break;
      case AppBadgeType.info:
      case AppBadgeType.lawyer:
        backgroundColor = AppColors.lawyerSurface;
        textColor = AppColors.lawyer;
        borderColor = AppColors.lawyerBorder;
        break;
      case AppBadgeType.psychologist:
        backgroundColor = AppColors.psychologistSurface;
        textColor = AppColors.psychologist;
        borderColor = AppColors.psychologistBorder;
        break;
      case AppBadgeType.neutral:
        backgroundColor = AppColors.neutralSurfaceSecondary;
        textColor = AppColors.textSecondary;
        borderColor = AppColors.border;
        break;
    }

    final radius = isPill ? AppRadii.pill : AppRadii.r8;

    Widget content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: radius,
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showDot) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: textColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: AppTypography.badgeTexte.copyWith(color: textColor),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: content,
      );
    }

    return content;
  }
}
