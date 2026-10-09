import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/user_message.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/widgets.dart';
import '../controllers/auth_controller.dart';
import '../controllers/session_controller.dart';
import '../../../../core/router/app_routes.dart';

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

    // Firebase uniquement : la suite (GET /me, rôle, univers) est décidée
    // par la session et le routeur, pas par cet écran.
    await ref
        .read(authControllerProvider.notifier)
        .signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

    // Erreurs Firebase (identifiants incorrects, réseau…).
    ref.listen<AsyncValue<void>>(authControllerProvider, (_, next) {
      if (next.hasError && !next.isLoading) {
        AppNotification.showError(context, userMessageFor(next.error!));
      }
    });

    // Succès confirmé seulement quand le backend a validé le compte (GET /me).
    ref.listen<SessionState>(sessionControllerProvider, (previous, next) {
      if (next.isAuthorized && previous?.isAuthorized != true) {
        AppNotification.showSuccess(context, 'Connexion réussie');
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
                                label: 'Email',
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
                                      context.push(AppRoutes.forgotPassword),
                                  child: Text(
                                    'Mot de passe oublié ?',
                                    style: AppTypography.lien,
                                  ),
                                ),
                              ),
                              AppSpacing.vGap8,
                              AppButton(
                                text: 'Se connecter',
                                color: AppColors.lawyer,
                                isLoading: isLoading,
                                onPressed: _submit,
                              ),
                              const Spacer(),
                              AppSpacing.vGap24,
                              AppInlineLink(
                                text: 'Pas encore de compte ?',
                                linkText: "S'inscrire",
                                onTap: () => context.push(AppRoutes.register),
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
