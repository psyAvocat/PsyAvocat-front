import 'package:flutter/material.dart';
import '../../../../core/theme/design_system.dart';
import 'auto_crossfade_images.dart';

/// Une page d'onboarding (maquettes « Splash screen ») : photos qui défilent
/// en plein écran, dégradé sombre qui remonte du bas, puis le texte.
///
/// Le bouton et les points sont posés par l'écran parent, sous ce contenu.
class OnboardingPage extends StatelessWidget {
  final List<String> images;

  const OnboardingPage({super.key, required this.images});

  /// Hauteur réservée en bas pour le bouton « Continuer » et les points.
  static const double _bottomControlsHeight = 120;

  static const List<String> _highlights = [
    'Écoute bienveillante',
    'Suivi personnalisé',
    'En toute confidentialité',
  ];

  @override
  Widget build(BuildContext context) {
    final white = AppTypography.grandTitre.copyWith(
      color: AppColors.textOnColor,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        AutoCrossfadeImages(images: images),
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
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
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
                        children: const [
                          TextSpan(text: 'Trouvez votre\n'),
                          TextSpan(
                            text: 'psychologue',
                            style: TextStyle(
                              color: AppColors.psychologistAccent,
                            ),
                          ),
                          TextSpan(text: '\net + '),
                          TextSpan(
                            text: 'avocat',
                            style: TextStyle(color: AppColors.lawyerAccent),
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.vGap12,
                    Text(
                      'Échangez avec un professionnel qualifié et avancez à votre rythme.',
                      style: AppTypography.texte.copyWith(
                        color: AppColors.onboardingTextMuted,
                      ),
                    ),
                    AppSpacing.vGap20,
                    for (final highlight in _highlights)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: AppSpacing.s32,
                          bottom: AppSpacing.s12,
                        ),
                        child: Text(
                          highlight,
                          style: AppTypography.texte.copyWith(
                            color: AppColors.textOnColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
