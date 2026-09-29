/// Modèle représentant le détail complet d'un professionnel (Avocat ou Psychologue).
class ProfessionalTarif {
  final String titre;
  final int montantFcfa;
  final String? description;

  const ProfessionalTarif({
    required this.titre,
    required this.montantFcfa,
    this.description,
  });

  String get formattedPrice {
    final s = montantFcfa.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(s[i]);
    }
    return '${buffer.toString()} FCFA';
  }
}

class DisponibiliteJour {
  final String date; // YYYY-MM-DD
  final String labelJour; // ex: "Lun"
  final String labelNumero; // ex: "14"
  final String labelMois; // ex: "Avr"
  final List<String> creneaux; // ex: ["09:00", "10:00", "11:30"]

  const DisponibiliteJour({
    required this.date,
    required this.labelJour,
    required this.labelNumero,
    required this.labelMois,
    required this.creneaux,
  });
}

class ProfessionalDetail {
  final String id;
  final String nom;
  final String titre;
  final String specialitePrincipale;
  final List<String> specialites;
  final String ville;
  final String adresse;
  final String distance;
  final String imagePath;
  final double note;
  final int nombreAvis;
  final String biographie;
  final List<ProfessionalTarif> tarifs;
  final List<String> langues;
  final bool enLigne;
  final bool isAvocat;
  final List<DisponibiliteJour> disponibilites;

  const ProfessionalDetail({
    required this.id,
    required this.nom,
    required this.titre,
    required this.specialitePrincipale,
    required this.specialites,
    required this.ville,
    required this.adresse,
    required this.distance,
    required this.imagePath,
    required this.note,
    required this.nombreAvis,
    required this.biographie,
    required this.tarifs,
    required this.langues,
    this.enLigne = true,
    this.isAvocat = true,
    required this.disponibilites,
  });
}
