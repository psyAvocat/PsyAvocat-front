import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Fond décoratif : petites particules floues qui montent lentement le long
/// des bords gauche et droit de l'écran. Très discret (faible opacité), ne
/// capte aucun geste et reste immobile si l'utilisateur a réduit les animations.
///
/// À placer en premier enfant d'un `Stack`, derrière le contenu.
class AmbientParticles extends StatefulWidget {
  /// Couleur des particules (par défaut : couleur principale de l'univers).
  final Color? color;

  /// Nombre de particules.
  final int count;

  const AmbientParticles({super.key, this.color, this.count = 22});

  @override
  State<AmbientParticles> createState() => _AmbientParticlesState();
}

class _AmbientParticlesState extends State<AmbientParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  );
  late List<_Particle> _particles = _generate(widget.count);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant AmbientParticles oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.count != widget.count) _particles = _generate(widget.count);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Tirage fixe (graine constante) : même disposition à chaque ouverture.
  static List<_Particle> _generate(int count) {
    final random = math.Random(7);
    return List.generate(count, (i) {
      // Uniquement sur les côtés : bande gauche ou bande droite.
      final leftSide = i.isEven;
      final band = random.nextDouble() * 0.26;
      return _Particle(
        x: leftSide ? 0.02 + band : 0.98 - band,
        y: random.nextDouble(),
        radius: 2 + random.nextDouble() * 4.5,
        // Vitesses entières : la boucle de l'animation est parfaitement continue.
        speed: 1 + random.nextInt(2),
        drift: 0.008 + random.nextDouble() * 0.02,
        phase: random.nextDouble(),
        opacity: 0.07 + random.nextDouble() * 0.11,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _ParticlesPainter(
            particles: _particles,
            color: color,
            progress: _controller,
          ),
        ),
      ),
    );
  }
}

class _Particle {
  final double x;
  final double y;
  final double radius;
  final int speed;
  final double drift;
  final double phase;
  final double opacity;

  const _Particle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.drift,
    required this.phase,
    required this.opacity,
  });
}

class _ParticlesPainter extends CustomPainter {
  final List<_Particle> particles;
  final Color color;
  final Animation<double> progress;

  _ParticlesPainter({
    required this.particles,
    required this.color,
    required this.progress,
  }) : super(repaint: progress);

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    final paint = Paint();
    for (final p in particles) {
      // Montée lente, avec retour en bas une fois sortie de l'écran.
      final y = (p.y - t * p.speed) % 1.0;
      final angle = 2 * math.pi * (t * 2 + p.phase);
      final x = p.x + math.sin(angle) * p.drift;
      // Fondu près des bords haut et bas, et léger scintillement.
      final edgeFade = math.min(1.0, math.min(y, 1 - y) * 6);
      final twinkle = 0.75 + 0.25 * math.sin(angle * 1.5);
      paint
        ..color = color.withValues(alpha: p.opacity * edgeFade * twinkle)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.radius * 0.6);
      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        p.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.particles != particles;
}
