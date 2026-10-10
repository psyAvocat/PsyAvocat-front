import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/user_message.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../profile/data/repositories/profil_repository.dart';
import '../controllers/session_controller.dart';

/// « Compléter mon profil » : compte Firebase sans profil client dans le
/// backend (inscription interrompue avant la création du profil).
///
/// Une fois le profil créé, l'accès est réévalué via `GET /me` : c'est le
/// routeur qui navigue ensuite, à partir de l'état de session.
class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _prenomController;
  late final TextEditingController _nomController;
  late final TextEditingController _phoneController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(sessionControllerProvider).user;
    _prenomController = TextEditingController(text: user?.prenom ?? '');
    _nomController = TextEditingController(text: user?.nom ?? '');
    _phoneController = TextEditingController(text: user?.telephone ?? '');
  }

  @override
  void dispose() {
    _prenomController.dispose();
    _nomController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref
          .read(profilRepositoryProvider)
          .createClientProfile(
            nom: _nomController.text.trim(),
            prenom: _prenomController.text.trim(),
            telephone: _phoneController.text.trim(),
          );
      await ref
          .read(sessionControllerProvider.notifier)
          .refreshAfterProfileCreation();
    } catch (error) {
      if (mounted) AppNotification.showError(context, userMessageFor(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(sessionControllerProvider).user?.email ?? '';

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSpacing.vGap24,
                Text('Compléter mon profil', style: AppTypography.grandTitre),
                AppSpacing.vGap8,
                Text(
                  'Votre compte $email existe, mais votre profil n’a pas été '
                  'finalisé. Renseignez ces informations pour continuer.',
                  style: AppTypography.texteSecondaire,
                ),
                AppSpacing.vGap24,
                AppTextField(
                  controller: _prenomController,
                  label: 'Prénom',
                  hint: 'Ex: Ramla',
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  validator: (value) =>
                      Validators.required(value, 'Votre prénom est requis'),
                ),
                AppSpacing.vGap20,
                AppTextField(
                  controller: _nomController,
                  label: 'Nom',
                  hint: 'Ex: Diarra',
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  validator: (value) =>
                      Validators.required(value, 'Votre nom est requis'),
                ),
                AppSpacing.vGap20,
                AppTextField(
                  controller: _phoneController,
                  label: 'Téléphone',
                  hint: 'Ex: +223 76 12 34 56',
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  validator: Validators.phone,
                  onFieldSubmitted: (_) => _submit(),
                ),
                AppSpacing.vGap32,
                AppGradientButton(
                  label: 'Enregistrer mon profil',
                  isLoading: _isLoading,
                  onPressed: _submit,
                ),
                AppSpacing.vGap16,
                Center(
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => ref
                              .read(sessionControllerProvider.notifier)
                              .signOut(),
                    child: Text('Se déconnecter', style: AppTypography.lien),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
