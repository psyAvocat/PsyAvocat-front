import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../widgets/profile_menu.dart';
import '../../../../core/l10n/app_strings.dart';

/// Question fréquente : la réponse décrit le fonctionnement réel de l'app.
typedef _Faq = ({String question, String reponse});

const _questionsGenerales = <_Faq>[
  (
    question: 'Comment changer d’espace (Avocat / Psychologue) ?',
    reponse:
        'Ouvrez Profil > Paramètres, puis « Passer à l’espace … ». Votre compte '
        'est le même dans les deux espaces.',
  ),
  (
    question: 'Comment modifier mes informations ?',
    reponse:
        'Ouvrez Profil > Informations personnelles. Vous pouvez modifier votre '
        'nom, votre prénom, votre téléphone et votre photo. L’adresse e-mail '
        'est votre identifiant de connexion : elle ne peut pas être modifiée.',
  ),
  (
    question: 'Comment gérer les notifications ?',
    reponse:
        'Ouvrez Profil > Paramètres et activez ou désactivez « Notifications ». '
        'Le réglage s’applique à cet appareil.',
  ),
  (
    question: 'Où retrouver mes paiements et mes messages ?',
    reponse:
        'Vos messages sont dans Profil > Messagerie, et vos paiements dans '
        'Profil > Paramètres > Mes paiements.',
  ),
  (
    question: 'Comment changer le thème ou la langue ?',
    reponse:
        'Ouvrez Profil > Paramètres, puis « Thème » (clair, sombre ou comme le '
        'téléphone) ou « Langue » (français ou anglais).',
  ),
];

const _questionsAvocat = <_Faq>[
  (
    question: 'Comment consulter un avocat ?',
    reponse:
        'Créez un dossier depuis « Mes dossiers », joignez vos documents et '
        'envoyez-le aux avocats de votre choix. Chaque avocat accepte ou '
        'décline et indique ses honoraires.',
  ),
  (
    question: 'Comment choisir l’avocat qui suivra mon dossier ?',
    reponse:
        'Dans le détail du dossier, appuyez sur « Accepter » sous l’avocat '
        'retenu, puis choisissez un créneau. Le dossier lui est alors confié.',
  ),
  (
    question: 'Qui peut voir mes pièces jointes ?',
    reponse:
        'Vos documents sont stockés en accès privé et ouverts par des liens '
        'temporaires. Seuls vous et les avocats à qui vous avez envoyé le '
        'dossier y ont accès ; une fois le dossier confié à l’un d’eux, les '
        'autres n’y ont plus accès.',
  ),
];

const _questionsPsychologue = <_Faq>[
  (
    question: 'Comment prendre rendez-vous avec un psychologue ?',
    reponse:
        'Ouvrez la fiche d’un psychologue, choisissez un tarif puis un créneau '
        'disponible et confirmez la réservation.',
  ),
  (
    question: 'À quoi sert le questionnaire ?',
    reponse:
        'Il est facultatif : il aide à préciser votre besoin pour vous orienter '
        'vers les bons professionnels. Ce n’est pas un diagnostic. Vos résultats '
        'sont visibles dans Profil > Fiche patient.',
  ),
];

/// « Aide et support » : questions fréquentes de l'espace courant.
class HelpSupportScreen extends ConsumerWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final universe = ref.watch(currentUniverseProvider);
    final couleur = Theme.of(context).colorScheme.primary;
    final questionsEspace = universe.isPsychologist
        ? _questionsPsychologue
        : _questionsAvocat;

    return Scaffold(
      backgroundColor: context.palette.card,
      appBar: AppPageHeader(title: tr('Aide et support')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        children: [
          ProfileSectionTitle(
            universe.isPsychologist
                ? tr('Espace Psychologue')
                : tr('Espace Avocat'),
          ),
          for (final faq in questionsEspace)
            _FaqTile(faq: faq, couleur: couleur),
          ProfileSectionTitle(tr('Mon compte')),
          for (final faq in _questionsGenerales)
            _FaqTile(faq: faq, couleur: couleur),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final _Faq faq;
  final Color couleur;

  const _FaqTile({required this.faq, required this.couleur});

  @override
  Widget build(BuildContext context) {
    return Theme(
      // Pas de lignes de séparation ajoutées par ExpansionTile.
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: context.palette.border)),
        ),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 14),
          iconColor: couleur,
          expandedAlignment: Alignment.centerLeft,
          title: Text(
            tr(faq.question),
            style: AppTypography.texteMedium.copyWith(
              fontSize: 15,
              color: context.palette.textStrong,
            ),
          ),
          children: [
            Text(
              tr(faq.reponse),
              style: AppTypography.texteSecondaire.copyWith(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
