import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Statut d'un rendez-vous, converti depuis les valeurs réelles du backend
/// (`RendezVous.statut` : CONFIRME, EN_ATTENTE, PASSE, ANNULE).
enum AppointmentStatus {
  confirme('CONFIRME', 'Confirmé'),
  enAttente('EN_ATTENTE', 'En attente'),
  passe('PASSE', 'Terminé'),
  annule('ANNULE', 'Annulé'),
  inconnu('', 'Statut inconnu');

  final String apiValue;
  final String label;

  const AppointmentStatus(this.apiValue, this.label);

  static AppointmentStatus fromApi(String? value) {
    final normalise = value?.trim().toUpperCase();
    return AppointmentStatus.values.firstWhere(
      (s) => s.apiValue == normalise && s != AppointmentStatus.inconnu,
      orElse: () => AppointmentStatus.inconnu,
    );
  }

  /// Couleur fonctionnelle (vert = confirmé, orange = en attente, rouge = annulé).
  Color color(ColorScheme scheme) {
    switch (this) {
      case AppointmentStatus.confirme:
        return AppColors.successText;
      case AppointmentStatus.enAttente:
        return AppColors.warningText;
      case AppointmentStatus.annule:
        return scheme.error;
      case AppointmentStatus.passe:
      case AppointmentStatus.inconnu:
        return scheme.onSurfaceVariant;
    }
  }
}

/// Onglet d'affichage d'un rendez-vous, déduit du statut et des horaires réels.
enum AppointmentPhase {
  aVenir('À venir'),
  enCours('En cours'),
  passe('Passés');

  final String label;

  const AppointmentPhase(this.label);
}
