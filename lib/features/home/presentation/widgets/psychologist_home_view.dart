import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../contenus/presentation/widgets/popular_publications_section.dart';
import 'home_action_card.dart';
import 'home_cards.dart';
import '../../../../core/l10n/app_strings.dart';

/// Accueil de l'univers Psychologue — maquette « Accueil psychologue ».
class PsychologistHomeView extends StatelessWidget {
  const PsychologistHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      // Marge basse : la barre de navigation flotte au-dessus du contenu.
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s20,
        AppSpacing.s8,
        AppSpacing.s20,
        120,
      ),
      children: [
        // La recherche ouvre l'écran de recherche des psychologues.
        SearchBar(
          hintText: tr('Rechercher un psychologue, une spécialité…'),
          leading: const Icon(Icons.search_rounded),
          elevation: const WidgetStatePropertyAll(0),
          onTap: () => context.go(AppRoutes.professionnelsRecherche),
          readOnly: true,
        ),
        AppSpacing.vGap20,
        const _WellbeingBanner(),
        AppSpacing.vGap20,
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: HomeActionCard(
                  title: tr('Trouver un psychologue'),
                  icon: Icons.psychology_rounded,
                  subtitle: tr('Trouvez le professionnel qui vous correspond'),
                  highlighted: true,
                  onTap: () => context.go(AppRoutes.professionnels),
                ),
              ),
              AppSpacing.hGap12,
              Expanded(
                child: HomeActionCard(
                  title: tr('Consulter les conseils'),
                  icon: Icons.tips_and_updates_rounded,
                  subtitle: tr('Des conseils d’experts pour mieux vivre'),
                  onTap: () => context.go(AppRoutes.conseils),
                ),
              ),
            ],
          ),
        ),
        AppSpacing.vGap24,
        AppSectionHeader(title: tr('Votre prochain rendez-vous')),
        AppSpacing.vGap8,
        const NextAppointmentCard(),
        AppSpacing.vGap24,
        const PopularPublicationsSection(),
      ],
    );
  }
}

/// Bannière « Prenez soin de votre santé mentale » : fond illustré généré
/// (formes douces dans la couleur de l'univers). Elle ouvre le questionnaire
/// d'orientation (questions et réponses chargées depuis la base).
class _WellbeingBanner extends StatelessWidget {
  const _WellbeingBanner();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: AppRadii.r16,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push(AppRoutes.orientation),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _BannerArtPainter(scheme.primary)),
              ),
              Padding(
                padding: AppSpacing.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSpacing.vGap16,
                    Text(
                      tr('Prenez soin\nde votre santé mentale'),
                      style: AppTypography.petitTitre.copyWith(
                        color: scheme.onPrimary,
                      ),
                    ),
                    AppSpacing.vGap8,
                    Text(
                      tr(
                        'Un accompagnement bienveillant pour avancer sereinement.',
                      ),
                      style: AppTypography.texteSecondaire.copyWith(
                        color: scheme.onPrimary,
                      ),
                    ),
                    AppSpacing.vGap16,
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s16,
                        vertical: AppSpacing.s8,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.onPrimary,
                        borderRadius: AppRadii.pill,
                      ),
                      child: Text(
                        tr('Faire le test d’orientation'),
                        style: AppTypography.texteSecondaire.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    AppSpacing.vGap8,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Illustration de fond de la bannière : aplat de la couleur de l'univers,
/// halos lumineux et vague apaisante. Dessinée en vectoriel : nette sur tous
/// les écrans, sans image à télécharger.
class _BannerArtPainter extends CustomPainter {
  final Color base;

  const _BannerArtPainter(this.base);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..color = base);

    canvas.drawCircle(
      Offset(w * 0.92, h * 0.12),
      h * 0.62,
      Paint()..color = Colors.white.withValues(alpha: 0.10),
    );
    canvas.drawCircle(
      Offset(w * 0.80, h * 0.95),
      h * 0.38,
      Paint()..color = Colors.white.withValues(alpha: 0.07),
    );
    canvas.drawCircle(
      Offset(w * 0.70, h * 0.30),
      h * 0.16,
      Paint()..color = Colors.white.withValues(alpha: 0.12),
    );

    final vague = Path()
      ..moveTo(0, h * 0.78)
      ..cubicTo(w * 0.25, h * 0.62, w * 0.45, h * 0.98, w * 0.70, h * 0.80)
      ..cubicTo(w * 0.85, h * 0.70, w * 0.95, h * 0.74, w, h * 0.70)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      vague,
      Paint()..color = Colors.white.withValues(alpha: 0.08),
    );
  }

  @override
  bool shouldRepaint(_BannerArtPainter old) => old.base != base;
}
