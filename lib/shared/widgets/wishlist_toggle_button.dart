import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/wishlist/presentation/wishlist_providers.dart';
import '../models/product.dart';

class WishlistToggleButton extends ConsumerWidget {
  final Product product;
  final double size;

  const WishlistToggleButton({super.key, required this.product, this.size = 20});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWishlisted = ref.watch(wishlistProvider).any((e) => e.id == product.id);

    return IconButton(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      icon: Icon(
        isWishlisted ? Icons.favorite : Icons.favorite_border,
        size: size,
        color: isWishlisted ? Colors.redAccent : Colors.grey,
      ),
      onPressed: () => ref.read(wishlistProvider.notifier).toggle(product),
    );
  }
}
