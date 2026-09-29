import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/universe_provider.dart';

/// Écran d'animation de matching algorithmique.
/// Analyse les réponses du questionnaire et calcule les profils les plus adaptés.
class OrientationMatchingScreen extends ConsumerStatefulWidget {
  const OrientationMatchingScreen({super.key});

  @override
  ConsumerState<OrientationMatchingScreen> createState() => _OrientationMatchingScreenState();
}

class _OrientationMatchingScreenState extends ConsumerState<OrientationMatchingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  int _messageIndex = 0;

  static const List<String> _messages = [
    'Analyse de vos critères...',
    'Détection du domaine juridique compétent...',
    'Recherche des professionnels à votre écoute...',
    'Sélection des profils optimaux terminée !',
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Progression des messages
    Timer.periodic(const Duration(milliseconds: 650), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_messageIndex < _messages.length - 1) {
        setState(() {
          _messageIndex++;
        });
      } else {
        timer.cancel();
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) {
            context.go('/professionnels');
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final universe = ref.watch(currentUniverseProvider);
    final primaryColor = universe.primaryColor;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animation de pulsation
                RotationTransition(
                  turns: _animController,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.2),
                        width: 3,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primaryColor,
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                const Text(
                  'Algorithme de matching',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E2432),
                    fontFamily: 'Montserrat',
                  ),
                ),

                const SizedBox(height: 12),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    _messages[_messageIndex],
                    key: ValueKey<int>(_messageIndex),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
