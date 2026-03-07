import 'dart:convert';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/models/product.dart';

class WishlistNotifier extends Notifier<List<Product>> {
  static const _storageKey = 'wishlist_items';

  @override
  List<Product> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? [];
    final items = raw
        .map((e) => Product.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
    state = items;
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
