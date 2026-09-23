/// Rôles des acteurs du système PsyAvocat.
enum UserRole {
  patient('PATIENT', 'Patient'),
  justiciable('JUSTICIABLE', 'Justiciable / Client'),
  avocat('AVOCAT', 'Avocat'),
  psychologue('PSYCHOLOGUE', 'Psychologue'),
  admin('ADMINISTRATEUR', 'Administrateur');

  final String code;
  final String label;

  const UserRole(this.code, this.label);

  static UserRole fromCode(String? code) {
    return UserRole.values.firstWhere(
      (r) => r.code == code,
      orElse: () => UserRole.patient,
    );
  }
}
