import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../controllers/create_dossier_wizard_controller.dart';
import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/l10n/app_strings.dart';

/// Étape 4 : récapitulatif puis envoi réel (création, pièces, soumissions).
class StepValidation extends ConsumerWidget {
  final VoidCallback onSubmitted;
  final VoidCallback onBack;
  final Color primaryColor;

  const StepValidation({
    super.key,
    required this.onSubmitted,
    required this.onBack,
    required this.primaryColor,
  });

  Future<void> _envoyer(WidgetRef ref) async {
    final resultat = await ref
        .read(createDossierWizardProvider.notifier)
        .envoyer();
    if (resultat != null) onSubmitted();
  }

  String _etape(EnvoiDossierEtape etape) {
    switch (etape) {
      case EnvoiDossierEtape.creation:
        return tr('Création du dossier…');
      case EnvoiDossierEtape.piecesJointes:
        return tr('Envoi des pièces jointes…');
      case EnvoiDossierEtape.soumissions:
        return tr('Transmission aux avocats…');
      case EnvoiDossierEtape.inactif:
      case EnvoiDossierEtape.termine:
        return '';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createDossierWizardProvider);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              Text(
                tr('Récapitulatif'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: context.palette.textStrong,
                ),
              ),
              const SizedBox(height: 16),
              _Bloc(
                titre: tr('Informations du dossier'),
                children: [
                  _Ligne(
                    icone: Icons.description_outlined,
                    libelle: tr('Titre'),
                    valeur: state.titre,
                  ),
                  _Ligne(
                    icone: Icons.work_outline,
                    libelle: tr('Domaine'),
                    valeur: state.domaine?.nom ?? tr('Non précisé'),
                  ),
                  _Ligne(
                    icone: Icons.edit_outlined,
                    libelle: tr('Description'),
                    valeur: state.description,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _Bloc(
                titre: tr('Avocats destinataires ({n})', {
                  'n': state.selectedProfessionnels.length,
                }),
                children: state.selectedProfessionnels
                    .map(
                      (p) => _Ligne(
                        icone: Icons.gavel_rounded,
                        libelle: '',
                        valeur: p.displayName,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              _Bloc(
                titre: tr('Pièces jointes ({n})', {
                  'n': state.piecesJointes.length,
                }),
                children: state.piecesJointes.isEmpty
                    ? const [
                        _Ligne(
                          icone: Icons.attach_file_rounded,
                          libelle: '',
                          valeur: 'Aucune',
                        ),
                      ]
                    : state.piecesJointes
                          .map(
                            (p) => _Ligne(
                              icone: Icons.attach_file_rounded,
                              libelle: '',
                              valeur: p.nom,
                            ),
                          )
                          .toList(),
              ),
              const SizedBox(height: 16),
              Text(
                tr(
                  'Chaque avocat pourra accepter ou décliner votre dossier. Dès qu’un avocat '
                  'l’accepte, il lui est confié et vous pourrez prendre rendez-vous avec lui.',
                ),
                style: TextStyle(
                  fontSize: 13,
                  color: context.palette.textMuted,
                  height: 1.4,
                ),
              ),
              if (state.envoiEnCours) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _etape(state.etape),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ],
              if (state.erreur != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    state.erreur!,
                    style: const TextStyle(color: Color(0xFF991B1B)),
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
                    onPressed: state.envoiEnCours ? null : onBack,
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
                    isLoading: state.envoiEnCours,
                    onPressed: state.envoiEnCours ? null : () => _envoyer(ref),
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

class _Bloc extends StatelessWidget {
  final String titre;
  final List<Widget> children;
  const _Bloc({required this.titre, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.palette.muted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titre,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: context.palette.textStrong,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _Ligne extends StatelessWidget {
  final IconData icone;
  final String libelle;
  final String valeur;
  const _Ligne({
    required this.icone,
    required this.libelle,
    required this.valeur,
  });

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
            child: Text.rich(
              TextSpan(
                children: [
                  if (libelle.isNotEmpty)
                    TextSpan(
                      text: '${tr(libelle)} : ',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  TextSpan(text: valeur),
                ],
              ),
              style: TextStyle(
                fontSize: 14,
                color: context.palette.text,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
