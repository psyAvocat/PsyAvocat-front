import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/user_message.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/widgets.dart';
import '../controllers/auth_controller.dart';

/// Écran de réinitialisation de mot de passe (Mot de passe oublié).
/// Envoie un email de réinitialisation via Firebase Authentication.
///
/// Pas de maquette Figma dédiée : l'écran reprend les composants de la connexion.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(authControllerProvider.notifier)
        .sendPasswordResetEmail(email: _emailController.text);

    if (success && mounted) {
      setState(() => _emailSent = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

    ref.listen<AsyncValue<void>>(authControllerProvider, (_, next) {
      if (next.hasError && !next.isLoading) {
        AppNotification.showError(context, userMessageFor(next.error!));
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const AppCurvedHeader(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
              child: _emailSent
                  ? _buildSuccessContent()
                  : _buildForm(isLoading),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSpacing.vGap32,
          Text('Mot de passe oublié ?', style: AppTypography.titreMoyen),
          AppSpacing.vGap8,
          Text(
            'Entrez votre adresse email ci-dessous. Nous vous enverrons un lien '
            'sécurisé pour réinitialiser votre mot de passe.',
            style: AppTypography.texteSecondaire,
          ),
          AppSpacing.vGap24,
          AppTextField(
            controller: _emailController,
            label: 'Adresse email',
            hint: 'Ex: ramla@gmail.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: Validators.email,
            onFieldSubmitted: (_) => _submit(),
          ),
          AppSpacing.vGap32,
          AppGradientButton(
            label: 'Envoyer le lien',
            isLoading: isLoading,
            onPressed: _submit,
          ),
          AppSpacing.vGap16,
          Center(
            child: TextButton(
              onPressed: () => context.pop(),
              child: Text('Retour à la connexion', style: AppTypography.lien),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessContent() {
    return Column(
      children: [
        AppSpacing.vGap40,
        const Icon(
          Icons.mark_email_read_outlined,
          size: 64,
          color: AppColors.brandPurple,
        ),
        AppSpacing.vGap16,
        Text('Email envoyé !', style: AppTypography.titreMoyen),
        AppSpacing.vGap8,
        Text(
          'Un email contenant les instructions de réinitialisation a été envoyé à '
          '${_emailController.text}.',
          textAlign: TextAlign.center,
          style: AppTypography.texteSecondaire,
        ),
        AppSpacing.vGap32,
        AppGradientButton(
          label: 'Retour à la connexion',
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }
}
