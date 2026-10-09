import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/professionnels/data/models/professionnel_summary.dart';

class CreateDossierWizardState {
  final List<ProfessionnelSummary> selectedProfessionnels;
  final String titre;
  final String domaine;
  final String description;
  final DateTime? dateImportante;
  final List<String> piecesJointes; // For now, simple list of paths or names

  const CreateDossierWizardState({
    this.selectedProfessionnels = const [],
    this.titre = '',
    this.domaine = 'Droit immobilier', // Or any default based on universe
    this.description = '',
    this.dateImportante,
    this.piecesJointes = const [],
  });

  CreateDossierWizardState copyWith({
    List<ProfessionnelSummary>? selectedProfessionnels,
    String? titre,
    String? domaine,
    String? description,
    DateTime? dateImportante,
    List<String>? piecesJointes,
  }) {
    return CreateDossierWizardState(
      selectedProfessionnels:
          selectedProfessionnels ?? this.selectedProfessionnels,
      titre: titre ?? this.titre,
      domaine: domaine ?? this.domaine,
      description: description ?? this.description,
      dateImportante: dateImportante ?? this.dateImportante,
      piecesJointes: piecesJointes ?? this.piecesJointes,
    );
  }
}

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

  void updateInformations({
    required String titre,
    required String domaine,
    required String description,
    DateTime? dateImportante,
  }) {
    state = state.copyWith(
      titre: titre,
      domaine: domaine,
      description: description,
      dateImportante: dateImportante,
    );
  }

  void addPieceJointe(String path) {
    state = state.copyWith(piecesJointes: [...state.piecesJointes, path]);
  }

  void removePieceJointe(String path) {
    state = state.copyWith(
      piecesJointes: state.piecesJointes.where((p) => p != path).toList(),
    );
  }

  void clear() {
    state = const CreateDossierWizardState();
  }
}

final createDossierWizardProvider =
    NotifierProvider<CreateDossierWizardNotifier, CreateDossierWizardState>(
      CreateDossierWizardNotifier.new,
    );
