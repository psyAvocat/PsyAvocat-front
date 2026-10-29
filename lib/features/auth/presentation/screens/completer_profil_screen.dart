import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/user_message.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/widgets.dart';
import '../controllers/auth_controller.dart';
import '../controllers/session_controller.dart';

/// Dernière étape d'une première connexion Google (ou d'une inscription
/// commencée sur un autre appareil) : le compte est connecté mais n'a pas
/// encore de profil PsyAvocat. Prénom et nom sont pré-remplis avec ceux de
/// Google ; le téléphone, que Google ne fournit pas, est demandé.
class CompleterProfilScreen extends ConsumerStatefulWidget {
  const CompleterProfilScreen({super.key});

  @override
  ConsumerState<CompleterProfilScreen> createState() =>
      _CompleterProfilScreenState();
}

class _CompleterProfilScreenState extends ConsumerState<CompleterProfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _prenomController = TextEditingController();
  final _nomController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // « Awa Traoré » → prénom « Awa », nom « Traoré ».
    final parties = (ref.read(authRepositoryProvider).displayName ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parties.isNotEmpty) {
      _prenomController.text = parties.first;
      _nomController.text = parties.skip(1).join(' ');
    }
  }

  @override
  void dispose() {
    _prenomController.dispose();
    _nomController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _valider() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authControllerProvider.notifier)
        .completerProfil(
          prenom: _prenomController.text.trim(),
          nom: _nomController.text.trim(),
          telephone: _phoneController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final enCours =
        ref.watch(authControllerProvider).isLoading ||
        ref.watch(sessionControllerProvider).status == SessionStatus.loading;

    // Téléphone déjà utilisé, serveur injoignable… : message clair.
    ref.listen<AsyncValue<void>>(authControllerProvider, (_, next) {
      if (next.hasError && !next.isLoading) {
        AppNotification.showError(context, userMessageFor(next.error!));
      }
    });

    return Scaffold(
      backgroundColor: context.palette.card,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s24,
            AppSpacing.s32,
            AppSpacing.s24,
            AppSpacing.s24,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('Finalisez votre profil'),
                  style: AppTypography.grandTitre,
                ),
                AppSpacing.vGap8,
                Text(
                  tr(
                    'Plus qu’une étape : vérifiez votre nom et indiquez votre numéro de téléphone, '
                    'pour que les professionnels puissent vous joindre.',
                  ),
                  style: AppTypography.texteSecondaire,
                ),
                AppSpacing.vGap32,
                AppTextField(
                  controller: _prenomController,
                  label: tr('Prénom'),
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  validator: (value) =>
                      Validators.required(value, tr('Votre prénom est requis')),
                ),
                AppSpacing.vGap20,
                AppTextField(
                  controller: _nomController,
                  label: tr('Nom'),
                  prefixIcon: const Icon(Icons.badge_outlined),
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  validator: (value) =>
                      Validators.required(value, tr('Votre nom est requis')),
                ),
                AppSpacing.vGap20,
                AppTextField(
                  controller: _phoneController,
                  label: tr('Téléphone'),
                  prefixIcon: const Icon(Icons.phone_outlined),
                  hint: tr('Ex: +223 76 12 34 56'),
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  validator: Validators.phone,
                  onFieldSubmitted: (_) => _valider(),
                ),
                AppSpacing.vGap32,
                AppButton(
                  text: tr('Continuer'),
                  color: AppColors.lawyer,
                  isLoading: enCours,
                  onPressed: _valider,
                ),
                AppSpacing.vGap12,
                Center(
                  child: AppButton.ghost(
                    text: tr('Utiliser un autre compte'),
                    onPressed: enCours
                        ? null
                        : () => ref
                              .read(sessionControllerProvider.notifier)
                              .signOut(),
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
