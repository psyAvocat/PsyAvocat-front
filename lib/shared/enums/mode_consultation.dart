import '../../core/l10n/app_strings.dart';

/// Modes de consultation proposés par les professionnels.
enum ModeConsultation {
  cabinet('CABINET', 'En cabinet'),
  visio('VISIO', 'En visioconférence'),
  domicile('DOMICILE', 'À domicile');

  final String code;
  final String _label;

  const ModeConsultation(this.code, this._label);

  /// Libellé dans la langue de l'interface.
  String get label => tr(_label);
}
