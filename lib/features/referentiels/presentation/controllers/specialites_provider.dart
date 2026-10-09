import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../data/models/specialite_option.dart';
import '../../data/repositories/referentiel_repository.dart';

/// Spécialités de l'univers actif (droit pour Avocat, psychologie pour
/// Psychologue). Rechargées si l'univers change ; jamais codées en dur.
final specialitesOfUniverseProvider =
    FutureProvider.autoDispose<List<SpecialiteOption>>((ref) {
      final type = ref.watch(currentUniverseProvider).apiProfessionalType;
      if (type == null) return const [];
      return ref.read(referentielRepositoryProvider).getSpecialites(type: type);
    });
