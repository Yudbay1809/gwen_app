import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ArticleMetrics {
  final int views;
  final int shares;

  const ArticleMetrics({required this.views, required this.shares});

  ArticleMetrics copyWith({int? views, int? shares}) {
    return ArticleMetrics(
      views: views ?? this.views,
      shares: shares ?? this.shares,
    );
  }
}

class ArticleMetricsNotifier extends Notifier<Map<int, ArticleMetrics>> {
  static const _storageKey = 'article_metrics';
  static const _seedKey = 'article_metrics_seeded';

  @override
  Map<int, ArticleMetrics> build() {
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
    final mapped = <int, ArticleMetrics>{};
    decoded.forEach((key, value) {
      final data = value as Map<String, dynamic>;
      mapped[int.parse(key)] = ArticleMetrics(
        views: (data['views'] as num?)?.toInt() ?? 0,
        shares: (data['shares'] as num?)?.toInt() ?? 0,
      );
    });
    state = mapped;
  }

  Future<void> _seed(SharedPreferences prefs) async {
    if (prefs.getBool(_seedKey) == true) return;
    state = {
      1: const ArticleMetrics(views: 120, shares: 6),
      2: const ArticleMetrics(views: 98, shares: 4),
      3: const ArticleMetrics(views: 45, shares: 2),
      4: const ArticleMetrics(views: 60, shares: 1),
      5: const ArticleMetrics(views: 30, shares: 1),
      6: const ArticleMetrics(views: 72, shares: 3),
      7: const ArticleMetrics(views: 22, shares: 0),
    };
    await _save();
    await prefs.setBool(_seedKey, true);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = state.map(
      (key, value) => MapEntry(
        key.toString(),
        {'views': value.views, 'shares': value.shares},
      ),
    );
    await prefs.setString(_storageKey, jsonEncode(encoded));
  }

  ArticleMetrics _get(int id) => state[id] ?? const ArticleMetrics(views: 0, shares: 0);

  void addView(int id) {
    final current = _get(id);
    state = {...state, id: current.copyWith(views: current.views + 1)};
    _save();
  }

  void addShare(int id) {
    final current = _get(id);
    state = {...state, id: current.copyWith(shares: current.shares + 1)};
    _save();
  }
}

final articleMetricsProvider =
    NotifierProvider<ArticleMetricsNotifier, Map<int, ArticleMetrics>>(ArticleMetricsNotifier.new);
