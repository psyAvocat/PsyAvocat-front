import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/user_message.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/widgets.dart';
import '../controllers/auth_controller.dart';
import '../../../../core/router/app_routes.dart';

/// Inscription en 3 étapes (style de la maquette Figma « Inscription ») :
/// 1. Identité — 2. Coordonnées — 3. Mot de passe et conditions.
///
/// À la fin : compte Firebase + profil client unique (valable dans les deux
/// univers), connecté immédiatement, puis choix de l'univers.
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
      context.go(AppRoutes.login);
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
          telephone: phone,
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
    if (!mounted) return;
    // Compte créé : il est connecté immédiatement. Le routeur ouvre ensuite le
    // choix de l'univers (ou « Compléter mon profil » si le serveur n'a pas
    // confirmé la création du profil).
    if (isSuccess) {
      AppNotification.showSuccess(context, 'Bienvenue sur PsyAvocat !');
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
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                const AppCurvedHeader(height: 210),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.s8),
                    child: IconButton(
                      onPressed: isLoading ? null : _goBack,
                      tooltip: 'Retour',
                      color: AppColors.textOnColor,
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s24,
                AppSpacing.s8,
                AppSpacing.s24,
                AppSpacing.s32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Créer un compte', style: AppTypography.grandTitre),
                  AppSpacing.vGap8,
                  Text(
                    'Rejoignez PsyAvocat en quelques secondes.',
                    style: AppTypography.texteSecondaire,
                  ),
                  AppSpacing.vGap24,
                  _StepIndicator(
                    labels: const ['Identité', 'Contact', 'Sécurité'],
                    current: _currentStep,
                  ),
                  AppSpacing.vGap24,
                  Text(
                    _stepTitles[_currentStep],
                    style: AppTypography.petitTitre,
                  ),
                  AppSpacing.vGap16,
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    switchInCurve: Curves.easeOutCubic,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.06, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(_currentStep),
                      child: Form(
                        key: _formKeys[_currentStep],
                        child: _buildStepFields(),
                      ),
                    ),
                  ),
                  AppSpacing.vGap32,
                  AppButton(
                    text: _isLastStep ? 'Créer mon compte' : 'Continuer',
                    color: AppColors.lawyer,
                    isLoading: isLoading,
                    // Dernière étape : bouton actif seulement si les CGU sont acceptées.
                    onPressed: (_isLastStep && !_hasAcceptedTerms)
                        ? null
                        : _onContinuePressed,
                  ),
                  AppSpacing.vGap24,
                  Center(
                    child: AppInlineLink(
                      text: 'Vous avez déjà un compte ?',
                      linkText: 'Se connecter',
                      onTap: () => context.go(AppRoutes.login),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
              prefixIcon: const Icon(Icons.person_outline_rounded),
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
              prefixIcon: const Icon(Icons.badge_outlined),
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
              prefixIcon: const Icon(Icons.alternate_email_rounded),
              hint: 'Ex: ramla@gmail.com',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: Validators.email,
            ),
            AppSpacing.vGap20,
            AppTextField(
              controller: _phoneController,
              label: 'Téléphone',
              prefixIcon: const Icon(Icons.phone_outlined),
              hint: 'Ex: +223 76 12 34 56',
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
              prefixIcon: const Icon(Icons.lock_outline_rounded),
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
              prefixIcon: const Icon(Icons.lock_reset_rounded),
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

/// Étapes nommées de l'inscription : pastille numérotée, coche une fois franchie.
class _StepIndicator extends StatelessWidget {
  final List<String> labels;
  final int current;

  const _StepIndicator({required this.labels, required this.current});

  @override
  Widget build(BuildContext context) {
    const actif = AppColors.lawyer;
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0)
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                height: 2,
                margin: const EdgeInsets.only(bottom: 20),
                color: i <= current ? actif : AppColors.border,
              ),
            ),
          Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i <= current ? actif : Colors.white,
                  border: Border.all(
                    color: i <= current ? actif : AppColors.border,
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: i < current
                    ? const Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: Colors.white,
                      )
                    : Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: i == current
                              ? Colors.white
                              : AppColors.textTertiary,
                        ),
                      ),
              ),
              const SizedBox(height: 6),
              Text(
                labels[i],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: i == current ? FontWeight.w700 : FontWeight.w500,
                  color: i <= current ? actif : AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
