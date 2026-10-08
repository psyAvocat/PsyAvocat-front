import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../../../core/widgets/widgets.dart';
import '../../data/models/professionnel_summary.dart';
import '../controllers/professionnels_controller.dart';
import '../widgets/professionnel_card.dart';

/// Onglet « Avocats » ou « Psychologues » selon l'univers actif.
/// Données : GET /api/professionnels?type=AVOCAT|PSYCHOLOGUE.
class ProfessionnelsListScreen extends ConsumerWidget {
  const ProfessionnelsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final universe = ref.watch(currentUniverseProvider);
    final professionnels = ref.watch(professionnelsByUniverseProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(universe.professionalsLabel),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Rechercher',
            onPressed: () => context.push('/professionnels/recherche'),
          ),
        ],
      ),
      body: AppAsyncView<List<ProfessionnelSummary>>(
        value: professionnels,
        isEmpty: (list) => list.isEmpty,
        emptyTitle: 'Aucun professionnel pour le moment',
        emptyMessage:
            'Aucun ${universe.professionalsLabel.toLowerCase()} n’est disponible actuellement. Revenez bientôt.',
        emptyIcon: Icons.person_search_outlined,
        onRetry: () => ref.invalidate(professionnelsByUniverseProvider),
        builder: (list) => RefreshIndicator(
          onRefresh: () => ref.refresh(professionnelsByUniverseProvider.future),
          child: ListView.separated(
            padding: AppSpacing.screenPadding,
            itemCount: list.length,
            separatorBuilder: (_, _) => AppSpacing.vGap12,
            itemBuilder: (context, index) {
              final pro = list[index];
              return ProfessionnelCard(
                professionnel: pro,
                onTap: () => context.push('/professionnels/${pro.id}'),
              );
            },
          ),
        ),
      ),
    );
  }
}
