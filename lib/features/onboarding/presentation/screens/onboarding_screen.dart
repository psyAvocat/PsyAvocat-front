import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/services/app_preferences_service.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/widgets/widgets.dart';
import '../widgets/onboarding_page.dart';

/// Onboarding en 2 pages — maquettes « Splash screen psychologue » puis
/// « Splash screen avocat ». Sur chaque page, deux photos défilent
/// automatiquement l'une après l'autre.
///
/// Transition fluide : photos préchargées avant l'affichage (aucun décodage
/// pendant le glissement), courbe douce et effet de profondeur (parallaxe).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  /// Violet et bleu lisibles sur le fond sombre de l'onboarding.
  static const Color _violet = Color(0xFFA36BEB);
  static const Color _bleu = Color(0xFF6B9BFF);

  static const List<OnboardingContent> _pages = [
    OnboardingContent(
      images: [
        'assets/images/psychologist_1.jpg',
        'assets/images/psychologist_2.jpg',
      ],
      titleBefore: 'Bénéficiez d’un soutien\n',
      highlight: 'psychologique',
      titleAfter: '\nà votre écoute',
      highlightColor: _violet,
      subtitle:
          'Des psychologues vérifiés vous accompagnent pas à pas, à votre rythme.',
      points: [
        'Écoute bienveillante',
        'Suivi personnalisé',
        'En toute confidentialité',
      ],
    ),
    OnboardingContent(
      images: ['assets/images/lawyer_1.jpg', 'assets/images/lawyer_2.jpg'],
      titleBefore: 'Trouvez un ',
      highlight: 'avocat',
      titleAfter: '\npour vous conseiller\net vous accompagner',
      highlightColor: _bleu,
      subtitle:
          'Présentez votre situation et échangez avec des avocats vérifiés.',
      points: [
        'Avocats vérifiés',
        'Dossier confidentiel',
        'Accompagnement sur mesure',
      ],
    ),
  ];

  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _imagesPrechargees = false;

  bool get _isLastPage => _currentPage == _pages.length - 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Décodage des photos avant leur première apparition : pas d'à-coup.
    if (!_imagesPrechargees) {
      _imagesPrechargees = true;
      for (final page in _pages) {
        for (final image in page.images) {
          precacheImage(AssetImage(image), context);
        }
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _onContinue() async {
    if (!_isLastPage) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
      return;
    }
    await ref.read(appPreferencesServiceProvider).setHasSeenOnboarding(true);
    // Connexion / inscription obligatoires, puis choix de l'univers.
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Icônes de la barre d'état en blanc sur les photos.
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.onboardingBackground,
        body: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (_, index) => AnimatedBuilder(
                animation: _pageController,
                builder: (context, _) {
                  final position =
                      _pageController.hasClients &&
                          _pageController.position.haveDimensions
                      ? (_pageController.page ?? 0)
                      : _currentPage.toDouble();
                  return OnboardingPage(
                    content: _pages[index],
                    pageOffset: (index - position).clamp(-1.0, 1.0),
                  );
                },
              ),
            ),
            // Bouton et points fixes, communs aux deux pages.
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                minimum: const EdgeInsets.fromLTRB(
                  AppSpacing.s24,
                  0,
                  AppSpacing.s24,
                  AppSpacing.s16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppButton(
                      text: _isLastPage ? 'Commencer' : 'Continuer',
                      color: _isLastPage
                          ? AppColors.lawyerSecondary
                          : AppColors.psychologistLight,
                      onPressed: _onContinue,
                    ),
                    AppSpacing.vGap20,
                    AppPageDots(
                      count: _pages.length,
                      activeIndex: _currentPage,
                      color: AppColors.textOnColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
