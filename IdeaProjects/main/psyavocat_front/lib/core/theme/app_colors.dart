import 'package:flutter/material.dart';

/// Palette de couleurs officielle de l'application PsyAvocat.
/// Alliant l'univers juridique (bleu nuit profond) et l'univers psychologique (vert sauge apaisant).
class AppColors {
  AppColors._();

  // Couleurs Primaires (Droit / Confiance)
  static const Color primary = Color(0xFF162846);
  static const Color primaryLight = Color(0xFF2B436D);
  static const Color primaryDark = Color(0xFF0C1729);

  // Couleurs Secondaires (Psychologie / Bien-être)
  static const Color secondary = Color(0xFF2D7260);
  static const Color secondaryLight = Color(0xFF4C9380);
  static const Color secondaryDark = Color(0xFF1B473C);

  // Couleurs d'accentuation
  static const Color accent = Color(0xFFE89234);

  // Statuts Métier
  static const Color statusPending = Color(0xFFD97706);
  static const Color statusApproved = Color(0xFF059669);
  static const Color statusRejected = Color(0xFFDC2626);
  static const Color statusSuspended = Color(0xFF4B5563);

  // Neutres - Mode Clair
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceSecondary = Color(0xFFF1F5F9);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightBorder = Color(0xFFE2E8F0);

  // Neutres - Mode Sombre
  static const Color darkBackground = Color(0xFF0B1320);
  static const Color darkSurface = Color(0xFF131F33);
  static const Color darkSurfaceSecondary = Color(0xFF1D2E49);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkBorder = Color(0xFF263A5C);
}
