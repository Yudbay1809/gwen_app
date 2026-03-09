import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/product.dart';
import '../../../shared/widgets/product_card.dart';
import 'section_header.dart';
import '../../cart/presentation/cart_providers.dart';

class FlashSaleSection extends ConsumerWidget {
  final List<Product> products;
  final VoidCallback? onSeeAll;

  const FlashSaleSection({super.key, required this.products, this.onSeeAll});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Flash Sale', onSeeAll: onSeeAll),
        SizedBox(
          height: 248,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final product = products[index];
              return SizedBox(
                width: 180,
                child: ProductCard(
                  product: product,
                  onTap: () => context.go('/product/${product.id}'),
                  onAdd: () => ref.read(cartProvider.notifier).add(product),
                ),
              );
            },
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemCount: products.length,
          ),
        ),
      ],
    ),
    );
  }
}
