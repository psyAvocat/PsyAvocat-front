import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/widgets/widgets.dart';

/// Contenu d'une page de l'onboarding.
class OnboardingSlideData {
  /// Univers présenté : fournit la couleur d'accent (via le thème).
  final AppUniverse universe;

  /// Les deux photos de l'univers, qui alternent l'une après l'autre.
  final String firstImage;
  final String secondImage;

  final IconData icon;

  /// Titre découpé pour colorer la fin : [titleStart] + [titleHighlight].
  final String titleStart;
  final String titleHighlight;

  final String description;
  final List<String> highlights;

  const OnboardingSlideData({
    required this.universe,
    required this.firstImage,
    required this.secondImage,
    required this.icon,
    required this.titleStart,
    required this.titleHighlight,
    required this.description,
    required this.highlights,
  });

  /// Couleur d'accent de l'univers, lisible sur fond sombre.
  Color get accentColor => AppTheme.colorSchemeFor(universe).tertiary;
}

/// Une page de l'onboarding :
/// - Une SEULE image visible à la fois.
/// - Première image choisie aléatoirement parmi les deux.
/// - L'image reste visible un court instant, puis fondu vers le fond sombre,
///   puis fondu de la deuxième image.
/// - Boucle continue fluide et élégante sans superposition ni collage.
/// - Textes, badge et points forts restent stables.
class OnboardingSlide extends StatefulWidget {
  final OnboardingSlideData data;

  const OnboardingSlide({super.key, required this.data});

  @override
  State<OnboardingSlide> createState() => _OnboardingSlideState();
}

class _OnboardingSlideState extends State<OnboardingSlide>
    with TickerProviderStateMixin {
  late bool _isFirstImage;
  Timer? _loopTimer;

  late final AnimationController _imageFadeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
    value: 1.0,
  );

  late final AnimationController _textController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..forward();

  late final Animation<double> _textOpacity = CurvedAnimation(
    parent: _textController,
    curve: Curves.easeOut,
  );

  /// Part de la hauteur de la page occupée par la photo.
  static const double _imageHeightRatio = 0.58;

  @override
  void initState() {
    super.initState();
    // 1. Choix aléatoire de la première image
    _isFirstImage = Random().nextBool();
    _startImageRotationLoop();
  }

  void _startImageRotationLoop() {
    _loopTimer = Timer.periodic(const Duration(milliseconds: 3800), (_) async {
      if (!mounted) return;
      // Fondu sortant vers le fond sombre
      await _imageFadeController.reverse();
      if (!mounted) return;
      // Bascule vers l'autre image
      setState(() {
        _isFirstImage = !_isFirstImage;
      });
      // Fondu entrant de la nouvelle image
      await _imageFadeController.forward();
    });
  }

  @override
  void dispose() {
    _loopTimer?.cancel();
    _imageFadeController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageHeight = constraints.maxHeight * _imageHeightRatio;

        return Stack(
          children: [
            // Une seule image à la fois en haut, avec transition fluide
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: imageHeight,
              child: _buildSingleImage(),
            ),
            // Le texte est aligné en bas et reste parfaitement stable
            Positioned.fill(
              child: SingleChildScrollView(
                padding: AppSpacing.screenHorizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: imageHeight * 0.55),
                      FadeTransition(
                        opacity: _textOpacity,
                        child: _OnboardingTexts(data: widget.data),
                      ),
                      AppSpacing.vGap24,
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Une SEULE photo à la fois + dégradé sombre qui remonte du bas.
  Widget _buildSingleImage() {
    final currentImagePath =
        _isFirstImage ? widget.data.firstImage : widget.data.secondImage;

    return Stack(
      fit: StackFit.expand,
      children: [
        FadeTransition(
          opacity: _imageFadeController,
          child: _OnboardingImage(currentImagePath),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              stops: [0.0, 0.45, 1.0],
              colors: [
                AppColors.onboardingBackground,
                Color(0x990B0D1A), // fond à 60 %
                Color(0x000B0D1A), // transparent
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OnboardingImage extends StatelessWidget {
  final String path;

  const _OnboardingImage(this.path);

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      path,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
    );
  }
}

/// Badge, titre, description et points forts d'une page.
class _OnboardingTexts extends StatelessWidget {
  final OnboardingSlideData data;

  const _OnboardingTexts({required this.data});

  @override
  Widget build(BuildContext context) {
    final accent = data.accentColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: accent,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.45),
                blurRadius: 24,
              ),
            ],
          ),
          child: Icon(
            data.icon,
            color: AppColors.textOnColor,
            size: AppIcons.sizeLg,
          ),
        ),
        AppSpacing.vGap24,
        AppHighlightedTitle(
          before: data.titleStart,
          highlight: data.titleHighlight,
          highlightColor: accent,
          color: AppColors.textOnColor,
        ),
        AppSpacing.vGap12,
        Text(
          data.description,
          style: AppTypography.texte.copyWith(
            color: AppColors.onboardingTextMuted,
          ),
        ),
        AppSpacing.vGap20,
        for (final highlight in data.highlights)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s12),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: AppColors.textOnColor,
                  ),
                ),
                AppSpacing.hGap12,
                Expanded(
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
      ],
    );
  }
}
