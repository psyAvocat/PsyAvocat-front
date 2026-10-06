import 'package:firebase_auth/firebase_auth.dart';
import 'package:psyavocat_front/core/errors/app_exception.dart';
import 'package:psyavocat_front/features/auth/data/models/current_user.dart';
import 'package:psyavocat_front/features/auth/data/repositories/auth_repository.dart';
import 'package:psyavocat_front/features/auth/data/repositories/session_repository.dart';
import 'package:psyavocat_front/features/orientation/data/models/questionnaire_model.dart';
import 'package:psyavocat_front/features/orientation/data/repositories/orientation_repository.dart';

// Doublures de test (jamais utilisées par l'application) pour simuler
// les réponses de l'API Spring Boot et de Firebase dans les tests.

/// Questionnaire de test à [count] questions, du type demandé.
QuestionnaireModel buildTestQuestionnaire({
  int count = 3,
  String typeReponse = QuestionModel.typeChoixUnique,
  bool obligatoire = true,
}) {
  return QuestionnaireModel(
    id: 'questionnaire-test',
    titre: 'Questionnaire de test',
    type: 'JURIDIQUE',
    questions: [
      for (var i = 1; i <= count; i++)
        QuestionModel(
          id: 'q$i',
          texte: 'Question de test numéro $i',
          ordre: i,
          obligatoire: obligatoire,
          typeReponse: typeReponse,
          reponses: [
            ReponseModel(id: 'q$i-a', libelle: 'Réponse A$i'),
            ReponseModel(id: 'q$i-b', libelle: 'Réponse B$i'),
          ],
        ),
    ],
  );
}

class FakeOrientationRepository implements OrientationRepository {
  final QuestionnaireModel? questionnaire;
  final Object? loadError;
  final List<ResultatOrientationModel> mesResultats;

  /// Dernières réponses soumises (pour vérifier la requête construite).
  List<String>? submittedReponseIds;
  String? submittedQuestionnaireId;

  FakeOrientationRepository({
    this.questionnaire,
    this.loadError,
    this.mesResultats = const [],
  });

  @override
  Future<QuestionnaireModel?> getQuestionnaireByType(String type) async {
    if (loadError != null) throw loadError!;
    return questionnaire;
  }

  @override
  Future<ResultatOrientationModel> evaluerQuestionnaire({
    required String questionnaireId,
    required List<String> reponseIds,
  }) async {
    submittedQuestionnaireId = questionnaireId;
    submittedReponseIds = reponseIds;
    return const ResultatOrientationModel(
      categorieBesoinNom: 'Catégorie de test',
    );
  }

  @override
  Future<List<ResultatOrientationModel>> getMesResultats() async =>
      mesResultats;
}

class FakeSessionRepository implements SessionRepository {
  final CurrentUser user;

  FakeSessionRepository({
    List<String> roles = const ['ROLE_JUSTICIABLE', 'ROLE_USER'],
  }) : user = CurrentUser(
         userId: 'u1',
         email: 'test@example.com',
         nom: 'Test',
         prenom: 'Awa',
         roles: roles,
         hasMetierProfile: true,
       );

  @override
  Future<CurrentUser> getCurrentUser() async => user;
}

/// Firebase simulé : personne n'est connecté, la connexion échoue.
class FakeAuthRepository implements AuthRepository {
  @override
  User? get currentUser => null;

  @override
  Stream<User?> get authStateChanges => const Stream.empty();

  @override
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) => throw const AuthException('Email ou mot de passe incorrect.');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
