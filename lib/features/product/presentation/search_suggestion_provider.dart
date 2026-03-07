import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchSuggestionNotifier extends Notifier<List<String>> {
  static const _storageKey = 'search_suggestions';

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

  void setSuggestions(List<String> list) {
    state = list;
    _save();
  }
}

final searchSuggestionProvider = NotifierProvider<SearchSuggestionNotifier, List<String>>(SearchSuggestionNotifier.new);
