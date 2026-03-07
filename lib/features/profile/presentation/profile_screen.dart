import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../wishlist/presentation/wishlist_entry_button.dart';
import 'profile_menu_tile.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: const [WishlistEntryButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CircleAvatar(radius: 32, child: Icon(Icons.person)),
          const SizedBox(height: 12),
          const Center(child: Text('Guest User', style: TextStyle(fontWeight: FontWeight.w700))),
          const SizedBox(height: 24),
          ProfileMenuTile(
            icon: Icons.favorite_border,
            title: 'Wishlist',
            onTap: () => context.go('/wishlist'),
          ),
          ProfileMenuTile(
            icon: Icons.receipt_long,
            title: 'Orders',
            onTap: () => context.go('/orders'),
          ),
          ProfileMenuTile(
            icon: Icons.settings,
            title: 'Settings',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
