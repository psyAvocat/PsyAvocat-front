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
import '../../../../core/l10n/app_strings.dart';

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
      return tr('Les mots de passe ne correspondent pas');
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
    // choix de l'univers. Si la vérification du compte a échoué, l'erreur est
    // affichée par l'écoute de la session ci-dessous.
    if (isSuccess &&
        ref.read(sessionControllerProvider).status != SessionStatus.error) {
      AppNotification.showSuccess(context, tr('Bienvenue sur PsyAvocat !'));
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

    // Compte créé mais serveur injoignable pendant la vérification (GET /me) :
    // le compte reste connecté, la connexion relancera la vérification.
    ref.listen<SessionState>(sessionControllerProvider, (previous, next) {
      if (next.status == SessionStatus.error &&
          previous?.status != SessionStatus.error) {
        AppNotification.showError(
          context,
          next.message ?? tr('Connexion au serveur impossible. Réessayez.'),
        );
      }
    });

    // Page fixe : tout tient dans la hauteur de l'écran, les espaces flexibles
    // (Spacer) absorbent la place restante. Le défilement n'existe que lorsque
    // le clavier réduit la hauteur disponible, pour garder le champ actif visible.
    return Scaffold(
      backgroundColor: context.palette.card,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Écrans courts (iPhone SE, anciens Android) : espacements resserrés,
            // et sous-titre masqué sur les plus petits.
            final compact = constraints.maxHeight < 700;
            final showSubtitle = constraints.maxHeight >= 640;
            final sectionGap = compact ? AppSpacing.vGap12 : AppSpacing.vGap20;
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.s24,
                      AppSpacing.s4,
                      AppSpacing.s24,
                      AppSpacing.s16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Transform.translate(
                          // Icône alignée sur le texte malgré sa zone de toucher.
                          offset: const Offset(-AppSpacing.s12, 0),
                          child: IconButton(
                            onPressed: isLoading ? null : _goBack,
                            tooltip: tr('Retour'),
                            color: context.colors.primary,
                            icon: const Icon(
                              AppBackButton.icon,
                              size: AppBackButton.iconSize,
                            ),
                          ),
                        ),
                        AppSpacing.vGap4,
                        Text(
                          tr('Créer un compte'),
                          style: compact
                              ? AppTypography.titreMoyen
                              : AppTypography.grandTitre,
                        ),
                        if (showSubtitle) ...[
                          AppSpacing.vGap4,
                          Text(
                            tr('Rejoignez PsyAvocat en quelques secondes.'),
                            style: AppTypography.texteSecondaire,
                          ),
                        ],
                        sectionGap,
                        const Spacer(),
                        _StepIndicator(
                          labels: [tr('Identité'), 'Contact', tr('Sécurité')],
                          current: _currentStep,
                        ),
                        sectionGap,
                        const Spacer(),
                        Text(
                          tr(_stepTitles[_currentStep]),
                          style: AppTypography.petitTitre,
                        ),
                        compact ? AppSpacing.vGap12 : AppSpacing.vGap16,
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          switchInCurve: Curves.easeOutCubic,
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
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
                              child: _buildStepFields(compact),
                            ),
                          ),
                        ),
                        compact ? AppSpacing.vGap16 : AppSpacing.vGap24,
                        const Spacer(flex: 2),
                        AppButton(
                          text: _isLastStep
                              ? tr('Créer mon compte')
                              : 'Continuer',
                          color: AppColors.lawyer,
                          isLoading: isLoading,
                          // Dernière étape : bouton actif seulement si les CGU sont acceptées.
                          onPressed: (_isLastStep && !_hasAcceptedTerms)
                              ? null
                              : _onContinuePressed,
                        ),
                        AppSpacing.vGap12,
                        Center(
                          child: AppInlineLink(
                            text: tr('Déjà un compte ?'),
                            linkText: tr('Se connecter'),
                            onTap: () => context.go(AppRoutes.login),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStepFields(bool compact) {
    final fieldGap = compact ? AppSpacing.vGap16 : AppSpacing.vGap20;
    switch (_currentStep) {
      case 0:
        return Column(
          children: [
            AppTextField(
              controller: _prenomController,
              label: tr('Prénom'),
              prefixIcon: const Icon(Icons.person_outline_rounded),
              hint: tr('Ex: Ramla'),
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.next,
              validator: (value) =>
                  Validators.required(value, tr('Votre prénom est requis')),
            ),
            fieldGap,
            AppTextField(
              controller: _nomController,
              label: tr('Nom'),
              prefixIcon: const Icon(Icons.badge_outlined),
              hint: tr('Ex: Diarra'),
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.done,
              validator: (value) =>
                  Validators.required(value, tr('Votre nom est requis')),
              onFieldSubmitted: (_) => _onContinuePressed(),
            ),
          ],
        );
      case 1:
        return Column(
          children: [
            AppTextField(
              controller: _emailController,
              label: tr('Email'),
              prefixIcon: const Icon(Icons.alternate_email_rounded),
              hint: tr('Ex: ramla@gmail.com'),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: Validators.email,
            ),
            fieldGap,
            AppTextField(
              controller: _phoneController,
              label: tr('Téléphone'),
              prefixIcon: const Icon(Icons.phone_outlined),
              hint: tr('Ex: +223 76 12 34 56'),
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
              label: tr('Mot de passe'),
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              // Règle indiquée dans le champ : pas de ligne d'aide en dessous.
              hint: tr('Au moins 6 caractères'),
              obscureText: true,
              textInputAction: TextInputAction.next,
              validator: Validators.password,
            ),
            fieldGap,
            AppTextField(
              controller: _confirmPasswordController,
              label: tr('Confirmer le mot de passe'),
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
          color: context.palette.textSubtle,
        ),
        children: [
          TextSpan(text: tr("J'accepte les ")),
          TextSpan(text: tr("conditions d'utilisation"), style: highlighted),
          TextSpan(text: tr(' et la ')),
          TextSpan(
            text: tr('politique de confidentialité'),
            style: highlighted,
          ),
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
    final actif = context.colors.primary;
    final surActif = context.colors.onPrimary;
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0)
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                height: 2,
                margin: const EdgeInsets.only(bottom: 20),
                color: i <= current ? actif : context.palette.border,
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
                  color: i <= current ? actif : context.palette.card,
                  border: Border.all(
                    color: i <= current ? actif : context.palette.border,
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: i < current
                    ? Icon(Icons.check_rounded, size: 18, color: surActif)
                    : Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: i == current
                              ? surActif
                              : context.palette.textSubtle,
                        ),
                      ),
              ),
              const SizedBox(height: 6),
              Text(
                labels[i],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: i == current ? FontWeight.w700 : FontWeight.w500,
                  color: i <= current ? actif : context.palette.textSubtle,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
