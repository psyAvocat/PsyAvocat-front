import 'package:flutter/material.dart';

/// Clipper pour l'arche supérieure violette foncée conforme à la charte Figma PsyAvocat.
/// Utilisé sur les écrans d'authentification (LoginScreen, RegisterScreen, ForgotPasswordScreen).
class TopArchClipper extends CustomClipper<Path> {
  const TopArchClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.82);
    path.quadraticBezierTo(
      size.width * 0.45,
      size.height * 1.08,
      size.width,
      size.height * 0.15,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Alias pour compatibilité ascendante avec les suites de test
typedef TopWaveClipper = TopArchClipper;
