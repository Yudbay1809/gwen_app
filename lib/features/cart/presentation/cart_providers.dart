import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/models/cart_item.dart';
import '../../../shared/models/product.dart';
import '../../home/presentation/home_providers.dart';

class CartNotifier extends Notifier<List<CartItem>> {
  static const _storageKey = 'cart_items';
  static const _snapshotKey = 'cart_snapshot';
  static const _seedKey = 'cart_seeded';

  @override
  List<CartItem> build() {
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
        .map((e) => CartItem.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
    state = items;
  }

  Future<void> _seed(SharedPreferences prefs) async {
    if (prefs.getBool(_seedKey) == true) return;
    final products = ref.read(homeDataProvider).bestSeller.take(2).toList();
    state = products.map((p) => CartItem(product: p, quantity: 1, note: '')).toList();
    await _save();
    await prefs.setBool(_seedKey, true);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = state.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_storageKey, raw);
  }

  void add(Product product) {
    final index = state.indexWhere((e) => e.product.id == product.id);
    if (index == -1) {
      state = [...state, CartItem(product: product, quantity: 1, note: '')];
    } else {
      final updated = state[index].copyWith(quantity: state[index].quantity + 1);
      final next = [...state];
      next[index] = updated;
      state = next;
    }
    _save();
  }

  void remove(Product product) {
    state = state.where((e) => e.product.id != product.id).toList();
    _save();
  }

  void updateQty(Product product, int qty) {
    if (qty <= 0) {
      remove(product);
      return;
    }
    final index = state.indexWhere((e) => e.product.id == product.id);
    if (index == -1) return;
    final next = [...state];
    next[index] = next[index].copyWith(quantity: qty);
    state = next;
    _save();
  }

  void updateNote(Product product, String note) {
    final index = state.indexWhere((e) => e.product.id == product.id);
    if (index == -1) return;
    final next = [...state];
    next[index] = next[index].copyWith(note: note);
    state = next;
    _save();
  }

  void clear() {
    state = [];
    _save();
  }

  Future<void> saveSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = state.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_snapshotKey, raw);
  }

  Future<void> restoreSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_snapshotKey);
    if (raw == null) return;
    final items = raw
        .map((e) => CartItem.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
    state = items;
    _save();
  }
}

class SavedForLaterNotifier extends Notifier<List<CartItem>> {
  static const _storageKey = 'cart_saved_items';
  static const _seedKey = 'cart_saved_seeded';

  @override
  List<CartItem> build() {
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
        .map((e) => CartItem.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
    state = items;
  }

  Future<void> _seed(SharedPreferences prefs) async {
    if (prefs.getBool(_seedKey) == true) return;
    final products = ref.read(homeDataProvider).newArrivals.take(2).toList();
    state = products.map((p) => CartItem(product: p, quantity: 1, note: '')).toList();
    await _save();
    await prefs.setBool(_seedKey, true);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = state.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_storageKey, raw);
  }

  void add(CartItem item) {
    state = [...state, item];
    _save();
    ref.read(savedForLaterAnalyticsProvider.notifier).recordMove();
  }

  void remove(CartItem item) {
    state = state.where((e) => e.product.id != item.product.id).toList();
    _save();
    ref.read(savedForLaterAnalyticsProvider.notifier).recordMove();
  }
}

final savedForLaterProvider =
    NotifierProvider<SavedForLaterNotifier, List<CartItem>>(SavedForLaterNotifier.new);

class SavedForLaterAnalytics {
  final int moveCount;
  final DateTime? lastMovedAt;

  const SavedForLaterAnalytics({required this.moveCount, required this.lastMovedAt});

  SavedForLaterAnalytics copyWith({int? moveCount, DateTime? lastMovedAt}) {
    return SavedForLaterAnalytics(
      moveCount: moveCount ?? this.moveCount,
      lastMovedAt: lastMovedAt ?? this.lastMovedAt,
    );
  }
}

class SavedForLaterAnalyticsNotifier extends Notifier<SavedForLaterAnalytics> {
  static const _storageKey = 'saved_for_later_analytics';

  @override
  SavedForLaterAnalytics build() {
    _load();
    return const SavedForLaterAnalytics(moveCount: 0, lastMovedAt: null);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey);
    if (raw == null || raw.length < 2) return;
    final count = int.tryParse(raw[0]) ?? 0;
    final last = raw[1].isEmpty ? null : DateTime.tryParse(raw[1]);
    state = SavedForLaterAnalytics(moveCount: count, lastMovedAt: last);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey,
      [
        state.moveCount.toString(),
        state.lastMovedAt?.toIso8601String() ?? '',
      ],
    );
  }

  void recordMove() {
    state = state.copyWith(
      moveCount: state.moveCount + 1,
      lastMovedAt: DateTime.now(),
    );
    _save();
  }
}

final savedForLaterAnalyticsProvider =
    NotifierProvider<SavedForLaterAnalyticsNotifier, SavedForLaterAnalytics>(
  SavedForLaterAnalyticsNotifier.new,
);

class PromoRule {
  final String code;
  final double discountPct;
  final double minSubtotal;
  final bool stackable;

  const PromoRule({
    required this.code,
    required this.discountPct,
    required this.minSubtotal,
    required this.stackable,
  });
}

class AppliedPromo {
  final String code;
  final double discountPct;
  final bool stackable;

  const AppliedPromo({
    required this.code,
    required this.discountPct,
    required this.stackable,
  });
}

class SmartBundle {
  final String code;
  final String name;
  final int discountPct;

  const SmartBundle({required this.code, required this.name, required this.discountPct});
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(CartNotifier.new);

final availablePromosProvider = Provider<List<PromoRule>>((ref) {
  return const [
    PromoRule(code: 'BEAUTY10', discountPct: 0.10, minSubtotal: 100000, stackable: true),
    PromoRule(code: 'GLOW20', discountPct: 0.20, minSubtotal: 300000, stackable: false),
    PromoRule(code: 'SKIN5', discountPct: 0.05, minSubtotal: 0, stackable: true),
  ];
});

class AppliedPromosNotifier extends Notifier<List<AppliedPromo>> {
  @override
  List<AppliedPromo> build() => [];

  String apply({required String code, required double subtotal, required List<PromoRule> rules}) {
    final rule = rules.where((r) => r.code == code).firstOrNull;
    if (rule == null) return 'Promo code not found';
    if (subtotal < rule.minSubtotal) return 'Minimum subtotal Rp ${rule.minSubtotal.toStringAsFixed(0)}';
    if (state.any((p) => p.code == code)) return 'Promo already applied';
    if (state.length >= 2) return 'Max 2 promos can be applied';
    if (!rule.stackable && state.isNotEmpty) return 'This promo cannot be stacked';
    if (state.any((p) => p.stackable == false)) return 'Existing promo cannot be stacked';

    state = [...state, AppliedPromo(code: rule.code, discountPct: rule.discountPct, stackable: rule.stackable)];
    return '';
  }

  void remove(String code) {
    state = state.where((p) => p.code != code).toList();
  }

  void clear() {
    state = [];
  }
}

final appliedPromosProvider = NotifierProvider<AppliedPromosNotifier, List<AppliedPromo>>(
  AppliedPromosNotifier.new,
);

final cartSubtotalProvider = Provider<double>((ref) {
  final items = ref.watch(cartProvider);
  return items.fold(0, (sum, item) => sum + (item.product.discountPrice * item.quantity));
});

final cartDiscountProvider = Provider<double>((ref) {
  final subtotal = ref.watch(cartSubtotalProvider);
  final promos = ref.watch(appliedPromosProvider);
  var discount = promos.fold<double>(0, (sum, p) => sum + (subtotal * p.discountPct));
  if (discount > subtotal) discount = subtotal;
  return discount;
});

final cartTotalProvider = Provider<double>((ref) {
  final subtotal = ref.watch(cartSubtotalProvider);
  final discount = ref.watch(cartDiscountProvider);
  return subtotal - discount;
});

SmartBundle? suggestBundle(List<CartItem> items) {
  if (items.length < 2) return null;
  final categories = items.map((e) => e.product.categoryId).toSet().toList();
  if (categories.length < 2) return null;
  return const SmartBundle(code: 'BUNDLE5', name: 'Routine Pair', discountPct: 5);
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
