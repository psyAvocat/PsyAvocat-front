import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/network_providers.dart';
import '../../data/repositories/auth_repository.dart';

/// Contrôleur Riverpod pour gérer les actions d'authentification dans l'UI (Riverpod 3).
class AuthController extends Notifier<AsyncValue<void>> {
  late final AuthRepository _repository;

  @override
  AsyncValue<void> build() {
    _repository = ref.watch(authRepositoryProvider);
    return const AsyncValue.data(null);
  }

  Future<bool> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      await _repository.signIn(email: email, password: password);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> signUp({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      await _repository.signUp(email: email, password: password);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _repository.signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AsyncValue<void>>(AuthController.new);
