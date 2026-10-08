import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/user_message.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/widgets.dart';
import '../controllers/auth_controller.dart';

/// Inscription en 3 étapes (style de la maquette Figma « Inscription ») :
/// 1. Identité — 2. Coordonnées — 3. Mot de passe et conditions.
///
/// À la fin, le compte Firebase est créé ; le profil métier (patient ou
/// justiciable) est créé à l'étape suivante, lors du choix de l'univers.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  static const List<String> _stepTitles = [
    'Qui êtes-vous ?',
    'Comment vous joindre ?',
    'Sécurisez votre compte',
  ];

  /// Un formulaire par étape : on ne valide que les champs affichés.
  final List<GlobalKey<FormState>> _formKeys = List.generate(
    _stepTitles.length,
    (_) => GlobalKey<FormState>(),
  );

  final _prenomController = TextEditingController();
  final _nomController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _currentStep = 0;
  bool _hasAcceptedTerms = false;

  bool get _isLastStep => _currentStep == _stepTitles.length - 1;

  @override
  void dispose() {
    _prenomController.dispose();
    _nomController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateConfirmation(String? value) {
    if (value != _passwordController.text) {
      return 'Les mots de passe ne correspondent pas';
    }
    return null;
  }

  void _goBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/login');
    }
  }

  Future<void> _onContinuePressed() async {
    if (!_formKeys[_currentStep].currentState!.validate()) return;

    if (!_isLastStep) {
      setState(() => _currentStep++);
      return;
    }

    final phone = _phoneController.text.trim();
    final isSuccess = await ref
        .read(authControllerProvider.notifier)
        .register(
          prenom: _prenomController.text.trim(),
          nom: _nomController.text.trim(),
          telephone: phone.isEmpty ? null : phone,
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
    if (isSuccess && mounted) {
      AppNotification.showSuccess(
        context,
        'Inscription réussie ! Vous pouvez maintenant vous connecter.',
      );
      context.go('/login');
    }
  }

  void _signUpWithGoogle() {
    AppNotification.showInfo(
      context,
      'Inscription Google disponible dans une prochaine version.',
    );
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton.outlined(
                onPressed: _goBack,
                tooltip: 'Retour',
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              AppSpacing.vGap24,
              Text('Créer un compte', style: AppTypography.grandTitre),
              AppSpacing.vGap16,
              AppStepProgress(
                currentStep: _currentStep + 1,
                totalSteps: _stepTitles.length,
              ),
              AppSpacing.vGap24,
              Text(_stepTitles[_currentStep], style: AppTypography.petitTitre),
              AppSpacing.vGap20,
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: KeyedSubtree(
                  key: ValueKey(_currentStep),
                  child: Form(
                    key: _formKeys[_currentStep],
                    child: _buildStepFields(),
                  ),
                ),
              ),
              AppSpacing.vGap32,
              AppGradientButton(
                label: _isLastStep ? "S'inscrire" : 'Continuer',
                isLoading: isLoading,
                // Dernière étape : bouton actif seulement si les CGU sont acceptées.
                onPressed: (_isLastStep && !_hasAcceptedTerms)
                    ? null
                    : _onContinuePressed,
              ),
              AppSpacing.vGap16,
              const AppTextDivider(label: 'CONTINUE AVEC'),
              AppSpacing.vGap8,
              Center(child: GoogleSignInButton(onPressed: _signUpWithGoogle)),
              AppSpacing.vGap16,
              AppInlineLink(
                text: 'Vous avez un compte ?',
                linkText: 'Connexion',
                onTap: () => context.go('/login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepFields() {
    switch (_currentStep) {
      case 0:
        return Column(
          children: [
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
              textInputAction: TextInputAction.done,
              validator: (value) =>
                  Validators.required(value, 'Votre nom est requis'),
              onFieldSubmitted: (_) => _onContinuePressed(),
            ),
          ],
        );
      case 1:
        return Column(
          children: [
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
              controller: _phoneController,
              label: 'Téléphone (facultatif)',
              hint: 'Ex: +221 77 123 45 67',
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              validator: Validators.phone,
              onFieldSubmitted: (_) => _onContinuePressed(),
            ),
          ],
        );
      default:
        return Column(
          children: [
            AppTextField(
              controller: _passwordController,
              label: 'Mot de passe',
              hint: '••••••••',
              helperText: 'Au moins 6 caractères',
              obscureText: true,
              textInputAction: TextInputAction.next,
              validator: Validators.password,
            ),
            AppSpacing.vGap20,
            AppTextField(
              controller: _confirmPasswordController,
              label: 'Confirmer le mot de passe',
              hint: '••••••••',
              obscureText: true,
              textInputAction: TextInputAction.done,
              validator: _validateConfirmation,
            ),
            AppSpacing.vGap16,
            AppCheckboxTile(
              value: _hasAcceptedTerms,
              onChanged: (value) => setState(() => _hasAcceptedTerms = value),
              label: const _TermsText(),
            ),
          ],
        );
    }
  }
}

/// « J'accepte les conditions d'utilisation et la politique de confidentialité »
/// avec les deux documents mis en couleur.
class _TermsText extends StatelessWidget {
  const _TermsText();

  @override
  Widget build(BuildContext context) {
    final highlighted = AppTypography.lien.copyWith(
      color: Theme.of(context).colorScheme.primary,
    );

    return Text.rich(
      TextSpan(
        style: AppTypography.texteSecondaire.copyWith(
          color: AppColors.formHint,
        ),
        children: [
          const TextSpan(text: "J'accepte les "),
          TextSpan(text: "conditions d'utilisation", style: highlighted),
          const TextSpan(text: ' et la '),
          TextSpan(text: 'politique de confidentialité', style: highlighted),
        ],
      ),
    );
  }
}
