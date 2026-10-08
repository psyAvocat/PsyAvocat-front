import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/questionnaire_model.dart';
import '../../data/repositories/orientation_repository.dart';

/// État du questionnaire en cours de remplissage.
///
/// Tout est dérivé du questionnaire reçu de l'API : nombre d'étapes,
/// type de chaque question, caractère obligatoire. Rien n'est codé en dur.
class OrientationState {
  /// `null` si aucun questionnaire n'est publié pour l'univers actif.
  final QuestionnaireModel? questionnaire;
  final int currentIndex;

  /// Réponses choisies : identifiant de question → identifiants de réponses.
  final Map<String, Set<String>> answers;
  final bool isSubmitting;

  const OrientationState({
    required this.questionnaire,
    this.currentIndex = 0,
    this.answers = const {},
    this.isSubmitting = false,
  });

  List<QuestionModel> get questions => questionnaire?.questions ?? const [];
  int get totalQuestions => questions.length;
  bool get isEmpty => totalQuestions == 0;
  QuestionModel get currentQuestion => questions[currentIndex];
  bool get isFirstQuestion => currentIndex == 0;
  bool get isLastQuestion => currentIndex == totalQuestions - 1;

  Set<String> answersFor(String questionId) => answers[questionId] ?? const {};

  /// On peut avancer si la question est facultative ou a au moins une réponse.
  bool get canGoNext =>
      !currentQuestion.obligatoire || answersFor(currentQuestion.id).isNotEmpty;

  OrientationState copyWith({
    int? currentIndex,
    Map<String, Set<String>>? answers,
    bool? isSubmitting,
  }) {
    return OrientationState(
      questionnaire: questionnaire,
      currentIndex: currentIndex ?? this.currentIndex,
      answers: answers ?? this.answers,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

/// Charge le questionnaire de l'univers actif, gère les réponses localement,
/// puis soumet le tout à Spring Boot qui calcule l'orientation.
class OrientationController extends AsyncNotifier<OrientationState> {
  @override
  Future<OrientationState> build() async {
    // Règle 10 : Les questionnaires sont réservés au domaine psychologique
    final questionnaire = await ref
        .read(orientationRepositoryProvider)
        .getQuestionnaireByType('PSYCHOLOGIQUE');
    return OrientationState(questionnaire: questionnaire);
  }

  OrientationState? get _current => state.value;

  /// Choisit (ou retire, en choix multiple) une réponse à la question courante.
  void toggleAnswer(String reponseId) {
    final current = _current;
    if (current == null || current.isEmpty) return;

    final question = current.currentQuestion;
    final selected = Set<String>.from(current.answersFor(question.id));

    if (question.allowsMultiple) {
      selected.contains(reponseId)
          ? selected.remove(reponseId)
          : selected.add(reponseId);
    } else {
      // Choix unique / Oui-Non : la nouvelle réponse remplace l'ancienne.
      selected
        ..clear()
        ..add(reponseId);
    }

    final answers = Map<String, Set<String>>.from(current.answers)
      ..[question.id] = selected;
    state = AsyncData(current.copyWith(answers: answers));
  }

  void goToNextQuestion() {
    final current = _current;
    if (current == null || current.isLastQuestion || !current.canGoNext) return;
    state = AsyncData(current.copyWith(currentIndex: current.currentIndex + 1));
  }

  /// Revient à la question précédente. Renvoie `false` si on est déjà à la première.
  bool goToPreviousQuestion() {
    final current = _current;
    if (current == null || current.isFirstQuestion) return false;
    state = AsyncData(current.copyWith(currentIndex: current.currentIndex - 1));
    return true;
  }

  /// Envoie toutes les réponses (SoumissionQuestionnaireRequest).
  /// En cas de succès, le résultat est disponible dans [lastOrientationResultProvider].
  /// En cas d'échec, l'erreur est levée pour que l'écran l'affiche ;
  /// les réponses sont conservées.
  Future<void> submit() async {
    final current = _current;
    final questionnaire = current?.questionnaire;
    if (current == null || questionnaire == null || current.isSubmitting) {
      return;
    }

    state = AsyncData(current.copyWith(isSubmitting: true));
    try {
      final reponseIds = current.answers.values.expand((ids) => ids).toList();
      final result = await ref
          .read(orientationRepositoryProvider)
          .evaluerQuestionnaire(
            questionnaireId: questionnaire.id,
            reponseIds: reponseIds,
          );
      ref.read(lastOrientationResultProvider.notifier).set(result);
      ref.invalidate(mesResultatsProvider);
    } finally {
      final latest = _current;
      if (latest != null) {
        state = AsyncData(latest.copyWith(isSubmitting: false));
      }
    }
  }
}

final orientationControllerProvider =
    AsyncNotifierProvider<OrientationController, OrientationState>(
      OrientationController.new,
    );

/// Dernier résultat obtenu dans cette session (affiché par l'écran de résultat).
class LastOrientationResultNotifier
    extends Notifier<ResultatOrientationModel?> {
  @override
  ResultatOrientationModel? build() => null;

  void set(ResultatOrientationModel result) => state = result;
}

final lastOrientationResultProvider =
    NotifierProvider<LastOrientationResultNotifier, ResultatOrientationModel?>(
      LastOrientationResultNotifier.new,
    );

/// Historique des résultats de l'utilisateur (GET /api/orientation/mes-resultats),
/// du plus récent au plus ancien.
final mesResultatsProvider = FutureProvider<List<ResultatOrientationModel>>((
  ref,
) async {
  final results = await ref
      .read(orientationRepositoryProvider)
      .getMesResultats();
  return [...results]..sort((a, b) {
    final dateA = a.dateEvaluation ?? DateTime(0);
    final dateB = b.dateEvaluation ?? DateTime(0);
    return dateB.compareTo(dateA);
  });
});
