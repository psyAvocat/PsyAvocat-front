import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_providers.dart';
import '../models/rendez_vous_model.dart';

/// Contrat officiel du repository des rendez-vous
abstract class RendezVousRepository {
  Future<List<RendezVousItem>> getMyRendezVous();
  Future<RendezVousItem> createRendezVousDirect({
    required String proId,
    required bool isAvocat,
    required String disponibiliteId,
    required String mode,
    required double montantTotal,
    String? motif,
  });
  Future<void> annulerRendezVous(String id);
}

/// Implémentation API connectée aux endpoints Spring Boot :
/// - GET /api/rendez-vous
/// - POST /api/rendez-vous/avocat/direct ou /api/rendez-vous/psychologue
/// - PATCH /api/rendez-vous/{id}/annuler
class ApiRendezVousRepository implements RendezVousRepository {
  final ApiClient _client;

  ApiRendezVousRepository(this._client);

  @override
  Future<List<RendezVousItem>> getMyRendezVous() async {
    try {
      final response = await _client.get('/rendez-vous');
      final list = response.data as List<dynamic>? ?? [];

      return list.map((item) {
        final map = item as Map<String, dynamic>;
        final dt = DateTime.tryParse(map['dateHeure'] as String? ?? '') ?? DateTime.now();
        final typePro = map['typeProfessionnel'] as String? ?? 'AVOCAT';
        final isAvocat = typePro == 'AVOCAT';
        final proNom = map['professionnelNom'] as String? ?? '';
        final proPrenom = map['professionnelPrenom'] as String? ?? '';

        final months = [
          'Jan.', 'Fév.', 'Mar.', 'Avr.', 'Mai', 'Juin',
          'Juil.', 'Août', 'Sep.', 'Oct.', 'Nov.', 'Déc.'
        ];
        final monthStr = dt.month >= 1 && dt.month <= 12 ? months[dt.month - 1] : 'Avr.';

        final hourStr = dt.hour.toString().padLeft(2, '0');
        final minStr = dt.minute.toString().padLeft(2, '0');
        final endHour = (dt.hour + 1).toString().padLeft(2, '0');

        final total = (map['montantTotal'] as num?)?.toInt() ?? 0;
        final acompte = (map['montantAcompte'] as num?)?.toInt() ?? (total * 0.20).round();

        final rawStatut = (map['statut'] as String? ?? 'CONFIRME').toUpperCase();
        String uiStatut = 'Confirmé';
        if (rawStatut.contains('ATTENTE')) {
          uiStatut = 'En attente';
        } else if (rawStatut.contains('ANNUL')) {
          uiStatut = 'Annulé';
        } else if (rawStatut.contains('EFFECTU') || dt.isBefore(DateTime.now())) {
          uiStatut = 'Passé';
        }

        final proDisplayName = (proPrenom.isNotEmpty || proNom.isNotEmpty)
            ? (isAvocat ? 'Maître $proPrenom $proNom'.trim() : 'Dr. $proPrenom $proNom'.trim())
            : (isAvocat ? 'Avocat' : 'Psychologue');

        return RendezVousItem(
          id: map['id']?.toString() ?? 'rdv-${DateTime.now().millisecondsSinceEpoch}',
          day: dt.day.toString().padLeft(2, '0'),
          month: monthStr,
          year: dt.year.toString(),
          time: '$hourStr:$minStr - $endHour:$minStr',
          proId: map['professionnelId']?.toString() ?? '',
          proName: proDisplayName,
          proRole: isAvocat ? 'Avocat' : 'Psychologue',
          specialty: isAvocat ? 'Droit général' : 'Psychologie clinique',
          mode: (map['mode'] as String?)?.toUpperCase() == 'CABINET'
              ? 'Au cabinet'
              : 'En ligne (visioconférence)',
          status: uiStatut,
          montantTotal: total,
          montantAcompte: acompte,
          motif: map['motif'] as String?,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<RendezVousItem> createRendezVousDirect({
    required String proId,
    required bool isAvocat,
    required String disponibiliteId,
    required String mode,
    required double montantTotal,
    String? motif,
  }) async {
    final endpoint = isAvocat ? '/rendez-vous/avocat/direct' : '/rendez-vous/psychologue';
    final payload = isAvocat
        ? {
            'avocatId': proId,
            'disponibiliteId': disponibiliteId,
            'mode': mode.contains('cabinet') ? 'CABINET' : 'VISIO',
            'montantTotal': montantTotal,
            'motif': motif ?? 'Consultation',
          }
        : {
            'psychologueId': proId,
            'disponibiliteId': disponibiliteId,
            'mode': mode.contains('cabinet') ? 'CABINET' : 'VISIO',
            'montantTotal': montantTotal,
          };

    final response = await _client.post(endpoint, data: payload);
    final map = response.data as Map<String, dynamic>;

    final dt = DateTime.tryParse(map['dateHeure'] as String? ?? '') ?? DateTime.now();
    final months = [
      'Jan.', 'Fév.', 'Mar.', 'Avr.', 'Mai', 'Juin',
      'Juil.', 'Août', 'Sep.', 'Oct.', 'Nov.', 'Déc.'
    ];
    final monthStr = dt.month >= 1 && dt.month <= 12 ? months[dt.month - 1] : 'Avr.';
    final hourStr = dt.hour.toString().padLeft(2, '0');
    final minStr = dt.minute.toString().padLeft(2, '0');
    final endHour = (dt.hour + 1).toString().padLeft(2, '0');

    final total = (map['montantTotal'] as num?)?.toInt() ?? montantTotal.toInt();
    final acompte = (map['montantAcompte'] as num?)?.toInt() ?? (total * 0.20).round();

    return RendezVousItem(
      id: map['id']?.toString() ?? 'rdv-${DateTime.now().millisecondsSinceEpoch}',
      day: dt.day.toString().padLeft(2, '0'),
      month: monthStr,
      year: dt.year.toString(),
      time: '$hourStr:$minStr - $endHour:$minStr',
      proId: proId,
      proName: isAvocat ? 'Avocat' : 'Psychologue',
      proRole: isAvocat ? 'Avocat' : 'Psychologue',
      specialty: 'Consultation',
      mode: mode,
      status: 'Confirmé',
      montantTotal: total,
      montantAcompte: acompte,
      motif: motif,
    );
  }

  @override
  Future<void> annulerRendezVous(String id) async {
    await _client.patch('/rendez-vous/$id/annuler');
  }
}

/// Provider du repository des rendez-vous
final rendezVousRepositoryProvider = Provider<RendezVousRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ApiRendezVousRepository(client);
});
