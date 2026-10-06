import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_providers.dart';
import '../models/questionnaire_model.dart';

abstract class OrientationRepository {
  /// Questionnaire actif du type demandé (`JURIDIQUE` ou `PSYCHOLOGIQUE`),
  /// ou `null` si l'administrateur n'en a publié aucun.
  Future<QuestionnaireModel?> getQuestionnaireByType(String type);

  /// Envoie les réponses ; le backend calcule et renvoie le résultat.
  Future<ResultatOrientationModel> evaluerQuestionnaire({
    required String questionnaireId,
    required List<String> reponseIds,
  });

  /// Historique des résultats de l'utilisateur connecté.
  Future<List<ResultatOrientationModel>> getMesResultats();
}

class ApiOrientationRepository implements OrientationRepository {
  final ApiClient _client;

  ApiOrientationRepository(this._client);

  @override
  Future<QuestionnaireModel?> getQuestionnaireByType(String type) async {
    try {
      final response = await _client.get(
        '/orientation/questionnaires/type/$type',
      );
      return QuestionnaireModel.fromJson(response.data as Map<String, dynamic>);
    } on NotFoundException {
      // Aucun questionnaire publié pour ce type : état vide, pas une erreur.
      return null;
    }
  }

  @override
  Future<ResultatOrientationModel> evaluerQuestionnaire({
    required String questionnaireId,
    required List<String> reponseIds,
  }) async {
    // Corps = SoumissionQuestionnaireRequest côté Spring Boot.
    final response = await _client.post(
      '/orientation/evaluer',
      data: {'questionnaireId': questionnaireId, 'reponseIds': reponseIds},
    );
    return ResultatOrientationModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  @override
  Future<List<ResultatOrientationModel>> getMesResultats() async {
    final response = await _client.get('/orientation/mes-resultats');
    final list = response.data as List<dynamic>? ?? [];
    return list
        .map(
          (e) => ResultatOrientationModel.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }
}

final orientationRepositoryProvider = Provider<OrientationRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ApiOrientationRepository(client);
});
