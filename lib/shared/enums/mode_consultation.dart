/// Modes de consultation proposés par les professionnels.
enum ModeConsultation {
  cabinet('CABINET', 'En cabinet'),
  visio('VISIO', 'En visioconférence'),
  domicile('DOMICILE', 'À domicile');

  final String code;
  final String label;

  const ModeConsultation(this.code, this.label);

  static ModeConsultation fromCode(String? code) {
    return ModeConsultation.values.firstWhere(
      (m) => m.code == code,
      orElse: () => ModeConsultation.visio,
    );
  }
}
