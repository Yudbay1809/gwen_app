import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthState {
  final bool isLoggedIn;
  final bool isLoading;

  const AuthState({required this.isLoggedIn, required this.isLoading});
}

class AuthNotifier extends Notifier<AuthState> {
  static const _key = 'auth_logged_in';

  @override
  AuthState build() {
    _load();
    return const AuthState(isLoggedIn: false, isLoading: true);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool(_key) ?? false;
    state = AuthState(isLoggedIn: loggedIn, isLoading: false);
  }

  Future<void> login() async {
    state = const AuthState(isLoggedIn: true, isLoading: false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }

  Future<void> logout() async {
    state = const AuthState(isLoggedIn: false, isLoading: false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, false);
    await prefs.remove('home_all_filter');
    await prefs.remove('home_all_query');
    await prefs.remove('home_all_scroll');
    await prefs.remove('home_all_scroll_all');
    await prefs.remove('home_all_scroll_promo');
    await prefs.remove('home_all_scroll_best');
    await prefs.remove('home_all_scroll_newest');
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
