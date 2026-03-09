import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/models/product.dart';

class WishlistPriceAlertNotifier extends Notifier<Set<int>> {
  static const _storageKey = 'wishlist_price_alerts';
  static const _seedKey = 'wishlist_price_alerts_seeded';

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
    final rawWishlist = prefs.getStringList('wishlist_items') ?? [];
    if (rawWishlist.isNotEmpty) {
      final ids = rawWishlist
          .map((e) => Product.fromJson(jsonDecode(e) as Map<String, dynamic>))
          .map((p) => p.id)
          .toList();
      state = ids.take(2).toSet();
    } else {
      state = {1, 3};
    }
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
}

final wishlistPriceAlertProvider =
    NotifierProvider<WishlistPriceAlertNotifier, Set<int>>(WishlistPriceAlertNotifier.new);
