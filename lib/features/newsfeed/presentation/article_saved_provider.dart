import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ArticleSavedNotifier extends Notifier<Set<int>> {
  static const _storageKey = 'article_saved';

  @override
  Set<int> build() {
    _load();
    return <int>{};
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? [];
    state = raw.map(int.parse).toSet();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, state.map((e) => e.toString()).toList());
  }

  void toggle(int id) {
    final next = Set<int>.from(state);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    state = next;
    _save();
  }
}

final articleSavedProvider =
    NotifierProvider<ArticleSavedNotifier, Set<int>>(ArticleSavedNotifier.new);
