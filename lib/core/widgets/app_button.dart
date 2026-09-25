import 'package:flutter/material.dart';
import '../theme/design_system.dart';

/// Variantes de style pour les boutons PsyAvocat.
enum AppButtonVariant {
  primary,
  secondary,
  outline,
  ghost,
}

/// Tailles de boutons PsyAvocat.
enum AppButtonSize {
  compact,
  standard,
  large,
}

/// Bouton principal et réutilisable de PsyAvocat.
///
/// Respecte scrupuleusement les spécifications :
/// - Hauteur cohérente sur toute l'application (52 px par défaut).
/// - Texte toujours blanc (#FFFFFF) pour les boutons colorés.
/// - Coins arrondis modernes (16 px).
/// - États normal, pressed, disabled et loading.
/// - Ombre légère uniquement lorsque demandée (`hasShadow`).
/// - Support des univers (Psychologue, Avocat, Transition gradient).
class AppButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final Widget? customIcon;
  final bool isTrailingIcon;
  final Color? color;
  final Color? textColor;
  final bool isFullWidth;
  final bool hasShadow;
  final AppUniverse? universe;
  final BorderRadius? borderRadius;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.standard,
    this.icon,
    this.customIcon,
    this.isTrailingIcon = false,
    this.color,
    this.textColor,
    this.isFullWidth = true,
    this.hasShadow = false,
    this.universe,
    this.borderRadius,
  });

  /// Constructeur de commodité pour bouton secondaire teinté
  const AppButton.secondary({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.size = AppButtonSize.standard,
    this.icon,
    this.customIcon,
    this.isTrailingIcon = false,
    this.color,
    this.textColor,
    this.isFullWidth = true,
    this.universe,
    this.borderRadius,
  })  : isOutlined = false,
        variant = AppButtonVariant.secondary,
        hasShadow = false;

  /// Constructeur de commodité pour bouton avec contour (Outlined)
  const AppButton.outline({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.size = AppButtonSize.standard,
    this.icon,
    this.customIcon,
    this.isTrailingIcon = false,
    this.color,
    this.textColor,
    this.isFullWidth = true,
    this.universe,
    this.borderRadius,
  })  : isOutlined = true,
        variant = AppButtonVariant.outline,
        hasShadow = false;

  /// Constructeur de commodité pour bouton textuel discret (Ghost)
  const AppButton.ghost({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.size = AppButtonSize.standard,
    this.icon,
    this.customIcon,
    this.isTrailingIcon = false,
    this.color,
    this.textColor,
    this.isFullWidth = false,
    this.universe,
    this.borderRadius,
  })  : isOutlined = false,
        variant = AppButtonVariant.ghost,
        hasShadow = false;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isPressed = false;

  double get _height {
    switch (widget.size) {
      case AppButtonSize.compact:
        return AppButtonSizes.heightCompact;
      case AppButtonSize.standard:
        return AppButtonSizes.heightDefault;
      case AppButtonSize.large:
        return AppButtonSizes.heightLarge;
    }
  }

  double get _loaderSize {
    switch (widget.size) {
      case AppButtonSize.compact:
        return AppButtonSizes.loaderSizeCompact;
      case AppButtonSize.standard:
      case AppButtonSize.large:
        return AppButtonSizes.loaderSizeDefault;
    }
  }

  TextStyle _getTextStyle(Color effectiveTextColor) {
    switch (widget.size) {
      case AppButtonSize.compact:
        return AppTypography.buttonTextSmall.copyWith(color: effectiveTextColor);
      case AppButtonSize.standard:
      case AppButtonSize.large:
        return AppTypography.buttonText.copyWith(color: effectiveTextColor);
    }
  }

  @override
  Widget build(BuildContext context) {
    final universeColors = widget.universe != null
        ? AppUniverseColors.fromUniverse(widget.universe!)
        : AppTheme.universeOf(context);

    final isEffectiveOutlined = widget.isOutlined || widget.variant == AppButtonVariant.outline;
    final isSecondary = widget.variant == AppButtonVariant.secondary;
    final isGhost = widget.variant == AppButtonVariant.ghost;

    final primaryColor = widget.color ?? universeColors.primary;
    final isDisabled = widget.onPressed == null || widget.isLoading;

    // Détermination de la couleur de fond
    Color backgroundColor;
    Color effectiveTextColor;
    Border? border;

    if (isDisabled) {
      if (isEffectiveOutlined || isGhost) {
        backgroundColor = Colors.transparent;
        effectiveTextColor = AppColors.buttonDisabledText;
        border = isEffectiveOutlined ? Border.all(color: AppColors.border, width: 1.2) : null;
      } else if (isSecondary) {
        backgroundColor = AppColors.neutralSurfaceSecondary;
        effectiveTextColor = AppColors.buttonDisabledText;
        border = null;
      } else {
        backgroundColor = AppColors.buttonDisabledBackground;
        effectiveTextColor = AppColors.buttonDisabledText;
        border = null;
      }
    } else {
      if (isEffectiveOutlined) {
        backgroundColor = _isPressed
            ? primaryColor.withValues(alpha: 0.08)
            : Colors.transparent;
        effectiveTextColor = widget.textColor ?? primaryColor;
        border = Border.all(color: primaryColor, width: 1.5);
      } else if (isSecondary) {
        backgroundColor = _isPressed
            ? universeColors.surfaceSelected
            : universeColors.surface;
        effectiveTextColor = widget.textColor ?? primaryColor;
        border = Border.all(color: universeColors.border.withValues(alpha: 0.5), width: 1);
      } else if (isGhost) {
        backgroundColor = _isPressed
            ? primaryColor.withValues(alpha: 0.08)
            : Colors.transparent;
        effectiveTextColor = widget.textColor ?? primaryColor;
        border = null;
      } else {
        // Bouton principal coloré : texte TOUJOURS blanc #FFFFFF
        backgroundColor = _isPressed
            ? Color.lerp(primaryColor, Colors.black, 0.12)!
            : primaryColor;
        effectiveTextColor = widget.textColor ?? AppColors.buttonText;
        border = null;
      }
    }

    final radius = widget.borderRadius ?? AppRadii.r16;

    // Ombre légère uniquement lorsque nécessaire
    final List<BoxShadow> boxShadows = (!isDisabled && widget.hasShadow && !isEffectiveOutlined && !isGhost)
        ? AppShadows.buttonUniverse(primaryColor)
        : AppShadows.none;

    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: _height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: radius,
        border: border,
        boxShadow: boxShadows,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: widget.size == AppButtonSize.compact ? 16 : 24,
      ),
      child: Center(
        child: widget.isLoading
            ? SizedBox(
                height: _loaderSize,
                width: _loaderSize,
                child: CircularProgressIndicator(
                  strokeWidth: AppButtonSizes.loaderStrokeWidth,
                  valueColor: AlwaysStoppedAnimation<Color>(effectiveTextColor),
                ),
              )
            : _buildContent(context, effectiveTextColor),
      ),
    );

    if (widget.isFullWidth) {
      content = SizedBox(width: double.infinity, child: content);
    }

    return Semantics(
      button: true,
      enabled: !isDisabled,
      label: widget.text,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : widget.onPressed,
          onHighlightChanged: (pressed) {
            if (!isDisabled && mounted) {
              setState(() => _isPressed = pressed);
            }
          },
          borderRadius: radius,
          splashColor: effectiveTextColor.withValues(alpha: 0.12),
          highlightColor: Colors.transparent,
          child: content,
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Color textColor) {
    final textWidget = Text(
      widget.text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: _getTextStyle(textColor),
    );

    final iconWidget = widget.customIcon ??
        (widget.icon != null
            ? Icon(
                widget.icon,
                size: widget.size == AppButtonSize.compact
                    ? AppButtonSizes.iconSizeCompact
                    : AppButtonSizes.iconSizeDefault,
                color: textColor,
              )
            : null);

    if (iconWidget == null) {
      return textWidget;
    }

    if (widget.isTrailingIcon) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          textWidget,
          const SizedBox(width: AppButtonSizes.iconGap),
          iconWidget,
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        iconWidget,
        const SizedBox(width: AppButtonSizes.iconGap),
        textWidget,
      ],
    );
  }
}

/// Bouton secondaire dédié (commodité)
class AppSecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool isFullWidth;
  final AppUniverse? universe;
  final AppButtonSize size;

  const AppSecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.isFullWidth = true,
    this.universe,
    this.size = AppButtonSize.standard,
  });

  @override
  Widget build(BuildContext context) {
    return AppButton.secondary(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: icon,
      isFullWidth: isFullWidth,
      universe: universe,
      size: size,
    );
  }
}
