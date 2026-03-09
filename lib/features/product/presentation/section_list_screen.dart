import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../home/presentation/home_providers.dart';
import '../../../shared/widgets/product_card.dart';
import '../../cart/presentation/cart_providers.dart';

enum SectionType { promo, bestSeller, newArrivals }

class SectionListScreen extends ConsumerWidget {
  final SectionType type;

  const SectionListScreen({super.key, required this.type});

  String get _title {
    switch (type) {
      case SectionType.promo:
        return 'Promo';
      case SectionType.bestSeller:
        return 'Best Seller';
      case SectionType.newArrivals:
        return 'New Arrivals';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(homeDataProvider);
    final products = switch (type) {
      SectionType.promo => data.flashSale,
      SectionType.bestSeller => data.bestSeller,
      SectionType.newArrivals => data.newArrivals,
    };

    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.62,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return ProductCard(
            product: product,
            onTap: () => context.go('/product/${product.id}'),
            onAdd: () => ref.read(cartProvider.notifier).add(product),
          );
        },
      ),
    );
  }
}
