import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../controllers/create_dossier_wizard_controller.dart';
import '../../controllers/dossiers_controller.dart';

class StepValidation extends ConsumerStatefulWidget {
  final VoidCallback onSubmit;
  final Color primaryColor;

  const StepValidation({
    super.key,
    required this.onSubmit,
    required this.primaryColor,
  });

  @override
  ConsumerState<StepValidation> createState() => _StepValidationState();
}

class _StepValidationState extends ConsumerState<StepValidation> {
  bool _isSubmitting = false;

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    final state = ref.read(createDossierWizardProvider);

    final ok = await ref
        .read(dossiersListProvider.notifier)
        .createDossier(
          titre: state.titre,
          description: state.description,
          domaine: state.domaine,
        );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (ok) {
        widget.onSubmit();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la création du dossier'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createDossierWizardProvider);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              const Text(
                'Récapitulatif',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 16),

              // Informations du dossier
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informations du dossier',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildRow(
                      Icons.description_outlined,
                      'Titre :',
                      state.titre,
                    ),
                    const SizedBox(height: 12),
                    _buildRow(Icons.work_outline, 'Domaine :', state.domaine),
                    const SizedBox(height: 12),
                    _buildRow(
                      Icons.edit_outlined,
                      'Description :',
                      state.description,
                    ),
                    const SizedBox(height: 12),
                    _buildRow(
                      Icons.calendar_today_outlined,
                      'Date importante :',
                      state.dateImportante != null
                          ? DateFormat(
                              'dd/MM/yyyy',
                            ).format(state.dateImportante!)
                          : 'Non spécifiée',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Avocats sélectionnés
              Text(
                'Avocats sélectionnés (${state.selectedProfessionnels.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: state.selectedProfessionnels.map((p) {
                    return Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: widget.primaryColor.withValues(
                              alpha: 0.1,
                            ),
                            backgroundImage: p.photoUrl != null
                                ? NetworkImage(p.photoUrl!)
                                : null,
                            child: p.photoUrl == null
                                ? Text(
                                    p.fullName.isNotEmpty
                                        ? p.fullName[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      color: widget.primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.displayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                Text(
                                  p.specialites.isNotEmpty
                                      ? p.specialites.first
                                      : 'Généraliste',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // Pièces jointes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.attach_file,
                        size: 18,
                        color: Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Pièces jointes (${state.piecesJointes.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    'Voir les détails',
                    style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: state.piecesJointes.map((p) {
                  final isPdf = p.endsWith('.pdf');
                  return Container(
                    width: (MediaQuery.of(context).size.width - 40 - 24) / 3,
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isPdf
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF3B82F6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.insert_drive_file,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          p,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 9,
                            color: Color(0xFF111827),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color(0x0A000000),
                offset: Offset(0, -4),
                blurRadius: 10,
              ),
            ],
          ),
          child: AppButton(
            text: 'Envoyer le dossier',
            onPressed: _submit,
            isLoading: _isSubmitting,
            color: const Color(
              0xFF0C2659,
            ), // It's very dark blue in the mockup, matching lawyer color usually
          ),
        ),
      ],
    );
  }

  Widget _buildRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF4B5563)),
        const SizedBox(width: 8),
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
          ),
        ),
      ],
    );
  }
}
