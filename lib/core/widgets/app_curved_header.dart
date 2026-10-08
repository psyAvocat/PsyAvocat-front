import 'package:flutter/material.dart';
import '../theme/design_system.dart';
import 'psyavocat_logo.dart';
import 'top_arch_clipper.dart';

/// En-tête arrondi en dégradé violet → bleu nuit avec le logo blanc.
///
/// Placé en haut des écrans d'authentification (connexion, mot de passe oublié).
/// Exemple : `const AppCurvedHeader()`
class AppCurvedHeader extends StatelessWidget {
  final double height;

  const AppCurvedHeader({super.key, this.height = 258});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: ClipPath(
        clipper: const TopArchClipper(),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: AppColors.authHeaderGradient,
          ),
          child: SafeArea(
            bottom: false,
            // Le logo est décalé vers la gauche, comme sur la maquette.
            child: Align(
              alignment: const Alignment(-0.35, -0.2),
              child: PsyAvocatLogo(
                size: height * 0.45,
                fontSize: 30,
                isWhite: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
