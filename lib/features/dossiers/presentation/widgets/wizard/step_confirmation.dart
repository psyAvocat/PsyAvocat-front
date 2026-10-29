import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../controllers/create_dossier_wizard_controller.dart';
import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/l10n/app_strings.dart';

/// Résultat de l'envoi : n'affiche que ce que le backend a réellement enregistré,
/// avec le détail d'éventuels échecs partiels, la suite du parcours et deux
/// sorties : suivre le dossier, ou « Terminé » (retour à l'accueil).
class StepConfirmationScreen extends ConsumerWidget {
  final Color primaryColor;

  const StepConfirmationScreen({super.key, required this.primaryColor});

  static const _vert = Color(0xFF16A34A);
  static const _orange = Color(0xFFEA580C);

  /// Quitte l'assistant (page posée par-dessus le routeur) puis navigue :
  /// le retour depuis la destination ne ramène jamais à cette confirmation.
  void _quitter(BuildContext context, WidgetRef ref, String destination) {
    final router = GoRouter.of(context);
    final notifier = ref.read(createDossierWizardProvider.notifier);
    Navigator.of(context).pop();
    router.go(destination);
    notifier.clear();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createDossierWizardProvider);
    final resultat = state.resultat;
    final complet = resultat?.complet ?? false;
    final couleur = complet ? _vert : _orange;
    final avocats = state.selectedProfessionnels
        .map((p) => p.displayName)
        .where((n) => !(resultat?.avocatsEnEchec.contains(n) ?? false))
        .toList();
    final pieces =
        state.piecesJointes.length - (resultat?.piecesEnEchec.length ?? 0);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _quitter(context, ref, AppRoutes.home);
      },
      child: Scaffold(
        backgroundColor: context.palette.page,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                  children: [
                    Center(
                      child: _Embleme(couleur: couleur, complet: complet),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      complet
                          ? tr('Dossier envoyé !')
                          : tr('Dossier créé, envoi incomplet'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: context.palette.textStrong,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      complet
                          ? tr(
                              'Les avocats sélectionnés ont été notifiés. Vous serez prévenu dès que l’un d’eux accepte votre dossier.',
                            )
                          : tr(
                              'Votre dossier « {titre} » est enregistré, mais certains éléments n’ont pas pu être transmis.',
                              {'titre': resultat?.dossier.titre ?? ''},
                            ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: context.palette.text,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _Carte(
                      children: [
                        _Info(
                          icone: Icons.folder_outlined,
                          couleur: primaryColor,
                          titre: resultat?.dossier.titre ?? state.titre,
                          detail: state.domaine?.nom,
                        ),
                        _Info(
                          icone: Icons.gavel_rounded,
                          couleur: primaryColor,
                          titre: avocats.length > 1
                              ? tr('Transmis à {n} avocats', {
                                  'n': avocats.length,
                                })
                              : tr('Transmis à {n} avocat', {
                                  'n': avocats.length,
                                }),
                          detail: avocats.isEmpty ? null : avocats.join(', '),
                        ),
                        _Info(
                          icone: Icons.attach_file_rounded,
                          couleur: primaryColor,
                          titre: pieces > 1
                              ? tr('{n} pièces jointes', {'n': pieces})
                              : tr('{n} pièce jointe', {'n': pieces}),
                          dernier: true,
                        ),
                      ],
                    ),
                    if (resultat != null &&
                        resultat.avocatsEnEchec.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _Liste(
                        titre: tr('Non transmis à'),
                        elements: resultat.avocatsEnEchec,
                      ),
                    ],
                    if (resultat != null &&
                        resultat.piecesEnEchec.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _Liste(
                        titre: tr('Pièces non enregistrées'),
                        elements: resultat.piecesEnEchec,
                      ),
                    ],
                    const SizedBox(height: 16),
                    _Carte(
                      children: [
                        Text(
                          tr('Et maintenant ?'),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: context.palette.textStrong,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _Etape(
                          numero: 1,
                          couleur: primaryColor,
                          texte: tr(
                            'Les avocats examinent votre dossier et ses pièces.',
                          ),
                        ),
                        _Etape(
                          numero: 2,
                          couleur: primaryColor,
                          texte: tr(
                            'Vous recevez une notification dès qu’un avocat l’accepte, avec ses honoraires.',
                          ),
                        ),
                        _Etape(
                          numero: 3,
                          couleur: primaryColor,
                          texte: tr(
                            'Vous choisissez un créneau dans son agenda pour votre rendez-vous.',
                          ),
                          dernier: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                color: context.palette.page,
                child: Column(
                  children: [
                    if (resultat != null)
                      AppButton(
                        text: tr('Suivre mon dossier'),
                        icon: Icons.folder_open_rounded,
                        color: primaryColor,
                        onPressed: () => _quitter(
                          context,
                          ref,
                          AppRoutes.dossier(resultat.dossier.id),
                        ),
                      ),
                    const SizedBox(height: 10),
                    AppButton(
                      text: tr('Terminé'),
                      isOutlined: true,
                      color: primaryColor,
                      onPressed: () => _quitter(context, ref, AppRoutes.home),
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

/// Pastille animée (apparition en douceur) avec un halo.
class _Embleme extends StatelessWidget {
  final Color couleur;
  final bool complet;

  const _Embleme({required this.couleur, required this.complet});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      builder: (context, echelle, child) =>
          Transform.scale(scale: echelle, child: child),
      child: Container(
        width: 128,
        height: 128,
        decoration: BoxDecoration(
          color: couleur.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            color: couleur.withValues(alpha: 0.16),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: couleur, shape: BoxShape.circle),
            child: Icon(
              complet ? Icons.check_rounded : Icons.priority_high_rounded,
              size: 38,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _Carte extends StatelessWidget {
  final List<Widget> children;
  const _Carte({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final IconData icone;
  final Color couleur;
  final String titre;
  final String? detail;
  final bool dernier;

  const _Info({
    required this.icone,
    required this.couleur,
    required this.titre,
    this.detail,
    this.dernier = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: dernier ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: couleur.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icone, size: 18, color: couleur),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titre,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.palette.textStrong,
                  ),
                ),
                if (detail != null && detail!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    detail!,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: context.palette.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Etape extends StatelessWidget {
  final int numero;
  final Color couleur;
  final String texte;
  final bool dernier;

  const _Etape({
    required this.numero,
    required this.couleur,
    required this.texte,
    this.dernier = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: dernier ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: couleur.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$numero',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: couleur,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                texte,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: context.palette.text,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Liste extends StatelessWidget {
  final String titre;
  final List<String> elements;
  const _Liste({required this.titre, required this.elements});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titre,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF7C2D12),
            ),
          ),
          const SizedBox(height: 6),
          ...elements.map(
            (e) =>
                Text('• $e', style: const TextStyle(color: Color(0xFF7C2D12))),
          ),
        ],
      ),
    );
  }
}
