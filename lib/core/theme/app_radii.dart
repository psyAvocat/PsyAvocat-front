import 'package:flutter/material.dart';

/// Rayons de courbure (Border Radius) du Design System PsyAvocat.
/// Favorise des coins arrondis modernes et élégants.
class AppRadii {
  AppRadii._();

  // ===========================================================================
  // VALEURS NUMÉRIQUES
  // ===========================================================================
  static const double v4 = 4.0;
  static const double v8 = 8.0;
  static const double v12 = 12.0;
  static const double v16 = 16.0;
  static const double v20 = 20.0;
  static const double v24 = 24.0;
  static const double vFull = 999.0;

  // ===========================================================================
  // BORDERRADIUS FLUTTER
  // ===========================================================================
  /// 4 px : Micro-arrondi
  static const BorderRadius r4 = BorderRadius.all(Radius.circular(v4));

  /// 8 px : Petit arrondi (éléments intérieurs, tags)
  static const BorderRadius r8 = BorderRadius.all(Radius.circular(v8));

  /// 12 px : Arrondi standard (champs de saisie, boutons secondaires)
  static const BorderRadius r12 = BorderRadius.all(Radius.circular(v12));

  /// 16 px : Arrondi moderne (boutons principaux, cartes, conteneurs)
  static const BorderRadius r16 = BorderRadius.all(Radius.circular(v16));

  /// 20 px : Grand arrondi moderne (grandes cartes, modales, dialogues)
  static const BorderRadius r20 = BorderRadius.all(Radius.circular(v20));

  /// 24 px : Très grand arrondi (feuilles de fond, bottom sheets)
  static const BorderRadius r24 = BorderRadius.all(Radius.circular(v24));

  /// Pill / Full : Arrondi circulaire complet (badges, puces, boutons ronds)
  static const BorderRadius pill = BorderRadius.all(Radius.circular(vFull));

  // ===========================================================================
  // BORDERRADIUS SPÉCIFIQUES
  // ===========================================================================
  /// Arrondi supérieur pour BottomSheets et tiroirs (24 px)
  static const BorderRadius topSheet = BorderRadius.only(
    topLeft: Radius.circular(v24),
    topRight: Radius.circular(v24),
  );

  /// Arrondi supérieur pour Dialogues (20 px)
  static const BorderRadius topDialog = BorderRadius.only(
    topLeft: Radius.circular(v20),
    topRight: Radius.circular(v20),
  );
}
