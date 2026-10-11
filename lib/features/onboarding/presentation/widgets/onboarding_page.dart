import 'package:flutter/material.dart';
import '../../../../core/theme/design_system.dart';
import 'auto_crossfade_images.dart';

/// Contenu d'une page d'onboarding.
class OnboardingContent {
  final List<String> images;

  /// Titre découpé en morceaux : [highlight] est mis en couleur.
  final String titleBefore;
  final String highlight;
  final String titleAfter;
  final Color highlightColor;

  final String subtitle;
  final List<String> points;

  const OnboardingContent({
    required this.images,
    required this.titleBefore,
    required this.highlight,
    required this.titleAfter,
    required this.highlightColor,
    required this.subtitle,
    required this.points,
  });
}

/// Une page d'onboarding (maquettes « Splash screen ») : photos qui défilent
/// en plein écran, dégradé sombre qui remonte du bas, puis le texte.
///
/// [pageOffset] (−1 → 1) : position de la page pendant le glissement ; les photos
/// se décalent moins vite que le texte (effet de profondeur) et le texte s'estompe.
/// Le bouton et les points sont posés par l'écran parent, sous ce contenu.
class OnboardingPage extends StatelessWidget {
  final OnboardingContent content;
  final double pageOffset;

  const OnboardingPage({super.key, required this.content, this.pageOffset = 0});

  /// Hauteur réservée en bas pour le bouton « Continuer » et les points.
  static const double _bottomControlsHeight = 128;

  @override
  Widget build(BuildContext context) {
    final white = AppTypography.grandTitre.copyWith(
      color: AppColors.textOnColor,
      height: 1.2,
    );
    final width = MediaQuery.sizeOf(context).width;
    final visibilite = (1 - pageOffset.abs()).clamp(0.0, 1.0);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Parallaxe : la photo glisse plus lentement que la page.
        ClipRect(
          child: Transform.translate(
            offset: Offset(pageOffset * width * 0.35, 0),
            child: AutoCrossfadeImages(images: content.images),
          ),
        ),
        // Dégradé prévu par la maquette : lisibilité du texte sur la photo.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              stops: [0.0, 0.45, 0.75],
              colors: [
                AppColors.onboardingBackground,
                Color(0xD90B0D1A), // fond à 85 %
                Color(0x000B0D1A), // transparent
              ],
            ),
          ),
        ),
        SafeArea(
          child: Opacity(
            opacity: Curves.easeOut.transform(visibilite),
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s32,
                  0,
                  AppSpacing.s32,
                  _bottomControlsHeight,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - _bottomControlsHeight,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          style: white,
                          children: [
                            TextSpan(text: content.titleBefore),
                            TextSpan(
                              text: content.highlight,
                              style: TextStyle(color: content.highlightColor),
                            ),
                            TextSpan(text: content.titleAfter),
                          ],
                        ),
                      ),
                      AppSpacing.vGap12,
                      Text(
                        content.subtitle,
                        style: AppTypography.texte.copyWith(
                          color: AppColors.onboardingTextMuted,
                          height: 1.45,
                        ),
                      ),
                      AppSpacing.vGap20,
                      for (final point in content.points)
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppSpacing.s12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: content.highlightColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              AppSpacing.hGap12,
                              Expanded(
                                child: Text(
                                  point,
                                  style: AppTypography.texte.copyWith(
                                    color: AppColors.textOnColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
