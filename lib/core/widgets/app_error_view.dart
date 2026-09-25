import 'package:flutter/material.dart';
import '../theme/design_system.dart';
import 'app_button.dart';

/// Vue d'erreur avec message et bouton de réessai harmonisée avec le Design System.
class AppErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AppErrorView({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.dangerSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                AppIcons.danger,
                size: 32,
                color: AppColors.danger,
              ),
            ),
            AppSpacing.vGap20,
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.texteMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            if (onRetry != null) ...[
              AppSpacing.vGap24,
              SizedBox(
                width: 170,
                child: AppButton.outline(
                  text: 'Réessayer',
                  onPressed: onRetry,
                  size: AppButtonSize.compact,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
