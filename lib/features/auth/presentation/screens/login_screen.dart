import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/user_message.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/widgets.dart';
import '../controllers/auth_controller.dart';

/// Écran de connexion — interface fixe, stable et réactive.
///
/// Parcours : Firebase Authentication → ID Token → `GET /me` → rôle réel → page suivante.
/// La disposition est rigoureusement ancrée (pas de décalage parasite ni flottement).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final isSuccess = await ref
        .read(authControllerProvider.notifier)
        .signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (isSuccess && mounted) {
      AppNotification.showSuccess(context, 'Connexion réussie !');
      // GoRouter automatically redirects to /home based on authStateChanges
    }
  }

  void _signInWithGoogle() {
    AppNotification.showInfo(
      context,
      'Connexion Google disponible dans une prochaine version.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

    // Erreurs Firebase (identifiants…) ou API (/me injoignable, compte pro…).
    ref.listen<AsyncValue<void>>(authControllerProvider, (_, next) {
      if (next.hasError && !next.isLoading) {
        AppNotification.showError(context, userMessageFor(next.error!));
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const AppCurvedHeader(),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s20,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppSpacing.vGap24,
                              Text(
                                'Connexion',
                                style: AppTypography.grandTitre,
                              ),
                              AppSpacing.vGap16,
                              AppTextField(
                                controller: _emailController,
                                label: 'Email ou numéro de téléphone',
                                hint: 'Ex: ramla@gmail.com',
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                validator: Validators.email,
                              ),
                              AppSpacing.vGap20,
                              AppTextField(
                                controller: _passwordController,
                                label: 'Mot de passe',
                                hint: '••••••••',
                                obscureText: true,
                                textInputAction: TextInputAction.done,
                                validator: Validators.password,
                                onFieldSubmitted: (_) => _submit(),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () =>
                                      context.push('/forgot-password'),
                                  child: Text(
                                    'Mot de passe oublié ?',
                                    style: AppTypography.lien,
                                  ),
                                ),
                              ),
                              AppSpacing.vGap8,
                              AppGradientButton(
                                label: 'Se connecter',
                                isLoading: isLoading,
                                onPressed: _submit,
                              ),
                              AppSpacing.vGap20,
                              const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppSpacing.s24,
                                ),
                                child: AppTextDivider(),
                              ),
                              AppSpacing.vGap16,
                              Center(
                                child: GoogleSignInButton(
                                  onPressed: _signInWithGoogle,
                                ),
                              ),
                              const Spacer(),
                              AppSpacing.vGap24,
                              AppInlineLink(
                                text: 'Pas encore de compte ?',
                                linkText: "S'inscrire",
                                onTap: () => context.push('/register'),
                              ),
                              AppSpacing.vGap24,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
