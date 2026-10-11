import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/user_message.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../data/models/paiement_model.dart';
import '../controllers/paiements_controller.dart';

/// Historique des acomptes de l'univers courant.
/// V1 : paiements SIMULÉS, présentés comme tels (aucune transaction réelle).
class PaiementsScreen extends ConsumerWidget {
  const PaiementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final universe = ref.watch(currentUniverseProvider);
    final primaryColor = universe.primaryColor;
    final paiementsAsync = ref.watch(paiementsUniversProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Mes paiements',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E2432),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(paiementsListProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.science_outlined, color: Color(0xFFC2410C)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Paiements simulés : l’acompte de 20 % valide votre rendez-vous, mais aucune '
                      'somme n’est réellement débitée. Le paiement en ligne sera disponible ultérieurement.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF7C2D12),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...paiementsAsync.when(
              loading: () => [
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
              error: (e, _) => [
                AppErrorStateView(
                  title: 'Impossible de charger vos paiements',
                  message: userMessageFor(e),
                  onRetry: () =>
                      ref.read(paiementsListProvider.notifier).refresh(),
                ),
              ],
              data: (paiements) => paiements.isEmpty
                  ? [
                      const AppEmptyStateView(
                        icon: Icons.receipt_long_outlined,
                        title: 'Aucun paiement',
                        message:
                            'Les acomptes de vos rendez-vous apparaîtront ici.',
                      ),
                    ]
                  : paiements
                        .map(
                          (p) => _PaiementCard(
                            item: p,
                            primaryColor: primaryColor,
                          ),
                        )
                        .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaiementCard extends StatelessWidget {
  final PaiementModel item;
  final Color primaryColor;

  const _PaiementCard({required this.item, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    final couleurStatut = item.estAnnule
        ? const Color(0xFF6B7280)
        : const Color(0xFF059669);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.professionnel.isNotEmpty
                      ? item.professionnel
                      : 'Rendez-vous',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: couleurStatut.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.estAnnule
                      ? 'Annulé'
                      : (item.simulation ? 'Acompte simulé' : 'Payé'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: couleurStatut,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (item.rendezVousDate != null)
            Text(
              'Rendez-vous du ${Formatters.formatJourLong(item.rendezVousDate!)} à ${Formatters.formatHeure(item.rendezVousDate!)}',
              style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
            ),
          if (item.datePaiement != null)
            Text(
              'Enregistré le ${Formatters.formatLongDate(item.datePaiement)}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  item.montantTotalRendezVous != null
                      ? 'Total du rendez-vous : ${Formatters.formatFcfa(item.montantTotalRendezVous!)}'
                      : '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
              Text(
                Formatters.formatFcfa(item.montant),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
