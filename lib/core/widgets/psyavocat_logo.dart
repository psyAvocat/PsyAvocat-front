import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/design_system.dart';

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
    final logoWidget = SvgPicture.asset(
      isWhite
          ? 'assets/logos/logo_psyavocat_white.svg'
          : 'assets/logos/logo_psyavocat.svg',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );

    if (!showText) {
      return logoWidget;
    }

    final double effectiveFontSize =
        fontSize ?? (size * 0.28).clamp(18.0, 34.0);
    final textStyle = AppTypography.grandTitre.copyWith(
      fontSize: effectiveFontSize,
      fontWeight: FontWeight.w800,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        logoWidget,
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            style: textStyle,
            children: [
              TextSpan(
                text: 'Psy',
                style: TextStyle(
                  color: isWhite ? Colors.white : AppColors.logoPsy,
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
