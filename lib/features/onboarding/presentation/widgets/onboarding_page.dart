import 'package:flutter/material.dart';
import '../../../../core/theme/design_system.dart';
import 'auto_crossfade_images.dart';
import '../../../../core/l10n/app_strings.dart';

/// Contenu d'une page d'onboarding.
class OnboardingContent {
  final List<String> images;

  /// Titre découpé en morceaux : [highlight] est mis en couleur.
  final String titleBefore;
  final String highlight;
  final String titleAfter;
  final Color highlightColor;

  /// Facultatif : absent ou vide, rien n'est affiché sous le titre.
  final String? subtitle;
  final List<String> points;

  const OnboardingContent({
    required this.images,
    required this.titleBefore,
    required this.highlight,
    required this.titleAfter,
    required this.highlightColor,
    this.subtitle,
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
    final width = MediaQuery.sizeOf(context).width;
    // Grand titre proportionnel à la largeur : ~37 px sur un téléphone de
    // 393 pt, sans que la plus longue ligne (« Trouvez un avocat ») ne déborde.
    final white = AppTypography.grandTitre.copyWith(
      color: AppColors.textOnColor,
      fontSize: (width * 0.095).clamp(32.0, 40.0),
      height: 1.15,
    );
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
                // Même marge que le bouton : textes et bouton alignés à gauche.
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s24,
                  0,
                  AppSpacing.s24,
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
                        textAlign: TextAlign.left,
                        TextSpan(
                          style: white,
                          children: [
                            TextSpan(text: tr(content.titleBefore)),
                            TextSpan(
                              text: tr(content.highlight),
                              style: TextStyle(color: content.highlightColor),
                            ),
                            TextSpan(text: tr(content.titleAfter)),
                          ],
                        ),
                      ),
                      if (content.subtitle?.isNotEmpty ?? false) ...[
                        AppSpacing.vGap16,
                        Text(
                          tr(content.subtitle!),
                          textAlign: TextAlign.left,
                          style: AppTypography.texte.copyWith(
                            color: AppColors.onboardingTextMuted,
                            height: 1.45,
                          ),
                        ),
                      ],
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
                                  tr(point),
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
