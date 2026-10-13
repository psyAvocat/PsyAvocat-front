import '../../../../shared/enums/mode_consultation.dart';

/// Résumé d'un professionnel pour les listes (cartes), construit à partir de
/// `ProfessionnelResponseDTO` (GET /api/professionnels).
///
/// Aucune valeur n'est inventée : un champ absent de l'API reste vide
/// et la carte ne l'affiche pas.
class ProfessionnelSummary {
  final String id;
  final String fullName;
  final String? photoUrl;
  final String? ville;
  final List<String> specialites;
  final double? noteMoyenne;
  final int nombreAvis;
  final String? modeConsultation;

  /// AVOCAT ou PSYCHOLOGUE.
  final String? type;

  /// Indicateur « en ligne » renseigné par le backend.
  final bool enLigne;

  const ProfessionnelSummary({
    required this.id,
    required this.fullName,
    this.photoUrl,
    this.ville,
    this.specialites = const [],
    this.noteMoyenne,
    this.nombreAvis = 0,
    this.modeConsultation,
    this.type,
    this.enLigne = false,
  });

  factory ProfessionnelSummary.fromJson(Map<String, dynamic> json) {
    final prenom = (json['prenom'] as String? ?? '').trim();
    final nom = (json['nom'] as String? ?? '').trim();

    final specialites = (json['specialites'] as List<dynamic>? ?? [])
        .map(
          (s) => s is Map<String, dynamic>
              ? s['nom'] as String? ?? ''
              : s.toString(),
        )
        .where((s) => s.isNotEmpty)
        .toList();

    return ProfessionnelSummary(
      id: json['id']?.toString() ?? '',
      fullName: [prenom, nom].where((part) => part.isNotEmpty).join(' '),
      photoUrl: json['photoUrl'] as String?,
      ville: json['ville'] as String?,
      specialites: specialites,
      noteMoyenne: (json['noteMoyenne'] as num?)?.toDouble(),
      nombreAvis: (json['nombreAvis'] as num?)?.toInt() ?? 0,
      modeConsultation: json['modeConsultation'] as String?,
      type: json['type'] as String?,
      enLigne: json['enLigne'] as bool? ?? false,
    );
  }

  /// La note n'a de sens que si au moins un avis existe.
  bool get hasRating => noteMoyenne != null && nombreAvis > 0;

  bool get isAvocat => type == 'AVOCAT';

  /// « Me » pour un avocat, « Dr » pour un psychologue (usage professionnel).
  String get displayName {
    if (type == 'AVOCAT') return 'Me $fullName';
    if (type == 'PSYCHOLOGUE') return 'Dr $fullName';
    return fullName;
  }

  /// Libellé lisible du mode de consultation (valeur brute si code inconnu).
  String? get modeConsultationLabel {
    final code = modeConsultation?.trim();
    if (code == null || code.isEmpty) return null;
    for (final mode in ModeConsultation.values) {
      if (mode.code == code.toUpperCase()) return mode.label;
    }
    return code;
  }
}
