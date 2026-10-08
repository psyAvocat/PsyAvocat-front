import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/enums/appointment_status.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../data/models/rendez_vous_model.dart';
import '../controllers/rendez_vous_controller.dart';

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
              const Icon(Icons.wifi_off_rounded, size: 60, color: Color(0xFFD1D5DB)),
              const SizedBox(height: 16),
              const Text('Impossible de charger vos rendez-vous'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.read(rendezVousControllerProvider.notifier).reload(),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    final rdvList = rdvAsync.value ?? [];
    final aVenir = rdvList.where((r) => r.statut == AppointmentStatus.confirme || r.statut == AppointmentStatus.enAttente).toList();
    final passes = rdvList.where((r) => r.statut == AppointmentStatus.passe).toList();
    final annules = rdvList.where((r) => r.statut == AppointmentStatus.annule).toList();

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
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
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
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
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
        final isConfirme = item.statut == AppointmentStatus.confirme;
        final isAnnule = item.statut == AppointmentStatus.annule;

        final statusColor = isConfirme
            ? const Color(0xFF16A34A)
            : isAnnule
                ? const Color(0xFFEF4444)
                : const Color(0xFFD97706);
        final statusBg = isConfirme
            ? const Color(0xFFDCFCE7)
            : isAnnule
                ? const Color(0xFFFEE2E2)
                : const Color(0xFFFEF3C7);
        
        final dayStr = DateFormat('d', 'fr_FR').format(item.dateHeure);
        final monthStr = DateFormat('MMM', 'fr_FR').format(item.dateHeure);
        final yearStr = DateFormat('yyyy', 'fr_FR').format(item.dateHeure);
        final timeStr = DateFormat('HH:mm', 'fr_FR').format(item.dateHeure) + ' - ' + DateFormat('HH:mm', 'fr_FR').format(item.fin);

        return InkWell(
          onTap: () {
            _showAppointmentDetailsSheet(context, item);
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge de date à gauche
                Container(
                  width: 64,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isConfirme ? const Color(0xFFEFF6FF) : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text(
                        dayStr,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: isConfirme ? const Color(0xFF1D4ED8) : const Color(0xFF6B7280),
                        ),
                      ),
                      Text(
                        monthStr,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isConfirme ? const Color(0xFF1D4ED8) : const Color(0xFF6B7280),
                        ),
                      ),
                      Text(
                        yearStr,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 14),

                // Détails au centre
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        timeStr,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.professionnelDisplayName,
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.typeProfessionnel,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4B5563),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.professionnelSpecialite ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF9CA3AF)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.mode ?? 'Non spécifié',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          item.statut.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Color(0xFF9CA3AF),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAppointmentDetailsSheet(BuildContext context, RendezVous item) {
    final dayStr = DateFormat('d', 'fr_FR').format(item.dateHeure);
    final monthStr = DateFormat('MMM', 'fr_FR').format(item.dateHeure);
    final yearStr = DateFormat('yyyy', 'fr_FR').format(item.dateHeure);
    final timeStr = '${DateFormat('HH:mm', 'fr_FR').format(item.dateHeure)} - ${DateFormat('HH:mm', 'fr_FR').format(item.fin)}';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.professionnelDisplayName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: item.statut == AppointmentStatus.confirme
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item.statut.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: item.statut == AppointmentStatus.confirme
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${item.typeProfessionnel} • ${item.professionnelSpecialite ?? ''}',
                style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
              ),
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF6B7280)),
                  const SizedBox(width: 8),
                  Text('$dayStr $monthStr $yearStr à $timeStr'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF6B7280)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item.mode ?? 'Non spécifié')),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.payments_outlined, size: 16, color: Color(0xFF6B7280)),
                  const SizedBox(width: 8),
                  Text('Honoraires : ${item.montantTotal ?? 0} FCFA (Acompte réglé : ${item.montantAcompte ?? 0} FCFA)'),
                ],
              ),
              if (item.canBeChangedAt(DateTime.now())) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ref.read(rendezVousControllerProvider.notifier).annuler(item.id);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Rendez-vous annulé avec succès.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.cancel_outlined, color: Color(0xFFEF4444), size: 18),
                    label: const Text(
                      'Annuler ce rendez-vous',
                      style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

