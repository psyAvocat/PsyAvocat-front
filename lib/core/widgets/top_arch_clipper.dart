import 'package:flutter/material.dart';

/// Découpe la forme arrondie de l'en-tête des écrans d'authentification.
///
/// Les points sont recopiés de la maquette Figma « Connexion »,
/// dessinée dans un cadre de 393 × 258 px, puis mis à l'échelle
/// à la taille réelle de l'en-tête.
class TopArchClipper extends CustomClipper<Path> {
  const TopArchClipper();

  /// Taille du cadre dans la maquette Figma.
  static const double _figmaWidth = 393;
  static const double _figmaHeight = 258;

  @override
  Path getClip(Size size) {
    // Convertit un point de la maquette en point réel.
    Offset point(double x, double y) =>
        Offset(x / _figmaWidth * size.width, y / _figmaHeight * size.height);

    final start = point(419, -18);
    final bottom = point(137, 254);
    final left = point(-3, 19);
    final c1 = point(395, 31);
    final c2 = point(364, 203);
    final c3 = point(-39, 293);
    final c4 = point(-24, 53);

    return Path()
      ..moveTo(start.dx, start.dy)
      // Bord droit qui descend vers le bas de la courbe
      ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, bottom.dx, bottom.dy)
      // Bas de la courbe qui remonte vers le bord gauche
      ..cubicTo(c3.dx, c3.dy, c4.dx, c4.dy, left.dx, left.dy)
      // Fermeture par le haut de l'écran
      ..lineTo(left.dx, start.dy)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
