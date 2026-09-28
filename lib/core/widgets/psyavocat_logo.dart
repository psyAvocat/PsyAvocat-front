import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Widget officiel du logo de marque PsyAvocat.
/// Supporte l'affichage avec ou sans texte, et la variante blanche pour fonds colorés.
class PsyAvocatLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool isWhite;
  final double? fontSize;

  const PsyAvocatLogo({
    super.key,
    this.size = 120.0,
    this.showText = true,
    this.isWhite = false,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final logoWidget = Image.asset(
      'assets/logos/logo_psyavocat.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      color: isWhite ? Colors.white : null,
      errorBuilder: (context, error, stackTrace) {
        // Fallback icône élégante si l'asset met du temps à se charger
        return Icon(
          Icons.balance_rounded,
          size: size,
          color: isWhite ? Colors.white : AppColors.psychologist,
        );
      },
    );

    if (!showText) {
      return logoWidget;
    }

    final double effectiveFontSize = fontSize ?? (size * 0.28).clamp(18.0, 34.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        logoWidget,
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: effectiveFontSize,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              fontFamily: 'Montserrat',
            ),
            children: [
              TextSpan(
                text: 'Psy',
                style: TextStyle(
                  color: isWhite ? Colors.white : AppColors.psychologist,
                ),
              ),
              TextSpan(
                text: 'Avocat',
                style: TextStyle(
                  color: isWhite ? Colors.white : AppColors.lawyer,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
