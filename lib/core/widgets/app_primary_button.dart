import 'package:flutter/material.dart';
import '../theme/design_system.dart';

/// Bouton principal pleine largeur, basé sur [FilledButton] (Material 3).
///
/// - Couleur : `colorScheme.primary` de l'univers actif (via le thème).
/// - [isLoading] : affiche un indicateur et bloque les taps sans changer la couleur.
/// - [onPressed] `null` : bouton désactivé (gris).
/// - [trailingIcon] : icône dans une pastille à droite du texte (ex. « Continuer → »).
///
/// Exemple : `AppPrimaryButton(label: 'Suivant', onPressed: _next)`
class AppPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? trailingIcon;
  final double height;

  /// Couleur de fond forcée. À n'utiliser que sur un écran dont le contexte
  /// n'est pas l'univers actif (ex. page Psychologue de l'onboarding).
  final Color? backgroundColor;

  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.trailingIcon,
    this.height = AppButtonSizes.heightLarge,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: FilledButton(
        // Pendant le chargement, on garde la couleur mais on ignore les taps.
        onPressed: onPressed == null ? null : (isLoading ? () {} : onPressed),
        style: backgroundColor == null
            ? null
            : FilledButton.styleFrom(backgroundColor: backgroundColor),
        child: _ButtonContent(
          label: label,
          isLoading: isLoading,
          trailingIcon: trailingIcon,
        ),
      ),
    );
  }
}

/// Bouton principal en dégradé violet → bleu.
///
/// Réservé aux écrans dont la maquette prévoit explicitement ce dégradé
/// (connexion, inscription). Partout ailleurs, utiliser [AppPrimaryButton].
class AppGradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const AppGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadii.pill,
        gradient: isEnabled ? AppColors.brandGradient : null,
        color: isEnabled ? null : AppColors.buttonDisabledBackground,
        boxShadow: isEnabled ? AppShadows.brandButton : null,
      ),
      child: SizedBox(
        width: double.infinity,
        height: AppButtonSizes.heightPill,
        child: FilledButton(
          onPressed: isEnabled ? (isLoading ? () {} : onPressed) : null,
          style: FilledButton.styleFrom(
            // Le fond est porté par le dégradé ci-dessus.
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: AppColors.textOnColor,
          ),
          child: _ButtonContent(label: label, isLoading: isLoading),
        ),
      ),
    );
  }
}

/// Texte (ou indicateur de chargement) commun aux boutons principaux.
class _ButtonContent extends StatelessWidget {
  final String label;
  final bool isLoading;
  final IconData? trailingIcon;

  const _ButtonContent({
    required this.label,
    required this.isLoading,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox.square(
        dimension: AppButtonSizes.loaderSizeDefault,
        child: CircularProgressIndicator(
          strokeWidth: AppButtonSizes.loaderStrokeWidth,
          color: AppColors.textOnColor,
        ),
      );
    }

    final text = Flexible(
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.buttonText.copyWith(fontSize: 18),
      ),
    );

    if (trailingIcon == null) {
      return Row(mainAxisSize: MainAxisSize.min, children: [text]);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        text,
        AppSpacing.hGap12,
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.textOnColor.withValues(alpha: 0.2),
          ),
          child: Icon(trailingIcon, size: AppIcons.sizeSm),
        ),
      ],
    );
  }
}
