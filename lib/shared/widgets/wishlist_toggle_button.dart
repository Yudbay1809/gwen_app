import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/wishlist/presentation/wishlist_providers.dart';
import '../../features/wishlist/presentation/wishlist_collections_provider.dart';
import '../models/product.dart';

class WishlistToggleButton extends ConsumerWidget {
  final Product product;
  final double size;

  const WishlistToggleButton({super.key, required this.product, this.size = 20});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWishlisted = ref.watch(wishlistProvider).any((e) => e.id == product.id);
    final collections = ref.watch(wishlistCollectionsProvider);

    return IconButton(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      icon: Icon(
        isWishlisted ? Icons.favorite : Icons.favorite_border,
        size: size,
        color: isWishlisted ? Colors.redAccent : Colors.grey,
      ),
      onPressed: () {
        if (isWishlisted) {
          ref.read(wishlistProvider.notifier).toggle(product);
          return;
        }

        if (collections.isEmpty) {
          ref.read(wishlistProvider.notifier).toggle(product);
          return;
        }

        showModalBottomSheet(
          context: context,
          showDragHandle: true,
          builder: (_) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Add to wishlist', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                ListTile(
                  title: const Text('Just wishlist'),
                  onTap: () {
                    ref.read(wishlistProvider.notifier).toggle(product);
                    Navigator.pop(context);
                  },
                ),
                const Divider(),
                const Text('Collections', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                ...collections.map(
                  (c) => ListTile(
                    title: Text(c.name),
                    subtitle: Text('${c.items.length} items'),
                    onTap: () {
                      ref.read(wishlistProvider.notifier).toggle(product);
                      ref.read(wishlistCollectionsProvider.notifier).addToCollection(c.name, product);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Added to ${c.name}')),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
