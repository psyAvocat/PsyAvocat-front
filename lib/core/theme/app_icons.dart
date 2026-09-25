import 'package:flutter/material.dart';

/// Dimensions et icônes standardisées pour le Design System PsyAvocat.
class AppIcons {
  AppIcons._();

  // ===========================================================================
  // TAILLES D'ICÔNES
  // ===========================================================================
  /// 14 px : Micro-icône (badges compacts, indicateurs d'état)
  static const double sizeXs = 14.0;

  /// 18 px : Petite icône (boutons compacts, tags)
  static const double sizeSm = 18.0;

  /// 22 px : Icône standard (boutons, champs de saisie, barres d'outils)
  static const double sizeMd = 22.0;

  /// 28 px : Grande icône (cartes, éléments de navigation)
  static const double sizeLg = 28.0;

  /// 44 px : Icône hero / modale (dialogues, alertes, écrans vides)
  static const double sizeXl = 44.0;

  // ===========================================================================
  // ICÔNES MÉTIER ET UNIVERS
  // ===========================================================================
  static const IconData psychologist = Icons.psychology_outlined;
  static const IconData psychologistFilled = Icons.psychology_rounded;

  static const IconData lawyer = Icons.gavel_outlined;
  static const IconData lawyerFilled = Icons.gavel_rounded;

  static const IconData neutral = Icons.balance_outlined;

  // ===========================================================================
  // ICÔNES D'ÉTATS ET DE RETOURS
  // ===========================================================================
  static const IconData success = Icons.check_circle_rounded;
  static const IconData warning = Icons.warning_amber_rounded;
  static const IconData danger = Icons.error_outline_rounded;
  static const IconData info = Icons.info_outline_rounded;

  // ===========================================================================
  // ICÔNES DE NAVIGATION ET D'ACTIONS
  // ===========================================================================
  static const IconData back = Icons.arrow_back_ios_new_rounded;
  static const IconData forward = Icons.arrow_forward_ios_rounded;
  static const IconData close = Icons.close_rounded;
  static const IconData check = Icons.check_rounded;
  static const IconData search = Icons.search_rounded;
  static const IconData visibility = Icons.visibility_outlined;
  static const IconData visibilityOff = Icons.visibility_off_outlined;
  static const IconData calendar = Icons.calendar_today_rounded;
  static const IconData user = Icons.person_outline_rounded;
  static const IconData settings = Icons.tune_rounded;
  static const IconData filter = Icons.filter_list_rounded;
  static const IconData message = Icons.chat_bubble_outline_rounded;
}
