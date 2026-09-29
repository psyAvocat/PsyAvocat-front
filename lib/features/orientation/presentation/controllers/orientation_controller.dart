import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_universe.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../data/models/questionnaire_model.dart';
import '../../data/repositories/orientation_repository.dart';

/// Données d'une réponse sélectionnée lors du questionnaire d'orientation
class OrientationAnswer {
  final String questionId;
  final String question;
  final String label;
  final String code; // ID de la réponse pour la soumission au backend

  const OrientationAnswer({
    required this.questionId,
    required this.question,
    required this.label,
    required this.code,
  });
}

/// État du questionnaire d'orientation dynamique
class OrientationState {
  final int currentStep;
  final QuestionnaireModel? questionnaire;
  final Map<int, OrientationAnswer> answers;
  final bool isLoading;
  final String? errorMessage;
  final ResultatOrientationModel? resultat;

  const OrientationState({
    this.currentStep = 0,
    this.questionnaire,
    this.answers = const {},
    this.isLoading = false,
    this.errorMessage,
    this.resultat,
  });

  OrientationState copyWith({
    int? currentStep,
    QuestionnaireModel? questionnaire,
    Map<int, OrientationAnswer>? answers,
    bool? isLoading,
    String? errorMessage,
    ResultatOrientationModel? resultat,
  }) {
    return OrientationState(
      currentStep: currentStep ?? this.currentStep,
      questionnaire: questionnaire ?? this.questionnaire,
      answers: answers ?? this.answers,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      resultat: resultat ?? this.resultat,
    );
  }
}

/// Contrôleur Riverpod pour gérer l'orientation avec le backend Spring Boot & MySQL
class OrientationController extends Notifier<OrientationState> {
  @override
  OrientationState build() {
    return const OrientationState(isLoading: false);
  }

  Future<void> loadQuestionnaire() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final universe = ref.read(currentUniverseProvider);
      final type = universe == AppUniverse.lawyer ? 'JURIDIQUE' : 'PSYCHOLOGIQUE';
      final repository = ref.read(orientationRepositoryProvider);
      final questionnaire = await repository.getQuestionnaireByType(type);
      state = state.copyWith(
        isLoading: false,
        questionnaire: questionnaire,
        currentStep: 0,
        answers: {},
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Impossible de charger le questionnaire depuis la base de données : $e',
      );
    }
  }

  void selectAnswer({
    required int step,
    String? questionId,
    required String question,
    required String label,
    String? reponseId,
    String? code,
  }) {
    final effectiveCode = reponseId ?? code ?? '';
    final effectiveQuestionId = questionId ?? '';
    final updated = Map<int, OrientationAnswer>.from(state.answers);
    updated[step] = OrientationAnswer(
      questionId: effectiveQuestionId,
      question: question,
      label: label,
      code: effectiveCode,
    );
    state = state.copyWith(answers: updated);
  }

  bool nextStep(int totalSteps) {
    if (state.currentStep < totalSteps - 1) {
      state = state.copyWith(currentStep: state.currentStep + 1);
      return true;
    }
    return false; // Arrivé à la fin du questionnaire
  }

  bool previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
      return true;
    }
    return false;
  }

  Future<bool> soumettreQuestionnaire() async {
    final q = state.questionnaire;
    if (q == null) return false;

    final reponseIds = state.answers.values.map((a) => a.code).toList();
    if (reponseIds.isEmpty) return false;

    state = state.copyWith(isLoading: true);
    try {
      final repository = ref.read(orientationRepositoryProvider);
      final res = await repository.evaluerQuestionnaire(
        questionnaireId: q.id,
        reponseIds: reponseIds,
      );
      state = state.copyWith(isLoading: false, resultat: res);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Erreur lors de l\'évaluation : $e',
      );
      return false;
    }
  }

  void reset() {
    state = const OrientationState();
    loadQuestionnaire();
  }
}

final orientationControllerProvider =
    NotifierProvider<OrientationController, OrientationState>(
  OrientationController.new,
);
