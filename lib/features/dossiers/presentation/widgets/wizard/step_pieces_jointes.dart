import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../controllers/create_dossier_wizard_controller.dart';
import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/l10n/app_strings.dart';

/// Étape 3 : pièces du dossier, photographiées directement ou choisies sur
/// l'appareil, puis déposées dans le stockage privé du backend lors de l'envoi
/// (formats acceptés par le serveur).
class StepPiecesJointes extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  final Color primaryColor;

  const StepPiecesJointes({
    super.key,
    required this.onNext,
    required this.onBack,
    required this.primaryColor,
  });

  @override
  ConsumerState<StepPiecesJointes> createState() => _StepPiecesJointesState();
}

class _StepPiecesJointesState extends ConsumerState<StepPiecesJointes> {
  /// Extensions acceptées par le backend (PDF, images, Word).
  static const _extensions = ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'];

  bool _selection = false;

  Future<void> _choisir() async {
    setState(() => _selection = true);
    try {
      final fichiers = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: _extensions,
      );
      final notifier = ref.read(createDossierWizardProvider.notifier);
      for (final f in fichiers) {
        final bytes = await f.readAsBytes();
        final erreur = notifier.addPieceJointe(
          PieceAJoindre(nom: f.name, bytes: bytes),
        );
        if (erreur != null && mounted) _message(erreur);
      }
    } catch (_) {
      if (mounted) {
        _message(tr('Impossible d’accéder à ce fichier. Réessayez.'));
      }
    } finally {
      if (mounted) setState(() => _selection = false);
    }
  }

  /// Photo prise avec l'appareil : compressée en JPEG (lisible, sous 10 Mo).
  Future<void> _photographier() async {
    setState(() => _selection = true);
    try {
      final photo = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 2400,
        maxHeight: 2400,
      );
      if (photo == null) return;
      final bytes = await photo.readAsBytes();
      final nom =
          'photo_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.jpg';
      final erreur = ref
          .read(createDossierWizardProvider.notifier)
          .addPieceJointe(PieceAJoindre(nom: nom, bytes: bytes));
      if (!mounted) return;
      if (erreur != null) {
        _message(erreur);
      } else if (ref.read(createDossierWizardProvider).piecesJointes.length <
          maxPiecesJointes) {
        _message(
          tr('Photo ajoutée au dossier.'),
          action: SnackBarAction(
            label: tr('Autre photo'),
            onPressed: _photographier,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        _message(
          tr(
            'Impossible d’ouvrir l’appareil photo. Vérifiez l’autorisation dans les réglages du téléphone.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _selection = false);
    }
  }

  void _message(String texte, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(texte),
          action: action,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final pieces = ref.watch(createDossierWizardProvider).piecesJointes;
    final primaryColor = widget.primaryColor;
    final complet = pieces.length >= maxPiecesJointes;
    final actif = !_selection && !complet;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              Text(
                tr('Ajouter les pièces du dossier'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: context.palette.textStrong,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tr(
                  'Joignez les documents utiles (contrat, courrier, décision, photo…). '
                  'Ils ne sont visibles que par vous et les avocats destinataires.',
                ),
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: context.palette.textMuted,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _Source(
                      icone: Icons.photo_camera_outlined,
                      titre: tr('Prendre une photo'),
                      sousTitre: tr('Document papier'),
                      couleur: primaryColor,
                      onTap: actif ? _photographier : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Source(
                      icone: Icons.upload_file_rounded,
                      titre: tr('Importer un fichier'),
                      sousTitre: tr('PDF, image, Word'),
                      couleur: primaryColor,
                      onTap: actif ? _choisir : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_selection)
                const LinearProgressIndicator(minHeight: 2)
              else
                Text(
                  complet
                      ? tr('Nombre maximal de documents atteint.')
                      : tr(
                          'PDF, JPG, PNG, DOC, DOCX — 10 Mo maximum par fichier',
                        ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.palette.textMuted,
                  ),
                ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 18,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        tr(
                          'Astuce : photographiez le document à plat, en entier et bien éclairé, une page par photo.',
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: context.palette.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text(
                tr('Documents ajoutés ({n}/{max})', {
                  'n': pieces.length,
                  'max': maxPiecesJointes,
                }),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: context.palette.textStrong,
                ),
              ),
              const SizedBox(height: 12),
              if (pieces.isEmpty)
                Text(
                  tr(
                    'Aucun document pour le moment. Cette étape est facultative.',
                  ),
                  style: TextStyle(
                    fontSize: 13,
                    color: context.palette.textSubtle,
                  ),
                ),
              ...pieces.map(
                (p) => _PieceAjoutee(
                  piece: p,
                  couleur: primaryColor,
                  onRetirer: () => ref
                      .read(createDossierWizardProvider.notifier)
                      .removePieceJointe(p),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.palette.card,
            boxShadow: [
              BoxShadow(
                color: Color(0x0A000000),
                offset: Offset(0, -4),
                blurRadius: 10,
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: tr('Retour'),
                    onPressed: widget.onBack,
                    isOutlined: true,
                    textColor: context.palette.textStrong,
                    color: context.palette.border,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    text: pieces.isEmpty ? tr('Passer') : tr('Suivant'),
                    onPressed: widget.onNext,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Source d'une pièce : appareil photo ou fichier.
class _Source extends StatelessWidget {
  final IconData icone;
  final String titre;
  final String sousTitre;
  final Color couleur;
  final VoidCallback? onTap;

  const _Source({
    required this.icone,
    required this.titre,
    required this.sousTitre,
    required this.couleur,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final actif = onTap != null;
    return Material(
      color: context.palette.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: couleur.withValues(alpha: actif ? 0.45 : 0.15),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: couleur.withValues(alpha: actif ? 0.1 : 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icone,
                  size: 24,
                  color: actif ? couleur : context.palette.textSubtle,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                titre,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: actif ? couleur : context.palette.textSubtle,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sousTitre,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: context.palette.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pièce ajoutée : miniature pour une image, icône selon le type sinon.
class _PieceAjoutee extends StatelessWidget {
  final PieceAJoindre piece;
  final Color couleur;
  final VoidCallback onRetirer;

  const _PieceAjoutee({
    required this.piece,
    required this.couleur,
    required this.onRetirer,
  });

  String get _extension {
    final i = piece.nom.lastIndexOf('.');
    return i < 0 ? '' : piece.nom.substring(i + 1).toLowerCase();
  }

  bool get _estImage => const {'jpg', 'jpeg', 'png'}.contains(_extension);

  String _taille(int octets) {
    if (octets >= 1024 * 1024) {
      return tr('{n} Mo', {'n': (octets / (1024 * 1024)).toStringAsFixed(1)});
    }
    return tr('{n} Ko', {'n': (octets / 1024).ceil()});
  }

  @override
  Widget build(BuildContext context) {
    final icone = switch (_extension) {
      'pdf' => Icons.picture_as_pdf_outlined,
      'doc' || 'docx' => Icons.description_outlined,
      _ => Icons.insert_drive_file_outlined,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
      decoration: BoxDecoration(
        color: context.palette.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.palette.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 44,
              height: 44,
              child: _estImage
                  ? Image.memory(
                      piece.bytes,
                      fit: BoxFit.cover,
                      cacheWidth: 120,
                      errorBuilder: (_, _, _) =>
                          Icon(Icons.image_outlined, color: couleur),
                    )
                  : ColoredBox(
                      color: couleur.withValues(alpha: 0.08),
                      child: Icon(icone, color: couleur),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  piece.nom,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.palette.textStrong,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _taille(piece.taille),
                  style: TextStyle(
                    fontSize: 12,
                    color: context.palette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: tr('Retirer'),
            icon: Icon(Icons.close_rounded, color: context.palette.textMuted),
            onPressed: onRetirer,
          ),
        ],
      ),
    );
  }
}
