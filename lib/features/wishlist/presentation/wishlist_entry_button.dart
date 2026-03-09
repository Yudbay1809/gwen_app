import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'wishlist_providers.dart';

class WishlistEntryButton extends ConsumerWidget {
  const WishlistEntryButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(wishlistProvider).length;

    return IconButton(
      onPressed: () => context.go('/wishlist'),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.favorite_border, color: Colors.pink.shade300),
          if (count > 0)
            Positioned(
              right: -6,
              top: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(minWidth: 18),
                child: Text(
                  '$count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
