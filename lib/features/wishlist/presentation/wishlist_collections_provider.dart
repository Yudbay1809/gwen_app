import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/models/product.dart';

class WishlistCollection {
  final String name;
  final List<Product> items;

  const WishlistCollection({required this.name, required this.items});

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }

  factory WishlistCollection.fromJson(Map<String, dynamic> json) {
    return WishlistCollection(
      name: json['name'] as String,
      items: (json['items'] as List).map((e) => Product.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class WishlistCollectionsNotifier extends Notifier<List<WishlistCollection>> {
  static const _storageKey = 'wishlist_collections';

  @override
  List<WishlistCollection> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? [];
    final collections = raw
        .map((e) => WishlistCollection.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
    state = collections;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = state.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_storageKey, raw);
  }

  void createCollection(String name) {
    if (name.trim().isEmpty) return;
    if (state.any((c) => c.name == name)) return;
    state = [...state, WishlistCollection(name: name, items: [])];
    _save();
  }

  void addToCollection(String name, Product product) {
    final next = state.map((c) {
      if (c.name != name) return c;
      if (c.items.any((e) => e.id == product.id)) return c;
      return WishlistCollection(name: c.name, items: [...c.items, product]);
    }).toList();
    state = next;
    ref.read(collectionHistoryProvider.notifier).recordAdd(name);
    _save();
  }

  void removeFromCollection(String name, Product product) {
    final next = state.map((c) {
      if (c.name != name) return c;
      return WishlistCollection(name: c.name, items: c.items.where((e) => e.id != product.id).toList());
    }).toList();
    state = next;
    _save();
  }

  void renameCollection(String oldName, String newName) {
    if (newName.trim().isEmpty) return;
    if (state.any((c) => c.name == newName)) return;
    state = state
        .map((c) => c.name == oldName ? WishlistCollection(name: newName, items: c.items) : c)
        .toList();
    _save();
  }

  void deleteCollection(String name) {
    state = state.where((c) => c.name != name).toList();
    _save();
  }

  void moveItem(String from, String to, Product product) {
    if (from == to) return;
    removeFromCollection(from, product);
    addToCollection(to, product);
  }
}

final wishlistCollectionsProvider =
    NotifierProvider<WishlistCollectionsNotifier, List<WishlistCollection>>(WishlistCollectionsNotifier.new);

class CollectionHistoryNotifier extends Notifier<Map<String, List<DateTime>>> {
  static const _storageKey = 'wishlist_collection_history';

  @override
  Map<String, List<DateTime>> build() {
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
    final mapped = <String, List<DateTime>>{};
    decoded.forEach((key, value) {
      final list = (value as List).map((e) => DateTime.parse(e as String)).toList();
      mapped[key] = list;
    });
    state = mapped;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = state.map((key, value) => MapEntry(key, value.map((d) => d.toIso8601String()).toList()));
    await prefs.setString(_storageKey, jsonEncode(encoded));
  }

  Future<void> recordAdd(String name) async {
    final now = DateTime.now();
    final List<DateTime> list = [...(state[name] ?? const <DateTime>[]), now];
    final cutoff = now.subtract(const Duration(days: 30));
    final List<DateTime> trimmed = list.where((d) => d.isAfter(cutoff)).toList();
    state = {...state, name: trimmed};
    await _save();
  }
}

final collectionHistoryProvider =
    NotifierProvider<CollectionHistoryNotifier, Map<String, List<DateTime>>>(CollectionHistoryNotifier.new);

class CollectionAnalytics {
  final String name;
  final int itemCount;
  final int last7;
  final int prev7;

  const CollectionAnalytics({
    required this.name,
    required this.itemCount,
    required this.last7,
    required this.prev7,
  });

  int get growth => last7 - prev7;
}

final collectionAnalyticsProvider = Provider<List<CollectionAnalytics>>((ref) {
  final collections = ref.watch(wishlistCollectionsProvider);
  final history = ref.watch(collectionHistoryProvider);
  final now = DateTime.now();
  final last7Start = now.subtract(const Duration(days: 7));
  final prev7Start = now.subtract(const Duration(days: 14));

  final analytics = collections.map((c) {
    final events = history[c.name] ?? const [];
    final last7 = events.where((d) => d.isAfter(last7Start)).length;
    final prev7 = events.where((d) => d.isAfter(prev7Start) && d.isBefore(last7Start)).length;
    return CollectionAnalytics(
      name: c.name,
      itemCount: c.items.length,
      last7: last7,
      prev7: prev7,
    );
  }).toList();

  analytics.sort((a, b) => b.itemCount.compareTo(a.itemCount));
  return analytics;
});
