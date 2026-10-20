import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/controllers/session_controller.dart';
import '../../../../core/l10n/app_strings.dart';

/// Écran de démarrage — maquette Figma « première page ».
///
/// Page blanche avec le logo, affichée UNE seule fois : à l'ouverture de l'app
/// (durée minimale, puis tant que la session restaurée se vérifie), avec
/// « Réessayer » si le serveur est injoignable. La page suivante est choisie
/// par le routeur (voir route_guard.dart).
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

  /// Largeur du logo sur l'écran de lancement natif (Android et iOS), en dp :
  /// le logo part de cette taille, au même endroit, pour une transition sans saut.
  static const _largeurNative = 140.0;

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
        ? (session.message ?? tr('Connexion au serveur impossible.'))
        : null;
    final ecran = MediaQuery.sizeOf(context);
    final logoSize = (ecran.width * 0.55).clamp(140.0, 240.0);
    final echelle = Tween<double>(
      begin: (_largeurNative / logoSize).clamp(0.4, 1.0),
      end: 1,
    ).animate(CurvedAnimation(parent: _animation, curve: Curves.easeOutCubic));
    final texte = CurvedAnimation(
      parent: _animation,
      curve: const Interval(0.35, 1, curve: Curves.easeOut),
    );
    // Sortie : quand la page suivante arrive, le logo et les textes s'effacent
    // avec un léger zoom, sur le fond blanc qui reste en place (fondu enchaîné).
    final sortie =
        (ModalRoute.of(context)?.secondaryAnimation ??
                kAlwaysDismissedAnimation)
            .drive(
              CurveTween(curve: const Interval(0, 0.4, curve: Curves.easeIn)),
            );

    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: sortie.drive(Tween(begin: 1.0, end: 0.0)),
        child: ScaleTransition(
          scale: sortie.drive(Tween(begin: 1.0, end: 1.06)),
          child: Stack(
            children: [
              // Logo au centre exact de l'écran, comme sur l'écran de lancement natif :
              // il y est déjà visible, il grandit simplement jusqu'à sa taille finale.
              Center(
                child: ScaleTransition(
                  scale: echelle,
                  child: PsyAvocatLogo(size: logoSize, showText: false),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                // Sous le logo (hauteur réelle du dessin : 87 % de sa largeur).
                top: ecran.height / 2 + logoSize * 0.44 + 12,
                child: FadeTransition(
                  opacity: texte,
                  child: SingleChildScrollView(
                    padding: AppSpacing.screenPadding,
                    child: Column(
                      children: [
                        Text.rich(
                          TextSpan(
                            style: AppTypography.grandTitre.copyWith(
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                            ),
                            children: const [
                              TextSpan(
                                text: 'Psy',
                                style: TextStyle(color: AppColors.logoPsy),
                              ),
                              TextSpan(
                                text: 'Avocat',
                                style: TextStyle(color: AppColors.lawyer),
                              ),
                            ],
                          ),
                        ),
                        AppSpacing.vGap16,
                        Text(
                          tr('Votre solution juridique\net psychologique'),
                          textAlign: TextAlign.center,
                          style: AppTypography.petitTitre,
                        ),
                        if (errorMessage != null) ...[
                          AppSpacing.vGap32,
                          Text(
                            errorMessage,
                            textAlign: TextAlign.center,
                            style: AppTypography.texteSecondaire,
                          ),
                          AppSpacing.vGap16,
                          AppButton(
                            text: tr('Réessayer'),
                            isFullWidth: false,
                            onPressed: () => ref
                                .read(sessionControllerProvider.notifier)
                                .resolve(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
