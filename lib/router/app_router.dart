import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/auth/presentation/onboarding_screen.dart';
import '../features/auth/presentation/otp_screen.dart';
import '../features/auth/presentation/complete_profile_screen.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/login_otp_screen.dart';
import '../features/auth/presentation/login_otp_verify_screen.dart';
import '../features/auth/presentation/auth_state_provider.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/product/presentation/product_detail_screen.dart';
import '../features/product/presentation/section_list_screen.dart';
import '../features/product/presentation/search_screen.dart';
import '../features/product/presentation/product_list_screen.dart';
import '../features/product/presentation/product_compare_screen.dart';
import '../features/product/presentation/mood_section_screen.dart';
import '../features/cart/presentation/cart_screen.dart';
import '../features/cart/presentation/checkout_screen.dart';
import '../features/cart/presentation/order_success_screen.dart';
import '../features/review/presentation/review_list_screen.dart';
import '../features/review/presentation/create_review_screen.dart';
import '../features/review/presentation/review_detail_screen.dart';
import '../features/review/presentation/review_media_screen.dart';
import '../features/scan/presentation/barcode_scanner_screen.dart';
import '../features/newsfeed/presentation/newsfeed_screen.dart';
import '../features/newsfeed/presentation/article_detail_screen.dart';
import '../features/newsfeed/presentation/newsfeed_saved_screen.dart';
import '../features/newsfeed/presentation/newsfeed_authors_screen.dart';
import '../features/newsfeed/presentation/newsfeed_author_profile_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/profile/presentation/edit_profile_screen.dart';
import '../features/profile/presentation/address_book_screen.dart';
import '../features/profile/presentation/payment_methods_screen.dart';
import '../features/profile/presentation/profile_preferences_screen.dart';
import '../features/profile/presentation/profile_security_screen.dart';
import '../features/profile/presentation/dev_tools_screen.dart';
import '../features/wishlist/presentation/wishlist_screen.dart';
import '../features/orders/presentation/orders_screen.dart';
import '../features/notification/presentation/notification_screen.dart';
import '../features/notification/presentation/notification_detail_screen.dart';
import '../features/notification/presentation/notification_settings_screen.dart';
import '../features/wishlist/presentation/wishlist_collection_detail_screen.dart';
import '../features/store_locator/presentation/store_locator_screen.dart';
import '../features/store_locator/presentation/store_detail_screen.dart';
import '../features/coupons/presentation/coupons_screen.dart';
import '../features/search/presentation/global_search_screen.dart';
import '../features/profile/presentation/dev_tools_settings_provider.dart';
import '../features/analytics/presentation/analytics_log_provider.dart';
import '../features/analytics/presentation/analytics_log_screen.dart';
import '../features/cart/presentation/cart_providers.dart';
import '../core/theme/colors.dart';
import '../core/network/connectivity_provider.dart';
import 'dart:ui';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: routerAuthRefresh,
    redirect: (context, state) {
      final authState = routerAuthState;
      final isLoading = authState?.isLoading ?? true;
      final isLoggedIn = authState?.isLoggedIn ?? false;
      final isAuthRoute = state.uri.path.startsWith('/login') ||
          state.uri.path.startsWith('/register') ||
          state.uri.path.startsWith('/forgot-password') ||
          state.uri.path.startsWith('/login-otp') ||
          state.uri.path.startsWith('/otp') ||
          state.uri.path.startsWith('/complete-profile') ||
          state.uri.path.startsWith('/onboarding') ||
          state.uri.path.startsWith('/splash');
      if (isLoading) {
        return state.uri.path == '/splash' ? null : '/splash';
      }
      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && (state.uri.path == '/login' || state.uri.path == '/onboarding')) {
        return '/shop';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/login-otp',
        builder: (context, state) => const LoginOtpScreen(),
      ),
      GoRoute(
        path: '/login-otp/verify',
        builder: (context, state) =>
            LoginOtpVerifyScreen(phone: state.extra is String ? state.extra as String : ''),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) => const OtpScreen(),
      ),
      GoRoute(
        path: '/complete-profile',
        builder: (context, state) => const CompleteProfileScreen(),
      ),
      GoRoute(
        path: '/product/:id',
        builder: (_, state) => ProductDetailScreen(id: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/products',
        builder: (context, state) => const ProductListScreen(),
      ),
      GoRoute(
        path: '/compare',
        builder: (context, state) => const ProductCompareScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/promo',
        builder: (context, state) => const SectionListScreen(type: SectionType.promo),
      ),
      GoRoute(
        path: '/section/mood/:mood',
        builder: (context, state) => MoodSectionScreen(mood: state.pathParameters['mood'] ?? ''),
      ),
      GoRoute(
        path: '/best-seller',
        builder: (context, state) => const SectionListScreen(type: SectionType.bestSeller),
      ),
      GoRoute(
        path: '/new-arrivals',
        builder: (context, state) => const SectionListScreen(type: SectionType.newArrivals),
      ),
      GoRoute(
        path: '/review/create',
        builder: (context, state) => const CreateReviewScreen(),
      ),
      GoRoute(
        path: '/review/media',
        builder: (context, state) => const ReviewMediaScreen(),
      ),
      GoRoute(
        path: '/review/:id',
        builder: (_, state) => ReviewDetailScreen(id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0),
      ),
      GoRoute(
        path: '/cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/order-success',
        builder: (context, state) =>
            OrderSuccessScreen(args: state.extra is OrderSuccessArgs ? state.extra as OrderSuccessArgs : null),
      ),
      GoRoute(
        path: '/wishlist',
        builder: (context, state) => const WishlistScreen(),
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const OrdersScreen(),
      ),
      GoRoute(
        path: '/article/:id',
        builder: (_, state) => ArticleDetailScreen(id: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/newsfeed/saved',
        builder: (context, state) => const NewsfeedSavedScreen(),
      ),
      GoRoute(
        path: '/newsfeed/authors',
        builder: (context, state) => const NewsfeedAuthorsScreen(),
      ),
      GoRoute(
        path: '/newsfeed/author/:name',
        builder: (context, state) =>
            NewsfeedAuthorProfileScreen(author: state.pathParameters['name'] ?? ''),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationScreen(),
      ),
      GoRoute(
        path: '/notifications/:id',
        builder: (_, state) => NotificationDetailScreen(id: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/notifications/settings',
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: '/wishlist/collection/:name',
        builder: (_, state) => WishlistCollectionDetailScreen(name: state.pathParameters['name'] ?? ''),
      ),
      GoRoute(
        path: '/stores',
        builder: (context, state) => const StoreLocatorScreen(),
      ),
      GoRoute(
        path: '/stores/:id',
        builder: (_, state) => StoreDetailScreen(id: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/coupons',
        builder: (context, state) => const CouponsScreen(),
      ),
      GoRoute(
        path: '/global-search',
        builder: (context, state) => const GlobalSearchScreen(),
      ),
      GoRoute(
        path: '/analytics/logs',
        builder: (context, state) => const AnalyticsLogScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/profile/addresses',
        builder: (context, state) => const AddressBookScreen(),
      ),
      GoRoute(
        path: '/profile/payments',
        builder: (context, state) => const PaymentMethodsScreen(),
      ),
      GoRoute(
        path: '/profile/preferences',
        builder: (context, state) => const ProfilePreferencesScreen(),
      ),
      GoRoute(
        path: '/profile/security',
        builder: (context, state) => const ProfileSecurityScreen(),
      ),
      GoRoute(
        path: '/dev',
        builder: (context, state) => const DevToolsScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/shop',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/review',
            builder: (context, state) => const ReviewListScreen(),
          ),
          GoRoute(
            path: '/scan',
            builder: (context, state) => const BarcodeScannerScreen(),
          ),
          GoRoute(
            path: '/newsfeed',
            builder: (context, state) => const NewsfeedScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
}

class AppShell extends ConsumerStatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  DateTime? _lastBackAt;
  bool _backHintShown = false;

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
        _log('[back] navigate_to_shop');
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
  Widget build(BuildContext context) {
    if (!_backHintShown) {
      _loadBackHint(context);
    }
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _indexFromLocation(location);
    final count = ref.watch(cartProvider).fold<int>(0, (sum, item) => sum + item.quantity);
    final online = ref.watch(connectivityProvider).maybeWhen(data: (v) => v, orElse: () => true);

    return Scaffold(
      body: Stack(
        children: [
          PopScope(
            canPop: currentIndex == 0,
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) return;
              if (currentIndex != 0) {
                _onTap(context, 0);
                _log('[back] from_tab_$currentIndex -> shop');
                return;
              }
              final now = DateTime.now();
              if (_lastBackAt == null || now.difference(_lastBackAt!) > const Duration(seconds: 2)) {
                _lastBackAt = now;
                ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(
                    const SnackBar(content: Text('Press back again to exit')),
                  );
                _log('[back] prompt_exit');
                return;
              }
              _log('[back] exit_app');
              SystemNavigator.pop();
            },
            child: widget.child,
          ),
          if (!online)
            SafeArea(
              child: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withAlpha(220),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wifi_off, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text('You are offline', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _FloatingNavBar(
        currentIndex: currentIndex,
        count: count,
        onTap: (i) => _onTap(context, i),
      ),
    );
  }

  void _log(String message) {
    final enabled = ref.read(devToolsSettingsProvider).analyticsEnabled;
    if (enabled) {
      debugPrint(message);
      ref.read(analyticsLogProvider.notifier).log(message);
    }
  }

  Future<void> _loadBackHint(BuildContext context) async {
    _backHintShown = true;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('back_hint_shown') == true) return;
    if (!context.mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('Tip: swipe from edge to go back')));
    });
    await prefs.setBool('back_hint_shown', true);
  }
}

Widget _navIconWithBadge(IconData icon, int count, {required String label}) {
  return Stack(
    clipBehavior: Clip.none,
    children: [
      Icon(icon),
      if (count > 0)
        Positioned(
          right: -6,
          top: -6,
          child: Semantics(
            label: '$label badge',
            value: '$count new items',
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
        ),
    ],
  );
}

class _FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final int count;
  final ValueChanged<int> onTap;

  const _FloatingNavBar({
    required this.currentIndex,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(220),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
            currentIndex: currentIndex,
            onTap: onTap,
            items: [
              BottomNavigationBarItem(
                icon: _navIconWithBadge(Icons.store, count, label: 'Shop'),
                label: 'Shop',
              ),
              const BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Review'),
              const BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
              const BottomNavigationBarItem(icon: Icon(Icons.feed), label: 'Newsfeed'),
              const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

}

AuthState? routerAuthState;
final ValueNotifier<int> routerAuthRefresh = ValueNotifier<int>(0);
