import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../../auth/data/repositories/session_repository.dart';
import '../../../notifications/presentation/controllers/notifications_controller.dart';
import '../../../orientation/presentation/controllers/orientation_controller.dart';
import '../../../professionnels/presentation/controllers/professionnels_controller.dart';
import '../../../rendez_vous/presentation/controllers/rendez_vous_controller.dart';
import '../widgets/lawyer_home_view.dart';
import '../widgets/psychologist_home_view.dart';

/// Accueil : uniquement des données réelles (rendez-vous, orientation,
/// professionnels de l'univers). Chaque section gère ses propres états
/// chargement / vide / erreur, sans bloquer les autres.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref
      ..invalidate(currentUserProvider)
      ..invalidate(rendezVousControllerProvider)
      ..invalidate(mesResultatsProvider)
      ..invalidate(notificationsControllerProvider)
      ..invalidate(professionnelsByUniverseProvider);
    // L'indicateur de rafraîchissement reste affiché jusqu'au rechargement de la liste.
    await ref.read(professionnelsByUniverseProvider.future);
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
