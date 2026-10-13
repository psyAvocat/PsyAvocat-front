import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../shared/enums/appointment_status.dart';
import '../../../orientation/data/models/questionnaire_model.dart';
import '../../../orientation/presentation/controllers/orientation_controller.dart';
import '../../../rendez_vous/data/models/rendez_vous_model.dart';
import '../../../rendez_vous/presentation/controllers/rendez_vous_controller.dart';
import '../controllers/profil_controller.dart';
import '../widgets/profile_menu.dart';
import '../../../../core/l10n/app_strings.dart';

/// « Fiche patient » (univers Psychologue) : ce que le client sait de son
/// suivi — identité, résultats du questionnaire d'orientation et séances
/// avec les psychologues. Les notes de séance restent privées au psychologue.
class FichePatientScreen extends ConsumerWidget {
  const FichePatientScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final couleur = Theme.of(context).colorScheme.primary;
    final profil = ref.watch(currentProfilProvider).value;
    final resultats = ref.watch(mesResultatsProvider);
    final seances = ref.watch(rendezVousControllerProvider);

    return Scaffold(
      backgroundColor: context.palette.card,
      appBar: AppPageHeader(title: tr('Fiche patient')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(mesResultatsProvider);
          await ref.read(rendezVousControllerProvider.notifier).reload();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          children: [
            ProfileSectionTitle(tr('Identité')),
            _Carte(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profil?.nomComplet ?? '—',
                    style: AppTypography.texteSemiBold.copyWith(fontSize: 16),
                  ),
                  if (profil?.telephone != null) ...[
                    AppSpacing.vGap4,
                    Text(
                      profil!.telephone!,
                      style: AppTypography.texteSecondaire,
                    ),
                  ],
                  if (profil?.email.isNotEmpty == true) ...[
                    AppSpacing.vGap4,
                    Text(profil!.email, style: AppTypography.texteSecondaire),
                  ],
                ],
              ),
            ),
            ProfileSectionTitle(tr('Questionnaire d’orientation')),
            resultats.when(
              loading: () => const _Chargement(),
              error: (_, _) => _Message(
                tr('Vos résultats ne peuvent pas être chargés pour le moment.'),
              ),
              data: (liste) => liste.isEmpty
                  ? _Carte(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            tr(
                              'Vous n’avez pas encore répondu au questionnaire. '
                              'Il aide à préciser votre besoin (ce n’est pas un diagnostic).',
                            ),
                            style: AppTypography.texteSecondaire,
                          ),
                          AppSpacing.vGap12,
                          AppButton.outline(
                            text: tr('Répondre au questionnaire'),
                            color: couleur,
                            onPressed: () =>
                                context.push(AppRoutes.orientation),
                          ),
                        ],
                      ),
                    )
                  : _Resultat(resultat: liste.first, couleur: couleur),
            ),
            ProfileSectionTitle(tr('Mes séances')),
            seances.when(
              loading: () => const _Chargement(),
              error: (_, _) => _Message(
                tr('Vos séances ne peuvent pas être chargées pour le moment.'),
              ),
              data: (liste) {
                final psy =
                    liste.where((r) => r.typeProfessionnel != 'AVOCAT').toList()
                      ..sort((a, b) => b.dateHeure.compareTo(a.dateHeure));
                if (psy.isEmpty) {
                  return _Message(
                    tr(
                      'Aucune séance pour le moment. Réservez un créneau depuis '
                      'la fiche d’un psychologue.',
                    ),
                  );
                }
                return Column(
                  children: [for (final rdv in psy.take(10)) _Seance(rdv: rdv)],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Carte extends StatelessWidget {
  final Widget child;

  const _Carte({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.palette.border),
      ),
      child: child,
    );
  }
}

class _Chargement extends StatelessWidget {
  const _Chargement();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(16),
    child: Center(child: CircularProgressIndicator()),
  );
}

class _Message extends StatelessWidget {
  final String texte;

  const _Message(this.texte);

  @override
  Widget build(BuildContext context) =>
      _Carte(child: Text(texte, style: AppTypography.texteSecondaire));
}

class _Resultat extends StatelessWidget {
  final ResultatOrientationModel resultat;
  final Color couleur;

  const _Resultat({required this.resultat, required this.couleur});

  @override
  Widget build(BuildContext context) {
    final scores = [...resultat.scoresParCategorie]
      ..sort((a, b) => b.score.compareTo(a.score));
    final max = scores.isEmpty ? 0 : scores.first.score;
    return _Carte(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (resultat.dateEvaluation != null)
            Text(
              tr('Répondu le {date}', {
                'date': Formatters.formatLongDate(resultat.dateEvaluation),
              }),
              style: AppTypography.miniTexte.copyWith(
                color: context.palette.textMuted,
              ),
            ),
          if (resultat.mainLabel != null) ...[
            AppSpacing.vGap8,
            Text(
              resultat.mainLabel!,
              style: AppTypography.texteSemiBold.copyWith(
                fontSize: 16,
                color: couleur,
              ),
            ),
          ],
          for (final score in scores.take(3)) ...[
            AppSpacing.vGap12,
            Text(score.nom, style: AppTypography.texte.copyWith(fontSize: 13)),
            AppSpacing.vGap4,
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: max == 0 ? 0 : score.score / max,
                minHeight: 6,
                color: couleur,
                backgroundColor: couleur.withValues(alpha: 0.12),
              ),
            ),
          ],
          AppSpacing.vGap12,
          Align(
            alignment: Alignment.centerRight,
            child: AppButton.ghost(
              text: tr('Refaire le questionnaire'),
              color: couleur,
              size: AppButtonSize.compact,
              onPressed: () => context.push(AppRoutes.orientation),
            ),
          ),
        ],
      ),
    );
  }
}

class _Seance extends StatelessWidget {
  final RendezVous rdv;

  const _Seance({required this.rdv});

  @override
  Widget build(BuildContext context) {
    final phase = rdv.phaseAt(DateTime.now());
    final libelle = switch (rdv.statut) {
      AppointmentStatus.confirme || AppointmentStatus.enAttente => phase.label,
      _ => rdv.statut.label,
    };
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.palette.border)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.event_note_outlined,
            size: 20,
            color: context.palette.textMuted,
          ),
          AppSpacing.hGap12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rdv.professionnelDisplayName,
                  style: AppTypography.texteMedium.copyWith(fontSize: 14),
                ),
                Text(
                  Formatters.formatDateHeure(rdv.dateHeure),
                  style: AppTypography.miniTexte.copyWith(
                    color: context.palette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            libelle,
            style: AppTypography.miniTexte.copyWith(
              color: context.palette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
