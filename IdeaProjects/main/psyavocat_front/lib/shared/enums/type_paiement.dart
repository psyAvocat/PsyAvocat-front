/// Types de paiement supportés par PsyAvocat (Chapitre 19 de project_context.md).
enum TypePaiement {
  rendezVous('RENDEZ_VOUS', 'Rendez-vous'),
  abonnement('ABONNEMENT', 'Abonnement professionnel');

  final String code;
  final String label;

  const TypePaiement(this.code, this.label);

  static TypePaiement fromCode(String? code) {
    return TypePaiement.values.firstWhere(
      (p) => p.code == code,
      orElse: () => TypePaiement.rendezVous,
    );
  }
}
