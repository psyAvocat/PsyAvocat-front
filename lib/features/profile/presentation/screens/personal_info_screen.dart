import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/errors/user_message.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_alert.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/models/profil_model.dart';
import '../controllers/profil_controller.dart';
import '../../../../core/l10n/app_strings.dart';

/// « Informations personnelles » : identité du compte, photo modifiable,
/// nom, prénom et téléphone modifiables. L'email (identifiant de connexion)
/// n'est pas modifiable ici.
class PersonalInfoScreen extends ConsumerStatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  ConsumerState<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends ConsumerState<PersonalInfoScreen> {
  bool _envoiPhoto = false;

  Future<void> _changerPhoto() async {
    final XFile? image;
    try {
      image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 85,
      );
    } catch (_) {
      if (mounted) {
        AppNotification.showError(
          context,
          tr('Impossible d’accéder à vos photos. Vérifiez les autorisations.'),
        );
      }
      return;
    }
    if (image == null) return;
    setState(() => _envoiPhoto = true);
    final error = await ref
        .read(currentProfilProvider.notifier)
        .updatePhoto(bytes: await image.readAsBytes(), fileName: image.name);
    if (!mounted) return;
    setState(() => _envoiPhoto = false);
    if (error != null) {
      AppNotification.showError(context, error);
    } else {
      AppNotification.showSuccess(context, tr('Photo de profil mise à jour'));
    }
  }

  void _modifier(ProfilModel profil, Color couleur) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfilSheet(profil: profil, primaryColor: couleur),
    );
  }

  @override
  Widget build(BuildContext context) {
    final universe = ref.watch(currentUniverseProvider);
    final couleur = Theme.of(context).colorScheme.primary;
    final profilAsync = ref.watch(currentProfilProvider);

    return Scaffold(
      backgroundColor: context.palette.card,
      appBar: AppPageHeader(title: tr('Informations personnelles')),
      body: profilAsync.when(
        loading: () => AppLoadingView(universe: universe),
        error: (e, _) => AppErrorStateView(
          title: tr('Profil indisponible'),
          message: userMessageFor(e),
          onRetry: () => ref.read(currentProfilProvider.notifier).refresh(),
        ),
        data: (profil) {
          if (profil == null) return const SizedBox.shrink();
          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
            children: [
              Center(
                child: Stack(
                  children: [
                    AppAvatar(
                      name: profil.nomComplet,
                      photoUrl: profil.photoUrl,
                      size: 104,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Material(
                        color: couleur,
                        shape: const CircleBorder(
                          side: BorderSide(color: Colors.white, width: 3),
                        ),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _envoiPhoto ? null : _changerPhoto,
                          child: SizedBox(
                            width: 36,
                            height: 36,
                            child: _envoiPhoto
                                ? const Padding(
                                    padding: EdgeInsets.all(9),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    Icons.photo_camera_outlined,
                                    size: 18,
                                    color: Colors.white,
                                    semanticLabel: tr('Changer la photo'),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.vGap24,
              _Ligne(label: tr('Prénom'), valeur: profil.prenom),
              _Ligne(label: tr('Nom'), valeur: profil.nom),
              _Ligne(label: tr('Email'), valeur: profil.email),
              _Ligne(
                label: tr('Téléphone'),
                valeur: profil.telephone ?? tr('Non renseigné'),
              ),
              if (profil.dateInscription != null)
                _Ligne(
                  label: tr('Membre depuis'),
                  valeur: Formatters.formatLongDate(profil.dateInscription),
                ),
              AppSpacing.vGap32,
              AppButton(
                text: tr('Modifier mes informations'),
                icon: Icons.edit_outlined,
                color: couleur,
                onPressed: () => _modifier(profil, couleur),
              ),
              AppSpacing.vGap12,
              Text(
                tr(
                  'L’adresse e-mail est votre identifiant de connexion : '
                  'elle ne peut pas être modifiée.',
                ),
                textAlign: TextAlign.center,
                style: AppTypography.miniTexte.copyWith(
                  color: context.palette.textMuted,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Ligne extends StatelessWidget {
  final String label;
  final String valeur;

  const _Ligne({required this.label, required this.valeur});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.palette.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: AppTypography.texteSecondaire),
          ),
          Expanded(
            child: Text(
              valeur.isEmpty ? '—' : valeur,
              textAlign: TextAlign.right,
              style: AppTypography.texteMedium.copyWith(
                color: context.palette.textStrong,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Formulaire de modification : nom, prénom, téléphone (mêmes règles que
/// l'inscription).
class _EditProfilSheet extends ConsumerStatefulWidget {
  final ProfilModel profil;
  final Color primaryColor;

  const _EditProfilSheet({required this.profil, required this.primaryColor});

  @override
  ConsumerState<_EditProfilSheet> createState() => _EditProfilSheetState();
}

class _EditProfilSheetState extends ConsumerState<_EditProfilSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _prenomController = TextEditingController(
    text: widget.profil.prenom,
  );
  late final _nomController = TextEditingController(text: widget.profil.nom);
  late final _telephoneController = TextEditingController(
    text: widget.profil.telephone ?? '',
  );
  bool _isLoading = false;

  @override
  void dispose() {
    _prenomController.dispose();
    _nomController.dispose();
    _telephoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final error = await ref
        .read(currentProfilProvider.notifier)
        .updateProfile(
          prenom: _prenomController.text.trim(),
          nom: _nomController.text.trim(),
          telephone: _telephoneController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isLoading = false);
    if (error != null) {
      AppNotification.showError(context, error);
      return;
    }
    Navigator.of(context).pop();
    AppNotification.showSuccess(context, tr('Informations mises à jour'));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.palette.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: context.palette.border,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                AppSpacing.vGap24,
                Text(
                  tr('Modifier mes informations'),
                  textAlign: TextAlign.center,
                  style: AppTypography.titreMoyen.copyWith(fontSize: 20),
                ),
                AppSpacing.vGap24,
                AppTextField(
                  controller: _prenomController,
                  label: tr('Prénom'),
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                  textInputAction: TextInputAction.next,
                  validator: (value) =>
                      Validators.required(value, tr('Votre prénom est requis')),
                ),
                AppSpacing.vGap16,
                AppTextField(
                  controller: _nomController,
                  label: tr('Nom'),
                  prefixIcon: const Icon(Icons.badge_outlined),
                  textInputAction: TextInputAction.next,
                  validator: (value) =>
                      Validators.required(value, tr('Votre nom est requis')),
                ),
                AppSpacing.vGap16,
                AppTextField(
                  controller: _telephoneController,
                  label: tr('Téléphone'),
                  prefixIcon: const Icon(Icons.phone_outlined),
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  validator: Validators.phone,
                ),
                AppSpacing.vGap32,
                AppButton(
                  text: tr('Enregistrer'),
                  color: widget.primaryColor,
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
