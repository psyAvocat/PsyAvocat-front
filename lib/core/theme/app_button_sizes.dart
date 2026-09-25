import 'package:flutter/material.dart';

/// Dimensions standardisées des boutons pour garantir une hauteur cohérente
/// sur toute l'application PsyAvocat.
class AppButtonSizes {
  AppButtonSizes._();

  // ===========================================================================
  // HAUTEURS STANDARDS
  // ===========================================================================
  /// Hauteur standard par défaut : 52 px (ergonomie tactile optimale sur mobile)
  static const double heightDefault = 52.0;

  /// Hauteur compacte : 42 px (dialogues restreints, boutons de listes)
  static const double heightCompact = 42.0;

  /// Hauteur large : 58 px (actions hero / call-to-action majeurs)
  static const double heightLarge = 58.0;

  // ===========================================================================
  // TAILLES MINIMALES ET PADDINGS
  // ===========================================================================
  /// Largeur minimale pour éviter les micro-boutons
  static const double minWidthDefault = 120.0;

  /// Taille de l'indicateur de chargement dans un bouton standard
  static const double loaderSizeDefault = 22.0;

  /// Taille de l'indicateur de chargement dans un bouton compact
  static const double loaderSizeCompact = 18.0;

  /// Épaisseur du trait de chargement
  static const double loaderStrokeWidth = 2.4;

  /// Taille de l'icône dans un bouton standard
  static const double iconSizeDefault = 20.0;

  /// Taille de l'icône dans un bouton compact
  static const double iconSizeCompact = 16.0;

  /// Espacement entre icône et texte dans un bouton
  static const double iconGap = 10.0;

  // ===========================================================================
  // PADDINGS INTERNES
  // ===========================================================================
  static const EdgeInsets paddingDefault = EdgeInsets.symmetric(
    horizontal: 24.0,
    vertical: 14.0,
  );

  static const EdgeInsets paddingCompact = EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 10.0,
  );

  static const EdgeInsets paddingLarge = EdgeInsets.symmetric(
    horizontal: 28.0,
    vertical: 16.0,
  );
}
