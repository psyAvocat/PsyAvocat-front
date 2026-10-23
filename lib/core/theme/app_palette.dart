import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_universe.dart';

/// Couleurs neutres des écrans (fonds, cartes, textes, bordures) en clair et
/// en sombre. En clair, les valeurs sont exactement celles des maquettes ; en
/// sombre, leurs équivalents lisibles : un texte reste toujours visible sur le
/// fond prévu pour lui, quel que soit le mode.
///
/// Accès : `context.palette.textStrong`, `context.palette.card`…
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  /// Fond de page.
  final Color page;

  /// Cartes, barres, feuilles (blanc en clair).
  final Color card;

  /// Fonds discrets (onglets, zones grisées).
  final Color muted;

  /// Titres et texte principal.
  final Color textStrong;

  /// Texte courant.
  final Color text;

  /// Texte secondaire.
  final Color textMuted;

  /// Texte d'appoint, indications.
  final Color textSubtle;

  final Color border;
  final Color borderStrong;

  /// Cartes teintées des dossiers et leur bordure.
  final Color cardTinted;
  final Color borderTinted;

  /// Pastilles, onglets inactifs et fonds d'icônes.
  final Color chip;

  /// Carré d'icône du menu du profil et icône dessus.
  final Color iconTile;
  final Color onIconTile;

  /// Bulle de message reçue et son texte.
  final Color bubbleIncoming;
  final Color onBubbleIncoming;

  /// Fond des champs de saisie arrondis (messagerie).
  final Color inputFill;

  const AppPalette({
    required this.page,
    required this.card,
    required this.muted,
    required this.textStrong,
    required this.text,
    required this.textMuted,
    required this.textSubtle,
    required this.border,
    required this.borderStrong,
    required this.cardTinted,
    required this.borderTinted,
    required this.chip,
    required this.iconTile,
    required this.onIconTile,
    required this.bubbleIncoming,
    required this.onBubbleIncoming,
    required this.inputFill,
  });

  static const light = AppPalette(
    page: Color(0xFFF9FAFC),
    card: Colors.white,
    muted: Color(0xFFF3F4F6),
    textStrong: Color(0xFF111827),
    text: Color(0xFF374151),
    textMuted: Color(0xFF6B7280),
    textSubtle: Color(0xFF9CA3AF),
    border: Color(0xFFE5E7EB),
    borderStrong: Color(0xFFD1D5DB),
    cardTinted: Color(0xFFF7FAFE),
    borderTinted: Color(0xFFDCE5F2),
    chip: Color(0xFFEDF1FA),
    iconTile: Color(0xFFE2ECF8),
    onIconTile: Color(0xFF1E3A5F),
    bubbleIncoming: Color(0xFFD9D9D9),
    onBubbleIncoming: Colors.black,
    inputFill: Color(0xFFF1F1F1),
  );

  static const dark = AppPalette(
    page: AppColors.darkBackground,
    card: AppColors.darkSurface,
    muted: AppColors.darkSurfaceSecondary,
    textStrong: AppColors.darkTextPrimary,
    text: Color(0xFFD1D5DB),
    textMuted: AppColors.darkTextSecondary,
    textSubtle: Color(0xFF7B8599),
    border: AppColors.darkBorder,
    borderStrong: Color(0xFF33456A),
    cardTinted: Color(0xFF16213A),
    borderTinted: Color(0xFF2A3B5C),
    chip: Color(0xFF1E2B47),
    iconTile: Color(0xFF1E2B47),
    onIconTile: Color(0xFF8FB0F5),
    bubbleIncoming: Color(0xFF26324D),
    onBubbleIncoming: AppColors.darkTextPrimary,
    inputFill: AppColors.darkSurfaceSecondary,
  );

  /// Palette de l'univers : les teintes « bleutées » (pastilles, carrés
  /// d'icônes, cartes teintées) passent en variantes violettes côté Psychologue.
  static AppPalette forUniverse(AppUniverse universe, Brightness brightness) {
    final base = brightness == Brightness.dark ? dark : light;
    if (!universe.isPsychologist) return base;
    return brightness == Brightness.dark
        ? base._tinted(
            cardTinted: const Color(0xFF1F1636),
            borderTinted: const Color(0xFF3D2C5E),
            chip: const Color(0xFF2A1E47),
            iconTile: const Color(0xFF2A1E47),
            onIconTile: const Color(0xFFC3A8F5),
          )
        : base._tinted(
            cardTinted: const Color(0xFFFAF7FE),
            borderTinted: const Color(0xFFE6DCF5),
            chip: const Color(0xFFF1EAFB),
            iconTile: const Color(0xFFEDE3FA),
            onIconTile: AppColors.psychologist,
          );
  }

  AppPalette _tinted({
    required Color cardTinted,
    required Color borderTinted,
    required Color chip,
    required Color iconTile,
    required Color onIconTile,
  }) => AppPalette(
    page: page,
    card: card,
    muted: muted,
    textStrong: textStrong,
    text: text,
    textMuted: textMuted,
    textSubtle: textSubtle,
    border: border,
    borderStrong: borderStrong,
    cardTinted: cardTinted,
    borderTinted: borderTinted,
    chip: chip,
    iconTile: iconTile,
    onIconTile: onIconTile,
    bubbleIncoming: bubbleIncoming,
    onBubbleIncoming: onBubbleIncoming,
    inputFill: inputFill,
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(covariant AppPalette? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      page: l(page, other.page),
      card: l(card, other.card),
      muted: l(muted, other.muted),
      textStrong: l(textStrong, other.textStrong),
      text: l(text, other.text),
      textMuted: l(textMuted, other.textMuted),
      textSubtle: l(textSubtle, other.textSubtle),
      border: l(border, other.border),
      borderStrong: l(borderStrong, other.borderStrong),
      cardTinted: l(cardTinted, other.cardTinted),
      borderTinted: l(borderTinted, other.borderTinted),
      chip: l(chip, other.chip),
      iconTile: l(iconTile, other.iconTile),
      onIconTile: l(onIconTile, other.onIconTile),
      bubbleIncoming: l(bubbleIncoming, other.bubbleIncoming),
      onBubbleIncoming: l(onBubbleIncoming, other.onBubbleIncoming),
      inputFill: l(inputFill, other.inputFill),
    );
  }
}

extension AppPaletteContext on BuildContext {
  /// Palette neutre du mode courant (clair ou sombre).
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;

  /// Couleurs de l'univers courant (primaire…) du mode courant.
  ColorScheme get colors => Theme.of(this).colorScheme;

  /// [color] lisible en texte ou en contour sur les fonds du mode courant :
  /// en sombre, une couleur trop foncée (bleu marine, violet) est remplacée par
  /// la couleur primaire du thème sombre.
  Color readable(Color color) =>
      Theme.of(this).brightness == Brightness.dark &&
          color.computeLuminance() < 0.12
      ? colors.primary
      : color;
}
