import '../../../../shared/models/specialite.dart';
import 'professionnel_summary.dart';

/// Tarif publié par un professionnel (seuls les montants publiés sont réservables).
class Tarif {
  final String id;
  final String titre;
  final double montant;
  final String devise;
  final String? description;
  final int? dureeMinutes;

  const Tarif({
    required this.id,
    required this.titre,
    required this.montant,
    required this.devise,
    this.description,
    this.dureeMinutes,
  });

  factory Tarif.fromJson(Map<String, dynamic> json) {
    return Tarif(
      id: json['id']?.toString() ?? '',
      titre: json['titre'] as String? ?? 'Consultation',
      montant: (json['montant'] as num?)?.toDouble() ?? 0,
      devise: json['devise'] as String? ?? 'XOF',
      description: json['description'] as String?,
      dureeMinutes: (json['dureeMinutes'] as num?)?.toInt(),
    );
  }
}

/// Fiche complète d'un professionnel (GET /api/professionnels/{id}).
class ProfessionnelDetail {
  final ProfessionnelSummary summary;
  final String? biographie;
  final String? adresse;
  final String? langues;
  final List<Specialite> specialites;
  final List<Tarif> tarifs;

  const ProfessionnelDetail({
    required this.summary,
    this.biographie,
    this.adresse,
    this.langues,
    this.specialites = const [],
    this.tarifs = const [],
  });

  factory ProfessionnelDetail.fromJson(Map<String, dynamic> json) {
    return ProfessionnelDetail(
      summary: ProfessionnelSummary.fromJson(json),
      biographie: json['biographie'] as String?,
      adresse: json['adresse'] as String?,
      langues: json['langues'] as String?,
      specialites: (json['specialites'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(Specialite.fromJson)
          .toList(),
      tarifs: (json['tarifs'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(Tarif.fromJson)
          .toList(),
    );
  }

  String get id => summary.id;
}
