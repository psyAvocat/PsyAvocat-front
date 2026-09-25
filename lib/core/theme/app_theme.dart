import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_radii.dart';
import 'app_spacing.dart';
import 'app_button_sizes.dart';
import 'app_universe.dart';

/// Extension de thème pour accéder facilement aux éléments de l'univers actif
/// via `Theme.of(context).extension<AppUniverseColors>()` ou `AppTheme.universeOf(context)`.
@immutable
class AppUniverseColors extends ThemeExtension<AppUniverseColors> {
  final AppUniverse universe;
  final Color primary;
  final Color primaryLight;
  final Color surface;
  final Color surfaceSelected;
  final Color border;
  final Gradient gradient;

  const AppUniverseColors({
    required this.universe,
    required this.primary,
    required this.primaryLight,
    required this.surface,
    required this.surfaceSelected,
    required this.border,
    required this.gradient,
  });

  factory AppUniverseColors.fromUniverse(AppUniverse universe) {
    switch (universe) {
      case AppUniverse.psychologist:
        return const AppUniverseColors(
          universe: AppUniverse.psychologist,
          primary: AppColors.psychologist,
          primaryLight: AppColors.psychologistLight,
          surface: AppColors.psychologistSurface,
          surfaceSelected: AppColors.psychologistSurfaceSelected,
          border: AppColors.psychologistBorder,
          gradient: AppColors.psychologistGradient,
        );
      case AppUniverse.lawyer:
        return const AppUniverseColors(
          universe: AppUniverse.lawyer,
          primary: AppColors.lawyer,
          primaryLight: AppColors.lawyerLight,
          surface: AppColors.lawyerSurface,
          surfaceSelected: AppColors.lawyerSurfaceSelected,
          border: AppColors.lawyerBorder,
          gradient: AppColors.lawyerGradient,
        );
      case AppUniverse.neutral:
        return const AppUniverseColors(
          universe: AppUniverse.neutral,
          primary: AppColors.lawyer,
          primaryLight: AppColors.psychologist,
          surface: AppColors.neutralSurfaceSecondary,
          surfaceSelected: AppColors.lawyerSurfaceSelected,
          border: AppColors.border,
          gradient: AppColors.transitionGradient,
        );
    }
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
  }) {
    return AppUniverseColors(
      universe: universe ?? this.universe,
      primary: primary ?? this.primary,
      primaryLight: primaryLight ?? this.primaryLight,
      surface: surface ?? this.surface,
      surfaceSelected: surfaceSelected ?? this.surfaceSelected,
      border: border ?? this.border,
      gradient: gradient ?? this.gradient,
    );
  }

  @override
  AppUniverseColors lerp(ThemeExtension<AppUniverseColors>? other, double t) {
    if (other is! AppUniverseColors) return this;
    return AppUniverseColors(
      universe: t < 0.5 ? universe : other.universe,
      primary: Color.lerp(primary, other.primary, t) ?? primary,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t) ?? primaryLight,
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      surfaceSelected: Color.lerp(surfaceSelected, other.surfaceSelected, t) ?? surfaceSelected,
      border: Color.lerp(border, other.border, t) ?? border,
      gradient: Gradient.lerp(gradient, other.gradient, t) ?? gradient,
    );
  }
}

/// Thèmes Flutter officiels de PsyAvocat.
/// Supporte le thème neutre (transition), psychologue et avocat.
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
  static ThemeData get psychologistTheme => buildTheme(AppUniverse.psychologist);

  /// Thème dédié à l'univers Avocat (#0C2659)
  static ThemeData get lawyerTheme => buildTheme(AppUniverse.lawyer);

  /// Générateur de thème en fonction de l'univers sélectionné
  static ThemeData buildTheme(AppUniverse universe) {
    final universeColors = AppUniverseColors.fromUniverse(universe);
    final primaryColor = universeColors.primary;
    final textTheme = AppTypography.createTextTheme(AppColors.textPrimary);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: AppColors.neutralBackground,
      fontFamily: AppTypography.fontFamily,
      extensions: [universeColors],
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: universe == AppUniverse.psychologist
            ? AppColors.psychologistLight
            : AppColors.lawyerLight,
        surface: AppColors.neutralSurface,
        error: AppColors.danger,
        onPrimary: AppColors.buttonText,
        onSurface: AppColors.textPrimary,
        onError: AppColors.buttonText,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.neutralSurface,
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
        titleTextStyle: AppTypography.titreMoyen.copyWith(
          fontSize: 18,
          color: AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.textPrimary,
          size: 22,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.neutralSurface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.r16,
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primaryColor,
          foregroundColor: AppColors.buttonText,
          minimumSize: const Size.fromHeight(AppButtonSizes.heightDefault),
          padding: AppButtonSizes.paddingDefault,
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadii.r16,
          ),
          textStyle: AppTypography.buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          foregroundColor: primaryColor,
          minimumSize: const Size.fromHeight(AppButtonSizes.heightDefault),
          padding: AppButtonSizes.paddingDefault,
          side: BorderSide(color: primaryColor, width: 1.5),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadii.r16,
          ),
          textStyle: AppTypography.buttonText.copyWith(color: primaryColor),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.neutralSurface,
        contentPadding: AppSpacing.inputPadding,
        hintStyle: AppTypography.texteSecondaire.copyWith(
          color: AppColors.textTertiary,
        ),
        labelStyle: AppTypography.labelInput,
        floatingLabelStyle: AppTypography.labelInput.copyWith(color: primaryColor),
        border: const OutlineInputBorder(
          borderRadius: AppRadii.r12,
          borderSide: BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadii.r12,
          borderSide: BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.r12,
          borderSide: BorderSide(color: primaryColor, width: 1.6),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadii.r12,
          borderSide: BorderSide(color: AppColors.danger, width: 1),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: AppRadii.r12,
          borderSide: BorderSide(color: AppColors.danger, width: 1.6),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.neutralSurface,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadii.r20,
        ),
        titleTextStyle: AppTypography.titreMoyen,
        contentTextStyle: AppTypography.texteSecondaire,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: primaryColor.withValues(alpha: 0.15),
        circularTrackColor: primaryColor.withValues(alpha: 0.15),
      ),
    );
  }

  /// Rétrocompatibilité : thème sombre
  static ThemeData get darkTheme => lightTheme;
}
