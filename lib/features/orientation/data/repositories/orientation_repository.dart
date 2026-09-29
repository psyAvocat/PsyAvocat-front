import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_providers.dart';
import '../models/questionnaire_model.dart';

abstract class OrientationRepository {
  Future<QuestionnaireModel> getQuestionnaireByType(String type);
  Future<ResultatOrientationModel> evaluerQuestionnaire({
    required String questionnaireId,
    required List<String> reponseIds,
  });
}

class ApiOrientationRepository implements OrientationRepository {
  final ApiClient _client;

  ApiOrientationRepository(this._client);

  @override
  Future<QuestionnaireModel> getQuestionnaireByType(String type) async {
    final response = await _client.get('/orientation/questionnaires/type/$type');
    return QuestionnaireModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<ResultatOrientationModel> evaluerQuestionnaire({
    required String questionnaireId,
    required List<String> reponseIds,
  }) async {
    final response = await _client.post(
      '/orientation/evaluer',
      data: {
        'questionnaireId': questionnaireId,
        'reponseIds': reponseIds,
      },
    );
    return ResultatOrientationModel.fromJson(response.data as Map<String, dynamic>);
  }
}

final orientationRepositoryProvider = Provider<OrientationRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ApiOrientationRepository(client);
});
