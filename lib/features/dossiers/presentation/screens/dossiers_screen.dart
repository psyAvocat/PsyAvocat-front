import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/user_message.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../rendez_vous/data/models/reservation_contexte.dart';
import '../../data/models/dossier_model.dart';
import '../controllers/create_dossier_wizard_controller.dart';
import '../controllers/dossiers_controller.dart';
import 'create_dossier_wizard_screen.dart';
import '../../../../core/widgets/app_button.dart';

/// « Mes dossiers juridiques » : suivi réel des soumissions (GET /api/dossiers).
class DossiersScreen extends ConsumerWidget {
  const DossiersScreen({super.key});

  void _nouveauDossier(BuildContext context, WidgetRef ref) {
    ref.read(createDossierWizardProvider.notifier).clear();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateDossierWizardScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final universe = ref.watch(currentUniverseProvider);
    final primaryColor = universe.primaryColor;
    final dossiersAsync = ref.watch(dossiersListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Mes dossiers',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
            fontFamily: 'Montserrat',
          ),
        ),
      ),
      body: SafeArea(
        child: dossiersAsync.when(
          loading: () => AppLoadingView(universe: universe),
          error: (e, _) => AppErrorStateView(
            title: 'Impossible de charger vos dossiers',
            message: userMessageFor(e),
            onRetry: () => ref.read(dossiersListProvider.notifier).refresh(),
          ),
          data: (dossiers) {
            if (dossiers.isEmpty) {
              return AppEmptyStateView(
                icon: Icons.folder_open_rounded,
                title: 'Aucun dossier en cours',
                message:
                    'Déposez votre premier dossier juridique pour le soumettre aux avocats de votre choix.',
                actionText: 'Créer un dossier',
                onAction: () => _nouveauDossier(context, ref),
              );
            }
            return RefreshIndicator(
              onRefresh: () =>
                  ref.read(dossiersListProvider.notifier).refresh(),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                itemCount: dossiers.length,
                itemBuilder: (context, index) => _DossierCard(
                  dossier: dossiers[index],
                  primaryColor: primaryColor,
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _nouveauDossier(context, ref),
        backgroundColor: primaryColor,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Nouveau dossier',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

/// Libellé et couleur d'un statut de dossier.
(String, Color) _statutDossier(DossierModel d) {
  if (d.estPrisEnCharge) return ('Pris en charge', const Color(0xFF059669));
  if (d.soumissions.isNotEmpty &&
      d.soumissions.every((s) => s.statut == 'REFUSEE')) {
    return ('Décliné', const Color(0xFFDC2626));
  }
  return ('En attente de réponse', const Color(0xFFD97706));
}

/// Libellé et couleur d'un statut de soumission.
(String, Color) _statutSoumission(SoumissionModel s) {
  switch (s.statut) {
    case 'ACCEPTEE':
      return ('Accepté', const Color(0xFF059669));
    case 'RETENUE':
      return ('Rendez-vous pris', const Color(0xFF1D4ED8));
    case 'REFUSEE':
      return ('Décliné', const Color(0xFFDC2626));
    case 'CADUQUE':
      return ('Confié à un confrère', const Color(0xFF6B7280));
    default:
      return ('En attente', const Color(0xFFD97706));
  }
}

class _DossierCard extends StatelessWidget {
  final DossierModel dossier;
  final Color primaryColor;

  const _DossierCard({required this.dossier, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    final statut = _statutDossier(dossier);
    final retenue = dossier.soumissionRetenue;
    final reponses = dossier.soumissions
        .where((s) => s.statut != 'EN_ATTENTE')
        .length;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: InkWell(
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _DossierDetailSheet(
            dossierId: dossier.id,
            primaryColor: primaryColor,
          ),
        ),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      dossier.dateOuverture != null
                          ? 'Ouvert le ${Formatters.formatLongDate(dossier.dateOuverture)}'
                          : (dossier.domaineNom ?? ''),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                  _Badge(label: statut.$1, color: statut.$2),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                dossier.titre,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              if (dossier.domaineNom != null) ...[
                const SizedBox(height: 4),
                Text(
                  dossier.domaineNom!,
                  style: TextStyle(
                    fontSize: 13,
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                retenue != null
                    ? 'Confié à ${retenue.displayName}'
                    : '${dossier.soumissions.length} avocat(s) sollicité(s) • $reponses réponse(s)',
                style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

/// Détail d'un dossier : relu depuis la liste à jour (statuts temps réel).
class _DossierDetailSheet extends ConsumerWidget {
  final String dossierId;
  final Color primaryColor;

  const _DossierDetailSheet({
    required this.dossierId,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dossier = ref
        .watch(dossiersListProvider)
        .value
        ?.where((d) => d.id == dossierId)
        .firstOrNull;
    if (dossier == null) return const SizedBox.shrink();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scroll) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: scroll,
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              dossier.titre,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 16),
            if (dossier.description.isNotEmpty) ...[
              const Text(
                'Description',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                dossier.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF374151),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (dossier.piecesJointes.isNotEmpty) ...[
              Text(
                'Pièces jointes (${dossier.piecesJointes.length})',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ...dossier.piecesJointes.map(
                (p) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.insert_drive_file_outlined,
                    color: primaryColor,
                  ),
                  title: Text(
                    p.nom,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              'Avocats sollicités (${dossier.soumissions.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 12),
            ...dossier.soumissions.map(
              (s) => _SoumissionCard(
                dossier: dossier,
                soumission: s,
                primaryColor: primaryColor,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SoumissionCard extends StatelessWidget {
  final DossierModel dossier;
  final SoumissionModel soumission;
  final Color primaryColor;

  const _SoumissionCard({
    required this.dossier,
    required this.soumission,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final statut = _statutSoumission(soumission);
    final reservable =
        soumission.estAcceptee &&
        soumission.tarifPropose != null &&
        soumission.avocatId.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  soumission.displayName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              _Badge(label: statut.$1, color: statut.$2),
            ],
          ),
          if (soumission.reponse != null && soumission.reponse!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              soumission.reponse!,
              style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
            ),
          ],
          if (soumission.tarifPropose != null) ...[
            const SizedBox(height: 8),
            Text(
              'Honoraires proposés : ${Formatters.formatFcfa(soumission.tarifPropose!)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: primaryColor,
              ),
            ),
          ],
          if (reservable) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: 'Prendre rendez-vous',
                color: primaryColor,
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push(
                    AppRoutes.choixCreneau(soumission.avocatId),
                    extra: ReservationContexte.avocat(
                      professionnelId: soumission.avocatId,
                      soumissionId: soumission.id,
                      dossierTitre: dossier.titre,
                      montantDossier: soumission.tarifPropose!,
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
