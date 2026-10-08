import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/realtime/realtime_service.dart';
import '../../../../core/theme/app_universe.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../data/models/contenu_model.dart';
import '../../data/repositories/contenus_repository.dart';

/// Type de publication de l'univers : Articles (Avocat) ou Conseils (Psychologue).
String publicationTypeFor(AppUniverse universe) =>
    universe.isLawyer ? 'ARTICLE' : 'CONSEIL';

/// Libellé pluriel : « Articles » ou « Conseils ».
String publicationsLabelFor(AppUniverse universe) =>
    universe.isLawyer ? 'Articles' : 'Conseils';

/// Critères de recherche (le type est toujours celui de l'univers courant).
typedef PublicationQuery = ({String? q, String? specialiteId, PublicationSort tri});

/// Publications de l'univers courant ; rechargées dès qu'un professionnel
/// publie, modifie, désactive ou supprime un contenu.
final publicationsProvider =
    FutureProvider.autoDispose.family<List<Publication>, PublicationQuery>((ref, query) {
  final universe = ref.watch(currentUniverseProvider);
  listenRealtime(ref, {RealtimeEventType.contenuMisAJour}, (_) => ref.invalidateSelf());
  return ref.read(contenusRepositoryProvider).rechercher(
    type: publicationTypeFor(universe),
    q: query.q,
    specialiteId: query.specialiteId,
    tri: query.tri,
  );
});

/// Publications populaires affichées sur l'accueil.
final popularPublicationsProvider = FutureProvider.autoDispose<List<Publication>>((ref) async {
  final all = await ref.watch(
    publicationsProvider((q: null, specialiteId: null, tri: PublicationSort.populaire)).future,
  );
  return all.take(5).toList();
});

/// Détail d'une publication ; s'il est retiré pendant la lecture, l'écran
/// bascule sur « Cette ressource n'est plus disponible. ».
final publicationDetailProvider =
    FutureProvider.autoDispose.family<Publication, String>((ref, id) {
  listenRealtime(ref, {RealtimeEventType.contenuMisAJour}, (event) {
    if (event.payload['id']?.toString() == id) ref.invalidateSelf();
  });
  return ref.read(contenusRepositoryProvider).getPublication(id);
});
