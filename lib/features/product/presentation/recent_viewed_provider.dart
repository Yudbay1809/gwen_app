import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/product.dart';

class RecentViewedNotifier extends Notifier<List<Product>> {
  @override
  List<Product> build() => [];

  void add(Product product) {
    final next = [product, ...state.where((e) => e.id != product.id)];
    state = next.take(10).toList();
  }

  void clear() {
    state = [];
  }
}

final recentViewedProvider =
    NotifierProvider<RecentViewedNotifier, List<Product>>(RecentViewedNotifier.new);
