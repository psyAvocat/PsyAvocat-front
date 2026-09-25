import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Univers de l'application PsyAvocat.
/// - [neutral] : état avant l'entrée dans un univers (utilise le gradient #0C2659 → #45088E)
/// - [psychologist] : univers Psychologue (#45088E)
/// - [lawyer] : univers Avocat (#0C2659)
enum AppUniverse {
  neutral,
  psychologist,
  lawyer;

  bool get isPsychologist => this == AppUniverse.psychologist;
  bool get isLawyer => this == AppUniverse.lawyer;
  bool get isNeutral => this == AppUniverse.neutral;

  /// Nom d'affichage de l'univers
  String get displayName {
    switch (this) {
      case AppUniverse.psychologist:
        return 'Psychologue';
      case AppUniverse.lawyer:
        return 'Avocat';
      case AppUniverse.neutral:
        return 'PsyAvocat';
    }
  }

  /// Couleur principale dédiée à l'univers
  Color get primaryColor {
    switch (this) {
      case AppUniverse.psychologist:
        return AppColors.psychologist;
      case AppUniverse.lawyer:
        return AppColors.lawyer;
      case AppUniverse.neutral:
        return AppColors.lawyer; // Base élégante
    }
  }

  /// Nuance claire pour les surfaces et fonds de l'univers
  Color get surfaceLight {
    switch (this) {
      case AppUniverse.psychologist:
        return AppColors.psychologistSurface;
      case AppUniverse.lawyer:
        return AppColors.lawyerSurface;
      case AppUniverse.neutral:
        return AppColors.neutralSurface;
    }
  }

  /// Nuance pour les états sélectionnés de l'univers
  Color get selectedSurface {
    switch (this) {
      case AppUniverse.psychologist:
        return AppColors.psychologistSurfaceSelected;
      case AppUniverse.lawyer:
        return AppColors.lawyerSurfaceSelected;
      case AppUniverse.neutral:
        return AppColors.lawyerSurfaceSelected;
    }
  }

  /// Couleur de bordure subtile de l'univers
  Color get borderLight {
    switch (this) {
      case AppUniverse.psychologist:
        return AppColors.psychologistBorder;
      case AppUniverse.lawyer:
        return AppColors.lawyerBorder;
      case AppUniverse.neutral:
        return AppColors.border;
    }
  }

  /// Gradient associé à l'univers (gradient de transition pour le neutre)
  Gradient get gradient {
    switch (this) {
      case AppUniverse.psychologist:
        return AppColors.psychologistGradient;
      case AppUniverse.lawyer:
        return AppColors.lawyerGradient;
      case AppUniverse.neutral:
        return AppColors.transitionGradient;
    }
  }
}
