import 'package:flutter/material.dart';

/// Ombres et élévations standardisées de PsyAvocat.
/// Conforme à la consigne : "Ombre légère uniquement lorsque nécessaire".
class AppShadows {
  AppShadows._();

  /// Aucune ombre
  static const List<BoxShadow> none = [];

  /// Ombre ultra-légère pour les cartes et conteneurs posés
  static const List<BoxShadow> subtle = [
    BoxShadow(
      color: Color(0x0A000000), // ~4% noir
      blurRadius: 8,
      spreadRadius: 0,
      offset: Offset(0, 2),
    ),
  ];

  /// Ombre douce pour les cartes interactives ou cartes sélectionnées
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0F0C2659), // Teinte subtilement bleutée 6%
      blurRadius: 16,
      spreadRadius: 0,
      offset: Offset(0, 4),
    ),
  ];

  /// Ombre légère pour les boutons surélevés majeurs
  static const List<BoxShadow> button = [
    BoxShadow(
      color: Color(0x1A0C2659), // 10%
      blurRadius: 12,
      spreadRadius: 0,
      offset: Offset(0, 4),
    ),
  ];

  /// Ombre de bouton avec couleur dédiée à l'univers
  static List<BoxShadow> buttonUniverse(Color primaryColor) {
    return [
      BoxShadow(
        color: primaryColor.withValues(alpha: 0.25),
        blurRadius: 14,
        spreadRadius: 0,
        offset: const Offset(0, 4),
      ),
    ];
  }

  /// Ombre pour les modales, dialogues et popups
  static const List<BoxShadow> modal = [
    BoxShadow(
      color: Color(0x1F000000), // 12% noir
      blurRadius: 28,
      spreadRadius: 0,
      offset: Offset(0, 10),
    ),
  ];

  /// Ombre supérieure pour la barre de navigation basse
  static const List<BoxShadow> navigation = [
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 12,
      spreadRadius: 0,
      offset: Offset(0, -2),
    ),
  ];
}
