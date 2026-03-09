import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferencesState {
  final bool isDarkMode;
  final String language;
  final String currency;
  final bool isLoading;

  const AppPreferencesState({
    required this.isDarkMode,
    required this.language,
    required this.currency,
    required this.isLoading,
  });

  AppPreferencesState copyWith({
    bool? isDarkMode,
    String? language,
    String? currency,
    bool? isLoading,
  }) {
    return AppPreferencesState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      language: language ?? this.language,
      currency: currency ?? this.currency,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AppPreferencesNotifier extends Notifier<AppPreferencesState> {
  static const _darkKey = 'pref_dark_mode';
  static const _langKey = 'pref_language';
  static const _currencyKey = 'pref_currency';

  @override
  AppPreferencesState build() {
    _load();
    return const AppPreferencesState(
      isDarkMode: false,
      language: 'ID',
      currency: 'IDR',
      isLoading: true,
    );
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool(_darkKey) ?? false;
      var language = prefs.getString(_langKey) ?? 'ID';
      var currency = prefs.getString(_currencyKey) ?? 'IDR';
      const languages = ['ID', 'EN'];
      const currencies = ['IDR', 'USD'];
      if (!languages.contains(language) || !currencies.contains(currency)) {
        language = 'ID';
        currency = 'IDR';
        await prefs.remove(_langKey);
        await prefs.remove(_currencyKey);
      }
      state = state.copyWith(
        isDarkMode: isDark,
        language: language,
        currency: currency,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isDarkMode: false, language: 'ID', currency: 'IDR', isLoading: false);
    }
  }

  Future<void> setDarkMode(bool value) async {
    state = state.copyWith(isDarkMode: value, isLoading: false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkKey, value);
  }

  Future<void> setLanguage(String value) async {
    state = state.copyWith(language: value, isLoading: false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, value);
  }

  Future<void> setCurrency(String value) async {
    state = state.copyWith(currency: value, isLoading: false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, value);
  }

  Future<void> reset() async {
    state = state.copyWith(isDarkMode: false, language: 'ID', currency: 'IDR', isLoading: false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_darkKey);
    await prefs.remove(_langKey);
    await prefs.remove(_currencyKey);
  }

  ThemeMode get themeMode => state.isDarkMode ? ThemeMode.dark : ThemeMode.light;
}

final appPreferencesProvider =
    NotifierProvider<AppPreferencesNotifier, AppPreferencesState>(AppPreferencesNotifier.new);
