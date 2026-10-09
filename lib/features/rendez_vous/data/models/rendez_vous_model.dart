import '../../../../core/theme/app_universe.dart';
import '../../../../shared/enums/appointment_status.dart';

/// Rendez-vous de l'utilisateur, tel que renvoyé par Spring Boot (RendezVousResponseDTO).
/// Aucune valeur n'est complétée côté Flutter : un champ absent n'est pas affiché.
class RendezVous {
  final String id;
  final DateTime dateHeure;
  final DateTime? dateFin;
  final int? dureeMinutes;
  final AppointmentStatus statut;

  /// VISIO ou CABINET.
  final String? mode;
  final String? motif;
  final String? lienVisio;
  final String? adresseCabinet;
  final double? montantTotal;
  final double? montantAcompte;
  final String? devise;
  final String? statutPaiement;
  final String? disponibiliteId;

  final String professionnelId;
  final String professionnelNom;
  final String professionnelPrenom;

  /// AVOCAT ou PSYCHOLOGUE : détermine l'univers du rendez-vous.
  final String typeProfessionnel;
  final String? professionnelPhotoUrl;
  final String? professionnelSpecialite;

  const RendezVous({
    required this.id,
    required this.dateHeure,
    required this.statut,
    required this.professionnelId,
    required this.professionnelNom,
    required this.professionnelPrenom,
    required this.typeProfessionnel,
    this.dateFin,
    this.dureeMinutes,
    this.mode,
    this.motif,
    this.lienVisio,
    this.adresseCabinet,
    this.montantTotal,
    this.montantAcompte,
    this.devise,
    this.statutPaiement,
    this.disponibiliteId,
    this.professionnelPhotoUrl,
    this.professionnelSpecialite,
  });

  factory RendezVous.fromJson(Map<String, dynamic> json) {
    return RendezVous(
      id: json['id']?.toString() ?? '',
      dateHeure: DateTime.parse(json['dateHeure'] as String),
      dateFin: DateTime.tryParse(json['dateFin'] as String? ?? ''),
      dureeMinutes: (json['dureeMinutes'] as num?)?.toInt(),
      statut: AppointmentStatus.fromApi(json['statut'] as String?),
      mode: json['mode'] as String?,
      motif: json['motif'] as String?,
      lienVisio: json['lienVisio'] as String?,
      adresseCabinet: json['adresseCabinet'] as String?,
      montantTotal: (json['montantTotal'] as num?)?.toDouble(),
      montantAcompte: (json['montantAcompte'] as num?)?.toDouble(),
      devise: json['devise'] as String?,
      statutPaiement: json['statutPaiement'] as String?,
      disponibiliteId: json['disponibiliteId'] as String?,
      professionnelId: json['professionnelId']?.toString() ?? '',
      professionnelNom: json['professionnelNom'] as String? ?? '',
      professionnelPrenom: json['professionnelPrenom'] as String? ?? '',
      typeProfessionnel: json['typeProfessionnel'] as String? ?? '',
      professionnelPhotoUrl: json['professionnelPhotoUrl'] as String?,
      professionnelSpecialite: json['professionnelSpecialite'] as String?,
    );
  }

  /// Univers auquel appartient ce rendez-vous.
  AppUniverse get universe => typeProfessionnel == 'AVOCAT'
      ? AppUniverse.lawyer
      : AppUniverse.psychologist;

  String get professionnelDisplayName {
    final nom = '$professionnelPrenom $professionnelNom'.trim();
    return typeProfessionnel == 'AVOCAT' ? 'Me $nom' : 'Dr $nom';
  }

  /// Fin réelle (renvoyée par le backend), sinon début + durée.
  DateTime get fin =>
      dateFin ?? dateHeure.add(Duration(minutes: dureeMinutes ?? 45));

  /// Onglet d'affichage, calculé à partir du statut backend et de l'heure réelle.
  AppointmentPhase phaseAt(DateTime now) {
    final actif =
        statut == AppointmentStatus.confirme ||
        statut == AppointmentStatus.enAttente;
    if (actif && dateHeure.isAfter(now)) return AppointmentPhase.aVenir;
    if (statut == AppointmentStatus.confirme &&
        !dateHeure.isAfter(now) &&
        fin.isAfter(now)) {
      return AppointmentPhase.enCours;
    }
    return AppointmentPhase.passe;
  }

  /// Modifiable / annulable : rendez-vous actif qui n'a pas encore commencé.
  bool canBeChangedAt(DateTime now) =>
      (statut == AppointmentStatus.confirme ||
          statut == AppointmentStatus.enAttente) &&
      dateHeure.isAfter(now);
}
