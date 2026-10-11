import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/errors/user_message.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../referentiels/data/models/specialite_option.dart';
import '../../../../referentiels/presentation/controllers/specialites_provider.dart';
import '../../controllers/create_dossier_wizard_controller.dart';

/// Étape 2 : titre, domaine juridique (référentiel réel des spécialités Avocat)
/// et description du dossier.
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
  SpecialiteOption? _domaine;

  @override
  void initState() {
    super.initState();
    final state = ref.read(createDossierWizardProvider);
    _titreController = TextEditingController(text: state.titre);
    _descController = TextEditingController(text: state.description);
    _domaine = state.domaine;
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
        );
    FocusScope.of(context).unfocus();
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final domainesAsync = ref.watch(specialitesOfUniverseProvider);

    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                const _Libelle('Titre du dossier *'),
                TextFormField(
                  controller: _titreController,
                  maxLength: 150,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                  decoration: _inputDeco('Ex : Litige concernant un terrain'),
                ),
                const SizedBox(height: 12),
                const _Libelle('Domaine juridique (facultatif)'),
                domainesAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Row(
                    children: [
                      Expanded(
                        child: Text(
                          userMessageFor(e),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ),
                      AppButton.ghost(
                        text: 'Réessayer',
                        onPressed: () =>
                            ref.invalidate(specialitesOfUniverseProvider),
                      ),
                    ],
                  ),
                  data: (domaines) {
                    final selection = _domaine != null
                        ? domaines
                              .where((d) => d.id == _domaine!.id)
                              .firstOrNull
                        : null;
                    return DropdownButtonFormField<SpecialiteOption?>(
                      initialValue: selection,
                      isExpanded: true,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF111827),
                      ),
                      decoration: _inputDeco('Sélectionner un domaine'),
                      items: [
                        const DropdownMenuItem<SpecialiteOption?>(
                          value: null,
                          child: Text('Je ne sais pas'),
                        ),
                        ...domaines.map(
                          (d) => DropdownMenuItem<SpecialiteOption?>(
                            value: d,
                            child: Text(d.nom, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _domaine = v),
                    );
                  },
                ),
                const SizedBox(height: 20),
                const _Libelle('Description de la situation *'),
                TextFormField(
                  controller: _descController,
                  maxLines: 6,
                  maxLength: 2000,
                  validator: (v) => (v == null || v.trim().length < 20)
                      ? 'Décrivez votre situation (20 caractères minimum)'
                      : null,
                  decoration: _inputDeco(
                    'Décrivez les faits, les parties concernées et votre demande…',
                  ),
                ),
                const SizedBox(height: 24),
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
            child: SafeArea(
              top: false,
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

class _Libelle extends StatelessWidget {
  final String texte;
  const _Libelle(this.texte);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        texte,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F2937),
        ),
      ),
    );
  }
}
