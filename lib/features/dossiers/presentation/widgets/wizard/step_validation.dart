import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../controllers/create_dossier_wizard_controller.dart';
import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/l10n/app_strings.dart';

/// Étape 4 : récapitulatif (chaque partie se modifie en revenant à son étape)
/// puis envoi réel (création, pièces, soumissions) avec sa progression.
class StepValidation extends ConsumerWidget {
  final VoidCallback onSubmitted;
  final VoidCallback onBack;

  /// Retour à une étape précise (0 : avocats, 1 : informations, 2 : pièces).
  final ValueChanged<int> onModifier;
  final Color primaryColor;

  const StepValidation({
    super.key,
    required this.onSubmitted,
    required this.onBack,
    required this.onModifier,
    required this.primaryColor,
  });

  Future<void> _envoyer(WidgetRef ref) async {
    final resultat = await ref
        .read(createDossierWizardProvider.notifier)
        .envoyer();
    if (resultat != null) onSubmitted();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createDossierWizardProvider);
    final enCours = state.envoiEnCours;
    final modifier = enCours ? null : onModifier;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              Text(
                tr('Vérifiez avant d’envoyer'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: context.palette.textStrong,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                tr(
                  'Touchez « Modifier » pour corriger une partie. Rien n’est envoyé avant votre confirmation.',
                ),
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: context.palette.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              _Bloc(
                titre: tr('Informations du dossier'),
                icone: Icons.description_outlined,
                couleur: primaryColor,
                onModifier: modifier == null ? null : () => modifier(1),
                children: [
                  _Ligne(libelle: tr('Titre'), valeur: state.titre),
                  _Ligne(
                    libelle: tr('Domaine'),
                    valeur: state.domaine?.nom ?? tr('Non précisé'),
                  ),
                  _Ligne(
                    libelle: tr('Description'),
                    valeur: state.description,
                    maxLignes: 4,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _Bloc(
                titre: tr('Avocats destinataires ({n})', {
                  'n': state.selectedProfessionnels.length,
                }),
                icone: Icons.gavel_rounded,
                couleur: primaryColor,
                onModifier: modifier == null ? null : () => modifier(0),
                children: [
                  for (final p in state.selectedProfessionnels)
                    _Puce(texte: p.displayName, icone: Icons.person_outline),
                ],
              ),
              const SizedBox(height: 12),
              _Bloc(
                titre: tr('Pièces jointes ({n})', {
                  'n': state.piecesJointes.length,
                }),
                icone: Icons.attach_file_rounded,
                couleur: primaryColor,
                onModifier: modifier == null ? null : () => modifier(2),
                children: state.piecesJointes.isEmpty
                    ? [_Puce(texte: tr('Aucune'), icone: Icons.remove_rounded)]
                    : [
                        for (final p in state.piecesJointes)
                          _Puce(
                            texte: p.nom,
                            icone: Icons.insert_drive_file_outlined,
                          ),
                      ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        tr(
                          'Chaque avocat pourra accepter ou décliner votre dossier. Le premier qui '
                          'l’accepte le prend en charge : vous pourrez alors prendre rendez-vous avec lui.',
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: context.palette.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (enCours) ...[
                const SizedBox(height: 14),
                _Progression(etape: state.etape, couleur: primaryColor),
              ],
              if (state.erreur != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Color(0xFFDC2626),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          state.erreur!,
                          style: const TextStyle(color: Color(0xFF991B1B)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.palette.card,
            boxShadow: [
              BoxShadow(
                color: Color(0x0A000000),
                offset: Offset(0, -4),
                blurRadius: 10,
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: tr('Retour'),
                    onPressed: enCours ? null : onBack,
                    isOutlined: true,
                    textColor: context.palette.textStrong,
                    color: context.palette.border,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: AppButton(
                    text: tr('Envoyer le dossier'),
                    icon: Icons.send_rounded,
                    isLoading: enCours,
                    onPressed: enCours ? null : () => _envoyer(ref),
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Progression de l'envoi : création, pièces jointes, transmission.
class _Progression extends StatelessWidget {
  final EnvoiDossierEtape etape;
  final Color couleur;

  const _Progression({required this.etape, required this.couleur});

  @override
  Widget build(BuildContext context) {
    const ordre = [
      EnvoiDossierEtape.creation,
      EnvoiDossierEtape.piecesJointes,
      EnvoiDossierEtape.soumissions,
    ];
    final libelles = [
      tr('Création du dossier'),
      tr('Envoi des pièces jointes'),
      tr('Transmission aux avocats'),
    ];
    final courant = ordre.indexOf(etape);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.palette.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.palette.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < ordre.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == ordre.length - 1 ? 0 : 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: i < courant
                        ? Icon(
                            Icons.check_circle_rounded,
                            size: 20,
                            color: couleur,
                          )
                        : i == courant
                        ? CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: couleur,
                          )
                        : Icon(
                            Icons.radio_button_unchecked_rounded,
                            size: 20,
                            color: context.palette.textSubtle,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    libelles[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: i == courant
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: i <= courant
                          ? context.palette.textStrong
                          : context.palette.textSubtle,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Bloc extends StatelessWidget {
  final String titre;
  final IconData icone;
  final Color couleur;
  final VoidCallback? onModifier;
  final List<Widget> children;

  const _Bloc({
    required this.titre,
    required this.icone,
    required this.couleur,
    required this.onModifier,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
      decoration: BoxDecoration(
        color: context.palette.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, size: 18, color: couleur),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titre,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: context.palette.textStrong,
                  ),
                ),
              ),
              TextButton(
                onPressed: onModifier,
                style: TextButton.styleFrom(
                  foregroundColor: couleur,
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(tr('Modifier')),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _Ligne extends StatelessWidget {
  final String libelle;
  final String valeur;
  final int maxLignes;

  const _Ligne({
    required this.libelle,
    required this.valeur,
    this.maxLignes = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            libelle,
            style: TextStyle(fontSize: 11, color: context.palette.textMuted),
          ),
          const SizedBox(height: 2),
          Text(
            valeur,
            maxLines: maxLignes,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: context.palette.textStrong,
            ),
          ),
        ],
      ),
    );
  }
}

class _Puce extends StatelessWidget {
  final String texte;
  final IconData icone;
  const _Puce({required this.texte, required this.icone});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icone, size: 16, color: context.palette.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texte,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, color: context.palette.text),
            ),
          ),
        ],
      ),
    );
  }
}
