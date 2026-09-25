import 'package:flutter/material.dart';

/// Système d'espacements standardisé pour PsyAvocat.
///
/// Échelle cohérente basée sur 4/8 px :
/// 4, 8, 12, 16, 20, 24, 32, 40, 48 px.
///
/// Conçu pour offrir des marges intérieures généreuses et une interface mobile aérée.
class AppSpacing {
  AppSpacing._();

  // ===========================================================================
  // VALEURS DE BASE (en pixels)
  // ===========================================================================
  /// 4 px : Micro-espacement (icône + texte compact, pastille)
  static const double s4 = 4.0;

  /// 8 px : Petit espacement (gaps d'éléments groupés, badges)
  static const double s8 = 8.0;

  /// 12 px : Espacement moyen-faible (gaps d'entrées, padding compact)
  static const double s12 = 12.0;

  /// 16 px : Espacement standard de base (padding de cartes, éléments de liste)
  static const double s16 = 16.0;

  /// 20 px : Espacement aéré (padding de cartes premium, espacement entre sections moyennes)
  static const double s20 = 20.0;

  /// 24 px : Espacement généreux (marges d'écran, espacement majeur)
  static const double s24 = 24.0;

  /// 32 px : Grand espacement (séparation entre grands blocs)
  static const double s32 = 32.0;

  /// 40 px : Très grand espacement (en-têtes, transitions)
  static const double s40 = 40.0;

  /// 48 px : Espacement maximal (espacement hero, haut de page)
  static const double s48 = 48.0;

  // ===========================================================================
  // PADDINGS STANDARDS (Généreux & Aérés)
  // ===========================================================================

  /// Marges d'écran standard (horizontal: 24, vertical: 20)
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: s24,
    vertical: s20,
  );

  /// Marges d'écran horizontales seules
  static const EdgeInsets screenHorizontal = EdgeInsets.symmetric(
    horizontal: s24,
  );

  /// Padding intérieur de carte généreux (20 px)
  static const EdgeInsets cardPadding = EdgeInsets.all(s20);

  /// Padding compact de carte (16 px)
  static const EdgeInsets cardPaddingCompact = EdgeInsets.all(s16);

  /// Padding des dialogues et modales (24 px)
  static const EdgeInsets dialogPadding = EdgeInsets.all(s24);

  /// Padding intérieur des boutons standards (horizontal: 24, vertical: 14)
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: s24,
    vertical: 14.0,
  );

  /// Padding intérieur des champs de formulaire
  static const EdgeInsets inputPadding = EdgeInsets.symmetric(
    horizontal: s16,
    vertical: 14.0,
  );

  // Paddings 'All' prédéfinis
  static const EdgeInsets paddingAll4 = EdgeInsets.all(s4);
  static const EdgeInsets paddingAll8 = EdgeInsets.all(s8);
  static const EdgeInsets paddingAll12 = EdgeInsets.all(s12);
  static const EdgeInsets paddingAll16 = EdgeInsets.all(s16);
  static const EdgeInsets paddingAll20 = EdgeInsets.all(s20);
  static const EdgeInsets paddingAll24 = EdgeInsets.all(s24);
  static const EdgeInsets paddingAll32 = EdgeInsets.all(s32);

  // ===========================================================================
  // GAPS VERTICAUX (SizedBox pour Columns)
  // ===========================================================================
  static const SizedBox vGap4 = SizedBox(height: s4);
  static const SizedBox vGap8 = SizedBox(height: s8);
  static const SizedBox vGap12 = SizedBox(height: s12);
  static const SizedBox vGap16 = SizedBox(height: s16);
  static const SizedBox vGap20 = SizedBox(height: s20);
  static const SizedBox vGap24 = SizedBox(height: s24);
  static const SizedBox vGap32 = SizedBox(height: s32);
  static const SizedBox vGap40 = SizedBox(height: s40);
  static const SizedBox vGap48 = SizedBox(height: s48);

  // ===========================================================================
  // GAPS HORIZONTAUX (SizedBox pour Rows)
  // ===========================================================================
  static const SizedBox hGap4 = SizedBox(width: s4);
  static const SizedBox hGap8 = SizedBox(width: s8);
  static const SizedBox hGap12 = SizedBox(width: s12);
  static const SizedBox hGap16 = SizedBox(width: s16);
  static const SizedBox hGap20 = SizedBox(width: s20);
  static const SizedBox hGap24 = SizedBox(width: s24);
  static const SizedBox hGap32 = SizedBox(width: s32);
  static const SizedBox hGap40 = SizedBox(width: s40);
  static const SizedBox hGap48 = SizedBox(width: s48);
}
