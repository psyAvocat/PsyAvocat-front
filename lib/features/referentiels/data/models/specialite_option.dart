/// Spécialité du référentiel administré dans l'Admin Angular
/// (`SpecialiteDTO`), utilisée comme catégorie de filtre.
class SpecialiteOption {
  final String id;
  final String nom;

  const SpecialiteOption({required this.id, required this.nom});

  factory SpecialiteOption.fromJson(Map<String, dynamic> json) {
    return SpecialiteOption(
      id: json['id']?.toString() ?? '',
      nom: json['nom'] as String? ?? '',
    );
  }
}
