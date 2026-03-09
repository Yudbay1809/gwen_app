import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ArticleCommentsNotifier extends Notifier<Map<int, List<String>>> {
  static const _storageKey = 'article_comments';
  static const _seedKey = 'article_comments_seeded';

  @override
  Map<int, List<String>> build() {
    _load();
    return {};
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) {
      await _seed(prefs);
      return;
    }
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final mapped = decoded.map(
      (key, value) => MapEntry(
        int.parse(key),
        (value as List).map((e) => e.toString()).toList(),
      ),
    );
    state = mapped;
  }

  Future<void> _seed(SharedPreferences prefs) async {
    if (prefs.getBool(_seedKey) == true) return;
    state = {
      1: ['Love this routine!', 'So helpful, thanks!', 'Trying this tonight'],
      2: ['SPF tips are gold', 'Need more recommendations'],
      3: ['Dewy look on point'],
      4: ['Haircare tips saved!', 'Any product recs?'],
      5: ['Exfoliation helps a lot'],
    };
    await _save();
    await prefs.setBool(_seedKey, true);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = state.map((key, value) => MapEntry(key.toString(), value));
    await prefs.setString(_storageKey, jsonEncode(encoded));
  }

  void addComment(int id, String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    final list = [...(state[id] ?? const <String>[])];
    list.insert(0, t);
    state = {...state, id: list};
    _save();
  }
}

final articleCommentsProvider =
    NotifierProvider<ArticleCommentsNotifier, Map<int, List<String>>>(ArticleCommentsNotifier.new);

class ArticleReadProgressNotifier extends Notifier<Map<int, double>> {
  @override
  Map<int, double> build() => {};

  void setProgress(int id, double value) {
    final clamped = value.clamp(0, 1).toDouble();
    state = {...state, id: clamped};
  }
}

final articleReadProgressProvider =
    NotifierProvider<ArticleReadProgressNotifier, Map<int, double>>(ArticleReadProgressNotifier.new);
