import 'package:flutter/material.dart';
import '../theme/design_system.dart';
import 'app_button.dart';

/// Dialogue modal officiel du Design System PsyAvocat.
class AppDialog extends StatelessWidget {
  final String title;
  final String message;
  final Widget? content;
  final String primaryActionText;
  final VoidCallback onPrimaryAction;
  final String? secondaryActionText;
  final VoidCallback? onSecondaryAction;
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final bool isDestructive;
  final AppUniverse? universe;

  const AppDialog({
    super.key,
    required this.title,
    required this.message,
    this.content,
    required this.primaryActionText,
    required this.onPrimaryAction,
    this.secondaryActionText,
    this.onSecondaryAction,
    this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    this.isDestructive = false,
    this.universe,
  });

  /// Affiche le dialogue de manière impérative
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required String message,
    Widget? content,
    required String primaryActionText,
    required VoidCallback onPrimaryAction,
    String? secondaryActionText,
    VoidCallback? onSecondaryAction,
    IconData? icon,
    Color? iconColor,
    Color? iconBackgroundColor,
    bool isDestructive = false,
    AppUniverse? universe,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (ctx) => AppDialog(
        title: title,
        message: message,
        content: content,
        primaryActionText: primaryActionText,
        onPrimaryAction: onPrimaryAction,
        secondaryActionText: secondaryActionText,
        onSecondaryAction: onSecondaryAction,
        icon: icon,
        iconColor: iconColor,
        iconBackgroundColor: iconBackgroundColor,
        isDestructive: isDestructive,
        universe: universe,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final universeColors = universe != null
        ? AppUniverseColors.fromUniverse(universe!)
        : AppTheme.universeOf(context);

    final effectiveIconColor = iconColor ??
        (isDestructive ? AppColors.danger : universeColors.primary);
    final effectiveIconBg = iconBackgroundColor ??
        (isDestructive
            ? AppColors.dangerSurface
            : effectiveIconColor.withValues(alpha: 0.1));

    return Dialog(
      backgroundColor: AppColors.neutralSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadii.r20,
      ),
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: AppSpacing.dialogPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (icon != null) ...[
              Center(
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: effectiveIconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: AppIcons.sizeLg,
                    color: effectiveIconColor,
                  ),
                ),
              ),
              AppSpacing.vGap16,
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.petitTitre,
            ),
            AppSpacing.vGap8,
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.texteSecondaire,
            ),
            if (content != null) ...[
              AppSpacing.vGap16,
              content!,
            ],
            AppSpacing.vGap24,
            AppButton(
              text: primaryActionText,
              onPressed: onPrimaryAction,
              color: isDestructive ? AppColors.danger : universeColors.primary,
              universe: universe,
            ),
            if (secondaryActionText != null) ...[
              AppSpacing.vGap12,
              AppButton.outline(
                text: secondaryActionText!,
                onPressed: onSecondaryAction ?? () => Navigator.of(context).pop(),
                universe: universe,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
