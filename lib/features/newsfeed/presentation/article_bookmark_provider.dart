import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ArticleBookmarkNotifier extends Notifier<Set<int>> {
  static const _storageKey = 'article_bookmarks';
  static const _seedKey = 'article_bookmarks_seeded';

  @override
  Set<int> build() {
    _load();
    return <int>{};
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey);
    if (raw == null) {
      await _seed(prefs);
      return;
    }
    state = raw.map(int.parse).toSet();
  }

  Future<void> _seed(SharedPreferences prefs) async {
    if (prefs.getBool(_seedKey) == true) return;
    state = {1, 4};
    await _save();
    await prefs.setBool(_seedKey, true);
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

  bool isBookmarked(int id) => state.contains(id);
}

final articleBookmarkProvider = NotifierProvider<ArticleBookmarkNotifier, Set<int>>(ArticleBookmarkNotifier.new);
