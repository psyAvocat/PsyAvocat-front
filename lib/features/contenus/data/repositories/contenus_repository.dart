import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_providers.dart';
import '../models/contenu_model.dart';

abstract class ContenusRepository {
  Future<List<ContenuModel>> getContenus({String? univers});
  Future<ContenuModel?> getContenuById(String id);
}

/// Implémentation officielle connectée à l'API Spring Boot
/// - GET /api/contenus
/// - GET /api/contenus/{id}
class ApiContenusRepository implements ContenusRepository {
  final ApiClient _client;

  ApiContenusRepository(this._client);

  @override
  Future<List<ContenuModel>> getContenus({String? univers}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (univers != null && univers.isNotEmpty) {
        queryParams['univers'] = univers;
      }
      final response = await _client.get('/contenus', queryParameters: queryParams);
      final list = response.data as List<dynamic>? ?? [];
      return list
          .map((item) => ContenuModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Retourne une liste vide en cas d'indisponibilité ou 404 (pas de données métier fictives)
      return [];
    }
  }

  @override
  Future<ContenuModel?> getContenuById(String id) async {
    try {
      final response = await _client.get('/contenus/$id');
      if (response.data != null) {
        return ContenuModel.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

final contenusRepositoryProvider = Provider<ContenusRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ApiContenusRepository(client);
});
