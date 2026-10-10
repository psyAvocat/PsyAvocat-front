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

  factory AppUniverseColors.fromUniverse(
    AppUniverse universe, {
    Brightness brightness = Brightness.light,
  }) {
    final scheme = AppTheme.colorSchemeFor(universe, brightness: brightness);
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
/// - Psychologue : violet #522578.
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

  // ===========================================================================
  // COLOR SCHEME — source unique des couleurs d'univers
  // ===========================================================================

  /// Palette Material 3 de chaque univers, en clair ou en sombre.
  static ColorScheme colorSchemeFor(
    AppUniverse universe, {
    Brightness brightness = Brightness.light,
  }) {
    if (brightness == Brightness.dark) return _darkSchemeFor(universe);
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

  /// Variantes sombres : couleurs d'univers éclaircies pour rester lisibles
  /// sur fond sombre (contraste AA), surfaces neutres sombres communes.
  static ColorScheme _darkSchemeFor(AppUniverse universe) {
    switch (universe) {
      case AppUniverse.psychologist:
        return _darkBaseScheme.copyWith(
          primary: const Color(0xFFCDB2F7),
          onPrimary: AppColors.psychologistDark,
          primaryContainer: AppColors.psychologist,
          onPrimaryContainer: AppColors.psychologistSurfaceSelected,
          secondary: AppColors.psychologistAccent,
          secondaryContainer: const Color(0xFF2B1F45),
          onSecondaryContainer: AppColors.psychologistSurfaceSelected,
          tertiary: AppColors.psychologistAccent,
        );
      case AppUniverse.lawyer:
        return _darkBaseScheme.copyWith(
          primary: const Color(0xFFA9C2F5),
          onPrimary: AppColors.lawyerDark,
          primaryContainer: AppColors.lawyerLight,
          onPrimaryContainer: AppColors.lawyerSurfaceSelected,
          secondary: AppColors.lawyerAccent,
          secondaryContainer: const Color(0xFF1A2742),
          onSecondaryContainer: AppColors.lawyerSurfaceSelected,
          tertiary: AppColors.lawyerAccent,
        );
      case AppUniverse.neutral:
        return _darkBaseScheme.copyWith(
          primary: const Color(0xFFC9B0F5),
          onPrimary: AppColors.psychologistDark,
          primaryContainer: AppColors.brandPurple,
          onPrimaryContainer: AppColors.psychologistSurfaceSelected,
          secondary: AppColors.lawyerAccent,
          secondaryContainer: const Color(0xFF241F38),
          onSecondaryContainer: AppColors.psychologistSurfaceSelected,
          tertiary: AppColors.psychologistAccent,
        );
    }
  }

  static const ColorScheme _darkBaseScheme = ColorScheme.dark(
    onSecondary: AppColors.darkBackground,
    onTertiary: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkTextPrimary,
    onSurfaceVariant: AppColors.darkTextSecondary,
    surfaceContainerLowest: AppColors.darkBackground,
    surfaceContainerLow: AppColors.darkBackground,
    surfaceContainer: AppColors.darkSurface,
    surfaceContainerHigh: AppColors.darkSurfaceSecondary,
    outline: Color(0xFF5B6B88),
    outlineVariant: AppColors.darkBorder,
    error: Color(0xFFFF8A8C),
    onError: AppColors.darkBackground,
    errorContainer: Color(0xFF5C1214),
    onErrorContainer: Color(0xFFFFDADB),
  );

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

  /// Générateur de thème : univers (couleurs) × luminosité (clair / sombre).
  static ThemeData buildTheme(
    AppUniverse universe, {
    Brightness brightness = Brightness.light,
  }) {
    final scheme = colorSchemeFor(universe, brightness: brightness);
    final textTheme = AppTypography.createTextTheme(scheme.onSurface);

    final inputBorder = OutlineInputBorder(
      borderRadius: AppRadii.r14,
      borderSide: BorderSide(color: scheme.outlineVariant),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      primaryColor: scheme.primary,
      scaffoldBackgroundColor: scheme.surfaceContainerLow,
      extensions: [
        AppUniverseColors.fromUniverse(universe, brightness: brightness),
      ],
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
          disabledBackgroundColor: scheme.onSurface.withValues(alpha: 0.12),
          disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.38),
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
        hintStyle: AppTypography.texte.copyWith(color: scheme.onSurfaceVariant),
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
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.r20,
          side: BorderSide(color: scheme.outlineVariant),
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
        linearTrackColor: scheme.surfaceContainerHigh,
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
        titleTextStyle: AppTypography.petitTitre.copyWith(
          color: scheme.onSurface,
        ),
        contentTextStyle: AppTypography.texteSecondaire.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),

      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.topSheet),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
      ),

      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
