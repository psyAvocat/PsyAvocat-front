import 'package:flutter/material.dart';
import '../theme/design_system.dart';

/// Type d'alerte.
enum AppAlertType {
  info,
  success,
  warning,
  danger,
}

/// Bannière d'alerte en ligne pour retours contextuels.
class AppAlertBanner extends StatelessWidget {
  final String message;
  final String? title;
  final AppAlertType type;
  final VoidCallback? onClose;
  final Widget? action;

  const AppAlertBanner({
    super.key,
    required this.message,
    this.title,
    this.type = AppAlertType.info,
    this.onClose,
    this.action,
  });

  const AppAlertBanner.success({
    super.key,
    required this.message,
    this.title,
    this.onClose,
    this.action,
  }) : type = AppAlertType.success;

  const AppAlertBanner.warning({
    super.key,
    required this.message,
    this.title,
    this.onClose,
    this.action,
  }) : type = AppAlertType.warning;

  const AppAlertBanner.danger({
    super.key,
    required this.message,
    this.title,
    this.onClose,
    this.action,
  }) : type = AppAlertType.danger;

  @override
  Widget build(BuildContext context) {
    Color surfaceColor;
    Color borderColor;
    Color textColor;
    IconData iconData;

    switch (type) {
      case AppAlertType.success:
        surfaceColor = AppColors.successSurface;
        borderColor = AppColors.successBorder;
        textColor = AppColors.successText;
        iconData = AppIcons.success;
        break;
      case AppAlertType.warning:
        surfaceColor = AppColors.warningSurface;
        borderColor = AppColors.warningBorder;
        textColor = AppColors.warningText;
        iconData = AppIcons.warning;
        break;
      case AppAlertType.danger:
        surfaceColor = AppColors.dangerSurface;
        borderColor = AppColors.dangerBorder;
        textColor = AppColors.dangerText;
        iconData = AppIcons.danger;
        break;
      case AppAlertType.info:
        surfaceColor = AppColors.lawyerSurface;
        borderColor = AppColors.lawyerBorder;
        textColor = AppColors.lawyer;
        iconData = AppIcons.info;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: AppRadii.r12,
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(iconData, size: 20, color: textColor),
          AppSpacing.hGap12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: AppTypography.texteSemiBold.copyWith(
                      fontSize: 14,
                      color: textColor,
                    ),
                  ),
                  AppSpacing.vGap4,
                ],
                Text(
                  message,
                  style: AppTypography.texteSecondaire.copyWith(
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
                if (action != null) ...[
                  AppSpacing.vGap8,
                  action!,
                ],
              ],
            ),
          ),
          if (onClose != null) ...[
            AppSpacing.hGap8,
            GestureDetector(
              onTap: onClose,
              child: Icon(Icons.close_rounded, size: 18, color: textColor),
            ),
          ],
        ],
      ),
    );
  }
}

/// Utilitaires pour afficher des notifications SnackBar conformes au Design System.
class AppNotification {
  AppNotification._();

  static void showSuccess(BuildContext context, String message) {
    _showSnackBar(
      context: context,
      message: message,
      backgroundColor: AppColors.success,
      icon: AppIcons.success,
    );
  }

  static void showError(BuildContext context, String message) {
    _showSnackBar(
      context: context,
      message: message,
      backgroundColor: AppColors.danger,
      icon: AppIcons.danger,
    );
  }

  static void showWarning(BuildContext context, String message) {
    _showSnackBar(
      context: context,
      message: message,
      backgroundColor: AppColors.warning,
      icon: AppIcons.warning,
      textColor: AppColors.textPrimary,
    );
  }

  static void showInfo(BuildContext context, String message, {AppUniverse? universe}) {
    final universeColors = universe != null
        ? AppUniverseColors.fromUniverse(universe)
        : AppTheme.universeOf(context);

    _showSnackBar(
      context: context,
      message: message,
      backgroundColor: universeColors.primary,
      icon: AppIcons.info,
    );
  }

  static void _showSnackBar({
    required BuildContext context,
    required String message,
    required Color backgroundColor,
    required IconData icon,
    Color textColor = AppColors.buttonText,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: AppRadii.r12,
            boxShadow: AppShadows.card,
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: textColor),
              AppSpacing.hGap12,
              Expanded(
                child: Text(
                  message,
                  style: AppTypography.texteMedium.copyWith(
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
