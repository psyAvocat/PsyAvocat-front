import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/app_preferences_service.dart';
import '../../../../core/widgets/psyavocat_logo.dart';

/// Écran Onboarding 3 slides — conforme à la maquette Figma PsyAvocat.
/// Fond blanc propre, bouton violet plein (sans gradient parasite), logo centré slide 1.
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
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fond blanc pur — pas de dégradé sur le Scaffold
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Barre supérieure : bouton Ignorer aligné à droite ────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_currentPage < 2)
                    TextButton(
                      onPressed: _completeOnboarding,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF6B7280),
                      ),
                      child: const Text(
                        'Ignorer',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 40),
                ],
              ),
            ),

            // ── Carrousel des 3 slides ────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  _buildSlide1(),
                  _buildSlide2(),
                  _buildSlide3(),
                ],
              ),
            ),

            // ── Zone inférieure : Bouton + Indicateurs ────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Bouton Suivant / Commencer — violet plein, sans gradient
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D2B8F),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        _currentPage == 2 ? 'Commencer' : 'Suivant',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Indicateurs de pagination
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      final isActive = _currentPage == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF2D2B8F)
                              : const Color(0xFFD1D5DB),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Slide 1 : Présentation de la marque ─────────────────────────────────
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
          const SizedBox(height: 28),
          const Text(
            'Votre solution juridique\net psychologique',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E2432),
              height: 1.4,
              fontFamily: 'Montserrat',
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Accédez aux meilleurs avocats et psychologues,\nen toute confidentialité.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Slide 2 : Focus Avocat ───────────────────────────────────────────────
  Widget _buildSlide2() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
                height: 1.2,
                fontFamily: 'Montserrat',
              ),
              children: [
                TextSpan(text: 'Trouvez un\n'),
                TextSpan(
                  text: 'avocat',
                  style: TextStyle(color: Color(0xFF4F46E5)),
                ),
                TextSpan(text: ' à\nvotre écoute'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Bénéficiez d\'un accompagnement juridique personnalisé, en toute confidentialité.',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Color(0xFF4B5563),
              height: 1.5,
            ),
          ),
          const Spacer(),
          Center(
            child: Image.asset(
              'assets/images/onboarding_lawyer.png',
              height: 300,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.gavel_rounded,
                size: 120,
                color: Color(0xFF4F46E5),
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  // ─── Slide 3 : Focus Psychologue ─────────────────────────────────────────
  Widget _buildSlide3() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
                height: 1.2,
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
          const SizedBox(height: 14),
          const Text(
            'Bénéficiez d\'une écoute attentive et bienveillante pour surmonter vos difficultés au quotidien.',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Color(0xFF4B5563),
              height: 1.5,
            ),
          ),
          const Spacer(),
          Center(
            child: Image.asset(
              'assets/images/onboarding_psy.png',
              height: 300,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.psychology_rounded,
                size: 120,
                color: Color(0xFF7C3AED),
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
