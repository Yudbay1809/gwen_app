import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ArticleFollowNotifier extends Notifier<Set<String>> {
  static const _storageKey = 'article_followed_authors';
  static const _seedKey = 'article_followed_seeded';

  @override
  Set<String> build() {
    _load();
    return <String>{};
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey);
    if (raw == null) {
      await _seed(prefs);
      return;
    }
    state = raw.toSet();
  }

  Future<void> _seed(SharedPreferences prefs) async {
    if (prefs.getBool(_seedKey) == true) return;
    state = {'Dr. Maya S.'};
    await _save();
    await prefs.setBool(_seedKey, true);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, state.toList());
  }

  void toggle(String author) {
    final next = Set<String>.from(state);
    if (next.contains(author)) {
      next.remove(author);
    } else {
      next.add(author);
    }
    state = next;
    _save();
  }
}

final articleFollowProvider =
    NotifierProvider<ArticleFollowNotifier, Set<String>>(ArticleFollowNotifier.new);
