import 'package:flutter/material.dart';

/// Fond de la barre de navigation : capsule blanche dont le bord supérieur est
/// creusé d'une encoche circulaire (un « trou ») centrée sur l'onglet actif.
///
/// L'encoche suit [notchCenterX] pendant l'animation ; le rond coloré de
/// l'onglet actif vient se loger dedans.
class NavBarPainter extends CustomPainter {
  /// Abscisse du centre de l'encoche, en pixels depuis le bord gauche.
  final double notchCenterX;

  /// Rayon de l'encoche (rond de l'onglet actif + marge autour).
  final double notchRadius;

  /// Ordonnée du centre de l'encoche par rapport au bord supérieur de la barre
  /// (négatif : au-dessus du bord).
  final double notchCenterY;

  final Color color;
  final Color shadowColor;
  final double cornerRadius;

  const NavBarPainter({
    required this.notchCenterX,
    required this.notchRadius,
    required this.notchCenterY,
    required this.color,
    required this.shadowColor,
    this.cornerRadius = 30,
  });

  Path _path(Size size) {
    final host = Offset.zero & size;
    final guest = Rect.fromCircle(
      center: Offset(notchCenterX, notchCenterY),
      radius: notchRadius,
    );
    // Encoche aux épaulements adoucis (même géométrie que la BottomAppBar Material).
    final notched = const CircularNotchedRectangle().getOuterPath(host, guest);
    final capsule = Path()
      ..addRRect(RRect.fromRectAndRadius(host, Radius.circular(cornerRadius)));
    return Path.combine(PathOperation.intersect, notched, capsule);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _path(size);
    canvas.drawShadow(path, shadowColor, 14, false);
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(NavBarPainter old) =>
      old.notchCenterX != notchCenterX ||
      old.notchRadius != notchRadius ||
      old.notchCenterY != notchCenterY ||
      old.color != color ||
      old.shadowColor != shadowColor ||
      old.cornerRadius != cornerRadius;
}
