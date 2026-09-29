class ReponseModel {
  final String id;
  final String libelle;
  final String? valeur;
  final int? poids;

  const ReponseModel({
    required this.id,
    required this.libelle,
    this.valeur,
    this.poids,
  });

  factory ReponseModel.fromJson(Map<String, dynamic> json) {
    return ReponseModel(
      id: json['id'] as String? ?? '',
      libelle: json['libelle'] as String? ?? '',
      valeur: json['valeur'] as String?,
      poids: json['poids'] as int?,
    );
  }
}

class QuestionModel {
  final String id;
  final String texte;
  final int ordre;
  final bool obligatoire;
  final List<ReponseModel> reponses;

  const QuestionModel({
    required this.id,
    required this.texte,
    required this.ordre,
    this.obligatoire = true,
    required this.reponses,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    final list = json['reponses'] as List<dynamic>? ?? [];
    return QuestionModel(
      id: json['id'] as String? ?? '',
      texte: json['texte'] as String? ?? '',
      ordre: json['ordre'] as int? ?? 1,
      obligatoire: json['obligatoire'] as bool? ?? true,
      reponses: list.map((e) => ReponseModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class QuestionnaireModel {
  final String id;
  final String titre;
  final String type;
  final bool actif;
  final List<QuestionModel> questions;

  const QuestionnaireModel({
    required this.id,
    required this.titre,
    required this.type,
    this.actif = true,
    required this.questions,
  });

  factory QuestionnaireModel.fromJson(Map<String, dynamic> json) {
    final list = json['questions'] as List<dynamic>? ?? [];
    return QuestionnaireModel(
      id: json['id'] as String? ?? '',
      titre: json['titre'] as String? ?? '',
      type: json['type'] as String? ?? '',
      actif: json['actif'] as bool? ?? true,
      questions: list.map((e) => QuestionModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class ResultatOrientationModel {
  final String? id;
  final double? score;
  final String? questionnaireTitre;
  final String? categorieBesoinNom;
  final String? categorieBesoinDescription;
  final String? specialiteNom;
  final String? specialiteDescription;
  final String? domaineNom;
  final List<dynamic>? professionnelsRecommandes;

  const ResultatOrientationModel({
    this.id,
    this.score,
    this.questionnaireTitre,
    this.categorieBesoinNom,
    this.categorieBesoinDescription,
    this.specialiteNom,
    this.specialiteDescription,
    this.domaineNom,
    this.professionnelsRecommandes,
  });

  factory ResultatOrientationModel.fromJson(Map<String, dynamic> json) {
    return ResultatOrientationModel(
      id: json['id'] as String?,
      score: (json['score'] as num?)?.toDouble(),
      questionnaireTitre: json['questionnaireTitre'] as String?,
      categorieBesoinNom: json['categorieBesoinNom'] as String?,
      categorieBesoinDescription: json['categorieBesoinDescription'] as String?,
      specialiteNom: json['specialiteNom'] as String?,
      specialiteDescription: json['specialiteDescription'] as String?,
      domaineNom: json['domaineNom'] as String?,
      professionnelsRecommandes: json['professionnelsRecommandes'] as List<dynamic>?,
    );
  }
}
