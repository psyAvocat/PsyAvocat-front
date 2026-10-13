import '../../../professionnels/data/models/creneau.dart';
import '../../../professionnels/data/models/professionnel_detail.dart';
import '../../../../core/l10n/app_strings.dart';

/// Point d'entrée du tunnel de réservation.
///
/// - Psychologue : réservation directe d'un créneau, au prix d'un tarif publié ([tarif]).
/// - Avocat : uniquement après acceptation d'un dossier ; le montant est celui
///   proposé par l'avocat ([soumissionId], [montantDossier]).
/// Le backend revérifie toujours le montant : aucun prix n'est décidé par l'application.
class ReservationContexte {
  final String professionnelId;
  final Tarif? tarif;
  final String? soumissionId;
  final String? dossierTitre;
  final double? montantDossier;

  /// Créneau déjà touché sur la fiche du professionnel (présélectionné s'il est
  /// toujours libre à l'arrivée sur l'écran de choix).
  final Creneau? creneauPropose;

  const ReservationContexte.psychologue({
    required this.professionnelId,
    required Tarif this.tarif,
    this.creneauPropose,
  }) : soumissionId = null,
       dossierTitre = null,
       montantDossier = null;

  const ReservationContexte.avocat({
    required this.professionnelId,
    required String this.soumissionId,
    required this.dossierTitre,
    required double this.montantDossier,
    this.creneauPropose,
  }) : tarif = null;

  bool get viaDossier => soumissionId != null;

  /// Montant total du rendez-vous (donnée serveur : tarif publié ou honoraires acceptés).
  double get montantTotal => viaDossier ? montantDossier! : tarif!.montant;

  String get libelleMontant =>
      viaDossier ? tr('Honoraires proposés') : (tarif?.titre ?? 'Consultation');
}

/// Récapitulatif transmis à l'écran de confirmation et de paiement simulé.
class ReservationRecap {
  final ReservationContexte contexte;
  final ProfessionnelDetail professionnel;
  final Creneau creneau;

  /// Code backend : VISIO ou CABINET.
  final String mode;
  final String? motif;

  const ReservationRecap({
    required this.contexte,
    required this.professionnel,
    required this.creneau,
    required this.mode,
    this.motif,
  });

  /// Taux d'acompte de la V1 : 20 % du montant total (recalculé et imposé par le backend).
  static const tauxAcompte = 0.20;

  double get montantTotal => contexte.montantTotal;

  /// Montant indicatif ; la valeur faisant foi est celle renvoyée par le backend.
  double get acompteEstime =>
      (montantTotal * tauxAcompte * 100).roundToDouble() / 100;
}
