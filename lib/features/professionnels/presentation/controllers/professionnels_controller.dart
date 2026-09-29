import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/professional_detail_model.dart';
import '../../data/repositories/professionnels_repository.dart';

/// Provider pour récupérer la liste des professionnels dynamiquement depuis l'API Spring Boot & MySQL.
final professionnelsListProvider = FutureProvider.family<List<ProfessionalDetail>, bool?>((ref, isAvocat) async {
  final repo = ref.watch(professionnelsRepositoryProvider);
  return repo.getProfessionnels(isAvocat: isAvocat);
});
