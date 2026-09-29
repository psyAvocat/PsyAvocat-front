import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_providers.dart';
import '../models/paiement_model.dart';

abstract class PaiementsRepository {
  Future<List<PaiementModel>> getMesPaiements();
}

/// Implémentation officielle connectée à l'API Spring Boot (GET /api/paiements)
class ApiPaiementsRepository implements PaiementsRepository {
  final ApiClient _client;

  ApiPaiementsRepository(this._client);

  @override
  Future<List<PaiementModel>> getMesPaiements() async {
    try {
      final response = await _client.get('/paiements');
      final list = response.data as List<dynamic>? ?? [];
      return list
          .map((item) => PaiementModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Retourne une liste vide propre si indisponible (pas de données métier fictives)
      return [];
    }
  }
}

final paiementsRepositoryProvider = Provider<PaiementsRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ApiPaiementsRepository(client);
});
