import 'dart:math';
import 'package:flutter/material.dart';

/// Widget vectoriel haute précision affichant le logo officiel "G" de Google en 4 couleurs.
/// Reproduit fidèlement la forme du G avec l'arc ouvert sur la gauche et la barre horizontale bleue.
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
    final Offset center = Offset(w / 2, h / 2);
    final double radius = min(w, h) / 2;

    // Épaisseur du trait proportionnelle à la taille
    final double strokeW = radius * 0.38;
    final double arcR = radius - strokeW / 2;
    final Rect rect = Rect.fromCircle(center: center, radius: arcR);

    // ─── Couleurs officielles Google ─────────────────────────────────────────
    const Color blue   = Color(0xFF4285F4);
    const Color green  = Color(0xFF34A853);
    const Color yellow = Color(0xFFFBBC04);
    const Color red    = Color(0xFFEA4335);

    Paint makePaint(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.butt;

    // ─── Arc Bleu : haut-droit (de -45° à +45°) ──────────────────────────────
    // Départ à -pi/2 (haut) + décalage pour ouvrir le G à gauche
    // Angles en radians, dans le sens horaire (flutter convention)
    // Rouge  : 225° → 315°  (de bas-gauche vers le haut-gauche)
    // Bleu   : 315° → 45°   (de haut-gauche vers haut-droit)
    // Vert   :  45° → 135°  (de haut-droit vers bas-droit)
    // Jaune  : 135° → 225°  (de bas-droit vers bas-gauche)

    // Convertis en radians (0 = droite, sens horaire)
    const double deg = pi / 180;

    // Rouge : de 225° pendant 90°
    canvas.drawArc(rect, 225 * deg, 90 * deg, false, makePaint(red));
    // Bleu : de 315° pendant 90°
    canvas.drawArc(rect, 315 * deg, 90 * deg, false, makePaint(blue));
    // Vert : de 45° pendant 90°
    canvas.drawArc(rect, 45 * deg, 90 * deg, false, makePaint(green));
    // Jaune : de 135° pendant 90°
    canvas.drawArc(rect, 135 * deg, 90 * deg, false, makePaint(yellow));

    // ─── Barre horizontale bleue du G ────────────────────────────────────────
    // Positionnée au centre vertical, de center.dx jusqu'au bord droit de l'arc
    final double barTop    = center.dy - strokeW / 2;
    final double barBottom = center.dy + strokeW / 2;
    final double barLeft   = center.dx - strokeW * 0.12; // légère extension gauche
    final double barRight  = center.dx + arcR + strokeW / 2;

    final Paint barPaint = Paint()
      ..color = blue
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTRB(barLeft, barTop, barRight, barBottom),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
