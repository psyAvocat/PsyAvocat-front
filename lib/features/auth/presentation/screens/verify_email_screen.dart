import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/user_message.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/widgets/widgets.dart';
import '../controllers/session_controller.dart';

/// « Confirmez votre adresse email » : le backend refuse tout accès client
/// tant que l'adresse n'est pas confirmée (lien envoyé à l'inscription).
///
/// Après le clic sur le lien, « J'ai confirmé mon adresse » renouvelle le jeton
/// Firebase et réévalue l'accès ; le routeur navigue ensuite.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _isChecking = false;
  bool _isSending = false;

  Future<void> _confirm() async {
    setState(() => _isChecking = true);
    final session = ref.read(sessionControllerProvider.notifier);
    try {
      await session.confirmEmailVerified();
      if (mounted &&
          ref.read(sessionControllerProvider).status ==
              SessionStatus.emailNotVerified) {
        AppNotification.showWarning(
          context,
          'Adresse pas encore confirmée. Ouvrez le lien reçu par email, puis réessayez.',
        );
      }
    } catch (error) {
      if (mounted) AppNotification.showError(context, userMessageFor(error));
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _isSending = true);
    try {
      await ref
          .read(sessionControllerProvider.notifier)
          .resendVerificationEmail();
      if (mounted) {
        AppNotification.showSuccess(context, 'Email de confirmation renvoyé.');
      }
    } catch (error) {
      if (mounted) AppNotification.showError(context, userMessageFor(error));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(sessionControllerProvider).user?.email ?? '';
    final busy = _isChecking || _isSending;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.screenPadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 64,
                  color: AppColors.brandPurple,
                ),
                AppSpacing.vGap16,
                Text(
                  'Confirmez votre adresse email',
                  textAlign: TextAlign.center,
                  style: AppTypography.titreMoyen,
                ),
                AppSpacing.vGap8,
                Text(
                  'Un lien de confirmation a été envoyé à $email. '
                  'Ouvrez-le pour activer votre compte.',
                  textAlign: TextAlign.center,
                  style: AppTypography.texteSecondaire,
                ),
                AppSpacing.vGap32,
                AppGradientButton(
                  label: "J'ai confirmé mon adresse",
                  isLoading: _isChecking,
                  onPressed: busy ? null : _confirm,
                ),
                AppSpacing.vGap16,
                TextButton(
                  onPressed: busy ? null : _resend,
                  child: Text(
                    "Renvoyer l'email de confirmation",
                    style: AppTypography.lien,
                  ),
                ),
                TextButton(
                  onPressed: busy
                      ? null
                      : () => ref
                            .read(sessionControllerProvider.notifier)
                            .signOut(),
                  child: Text('Se déconnecter', style: AppTypography.lien),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
