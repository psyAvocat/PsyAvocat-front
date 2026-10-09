import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_providers.dart';
import '../models/specialite_option.dart';

/// Référentiels administrés (Admin Angular → Spring Boot → MySQL).
abstract class ReferentielRepository {
  /// GET /api/referentiels/specialites?type=AVOCAT|PSYCHOLOGUE
  Future<List<SpecialiteOption>> getSpecialites({required String type});
}

class ApiReferentielRepository implements ReferentielRepository {
  final ApiClient _client;

  ApiReferentielRepository(this._client);

  @override
  Future<List<SpecialiteOption>> getSpecialites({required String type}) async {
    final response = await _client.get(
      '/referentiels/specialites',
      queryParameters: {'type': type},
    );
    final list = response.data as List<dynamic>? ?? [];
    return list
        .map((e) => SpecialiteOption.fromJson(e as Map<String, dynamic>))
        .where((s) => s.id.isNotEmpty && s.nom.isNotEmpty)
        .toList();
  }
}

final referentielRepositoryProvider = Provider<ReferentielRepository>((ref) {
  return ApiReferentielRepository(ref.watch(apiClientProvider));
});
