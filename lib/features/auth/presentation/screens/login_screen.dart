import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/user_message.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/widgets.dart';
import '../controllers/auth_controller.dart';
import '../controllers/session_controller.dart';
import '../widgets/bouton_google.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/l10n/app_strings.dart';

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

  /// Connexion (ou première inscription) avec un compte Google.
  Future<void> _connexionGoogle() =>
      ref.read(authControllerProvider.notifier).signInWithGoogle();

  @override
  Widget build(BuildContext context) {
    // Chargement : connexion Firebase, puis vérification du compte (GET /me).
    // L'écran de connexion reste affiché pendant ce temps (pas de splash).
    final isLoading =
        ref.watch(authControllerProvider).isLoading ||
        ref.watch(sessionControllerProvider).status == SessionStatus.loading;

    // Erreurs Firebase (identifiants incorrects, réseau…).
    ref.listen<AsyncValue<void>>(authControllerProvider, (_, next) {
      if (next.hasError && !next.isLoading) {
        AppNotification.showError(context, userMessageFor(next.error!));
      }
    });

    ref.listen<SessionState>(sessionControllerProvider, (previous, next) {
      // Déconnexion expliquée (inscription à refaire…) : message affiché ici.
      if (next.status == SessionStatus.unauthenticated &&
          next.message != null &&
          previous?.message != next.message) {
        AppNotification.showError(context, tr(next.message!));
      }
      // Serveur injoignable pendant la vérification du compte : message clair.
      if (next.status == SessionStatus.error &&
          previous?.status != SessionStatus.error) {
        AppNotification.showError(
          context,
          next.message ?? tr('Connexion au serveur impossible. Réessayez.'),
        );
      }
    });

    return Scaffold(
      backgroundColor: context.palette.card,
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // En-tête (motif et logo) proportionnel à la hauteur de l'écran ;
          // l'espace restant est réparti au-dessus et au-dessous du formulaire.
          // Espacements resserrés uniquement sur les très petits écrans.
          // Hauteur de l'écran SANS le clavier : à son ouverture, la page garde
          // sa mise en page et défile (le champ actif reste visible) au lieu de
          // se recalculer et de bouger.
          final hauteur = MediaQuery.sizeOf(context).height;
          final compact = hauteur < 700;
          final ecart = compact ? AppSpacing.vGap8 : AppSpacing.vGap16;
          // Motif plus grand dès qu'il y a la place (petits écrans : tout doit tenir).
          final hauteurEnTete = hauteur < 780
              ? (hauteur * 0.21).clamp(130.0, 200.0)
              : (hauteur * 0.25).clamp(195.0, 235.0);
          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: hauteur),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    AppCurvedHeader(
                      height: hauteurEnTete,
                      proportionLogo: 0.4,
                      taillePolice: 26,
                    ),
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
                              compact ? AppSpacing.vGap12 : AppSpacing.vGap16,
                              // Formulaire descendu : l'espace libre surtout au-dessus.
                              const Spacer(flex: 2),
                              Text(
                                tr('Connexion'),
                                style: compact
                                    ? AppTypography.titreMoyen
                                    : AppTypography.grandTitre,
                              ),
                              compact ? AppSpacing.vGap8 : AppSpacing.vGap16,
                              AppTextField(
                                controller: _emailController,
                                label: tr('Email'),
                                hint: tr('Ex: ramla@gmail.com'),
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                validator: Validators.email,
                              ),
                              ecart,
                              AppTextField(
                                controller: _passwordController,
                                label: tr('Mot de passe'),
                                hint: '••••••••',
                                obscureText: true,
                                textInputAction: TextInputAction.done,
                                validator: Validators.password,
                                onFieldSubmitted: (_) => _submit(),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: AppButton.ghost(
                                  text: tr('Mot de passe oublié ?'),
                                  color: context.colors.primary,
                                  size: AppButtonSize.compact,
                                  onPressed: () =>
                                      context.push(AppRoutes.forgotPassword),
                                ),
                              ),
                              AppSpacing.vGap8,
                              AppButton(
                                text: tr('Se connecter'),
                                color: AppColors.lawyer,
                                isLoading: isLoading,
                                onPressed: _submit,
                              ),
                              compact ? AppSpacing.vGap12 : AppSpacing.vGap20,
                              BoutonGoogle(
                                compact: compact,
                                onPressed: isLoading ? null : _connexionGoogle,
                              ),
                              const Spacer(),
                              compact ? AppSpacing.vGap8 : AppSpacing.vGap16,
                              AppInlineLink(
                                text: tr('Pas encore de compte ?'),
                                linkText: tr("S'inscrire"),
                                onTap: () => context.push(AppRoutes.register),
                              ),
                              compact ? AppSpacing.vGap12 : AppSpacing.vGap24,
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
