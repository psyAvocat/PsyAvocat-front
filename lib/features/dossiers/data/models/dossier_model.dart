/// Modèle représentant un dossier juridique dans PsyAvocat.
class DossierModel {
  final String id;
  final String reference;
  final String titre;
  final String description;
  final String statut; // EN_COURS | EN_ATTENTE | ACCEPTE | REJETE | CLOS
  final DateTime dateCreation;
  final List<SoumissionModel> soumissions;

  const DossierModel({
    required this.id,
    required this.reference,
    required this.titre,
    required this.description,
    required this.statut,
    required this.dateCreation,
    this.soumissions = const [],
  });

  factory DossierModel.fromJson(Map<String, dynamic> json) {
    final soumissionsList =
        (json['soumissions'] as List<dynamic>?)
            ?.map((e) => SoumissionModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return DossierModel(
      id: json['id'] as String? ?? '',
      reference: json['reference'] as String? ?? '',
      titre: json['titre'] as String? ?? 'Sans titre',
      description: json['description'] as String? ?? '',
      statut: json['statut'] as String? ?? 'EN_ATTENTE',
      dateCreation:
          DateTime.tryParse(json['dateCreation'] as String? ?? '') ??
          DateTime.now(),
      soumissions: soumissionsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reference': reference,
      'titre': titre,
      'description': description,
      'statut': statut,
      'dateCreation': dateCreation.toIso8601String(),
      'soumissions': soumissions.map((s) => s.toJson()).toList(),
    };
  }
}

class SoumissionModel {
  final String id;
  final String avocatNom;
  final String avocatPrenom;
  final String statut; // EN_ATTENTE | ACCEPTE | REJETE
  final String? reponse;
  final double? montantPropose;

  const SoumissionModel({
    required this.id,
    required this.avocatNom,
    required this.avocatPrenom,
    required this.statut,
    this.reponse,
    this.montantPropose,
  });

  String get displayName => 'Maître $avocatPrenom $avocatNom'.trim();

  factory SoumissionModel.fromJson(Map<String, dynamic> json) {
    return SoumissionModel(
      id: json['id'] as String? ?? '',
      avocatNom: json['avocatNom'] as String? ?? '',
      avocatPrenom: json['avocatPrenom'] as String? ?? '',
      statut: json['statut'] as String? ?? 'EN_ATTENTE',
      reponse: json['reponse'] as String?,
      montantPropose: (json['montantPropose'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'avocatNom': avocatNom,
      'avocatPrenom': avocatPrenom,
      'statut': statut,
      if (reponse != null) 'reponse': reponse,
      if (montantPropose != null) 'montantPropose': montantPropose,
    };
  }
}
