import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../shared/models/specialite.dart';
import '../models/creneau.dart';
import '../models/professionnel_detail.dart';
import '../models/professionnel_summary.dart';

/// Professionnels, créneaux et spécialités (Spring Boot).
/// Les erreurs remontent en AppException : chaque écran affiche son état d'erreur.
abstract class ProfessionnelsRepository {
  /// Professionnels validés et actifs d'un type (`AVOCAT` / `PSYCHOLOGUE`).
  Future<List<ProfessionnelSummary>> searchProfessionnels({
    String? type,
    String? q,
    String? specialiteId,
  });

  /// Fiche publique (404 « ressource indisponible » si suspendu ou non validé).
  Future<ProfessionnelDetail> getProfessionnel(String id);

  /// Créneaux à venir, libres ET réservés (légende du calendrier).
  Future<List<Creneau>> getCreneaux(String professionnelId);

  /// Spécialités du référentiel pour un univers.
  Future<List<Specialite>> getSpecialites(String type);
}

class ApiProfessionnelsRepository implements ProfessionnelsRepository {
  final ApiClient _client;

  ApiProfessionnelsRepository(this._client);

  @override
  Future<List<ProfessionnelSummary>> searchProfessionnels({
    String? type,
    String? q,
    String? specialiteId,
  }) async {
    final response = await _client.get(
      '/professionnels',
      queryParameters: {
        'type': ?type,
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        'specialiteId': ?specialiteId,
      },
    );
    final list = response.data as List<dynamic>? ?? [];
    return list
        .map(
          (item) => ProfessionnelSummary.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Future<ProfessionnelDetail> getProfessionnel(String id) async {
    final response = await _client.get('/professionnels/$id');
    return ProfessionnelDetail.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<Creneau>> getCreneaux(String professionnelId) async {
    final response = await _client.get(
      '/disponibilites/professionnel/$professionnelId',
      queryParameters: {'inclureReserves': true},
    );
    final list = response.data as List<dynamic>? ?? [];
    return list.map((e) => Creneau.fromJson(e as Map<String, dynamic>)).toList()
      ..sort((a, b) => a.debut.compareTo(b.debut));
  }

  @override
  Future<List<Specialite>> getSpecialites(String type) async {
    final response = await _client.get(
      '/referentiels/specialites',
      queryParameters: {'type': type},
    );
    final list = response.data as List<dynamic>? ?? [];
    return list
        .map((e) => Specialite.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.nom.compareTo(b.nom));
  }
}

final professionnelsRepositoryProvider = Provider<ProfessionnelsRepository>((
  ref,
) {
  return ApiProfessionnelsRepository(ref.watch(apiClientProvider));
});
