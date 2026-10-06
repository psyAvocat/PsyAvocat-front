import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../orientation/data/models/questionnaire_model.dart';
import '../../../orientation/presentation/controllers/orientation_controller.dart';
import '../../../rendez_vous/data/models/rendez_vous_model.dart';
import '../../../rendez_vous/presentation/controllers/rendez_vous_controller.dart';
import '../controllers/home_providers.dart';

/// Carte « Prochain rendez-vous » (GET /api/rendez-vous).
class NextAppointmentCard extends ConsumerWidget {
  const NextAppointmentCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final universe = ref.watch(currentUniverseProvider);

    return AppAsyncView<RendezVousItem?>(
      compact: true,
      value: ref.watch(nextAppointmentProvider),
      onRetry: () => ref.invalidate(rendezVousListProvider),
      builder: (rdv) => rdv == null
          // État vide avec une action utile : trouver un professionnel.
          ? _NoAppointmentContent(
              actionLabel:
                  'Trouver un ${universe.isPsychologist ? 'psychologue' : 'avocat'}',
            )
          : _AppointmentContent(appointment: rdv),
    );
  }
}

class _NoAppointmentContent extends StatelessWidget {
  final String actionLabel;

  const _NoAppointmentContent({required this.actionLabel});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: AppSpacing.cardPaddingCompact,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.event_available_outlined,
                  color: scheme.onSurfaceVariant,
                ),
                AppSpacing.hGap12,
                Expanded(
                  child: Text(
                    'Aucun rendez-vous à venir.',
                    style: AppTypography.texteSecondaire,
                  ),
                ),
              ],
            ),
            AppSpacing.vGap8,
            OutlinedButton(
              onPressed: () => context.go('/professionnels'),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentContent extends StatelessWidget {
  final RendezVousItem appointment;

  const _AppointmentContent({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        onTap: () => context.go('/rendez-vous'),
        child: Padding(
          padding: AppSpacing.cardPaddingCompact,
          child: Row(
            children: [
              // Pastille date : jour + mois.
              Container(
                width: 60,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: AppRadii.r12,
                ),
                child: Column(
                  children: [
                    Text(
                      appointment.day,
                      style: AppTypography.petitTitre.copyWith(
                        color: scheme.primary,
                      ),
                    ),
                    Text(
                      appointment.month,
                      style: AppTypography.miniTexte.copyWith(
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.hGap16,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.proName,
                      style: AppTypography.texteSemiBold,
                    ),
                    AppSpacing.vGap4,
                    Text(
                      appointment.time,
                      style: AppTypography.texteSecondaire,
                    ),
                    Text(appointment.mode, style: AppTypography.miniTexte),
                    AppSpacing.vGap4,
                    Text(
                      appointment.status,
                      style: AppTypography.badgeTexte.copyWith(
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Carte « Votre orientation » (GET /api/orientation/mes-resultats).
class OrientationSummaryCard extends ConsumerWidget {
  const OrientationSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latest = ref.watch(latestOrientationProvider);

    return AppAsyncView<ResultatOrientationModel?>(
      compact: true,
      value: latest,
      onRetry: () => ref.invalidate(mesResultatsProvider),
      builder: (result) => _OrientationContent(result: result),
    );
  }
}

class _OrientationContent extends ConsumerWidget {
  final ResultatOrientationModel? result;

  const _OrientationContent({required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final hasResult = result?.mainLabel != null;

    return Card(
      color: scheme.secondaryContainer,
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.r20),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.explore_outlined, color: scheme.primary),
                AppSpacing.hGap8,
                Expanded(
                  child: Text(
                    hasResult
                        ? 'Votre dernière orientation'
                        : 'Trouvez le bon professionnel',
                    style: AppTypography.texteSemiBold,
                  ),
                ),
              ],
            ),
            AppSpacing.vGap8,
            Text(
              hasResult
                  ? result!.mainLabel!
                  : 'Répondez à quelques questions : nous vous orientons vers '
                        'l’accompagnement adapté à votre situation.',
              style: hasResult
                  ? AppTypography.petitTitre.copyWith(color: scheme.primary)
                  : AppTypography.texteSecondaire,
            ),
            AppSpacing.vGap16,
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                onPressed: () => context.push('/orientation/intro'),
                child: Text(
                  hasResult ? 'Refaire le questionnaire' : 'Commencer',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte « Mes dossiers juridiques » (univers Avocat uniquement).
class DossiersSummaryCard extends StatelessWidget {
  const DossiersSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      color: scheme.secondaryContainer,
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.r20),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.folder_special_outlined, color: scheme.primary),
                AppSpacing.hGap8,
                Expanded(
                  child: Text(
                    'Suivi de vos dossiers juridiques',
                    style: AppTypography.texteSemiBold,
                  ),
                ),
              ],
            ),
            AppSpacing.vGap8,
            Text(
              'Consultez vos dossiers en cours, transmettez vos pièces et échangez avec votre avocat.',
              style: AppTypography.texteSecondaire,
            ),
            AppSpacing.vGap16,
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                onPressed: () => context.push('/dossiers'),
                child: const Text('Accéder à mes dossiers'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

