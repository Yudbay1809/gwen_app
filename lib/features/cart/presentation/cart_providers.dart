import 'dart:convert';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/models/cart_item.dart';
import '../../../shared/models/product.dart';

class CartNotifier extends Notifier<List<CartItem>> {
  static const _storageKey = 'cart_items';

  @override
  List<CartItem> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? [];
    final items = raw
        .map((e) => CartItem.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
    state = items;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = state.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_storageKey, raw);
  }

  void add(Product product) {
    final index = state.indexWhere((e) => e.product.id == product.id);
    if (index == -1) {
      state = [...state, CartItem(product: product, quantity: 1)];
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

  void clear() {
    state = [];
    _save();
  }
}

class PromoState {
  final String code;
  final double discountPct;

  const PromoState({required this.code, required this.discountPct});

  bool get isActive => code.isNotEmpty && discountPct > 0;
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(CartNotifier.new);

final promoProvider = StateProvider<PromoState>((ref) => const PromoState(code: '', discountPct: 0));

final cartSubtotalProvider = Provider<double>((ref) {
  final items = ref.watch(cartProvider);
  return items.fold(0, (sum, item) => sum + (item.product.discountPrice * item.quantity));
});

final cartDiscountProvider = Provider<double>((ref) {
  final subtotal = ref.watch(cartSubtotalProvider);
  final promo = ref.watch(promoProvider);
  return subtotal * promo.discountPct;
});

final cartTotalProvider = Provider<double>((ref) {
  final subtotal = ref.watch(cartSubtotalProvider);
  final discount = ref.watch(cartDiscountProvider);
  return subtotal - discount;
});
