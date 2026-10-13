import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../controllers/create_dossier_wizard_controller.dart';
import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/l10n/app_strings.dart';

/// Résultat de l'envoi : n'affiche que ce que le backend a réellement enregistré,
/// avec le détail d'éventuels échecs partiels.
class StepConfirmationScreen extends ConsumerWidget {
  final Color primaryColor;

  const StepConfirmationScreen({super.key, required this.primaryColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createDossierWizardProvider);
    final resultat = state.resultat;
    final complet = resultat?.complet ?? false;

    void terminer() {
      ref.read(createDossierWizardProvider.notifier).clear();
      Navigator.of(context).pop();
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) terminer();
      },
      child: Scaffold(
        backgroundColor: context.palette.card,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 24),
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: complet
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFF7ED),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    complet ? Icons.check_rounded : Icons.warning_amber_rounded,
                    size: 50,
                    color: complet
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFEA580C),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                complet
                    ? tr('Votre dossier a été envoyé')
                    : tr('Dossier créé, envoi incomplet'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: context.palette.textStrong,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                complet
                    ? tr(
                        'Les avocats sélectionnés ont été notifiés. Vous serez prévenu dès qu’un avocat '
                        'accepte votre dossier ; vous pourrez alors prendre rendez-vous depuis « Mes dossiers ».',
                      )
                    : tr(
                        'Votre dossier « {titre} » est enregistré, mais certains éléments '
                        'n’ont pas pu être transmis. Vous pouvez réessayer depuis « Mes dossiers ».',
                        {'titre': resultat?.dossier.titre ?? ''},
                      ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: context.palette.text,
                  height: 1.5,
                ),
              ),
              if (resultat != null && resultat.avocatsEnEchec.isNotEmpty) ...[
                const SizedBox(height: 20),
                _Liste(
                  titre: tr('Non transmis à'),
                  elements: resultat.avocatsEnEchec,
                ),
              ],
              if (resultat != null && resultat.piecesEnEchec.isNotEmpty) ...[
                const SizedBox(height: 12),
                _Liste(
                  titre: tr('Pièces non enregistrées'),
                  elements: resultat.piecesEnEchec,
                ),
              ],
              const SizedBox(height: 32),
              AppButton(
                text: tr('Voir mes dossiers'),
                onPressed: terminer,
                color: primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Liste extends StatelessWidget {
  final String titre;
  final List<String> elements;
  const _Liste({required this.titre, required this.elements});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titre,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF7C2D12),
            ),
          ),
          const SizedBox(height: 6),
          ...elements.map(
            (e) =>
                Text('• $e', style: const TextStyle(color: Color(0xFF7C2D12))),
          ),
        ],
      ),
    );
  }
}
