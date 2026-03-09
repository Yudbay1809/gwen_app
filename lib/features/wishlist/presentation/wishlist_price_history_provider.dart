import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WishlistPriceHistoryNotifier extends Notifier<Map<int, List<double>>> {
  static const _storageKey = 'wishlist_price_history';

  @override
  Map<int, List<double>> build() {
    _load();
    return _seed();
  }

  Map<int, List<double>> _seed() {
    return {
      100: [200000, 195000, 190000, 185000, 182000],
      101: [180000, 175000, 178000, 170000, 165000],
      200: [250000, 245000, 240000, 235000, 230000],
      201: [210000, 208000, 205000, 200000, 198000],
    };
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) {
      await _save(state);
      return;
    }
    try {
      final jsonMap = jsonDecode(raw) as Map<String, dynamic>;
      final mapped = <int, List<double>>{};
      for (final entry in jsonMap.entries) {
        final key = int.tryParse(entry.key);
        if (key == null) continue;
        final list = (entry.value as List).map((e) => (e as num).toDouble()).toList();
        mapped[key] = list;
      }
      state = mapped;
    } catch (_) {
      state = _seed();
      await _save(state);
    }
  }

  Future<void> _save(Map<int, List<double>> value) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonMap = value.map((k, v) => MapEntry(k.toString(), v));
    await prefs.setString(_storageKey, jsonEncode(jsonMap));
  }

  void setHistory(int productId, List<double> history) {
    state = {...state, productId: history};
    _save(state);
  }
}

final wishlistPriceHistoryProvider =
    NotifierProvider<WishlistPriceHistoryNotifier, Map<int, List<double>>>(
  WishlistPriceHistoryNotifier.new,
);
