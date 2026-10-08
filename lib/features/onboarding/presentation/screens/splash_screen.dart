import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/user_message.dart';
import '../../../../core/services/app_preferences_service.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

/// Écran de démarrage — maquette Figma « première page ».
///
/// Pendant que le logo apparaît en fondu, on restaure la session
/// (Firebase → `GET /me`), puis on ouvre la bonne page via GoRouter.
/// Aucune attente artificielle : on attend seulement la fin de l'animation
/// ET la réponse du backend.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  late final Animation<double> _scale = Tween<double>(
    begin: 0.9,
    end: 1,
  ).animate(CurvedAnimation(parent: _animation, curve: Curves.easeOutBack));

  /// Message affiché si la session n'a pas pu être restaurée (API injoignable…).
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() => _errorMessage = null);

    final results = await Future.wait<Object?>([
      _animation.forward(),
      _resolveNextRoute(),
    ]);
    if (!mounted) return;

    final route = results[1] as String?;
    if (route != null) context.go(route);
  }

  /// Route à ouvrir, ou `null` si la restauration de session a échoué.
  Future<String?> _resolveNextRoute() async {
    final authRepository = ref.read(authRepositoryProvider);
    if (authRepository.currentUser != null) {
      // Attendre la résolution de la session
      await ref.read(sessionControllerProvider.notifier).resolve();
      final sessionState = ref.read(sessionControllerProvider);
      
      if (sessionState.status == SessionStatus.error) {
        if (mounted) {
          setState(() => _errorMessage = sessionState.message ?? 'Erreur de connexion');
        }
        return null;
      }
      
      if (sessionState.isAuthorized) {
        final hasUniverse = ref.read(appPreferencesServiceProvider).getSelectedUniverse() != null;
        return hasUniverse ? '/home' : '/selection-univers';
      }
      return '/login'; // Fallback if denied or profile incomplete handling not specified here
    }

    // Personne n'est connecté.
    final hasSeenOnboarding = ref
        .read(appPreferencesServiceProvider)
        .hasSeenOnboarding();
    return hasSeenOnboarding ? '/login' : '/onboarding';
  }

  @override
  Widget build(BuildContext context) {
    final logoSize = (MediaQuery.sizeOf(context).width * 0.55).clamp(
      140.0,
      240.0,
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.screenPadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: _animation,
                  child: ScaleTransition(
                    scale: _scale,
                    child: PsyAvocatLogo(size: logoSize, fontSize: 40),
                  ),
                ),
                AppSpacing.vGap24,
                FadeTransition(
                  opacity: _animation,
                  child: Text(
                    'Votre solution juridique\net psychologique',
                    textAlign: TextAlign.center,
                    style: AppTypography.petitTitre,
                  ),
                ),
                if (_errorMessage != null) ...[
                  AppSpacing.vGap32,
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: AppTypography.texteSecondaire,
                  ),
                  AppSpacing.vGap16,
                  FilledButton.icon(
                    onPressed: _start,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Réessayer'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
