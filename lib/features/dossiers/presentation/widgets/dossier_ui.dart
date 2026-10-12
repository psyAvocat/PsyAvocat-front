import 'package:flutter/material.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/dossier_model.dart';
import '../../../../core/l10n/app_strings.dart';

/// « Envoyé le 08/10/2026 · 09:41 » (première soumission), sinon la date
/// d'ouverture du dossier, qui n'a pas d'heure.
String? libelleEnvoi(DossierModel dossier) {
  final envoi = dossier.dateEnvoi;
  if (envoi != null) {
    return tr('Envoyé le {date}', {'date': Formatters.formatDateHeure(envoi)});
  }
  final ouverture = dossier.dateOuverture;
  if (ouverture != null) {
    return tr('Créé le {date}', {
      'date': Formatters.formatDateCourte(ouverture),
    });
  }
  return null;
}

/// « 1 pièce jointe », « 3 pièces jointes ».
String piecesJointesLabel(int n) => (n > 1
    ? tr('{n} pièces jointes', {'n': n})
    : tr('{n} pièce jointe', {'n': n}));

/// Couleurs d'état des dossiers. Fonds, bordures et textes neutres viennent
/// de la palette du mode courant (`context.palette`).
class DossierColors {
  DossierColors._();

  static const succes = Color(0xFF15803D);
  static const succesFond = Color(0xFFDCFCE7);
  static const refus = Color(0xFFB91C1C);
  static const refusFond = Color(0xFFFEE2E2);
}

/// Styles de texte communs aux écrans de dossiers.
class DossierText {
  DossierText._();

  static TextStyle secondaire(BuildContext context) => AppTypography.texte
      .copyWith(fontSize: 12, color: context.palette.textMuted);

  static TextStyle petit(BuildContext context) => AppTypography.texte.copyWith(
    fontSize: 11,
    color: context.palette.textMuted,
  );

  static TextStyle section(BuildContext context) => AppTypography.texteSemiBold
      .copyWith(fontSize: 15, color: context.colors.primary);
}

/// Carte bleu très clair à bordure fine.
class DossierCardContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const DossierCardContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: context.palette.cardTinted,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.palette.borderTinted),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0C2659),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Pastille ronde avec une icône (document, balance…).
class DossierIconBadge extends StatelessWidget {
  final IconData icon;
  final double size;

  const DossierIconBadge({
    super.key,
    this.icon = Icons.description_outlined,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context.palette.chip,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: size * 0.55, color: context.colors.primary),
    );
  }
}

/// Pastille d'état d'un dossier : en attente, réponses reçues, pris en charge,
/// décliné.
class DossierStatutBadge extends StatelessWidget {
  final DossierModel dossier;
  final bool avecIcone;

  const DossierStatutBadge({
    super.key,
    required this.dossier,
    this.avecIcone = false,
  });

  @override
  Widget build(BuildContext context) {
    final (label, couleur, fond) = _statut(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (avecIcone) ...[
            Icon(Icons.schedule_rounded, size: 14, color: couleur),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTypography.texteSemiBold.copyWith(
              fontSize: 11,
              color: couleur,
            ),
          ),
        ],
      ),
    );
  }

  (String, Color, Color) _statut(BuildContext context) {
    if (dossier.estPrisEnCharge) {
      return (
        tr('Pris en charge'),
        DossierColors.succes,
        DossierColors.succesFond,
      );
    }
    if (dossier.estDecline) {
      return (tr('Décliné'), DossierColors.refus, DossierColors.refusFond);
    }
    final reponses = dossier.nombreReponses;
    if (reponses > 0) {
      return (
        reponses > 1
            ? tr('{n} réponses reçues', {'n': reponses})
            : tr('{n} réponse reçue', {'n': reponses}),
        DossierColors.succes,
        DossierColors.succesFond,
      );
    }
    return (
      tr('En attente de réponse'),
      context.colors.primary,
      context.palette.chip,
    );
  }
}
