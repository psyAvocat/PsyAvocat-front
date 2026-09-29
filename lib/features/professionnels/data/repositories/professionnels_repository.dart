import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_providers.dart';
import '../models/professional_detail_model.dart';

/// Contrat du repository de professionnels
abstract class ProfessionnelsRepository {
  Future<List<ProfessionalDetail>> getProfessionnels({bool? isAvocat});
  Future<ProfessionalDetail?> getProfessionnelById(String id);
}

/// Implémentation officielle connectée à l'API Spring Boot
/// - GET /api/professionnels
/// - GET /api/professionnels/{id}
/// - GET /api/disponibilites/professionnel/{id}
class ApiProfessionnelsRepository implements ProfessionnelsRepository {
  final ApiClient _client;

  ApiProfessionnelsRepository(this._client);

  @override
  Future<List<ProfessionalDetail>> getProfessionnels({bool? isAvocat}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (isAvocat != null) {
        queryParams['type'] = isAvocat ? 'AVOCAT' : 'PSYCHOLOGUE';
      }

      final response = await _client.get('/professionnels', queryParameters: queryParams);
      final list = response.data as List<dynamic>? ?? [];

      final results = <ProfessionalDetail>[];
      for (final item in list) {
        final proJson = item as Map<String, dynamic>;
        results.add(_mapToDetail(proJson, []));
      }
      return results;
    } catch (_) {
      // En cas d'erreur ou indisponibilité, renvoyer une liste vide (pas de fausses données)
      return [];
    }
  }

  @override
  Future<ProfessionalDetail?> getProfessionnelById(String id) async {
    try {
      final proRes = await _client.get('/professionnels/$id');
      final proJson = proRes.data as Map<String, dynamic>;

      // Récupération des disponibilités libres depuis MySQL via l'API
      List<DisponibiliteJour> disponibilites = [];
      try {
        final dispoRes = await _client.get('/disponibilites/professionnel/$id');
        final dispoList = dispoRes.data as List<dynamic>? ?? [];
        disponibilites = _groupDisponibilites(dispoList);
      } catch (_) {}

      return _mapToDetail(proJson, disponibilites);
    } catch (_) {
      return null;
    }
  }

  ProfessionalDetail _mapToDetail(
    Map<String, dynamic> json,
    List<DisponibiliteJour> disponibilites,
  ) {
    final prenom = json['prenom'] as String? ?? '';
    final nom = json['nom'] as String? ?? '';
    final type = (json['type'] as String? ?? 'AVOCAT').toUpperCase();
    final isAvocat = type == 'AVOCAT';

    final fullNom = prenom.isNotEmpty ? '$prenom $nom' : nom;
    final specialitesRaw = json['specialites'] as List<dynamic>? ?? [];
    final specialites = specialitesRaw
        .map((s) {
          if (s is Map<String, dynamic>) {
            return s['nom'] as String? ?? '';
          }
          return s.toString();
        })
        .where((s) => s.isNotEmpty)
        .toList();

    final specialitePrincipale = specialites.isNotEmpty
        ? specialites.first
        : (isAvocat ? 'Droit général' : 'Psychologie clinique');

    final tarifsRaw = json['tarifs'] as List<dynamic>? ?? [];
    final tarifs = tarifsRaw.map((t) {
      final map = t as Map<String, dynamic>;
      return ProfessionalTarif(
        titre: map['titre'] as String? ?? 'Consultation',
        montantFcfa: (map['montant'] as num?)?.toInt() ?? 0,
        description: map['description'] as String?,
      );
    }).toList();

    final languesStr = json['langues'] as String? ?? 'Français';
    final langues = languesStr.split(',').map((l) => l.trim()).toList();
    final ville = json['ville'] as String? ?? '';
    final note = (json['noteMoyenne'] as num?)?.toDouble() ?? 0.0;
    final nombreAvis = (json['nombreAvis'] as num?)?.toInt() ?? 0;

    return ProfessionalDetail(
      id: json['id']?.toString() ?? '',
      nom: isAvocat ? 'Maître $fullNom'.trim() : 'Dr. $fullNom'.trim(),
      titre: isAvocat ? 'Avocat au barreau' : 'Psychologue clinicien(ne)',
      specialitePrincipale: specialitePrincipale,
      specialites: specialites,
      ville: ville,
      adresse: json['adresse'] as String? ?? '',
      distance: ville.isNotEmpty ? ville : 'À distance',
      imagePath: isAvocat
          ? 'assets/images/onboarding_lawyer.png'
          : 'assets/images/onboarding_psy.png',
      note: note,
      nombreAvis: nombreAvis,
      biographie: json['biographie'] as String? ?? '',
      tarifs: tarifs,
      langues: langues,
      enLigne: json['enLigne'] as bool? ?? true,
      isAvocat: isAvocat,
      disponibilites: disponibilites,
    );
  }

  List<DisponibiliteJour> _groupDisponibilites(List<dynamic> list) {
    final Map<String, List<String>> byDate = {};
    for (final item in list) {
      final map = item as Map<String, dynamic>;
      final date = map['date'] as String? ?? '';
      final heure = map['heureDebut'] as String? ?? '';
      if (date.isNotEmpty && heure.isNotEmpty) {
        final creneau = heure.length >= 5 ? heure.substring(0, 5) : heure;
        byDate.putIfAbsent(date, () => []).add(creneau);
      }
    }

    final result = <DisponibiliteJour>[];
    byDate.forEach((dateStr, creneaux) {
      try {
        final dt = DateTime.parse(dateStr);
        final jours = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
        final mois = [
          'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
          'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'
        ];

        result.add(
          DisponibiliteJour(
            date: dateStr,
            labelJour: jours[dt.weekday - 1],
            labelNumero: dt.day.toString().padLeft(2, '0'),
            labelMois: mois[dt.month - 1],
            creneaux: creneaux..sort(),
          ),
        );
      } catch (_) {}
    });

    return result;
  }
}

/// Provider pour injecter le repository officiel de professionnels
final professionnelsRepositoryProvider = Provider<ProfessionnelsRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ApiProfessionnelsRepository(client);
});
