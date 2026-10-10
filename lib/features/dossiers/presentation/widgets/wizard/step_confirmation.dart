import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../controllers/create_dossier_wizard_controller.dart';

class StepConfirmationScreen extends ConsumerWidget {
  const StepConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createDossierWizardProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Success Icon
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_rounded,
                      size: 50,
                      color: Color(0xFF22C55E),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                'Votre dossier a été envoyé\navec succès !',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Votre dossier a été transmis aux professionnels sélectionnés. Vous pourrez consulter leurs réponses depuis votre espace.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              // Recap card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: Color(0xFF111827),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Récapitulatif',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildRow(
                      Icons.description_outlined,
                      'Titre',
                      state.titre.isEmpty ? 'Non spécifié' : state.titre,
                    ),
                    const SizedBox(height: 12),
                    _buildRow(
                      Icons.person_outline,
                      'Destinataires',
                      '${state.selectedProfessionnels.length} sélectionnés',
                    ),
                    const SizedBox(height: 12),
                    _buildRow(
                      Icons.attach_file,
                      'Pièces jointes',
                      '${state.piecesJointes.length} fichiers',
                    ),
                    const SizedBox(height: 12),
                    _buildRow(
                      Icons.calendar_today_outlined,
                      'Date d\'envoi',
                      DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now()),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              AppButton(
                text: 'Voir mes dossiers',
                onPressed: () {
                  ref.read(createDossierWizardProvider.notifier).clear();
                  Navigator.of(context).pop(); // Pops back to dossier screen
                },
                color: const Color(0xFF111827),
              ),
              const SizedBox(height: 12),
              AppButton(
                text: 'Retour à l\'accueil',
                onPressed: () {
                  ref.read(createDossierWizardProvider.notifier).clear();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                isOutlined: true,
                textColor: const Color(0xFF111827),
                color: const Color(0xFFE5E7EB),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6B7280)),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
        ),
        const Text(
          ': ',
          style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
