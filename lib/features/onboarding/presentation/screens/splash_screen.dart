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
    final logoSize = (MediaQuery.sizeOf(context).width * 0.55).clamp(
      140.0,
      240.0,
    );
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
          // Logo + textes centrés comme un seul bloc. Le bloc texte s'ouvre en
          // hauteur depuis 0 : au départ le logo est au centre exact (comme sur
          // l'écran de lancement natif), puis il remonte en douceur à mesure
          // que les textes apparaissent, jusqu'à ce que l'ensemble soit centré.
          child: Center(
            child: SingleChildScrollView(
              padding: AppSpacing.screenPadding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: echelle,
                    // Boîte réduite à la hauteur réelle du dessin (87 % de sa
                    // largeur) pour que l'espace sous le logo soit exact.
                    child: SizedBox(
                      width: logoSize,
                      height: logoSize * 0.87,
                      child: OverflowBox(
                        maxHeight: logoSize,
                        child: PsyAvocatLogo(size: logoSize, showText: false),
                      ),
                    ),
                  ),
                  SizeTransition(
                    sizeFactor: texte,
                    alignment: Alignment.topCenter,
                    child: FadeTransition(
                      opacity: texte,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppSpacing.vGap16,
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
                            textAlign: TextAlign.center,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
