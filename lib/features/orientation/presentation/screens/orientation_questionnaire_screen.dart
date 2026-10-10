import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/user_message.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/widgets/widgets.dart';
import '../../data/models/questionnaire_model.dart';
import '../controllers/orientation_controller.dart';
import '../../../../core/router/app_routes.dart';

/// Questionnaire d'orientation — maquettes Figma « Qst 1 Psy » / « Qst 3 Psy ».
///
/// Entièrement dynamique : questions, réponses, nombre d'étapes et type de
/// sélection viennent de l'API (questionnaire administré depuis l'Admin Angular).
class OrientationQuestionnaireScreen extends ConsumerWidget {
  const OrientationQuestionnaireScreen({super.key});

  void _goBack(BuildContext context, WidgetRef ref) {
    final wentBack = ref
        .read(orientationControllerProvider.notifier)
        .goToPreviousQuestion();
    if (wentBack) return;

    // Première question : on quitte le questionnaire.
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.orientationIntro);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orientation = ref.watch(orientationControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
          child: Column(
            children: [
              AppSpacing.vGap12,
              Row(
                children: [
                  IconButton.outlined(
                    onPressed: () => _goBack(context, ref),
                    tooltip: 'Retour',
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () => context.go(AppRoutes.home),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(48, 44),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s20,
                      ),
                    ),
                    child: const Text('Ignorer'),
                  ),
                ],
              ),
              AppSpacing.vGap24,
              Expanded(
                child: AppAsyncView<OrientationState>(
                  value: orientation,
                  isEmpty: (state) => state.isEmpty,
                  emptyTitle: 'Aucun questionnaire disponible',
                  emptyMessage:
                      "Le questionnaire d'orientation n'est pas encore publié. "
                      'Appuyez sur « Ignorer » pour accéder directement aux professionnels.',
                  emptyIcon: Icons.quiz_outlined,
                  onRetry: () => ref.invalidate(orientationControllerProvider),
                  builder: (state) => _QuestionnaireContent(state: state),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Progression, question courante et bouton d'action.
class _QuestionnaireContent extends ConsumerWidget {
  final OrientationState state;

  const _QuestionnaireContent({required this.state});

  Future<void> _onNextPressed(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(orientationControllerProvider.notifier);
    if (!state.isLastQuestion) {
      controller.goToNextQuestion();
      return;
    }

    try {
      await controller.submit();
      if (context.mounted) context.go(AppRoutes.orientationResult);
    } catch (error) {
      if (context.mounted) {
        AppNotification.showError(context, userMessageFor(error));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final question = state.currentQuestion;

    return Column(
      children: [
        AppStepProgress(
          currentStep: state.currentIndex + 1,
          totalSteps: state.totalQuestions,
          label: 'Question',
        ),
        AppSpacing.vGap24,
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            // La question reste collée en haut (par défaut elle serait centrée).
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topCenter,
              children: [...previous, ?current],
            ),
            child: _QuestionView(
              key: ValueKey(question.id),
              question: question,
              selectedIds: state.answersFor(question.id),
              onAnswerTapped: (reponseId) => ref
                  .read(orientationControllerProvider.notifier)
                  .toggleAnswer(reponseId),
            ),
          ),
        ),
        AppSpacing.vGap16,
        AppPrimaryButton(
          label: state.isLastQuestion ? 'Voir mon orientation' : 'Suivant',
          isLoading: state.isSubmitting,
          onPressed: state.canGoNext
              ? () => _onNextPressed(context, ref)
              : null,
        ),
        AppSpacing.vGap24,
      ],
    );
  }
}

class _QuestionView extends StatelessWidget {
  final QuestionModel question;
  final Set<String> selectedIds;
  final ValueChanged<String> onAnswerTapped;

  const _QuestionView({
    super.key,
    required this.question,
    required this.selectedIds,
    required this.onAnswerTapped,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.vGap24,
          Text(
            question.texte,
            textAlign: TextAlign.left,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E2432),
              height: 1.3,
            ),
          ),
          if (question.contexte != null &&
              question.contexte!.trim().isNotEmpty) ...[
            AppSpacing.vGap12,
            Text(
              question.contexte!,
              textAlign: TextAlign.left,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
          ],
          AppSpacing.vGap24,
          if (question.allowsMultiple || !question.obligatoire) ...[
            Wrap(
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s8,
              children: [
                if (question.allowsMultiple)
                  const Chip(
                    label: Text(
                      'Plusieurs réponses possibles',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor: Color(0xFFF3F4F6),
                    side: BorderSide.none,
                  ),
                if (!question.obligatoire)
                  const Chip(
                    label: Text(
                      'Facultatif',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor: Color(0xFFF3F4F6),
                    side: BorderSide.none,
                  ),
              ],
            ),
            AppSpacing.vGap24,
          ],
          _buildAnswers(),
          AppSpacing.vGap32,
        ],
      ),
    );
  }

  Widget _buildAnswers() {
    final tiles = [
      for (final reponse in question.reponses)
        AppChoiceTile(
          value: reponse.id,
          label: reponse.libelle,
          isSelected: selectedIds.contains(reponse.id),
          allowsMultiple: question.allowsMultiple,
          onTap: () => onAnswerTapped(reponse.id),
        ),
    ];

    if (question.allowsMultiple) return _spacedColumn(tiles);

    final layout = question.isYesNo && tiles.length == 2
        ? Row(
            children: [
              Expanded(child: tiles[0]),
              AppSpacing.hGap12,
              Expanded(child: tiles[1]),
            ],
          )
        : _spacedColumn(tiles);

    return RadioGroup<String>(
      groupValue: selectedIds.isEmpty ? null : selectedIds.first,
      onChanged: (reponseId) {
        if (reponseId != null) onAnswerTapped(reponseId);
      },
      child: layout,
    );
  }

  Widget _spacedColumn(List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final tile in tiles)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s16),
            child: tile,
          ),
      ],
    );
  }
}
