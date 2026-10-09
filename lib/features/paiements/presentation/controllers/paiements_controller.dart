import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/paiement_model.dart';
import '../../data/repositories/paiements_repository.dart';

final paiementsListProvider =
    AsyncNotifierProvider<PaiementsNotifier, List<PaiementModel>>(
      PaiementsNotifier.new,
    );

class PaiementsNotifier extends AsyncNotifier<List<PaiementModel>> {
  @override
  Future<List<PaiementModel>> build() async {
    return ref.read(paiementsRepositoryProvider).getMesPaiements();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(paiementsRepositoryProvider).getMesPaiements(),
    );
  }
}
