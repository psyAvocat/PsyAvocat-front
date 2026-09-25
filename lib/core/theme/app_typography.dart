import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Système typographique officiel de PsyAvocat.
///
/// Police principale : Montserrat.
///
/// Échelle demandée :
/// - Grand titre : 32 px, Bold (FontWeight.w700)
/// - Titre moyen : 24 px, SemiBold (FontWeight.w600)
/// - Petit titre : 20 px, SemiBold (FontWeight.w600)
/// - Texte : 16 px, Regular (FontWeight.w400)
/// - Mini texte : 12 px, Regular (FontWeight.w400)
class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Montserrat';

  // ===========================================================================
  // CONSTANTES DE STYLES DE BASE (Montserrat)
  // ===========================================================================

  /// Grand titre : 32 px, Bold
  static TextStyle get grandTitre => GoogleFonts.montserrat(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.5,
        color: AppColors.textPrimary,
      );

  /// Titre moyen : 24 px, SemiBold
  static TextStyle get titreMoyen => GoogleFonts.montserrat(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: -0.2,
        color: AppColors.textPrimary,
      );

  /// Petit titre : 20 px, SemiBold
  static TextStyle get petitTitre => GoogleFonts.montserrat(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: AppColors.textPrimary,
      );

  /// Texte standard : 16 px, Regular
  static TextStyle get texte => GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textPrimary,
      );

  /// Variante Texte Medium : 16 px, Medium
  static TextStyle get texteMedium => GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.5,
        color: AppColors.textPrimary,
      );

  /// Variante Texte SemiBold : 16 px, SemiBold
  static TextStyle get texteSemiBold => GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.5,
        color: AppColors.textPrimary,
      );

  /// Texte d'appoint / description : 14 px, Regular
  static TextStyle get texteSecondaire => GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: AppColors.textSecondary,
      );

  /// Texte d'appoint SemiBold : 14 px, SemiBold (utilisé pour les labels de champs)
  static TextStyle get labelInput => GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.textPrimary,
      );

  /// Mini texte : 12 px, Regular
  static TextStyle get miniTexte => GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: AppColors.textSecondary,
      );

  /// Mini texte SemiBold : 12 px, SemiBold (pour les badges et étiquettes)
  static TextStyle get badgeTexte => GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: 0.3,
      );

  /// Style de texte pour les boutons : 16 px, SemiBold, texte blanc #FFFFFF
  static TextStyle get buttonText => GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: AppColors.buttonText,
      );

  /// Style de texte pour les petits boutons : 14 px, SemiBold
  static TextStyle get buttonTextSmall => GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: AppColors.buttonText,
      );

  // ===========================================================================
  // FLUTTER TEXT THEME
  // ===========================================================================
  static TextTheme createTextTheme([Color textColor = AppColors.textPrimary]) {
    final base = GoogleFonts.montserratTextTheme();

    return base.copyWith(
      displayLarge: grandTitre.copyWith(color: textColor),
      displayMedium: grandTitre.copyWith(fontSize: 28, color: textColor),
      headlineLarge: grandTitre.copyWith(color: textColor),
      headlineMedium: titreMoyen.copyWith(color: textColor),
      headlineSmall: petitTitre.copyWith(color: textColor),
      titleLarge: titreMoyen.copyWith(color: textColor),
      titleMedium: petitTitre.copyWith(color: textColor),
      titleSmall: texteSemiBold.copyWith(fontSize: 15, color: textColor),
      bodyLarge: texte.copyWith(color: textColor),
      bodyMedium: texte.copyWith(fontSize: 14, color: textColor),
      bodySmall: miniTexte.copyWith(color: textColor.withValues(alpha: 0.8)),
      labelLarge: buttonText,
      labelMedium: labelInput.copyWith(color: textColor),
      labelSmall: badgeTexte,
    );
  }
}
