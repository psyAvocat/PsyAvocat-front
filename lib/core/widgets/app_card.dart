import 'package:flutter/material.dart';
import '../theme/design_system.dart';

/// Style visuel de la carte.
enum AppCardVariant {
  /// Fond blanc neutre avec bordure subtile
  elevated,
  /// Fond neutre avec bordure fine sans ombre
  outlined,
  /// Fond teinté dans la nuance claire de l'univers
  tinted,
  /// Carte avec gradient de transition ou gradient d'univers
  gradient,
}

/// Carte réutilisable du Design System PsyAvocat.
///
/// Intègre :
/// - Coins arrondis modernes (16 px ou 20 px).
/// - Marges intérieures généreuses (20 px).
/// - Ombres légères douces non intrusives.
/// - Variantes adaptée à l'univers (fond teinté, bordure subtile).
/// - Support tactile `onTap` avec effet ripple.
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final AppCardVariant variant;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;
  final AppUniverse? universe;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool hasShadow;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.variant = AppCardVariant.outlined,
    this.padding = AppSpacing.cardPadding,
    this.borderRadius,
    this.universe,
    this.backgroundColor,
    this.borderColor,
    this.hasShadow = false,
  });

  /// Constructeur de commodité pour carte teintée dans l'univers
  const AppCard.tinted({
    super.key,
    required this.child,
    this.onTap,
    this.padding = AppSpacing.cardPadding,
    this.borderRadius,
    this.universe,
    this.hasShadow = false,
  })  : variant = AppCardVariant.tinted,
        backgroundColor = null,
        borderColor = null;

  /// Constructeur de commodité pour carte en dégradé d'univers (transition #0C2659 → #45088E)
  const AppCard.gradient({
    super.key,
    required this.child,
    this.onTap,
    this.padding = AppSpacing.cardPadding,
    this.borderRadius,
    this.universe,
    this.hasShadow = true,
  })  : variant = AppCardVariant.gradient,
        backgroundColor = null,
        borderColor = null;

  @override
  Widget build(BuildContext context) {
    final universeColors = universe != null
        ? AppUniverseColors.fromUniverse(universe!)
        : AppTheme.universeOf(context);

    final effectiveRadius = borderRadius ?? AppRadii.r16;

    Color? effectiveBgColor;
    Gradient? effectiveGradient;
    Border? effectiveBorder;
    List<BoxShadow> effectiveShadows = AppShadows.none;

    switch (variant) {
      case AppCardVariant.elevated:
        effectiveBgColor = backgroundColor ?? AppColors.neutralSurface;
        effectiveBorder = Border.all(color: borderColor ?? AppColors.border, width: 1);
        effectiveShadows = AppShadows.card;
        break;

      case AppCardVariant.outlined:
        effectiveBgColor = backgroundColor ?? AppColors.neutralSurface;
        effectiveBorder = Border.all(color: borderColor ?? AppColors.border, width: 1);
        if (hasShadow) effectiveShadows = AppShadows.subtle;
        break;

      case AppCardVariant.tinted:
        effectiveBgColor = backgroundColor ?? universeColors.surface;
        effectiveBorder = Border.all(
          color: borderColor ?? universeColors.border.withValues(alpha: 0.6),
          width: 1,
        );
        if (hasShadow) effectiveShadows = AppShadows.subtle;
        break;

      case AppCardVariant.gradient:
        effectiveGradient = universeColors.gradient;
        effectiveBorder = null;
        if (hasShadow) {
          effectiveShadows = AppShadows.buttonUniverse(universeColors.primary);
        }
        break;
    }

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveBgColor,
        gradient: effectiveGradient,
        borderRadius: effectiveRadius,
        border: effectiveBorder,
        boxShadow: effectiveShadows,
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: effectiveRadius,
          splashColor: universeColors.primary.withValues(alpha: 0.08),
          highlightColor: universeColors.primary.withValues(alpha: 0.04),
          child: content,
        ),
      );
    }

    return content;
  }
}
