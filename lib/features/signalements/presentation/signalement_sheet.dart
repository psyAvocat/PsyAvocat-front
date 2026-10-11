import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/user_message.dart';
import '../../../core/widgets/app_button.dart';
import '../data/signalement_repository.dart';

/// Ouvre la feuille de signalement d'un professionnel.
/// Renvoie `true` si le signalement a été enregistré par le backend.
Future<bool?> showSignalementSheet(
  BuildContext context, {
  required String professionnelId,
  required String professionnelNom,
  required Color primaryColor,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _SignalementSheet(
      professionnelId: professionnelId,
      professionnelNom: professionnelNom,
      primaryColor: primaryColor,
    ),
  );
}

class _SignalementSheet extends ConsumerStatefulWidget {
  final String professionnelId;
  final String professionnelNom;
  final Color primaryColor;

  const _SignalementSheet({
    required this.professionnelId,
    required this.professionnelNom,
    required this.primaryColor,
  });

  @override
  ConsumerState<_SignalementSheet> createState() => _SignalementSheetState();
}

class _SignalementSheetState extends ConsumerState<_SignalementSheet> {
  /// Longueur minimale de description pour le motif « Autre » (identique au backend).
  static const _minDescriptionAutre = 10;

  MotifSignalement? _motif;
  final _description = TextEditingController();
  bool _envoi = false;
  String? _erreur;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  bool get _valide {
    final motif = _motif;
    if (motif == null) return false;
    return !motif.exigeDescription ||
        _description.text.trim().length >= _minDescriptionAutre;
  }

  Future<void> _envoyer() async {
    if (!_valide || _envoi) return;
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await ref
          .read(signalementRepositoryProvider)
          .signaler(
            professionnelId: widget.professionnelId,
            motif: _motif!.code,
            description: _description.text,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _envoi = false;
          _erreur = userMessageFor(error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final motifsAsync = ref.watch(motifsSignalementProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(height: 16),
            Text(
              'Signaler ${widget.professionnelNom}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Votre signalement est transmis à l’équipe PsyAvocat, qui l’examine en toute confidentialité.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            motifsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Row(
                children: [
                  Expanded(
                    child: Text(
                      userMessageFor(e),
                      style: const TextStyle(color: Color(0xFFDC2626)),
                    ),
                  ),
                  AppButton.ghost(
                    text: 'Réessayer',
                    onPressed: () => ref.invalidate(motifsSignalementProvider),
                  ),
                ],
              ),
              data: (motifs) => RadioGroup<String>(
                groupValue: _motif?.code,
                onChanged: (code) => setState(
                  () => _motif = motifs.firstWhere((m) => m.code == code),
                ),
                child: Column(
                  children: motifs
                      .map(
                        (m) => RadioListTile<String>(
                          value: m.code,
                          activeColor: widget.primaryColor,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text(m.libelle),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _description,
              maxLines: 4,
              maxLength: 1000,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: _motif?.exigeDescription == true
                    ? 'Décrivez la situation *'
                    : 'Précisions (facultatif)',
                helperText: _motif?.exigeDescription == true
                    ? '$_minDescriptionAutre caractères minimum'
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            if (_erreur != null) ...[
              const SizedBox(height: 8),
              Text(_erreur!, style: const TextStyle(color: Color(0xFFDC2626))),
            ],
            const SizedBox(height: 16),
            AppButton(
              text: 'Envoyer le signalement',
              isLoading: _envoi,
              onPressed: _valide && !_envoi ? _envoyer : null,
              color: widget.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
