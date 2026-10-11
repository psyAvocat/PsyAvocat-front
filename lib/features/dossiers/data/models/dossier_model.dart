/// Dossier juridique du justiciable (`DossierResponseDTO` du backend).
///
/// Statuts du dossier : `OUVERT` (soumis, en attente d'une prise en charge)
/// puis `PRIS_EN_CHARGE` (un avocat a accepté : dossier confié en exclusivité).
class DossierModel {
  final String id;
  final String titre;
  final String description;
  final String statut;
  final DateTime? dateOuverture;
  final String? domaineNom;
  final List<SoumissionModel> soumissions;
  final List<PieceJointeModel> piecesJointes;

  const DossierModel({
    required this.id,
    required this.titre,
    required this.description,
    required this.statut,
    this.dateOuverture,
    this.domaineNom,
    this.soumissions = const [],
    this.piecesJointes = const [],
  });

  bool get estPrisEnCharge => statut == 'PRIS_EN_CHARGE';

  /// Soumission de l'avocat qui a accepté la prise en charge, s'il y en a une.
  SoumissionModel? get soumissionRetenue {
    for (final s in soumissions) {
      if (s.estAcceptee) return s;
    }
    return null;
  }

  factory DossierModel.fromJson(Map<String, dynamic> json) {
    return DossierModel(
      id: json['id'] as String? ?? '',
      titre: json['titre'] as String? ?? '',
      description: json['description'] as String? ?? '',
      statut: json['statut'] as String? ?? 'OUVERT',
      dateOuverture: DateTime.tryParse(json['dateOuverture'] as String? ?? ''),
      domaineNom: json['specialiteNom'] as String?,
      soumissions:
          (json['soumissions'] as List<dynamic>?)
              ?.map((e) => SoumissionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      piecesJointes:
          (json['piecesJointes'] as List<dynamic>?)
              ?.map((e) => PieceJointeModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

/// Soumission du dossier à un avocat (`SoumissionDossierResponseDTO`).
///
/// Statuts : `EN_ATTENTE`, `ACCEPTEE` (honoraires proposés), `REFUSEE` (motif),
/// `RETENUE` (rendez-vous pris), `CADUQUE` (dossier confié à un confrère).
class SoumissionModel {
  final String id;
  final String avocatId;
  final String avocatNom;
  final String avocatPrenom;
  final String statut;
  final String? reponse;
  final double? tarifPropose;
  final DateTime? dateReponse;

  const SoumissionModel({
    required this.id,
    required this.avocatId,
    required this.avocatNom,
    required this.avocatPrenom,
    required this.statut,
    this.reponse,
    this.tarifPropose,
    this.dateReponse,
  });

  String get displayName => 'Me $avocatPrenom $avocatNom'.trim();

  /// Avocat ayant pris en charge le dossier : un rendez-vous peut être pris.
  bool get estAcceptee => statut == 'ACCEPTEE' || statut == 'RETENUE';

  factory SoumissionModel.fromJson(Map<String, dynamic> json) {
    return SoumissionModel(
      id: json['id'] as String? ?? '',
      avocatId: json['avocatId'] as String? ?? '',
      avocatNom: json['avocatNom'] as String? ?? '',
      avocatPrenom: json['avocatPrenom'] as String? ?? '',
      statut: json['statut'] as String? ?? 'EN_ATTENTE',
      reponse: json['reponse'] as String?,
      tarifPropose: (json['tarifPropose'] as num?)?.toDouble(),
      dateReponse: DateTime.tryParse(json['dateReponse'] as String? ?? ''),
    );
  }
}

/// Pièce jointe stockée dans le bucket privé ; [url] est un lien temporaire.
class PieceJointeModel {
  final String id;
  final String nom;
  final String? url;

  const PieceJointeModel({required this.id, required this.nom, this.url});

  factory PieceJointeModel.fromJson(Map<String, dynamic> json) {
    return PieceJointeModel(
      id: json['id'] as String? ?? '',
      nom: json['nom'] as String? ?? '',
      url: json['url'] as String?,
    );
  }
}
