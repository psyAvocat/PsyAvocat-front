import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/app_preferences_service.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/widgets/widgets.dart';
import '../widgets/onboarding_slide.dart';

/// Onboarding en 2 pages (maquette fournie, fond sombre) :
/// 1. Avocats — 2. Psychologues.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  /// Pour ajouter une page à l'onboarding, il suffit d'ajouter un élément ici.
  static const List<OnboardingSlideData> _slides = [
    OnboardingSlideData(
      universe: AppUniverse.lawyer,
      firstImage: 'assets/images/lawyer_1.jpg',
      secondImage: 'assets/images/lawyer_2.jpg',
      icon: Icons.balance_rounded,
      titleStart: 'Trouvez un avocat\n',
      titleHighlight: 'à votre écoute',
      description:
          "Bénéficiez d'un accompagnement juridique personnalisé, en toute confidentialité.",
      highlights: [
        'Des avocats vérifiés',
        'Un conseil adapté à votre situation',
        'En toute confidentialité',
      ],
    ),
    OnboardingSlideData(
      universe: AppUniverse.psychologist,
      firstImage: 'assets/images/psychologist_1.jpg',
      secondImage: 'assets/images/psychologist_2.jpg',
      icon: Icons.psychology_rounded,
      titleStart: 'Prenez soin de votre\n',
      titleHighlight: 'santé mentale',
      description:
          'Échangez avec un psychologue qualifié et avancez à votre rythme.',
      highlights: [
        'Écoute bienveillante',
        'Suivi personnalisé',
        'En toute confidentialité',
      ],
    ),
  ];

  final PageController _pageController = PageController();
  int _currentPage = 0;

  bool get _isLastPage => _currentPage == _slides.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onContinuePressed() {
    if (_isLastPage) {
      _finishOnboarding();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _finishOnboarding() async {
    await ref.read(appPreferencesServiceProvider).setHasSeenOnboarding(true);
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final currentSlide = _slides[_currentPage];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Icônes de la barre d'état en blanc sur le fond sombre.
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.onboardingBackground,
        body: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) =>
                    OnboardingSlide(data: _slides[index]),
              ),
            ),
            // Le bouton reste toujours visible, sous le contenu défilant.
            SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(
                AppSpacing.s24,
                AppSpacing.s8,
                AppSpacing.s24,
                AppSpacing.s24,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  borderRadius: AppRadii.pill,
                  boxShadow: [
                    BoxShadow(
                      color: currentSlide.accentColor.withValues(alpha: 0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: AppPrimaryButton(
                  label: _isLastPage ? 'Commencer' : 'Continuer',
                  trailingIcon: Icons.arrow_forward_rounded,
                  backgroundColor: currentSlide.accentColor,
                  onPressed: _onContinuePressed,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
