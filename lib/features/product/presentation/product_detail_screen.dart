import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/price_widget.dart';
import '../../../shared/widgets/rating_stars.dart';
import '../../../shared/widgets/discount_badge.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/cart_badge_button.dart';
import '../../home/presentation/home_providers.dart';
import '../../cart/presentation/cart_providers.dart';
import '../../wishlist/presentation/wishlist_providers.dart';

class ProductDetailScreen extends ConsumerWidget {
  final String id;

  const ProductDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(homeDataProvider);
    final productId = int.tryParse(id);
    final product = productId == null
        ? null
        : data.allProducts.where((p) => p.id == productId).firstOrNull;

    if (product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product')),
        body: const Center(child: Text('Product not found')),
      );
    }

    final hasDiscount = product.discountPrice < product.price;
    final isWishlisted = ref.watch(wishlistProvider).any((e) => e.id == product.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          IconButton(
            icon: Icon(isWishlisted ? Icons.favorite : Icons.favorite_border),
            onPressed: () {
              ref.read(wishlistProvider.notifier).toggle(product);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(isWishlisted ? 'Removed from wishlist' : 'Added to wishlist')),
              );
            },
          ),
          const CartBadgeButton(),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.network(
                  product.image,
                  height: 320,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                if (hasDiscount)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: DiscountBadge(
                      text: '-${(((product.price - product.discountPrice) / product.price) * 100).round()}%',
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  RatingStars(rating: product.rating),
                  const SizedBox(height: 12),
                  PriceWidget(price: product.discountPrice),
                  if (hasDiscount)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Rp ${product.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  const Text(
                    'Description',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'A lightweight, hydrating formula designed to keep your skin fresh and radiant. '
                    'Suitable for daily use and all skin types.',
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      label: 'Add to Cart',
                      onPressed: () {
                        ref.read(cartProvider.notifier).add(product);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Added to cart')),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
