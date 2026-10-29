import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/user_message.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../data/models/contenu_model.dart';
import '../controllers/contenus_controller.dart';
import '../../../../core/l10n/app_strings.dart';

/// Lecture d'un article (univers Avocat) ou d'un conseil (univers Psychologue).
///
/// Si l'auteur désactive ou supprime la publication (même pendant la lecture),
/// l'API répond 404 et l'écran l'indique au lieu d'afficher une vieille copie.
class ContenuDetailScreen extends ConsumerWidget {
  final String contenuId;

  const ContenuDetailScreen({super.key, required this.contenuId});

  void _leave(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(publicationDetailProvider(contenuId));

    return detail.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(leading: const AppBackButton()),
        body: error is NotFoundException
            ? AppEmptyStateView(
                title: tr("Cette ressource n'est plus disponible"),
                message: tr("Elle a été retirée par son auteur."),
                icon: Icons.link_off_rounded,
                actionText: tr('Retour'),
                onAction: () => _leave(context),
              )
            : AppErrorStateView(
                message: userMessageFor(error),
                onRetry: () =>
                    ref.invalidate(publicationDetailProvider(contenuId)),
              ),
      ),
      data: (publication) {
        // Cloisonnement : un article juridique ne s'ouvre pas depuis l'univers
        // Psychologue (lien profond, notification), et inversement.
        final universe = ref.watch(currentUniverseProvider);
        if (publication.isArticle != universe.isLawyer) {
          return Scaffold(
            appBar: AppBar(leading: const AppBackButton()),
            body: AppEmptyStateView(
              title: tr('Publication d’un autre univers'),
              message: publication.isArticle
                  ? tr(
                      'Cet article appartient à l’univers Avocat. Changez d’univers pour le lire.',
                    )
                  : tr(
                      'Ce conseil appartient à l’univers Psychologue. Changez d’univers pour le lire.',
                    ),
              icon: Icons.swap_horiz_rounded,
              actionText: tr('Retour'),
              onAction: () => _leave(context),
            ),
          );
        }
        return _LecteurPublication(
          publication: publication,
          onQuit: () => _leave(context),
        );
      },
    );
  }
}

/// Hauteur de l'illustration en tête de lecture.
const _hauteurEnTete = 300.0;

/// Largeur maximale du texte : lignes confortables à lire, même sur tablette.
const _largeurLecture = 680.0;

/// Mise en page de lecture, commune aux articles et aux conseils :
/// illustration pleine largeur, titre et chapô, auteur, texte en caractères de
/// lecture (serif), accès aux autres publications de l'auteur en fin de lecture.
///
/// En lisant (défilement vers le bas), le bouton « Quitter » glisse hors de
/// l'écran au rythme du défilement ; il revient de la même façon dès qu'on
/// remonte, et toujours en fin de lecture. Une fine barre indique la
/// progression de la lecture une fois l'illustration dépassée.
class _LecteurPublication extends StatefulWidget {
  final Publication publication;
  final VoidCallback onQuit;

  const _LecteurPublication({required this.publication, required this.onQuit});

  @override
  State<_LecteurPublication> createState() => _LecteurPublicationState();
}

/// Défilement (en pixels) sur lequel le bouton « Quitter » sort entièrement.
const _courseBouton = 140.0;

class _LecteurPublicationState extends State<_LecteurPublication>
    with SingleTickerProviderStateMixin {
  final _progression = ValueNotifier<double>(0);

  /// 0 : bouton « Quitter » affiché ; 1 : entièrement sorti par le bas.
  late final _masquage = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  /// L'illustration est sortie de l'écran : barre du haut opaque avec le titre.
  bool _replie = false;

  @override
  void dispose() {
    _progression.dispose();
    _masquage.dispose();
    super.dispose();
  }

  void _afficherBouton() {
    if (_masquage.value == 0 || _masquage.status == AnimationStatus.reverse) {
      return;
    }
    _masquage.animateBack(0, curve: Curves.easeOutCubic);
  }

  bool _surDefilement(ScrollNotification notification) {
    if (notification.depth != 0) return false;
    final metrics = notification.metrics;
    final seuil =
        _hauteurEnTete - kToolbarHeight - MediaQuery.paddingOf(context).top;
    final replie = metrics.pixels > seuil;
    if (replie != _replie) setState(() => _replie = replie);

    final finAtteinte = metrics.extentAfter < 48;
    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0;
      if (finAtteinte || metrics.pixels <= 0) {
        _afficherBouton();
      } else if (delta != 0) {
        // Le bouton suit le défilement, sans à-coup ni seuil.
        _masquage.stop();
        _masquage.value = (_masquage.value + delta / _courseBouton).clamp(
          0.0,
          1.0,
        );
      }
    } else if (notification is ScrollEndNotification) {
      // Geste terminé : le bouton achève doucement son mouvement.
      if (finAtteinte) {
        _afficherBouton();
      } else if (_masquage.value > 0 && _masquage.value < 1) {
        _masquage.animateTo(
          _masquage.value >= 0.5 ? 1 : 0,
          curve: Curves.easeOutCubic,
        );
      }
    }
    _progression.value = metrics.maxScrollExtent <= 0
        ? 1
        : (metrics.pixels / metrics.maxScrollExtent).clamp(0.0, 1.0);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final pub = widget.publication;
    final palette = context.palette;
    final couleur = Theme.of(context).colorScheme.primary;
    final sombre = Theme.of(context).brightness == Brightness.dark;
    final premierPlan = _replie ? palette.textStrong : Colors.white;

    return Scaffold(
      backgroundColor: palette.card,
      body: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: _surDefilement,
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  stretch: true,
                  expandedHeight: _hauteurEnTete,
                  backgroundColor: palette.card,
                  surfaceTintColor: Colors.transparent,
                  foregroundColor: premierPlan,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  systemOverlayStyle: _replie && !sombre
                      ? SystemUiOverlayStyle.dark
                      : SystemUiOverlayStyle.light,
                  leading: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        // Pastille sombre : retour lisible sur toute image.
                        color: _replie
                            ? Colors.transparent
                            : Colors.black.withValues(alpha: 0.32),
                      ),
                      child: AppBackButton(
                        color: premierPlan,
                        onPressed: widget.onQuit,
                      ),
                    ),
                  ),
                  title: AnimatedOpacity(
                    opacity: _replie ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      pub.titre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.texteSemiBold.copyWith(
                        color: palette.textStrong,
                      ),
                    ),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.parallax,
                    stretchModes: const [StretchMode.zoomBackground],
                    background: _Illustration(publication: pub),
                  ),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(2),
                    child: AnimatedOpacity(
                      opacity: _replie ? 1 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: ValueListenableBuilder<double>(
                        valueListenable: _progression,
                        builder: (_, valeur, _) => LinearProgressIndicator(
                          value: valeur,
                          minHeight: 2,
                          color: couleur,
                          backgroundColor: palette.border,
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: _largeurLecture,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 140),
                        child: _Article(publication: pub, couleur: couleur),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedBuilder(
              animation: _masquage,
              builder: (context, bouton) => IgnorePointer(
                ignoring: _masquage.value > 0.5,
                child: FractionalTranslation(
                  key: const ValueKey('quitter-position'),
                  translation: Offset(0, _masquage.value),
                  child: Opacity(
                    opacity: 1 - Curves.easeIn.transform(_masquage.value),
                    child: bouton,
                  ),
                ),
              ),
              child: DecoratedBox(
                // Fondu vers le bas : le texte passe sous le bouton sans coupure nette.
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [palette.card.withValues(alpha: 0), palette.card],
                    stops: const [0, 0.45],
                  ),
                ),
                child: SafeArea(
                  top: false,
                  minimum: const EdgeInsets.fromLTRB(16, 28, 16, 16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: _largeurLecture,
                      ),
                      child: AppButton(
                        text: tr('Quitter'),
                        onPressed: widget.onQuit,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Illustration de tête, assombrie en haut (barre d'état lisible) ; sans image,
/// un fond à la couleur de l'univers avec le symbole du domaine.
class _Illustration extends StatelessWidget {
  final Publication publication;

  const _Illustration({required this.publication});

  @override
  Widget build(BuildContext context) {
    final couleur = Theme.of(context).colorScheme.primary;
    final url = publication.imageUrl;
    final sansImage = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [couleur, Color.lerp(couleur, Colors.black, 0.35)!],
        ),
      ),
      child: Align(
        alignment: const Alignment(0.85, 0.4),
        child: Icon(
          publication.isArticle
              ? Icons.gavel_rounded
              : Icons.psychology_alt_rounded,
          size: 150,
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        if (url == null || url.isEmpty)
          sansImage
        else
          Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => sansImage,
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.45),
                Colors.transparent,
                Colors.transparent,
                Colors.black.withValues(alpha: 0.12),
              ],
              stops: const [0, 0.35, 0.75, 1],
            ),
          ),
        ),
      ],
    );
  }
}

/// En-tête éditorial, texte et carte de l'auteur.
class _Article extends StatelessWidget {
  final Publication publication;
  final Color couleur;

  const _Article({required this.publication, required this.couleur});

  @override
  Widget build(BuildContext context) {
    final pub = publication;
    final palette = context.palette;
    final rubrique = [
      pub.isArticle ? tr('Article') : tr('Conseil'),
      ?pub.specialiteNom,
    ].join('  ·  ');
    final description = pub.description?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rubrique.toUpperCase(),
          style: AppTypography.badgeTexte.copyWith(
            color: couleur,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w700,
          ),
        ),
        AppSpacing.vGap12,
        Text(
          pub.titre,
          style: AppTypography.grandTitre.copyWith(
            fontSize: 26,
            height: 1.25,
            fontWeight: FontWeight.w800,
            color: palette.textStrong,
          ),
        ),
        if (description != null && description.isNotEmpty) ...[
          AppSpacing.vGap16,
          Text(
            description,
            style: GoogleFonts.sourceSerif4(
              fontSize: 18.5,
              height: 1.5,
              fontStyle: FontStyle.italic,
              color: palette.textMuted,
            ),
          ),
        ],
        AppSpacing.vGap24,
        _Signature(publication: pub),
        AppSpacing.vGap24,
        Divider(height: 1, color: palette.border),
        AppSpacing.vGap24,
        SelectionArea(
          child: _CorpsDeTexte(texte: pub.contenu ?? '', puce: couleur),
        ),
        AppSpacing.vGap32,
        Center(
          child: Text(
            '◆',
            style: TextStyle(
              color: couleur.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
        ),
        if (pub.auteurId != null) ...[
          AppSpacing.vGap32,
          // Même bouton que sur la fiche du professionnel.
          AppButton.outline(
            text: pub.isArticle
                ? tr('Voir ses autres articles')
                : tr('Voir ses autres conseils'),
            icon: pub.isArticle
                ? Icons.menu_book_outlined
                : Icons.lightbulb_outline_rounded,
            color: couleur,
            onPressed: () => context.push(
              AppRoutes.publicationsProfessionnel(pub.auteurId!),
              extra: pub.auteurDisplayName,
            ),
          ),
        ],
      ],
    );
  }
}

/// Auteur, métier, date de publication et temps de lecture.
class _Signature extends StatelessWidget {
  final Publication publication;

  const _Signature({required this.publication});

  @override
  Widget build(BuildContext context) {
    final pub = publication;
    final palette = context.palette;
    final minutes = pub.tempsLectureMinutes;
    final details = [
      if (pub.datePublication != null)
        Formatters.formatLongDate(pub.datePublication),
      if (minutes != null) tr('{n} min de lecture', {'n': minutes}),
    ].join('  ·  ');

    return Row(
      children: [
        if (pub.auteurDisplayName != null) ...[
          AppAvatar(
            name: pub.auteurDisplayName!,
            photoUrl: pub.auteurPhotoUrl,
            size: 44,
          ),
          AppSpacing.hGap12,
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (pub.auteurDisplayName != null)
                Text(
                  pub.auteurDisplayName!,
                  style: AppTypography.texteSemiBold.copyWith(
                    color: palette.textStrong,
                  ),
                ),
              if (details.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  details,
                  style: AppTypography.miniTexte.copyWith(
                    color: palette.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Texte saisi par l'auteur (texte brut) : paragraphes séparés par une ligne
/// vide ; les lignes commençant par « - », « * », « • » ou « 1. » deviennent
/// des listes à puces ou numérotées.
class _CorpsDeTexte extends StatelessWidget {
  final String texte;
  final Color puce;

  const _CorpsDeTexte({required this.texte, required this.puce});

  static final _ligneDeListe = RegExp(r'^\s*([-*•]|\d+[.)])\s+(.*)$');

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.sourceSerif4(
      fontSize: 17.5,
      height: 1.75,
      color: context.palette.text,
    );
    final blocs = <Widget>[];
    final paragraphes = texte
        .replaceAll('\r\n', '\n')
        .trim()
        .split(RegExp(r'\n\s*\n'));

    for (final paragraphe in paragraphes) {
      final lignes = <String>[];
      void viderLignes() {
        if (lignes.isEmpty) return;
        blocs.add(Text(lignes.join('\n'), style: style));
        lignes.clear();
      }

      for (final ligne in paragraphe.split('\n')) {
        final element = _ligneDeListe.firstMatch(ligne);
        if (element == null) {
          lignes.add(ligne.trim());
          continue;
        }
        viderLignes();
        final marque = element.group(1)!;
        blocs.add(
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 2, bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    RegExp(r'\d').hasMatch(marque) ? marque : '•',
                    style: style.copyWith(
                      color: puce,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(child: Text(element.group(2)!, style: style)),
              ],
            ),
          ),
        );
      }
      viderLignes();
      blocs.add(const SizedBox(height: 18));
    }
    if (blocs.isNotEmpty) blocs.removeLast();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocs,
    );
  }
}
