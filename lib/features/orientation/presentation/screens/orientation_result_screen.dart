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
import '../../../../core/l10n/app_strings.dart';
import '../widgets/plant_illustration.dart';

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
        title: Text(tr('Votre orientation')),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: tr("Aller à l'accueil"),
            onPressed: () => context.go(AppRoutes.home),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      body: result == null
          ? AppEmptyStateView(
              title: tr('Aucun résultat'),
              message: tr(
                "Répondez au questionnaire pour obtenir votre orientation.",
              ),
              icon: Icons.quiz_outlined,
              actionText: tr('Faire le questionnaire'),
              onAction: () => context.go(AppRoutes.orientation),
            )
          : Stack(
              children: [
                const Positioned.fill(child: AmbientParticles()),
                _ResultContent(result: result),
              ],
            ),
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
        _ResultHeader(result: result),
        if (result.scoresParCategorie.isNotEmpty) ...[
          AppSpacing.vGap32,
          AppSectionHeader(title: tr('Détail par besoin')),
          AppSpacing.vGap12,
          _CategoryScores(scores: result.scoresParCategorie),
        ],
        AppSpacing.vGap32,
        AppSectionHeader(title: tr('Professionnels recommandés')),
        AppSpacing.vGap12,
        if (result.professionnelsRecommandes.isEmpty)
          Text(
            universe.isLawyer
                ? tr(
                    'Aucun professionnel ne correspond encore à cette orientation. '
                    'Consultez la liste complète des avocats.',
                  )
                : tr(
                    'Aucun professionnel ne correspond encore à cette orientation. '
                    'Consultez la liste complète des psychologues.',
                  ),
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
        AppButton(
          text: universe.isLawyer
              ? tr('Voir les avocats')
              : tr('Voir les psychologues'),
          onPressed: () => context.go(AppRoutes.professionnels),
        ),
        AppSpacing.vGap12,
        Center(
          child: AppButton.ghost(
            text: tr("Aller à l'accueil"),
            onPressed: () => context.go(AppRoutes.home),
          ),
        ),
        AppSpacing.vGap24,
      ],
    );
  }
}

/// En-tête du résultat : illustration, puis la catégorie / spécialité
/// retenue par le backend, sans carte.
class _ResultHeader extends StatelessWidget {
  final ResultatOrientationModel result;

  const _ResultHeader({required this.result});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        const PlantIllustration(size: 170),
        AppSpacing.vGap16,
        Text(
          tr('Nous vous orientons vers'),
          textAlign: TextAlign.center,
          style: AppTypography.texteSecondaire.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        AppSpacing.vGap4,
        Text(
          result.mainLabel ?? tr('Un accompagnement adapté'),
          textAlign: TextAlign.center,
          style: AppTypography.titreMoyen.copyWith(color: scheme.primary),
        ),
        if (result.mainDescription != null) ...[
          AppSpacing.vGap8,
          Text(
            result.mainDescription!,
            textAlign: TextAlign.center,
            style: AppTypography.texte.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
        AppSpacing.vGap12,
        Text(
          tr('Une orientation, pas un diagnostic.'),
          textAlign: TextAlign.center,
          style: AppTypography.miniTexte.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
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
