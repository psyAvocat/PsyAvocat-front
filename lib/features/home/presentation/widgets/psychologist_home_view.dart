import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../contenus/presentation/widgets/popular_publications_section.dart';
import 'home_action_card.dart';
import 'home_cards.dart';
import '../../../../core/l10n/app_strings.dart';

/// Accueil de l'univers Psychologue — maquette « Accueil psychologue ».
class PsychologistHomeView extends StatelessWidget {
  const PsychologistHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      // Marge basse : la barre de navigation flotte au-dessus du contenu.
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s20,
        AppSpacing.s8,
        AppSpacing.s20,
        120,
      ),
      children: [
        // La recherche ouvre l'écran de recherche des psychologues.
        AppSearchField(
          hintText: tr('Rechercher un psychologue, une spécialité…'),
          onTap: () => context.go(AppRoutes.professionnelsRecherche),
        ),
        AppSpacing.vGap20,
        const _WellbeingBanner(),
        AppSpacing.vGap20,
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: HomeActionCard(
                  title: tr('Trouver un psychologue'),
                  icon: Icons.person_search_outlined,
                  subtitle: tr('Trouvez le professionnel qui vous correspond'),
                  highlighted: true,
                  onTap: () => context.go(AppRoutes.professionnels),
                ),
              ),
              AppSpacing.hGap12,
              Expanded(
                child: HomeActionCard(
                  title: tr('Consulter les conseils'),
                  icon: Icons.lightbulb_outline_rounded,
                  subtitle: tr('Des conseils d’experts pour mieux vivre'),
                  onTap: () => context.go(AppRoutes.conseils),
                ),
              ),
            ],
          ),
        ),
        AppSpacing.vGap24,
        AppSectionHeader(title: tr('Votre prochain rendez-vous')),
        AppSpacing.vGap8,
        const NextAppointmentCard(),
        AppSpacing.vGap24,
        const PopularPublicationsSection(),
      ],
    );
  }
}

/// Bannière « Prenez soin de votre santé mentale » : photo d'une séance en
/// fond, visible en transparence sous la couleur de l'univers, et un reflet
/// discret qui parcourt le bord de temps en temps. Elle ouvre le questionnaire
/// d'orientation (questions et réponses chargées depuis la base).
class _WellbeingBanner extends StatelessWidget {
  const _WellbeingBanner();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _OccasionalBorderGlow(
      radius: 16,
      child: ClipRRect(
        borderRadius: AppRadii.r16,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push(AppRoutes.orientation),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/psychologist_session.jpg',
                    fit: BoxFit.cover,
                    alignment: const Alignment(0.2, 0),
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _BannerArtPainter(scheme.primary),
                  ),
                ),
                Padding(
                  padding: AppSpacing.cardPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSpacing.vGap16,
                      Text(
                        tr('Prenez soin\nde votre santé mentale'),
                        style: AppTypography.petitTitre.copyWith(
                          color: scheme.onPrimary,
                        ),
                      ),
                      AppSpacing.vGap8,
                      Text(
                        tr(
                          'Un accompagnement bienveillant pour avancer sereinement.',
                        ),
                        style: AppTypography.texteSecondaire.copyWith(
                          color: scheme.onPrimary,
                        ),
                      ),
                      AppSpacing.vGap16,
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s16,
                          vertical: AppSpacing.s8,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.onPrimary,
                          borderRadius: AppRadii.pill,
                        ),
                        child: Text(
                          tr('Faire le test d’orientation'),
                          style: AppTypography.texteSecondaire.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      AppSpacing.vGap8,
                    ],
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

/// Voile de la bannière, posé sur la photo : couleur de l'univers (la photo
/// reste visible en transparence) et vague apaisante.
class _BannerArtPainter extends CustomPainter {
  final Color base;

  const _BannerArtPainter(this.base);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = base.withValues(alpha: 0.78),
    );

    final vague = Path()
      ..moveTo(0, h * 0.78)
      ..cubicTo(w * 0.25, h * 0.62, w * 0.45, h * 0.98, w * 0.70, h * 0.80)
      ..cubicTo(w * 0.85, h * 0.70, w * 0.95, h * 0.74, w, h * 0.70)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      vague,
      Paint()..color = Colors.white.withValues(alpha: 0.08),
    );
  }

  @override
  bool shouldRepaint(_BannerArtPainter old) => old.base != base;
}

/// Reflet lumineux discret qui fait un tour du bord de la carte, puis
/// disparaît : il ne revient qu'après une pause (pas d'animation continue).
/// Désactivé si l'utilisateur a réduit les animations.
class _OccasionalBorderGlow extends StatefulWidget {
  final Widget child;
  final double radius;

  const _OccasionalBorderGlow({required this.child, required this.radius});

  @override
  State<_OccasionalBorderGlow> createState() => _OccasionalBorderGlowState();
}

class _OccasionalBorderGlowState extends State<_OccasionalBorderGlow>
    with SingleTickerProviderStateMixin {
  /// Durée d'un passage du reflet, et pause entre deux passages.
  static const _passage = Duration(milliseconds: 2600);
  static const _pause = Duration(seconds: 9);
  static const _premierDelai = Duration(seconds: 2);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _passage,
  )..addStatusListener(_onStatus);
  Timer? _timer;
  bool? _animationsReduites;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduites = MediaQuery.disableAnimationsOf(context);
    if (reduites == _animationsReduites) return;
    _animationsReduites = reduites;
    _timer?.cancel();
    if (reduites) {
      _controller.reset();
    } else {
      _timer = Timer(_premierDelai, _lancer);
    }
  }

  void _lancer() {
    if (mounted) _controller.forward(from: 0);
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _controller.reset();
      _timer = Timer(_pause, _lancer);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _GlowPainter(
        progress: _controller,
        radius: widget.radius,
      ),
      child: widget.child,
    );
  }
}

class _GlowPainter extends CustomPainter {
  final Animation<double> progress;
  final double radius;

  _GlowPainter({required this.progress, required this.radius})
    : super(repaint: progress);

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    if (t == 0) return;
    // Apparition et disparition en douceur au cours du passage.
    final intensite = math.sin(math.pi * t);
    final rect = (Offset.zero & size).deflate(0.75);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius - 0.75));
    final shader = SweepGradient(
      colors: [
        Colors.white.withValues(alpha: 0),
        Colors.white.withValues(alpha: 0),
        Colors.white.withValues(alpha: 0.55 * intensite),
        Colors.white.withValues(alpha: 0),
        Colors.white.withValues(alpha: 0),
      ],
      stops: const [0, 0.42, 0.5, 0.58, 1],
      transform: GradientRotation(-math.pi / 2 + t * 2 * math.pi),
    ).createShader(rect);

    // Halo léger, puis trait fin par-dessus.
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _GlowPainter oldDelegate) =>
      oldDelegate.radius != radius;
}
