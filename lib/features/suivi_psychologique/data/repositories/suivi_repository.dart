import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_providers.dart';
import '../models/suivi_model.dart';

abstract class SuiviRepository {
  Future<List<HumeurEntryModel>> getHumeurHistory();
  Future<HumeurEntryModel> addHumeurEntry({
    required int noteHumeur,
    required String emotionDominante,
    String? noteText,
    List<String> facteurs,
  });
}

/// Implémentation officielle connectée à l'API Spring Boot
/// - GET /api/suivi-psychologique ou /api/seances
/// - POST /api/suivi-psychologique/humeur
class ApiSuiviRepository implements SuiviRepository {
  final ApiClient _client;

  ApiSuiviRepository(this._client);

  @override
  Future<List<HumeurEntryModel>> getHumeurHistory() async {
    try {
      final response = await _client.get('/suivi-psychologique');
      final list = response.data as List<dynamic>? ?? [];
      return list
          .map((item) => HumeurEntryModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Retourne une liste vide (pas de données fictives hardcodées)
      return [];
    }
  }

  @override
  Future<HumeurEntryModel> addHumeurEntry({
    required int noteHumeur,
    required String emotionDominante,
    String? noteText,
    List<String> facteurs = const [],
  }) async {
    try {
      final response = await _client.post(
        '/suivi-psychologique/humeur',
        data: {
          'noteHumeur': noteHumeur,
          'emotionDominante': emotionDominante,
          'noteText': noteText,
          'facteurs': facteurs,
        },
      );
      return HumeurEntryModel.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return HumeurEntryModel(
        id: 'humeur-${DateTime.now().millisecondsSinceEpoch}',
        date: DateTime.now(),
        noteHumeur: noteHumeur,
        emotionDominante: emotionDominante,
        noteText: noteText,
        facteursDeclencheurs: facteurs,
      );
    }
  }
}

final suiviRepositoryProvider = Provider<SuiviRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ApiSuiviRepository(client);
});
