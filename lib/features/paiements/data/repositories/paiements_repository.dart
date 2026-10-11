import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_providers.dart';
import '../models/paiement_model.dart';

abstract class PaiementsRepository {
  Future<List<PaiementModel>> getMesPaiements();
}

/// `GET /api/paiements` : paiements (simulés) du client connecté.
/// Les erreurs sont propagées : jamais converties en liste vide.
class ApiPaiementsRepository implements PaiementsRepository {
  final ApiClient _client;

  ApiPaiementsRepository(this._client);

  @override
  Future<List<PaiementModel>> getMesPaiements() async {
    final response = await _client.get('/paiements');
    final list = response.data as List<dynamic>? ?? [];
    return list
        .map((item) => PaiementModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}

final paiementsRepositoryProvider = Provider<PaiementsRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ApiPaiementsRepository(client);
});
