import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/product.dart';

class ProductCompareNotifier extends Notifier<List<Product>> {
  @override
  List<Product> build() => [];

  void toggle(Product product) {
    if (state.any((e) => e.id == product.id)) {
      state = state.where((e) => e.id != product.id).toList();
    } else {
      if (state.length >= 3) return;
      state = [...state, product];
    }
  }

  void clear() => state = [];
}

final productCompareProvider =
    NotifierProvider<ProductCompareNotifier, List<Product>>(ProductCompareNotifier.new);

class CompareFavoriteNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void toggle(int id) => state = state == id ? null : id;
}

final compareFavoriteProvider =
    NotifierProvider<CompareFavoriteNotifier, int?>(CompareFavoriteNotifier.new);
