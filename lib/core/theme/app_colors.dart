import 'package:flutter/material.dart';

/// Palette officielle du Design System PsyAvocat.
///
/// Respecte scrupuleusement les codes couleurs de la marque :
/// - Univers Psychologue : #522578 (et ses nuances douces)
/// - Univers Avocat : #0C2659 (et ses nuances douces)
/// - Texte principal : #383636 (évite le noir pur #000000 pour un confort de lecture optimal)
/// - Validation / succès : #4BD418
/// - Avertissement : #F2C121
/// - Danger / erreur critique : #FB1216
/// - Boutons : texte blanc #FFFFFF
/// - Gradient d'avant-entrée : #0C2659 → #522578
class AppColors {
  AppColors._();

  // ===========================================================================
  // UNIVERS PSYCHOLOGUE (#522578)
  // ===========================================================================
  /// Couleur officielle de l'univers Psychologue. Toutes les nuances
  /// ci-dessous sont dérivées de cette teinte (même famille violet prune).
  static const Color psychologist = Color(0xFF522578);
  static const Color psychologistDark = Color(0xFF3A1A56);
  static const Color psychologistLight = Color(0xFF6E3A9C);
  static const Color psychologistSecondary = Color(0xFF8A5BB5);

  /// Nuances claires de l'univers Psychologue (fonds, cartes, surfaces d'accent)
  static const Color psychologistSurface = Color(0xFFF6F1FA);
  static const Color psychologistSurfaceSelected = Color(0xFFEADDF3);
  static const Color psychologistBorder = Color(0xFFD4BFE6);

  // ===========================================================================
  // UNIVERS AVOCAT (#0C2659)
  // ===========================================================================
  static const Color lawyer = Color(0xFF0C2659);
  static const Color lawyerDark = Color(0xFF07193C);
  static const Color lawyerLight = Color(0xFF1B418E);
  static const Color lawyerSecondary = Color(0xFF2C5BB8);

  /// Nuances claires de l'univers Avocat (fonds, cartes, surfaces d'accent)
  static const Color lawyerSurface = Color(0xFFEFF4FB);
  static const Color lawyerSurfaceSelected = Color(0xFFD9E6F7);
  static const Color lawyerBorder = Color(0xFFB5CEF0);

  // ===========================================================================
  // TYPOGRAPHIE ET TEXTES (Pas de noir pur)
  // ===========================================================================
  /// Texte principal : #383636
  static const Color textPrimary = Color(0xFF383636);

  /// Texte secondaire pour sous-titres et métadonnées
  static const Color textSecondary = Color(0xFF676464);

  /// Texte tertiaire pour les placeholders et textes discrets
  static const Color textTertiary = Color(0xFF989494);

  /// Texte blanc (#FFFFFF) pour les boutons colorés ou fonds sombres
  static const Color textOnColor = Color(0xFFFFFFFF);

  // ===========================================================================
  // ÉTATS FONCTIONNELS ET RETOURS (Succès, Avertissement, Danger)
  // Ne pas utiliser comme couleurs décoratives principales.
  // ===========================================================================
  /// Validation / Succès : #4BD418
  static const Color success = Color(0xFF4BD418);
  static const Color successSurface = Color(0xFFEFFDE9);
  static const Color successBorder = Color(0xFFB2F29A);
  static const Color successText = Color(0xFF236809); // Contraste élevé WCAG

  /// Avertissement : #F2C121
  static const Color warning = Color(0xFFF2C121);
  static const Color warningSurface = Color(0xFFFEFBE9);
  static const Color warningBorder = Color(0xFFF9E495);
  static const Color warningText = Color(0xFF7A6006); // Contraste élevé WCAG

  /// Danger / Erreur critique : #FB1216
  static const Color danger = Color(0xFFFB1216);
  static const Color dangerSurface = Color(0xFFFFECEC);
  static const Color dangerBorder = Color(0xFFFDA4A6);
  static const Color dangerText = Color(0xFF9E0B0E); // Contraste élevé WCAG

  // ===========================================================================
  // BOUTONS
  // ===========================================================================
  static const Color buttonText = Color(0xFFFFFFFF);
  static const Color buttonDisabledBackground = Color(0xFFE5E7EB);
  static const Color buttonDisabledText = Color(0xFF9CA3AF);

  // ===========================================================================
  // SURFACES ET NEUTRES
  // ===========================================================================
  static const Color neutralBackground = Color(0xFFFAFAFB);
  static const Color neutralSurface = Color(0xFFFFFFFF);
  static const Color neutralSurfaceSecondary = Color(0xFFF4F5F7);
  static const Color border = Color(0xFFE4E6EB);
  static const Color borderSubtle = Color(0xFFEFF0F3);
  static const Color divider = Color(0xFFEBECEF);

  // ===========================================================================
  // GRADIENTS D'UNIVERS
  // ===========================================================================
  /// Gradient doux de transition avant l'entrée dans un univers (#0C2659 → #522578)
  static const LinearGradient transitionGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0C2659), Color(0xFF522578)],
  );

  /// Gradient horizontal doux pour l'AppBar ou bannières de transition
  static const LinearGradient transitionGradientHorizontal = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF0C2659), Color(0xFF522578)],
  );

  /// Gradient subtil de l'univers Psychologue
  static const LinearGradient psychologistGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [psychologist, psychologistLight],
  );

  /// Gradient subtil de l'univers Avocat
  static const LinearGradient lawyerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0C2659), Color(0xFF1B418E)],
  );

  // ===========================================================================
  // MARQUE (valeurs relevées dans les maquettes Figma : docs/figma)
  // ===========================================================================
  /// Violet de marque : liens, cases à cocher, début du dégradé des boutons.
  static const Color brandPurple = Color(0xFF632CB5);

  /// Bleu de marque : fin du dégradé des boutons.
  static const Color brandBlue = Color(0xFF1F5AC7);

  /// Violet du mot « Psy » dans le logo.
  static const Color logoPsy = Color(0xFF672AB0);

  /// Couleur du mot « avocat » mis en avant sur l'onboarding.
  static const Color lawyerHighlight = Color(0xFF6B7AFF);

  /// Dégradé des boutons principaux (gauche → droite).
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [brandPurple, brandBlue],
  );

  /// Dégradé de l'en-tête arrondi des écrans d'authentification (haut → bas).
  static const LinearGradient authHeaderGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [brandPurple, lawyer],
  );

  // ===========================================================================
  // ACCENTS LUMINEUX (utilisés sur fond sombre : onboarding)
  // ===========================================================================
  /// Lavande de l'univers Psychologue (maquette onboarding : « santé mentale »).
  static const Color psychologistAccent = Color(0xFF8B7CF6);

  /// Bleu clair de l'univers Avocat, pendant de [psychologistAccent].
  static const Color lawyerAccent = Color(0xFF6B8CFF);

  // ===========================================================================
  // ONBOARDING SOMBRE (maquette onboarding)
  // ===========================================================================
  /// Fond bleu nuit très sombre de l'onboarding.
  static const Color onboardingBackground = Color(0xFF0B0D1A);

  /// Texte secondaire sur fond sombre.
  static const Color onboardingTextMuted = Color(0xFFA9ABC6);

  // ===========================================================================
  // FONDS D'ÉCRAN (Figma)
  // ===========================================================================
  /// Fond lavande : onboarding avocat, choix de la catégorie.
  static const Color backgroundLavender = Color(0xFFF7F5FA);

  /// Fond gris très clair : première page, questionnaire.
  static const Color backgroundLight = Color(0xFFF8FAFC);

  /// Fond dégradé de l'onboarding psychologue (gauche → droite).
  static const LinearGradient psychologistOnboardingBackground = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [backgroundLight, Color(0xFFE9D5FF)],
  );

  // ===========================================================================
  // FORMULAIRES (Figma : connexion / inscription)
  // ===========================================================================
  /// Libellés des champs.
  static const Color formLabel = Color(0xFF1E293B);

  /// Placeholders, icônes et textes secondaires des formulaires.
  static const Color formHint = Color(0xFF64748B);

  /// Bordure des champs de saisie.
  static const Color formBorder = Color(0xFFE2E8F0);

  /// Lignes de séparation (« CONTINUE AVEC »).
  static const Color formDivider = Color(0xFF94A3B8);

  // ===========================================================================
  // COMPOSANTS DIVERS (Figma)
  // ===========================================================================
  /// Sous-titre de l'écran de choix de catégorie.
  static const Color subtitleSlate = Color(0xFF5A6E85);

  /// Segments non remplis de la barre de progression du questionnaire.
  static const Color progressTrack = Color(0xFFF2F2F7);

  /// Fond du bouton « Ignorer ».
  static const Color chipBackground = Color(0xFFF7F7F7);

  /// Points inactifs de l'indicateur de pages.
  static const Color dotInactive = Color(0xFFD9D9D9);

  /// Dégradé de la carte « Avocat » (choix de catégorie).
  static const LinearGradient lawyerCardGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [lawyer, Color(0xFF1A3F7A)],
  );

  /// Dégradé de la carte « Psychologue » (choix de catégorie).
  static const LinearGradient psychologistCardGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [psychologist, psychologistLight],
  );

  // ===========================================================================
  // ALIASES ET RÉTROCOMPATIBILITÉ
  // ===========================================================================
  static const Color primary = lawyer;
  static const Color primaryLight = lawyerLight;
  static const Color primaryDark = lawyerDark;
  static const Color secondary = psychologist;
  static const Color secondaryLight = psychologistLight;
  static const Color secondaryDark = psychologistDark;

  static const Color lightBackground = neutralBackground;
  static const Color lightSurface = neutralSurface;
  static const Color lightSurfaceSecondary = neutralSurfaceSecondary;
  static const Color lightTextPrimary = textPrimary;
  static const Color lightTextSecondary = textSecondary;
  static const Color lightBorder = border;

  static const Color darkBackground = Color(0xFF0A101D);
  static const Color darkSurface = Color(0xFF121B2F);
  static const Color darkSurfaceSecondary = Color(0xFF19253F);
  static const Color darkTextPrimary = Color(0xFFF3F4F6);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkBorder = Color(0xFF243350);
}
