import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/user_message.dart';
import '../../../../features/professionnels/data/models/professionnel_summary.dart';
import '../../../referentiels/data/models/specialite_option.dart';
import '../../data/models/dossier_model.dart';
import '../../data/repositories/dossier_repository.dart';
import 'dossiers_controller.dart';

/// Fichier choisi par le justiciable, envoyé au backend après création du dossier.
class PieceAJoindre {
  final String nom;
  final Uint8List bytes;

  const PieceAJoindre({required this.nom, required this.bytes});

  int get taille => bytes.length;
}

/// Étapes de l'envoi réel au backend (affichées pendant la validation).
enum EnvoiDossierEtape {
  inactif,
  creation,
  piecesJointes,
  soumissions,
  termine,
}

/// Résultat de l'envoi : le dossier créé et les éventuels échecs partiels.
class EnvoiDossierResultat {
  final DossierModel dossier;
  final List<String> avocatsEnEchec;
  final List<String> piecesEnEchec;

  const EnvoiDossierResultat({
    required this.dossier,
    this.avocatsEnEchec = const [],
    this.piecesEnEchec = const [],
  });

  bool get complet => avocatsEnEchec.isEmpty && piecesEnEchec.isEmpty;
}

class CreateDossierWizardState {
  final List<ProfessionnelSummary> selectedProfessionnels;
  final String titre;
  final SpecialiteOption? domaine;
  final String description;
  final List<PieceAJoindre> piecesJointes;
  final EnvoiDossierEtape etape;
  final String? erreur;
  final EnvoiDossierResultat? resultat;

  const CreateDossierWizardState({
    this.selectedProfessionnels = const [],
    this.titre = '',
    this.domaine,
    this.description = '',
    this.piecesJointes = const [],
    this.etape = EnvoiDossierEtape.inactif,
    this.erreur,
    this.resultat,
  });

  bool get envoiEnCours =>
      etape != EnvoiDossierEtape.inactif && etape != EnvoiDossierEtape.termine;

  CreateDossierWizardState copyWith({
    List<ProfessionnelSummary>? selectedProfessionnels,
    String? titre,
    SpecialiteOption? domaine,
    bool clearDomaine = false,
    String? description,
    List<PieceAJoindre>? piecesJointes,
    EnvoiDossierEtape? etape,
    String? erreur,
    bool clearErreur = false,
    EnvoiDossierResultat? resultat,
  }) {
    return CreateDossierWizardState(
      selectedProfessionnels:
          selectedProfessionnels ?? this.selectedProfessionnels,
      titre: titre ?? this.titre,
      domaine: clearDomaine ? null : (domaine ?? this.domaine),
      description: description ?? this.description,
      piecesJointes: piecesJointes ?? this.piecesJointes,
      etape: etape ?? this.etape,
      erreur: clearErreur ? null : (erreur ?? this.erreur),
      resultat: resultat ?? this.resultat,
    );
  }
}

/// Nombre maximal de pièces jointes (même limite que le backend).
const maxPiecesJointes = 10;

/// Taille maximale d'un document (même limite que le backend : 10 Mo).
const maxTaillePieceJointe = 10 * 1024 * 1024;

class CreateDossierWizardNotifier extends Notifier<CreateDossierWizardState> {
  @override
  CreateDossierWizardState build() {
    return const CreateDossierWizardState();
  }

  void toggleProfessionnel(ProfessionnelSummary pro) {
    final current = List<ProfessionnelSummary>.from(
      state.selectedProfessionnels,
    );
    if (current.any((p) => p.id == pro.id)) {
      current.removeWhere((p) => p.id == pro.id);
    } else {
      current.add(pro);
    }
    state = state.copyWith(selectedProfessionnels: current);
  }

  /// Avocat présélectionné depuis sa fiche (« Soumettre un dossier »).
  void preselectionner(ProfessionnelSummary pro) {
    state = CreateDossierWizardState(selectedProfessionnels: [pro]);
  }

  void updateInformations({
    required String titre,
    required SpecialiteOption? domaine,
    required String description,
  }) {
    state = state.copyWith(
      titre: titre,
      domaine: domaine,
      clearDomaine: domaine == null,
      description: description,
    );
  }

  /// Ajoute un fichier ; renvoie un message d'erreur s'il est refusé.
  String? addPieceJointe(PieceAJoindre piece) {
    if (state.piecesJointes.length >= maxPiecesJointes) {
      return 'Vous pouvez joindre au maximum $maxPiecesJointes documents.';
    }
    if (piece.taille > maxTaillePieceJointe) {
      return '« ${piece.nom} » dépasse la taille maximale de 10 Mo.';
    }
    if (state.piecesJointes.any((p) => p.nom == piece.nom)) {
      return '« ${piece.nom} » est déjà joint.';
    }
    state = state.copyWith(piecesJointes: [...state.piecesJointes, piece]);
    return null;
  }

  void removePieceJointe(PieceAJoindre piece) {
    state = state.copyWith(
      piecesJointes: state.piecesJointes.where((p) => p != piece).toList(),
    );
  }

  /// Envoi réel : création du dossier, dépôt des pièces (bucket privé),
  /// puis soumission à chaque avocat sélectionné. Un échec partiel est
  /// signalé précisément ; rien n'est simulé.
  Future<EnvoiDossierResultat?> envoyer() async {
    if (state.envoiEnCours) return null;
    final repo = ref.read(dossierRepositoryProvider);
    state = state.copyWith(
      etape: EnvoiDossierEtape.creation,
      clearErreur: true,
    );

    final DossierModel dossier;
    try {
      dossier = await repo.createDossier(
        titre: state.titre,
        description: state.description,
        specialiteId: state.domaine?.id,
      );
    } catch (error) {
      state = state.copyWith(
        etape: EnvoiDossierEtape.inactif,
        erreur: userMessageFor(error),
      );
      return null;
    }

    state = state.copyWith(etape: EnvoiDossierEtape.piecesJointes);
    final piecesEnEchec = <String>[];
    for (final piece in state.piecesJointes) {
      try {
        await repo.ajouterPieceJointe(
          dossierId: dossier.id,
          nom: piece.nom,
          bytes: piece.bytes,
        );
      } catch (_) {
        piecesEnEchec.add(piece.nom);
      }
    }

    state = state.copyWith(etape: EnvoiDossierEtape.soumissions);
    final avocatsEnEchec = <String>[];
    for (final avocat in state.selectedProfessionnels) {
      try {
        await repo.soumettre(dossierId: dossier.id, avocatId: avocat.id);
      } catch (_) {
        avocatsEnEchec.add(avocat.displayName);
      }
    }

    final resultat = EnvoiDossierResultat(
      dossier: dossier,
      avocatsEnEchec: avocatsEnEchec,
      piecesEnEchec: piecesEnEchec,
    );
    state = state.copyWith(
      etape: EnvoiDossierEtape.termine,
      resultat: resultat,
    );
    ref.invalidate(dossiersListProvider);
    return resultat;
  }

  void clear() {
    state = const CreateDossierWizardState();
  }
}

final createDossierWizardProvider =
    NotifierProvider<CreateDossierWizardNotifier, CreateDossierWizardState>(
      CreateDossierWizardNotifier.new,
    );
