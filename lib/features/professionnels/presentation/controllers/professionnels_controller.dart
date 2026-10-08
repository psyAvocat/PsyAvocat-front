import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/realtime/realtime_service.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../../../shared/models/specialite.dart';
import '../../data/models/creneau.dart';
import '../../data/models/professionnel_detail.dart';
import '../../data/models/professionnel_summary.dart';
import '../../data/repositories/professionnels_repository.dart';

/// Ordre d'affichage de la liste des professionnels.
enum ProfessionnelSort { pertinence, nom, note }

typedef ProfessionnelsQuery = ({String? q, String? specialiteId, ProfessionnelSort tri});

/// Professionnels validés de l'univers courant, rechargés quand un statut change.
final professionnelsProvider = FutureProvider.autoDispose
    .family<List<ProfessionnelSummary>, ProfessionnelsQuery>((ref, query) async {
  final universe = ref.watch(currentUniverseProvider);
  listenRealtime(ref, {RealtimeEventType.professionnelMisAJour}, (_) => ref.invalidateSelf());
  final list = await ref.read(professionnelsRepositoryProvider).searchProfessionnels(
    type: universe.apiProfessionalType,
    q: query.q,
    specialiteId: query.specialiteId,
  );
  switch (query.tri) {
    case ProfessionnelSort.pertinence:
      return list;
    case ProfessionnelSort.nom:
      return [...list]..sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
    case ProfessionnelSort.note:
      return [...list]..sort((a, b) => (b.noteMoyenne ?? 0).compareTo(a.noteMoyenne ?? 0));
  }
});

/// Spécialités de l'univers courant (puces de filtre).
final specialitesProvider = FutureProvider.autoDispose<List<Specialite>>((ref) {
  final type = ref.watch(currentUniverseProvider).apiProfessionalType;
  if (type == null) return const [];
  return ref.read(professionnelsRepositoryProvider).getSpecialites(type);
});

/// Fiche publique d'un professionnel (404 s'il n'est plus validé).
final professionnelDetailProvider =
    FutureProvider.autoDispose.family<ProfessionnelDetail, String>((ref, id) {
  listenRealtime(ref, {RealtimeEventType.professionnelMisAJour}, (event) {
    if (event.payload['id']?.toString() == id) ref.invalidateSelf();
  });
  return ref.read(professionnelsRepositoryProvider).getProfessionnel(id);
});

/// Créneaux à venir (libres et réservés), mis à jour en temps réel.
final creneauxProvider = FutureProvider.autoDispose.family<List<Creneau>, String>((ref, proId) {
  listenRealtime(
    ref,
    {RealtimeEventType.creneauMisAJour, RealtimeEventType.creneauxMisAJour},
    (event) {
      if (event.payload['professionnelId']?.toString() == proId) ref.invalidateSelf();
    },
  );
  return ref.read(professionnelsRepositoryProvider).getCreneaux(proId);
});
