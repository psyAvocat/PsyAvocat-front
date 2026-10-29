import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Illustration « plante en pot » dessinée en code (aucune image à charger) :
/// pot en terre cuite ombré, feuillage dégradé et deux fleurs, avec un léger
/// balancement des feuilles. Posée sur un halo aux couleurs de l'univers.
class PlantIllustration extends StatefulWidget {
  final double size;

  const PlantIllustration({super.key, this.size = 200});

  @override
  State<PlantIllustration> createState() => _PlantIllustrationState();
}

class _PlantIllustrationState extends State<PlantIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sway = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _sway.stop();
    } else if (!_sway.isAnimating) {
      _sway.repeat();
    }
  }

  @override
  void dispose() {
    _sway.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final size = widget.size;
    return SizedBox(
      width: size,
      height: size * 1.1,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Halo doux derrière la plante.
          Positioned(
            top: size * 0.12,
            child: Container(
              width: size * 0.92,
              height: size * 0.92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    scheme.primaryContainer.withValues(alpha: 0.9),
                    scheme.primaryContainer.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(painter: _PlantPainter(sway: _sway)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Une feuille : angle depuis la verticale (radians), longueur de tige,
/// longueur et largeur de la feuille, teinte.
class _Leaf {
  final double angle;
  final double stem;
  final double length;
  final double width;
  final Color dark;
  final Color light;

  const _Leaf(
    this.angle,
    this.stem,
    this.length,
    this.width,
    this.dark,
    this.light,
  );
}

class _PlantPainter extends CustomPainter {
  final Animation<double> sway;

  _PlantPainter({required this.sway}) : super(repaint: sway);

  static const _deep = Color(0xFF2F6B4F);
  static const _mid = Color(0xFF3F8A5F);
  static const _fresh = Color(0xFF7DBB84);
  static const _pale = Color(0xFF9FD0A0);

  // Du fond (dessinées en premier) vers l'avant.
  static const _leaves = [
    _Leaf(-1.15, 18, 62, 17, _deep, _mid),
    _Leaf(1.15, 18, 62, 17, _deep, _mid),
    _Leaf(-0.72, 30, 70, 19, _mid, _fresh),
    _Leaf(0.70, 28, 72, 19, _mid, _fresh),
    _Leaf(-0.28, 40, 66, 17, _mid, _pale),
    _Leaf(0.30, 38, 64, 17, _deep, _fresh),
    _Leaf(0.02, 26, 58, 16, _mid, _pale),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // Dessin sur une grille de 200 × 220, mise à l'échelle.
    final scale = size.width / 200;
    canvas.save();
    canvas.scale(scale);

    final t = sway.value * 2 * math.pi;
    const root = Offset(100, 132);

    _drawShadow(canvas);

    // Fleurs à l'arrière-plan du feuillage.
    _drawFlower(canvas, root, -0.18 + math.sin(t) * 0.025, 92, 0.9);
    _drawFlower(canvas, root, 0.42 + math.sin(t + 1.3) * 0.025, 78, 0.75);

    for (var i = 0; i < _leaves.length; i++) {
      final leaf = _leaves[i];
      final angle = leaf.angle + math.sin(t + i * 0.9) * 0.035;
      _drawLeaf(canvas, root, leaf, angle);
    }

    _drawPot(canvas);
    canvas.restore();
  }

  void _drawShadow(Canvas canvas) {
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(100, 207), width: 118, height: 14),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
  }

  void _drawLeaf(Canvas canvas, Offset root, _Leaf leaf, double angle) {
    final dir = Offset(math.sin(angle), -math.cos(angle));
    final normal = Offset(math.cos(angle), math.sin(angle));
    final base = root + dir * leaf.stem;
    final tip = base + dir * leaf.length;

    // Tige légèrement courbée.
    final stem = Path()
      ..moveTo(root.dx, root.dy)
      ..quadraticBezierTo(
        root.dx + dir.dx * leaf.stem * 0.3,
        root.dy + dir.dy * leaf.stem * 0.7,
        base.dx,
        base.dy,
      );
    canvas.drawPath(
      stem,
      Paint()
        ..color = _deep
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );

    // Limbe : deux courbes qui se rejoignent à la pointe.
    final middle = base + dir * (leaf.length * 0.45);
    final c1 = middle + normal * leaf.width;
    final c2 = middle - normal * leaf.width;
    final blade = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(c1.dx, c1.dy, tip.dx, tip.dy)
      ..quadraticBezierTo(c2.dx, c2.dy, base.dx, base.dy)
      ..close();
    canvas.drawPath(
      blade,
      Paint()
        ..shader = LinearGradient(
          colors: [leaf.dark, leaf.light],
        ).createShader(Rect.fromPoints(base, tip)),
    );

    // Nervure centrale.
    canvas.drawLine(
      base,
      base + dir * (leaf.length * 0.85),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawFlower(
    Canvas canvas,
    Offset root,
    double angle,
    double height,
    double scale,
  ) {
    final dir = Offset(math.sin(angle), -math.cos(angle));
    final head = root + dir * height;
    canvas.drawLine(
      root,
      head,
      Paint()
        ..color = _mid
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    final petal = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFBD3DC), Color(0xFFF29CB1)],
      ).createShader(Rect.fromCircle(center: head, radius: 12 * scale));
    for (var i = 0; i < 5; i++) {
      final a = i * 2 * math.pi / 5;
      canvas.save();
      canvas.translate(head.dx, head.dy);
      canvas.rotate(a);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(0, -6.5 * scale),
          width: 8 * scale,
          height: 12 * scale,
        ),
        petal,
      );
      canvas.restore();
    }
    canvas.drawCircle(
      head,
      3.6 * scale,
      Paint()..color = const Color(0xFFF6C744),
    );
  }

  void _drawPot(Canvas canvas) {
    // Corps du pot : légèrement évasé, fond arrondi.
    final body = Path()
      ..moveTo(60, 142)
      ..lineTo(140, 142)
      ..lineTo(130, 198)
      ..quadraticBezierTo(129, 205, 121, 205)
      ..lineTo(79, 205)
      ..quadraticBezierTo(71, 205, 70, 198)
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFB45F3E), Color(0xFFE29A72), Color(0xFFA9553A)],
          stops: [0, 0.42, 1],
        ).createShader(const Rect.fromLTWH(60, 142, 80, 63)),
    );

    // Ombre du rebord sur le corps.
    canvas.drawRect(
      const Rect.fromLTWH(61, 142, 78, 5),
      Paint()..color = Colors.black.withValues(alpha: 0.12),
    );

    // Rebord.
    final rim = RRect.fromRectAndRadius(
      const Rect.fromLTWH(52, 126, 96, 18),
      const Radius.circular(6),
    );
    canvas.drawRRect(
      rim,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFC86E4B), Color(0xFFF0AE88), Color(0xFFBA6343)],
          stops: [0, 0.45, 1],
        ).createShader(rim.outerRect),
    );

    // Terre, visible au ras du rebord.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(100, 129), width: 86, height: 8),
      Paint()..color = const Color(0xFF5B3A29),
    );
  }

  @override
  bool shouldRepaint(covariant _PlantPainter oldDelegate) => false;
}
