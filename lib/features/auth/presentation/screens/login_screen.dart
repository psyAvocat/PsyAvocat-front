import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/app_preferences_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/google_logo.dart';
import '../../../../core/widgets/psyavocat_logo.dart';
import '../controllers/auth_controller.dart';
import '../../../../core/widgets/top_arch_clipper.dart';
export '../../../../core/widgets/top_arch_clipper.dart';

/// Écran de connexion officiel conforme à la maquette Figma PsyAvocat.
/// Arche violette foncée, formulaire propre, bouton violet→violet, icône G officielle.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authControllerProvider.notifier).signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (success && mounted) {
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
    final headerHeight = (screenHeight * 0.33).clamp(220.0, 300.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Arche violette supérieure avec logo blanc ──────────────────
            Stack(
              children: [
                ClipPath(
                  clipper: const TopArchClipper(),
                  child: Container(
                    height: headerHeight,
                    width: double.infinity,
                    // Couleur violette foncée conforme à la maquette (pas de gradient bleu)
                    color: const Color(0xFF3B1E78),
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 18,
                  left: 0,
                  right: 50,
                  child: Center(
                    child: const PsyAvocatLogo(
                      size: 100,
                      fontSize: 24,
                      showText: true,
                      isWhite: true,
                    ),
                  ),
                ),
              ],
            ),

            // ── 2. Formulaire ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    const Text(
                      'Connexion',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E2432),
                        fontFamily: 'Montserrat',
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 22),

                    // ── Champ Email ───────────────────────────────────────────
                    const Text(
                      'Email ou numéro de téléphone',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email,
                      decoration: _inputDecoration('Ex: ramla@gmail.com'),
                    ),

                    const SizedBox(height: 18),

                    // ── Champ Mot de passe ────────────────────────────────────
                    const Text(
                      'Mot de passe',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      validator: Validators.password,
                      decoration: _inputDecoration('••••••••').copyWith(
                        hintStyle: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 20,
                          letterSpacing: 2,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: const Color(0xFF6B7280),
                            size: 22,
                          ),
                          onPressed: () => setState(() {
                            _obscurePassword = !_obscurePassword;
                          }),
                        ),
                      ),
                    ),

                    // ── Mot de passe oublié ───────────────────────────────────
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push('/forgot-password'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                        ),
                        child: const Text(
                          'Mot de passe oublié ?',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF5B21B6),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // ── Bouton Se connecter — violet plein conforme maquette ───
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B1E78),
                          disabledBackgroundColor: const Color(0xFFE5E7EB),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Se connecter',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Séparateur ────────────────────────────────────────────
                    Row(
                      children: [
                        const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'ou',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // ── Bouton Google — icône G officielle centrée ────────────
                    Center(
                      child: InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Connexion Google disponible dans une prochaine version.',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                              color: const Color(0xFFEEEEEE),
                            ),
                          ),
                          child: const Center(
                            child: GoogleLogo(size: 26),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 36),

                    // ── Lien inscription ──────────────────────────────────────
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Pas encore de compte ? ',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.push('/register'),
                            child: const Text(
                              "S'inscrire",
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF5B21B6),
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF9CA3AF),
        fontSize: 14,
      ),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFF5B21B6),
          width: 1.6,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.6),
      ),
    );
  }
}
