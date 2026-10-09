import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/enums/appointment_status.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../data/models/rendez_vous_model.dart';
import '../controllers/rendez_vous_controller.dart';
import '../widgets/rendez_vous_card.dart';
import '../widgets/rendez_vous_details_sheet.dart';

/// Écran « Mes rendez-vous » conforme à la maquette Figma.
/// Affiche les 3 onglets : À venir, Passés, Annulés avec badges de date et statuts de confirmation.
class RendezVousScreen extends ConsumerStatefulWidget {
  const RendezVousScreen({super.key});

  @override
  ConsumerState<RendezVousScreen> createState() => _RendezVousScreenState();
}

class _RendezVousScreenState extends ConsumerState<RendezVousScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final universe = ref.watch(currentUniverseProvider);
    final primaryColor = universe.primaryColor;

    final rdvAsync = ref.watch(rendezVousControllerProvider);

    // Gestion état chargement / erreur
    if (rdvAsync.isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9FAFC),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (rdvAsync.hasError) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9FAFC),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                size: 60,
                color: Color(0xFFD1D5DB),
              ),
              const SizedBox(height: 16),
              const Text('Impossible de charger vos rendez-vous'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () =>
                    ref.read(rendezVousControllerProvider.notifier).reload(),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    final rdvList = rdvAsync.value ?? [];
    final aVenir = rdvList
        .where(
          (r) =>
              r.statut == AppointmentStatus.confirme ||
              r.statut == AppointmentStatus.enAttente,
        )
        .toList();
    final passes = rdvList
        .where((r) => r.statut == AppointmentStatus.passe)
        .toList();
    final annules = rdvList
        .where((r) => r.statut == AppointmentStatus.annule)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Mes rendez-vous',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
            fontFamily: 'Montserrat',
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Barre d'onglets segmentée
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 8.0,
              ),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF2F7),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF6B7280),
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabs: [
                    Tab(text: 'À venir (${aVenir.length})'),
                    Tab(text: 'Passés (${passes.length})'),
                    Tab(text: 'Annulés (${annules.length})'),
                  ],
                ),
              ),
            ),

            // Contenu des onglets
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  aVenir.isEmpty
                      ? const Center(
                          child: Text(
                            'Aucun rendez-vous à venir.',
                            style: TextStyle(color: Color(0xFF6B7280)),
                          ),
                        )
                      : _buildAppointmentsList(items: aVenir),
                  passes.isEmpty
                      ? const Center(
                          child: Text(
                            'Aucun rendez-vous passé.',
                            style: TextStyle(color: Color(0xFF6B7280)),
                          ),
                        )
                      : _buildAppointmentsList(items: passes),
                  annules.isEmpty
                      ? const Center(
                          child: Text(
                            'Aucun rendez-vous annulé.',
                            style: TextStyle(color: Color(0xFF6B7280)),
                          ),
                        )
                      : _buildAppointmentsList(items: annules),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentsList({required List<RendezVous> items}) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final item = items[index];
        return RendezVousCard(
          item: item,
          onTap: () => _showAppointmentDetailsSheet(context, item),
        );
      },
    );
  }

  void _showAppointmentDetailsSheet(BuildContext context, RendezVous item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return RendezVousDetailsSheet(
          item: item,
          onCancel: () {
            ref.read(rendezVousControllerProvider.notifier).annuler(item.id);
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Rendez-vous annulé avec succès.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        );
      },
    );
  }
}
