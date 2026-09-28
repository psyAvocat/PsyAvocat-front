import 'dart:math';
import 'package:flutter/material.dart';

/// Widget vectoriel haute précision affichant le logo officiel "G" de Google en 4 couleurs.
class GoogleLogo extends StatelessWidget {
  final double size;

  const GoogleLogo({super.key, this.size = 24.0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = min(w, h) / 2;
    final strokeWidth = radius * 0.42;
    final arcRadius = radius - (strokeWidth / 2);

    final rect = Rect.fromCircle(center: center, radius: arcRadius);

    final paintBlue = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final paintGreen = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final paintYellow = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final paintRed = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // Arcs pour le 'G'
    // Bleu : de 315° à 45°
    canvas.drawArc(rect, -pi / 4, pi / 2, false, paintBlue);

    // Vert : de 45° à 135°
    canvas.drawArc(rect, pi / 4, pi / 2, false, paintGreen);

    // Jaune : de 135° à 225°
    canvas.drawArc(rect, 3 * pi / 4, pi / 2, false, paintYellow);

    // Rouge : de 225° à 315°
    canvas.drawArc(rect, 5 * pi / 4, pi / 2, false, paintRed);

    // Barre horizontale bleue du G
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    final barRect = Rect.fromLTRB(
      center.dx - radius * 0.05,
      center.dy - strokeWidth / 2,
      center.dx + radius,
      center.dy + strokeWidth / 2,
    );
    canvas.drawRect(barRect, barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
