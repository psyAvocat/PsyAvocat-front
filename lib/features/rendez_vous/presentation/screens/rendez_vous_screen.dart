import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/enums/appointment_status.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../data/models/rendez_vous_model.dart';
import '../controllers/rendez_vous_controller.dart';
import '../widgets/rendez_vous_card.dart';
import '../widgets/rendez_vous_details_sheet.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/user_message.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/app_alert.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/design_system.dart';

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
    final primaryColor = Theme.of(context).colorScheme.primary;

    final rdvAsync = ref.watch(rendezVousControllerProvider);

    // Gestion état chargement / erreur
    if (rdvAsync.isLoading) {
      return Scaffold(
        backgroundColor: context.palette.page,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (rdvAsync.hasError) {
      return Scaffold(
        backgroundColor: context.palette.page,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 60,
                color: context.palette.borderStrong,
              ),
              const SizedBox(height: 16),
              Text(tr('Impossible de charger vos rendez-vous')),
              const SizedBox(height: 12),
              AppButton(
                text: tr('Réessayer'),
                isFullWidth: false,
                onPressed: () =>
                    ref.read(rendezVousControllerProvider.notifier).reload(),
              ),
            ],
          ),
        ),
      );
    }

    // Rendez-vous de l'univers courant uniquement (Avocat ou Psychologue).
    final now = DateTime.now();
    final rdvList = (rdvAsync.value ?? [])
        .where((r) => r.universe == universe)
        .toList();
    final annules =
        rdvList.where((r) => r.statut == AppointmentStatus.annule).toList()
          ..sort((a, b) => b.dateHeure.compareTo(a.dateHeure));
    final actifs = rdvList.where((r) => r.statut != AppointmentStatus.annule);
    final aVenir =
        actifs.where((r) => r.phaseAt(now) != AppointmentPhase.passe).toList()
          ..sort((a, b) => a.dateHeure.compareTo(b.dateHeure));
    final passes =
        actifs.where((r) => r.phaseAt(now) == AppointmentPhase.passe).toList()
          ..sort((a, b) => b.dateHeure.compareTo(a.dateHeure));

    return Scaffold(
      backgroundColor: context.palette.page,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text(
          tr('Mes rendez-vous'),
          style: AppTypography.titreMoyen.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: context.palette.textStrong,
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
                  color: context.palette.muted,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: context.palette.textMuted,
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
                    _onglet(tr('À venir ({n})', {'n': aVenir.length})),
                    _onglet(tr('Passés ({n})', {'n': passes.length})),
                    _onglet(tr('Annulés ({n})', {'n': annules.length})),
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
                      ? AppEmptyStateView(
                          icon: Icons.event_available_outlined,
                          title: tr('Aucun rendez-vous à venir'),
                          message: universe.isLawyer
                              ? tr(
                                  'Envoyez un dossier à un avocat : une fois accepté, vous pourrez réserver un créneau.',
                                )
                              : tr(
                                  'Choisissez un psychologue et réservez un créneau disponible.',
                                ),
                          actionText: universe.isLawyer
                              ? tr('Trouver un avocat')
                              : tr('Trouver un psychologue'),
                          onAction: () => context.go(AppRoutes.professionnels),
                        )
                      : _buildAppointmentsList(items: aVenir),
                  passes.isEmpty
                      ? AppEmptyStateView(
                          icon: Icons.history_rounded,
                          title: tr('Aucun rendez-vous passé'),
                          message: tr(
                            'Vos rendez-vous terminés apparaîtront ici.',
                          ),
                        )
                      : _buildAppointmentsList(items: passes),
                  annules.isEmpty
                      ? AppEmptyStateView(
                          icon: Icons.event_busy_outlined,
                          title: tr('Aucun rendez-vous annulé'),
                          message: tr(
                            'Les rendez-vous annulés apparaîtront ici.',
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

  /// Onglet dont le libellé se réduit pour tenir dans sa part de largeur.
  Widget _onglet(String libelle) => Tab(
    child: FittedBox(fit: BoxFit.scaleDown, child: Text(libelle, maxLines: 1)),
  );

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
      backgroundColor: context.palette.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return RendezVousDetailsSheet(
          item: item,
          onCancel: () async {
            Navigator.pop(ctx);
            try {
              await ref
                  .read(rendezVousControllerProvider.notifier)
                  .annuler(item.id);
              if (context.mounted) {
                AppNotification.showSuccess(
                  context,
                  tr('Rendez-vous annulé avec succès.'),
                );
              }
            } catch (error) {
              if (context.mounted) {
                AppNotification.showError(context, userMessageFor(error));
              }
            }
          },
        );
      },
    );
  }
}
