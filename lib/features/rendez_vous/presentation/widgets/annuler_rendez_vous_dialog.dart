import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/models/rendez_vous_model.dart';

/// Choix fait dans la feuille d'annulation : [motif] vide si non renseigné.
class AnnulationConfirmee {
  final String motif;
  const AnnulationConfirmee(this.motif);
}

/// Confirmation d'annulation d'un rendez-vous (boîte de dialogue centrée,
/// au-dessus de la barre de navigation), avec un motif facultatif transmis au
/// professionnel. Renvoie null si l'utilisateur garde son rendez-vous.
Future<AnnulationConfirmee?> showAnnulerRendezVousDialog(
  BuildContext context,
  RendezVous rdv,
) {
  return showDialog<AnnulationConfirmee>(
    context: context,
    useRootNavigator: true,
    builder: (_) => _AnnulerRendezVousDialog(rdv: rdv),
  );
}

class _AnnulerRendezVousDialog extends StatefulWidget {
  final RendezVous rdv;
  const _AnnulerRendezVousDialog({required this.rdv});

  @override
  State<_AnnulerRendezVousDialog> createState() =>
      _AnnulerRendezVousDialogState();
}

class _AnnulerRendezVousDialogState extends State<_AnnulerRendezVousDialog> {
  /// Même limite que le serveur.
  static const _longueurMax = 300;

  final _motif = TextEditingController();

  @override
  void dispose() {
    _motif.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rdv = widget.rdv;
    final viaDossier = rdv.dossierId != null;
    return Dialog(
      backgroundColor: context.palette.card,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.event_busy_rounded,
                    color: AppColors.danger,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                tr('Annuler ce rendez-vous ?'),
                textAlign: TextAlign.center,
                style: AppTypography.texteSemiBold.copyWith(
                  fontSize: 18,
                  color: context.palette.textStrong,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                tr('{pro} — {date} à {heure}', {
                  'pro': rdv.professionnelDisplayName,
                  'date': Formatters.formatJourLong(rdv.dateHeure),
                  'heure': Formatters.formatHeure(rdv.dateHeure),
                }),
                textAlign: TextAlign.center,
                style: AppTypography.texte.copyWith(
                  fontSize: 14,
                  color: context.palette.text,
                ),
              ),
              const SizedBox(height: 18),
              _Consequence(
                icone: Icons.lock_open_rounded,
                texte: tr('Le créneau est libéré pour d’autres personnes.'),
              ),
              _Consequence(
                icone: Icons.notifications_active_outlined,
                texte: tr(
                  '{pro} est prévenu immédiatement, avec votre motif s’il est renseigné.',
                  {'pro': rdv.professionnelDisplayName},
                ),
              ),
              _Consequence(
                icone: Icons.account_balance_wallet_outlined,
                texte: tr(
                  'L’acompte (paiement simulé) est annulé : aucune somme n’a été débitée.',
                ),
              ),
              if (viaDossier)
                _Consequence(
                  icone: Icons.folder_shared_outlined,
                  texte: tr(
                    'Votre dossier reste confié à cet avocat : vous pourrez reprendre rendez-vous à tout moment.',
                  ),
                ),
              const SizedBox(height: 14),
              TextField(
                controller: _motif,
                maxLength: _longueurMax,
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: tr('Motif (facultatif)'),
                  hintText: tr('Ex. : empêchement professionnel'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AppButton(
                text: tr('Confirmer l’annulation'),
                color: AppColors.danger,
                onPressed: () => Navigator.pop(
                  context,
                  AnnulationConfirmee(_motif.text.trim()),
                ),
              ),
              const SizedBox(height: 8),
              AppButton.ghost(
                text: tr('Garder mon rendez-vous'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Consequence extends StatelessWidget {
  final IconData icone;
  final String texte;
  const _Consequence({required this.icone, required this.texte});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 18, color: context.palette.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texte,
              style: AppTypography.texte.copyWith(
                fontSize: 13,
                height: 1.4,
                color: context.palette.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
