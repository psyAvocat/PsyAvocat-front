import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/errors/user_message.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../referentiels/data/models/specialite_option.dart';
import '../../../../referentiels/presentation/controllers/specialites_provider.dart';
import '../../controllers/create_dossier_wizard_controller.dart';
import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/l10n/app_strings.dart';

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

  /// Champs dont l'erreur est affichée : elle disparaît dès que l'utilisateur
  /// recommence à écrire, et revient au prochain « Suivant » si besoin.
  final _titreKey = GlobalKey<FormFieldState<String>>();
  final _descKey = GlobalKey<FormFieldState<String>>();
  bool _erreurTitre = false;
  bool _erreurDesc = false;

  String? _validerTitre(String? v) =>
      _erreurTitre && (v == null || v.trim().isEmpty)
      ? tr('Champ requis')
      : null;

  String? _validerDesc(String? v) =>
      _erreurDesc && (v == null || v.trim().length < 20)
      ? tr('Décrivez votre situation (20 caractères minimum)')
      : null;

  /// Saisie dans un champ en erreur : l'erreur (bordure rouge) est retirée.
  void _effacerErreur(GlobalKey<FormFieldState<String>> key, VoidCallback off) {
    if (key.currentState?.hasError ?? false) {
      off();
      key.currentState!.validate();
    }
  }

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
    _erreurTitre = true;
    _erreurDesc = true;
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
                Text(
                  tr('Informations du dossier'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: context.palette.textStrong,
                  ),
                ),
                const SizedBox(height: 24),
                _Libelle(tr('Titre du dossier *')),
                TextFormField(
                  key: _titreKey,
                  controller: _titreController,
                  maxLength: 150,
                  validator: _validerTitre,
                  onChanged: (_) =>
                      _effacerErreur(_titreKey, () => _erreurTitre = false),
                  decoration: _inputDeco(
                    tr('Ex : Litige concernant un terrain'),
                  ),
                ),
                const SizedBox(height: 12),
                _Libelle(tr('Domaine juridique (facultatif)')),
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
                        text: tr('Réessayer'),
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
                      // Même taille que les autres champs du formulaire.
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: context.palette.textStrong,
                      ),
                      decoration: _inputDeco(tr('Sélectionner un domaine')),
                      items: [
                        DropdownMenuItem<SpecialiteOption?>(
                          value: null,
                          child: Text(tr('Je ne sais pas')),
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
                _Libelle(tr('Description de la situation *')),
                TextFormField(
                  key: _descKey,
                  controller: _descController,
                  maxLines: 6,
                  maxLength: 2000,
                  validator: _validerDesc,
                  onChanged: (_) =>
                      _effacerErreur(_descKey, () => _erreurDesc = false),
                  decoration: _inputDeco(
                    tr(
                      'Décrivez les faits, les parties concernées et votre demande…',
                    ),
                  ),
                ),
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
                      onPressed: widget.onBack,
                      isOutlined: true,
                      textColor: context.palette.textStrong,
                      color: context.palette.border,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      text: tr('Suivant'),
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
      hintStyle: TextStyle(color: context.palette.textSubtle, fontSize: 14),
      filled: true,
      fillColor: context.palette.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: context.palette.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: context.palette.border),
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
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: context.palette.textStrong,
        ),
      ),
    );
  }
}
