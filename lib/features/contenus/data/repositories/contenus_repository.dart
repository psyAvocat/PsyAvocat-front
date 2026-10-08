import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_providers.dart';
import '../models/contenu_model.dart';

/// Ordre d'affichage des publications.
enum PublicationSort {
  /// Plus récentes d'abord.
  recent('recent'),

  /// Plus consultées d'abord (nombre réel de consultations).
  populaire('populaire');

  final String apiValue;

  const PublicationSort(this.apiValue);
}

/// Articles et Conseils publiés depuis l'espace professionnel Angular.
abstract class ContenusRepository {
  /// [type] : `ARTICLE` (univers Avocat) ou `CONSEIL` (univers Psychologue).
  Future<List<Publication>> rechercher({
    required String type,
    String? q,
    String? specialiteId,
    PublicationSort tri = PublicationSort.recent,
  });

  /// Détail (404 « ressource indisponible » si désactivé ou supprimé).
  Future<Publication> getPublication(String id);
}

class ApiContenusRepository implements ContenusRepository {
  final ApiClient _client;

  ApiContenusRepository(this._client);

  @override
  Future<List<Publication>> rechercher({
    required String type,
    String? q,
    String? specialiteId,
    PublicationSort tri = PublicationSort.recent,
  }) async {
    final response = await _client.get(
      '/contenus',
      queryParameters: {
        'type': type,
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        'specialiteId': ?specialiteId,
        'tri': tri.apiValue,
      },
    );
    final list = response.data as List<dynamic>? ?? [];
    return list.map((e) => Publication.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Publication> getPublication(String id) async {
    final response = await _client.get('/contenus/$id');
    return Publication.fromJson(response.data as Map<String, dynamic>);
  }
}

final contenusRepositoryProvider = Provider<ContenusRepository>((ref) {
  return ApiContenusRepository(ref.watch(apiClientProvider));
});
