import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_radii.dart';
import 'app_spacing.dart';
import 'app_button_sizes.dart';
import 'app_universe.dart';

/// Couleurs « métier » de l'univers actif qui n'ont pas d'équivalent direct
/// dans le [ColorScheme] Material (dégradé, surfaces teintées…).
///
/// Accès : `AppTheme.universeOf(context)`.
/// Toutes les valeurs sont dérivées du [ColorScheme] de l'univers :
/// il n'existe qu'une seule source de vérité, [AppTheme.colorSchemeFor].
@immutable
class AppUniverseColors extends ThemeExtension<AppUniverseColors> {
  final AppUniverse universe;
  final Color primary;
  final Color primaryLight;
  final Color surface;
  final Color surfaceSelected;
  final Color border;
  final Gradient gradient;

  /// Accent lumineux, lisible sur fond sombre (onboarding).
  final Color accent;

  const AppUniverseColors({
    required this.universe,
    required this.primary,
    required this.primaryLight,
    required this.surface,
    required this.surfaceSelected,
    required this.border,
    required this.gradient,
    required this.accent,
  });

  factory AppUniverseColors.fromUniverse(AppUniverse universe) {
    final scheme = AppTheme.colorSchemeFor(universe);
    return AppUniverseColors(
      universe: universe,
      primary: scheme.primary,
      primaryLight: scheme.secondary,
      surface: scheme.secondaryContainer,
      surfaceSelected: scheme.primaryContainer,
      border: universe.borderLight,
      gradient: universe.gradient,
      accent: scheme.tertiary,
    );
  }

  @override
  AppUniverseColors copyWith({
    AppUniverse? universe,
    Color? primary,
    Color? primaryLight,
    Color? surface,
    Color? surfaceSelected,
    Color? border,
    Gradient? gradient,
    Color? accent,
  }) {
    return AppUniverseColors(
      universe: universe ?? this.universe,
      primary: primary ?? this.primary,
      primaryLight: primaryLight ?? this.primaryLight,
      surface: surface ?? this.surface,
      surfaceSelected: surfaceSelected ?? this.surfaceSelected,
      border: border ?? this.border,
      gradient: gradient ?? this.gradient,
      accent: accent ?? this.accent,
    );
  }

  @override
  AppUniverseColors lerp(ThemeExtension<AppUniverseColors>? other, double t) {
    if (other is! AppUniverseColors) return this;
    return AppUniverseColors(
      universe: t < 0.5 ? universe : other.universe,
      primary: Color.lerp(primary, other.primary, t) ?? primary,
      primaryLight:
          Color.lerp(primaryLight, other.primaryLight, t) ?? primaryLight,
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      surfaceSelected:
          Color.lerp(surfaceSelected, other.surfaceSelected, t) ??
          surfaceSelected,
      border: Color.lerp(border, other.border, t) ?? border,
      gradient: Gradient.lerp(gradient, other.gradient, t) ?? gradient,
      accent: Color.lerp(accent, other.accent, t) ?? accent,
    );
  }
}

/// Thèmes Material 3 officiels de PsyAvocat.
///
/// La couleur dépend de l'univers actif (voir `currentUniverseProvider`) :
/// - neutre (avant le choix) : violet de marque ;
/// - Avocat : bleu nuit #0C2659 ;
/// - Psychologue : violet #45088E.
///
/// Les widgets lisent les couleurs via `Theme.of(context).colorScheme`
/// et ne codent jamais une couleur d'univers en dur.
class AppTheme {
  AppTheme._();

  /// Récupère les couleurs d'univers actuelles depuis le BuildContext
  static AppUniverseColors universeOf(BuildContext context) {
    return Theme.of(context).extension<AppUniverseColors>() ??
        AppUniverseColors.fromUniverse(AppUniverse.neutral);
  }

  /// Thème par défaut (avant l'entrée dans un univers / transition)
  static ThemeData get lightTheme => buildTheme(AppUniverse.neutral);

  /// Thème dédié à l'univers Psychologue (#45088E)
  static ThemeData get psychologistTheme =>
      buildTheme(AppUniverse.psychologist);

  /// Thème dédié à l'univers Avocat (#0C2659)
  static ThemeData get lawyerTheme => buildTheme(AppUniverse.lawyer);

  /// Rétrocompatibilité : thème sombre
  static ThemeData get darkTheme => lightTheme;

  // ===========================================================================
  // COLOR SCHEME — source unique des couleurs d'univers
  // ===========================================================================

  /// Palette Material 3 de chaque univers.
  static ColorScheme colorSchemeFor(AppUniverse universe) {
    switch (universe) {
      case AppUniverse.psychologist:
        return _baseScheme.copyWith(
          primary: AppColors.psychologist,
          primaryContainer: AppColors.psychologistSurfaceSelected,
          onPrimaryContainer: AppColors.psychologistDark,
          secondary: AppColors.psychologistLight,
          secondaryContainer: AppColors.psychologistSurface,
          onSecondaryContainer: AppColors.psychologistDark,
          tertiary: AppColors.psychologistAccent,
        );
      case AppUniverse.lawyer:
        return _baseScheme.copyWith(
          primary: AppColors.lawyer,
          primaryContainer: AppColors.lawyerSurfaceSelected,
          onPrimaryContainer: AppColors.lawyerDark,
          secondary: AppColors.lawyerLight,
          secondaryContainer: AppColors.lawyerSurface,
          onSecondaryContainer: AppColors.lawyerDark,
          tertiary: AppColors.lawyerAccent,
        );
      case AppUniverse.neutral:
        return _baseScheme.copyWith(
          primary: AppColors.brandPurple,
          primaryContainer: AppColors.psychologistSurfaceSelected,
          onPrimaryContainer: AppColors.psychologistDark,
          secondary: AppColors.brandBlue,
          secondaryContainer: AppColors.lawyerSurface,
          onSecondaryContainer: AppColors.lawyerDark,
          tertiary: AppColors.psychologistAccent,
        );
    }
  }

  /// Couleurs communes à tous les univers (surfaces, textes, erreurs).
  static const ColorScheme _baseScheme = ColorScheme.light(
    onPrimary: AppColors.textOnColor,
    onSecondary: AppColors.textOnColor,
    onTertiary: AppColors.textOnColor,
    surface: AppColors.neutralSurface,
    onSurface: AppColors.textPrimary,
    onSurfaceVariant: AppColors.textSecondary,
    surfaceContainerLowest: AppColors.neutralSurface,
    surfaceContainerLow: AppColors.backgroundLight,
    surfaceContainer: AppColors.neutralSurfaceSecondary,
    surfaceContainerHigh: AppColors.borderSubtle,
    outline: AppColors.formDivider,
    outlineVariant: AppColors.formBorder,
    error: AppColors.danger,
    onError: AppColors.textOnColor,
    errorContainer: AppColors.dangerSurface,
    onErrorContainer: AppColors.dangerText,
  );

  // ===========================================================================
  // THEMEDATA
  // ===========================================================================

  /// Générateur de thème en fonction de l'univers sélectionné
  static ThemeData buildTheme(AppUniverse universe) {
    final scheme = colorSchemeFor(universe);
    final textTheme = AppTypography.createTextTheme(scheme.onSurface);

    const inputBorder = OutlineInputBorder(
      borderRadius: AppRadii.r14,
      borderSide: BorderSide(color: AppColors.formBorder),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      primaryColor: scheme.primary,
      scaffoldBackgroundColor: scheme.surfaceContainerLow,
      extensions: [AppUniverseColors.fromUniverse(universe)],
      textTheme: textTheme,

      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scheme.surfaceContainerLow,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
        titleTextStyle: AppTypography.petitTitre.copyWith(
          color: scheme.onSurface,
        ),
      ),

      // ---- Boutons : forme pilule, hauteur tactile confortable -------------
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, AppButtonSizes.heightDefault),
          padding: AppButtonSizes.paddingDefault,
          shape: const StadiumBorder(),
          textStyle: AppTypography.buttonText,
          disabledBackgroundColor: AppColors.buttonDisabledBackground,
          disabledForegroundColor: AppColors.buttonDisabledText,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(64, AppButtonSizes.heightDefault),
          padding: AppButtonSizes.paddingDefault,
          shape: const StadiumBorder(),
          textStyle: AppTypography.buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(64, AppButtonSizes.heightDefault),
          padding: AppButtonSizes.paddingDefault,
          side: BorderSide(color: scheme.primary),
          shape: const StadiumBorder(),
          textStyle: AppTypography.buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(48, 48),
          textStyle: AppTypography.lien,
        ),
      ),

      // ---- Champs de saisie (maquettes connexion / inscription) -------------
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding: AppSpacing.inputPadding,
        hintStyle: AppTypography.texte.copyWith(color: AppColors.formHint),
        labelStyle: AppTypography.labelInput,
        errorStyle: AppTypography.miniTexte.copyWith(color: scheme.error),
        errorMaxLines: 2,
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
      ),

      // ---- Cartes -----------------------------------------------------------
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadii.r20,
          side: BorderSide(color: AppColors.formBorder),
        ),
      ),

      // ---- Navigation principale -------------------------------------------
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        height: 72,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          // 11 px : « Psychologues » et « Rendez-vous » tiennent sur une ligne.
          return AppTypography.miniTexte.copyWith(
            fontSize: 11,
            letterSpacing: -0.1,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
      ),

      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide.none,
        backgroundColor: scheme.secondaryContainer,
        labelStyle: AppTypography.badgeTexte.copyWith(color: scheme.primary),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: AppColors.progressTrack,
        circularTrackColor: scheme.primary.withValues(alpha: 0.15),
        linearMinHeight: 8,
        borderRadius: AppRadii.pill,
      ),

      checkboxTheme: CheckboxThemeData(
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.r4),
        side: BorderSide(color: scheme.primary, width: 2),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.r20),
        titleTextStyle: AppTypography.petitTitre,
        contentTextStyle: AppTypography.texteSecondaire,
      ),

      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
