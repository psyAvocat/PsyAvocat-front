import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../../contenus/presentation/controllers/contenus_controller.dart';
import '../../../notifications/presentation/controllers/notifications_controller.dart';
import '../../../rendez_vous/presentation/controllers/rendez_vous_controller.dart';
import '../widgets/lawyer_home_view.dart';
import '../widgets/psychologist_home_view.dart';

/// Accueil : uniquement des données réelles (rendez-vous, orientation,
/// professionnels de l'univers). Chaque section gère ses propres états
/// chargement / vide / erreur, sans bloquer les autres.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  /// Glisser vers le bas : recharge les données affichées sur l'accueil.
  /// L'indicateur se ferme au plus tard après 15 s (jamais de blocage), même si
  /// le réseau ne répond pas ; chaque section affiche ensuite son propre état.
  Future<void> _refresh(WidgetRef ref) async {
    ref
      ..invalidate(notificationsControllerProvider)
      ..invalidate(popularPublicationsProvider);
    try {
      await ref
          .refresh(rendezVousControllerProvider.future)
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      // Erreur ou délai dépassé : affichés par la section concernée.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final universe = ref.watch(currentUniverseProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _refresh(ref),
          child: universe.isPsychologist
              ? const PsychologistHomeView()
              : const LawyerHomeView(),
        ),
      ),
    );
  }
}
