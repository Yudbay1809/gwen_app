import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/product.dart';
import '../../home/presentation/home_providers.dart';

class ProductBundle {
  final String name;
  final List<Product> items;
  final double discountPct;

  const ProductBundle({
    required this.name,
    required this.items,
    required this.discountPct,
  });

  double get total => items.fold(0, (s, p) => s + p.discountPrice);
  double get bundleTotal => total * (1 - discountPct);
}

final productBundlesProvider = Provider<List<ProductBundle>>((ref) {
  final data = ref.watch(homeDataProvider);
  if (data.bestSeller.length < 2) return const [];
  return [
    ProductBundle(
      name: 'Glow Starter Kit',
      items: [data.bestSeller[0], data.bestSeller[1]],
      discountPct: 0.15,
    ),
    if (data.newArrivals.length >= 2)
      ProductBundle(
        name: 'Hydration Duo',
        items: [data.newArrivals[0], data.newArrivals[1]],
        discountPct: 0.1,
      ),
  ];
});
