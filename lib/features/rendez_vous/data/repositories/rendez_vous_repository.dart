import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_providers.dart';
import '../models/rendez_vous_model.dart';

/// Rendez-vous de l'utilisateur connecté (Spring Boot `/api/rendez-vous`).
///
/// La disponibilité réelle, le prix et l'acompte sont toujours décidés par le backend :
/// Flutter n'affiche que ce que le serveur confirme.
abstract class RendezVousRepository {
  Future<List<RendezVous>> getMesRendezVous();

  Future<RendezVous> getRendezVous(String id);

  /// Réservation directe d'un créneau libre (le backend revérifie le créneau sous verrou).
  Future<RendezVous> reserver({
    required String typeProfessionnel,
    required String professionnelId,
    required String disponibiliteId,
    required String mode,
    required double montantTotal,
    String? motif,
  });

  /// Déplace un rendez-vous sur un autre créneau libre du même professionnel.
  Future<RendezVous> modifierCreneau({
    required String id,
    required String disponibiliteId,
  });

  Future<RendezVous> annuler(String id);
}

class ApiRendezVousRepository implements RendezVousRepository {
  final ApiClient _client;

  ApiRendezVousRepository(this._client);

  @override
  Future<List<RendezVous>> getMesRendezVous() async {
    final response = await _client.get('/rendez-vous');
    final list = response.data as List<dynamic>? ?? [];
    return list
        .map((e) => RendezVous.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<RendezVous> getRendezVous(String id) async {
    final response = await _client.get('/rendez-vous/$id');
    return RendezVous.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<RendezVous> reserver({
    required String typeProfessionnel,
    required String professionnelId,
    required String disponibiliteId,
    required String mode,
    required double montantTotal,
    String? motif,
  }) async {
    final estAvocat = typeProfessionnel == 'AVOCAT';
    final response = await _client.post(
      estAvocat ? '/rendez-vous/avocat/direct' : '/rendez-vous/psychologue',
      data: {
        estAvocat ? 'avocatId' : 'psychologueId': professionnelId,
        'disponibiliteId': disponibiliteId,
        'mode': mode,
        'montantTotal': montantTotal,
        if (motif != null && motif.trim().isNotEmpty) 'motif': motif.trim(),
      },
    );
    return RendezVous.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<RendezVous> modifierCreneau({
    required String id,
    required String disponibiliteId,
  }) async {
    final response = await _client.patch(
      '/rendez-vous/$id/creneau',
      data: {'disponibiliteId': disponibiliteId},
    );
    return RendezVous.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<RendezVous> annuler(String id) async {
    final response = await _client.patch('/rendez-vous/$id/annuler');
    return RendezVous.fromJson(response.data as Map<String, dynamic>);
  }
}

final rendezVousRepositoryProvider = Provider<RendezVousRepository>((ref) {
  return ApiRendezVousRepository(ref.watch(apiClientProvider));
});
