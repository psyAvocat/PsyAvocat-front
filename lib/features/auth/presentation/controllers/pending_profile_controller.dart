import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Identité saisie à l'inscription, en attente de création du profil métier.
///
/// Le type de profil (patient ou justiciable) dépend de l'univers que
/// l'utilisateur choisit juste après l'inscription : le profil est donc créé
/// sur l'écran de choix d'univers. Donnée gardée en mémoire uniquement.
class PendingProfile {
  final String prenom;
  final String nom;
  final String? telephone;

  const PendingProfile({
    required this.prenom,
    required this.nom,
    this.telephone,
  });
}

class PendingProfileNotifier extends Notifier<PendingProfile?> {
  @override
  PendingProfile? build() => null;

  void save(PendingProfile profile) => state = profile;

  void clear() => state = null;
}

final pendingProfileProvider =
    NotifierProvider<PendingProfileNotifier, PendingProfile?>(
      PendingProfileNotifier.new,
    );
