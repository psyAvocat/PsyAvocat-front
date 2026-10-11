import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../controllers/create_dossier_wizard_controller.dart';

/// Étape 3 : pièces du dossier, choisies sur l'appareil puis déposées dans le
/// stockage privé du backend lors de l'envoi (formats acceptés par le serveur).
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
        final erreur = notifier.addPieceJointe(PieceAJoindre(nom: f.name, bytes: bytes));
        if (erreur != null && mounted) _message(erreur);
      }
    } catch (_) {
      if (mounted) _message('Impossible d’accéder à ce fichier. Réessayez.');
    } finally {
      if (mounted) setState(() => _selection = false);
    }
  }

  void _message(String texte) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texte), behavior: SnackBarBehavior.floating),
    );
  }

  String _taille(int octets) {
    if (octets >= 1024 * 1024) return '${(octets / (1024 * 1024)).toStringAsFixed(1)} Mo';
    return '${(octets / 1024).ceil()} Ko';
  }

  @override
  Widget build(BuildContext context) {
    final pieces = ref.watch(createDossierWizardProvider).piecesJointes;
    final primaryColor = widget.primaryColor;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              const Text(
                'Ajouter les pièces du dossier',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Joignez les documents utiles (contrat, courrier, décision, photo…). '
                'Ils ne sont visibles que par vous et les avocats destinataires.',
                style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 24),
              InkWell(
                onTap: _selection || pieces.length >= maxPiecesJointes ? null : _choisir,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryColor.withValues(alpha: 0.5), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      _selection
                          ? const SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 3))
                          : Icon(Icons.cloud_upload_outlined, size: 40, color: primaryColor),
                      const SizedBox(height: 12),
                      Text(
                        'Choisir des fichiers',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: primaryColor),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'PDF, JPG, PNG, DOC, DOCX — 10 Mo maximum par fichier',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Documents ajoutés (${pieces.length}/$maxPiecesJointes)',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
              ),
              const SizedBox(height: 12),
              if (pieces.isEmpty)
                const Text(
                  'Aucun document pour le moment. Cette étape est facultative.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                ),
              ...pieces.map(
                (p) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.insert_drive_file_outlined, color: primaryColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.nom, maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            Text(_taille(p.taille), style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Retirer',
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF6B7280)),
                        onPressed: () => ref.read(createDossierWizardProvider.notifier).removePieceJointe(p),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Color(0x0A000000), offset: Offset(0, -4), blurRadius: 10)],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Retour',
                    onPressed: widget.onBack,
                    isOutlined: true,
                    textColor: const Color(0xFF111827),
                    color: const Color(0xFFE5E7EB),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: AppButton(text: 'Suivant', onPressed: widget.onNext, color: primaryColor)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
