import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/user_message.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/widgets/widgets.dart';
import '../../data/models/questionnaire_model.dart';
import '../controllers/orientation_controller.dart';

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
      context.go('/orientation/intro');
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
                    onPressed: () => context.go('/home'),
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
      if (context.mounted) context.go('/orientation/resultat');
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

/// Une question et ses réponses, affichées selon le type défini par l'Admin.
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
          Text(
            question.texte,
            textAlign: TextAlign.center,
            style: AppTypography.petitTitre,
          ),
          if (question.contexte != null &&
              question.contexte!.trim().isNotEmpty) ...[
            AppSpacing.vGap8,
            Text(
              question.contexte!,
              textAlign: TextAlign.center,
              style: AppTypography.texteSecondaire,
            ),
          ],
          AppSpacing.vGap12,
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [
              if (question.allowsMultiple)
                const Chip(label: Text('Plusieurs réponses possibles')),
              if (!question.obligatoire) const Chip(label: Text('Facultatif')),
            ],
          ),
          AppSpacing.vGap24,
          _buildAnswers(),
          AppSpacing.vGap16,
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

    // Choix multiple : des cases à cocher, pas de groupe radio.
    if (question.allowsMultiple) return _spacedColumn(tiles);

    // Oui / Non avec exactement deux réponses : côte à côte.
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
      children: [
        for (final tile in tiles)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s12),
            child: tile,
          ),
      ],
    );
  }
}
