import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/controllers/session_controller.dart';

/// Écran de démarrage — maquette Figma « première page ».
///
/// Affiché tant que la session est en cours de vérification (`GET /me`), avec
/// « Réessayer » si le serveur est injoignable. La page suivante est choisie
/// par le routeur (voir route_guard.dart) dès que la session est connue.
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

  @override
  void initState() {
    super.initState();
    _animation.forward();
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Seul cas où le splash reste affiché : première connexion sur l'appareil
    // et serveur injoignable (GET /me). On propose alors de réessayer.
    final session = ref.watch(sessionControllerProvider);
    final errorMessage = session.status == SessionStatus.error
        ? (session.message ?? 'Connexion au serveur impossible.')
        : null;
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
                if (errorMessage != null) ...[
                  AppSpacing.vGap32,
                  Text(
                    errorMessage,
                    textAlign: TextAlign.center,
                    style: AppTypography.texteSecondaire,
                  ),
                  AppSpacing.vGap16,
                  FilledButton.icon(
                    onPressed: () =>
                        ref.read(sessionControllerProvider.notifier).resolve(),
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
