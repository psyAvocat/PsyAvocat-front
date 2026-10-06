import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/data/repositories/session_repository.dart';
import '../../../notifications/presentation/controllers/notifications_controller.dart';
import '../../../orientation/presentation/controllers/orientation_controller.dart';
import '../../../professionnels/data/models/professionnel_summary.dart';
import '../../../professionnels/presentation/controllers/professionnels_controller.dart';
import '../../../professionnels/presentation/widgets/professionnel_card.dart';
import '../../../rendez_vous/presentation/controllers/rendez_vous_controller.dart';
import '../widgets/home_cards.dart';
import '../widgets/home_header.dart';

/// Accueil : uniquement des données réelles (rendez-vous, orientation,
/// professionnels de l'univers). Chaque section gère ses propres états
/// chargement / vide / erreur, sans bloquer les autres.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  /// Nombre de professionnels mis en avant sur l'accueil.
  static const int _featuredCount = 3;

  Future<void> _refresh(WidgetRef ref) async {
    ref
      ..invalidate(currentUserProvider)
      ..invalidate(rendezVousListProvider)
      ..invalidate(mesResultatsProvider)
      ..invalidate(notificationsListProvider)
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
          child: ListView(
            padding: AppSpacing.screenPadding,
            children: [
              const HomeHeader(),
              AppSpacing.vGap32,
              const AppSectionHeader(title: 'Prochain rendez-vous'),
              AppSpacing.vGap12,
              const NextAppointmentCard(),
              AppSpacing.vGap32,
              if (universe.isPsychologist) ...[
                const OrientationSummaryCard(),
                AppSpacing.vGap32,
              ] else if (universe.isLawyer) ...[
                const DossiersSummaryCard(),
                AppSpacing.vGap32,
              ],
              AppSectionHeader(
                title: universe.professionalsLabel,
                actionLabel: 'Voir tout',
                onAction: () => context.go('/professionnels'),
              ),
              AppSpacing.vGap12,
              AppAsyncView<List<ProfessionnelSummary>>(
                compact: true,
                value: ref.watch(professionnelsByUniverseProvider),
                isEmpty: (list) => list.isEmpty,
                emptyMessage:
                    'Aucun ${universe.professionalsLabel.toLowerCase()} disponible pour le moment.',
                emptyIcon: Icons.person_search_outlined,
                onRetry: () => ref.invalidate(professionnelsByUniverseProvider),
                builder: (list) => Column(
                  children: [
                    for (final pro in list.take(_featuredCount))
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.s12),
                        child: ProfessionnelCard(
                          professionnel: pro,
                          onTap: () =>
                              context.push('/professionnels/${pro.id}'),
                        ),
                      ),
                  ],
                ),
              ),
              AppSpacing.vGap16,
            ],
          ),
        ),
      ),
    );
  }
}
