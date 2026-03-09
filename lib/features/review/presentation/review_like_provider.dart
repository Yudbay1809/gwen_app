import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReviewLikeNotifier extends Notifier<Set<int>> {
  static const _storageKey = 'review_likes';
  static const _seedKey = 'review_likes_seeded';

  @override
  Set<int> build() {
    _load();
    return <int>{};
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) {
      await _seed(prefs);
      return;
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    state = decoded.map((e) => e as int).toSet();
  }

  Future<void> _seed(SharedPreferences prefs) async {
    if (prefs.getBool(_seedKey) == true) return;
    state = {1, 2, 3, 5};
    await _save();
    await prefs.setBool(_seedKey, true);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(state.toList()));
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

  bool isLiked(int id) => state.contains(id);
}

final reviewLikeProvider = NotifierProvider<ReviewLikeNotifier, Set<int>>(ReviewLikeNotifier.new);

class ReviewHelpfulNotifier extends Notifier<Map<int, int>> {
  static const _storageKey = 'review_helpful';
  static const _seedKey = 'review_helpful_seeded';

  @override
  Map<int, int> build() {
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
    state = decoded.map((key, value) => MapEntry(int.parse(key), (value as num).toInt()));
  }

  Future<void> _seed(SharedPreferences prefs) async {
    if (prefs.getBool(_seedKey) == true) return;
    state = {1: 3, 2: 1, 3: 5, 4: 2, 5: 4, 6: 1};
    await _save();
    await prefs.setBool(_seedKey, true);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = state.map((key, value) => MapEntry(key.toString(), value));
    await prefs.setString(_storageKey, jsonEncode(encoded));
  }

  void toggleHelpful(int id) {
    final current = state[id] ?? 0;
    state = {...state, id: current + 1};
    _save();
  }
}

final reviewHelpfulProvider =
    NotifierProvider<ReviewHelpfulNotifier, Map<int, int>>(ReviewHelpfulNotifier.new);
