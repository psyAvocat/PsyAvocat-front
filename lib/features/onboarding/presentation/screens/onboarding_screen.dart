import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/app_preferences_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/psyavocat_logo.dart';

/// Écran Onboarding 3 slides officiel de PsyAvocat.
/// Reproduit fidèlement la maquette : carrousel fluide, dégradés et visuels dédiés.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = ref.read(appPreferencesServiceProvider);
    await prefs.setHasSeenOnboarding(true);
    if (mounted) {
      context.go('/login');
    }
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFD),
      body: SafeArea(
        child: Column(
          children: [
            // Barre supérieure avec bouton "Ignorer" (sauf sur le dernier slide)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 48), // Équilibrage visuel
                  if (_currentPage < 2)
                    TextButton(
                      onPressed: _completeOnboarding,
                      child: const Text(
                        'Ignorer',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 48),
                ],
              ),
            ),

            // Carrousel des 3 slides
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildSlide1(),
                  _buildSlide2(),
                  _buildSlide3(),
                ],
              ),
            ),

            // Section inférieure : Bouton Suivant + Indicateur 3 points
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Le bouton d'action apparaît sur les slides 2 et 3 (sur slide 1, on swipe ou on clique sur Suivant)
                  Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5B21B6), Color(0xFF2563EB)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF5B21B6).withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Text(
                        _currentPage == 2 ? 'Commencer' : 'Suivant',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Indicateur de pagination 3 points
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      final isActive = _currentPage == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        width: isActive ? 12 : 9,
                        height: isActive ? 12 : 9,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive
                              ? const Color(0xFF1B365D)
                              : const Color(0xFFD6D9E0),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Slide 1 : Présentation de marque
  Widget _buildSlide1() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const PsyAvocatLogo(
            size: 160,
            fontSize: 34,
            showText: true,
          ),
          const SizedBox(height: 24),
          const Text(
            'Votre solution juridique\net psychologique',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C3240),
              height: 1.4,
              fontFamily: 'Montserrat',
            ),
          ),
        ],
      ),
    );
  }

  // Slide 2 : Focus Avocat
  Widget _buildSlide2() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
                height: 1.25,
                fontFamily: 'Montserrat',
              ),
              children: [
                TextSpan(text: 'Trouvez un '),
                TextSpan(
                  text: 'avocat',
                  style: TextStyle(color: Color(0xFF4F46E5)),
                ),
                TextSpan(text: ' à\nvotre écoute'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Bénéficiez d\'un accompagnement juridique personnalisé, en toute confidentialité.',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Color(0xFF4B5563),
              height: 1.45,
            ),
          ),
          const Spacer(),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/onboarding_lawyer.png',
                height: 320,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 280,
                  color: Colors.transparent,
                  child: const Icon(
                    Icons.gavel_rounded,
                    size: 100,
                    color: Color(0xFF4F46E5),
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  // Slide 3 : Focus Psychologue
  Widget _buildSlide3() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
                height: 1.25,
                fontFamily: 'Montserrat',
              ),
              children: [
                TextSpan(text: 'Trouver le\n'),
                TextSpan(
                  text: 'psychologue',
                  style: TextStyle(color: Color(0xFF7C3AED)),
                ),
                TextSpan(text: ' qui\nvous comprend'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Bénéficiez d\'une écoute attentive et bienveillante pour surmonter vos difficultés au quotidien.',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Color(0xFF4B5563),
              height: 1.45,
            ),
          ),
          const Spacer(),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/onboarding_psy.png',
                height: 320,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 280,
                  color: Colors.transparent,
                  child: const Icon(
                    Icons.psychology_rounded,
                    size: 100,
                    color: Color(0xFF7C3AED),
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
