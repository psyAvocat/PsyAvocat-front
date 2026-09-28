import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/services/app_preferences_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../../../core/widgets/psyavocat_logo.dart';

/// Écran de démarrage (Splash Screen) officiel de PsyAvocat.
/// Affiche le logo de marque, restaure l'état de session et oriente vers le bon écran.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutBack,
      ),
    );

    _animController.forward();
    _initializeAppAndNavigate();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _initializeAppAndNavigate() async {
    // Laisser le temps à l'animation de se jouer et à Firebase de restaurer la session
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;

    final authRepo = ref.read(authRepositoryProvider);
    final prefs = ref.read(appPreferencesServiceProvider);
    final user = authRepo.currentUser;

    if (user != null) {
      // Utilisateur authentifié : restaurer l'univers ou aller au choix d'univers
      final universe = prefs.getSelectedUniverse();
      if (universe != null && !universe.isNeutral) {
        ref.read(currentUniverseProvider.notifier).setUniverse(universe);
        context.go('/home');
      } else {
        context.go('/selection-univers');
      }
    } else {
      // Utilisateur non connecté : vérifier si l'onboarding a déjà été vu
      final hasSeen = prefs.hasSeenOnboarding();
      if (hasSeen) {
        context.go('/login');
      } else {
        context.go('/onboarding');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                ),
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const PsyAvocatLogo(
                  size: 150,
                  fontSize: 32,
                  showText: true,
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text(
                    'Votre solution juridique\net psychologique',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      height: 1.4,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
