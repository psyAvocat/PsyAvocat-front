import '../../../professionnels/data/models/professionnel_summary.dart';

// Modèles du module d'orientation, alignés sur les DTO Spring Boot
// (QuestionnaireDTO, QuestionDTO, ReponseDTO, ResultatOrientationDTO).
//
// Les pondérations et le calcul du résultat restent exclusivement côté backend :
// Flutter ne lit ni ne manipule aucun poids.

/// Réponse proposée pour une question.
class ReponseModel {
  final String id;
  final String libelle;

  const ReponseModel({required this.id, required this.libelle});

  factory ReponseModel.fromJson(Map<String, dynamic> json) {
    return ReponseModel(
      id: json['id']?.toString() ?? '',
      libelle: json['libelle'] as String? ?? '',
    );
  }
}

/// Question d'un questionnaire, telle que configurée dans l'Admin Angular.
class QuestionModel {
  /// Types de réponse définis par le backend (champ `typeReponse`).
  static const String typeChoixUnique = 'CHOIX_UNIQUE';
  static const String typeChoixMultiple = 'CHOIX_MULTIPLE';
  static const String typeOuiNon = 'OUI_NON';

  final String id;
  final String texte;
  final int ordre;
  final bool obligatoire;
  final String? contexte;
  final String typeReponse;
  final List<ReponseModel> reponses;

  const QuestionModel({
    required this.id,
    required this.texte,
    required this.ordre,
    required this.obligatoire,
    required this.typeReponse,
    required this.reponses,
    this.contexte,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    final reponses = json['reponses'] as List<dynamic>? ?? [];
    return QuestionModel(
      id: json['id']?.toString() ?? '',
      texte: json['texte'] as String? ?? '',
      ordre: (json['ordre'] as num?)?.toInt() ?? 0,
      obligatoire: json['obligatoire'] as bool? ?? true,
      contexte: json['contexte'] as String?,
      // Valeur par défaut identique à celle du backend (entité Question).
      typeReponse:
          (json['typeReponse'] as String?)?.toUpperCase() ?? typeChoixUnique,
      reponses: reponses
          .map((e) => ReponseModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Même règle que la validation Spring Boot : seul CHOIX_MULTIPLE
  /// autorise plusieurs réponses ; tout autre type = une seule réponse.
  bool get allowsMultiple => typeReponse == typeChoixMultiple;

  /// Question Oui / Non : affichée avec les réponses côte à côte.
  bool get isYesNo => typeReponse == typeOuiNon;
}

/// Questionnaire d'orientation (créé et administré depuis l'Admin Angular).
class QuestionnaireModel {
  final String id;
  final String titre;
  final String type;

  /// Questions triées par leur ordre d'affichage.
  final List<QuestionModel> questions;

  const QuestionnaireModel({
    required this.id,
    required this.titre,
    required this.type,
    required this.questions,
  });

  factory QuestionnaireModel.fromJson(Map<String, dynamic> json) {
    final questions =
        (json['questions'] as List<dynamic>? ?? [])
            .map((e) => QuestionModel.fromJson(e as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.ordre.compareTo(b.ordre));

    return QuestionnaireModel(
      id: json['id']?.toString() ?? '',
      titre: json['titre'] as String? ?? '',
      type: json['type'] as String? ?? '',
      questions: questions,
    );
  }
}

/// Score d'une catégorie de besoin dans un résultat (classement du backend).
class CategorieScoreModel {
  final String nom;
  final String? description;
  final int score;
  final int? rang;

  const CategorieScoreModel({
    required this.nom,
    this.description,
    required this.score,
    this.rang,
  });

  factory CategorieScoreModel.fromJson(Map<String, dynamic> json) {
    return CategorieScoreModel(
      nom: json['categorieBesoinNom'] as String? ?? '',
      description: json['categorieBesoinDescription'] as String?,
      score: (json['score'] as num?)?.toInt() ?? 0,
      rang: (json['rang'] as num?)?.toInt(),
    );
  }
}

/// Résultat d'orientation calculé par Spring Boot (POST /api/orientation/evaluer).
class ResultatOrientationModel {
  final String? id;
  final DateTime? dateEvaluation;
  final String? questionnaireTitre;
  final String? categorieBesoinNom;
  final String? categorieBesoinDescription;
  final String? specialiteNom;
  final String? specialiteDescription;
  final String? domaineNom;
  final List<CategorieScoreModel> scoresParCategorie;
  final List<ProfessionnelSummary> professionnelsRecommandes;

  const ResultatOrientationModel({
    this.id,
    this.dateEvaluation,
    this.questionnaireTitre,
    this.categorieBesoinNom,
    this.categorieBesoinDescription,
    this.specialiteNom,
    this.specialiteDescription,
    this.domaineNom,
    this.scoresParCategorie = const [],
    this.professionnelsRecommandes = const [],
  });

  factory ResultatOrientationModel.fromJson(Map<String, dynamic> json) {
    return ResultatOrientationModel(
      id: json['id']?.toString(),
      dateEvaluation: DateTime.tryParse(
        json['dateEvaluation'] as String? ?? '',
      ),
      questionnaireTitre: json['questionnaireTitre'] as String?,
      categorieBesoinNom: json['categorieBesoinNom'] as String?,
      categorieBesoinDescription: json['categorieBesoinDescription'] as String?,
      specialiteNom: json['specialiteNom'] as String?,
      specialiteDescription: json['specialiteDescription'] as String?,
      domaineNom: json['domaineNom'] as String?,
      scoresParCategorie: (json['scoresParCategorie'] as List<dynamic>? ?? [])
          .map((e) => CategorieScoreModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      professionnelsRecommandes:
          (json['professionnelsRecommandes'] as List<dynamic>? ?? [])
              .map(
                (e) => ProfessionnelSummary.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
    );
  }

  /// Intitulé principal de l'orientation : catégorie de besoin (psychologie)
  /// ou spécialité / domaine (droit), selon ce que le backend a renseigné.
  String? get mainLabel => categorieBesoinNom ?? specialiteNom ?? domaineNom;

  String? get mainDescription =>
      categorieBesoinDescription ?? specialiteDescription;
}
