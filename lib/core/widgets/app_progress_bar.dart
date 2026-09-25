import 'package:flutter/material.dart';
import '../theme/design_system.dart';

/// Barre de progression linéaire moderne et accessible.
class AppProgressBar extends StatelessWidget {
  /// Valeur entre 0.0 et 1.0 (ou null pour indéterminée)
  final double? value;
  final double height;
  final Color? color;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final String? label;
  final bool showPercentage;
  final AppUniverse? universe;

  const AppProgressBar({
    super.key,
    this.value,
    this.height = 8.0,
    this.color,
    this.backgroundColor,
    this.borderRadius,
    this.label,
    this.showPercentage = false,
    this.universe,
  });

  @override
  Widget build(BuildContext context) {
    final universeColors = universe != null
        ? AppUniverseColors.fromUniverse(universe!)
        : AppTheme.universeOf(context);

    final effectiveColor = color ?? universeColors.primary;
    final effectiveBgColor = backgroundColor ?? effectiveColor.withValues(alpha: 0.12);
    final effectiveRadius = borderRadius ?? AppRadii.pill;

    final progressWidget = ClipRRect(
      borderRadius: effectiveRadius,
      child: SizedBox(
        height: height,
        child: LinearProgressIndicator(
          value: value,
          valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
          backgroundColor: effectiveBgColor,
        ),
      ),
    );

    if (label == null && !showPercentage) {
      return progressWidget;
    }

    final percentText = value != null ? '${(value! * 100).toInt()}%' : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null || showPercentage)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (label != null)
                  Text(
                    label!,
                    style: AppTypography.texteSecondaire.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (showPercentage && value != null)
                  Text(
                    percentText,
                    style: AppTypography.texteSemiBold.copyWith(
                      fontSize: 14,
                      color: effectiveColor,
                    ),
                  ),
              ],
            ),
          ),
        progressWidget,
      ],
    );
  }
}

/// Indicateur circulaire de chargement thématisé.
class AppCircularProgress extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color? color;
  final AppUniverse? universe;

  const AppCircularProgress({
    super.key,
    this.size = 28.0,
    this.strokeWidth = 3.0,
    this.color,
    this.universe,
  });

  @override
  Widget build(BuildContext context) {
    final universeColors = universe != null
        ? AppUniverseColors.fromUniverse(universe!)
        : AppTheme.universeOf(context);

    final effectiveColor = color ?? universeColors.primary;

    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
        backgroundColor: effectiveColor.withValues(alpha: 0.15),
      ),
    );
  }
}
