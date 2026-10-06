import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../data/models/professionnel_summary.dart';
import '../../data/repositories/professionnels_repository.dart';

/// Professionnels de l'univers actif (avocats ou psychologues), depuis l'API.
///
/// Rechargé automatiquement quand l'univers change.
/// Pour réessayer après une erreur : `ref.invalidate(professionnelsByUniverseProvider)`.
final professionnelsByUniverseProvider =
    FutureProvider<List<ProfessionnelSummary>>((ref) {
      final universe = ref.watch(currentUniverseProvider);
      return ref
          .watch(professionnelsRepositoryProvider)
          .searchProfessionnels(type: universe.apiProfessionalType);
    });
