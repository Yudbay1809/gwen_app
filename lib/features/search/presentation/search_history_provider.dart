import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryNotifier extends Notifier<List<String>> {
  static const _storageKey = 'global_search_history';
  static const _maxItems = 8;

  @override
  List<String> build() {
    _load();
    return const [];
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? const <String>[];
    state = raw;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, state);
  }

  void add(String query) {
    final value = query.trim();
    if (value.isEmpty) return;
    final next = [value, ...state.where((q) => q.toLowerCase() != value.toLowerCase())];
    state = next.take(_maxItems).toList();
    _save();
  }

  void remove(String query) {
    state = state.where((q) => q != query).toList();
    _save();
  }

  void clear() {
    state = [];
    _save();
  }
}

final searchHistoryProvider =
    NotifierProvider<SearchHistoryNotifier, List<String>>(SearchHistoryNotifier.new);
