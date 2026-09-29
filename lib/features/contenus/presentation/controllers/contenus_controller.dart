import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/contenu_model.dart';
import '../../data/repositories/contenus_repository.dart';

final contenusListProvider =
    AsyncNotifierProvider<ContenusNotifier, List<ContenuModel>>(
  ContenusNotifier.new,
);

class ContenusNotifier extends AsyncNotifier<List<ContenuModel>> {
  @override
  Future<List<ContenuModel>> build() async {
    return ref.read(contenusRepositoryProvider).getContenus();
  }

  Future<void> filterByUnivers(String? univers) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(contenusRepositoryProvider).getContenus(univers: univers),
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(contenusRepositoryProvider).getContenus(),
    );
  }
}

final contenuDetailProvider = FutureProvider.family<ContenuModel?, String>((ref, id) async {
  return ref.read(contenusRepositoryProvider).getContenuById(id);
});
