import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryNotifier extends Notifier<List<String>> {
  static const _storageKey = 'search_history';

  @override
  List<String> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getStringList(_storageKey) ?? [];
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, state);
  }

  void add(String query) {
    final cleaned = query.trim();
    if (cleaned.isEmpty) return;
    final next = [cleaned, ...state.where((e) => e != cleaned)];
    state = next.take(10).toList();
    _save();
  }

  void remove(String query) {
    state = state.where((e) => e != query).toList();
    _save();
  }

  void clear() {
    state = [];
    _save();
  }
}

final searchHistoryProvider = NotifierProvider<SearchHistoryNotifier, List<String>>(SearchHistoryNotifier.new);
