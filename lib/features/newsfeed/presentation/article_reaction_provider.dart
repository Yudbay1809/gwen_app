import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ArticleReactionState {
  final int likes;
  final bool liked;

  const ArticleReactionState({required this.likes, required this.liked});

  ArticleReactionState copyWith({int? likes, bool? liked}) {
    return ArticleReactionState(
      likes: likes ?? this.likes,
      liked: liked ?? this.liked,
    );
  }
}

class ArticleReactionNotifier extends Notifier<Map<int, ArticleReactionState>> {
  static const _storageKey = 'article_reactions';
  static const _seedKey = 'article_reactions_seeded';

  @override
  Map<int, ArticleReactionState> build() {
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
    final mapped = <int, ArticleReactionState>{};
    decoded.forEach((key, value) {
      final data = value as Map<String, dynamic>;
      mapped[int.parse(key)] = ArticleReactionState(
        likes: (data['likes'] as num?)?.toInt() ?? 0,
        liked: data['liked'] == true,
      );
    });
    state = mapped;
  }

  Future<void> _seed(SharedPreferences prefs) async {
    if (prefs.getBool(_seedKey) == true) return;
    state = {
      1: const ArticleReactionState(likes: 24, liked: true),
      2: const ArticleReactionState(likes: 18, liked: false),
      3: const ArticleReactionState(likes: 9, liked: false),
      4: const ArticleReactionState(likes: 12, liked: false),
      5: const ArticleReactionState(likes: 7, liked: false),
      6: const ArticleReactionState(likes: 14, liked: false),
      7: const ArticleReactionState(likes: 5, liked: false),
    };
    await _save();
    await prefs.setBool(_seedKey, true);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = state.map(
      (key, value) => MapEntry(
        key.toString(),
        {
          'likes': value.likes,
          'liked': value.liked,
        },
      ),
    );
    await prefs.setString(_storageKey, jsonEncode(encoded));
  }

  ArticleReactionState _get(int id) => state[id] ?? const ArticleReactionState(likes: 0, liked: false);

  void toggleLike(int id) {
    final current = _get(id);
    final nextLiked = !current.liked;
    final nextLikes = (current.likes + (nextLiked ? 1 : -1)).clamp(0, 9999);
    state = {...state, id: current.copyWith(likes: nextLikes, liked: nextLiked)};
    _save();
  }
}

final articleReactionProvider =
    NotifierProvider<ArticleReactionNotifier, Map<int, ArticleReactionState>>(ArticleReactionNotifier.new);
