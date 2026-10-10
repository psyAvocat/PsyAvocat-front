import 'package:flutter/material.dart';

/// Statut d'un créneau, converti depuis les valeurs réelles du backend
/// (`Disponibilite.statut` : LIBRE, RESERVE, BLOQUE).
enum SlotStatus {
  libre('LIBRE', 'Disponible'),
  reserve('RESERVE', 'Réservé'),
  bloque('BLOQUE', 'Indisponible');

  final String apiValue;
  final String label;

  const SlotStatus(this.apiValue, this.label);

  /// Statut inconnu → traité comme indisponible : un créneau n'est jamais
  /// présenté comme libre sans que le backend l'ait dit.
  static SlotStatus fromApi(String? value) {
    final normalise = value?.trim().toUpperCase();
    return SlotStatus.values.firstWhere(
      (s) => s.apiValue == normalise,
      orElse: () => SlotStatus.bloque,
    );
  }

  /// Fond du créneau (légende du calendrier).
  Color background(ColorScheme scheme) {
    switch (this) {
      case SlotStatus.libre:
        return const Color(0xFF2E9D63).withValues(alpha: 0.14);
      case SlotStatus.reserve:
        return scheme.primary.withValues(alpha: 0.10);
      case SlotStatus.bloque:
        return scheme.surfaceContainerHigh;
    }
  }

  /// Couleur de la pastille de légende.
  Color indicator(ColorScheme scheme) {
    switch (this) {
      case SlotStatus.libre:
        return const Color(0xFF2E9D63);
      case SlotStatus.reserve:
        return scheme.primary.withValues(alpha: 0.35);
      case SlotStatus.bloque:
        return scheme.outline;
    }
  }
}
