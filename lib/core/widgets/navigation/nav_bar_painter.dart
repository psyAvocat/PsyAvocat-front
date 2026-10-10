import 'package:flutter/material.dart';

/// Peintre personnalisé pour la barre avec dôme mobile et encoche centrale.
class NavBarPainter extends CustomPainter {
  final double animatedIndex;
  final double domeProgress;
  final double baselineY;
  final double bottomY;
  final double cornerRadius;

  NavBarPainter({
    required this.animatedIndex,
    required this.domeProgress,
    required this.baselineY,
    required this.bottomY,
    required this.cornerRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final cx = w / 2.0;
    const double scoopRadius = 35.0;
    const double scoopDepth = 24.0;

    final double itemWidth = w / 5.0;
    final double animatedX = (animatedIndex + 0.5) * itemWidth;

    // 1. Dessin de la barre de base avec l'encoche centrale concave
    final Path baseBar = Path();
    baseBar.moveTo(0, baselineY + cornerRadius);
    baseBar.quadraticBezierTo(0, baselineY, cornerRadius, baselineY);

    // Ligne vers l'encoche centrale
    final double sLeft = cx - scoopRadius;
    final double sRight = cx + scoopRadius;

    baseBar.lineTo(sLeft, baselineY);
    baseBar.cubicTo(
      sLeft + scoopRadius * 0.45,
      baselineY,
      cx - scoopRadius * 0.4,
      baselineY + scoopDepth,
      cx,
      baselineY + scoopDepth,
    );
    baseBar.cubicTo(
      cx + scoopRadius * 0.4,
      baselineY + scoopDepth,
      sRight - scoopRadius * 0.45,
      baselineY,
      sRight,
      baselineY,
    );

    // Ligne vers le coin supérieur droit
    baseBar.lineTo(w - cornerRadius, baselineY);
    baseBar.quadraticBezierTo(w, baselineY, w, baselineY + cornerRadius);

    // Bord droit, coin inférieur droit, bord bas, coin inférieur gauche
    baseBar.lineTo(w, bottomY - cornerRadius);
    baseBar.quadraticBezierTo(w, bottomY, w - cornerRadius, bottomY);
    baseBar.lineTo(cornerRadius, bottomY);
    baseBar.quadraticBezierTo(0, bottomY, 0, bottomY - cornerRadius);
    baseBar.close();

    // 2. Calcul du dôme d'accentuation blanche autour de l'élément sélectionné
    final double distToCenter = (animatedX - cx).abs();
    // Le dôme s'estompe naturellement s'il traverse la zone centrale
    final double centerFade = (distToCenter / (scoopRadius + 18.0)).clamp(
      0.0,
      1.0,
    );
    final double domeH = 15.0 * domeProgress * centerFade;
    final double domeRadius = itemWidth * 0.46;

    Path finalPath = baseBar;

    if (domeH > 0.5) {
      final Path dome = Path();
      final double dLeft = animatedX - domeRadius;
      final double dRight = animatedX + domeRadius;

      dome.moveTo(dLeft, baselineY);
      dome.cubicTo(
        dLeft + domeRadius * 0.45,
        baselineY,
        animatedX - domeRadius * 0.4,
        baselineY - domeH,
        animatedX,
        baselineY - domeH,
      );
      dome.cubicTo(
        animatedX + domeRadius * 0.4,
        baselineY - domeH,
        dRight - domeRadius * 0.45,
        baselineY,
        dRight,
        baselineY,
      );
      // Fermeture dans le corps de la barre pour une union propre
      dome.lineTo(dRight, baselineY + 25.0);
      dome.lineTo(dLeft, baselineY + 25.0);
      dome.close();

      try {
        finalPath = Path.combine(PathOperation.union, baseBar, dome);
      } catch (_) {
        finalPath = baseBar;
      }
    }

    // 3. Ombre portée douce
    canvas.drawShadow(
      finalPath,
      Colors.black.withValues(alpha: 0.08),
      10.0,
      false,
    );

    // Seconde passe d'ombre directionnelle subtile
    final Paint softShadow = Paint()
      ..color = const Color(0x0C000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);
    canvas.drawPath(finalPath.shift(const Offset(0, 3)), softShadow);

    // 4. Remplissage blanc pur
    final Paint fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawPath(finalPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant NavBarPainter oldDelegate) {
    return oldDelegate.animatedIndex != animatedIndex ||
        oldDelegate.domeProgress != domeProgress;
  }
}
