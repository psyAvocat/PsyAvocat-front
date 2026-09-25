import 'package:flutter/material.dart';
import '../theme/design_system.dart';
import 'app_button.dart';
import 'app_progress_bar.dart';

/// Vue d'état générique et harmonisée pour PsyAvocat.
class AppFeedbackView extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color? iconBackgroundColor;
  final String title;
  final String? message;
  final String? actionText;
  final VoidCallback? onAction;
  final Widget? customContent;

  const AppFeedbackView({
    super.key,
    required this.icon,
    required this.iconColor,
    this.iconBackgroundColor,
    required this.title,
    this.message,
    this.actionText,
    this.onAction,
    this.customContent,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBg = iconBackgroundColor ?? iconColor.withValues(alpha: 0.1);

    return Center(
      child: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: effectiveBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: AppIcons.sizeXl,
                color: iconColor,
              ),
            ),
            AppSpacing.vGap24,
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.titreMoyen,
            ),
            if (message != null) ...[
              AppSpacing.vGap8,
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: AppTypography.texteSecondaire,
                ),
              ),
            ],
            if (customContent != null) ...[
              AppSpacing.vGap16,
              customContent!,
            ],
            if (actionText != null && onAction != null) ...[
              AppSpacing.vGap24,
              SizedBox(
                width: 200,
                child: AppButton(
                  text: actionText!,
                  onPressed: onAction,
                  color: iconColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Vue d'état de chargement standardisée.
class AppLoadingView extends StatelessWidget {
  final String? message;
  final AppUniverse? universe;

  const AppLoadingView({
    super.key,
    this.message,
    this.universe,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppCircularProgress(
              size: 36,
              strokeWidth: 3.5,
              universe: universe,
            ),
            if (message != null) ...[
              AppSpacing.vGap16,
              Text(
                message!,
                textAlign: TextAlign.center,
                style: AppTypography.texteSecondaire.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Vue d'erreur critique avec possibilité de réessai.
class AppErrorStateView extends StatelessWidget {
  final String title;
  final String message;
  final String retryText;
  final VoidCallback? onRetry;

  const AppErrorStateView({
    super.key,
    this.title = 'Une erreur est survenue',
    required this.message,
    this.retryText = 'Réessayer',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return AppFeedbackView(
      icon: AppIcons.danger,
      iconColor: AppColors.danger,
      iconBackgroundColor: AppColors.dangerSurface,
      title: title,
      message: message,
      actionText: onRetry != null ? retryText : null,
      onAction: onRetry,
    );
  }
}

/// Vue de succès après action réussie.
class AppSuccessStateView extends StatelessWidget {
  final String title;
  final String? message;
  final String? actionText;
  final VoidCallback? onAction;

  const AppSuccessStateView({
    super.key,
    required this.title,
    this.message,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return AppFeedbackView(
      icon: AppIcons.success,
      iconColor: AppColors.success,
      iconBackgroundColor: AppColors.successSurface,
      title: title,
      message: message,
      actionText: actionText,
      onAction: onAction,
    );
  }
}

/// Vue d'avertissement.
class AppWarningStateView extends StatelessWidget {
  final String title;
  final String? message;
  final String? actionText;
  final VoidCallback? onAction;

  const AppWarningStateView({
    super.key,
    required this.title,
    this.message,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return AppFeedbackView(
      icon: AppIcons.warning,
      iconColor: AppColors.warning,
      iconBackgroundColor: AppColors.warningSurface,
      title: title,
      message: message,
      actionText: actionText,
      onAction: onAction,
    );
  }
}

/// Vue vide (aucun contenu à afficher).
class AppEmptyStateView extends StatelessWidget {
  final String title;
  final String? message;
  final String? actionText;
  final VoidCallback? onAction;
  final IconData icon;

  const AppEmptyStateView({
    super.key,
    this.title = 'Aucun élément trouvé',
    this.message,
    this.actionText,
    this.onAction,
    this.icon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return AppFeedbackView(
      icon: icon,
      iconColor: AppColors.textTertiary,
      iconBackgroundColor: AppColors.neutralSurfaceSecondary,
      title: title,
      message: message,
      actionText: actionText,
      onAction: onAction,
    );
  }
}
