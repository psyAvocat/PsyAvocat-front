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
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  /// Photos de chaque page (assets issus de docs/assets).
  static const List<List<String>> _pagesImages = [
    ['assets/images/psychologist_1.jpg', 'assets/images/psychologist_2.jpg'],
    ['assets/images/lawyer_1.jpg', 'assets/images/lawyer_2.jpg'],
  ];

  final PageController _pageController = PageController();
  int _currentPage = 0;

  bool get _isLastPage => _currentPage == _pagesImages.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _onContinue() async {
    if (!_isLastPage) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      return;
    }
    await ref.read(appPreferencesServiceProvider).setHasSeenOnboarding(true);
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
              itemCount: _pagesImages.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (_, index) =>
                  OnboardingPage(images: _pagesImages[index]),
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
                    AppPrimaryButton(
                      label: 'Continuer',
                      backgroundColor: AppColors.psychologistAccent,
                      onPressed: _onContinue,
                    ),
                    AppSpacing.vGap20,
                    AppPageDots(
                      count: _pagesImages.length,
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
