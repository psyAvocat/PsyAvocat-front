/// Article (publié par un avocat) ou Conseil (publié par un psychologue),
/// tel que renvoyé par Spring Boot (ContenuResponseDTO).
class Publication {
  final String id;

  /// ARTICLE ou CONSEIL.
  final String type;
  final String titre;
  final String? description;

  /// Texte complet (renvoyé uniquement par le détail).
  final String? contenu;
  final DateTime? datePublication;
  final String? auteurId;
  final String? auteurNom;
  final String? auteurPrenom;
  final String? auteurPhotoUrl;
  final String? specialiteId;
  final String? specialiteNom;
  final String? imageUrl;
  final int? tempsLectureMinutes;

  const Publication({
    required this.id,
    required this.type,
    required this.titre,
    this.description,
    this.contenu,
    this.datePublication,
    this.auteurId,
    this.auteurNom,
    this.auteurPrenom,
    this.auteurPhotoUrl,
    this.specialiteId,
    this.specialiteNom,
    this.imageUrl,
    this.tempsLectureMinutes,
  });

  factory Publication.fromJson(Map<String, dynamic> json) {
    return Publication(
      id: json['id']?.toString() ?? '',
      type: json['type'] as String? ?? '',
      titre: json['titre'] as String? ?? '',
      description: json['description'] as String?,
      contenu: json['contenu'] as String?,
      datePublication: DateTime.tryParse(json['datePublication'] as String? ?? ''),
      auteurId: json['auteurId'] as String?,
      auteurNom: json['auteurNom'] as String?,
      auteurPrenom: json['auteurPrenom'] as String?,
      auteurPhotoUrl: json['auteurPhotoUrl'] as String?,
      specialiteId: json['specialiteId'] as String?,
      specialiteNom: json['specialiteNom'] as String?,
      imageUrl: json['imageUrl'] as String?,
      tempsLectureMinutes: (json['tempsLectureMinutes'] as num?)?.toInt(),
    );
  }

  bool get isArticle => type == 'ARTICLE';

  /// « Me Thomas Bernard » (article) ou « Dr Marc Dupont » (conseil).
  String? get auteurDisplayName {
    final nom = '${auteurPrenom ?? ''} ${auteurNom ?? ''}'.trim();
    if (nom.isEmpty) return null;
    return isArticle ? 'Me $nom' : 'Dr $nom';
  }
}
