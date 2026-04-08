import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository_impl.dart';
import '../domain/auth_repository.dart';

class AuthState {
  final bool isLoggedIn;
  final bool isLoading;

  const AuthState({required this.isLoggedIn, required this.isLoading});
}

class AuthNotifier extends Notifier<AuthState> {
  late final AuthRepository _repository;

  @override
  AuthState build() {
    _repository = AuthRepositoryImpl();
    _load();
    return const AuthState(isLoggedIn: false, isLoading: true);
  }

  Future<void> _load() async {
    final loggedIn = await _repository.isLoggedIn();
    state = AuthState(isLoggedIn: loggedIn, isLoading: false);
  }

  Future<void> login() async {
    state = const AuthState(isLoggedIn: true, isLoading: false);
    await _repository.setLoggedIn(true);
  }

  Future<void> logout() async {
    state = const AuthState(isLoggedIn: false, isLoading: false);
    await _repository.setLoggedIn(false);
    await _repository.clearSessionScopedState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
