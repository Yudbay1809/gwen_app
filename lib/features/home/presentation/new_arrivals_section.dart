import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/product.dart';
import '../../../shared/widgets/product_card.dart';
import 'section_header.dart';

class NewArrivalsSection extends StatelessWidget {
  final List<Product> products;
  final VoidCallback? onSeeAll;

  const NewArrivalsSection({super.key, required this.products, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'New Arrivals', onSeeAll: onSeeAll),
        SizedBox(
          height: 260,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final product = products[index];
              return SizedBox(
                width: 180,
                child: ProductCard(
                  product: product,
                  onTap: () => context.go('/product/${product.id}'),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemCount: products.length,
          ),
        ),
      ],
    );
  }
}
