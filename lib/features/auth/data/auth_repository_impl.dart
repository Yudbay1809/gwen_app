import 'package:shared_preferences/shared_preferences.dart';

import '../domain/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  static const _authKey = 'auth_logged_in';
  static const _sessionScopedKeys = [
    'home_all_filter',
    'home_all_query',
    'home_all_scroll',
    'home_all_scroll_all',
    'home_all_scroll_promo',
    'home_all_scroll_best',
    'home_all_scroll_newest',
  ];

  @override
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_authKey) ?? false;
  }

  @override
  Future<void> setLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_authKey, value);
  }

  @override
  Future<void> clearSessionScopedState() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in _sessionScopedKeys) {
      await prefs.remove(key);
    }
  }
}
