import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/product/presentation/product_detail_screen.dart';
import '../features/product/presentation/section_list_screen.dart';
import '../features/product/presentation/search_screen.dart';
import '../features/product/presentation/product_list_screen.dart';
import '../features/cart/presentation/cart_screen.dart';
import '../features/cart/presentation/checkout_screen.dart';
import '../features/review/presentation/review_list_screen.dart';
import '../features/review/presentation/create_review_screen.dart';
import '../features/scan/presentation/barcode_scanner_screen.dart';
import '../features/newsfeed/presentation/newsfeed_screen.dart';
import '../features/newsfeed/presentation/article_detail_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/wishlist/presentation/wishlist_screen.dart';
import '../features/orders/presentation/orders_screen.dart';
import '../features/cart/presentation/cart_providers.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/shop',
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/product/:id',
        builder: (_, state) => ProductDetailScreen(id: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/products',
        builder: (_, __) => const ProductListScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (_, __) => const SearchScreen(),
      ),
      GoRoute(
        path: '/promo',
        builder: (_, __) => const SectionListScreen(type: SectionType.promo),
      ),
      GoRoute(
        path: '/best-seller',
        builder: (_, __) => const SectionListScreen(type: SectionType.bestSeller),
      ),
      GoRoute(
        path: '/new-arrivals',
        builder: (_, __) => const SectionListScreen(type: SectionType.newArrivals),
      ),
      GoRoute(
        path: '/review/create',
        builder: (_, __) => const CreateReviewScreen(),
      ),
      GoRoute(
        path: '/cart',
        builder: (_, __) => const CartScreen(),
      ),
      GoRoute(
        path: '/checkout',
        builder: (_, __) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/wishlist',
        builder: (_, __) => const WishlistScreen(),
      ),
      GoRoute(
        path: '/orders',
        builder: (_, __) => const OrdersScreen(),
      ),
      GoRoute(
        path: '/article/:id',
        builder: (_, state) => ArticleDetailScreen(id: state.pathParameters['id'] ?? ''),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/shop',
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: '/review',
            builder: (_, __) => const ReviewListScreen(),
          ),
          GoRoute(
            path: '/scan',
            builder: (_, __) => const BarcodeScannerScreen(),
          ),
          GoRoute(
            path: '/newsfeed',
            builder: (_, __) => const NewsfeedScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
}

class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  int _indexFromLocation(String location) {
    if (location.startsWith('/review')) return 1;
    if (location.startsWith('/scan')) return 2;
    if (location.startsWith('/newsfeed')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/shop');
        break;
      case 1:
        context.go('/review');
        break;
      case 2:
        context.go('/scan');
        break;
      case 3:
        context.go('/newsfeed');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _indexFromLocation(location);
    final count = ref.watch(cartProvider).fold<int>(0, (sum, item) => sum + item.quantity);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i) => _onTap(context, i),
        items: [
          BottomNavigationBarItem(
            icon: _navIconWithBadge(Icons.store, count),
            label: 'Shop',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Review'),
          const BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
          const BottomNavigationBarItem(icon: Icon(Icons.feed), label: 'Newsfeed'),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _navIconWithBadge(IconData icon, int count) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
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
    );
  }
}
