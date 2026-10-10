import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_providers.dart';
import '../models/dossier_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Repository Dossier — Interface abstraite & Implémentation API
// ─────────────────────────────────────────────────────────────────────────────

abstract class DossierRepository {
  Future<List<DossierModel>> getMyDossiers();
  Future<DossierModel> getDossierById(String id);
  Future<DossierModel> createDossier({
    required String titre,
    required String description,
    required String domaine,
  });
}

class ApiDossierRepository implements DossierRepository {
  final ApiClient _client;

  ApiDossierRepository(this._client);

  @override
  Future<List<DossierModel>> getMyDossiers() async {
    try {
      final response = await _client.get('/dossiers');
      final list = response.data as List<dynamic>? ?? [];
      return list
          .map((e) => DossierModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<DossierModel> getDossierById(String id) async {
    final response = await _client.get('/dossiers/$id');
    return DossierModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<DossierModel> createDossier({
    required String titre,
    required String description,
    required String domaine,
  }) async {
    final response = await _client.post(
      '/dossiers',
      data: {'titre': titre, 'description': description, 'domaine': domaine},
    );
    return DossierModel.fromJson(response.data as Map<String, dynamic>);
  }
}

final dossierRepositoryProvider = Provider<DossierRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ApiDossierRepository(client);
});
