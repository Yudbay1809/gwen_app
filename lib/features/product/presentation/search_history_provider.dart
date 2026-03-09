import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryNotifier extends Notifier<List<String>> {
  static const _storageKey = 'search_history';
  static const _seedKey = 'search_history_seeded';

  @override
  List<String> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey);
    if (raw == null) {
      await _seed(prefs);
      return;
    }
    state = raw;
  }

  Future<void> _seed(SharedPreferences prefs) async {
    if (prefs.getBool(_seedKey) == true) return;
    state = ['serum', 'sunscreen', 'lip balm', 'cleanser'];
    await _save();
    await prefs.setBool(_seedKey, true);
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

class SearchPinnedNotifier extends Notifier<List<String>> {
  static const _storageKey = 'search_pinned';

  @override
  List<String> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey);
    if (raw != null) {
      state = raw;
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, state);
  }

  void toggle(String query) {
    final cleaned = query.trim();
    if (cleaned.isEmpty) return;
    final next = [...state];
    if (next.contains(cleaned)) {
      next.remove(cleaned);
    } else {
      next.insert(0, cleaned);
    }
    state = next.take(6).toList();
    _save();
  }

  void remove(String query) {
    state = state.where((e) => e != query).toList();
    _save();
  }
}

final searchPinnedProvider = NotifierProvider<SearchPinnedNotifier, List<String>>(SearchPinnedNotifier.new);

final trendingSearchProvider = Provider<List<String>>((ref) {
  return const [
    'glass skin serum',
    'vitamin c',
    'sunscreen spf50',
    'retinol 0.3%',
    'lip tint',
    'hydrating toner',
  ];
});
