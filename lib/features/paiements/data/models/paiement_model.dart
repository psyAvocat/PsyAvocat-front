import '../../../../core/theme/app_universe.dart';

/// Paiement du client (`PaiementResponseDTO`) : acompte d'un rendez-vous.
/// En V1, tous les paiements sont SIMULÉS ([simulation]) : aucune transaction réelle.
class PaiementModel {
  final String id;
  final double montant;
  final String devise;
  final DateTime? datePaiement;

  /// PAYE (acompte simulé validé) ou ANNULE (rendez-vous annulé).
  final String statut;
  final bool simulation;
  final String? rendezVousId;
  final DateTime? rendezVousDate;
  final double? montantTotalRendezVous;
  final String professionnelNom;
  final String professionnelPrenom;

  /// AVOCAT ou PSYCHOLOGUE.
  final String? typeProfessionnel;

  const PaiementModel({
    required this.id,
    required this.montant,
    required this.devise,
    required this.statut,
    required this.simulation,
    this.datePaiement,
    this.rendezVousId,
    this.rendezVousDate,
    this.montantTotalRendezVous,
    this.professionnelNom = '',
    this.professionnelPrenom = '',
    this.typeProfessionnel,
  });

  /// Univers du paiement (cloisonnement de l'affichage).
  AppUniverse? get universe {
    if (typeProfessionnel == 'AVOCAT') return AppUniverse.lawyer;
    if (typeProfessionnel == 'PSYCHOLOGUE') return AppUniverse.psychologist;
    return null;
  }

  String get professionnel {
    final nom = '$professionnelPrenom $professionnelNom'.trim();
    if (nom.isEmpty) return '';
    return typeProfessionnel == 'AVOCAT' ? 'Me $nom' : 'Dr $nom';
  }

  bool get estAnnule => statut == 'ANNULE';

  factory PaiementModel.fromJson(Map<String, dynamic> json) {
    return PaiementModel(
      id: json['id'] as String? ?? '',
      montant: (json['montant'] as num?)?.toDouble() ?? 0,
      devise: json['devise'] as String? ?? 'XOF',
      datePaiement: DateTime.tryParse(json['datePaiement'] as String? ?? ''),
      statut: json['statut'] as String? ?? '',
      simulation: json['simulation'] as bool? ?? false,
      rendezVousId: json['rendezVousId'] as String?,
      rendezVousDate: DateTime.tryParse(json['rendezVousDate'] as String? ?? ''),
      montantTotalRendezVous: (json['montantTotalRendezVous'] as num?)?.toDouble(),
      professionnelNom: json['professionnelNom'] as String? ?? '',
      professionnelPrenom: json['professionnelPrenom'] as String? ?? '',
      typeProfessionnel: json['typeProfessionnel'] as String?,
    );
  }
}
