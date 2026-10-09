import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/suivi_model.dart';
import '../../data/repositories/suivi_repository.dart';

final humeurHistoryProvider =
    AsyncNotifierProvider<HumeurHistoryNotifier, List<HumeurEntryModel>>(
      HumeurHistoryNotifier.new,
    );

class HumeurHistoryNotifier extends AsyncNotifier<List<HumeurEntryModel>> {
  @override
  Future<List<HumeurEntryModel>> build() async {
    return ref.read(suiviRepositoryProvider).getHumeurHistory();
  }

  Future<bool> addEntry({
    required int noteHumeur,
    required String emotionDominante,
    String? noteText,
    List<String> facteurs = const [],
  }) async {
    try {
      final newEntry = await ref
          .read(suiviRepositoryProvider)
          .addHumeurEntry(
            noteHumeur: noteHumeur,
            emotionDominante: emotionDominante,
            noteText: noteText,
            facteurs: facteurs,
          );
      final current = state.value ?? [];
      state = AsyncData([newEntry, ...current]);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(suiviRepositoryProvider).getHumeurHistory(),
    );
  }
}
