/// Spécialité du référentiel administré (Admin Angular), propre à un univers.
class Specialite {
  final String id;
  final String nom;
  final String? description;

  const Specialite({required this.id, required this.nom, this.description});

  factory Specialite.fromJson(Map<String, dynamic> json) {
    return Specialite(
      id: json['id']?.toString() ?? '',
      nom: json['nom'] as String? ?? '',
      description: json['description'] as String?,
    );
  }
}
