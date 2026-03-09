import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/models/product.dart';
import '../../home/presentation/home_providers.dart';

class WishlistNotifier extends Notifier<List<Product>> {
  static const _storageKey = 'wishlist_items';
  static const _seedKey = 'wishlist_seeded';

  @override
  List<Product> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey);
    if (raw == null) {
      await _seed(prefs);
      return;
    }
    final items = raw
        .map((e) => Product.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
    state = items;
  }

  Future<void> _seed(SharedPreferences prefs) async {
    if (prefs.getBool(_seedKey) == true) return;
    final products = ref.read(homeDataProvider).bestSeller.take(3).toList();
    state = products;
    await _save();
    await prefs.setBool(_seedKey, true);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = state.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_storageKey, raw);
  }

  void toggle(Product product) {
    final exists = state.any((e) => e.id == product.id);
    if (exists) {
      state = state.where((e) => e.id != product.id).toList();
    } else {
      state = [...state, product];
      ref.read(wishlistAnalyticsProvider.notifier).trackAdd(product.id);
    }
    _save();
  }

  bool isWishlisted(Product product) => state.any((e) => e.id == product.id);

  void remove(Product product) {
    state = state.where((e) => e.id != product.id).toList();
    _save();
  }

  void clear() {
    state = [];
    _save();
  }
}

final wishlistProvider = NotifierProvider<WishlistNotifier, List<Product>>(WishlistNotifier.new);

class WishlistAnalyticsNotifier extends Notifier<Map<int, int>> {
  static const _storageKey = 'wishlist_analytics';

  @override
  Map<int, int> build() {
    _load();
    return {};
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) {
      state = {};
      return;
    }
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    state = decoded.map((key, value) => MapEntry(int.parse(key), value as int));
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(state.map((key, value) => MapEntry(key.toString(), value)));
    await prefs.setString(_storageKey, raw);
  }

  Future<void> trackAdd(int productId) async {
    final current = state[productId] ?? 0;
    state = {...state, productId: current + 1};
    await _save();
  }
}

final wishlistAnalyticsProvider =
    NotifierProvider<WishlistAnalyticsNotifier, Map<int, int>>(WishlistAnalyticsNotifier.new);
