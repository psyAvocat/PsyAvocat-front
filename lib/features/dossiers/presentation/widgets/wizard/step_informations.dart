import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../controllers/create_dossier_wizard_controller.dart';

class StepInformations extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  final Color primaryColor;

  const StepInformations({
    super.key,
    required this.onNext,
    required this.onBack,
    required this.primaryColor,
  });

  @override
  ConsumerState<StepInformations> createState() => _StepInformationsState();
}

class _StepInformationsState extends ConsumerState<StepInformations> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titreController;
  late TextEditingController _descController;
  late String _domaine;
  DateTime? _dateImportante;

  static const _domaines = [
    'Droit immobilier',
    'Droit de la famille',
    'Droit du travail',
    'Droit pénal',
    'Droit des affaires',
    'Autre',
  ];

  @override
  void initState() {
    super.initState();
    final state = ref.read(createDossierWizardProvider);
    _titreController = TextEditingController(text: state.titre);
    _descController = TextEditingController(text: state.description);
    _domaine = _domaines.contains(state.domaine)
        ? state.domaine
        : _domaines.first;
    _dateImportante = state.dateImportante;
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _saveAndNext() {
    if (!_formKey.currentState!.validate()) return;

    ref
        .read(createDossierWizardProvider.notifier)
        .updateInformations(
          titre: _titreController.text.trim(),
          domaine: _domaine,
          description: _descController.text.trim(),
          dateImportante: _dateImportante,
        );
    widget.onNext();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateImportante ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: widget.primaryColor),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() => _dateImportante = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                const Text(
                  'Informations du dossier',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Titre du dossier *',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titreController,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Champ requis' : null,
                  decoration: _inputDeco('Ex: Litige concernant un terrain'),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Domaine juridique *',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _domaine,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF111827),
                  ),
                  decoration: _inputDeco(''),
                  items: _domaines
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _domaine = v);
                  },
                ),
                const SizedBox(height: 20),

                const Text(
                  'Description du problème *',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descController,
                  maxLines: 5,
                  maxLength: 500,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Champ requis' : null,
                  decoration: _inputDeco('Décrivez votre situation...'),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Date ou délai important (optionnel)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          color: Color(0xFF6B7280),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _dateImportante != null
                              ? DateFormat(
                                  'dd/MM/yyyy',
                                ).format(_dateImportante!)
                              : 'Sélectionner une date',
                          style: TextStyle(
                            fontSize: 14,
                            color: _dateImportante != null
                                ? const Color(0xFF111827)
                                : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
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
            child: Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Retour',
                    onPressed: widget.onBack,
                    isOutlined: true,
                    textColor: const Color(0xFF111827),
                    color: const Color(0xFFE5E7EB),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    text: 'Suivant',
                    onPressed: _saveAndNext,
                    color: widget.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: widget.primaryColor),
      ),
    );
  }
}
