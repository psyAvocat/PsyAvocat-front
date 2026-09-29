import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/app_preferences_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/psyavocat_logo.dart';
import '../../../../core/widgets/top_arch_clipper.dart';
import '../controllers/auth_controller.dart';
import '../../../profile/data/repositories/profil_repository.dart';

/// Écran d'inscription PsyAvocat — 2 étapes :
/// 1. Informations de compte (email + mdp)
/// 2. Profil métier (prénom, nom, type de compte)
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Étape 1
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Étape 2
  final _prenomController = TextEditingController();
  final _nomController = TextEditingController();
  final _telephoneController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  int _step = 0; // 0 = compte, 1 = profil

  // Type : 'PATIENT' (psychologie) | 'JUSTICIABLE' (juridique)
  String _typeCompte = 'JUSTICIABLE';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _prenomController.dispose();
    _nomController.dispose();
    _telephoneController.dispose();
    super.dispose();
  }

  Future<void> _submitStep1() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Les mots de passe ne correspondent pas.'),
          backgroundColor: AppColors.statusRejected,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _step = 1);
  }

  Future<void> _submitStep2() async {
    if (!_formKey.currentState!.validate()) return;

    // 1. Création du compte Firebase
    final success = await ref.read(authControllerProvider.notifier).signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
    if (!success || !mounted) return;

    // 2. Création du profil métier dans le backend
    final profilRepo = ref.read(profilRepositoryProvider);
    try {
      if (_typeCompte == 'PATIENT') {
        await profilRepo.createPatientProfile(
          nom: _nomController.text.trim(),
          prenom: _prenomController.text.trim(),
          telephone: _telephoneController.text.trim().isNotEmpty
              ? _telephoneController.text.trim()
              : null,
        );
      } else {
        await profilRepo.createJusticiableProfile(
          nom: _nomController.text.trim(),
          prenom: _prenomController.text.trim(),
          telephone: _telephoneController.text.trim().isNotEmpty
              ? _telephoneController.text.trim()
              : null,
        );
      }
    } catch (_) {
      // Silencieux — on redirige quand même
    }

    if (mounted) {
      final prefs = ref.read(appPreferencesServiceProvider);
      final universe = prefs.getSelectedUniverse();
      if (universe != null && !universe.isNeutral) {
        ref.read(currentUniverseProvider.notifier).setUniverse(universe);
        context.go('/home');
      } else {
        context.go('/selection-univers');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    ref.listen<AsyncValue<void>>(authControllerProvider, (_, next) {
      if (next.hasError && !next.isLoading) {
        setState(() => _step = 0); // retour étape 1 si erreur Firebase
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString()),
            backgroundColor: AppColors.statusRejected,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    final screenHeight = MediaQuery.of(context).size.height;
    final headerHeight = (screenHeight * 0.28).clamp(200.0, 250.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Arche violette supérieure ────────────────────────────────
            Stack(
              children: [
                ClipPath(
                  clipper: const TopArchClipper(),
                  child: Container(
                    height: headerHeight,
                    width: double.infinity,
                    color: const Color(0xFF3B1E78),
                  ),
                ),
                // Bouton retour
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 4,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                    onPressed: () {
                      if (_step == 1) {
                        setState(() => _step = 0);
                      } else {
                        context.pop();
                      }
                    },
                  ),
                ),
                // Logo centré
                Positioned(
                  top: MediaQuery.of(context).padding.top + 14,
                  left: 0,
                  right: 50,
                  child: Center(
                    child: const PsyAvocatLogo(
                      size: 90,
                      fontSize: 22,
                      showText: true,
                      isWhite: true,
                    ),
                  ),
                ),
              ],
            ),

            // ── 2. Indicateur d'étape ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Row(
                children: [
                  _StepDot(active: true),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Container(
                      height: 3,
                      color: _step == 1 ? const Color(0xFF3B1E78) : const Color(0xFFE5E7EB),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _StepDot(active: _step == 1),
                ],
              ),
            ),

            // ── 3. Formulaire ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                  child: _step == 0
                      ? _Step1Form(
                          key: const ValueKey('step1'),
                          emailController: _emailController,
                          passwordController: _passwordController,
                          confirmController: _confirmPasswordController,
                          obscurePassword: _obscurePassword,
                          obscureConfirm: _obscureConfirm,
                          onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
                          onToggleConfirm: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          isLoading: isLoading,
                          onNext: _submitStep1,
                          onLogin: () => context.pop(),
                        )
                      : _Step2Form(
                          key: const ValueKey('step2'),
                          prenomController: _prenomController,
                          nomController: _nomController,
                          telephoneController: _telephoneController,
                          typeCompte: _typeCompte,
                          onTypeChanged: (t) => setState(() => _typeCompte = t),
                          isLoading: isLoading,
                          onSubmit: _submitStep2,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Étape 1 : Compte Firebase ────────────────────────────────────────────────
class _Step1Form extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final bool obscurePassword;
  final bool obscureConfirm;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirm;
  final bool isLoading;
  final VoidCallback onNext;
  final VoidCallback onLogin;

  const _Step1Form({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.confirmController,
    required this.obscurePassword,
    required this.obscureConfirm,
    required this.onTogglePassword,
    required this.onToggleConfirm,
    required this.isLoading,
    required this.onNext,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        const Text(
          'Créer un compte',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E2432),
            fontFamily: 'Montserrat',
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Étape 1 sur 2 — Vos identifiants',
          style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 20),

        _FieldLabel('Email'),
        const SizedBox(height: 8),
        TextFormField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          validator: Validators.email,
          decoration: _inputDeco('Ex: ramla@gmail.com'),
        ),
        const SizedBox(height: 16),

        _FieldLabel('Mot de passe'),
        const SizedBox(height: 8),
        TextFormField(
          controller: passwordController,
          obscureText: obscurePassword,
          validator: Validators.password,
          decoration: _inputDeco('Minimum 6 caractères').copyWith(
            suffixIcon: _EyeButton(obscure: obscurePassword, onTap: onTogglePassword),
          ),
        ),
        const SizedBox(height: 16),

        _FieldLabel('Confirmer le mot de passe'),
        const SizedBox(height: 8),
        TextFormField(
          controller: confirmController,
          obscureText: obscureConfirm,
          validator: (v) => (v?.isEmpty ?? true) ? 'Champ requis' : null,
          decoration: _inputDeco('Répétez le mot de passe').copyWith(
            suffixIcon: _EyeButton(obscure: obscureConfirm, onTap: onToggleConfirm),
          ),
        ),
        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: isLoading ? null : onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B1E78),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Continuer',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Déjà un compte ? ', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
              GestureDetector(
                onTap: onLogin,
                child: const Text(
                  'Se connecter',
                  style: TextStyle(fontSize: 14, color: Color(0xFF5B21B6), fontWeight: FontWeight.w700, decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF5B21B6), width: 1.6)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1.6)),
      );
}

// ─── Étape 2 : Profil métier ──────────────────────────────────────────────────
class _Step2Form extends StatelessWidget {
  final TextEditingController prenomController;
  final TextEditingController nomController;
  final TextEditingController telephoneController;
  final String typeCompte;
  final ValueChanged<String> onTypeChanged;
  final bool isLoading;
  final VoidCallback onSubmit;

  const _Step2Form({
    super.key,
    required this.prenomController,
    required this.nomController,
    required this.telephoneController,
    required this.typeCompte,
    required this.onTypeChanged,
    required this.isLoading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        const Text(
          'Votre profil',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E2432),
            fontFamily: 'Montserrat',
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Étape 2 sur 2 — Vos informations',
          style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 22),

        // Type de compte
        const Text('Je suis un(e)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _TypeTile(
                label: 'Client juridique',
                subtitle: 'Besoin d\'un avocat',
                icon: Icons.gavel_rounded,
                isSelected: typeCompte == 'JUSTICIABLE',
                onTap: () => onTypeChanged('JUSTICIABLE'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TypeTile(
                label: 'Patient',
                subtitle: 'Besoin d\'un psy',
                icon: Icons.psychology_rounded,
                isSelected: typeCompte == 'PATIENT',
                onTap: () => onTypeChanged('PATIENT'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Prénom + Nom côte à côte
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel('Prénom'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: prenomController,
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => (v?.isEmpty ?? true) ? 'Requis' : null,
                    decoration: _inputDeco('Ramla'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel('Nom'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: nomController,
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => (v?.isEmpty ?? true) ? 'Requis' : null,
                    decoration: _inputDeco('Diallo'),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        _FieldLabel('Téléphone (optionnel)'),
        const SizedBox(height: 8),
        TextFormField(
          controller: telephoneController,
          keyboardType: TextInputType.phone,
          decoration: _inputDeco('+223 XX XX XX XX'),
        ),
        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: isLoading ? null : onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B1E78),
              disabledBackgroundColor: const Color(0xFFE5E7EB),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              elevation: 0,
            ),
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : const Text(
                    'Créer mon compte',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF5B21B6), width: 1.6)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1.6)),
      );
}

// ─── Tuile type de compte ────────────────────────────────────────────────────
class _TypeTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF3B1E78);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? accent.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accent : const Color(0xFFE5E7EB),
            width: isSelected ? 1.8 : 1.2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? accent : const Color(0xFF9CA3AF), size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? accent : const Color(0xFF374151),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
      );
}

class _EyeButton extends StatelessWidget {
  final bool obscure;
  final VoidCallback onTap;
  const _EyeButton({required this.obscure, required this.onTap});

  @override
  Widget build(BuildContext context) => IconButton(
        icon: Icon(
          obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: const Color(0xFF6B7280),
          size: 22,
        ),
        onPressed: onTap,
      );
}

class _StepDot extends StatelessWidget {
  final bool active;
  const _StepDot({required this.active});

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: active ? 28 : 12,
        height: 8,
        decoration: BoxDecoration(
          color: active ? const Color(0xFF3B1E78) : const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(4),
        ),
      );
}
