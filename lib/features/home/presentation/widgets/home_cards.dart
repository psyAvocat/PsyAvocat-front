import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../rendez_vous/data/models/rendez_vous_model.dart';
import '../../../rendez_vous/presentation/controllers/rendez_vous_controller.dart'
    hide nextAppointmentProvider;
import '../controllers/home_providers.dart';
import '../../../../core/router/app_routes.dart';

/// Carte « Prochain rendez-vous » (GET /api/rendez-vous).
class NextAppointmentCard extends ConsumerWidget {
  const NextAppointmentCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppAsyncView<RendezVous?>(
      compact: true,
      value: ref.watch(nextAppointmentProvider),
      onRetry: () => ref.invalidate(rendezVousControllerProvider),
      builder: (rdv) => rdv == null
          ? const _NoAppointmentContent()
          : _AppointmentContent(appointment: rdv),
    );
  }
}

class _NoAppointmentContent extends ConsumerWidget {
  const _NoAppointmentContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final universe = ref.watch(currentUniverseProvider);

    if (universe.isPsychologist) {
      return Card(
        color: scheme.primaryContainer,
        elevation: 0,
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.calendar_month_outlined, color: scheme.primary),
              AppSpacing.hGap12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aucun rendez-vous prévu',
                      style: AppTypography.texteSemiBold.copyWith(
                        color: scheme.primary,
                      ),
                    ),
                    AppSpacing.vGap4,
                    Text(
                      'Vous n\'avez pas de rendez-vous pour le moment.',
                      style: AppTypography.miniTexte.copyWith(
                        color: scheme.primary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.r16,
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: InkWell(
        onTap: () => context.go(AppRoutes.professionnels),
        borderRadius: AppRadii.r16,
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Icon(
                  Icons.calendar_month_outlined,
                  color: scheme.onSurface,
                ),
              ),
              AppSpacing.hGap16,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aucun rendez-vous prévu',
                      style: AppTypography.texteSemiBold,
                    ),
                    AppSpacing.vGap4,
                    Text(
                      'Prenez rendez-vous avec un professionnel pour être accompagné.',
                      style: AppTypography.miniTexte.copyWith(
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.hGap8,
              Icon(Icons.chevron_right, color: scheme.onSurface),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppointmentContent extends StatelessWidget {
  final RendezVous appointment;

  const _AppointmentContent({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        onTap: () => context.go(AppRoutes.rendezVous),
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
                      appointment.dateHeure.day.toString(),
                      style: AppTypography.petitTitre.copyWith(
                        color: scheme.primary,
                      ),
                    ),
                    Text(
                      DateFormat(
                        'MMM',
                        'fr_FR',
                      ).format(appointment.dateHeure).toUpperCase(),
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
                      appointment.professionnelDisplayName,
                      style: AppTypography.texteSemiBold,
                    ),
                    AppSpacing.vGap4,
                    Text(
                      DateFormat('HH:mm').format(appointment.dateHeure),
                      style: AppTypography.texteSecondaire,
                    ),
                    Text(
                      appointment.mode ?? 'Visio',
                      style: AppTypography.miniTexte,
                    ),
                    AppSpacing.vGap4,
                    Text(
                      appointment.statut.label,
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
