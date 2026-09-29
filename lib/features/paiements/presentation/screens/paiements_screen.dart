import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../data/models/paiement_model.dart';
import '../controllers/paiements_controller.dart';

/// Écran « Historique des paiements & Factures » PsyAvocat
class PaiementsScreen extends ConsumerWidget {
  const PaiementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final universe = ref.watch(currentUniverseProvider);
    final primaryColor = universe.primaryColor;
    final paiementsAsync = ref.watch(paiementsListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Mes paiements & Reçus',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E2432),
          ),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Bannière récapitulative
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF1E293B), const Color(0xFF334155)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Paiements sécurisés',
                          style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.lock_rounded, size: 12, color: Colors.white),
                              SizedBox(width: 4),
                              Text('100% Crypté', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Acomptes légaux de 20%',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Conformément aux règles déontologiques, l\'acompte garantit la réservation de votre créneau horaire.',
                      style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Liste des transactions
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
            sliver: paiementsAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
              ),
              error: (err, stack) => const SliverToBoxAdapter(
                child: Center(child: Text('Erreur lors du chargement des paiements')),
              ),
              data: (transactions) {
                if (transactions.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Text('Aucun paiement enregistré pour l\'instant.'),
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = transactions[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _PaiementCard(item: item, primaryColor: primaryColor),
                      );
                    },
                    childCount: transactions.length,
                  ),
                );
              },
            ),
          ),
        ],
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.reference,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6B7280)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Payé',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.description,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E2432)),
          ),
          const SizedBox(height: 4),
          Text(
            'Bénéficiaire : ${item.proRole} ${item.proName}',
            style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Moyen de paiement', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                  const SizedBox(height: 2),
                  Text(
                    item.moyenPaiement.replaceAll('_', ' '),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E2432)),
                  ),
                ],
              ),
              Text(
                item.formattedMontant,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: primaryColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
