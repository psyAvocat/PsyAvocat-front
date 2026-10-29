import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/cible_visite.dart';
import '../visite_guidee_controller.dart';

/// Étape de la visite : un élément réel de l'interface ([cible], repéré par
/// [CibleVisite]) et une explication courte. Sans cible : carte d'accueil.
class _Etape {
  final String? cible;
  final String titre;
  final String texte;

  const _Etape({this.cible, required this.titre, required this.texte});
}

/// Visite guidée de l'application (première arrivée sur l'accueil).
///
/// L'écran s'assombrit sauf l'élément présenté, entouré d'un halo ; une bulle
/// l'explique en une ou deux phrases. « Passer » (ou le bouton retour) ferme la
/// visite, qui ne sera plus proposée ; elle se relance depuis les Paramètres.
class VisiteGuidee extends ConsumerStatefulWidget {
  const VisiteGuidee({super.key});

  @override
  ConsumerState<VisiteGuidee> createState() => _VisiteGuideeState();
}

class _VisiteGuideeState extends ConsumerState<VisiteGuidee>
    with WidgetsBindingObserver {
  int _etape = 0;

  /// Zone de l'élément présenté, dans le repère de la visite.
  Rect? _zone;

  List<_Etape> _etapes(AppUniverse univers) {
    final avocat = univers.isLawyer;
    return [
      _Etape(
        titre: tr('Bienvenue sur PsyAvocat'),
        texte: tr(
          'Une courte visite pour repérer l’essentiel : vos notifications, '
          'les contenus, les professionnels, vos rendez-vous et votre profil.',
        ),
      ),
      _Etape(
        cible: 'notifications',
        titre: tr('Vos notifications'),
        texte: tr(
          'Confirmations, nouveaux messages et rappels de rendez-vous. '
          'Pour une visio, le lien de la salle arrive ici 15 minutes avant.',
        ),
      ),
      _Etape(
        cible: 'onglet-1',
        titre: avocat ? tr('Articles juridiques') : tr('Conseils'),
        texte: avocat
            ? tr(
                'Des articles rédigés par des avocats vérifiés pour mieux comprendre vos droits.',
              )
            : tr(
                'Des conseils rédigés par des psychologues vérifiés pour prendre soin de vous.',
              ),
      ),
      _Etape(
        cible: 'onglet-2',
        titre: avocat ? tr('Trouver un avocat') : tr('Trouver un psychologue'),
        texte: avocat
            ? tr(
                'Consultez les profils vérifiés, soumettez votre dossier, puis réservez un créneau avec l’avocat qui l’accepte.',
              )
            : tr(
                'Consultez les profils vérifiés, leurs tarifs et leurs créneaux, puis réservez en quelques gestes.',
              ),
      ),
      _Etape(
        cible: 'onglet-3',
        titre: tr('Vos rendez-vous'),
        texte: tr(
          'Au cabinet ou en visio : l’heure, le lieu et, pour une visio, le bouton pour rejoindre la salle.',
        ),
      ),
      _Etape(
        cible: 'onglet-4',
        titre: tr('Votre profil'),
        texte: tr(
          'Messagerie, changement d’univers (Avocat ou Psychologue), paiements et paramètres. '
          'Cette visite peut être relancée depuis les paramètres.',
        ),
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _mesurerApresAffichage();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Rotation, clavier, taille de texte : la zone est remesurée.
  @override
  void didChangeMetrics() => _mesurerApresAffichage();

  void _mesurerApresAffichage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final repere = context.findRenderObject();
      final cible = _etapes(ref.read(currentUniverseProvider))[_etape].cible;
      final zone = cible != null && repere is RenderBox
          ? CibleVisite.zone(cible, repere)
          : null;
      if (zone != _zone) setState(() => _zone = zone);
    });
  }

  void _allerA(int etape) {
    setState(() => _etape = etape);
    _mesurerApresAffichage();
  }

  Future<void> _terminer() =>
      ref.read(visiteGuideeProvider.notifier).terminer();

  @override
  Widget build(BuildContext context) {
    final etapes = _etapes(ref.watch(currentUniverseProvider));
    final etape = etapes[_etape];
    final accueil = etape.cible == null;
    final zone = accueil ? null : _zone;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _terminer();
      },
      child: LayoutBuilder(
        builder: (context, contraintes) {
          final taille = contraintes.biggest;
          return Stack(
            children: [
              // Voile sombre, percé autour de l'élément présenté.
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {},
                  child: zone == null
                      ? const CustomPaint(painter: _Voile(trou: null))
                      // Le halo glisse d'un élément à l'autre.
                      : TweenAnimationBuilder<Rect?>(
                          tween: RectTween(end: zone.inflate(6)),
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOutCubic,
                          builder: (context, trou, _) =>
                              CustomPaint(painter: _Voile(trou: trou)),
                        ),
                ),
              ),
              _positionnerBulle(
                taille: taille,
                zone: zone,
                child: _Bulle(
                  key: ValueKey(_etape),
                  etape: etape,
                  numero: _etape,
                  total: etapes.length - 1,
                  onPasser: _terminer,
                  onPrecedent: _etape > 1 ? () => _allerA(_etape - 1) : null,
                  onSuivant: _etape < etapes.length - 1
                      ? () => _allerA(_etape + 1)
                      : _terminer,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Bulle au-dessus de l'élément s'il est en bas de l'écran, en dessous
  /// sinon ; centrée pour la carte d'accueil.
  Widget _positionnerBulle({
    required Size taille,
    required Rect? zone,
    required Widget child,
  }) {
    const marge = AppSpacing.s16;
    final largeur = (taille.width - 2 * marge).clamp(0.0, 380.0);
    final gauche = (taille.width - largeur) / 2;
    final animee = AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: child,
    );
    if (zone == null) {
      return Positioned(
        left: gauche,
        width: largeur,
        top: 0,
        bottom: 0,
        child: Center(child: animee),
      );
    }
    final enBas = zone.center.dy > taille.height / 2;
    return Positioned(
      left: gauche,
      width: largeur,
      top: enBas ? null : zone.bottom + 18,
      bottom: enBas ? taille.height - zone.top + 18 : null,
      child: animee,
    );
  }
}

class _Bulle extends StatelessWidget {
  final _Etape etape;
  final int numero;
  final int total;
  final VoidCallback onPasser;
  final VoidCallback? onPrecedent;
  final VoidCallback onSuivant;

  const _Bulle({
    super.key,
    required this.etape,
    required this.numero,
    required this.total,
    required this.onPasser,
    required this.onPrecedent,
    required this.onSuivant,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final couleur = Theme.of(context).colorScheme.primary;
    final accueil = etape.cible == null;
    final derniere = numero == total;

    return Material(
      color: palette.card,
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      borderRadius: AppRadii.r16,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: accueil
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            if (accueil) ...[
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: couleur.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.explore_outlined, color: couleur, size: 28),
              ),
              AppSpacing.vGap16,
            ] else
              Row(
                children: [
                  _Progression(etape: numero, total: total, couleur: couleur),
                  AppSpacing.hGap8,
                  Text(
                    tr('{n} sur {total}', {'n': numero, 'total': total}),
                    style: AppTypography.badgeTexte.copyWith(
                      color: couleur,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: onPasser,
                    style: TextButton.styleFrom(
                      foregroundColor: palette.textMuted,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(tr('Passer')),
                  ),
                ],
              ),
            Text(
              etape.titre,
              textAlign: accueil ? TextAlign.center : TextAlign.start,
              style: AppTypography.titrePage.copyWith(
                fontSize: 18,
                color: palette.textStrong,
              ),
            ),
            AppSpacing.vGap8,
            Text(
              etape.texte,
              textAlign: accueil ? TextAlign.center : TextAlign.start,
              style: AppTypography.texte.copyWith(
                color: palette.text,
                height: 1.45,
              ),
            ),
            AppSpacing.vGap20,
            if (accueil)
              Row(
                children: [
                  Expanded(
                    child: AppButton.ghost(
                      text: tr('Plus tard'),
                      isFullWidth: true,
                      size: AppButtonSize.compact,
                      onPressed: onPasser,
                    ),
                  ),
                  AppSpacing.hGap8,
                  Expanded(
                    child: AppButton(
                      text: tr('Commencer'),
                      size: AppButtonSize.compact,
                      onPressed: onSuivant,
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  if (onPrecedent != null) ...[
                    Expanded(
                      child: AppButton.ghost(
                        text: tr('Précédent'),
                        isFullWidth: true,
                        size: AppButtonSize.compact,
                        onPressed: onPrecedent,
                      ),
                    ),
                    AppSpacing.hGap8,
                  ],
                  Expanded(
                    child: AppButton(
                      text: derniere ? tr('Terminer') : tr('Suivant'),
                      size: AppButtonSize.compact,
                      onPressed: onSuivant,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Points de progression : l'étape courante est allongée.
class _Progression extends StatelessWidget {
  final int etape;
  final int total;
  final Color couleur;

  const _Progression({
    required this.etape,
    required this.total,
    required this.couleur,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 1; i <= total; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.only(right: 4),
            width: i == etape ? 16 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == etape ? couleur : couleur.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}

/// Voile sombre sur tout l'écran, percé d'un rectangle arrondi autour de
/// l'élément présenté (bordé d'un fin liseré blanc).
class _Voile extends CustomPainter {
  final Rect? trou;

  const _Voile({required this.trou});

  @override
  void paint(Canvas canvas, Size size) {
    final ecran = Path()..addRect(Offset.zero & size);
    final voile = Paint()..color = Colors.black.withValues(alpha: 0.62);
    final zone = trou;
    if (zone == null) {
      canvas.drawPath(ecran, voile);
      return;
    }
    final arrondi = RRect.fromRectAndRadius(zone, const Radius.circular(18));
    canvas.drawPath(
      Path.combine(PathOperation.difference, ecran, Path()..addRRect(arrondi)),
      voile,
    );
    canvas.drawRRect(
      arrondi,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(_Voile ancien) => ancien.trou != trou;
}
