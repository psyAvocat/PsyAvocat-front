/// Modèle pour les articles, guides et contenus de vulgarisation PsyAvocat
class ContenuModel {
  final String id;
  final String titre;
  final String extrait;
  final String contenuComplet;
  final String categorie;
  final String univers; // JURIDIQUE | PSYCHOLOGIQUE | MIXTE
  final String auteur;
  final String auteurTitre;
  final String dureeLecture;
  final DateTime datePublication;
  final List<String> tags;

  const ContenuModel({
    required this.id,
    required this.titre,
    required this.extrait,
    required this.contenuComplet,
    required this.categorie,
    required this.univers,
    required this.auteur,
    required this.auteurTitre,
    required this.dureeLecture,
    required this.datePublication,
    this.tags = const [],
  });

  factory ContenuModel.fromJson(Map<String, dynamic> json) {
    return ContenuModel(
      id: json['id'] as String? ?? '',
      titre: json['titre'] as String? ?? '',
      extrait: json['extrait'] as String? ?? '',
      contenuComplet: json['contenuComplet'] as String? ?? '',
      categorie: json['categorie'] as String? ?? '',
      univers: json['univers'] as String? ?? 'MIXTE',
      auteur: json['auteur'] as String? ?? '',
      auteurTitre: json['auteurTitre'] as String? ?? '',
      dureeLecture: json['dureeLecture'] as String? ?? '3 min',
      datePublication: DateTime.tryParse(json['datePublication'] as String? ?? '') ?? DateTime.now(),
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titre': titre,
      'extrait': extrait,
      'contenuComplet': contenuComplet,
      'categorie': categorie,
      'univers': univers,
      'auteur': auteur,
      'auteurTitre': auteurTitre,
      'dureeLecture': dureeLecture,
      'datePublication': datePublication.toIso8601String(),
      'tags': tags,
    };
  }
}
