import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../professionnels/presentation/widgets/professionnel_card.dart';
import '../../data/models/questionnaire_model.dart';
import '../controllers/orientation_controller.dart';
import '../../../../core/router/app_routes.dart';

/// Résultat d'orientation, tel que calculé par Spring Boot.
///
/// Flutter n'interprète rien : il affiche la catégorie / spécialité retenue,
/// le classement par besoin et les professionnels recommandés par le backend.
class OrientationResultScreen extends ConsumerWidget {
  const OrientationResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(lastOrientationResultProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Votre orientation'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: "Aller à l'accueil",
            onPressed: () => context.go(AppRoutes.home),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      body: result == null
          ? AppEmptyStateView(
              title: 'Aucun résultat',
              message:
                  "Répondez au questionnaire pour obtenir votre orientation.",
              icon: Icons.quiz_outlined,
              actionText: 'Faire le questionnaire',
              onAction: () => context.go(AppRoutes.orientation),
            )
          : _ResultContent(result: result),
    );
  }
}

class _ResultContent extends ConsumerWidget {
  final ResultatOrientationModel result;

  const _ResultContent({required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final universe = ref.watch(currentUniverseProvider);

    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        _MainResultCard(result: result),
        AppSpacing.vGap16,
        const AppAlertBanner(
          message:
              'Ce résultat est une orientation, pas un diagnostic. '
              'Seul un professionnel peut évaluer votre situation.',
        ),
        if (result.scoresParCategorie.isNotEmpty) ...[
          AppSpacing.vGap32,
          const AppSectionHeader(title: 'Détail par besoin'),
          AppSpacing.vGap12,
          _CategoryScores(scores: result.scoresParCategorie),
        ],
        AppSpacing.vGap32,
        const AppSectionHeader(title: 'Professionnels recommandés'),
        AppSpacing.vGap12,
        if (result.professionnelsRecommandes.isEmpty)
          Text(
            'Aucun professionnel ne correspond encore à cette orientation. '
            'Consultez la liste complète des ${universe.professionalsLabel.toLowerCase()}.',
            style: AppTypography.texteSecondaire,
          )
        else
          for (final pro in result.professionnelsRecommandes)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s12),
              child: ProfessionnelCard(
                professionnel: pro,
                onTap: () => context.push(AppRoutes.professionnel(pro.id)),
              ),
            ),
        AppSpacing.vGap24,
        AppPrimaryButton(
          label: 'Voir les ${universe.professionalsLabel.toLowerCase()}',
          onPressed: () => context.go(AppRoutes.professionnels),
        ),
        AppSpacing.vGap12,
        Center(
          child: TextButton(
            onPressed: () => context.go(AppRoutes.home),
            child: const Text("Aller à l'accueil"),
          ),
        ),
        AppSpacing.vGap24,
      ],
    );
  }
}

/// Carte principale : la catégorie / spécialité retenue par le backend.
class _MainResultCard extends StatelessWidget {
  final ResultatOrientationModel result;

  const _MainResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      color: scheme.primaryContainer,
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.r20),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.explore_outlined,
              color: scheme.primary,
              size: AppIcons.sizeLg,
            ),
            AppSpacing.vGap12,
            Text(
              'Nous vous orientons vers',
              style: AppTypography.texteSecondaire.copyWith(
                color: scheme.onPrimaryContainer,
              ),
            ),
            AppSpacing.vGap4,
            Text(
              result.mainLabel ?? 'Un accompagnement adapté',
              style: AppTypography.titreMoyen.copyWith(
                color: scheme.onPrimaryContainer,
              ),
            ),
            if (result.mainDescription != null) ...[
              AppSpacing.vGap8,
              Text(
                result.mainDescription!,
                style: AppTypography.texte.copyWith(
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Classement des catégories de besoin, tel que renvoyé par le backend.
class _CategoryScores extends StatelessWidget {
  final List<CategorieScoreModel> scores;

  const _CategoryScores({required this.scores});

  @override
  Widget build(BuildContext context) {
    // La barre est proportionnelle au meilleur score (affichage uniquement).
    final maxScore = scores
        .map((s) => s.score)
        .fold<int>(0, (a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: AppSpacing.cardPaddingCompact,
        child: Column(
          children: [
            for (final score in scores)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(score.nom, style: AppTypography.texteMedium),
                    AppSpacing.vGap8,
                    LinearProgressIndicator(
                      value: maxScore == 0 ? 0 : score.score / maxScore,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
