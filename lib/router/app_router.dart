import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
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
import '../features/product/presentation/brand_browse_screen.dart';
import '../features/product/presentation/search_screen.dart';
import '../features/product/presentation/product_list_screen.dart';
import '../features/product/presentation/product_compare_screen.dart';
import '../features/product/presentation/mood_section_screen.dart';
import '../features/product/presentation/category_browse_screen.dart';
import '../features/cart/presentation/cart_screen.dart';
import '../features/cart/presentation/checkout_screen.dart';
import '../features/cart/presentation/payment_screen.dart';
import '../features/cart/presentation/order_success_screen.dart';
import '../features/review/presentation/review_list_screen.dart';
import '../features/review/presentation/create_review_screen.dart';
import '../features/review/presentation/review_detail_screen.dart';
import '../features/review/presentation/review_media_screen.dart';
import '../features/shorts/presentation/beauty_shorts_screen.dart';
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
import '../features/profile/presentation/loyalty_benefits_screen.dart';
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
import '../core/network/connectivity_provider.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
bool routerJustLoggedIn = false;

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
      if (isLoggedIn && routerJustLoggedIn) {
        routerJustLoggedIn = false;
        if (state.uri.path != '/shop') return '/shop';
      }
      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && (state.uri.path == '/login' || state.uri.path == '/onboarding')) {
        return '/shop';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) => '/shop',
      ),
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
            LoginOtpVerifyScreen(
              args: state.extra is OtpVerifyArgs
                  ? state.extra as OtpVerifyArgs
                  : OtpVerifyArgs(
                      phone: state.extra is String ? state.extra as String : '',
                      method: 'WhatsApp',
                    ),
            ),
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
        path: '/categories',
        builder: (context, state) {
          final id = int.tryParse(state.uri.queryParameters['initialId'] ?? '');
          return CategoryBrowseScreen(initialId: id);
        },
      ),
      GoRoute(
        path: '/brands',
        builder: (context, state) => const BrandBrowseScreen(),
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
        path: '/payment',
        builder: (context, state) => const PaymentScreen(),
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
        path: '/loyalty/benefits',
        builder: (context, state) => const LoyaltyBenefitsScreen(),
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
              path: '/shorts',
              builder: (context, state) => const BeautyShortsScreen(),
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
  bool _showTutorial = false;
  int _tutorialIndex = 0;
  final List<GlobalKey> _navKeys = List.generate(6, (_) => GlobalKey());

  @override
  void initState() {
    super.initState();
    _loadTutorial();
  }

  Future<void> _loadTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool('nav_tutorial_shown') ?? false;
    if (!mounted) return;
    if (!shown) {
      setState(() => _showTutorial = true);
    }
  }

  int _indexFromLocation(String location) {
    if (location.startsWith('/review')) return 1;
    if (location.startsWith('/shorts')) return 2;
    if (location.startsWith('/scan')) return 3;
    if (location.startsWith('/newsfeed')) return 4;
    if (location.startsWith('/profile')) return 5;
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
        context.go('/shorts');
        break;
      case 3:
        context.go('/scan');
        break;
      case 4:
        context.go('/newsfeed');
        break;
      case 5:
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

      final hideNav = location.startsWith('/shorts') && !_showTutorial;
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
            if (_showTutorial)
              _BottomNavTutorialOverlay(
                target: _targetRect(_tutorialIndex),
                step: _tutorialSteps[_tutorialIndex],
                total: _tutorialSteps.length,
                index: _tutorialIndex,
                fullScreenStyle: location.startsWith('/shorts') && _tutorialIndex == 2,
                onSkip: _finishTutorial,
                onNext: () {
                  if (_tutorialIndex >= _tutorialSteps.length - 1) {
                    _finishTutorial();
                  } else {
                  setState(() => _tutorialIndex += 1);
                  _onTap(context, _tutorialIndex);
                }
              },
            ),
        ],
        ),
        floatingActionButton: null,
        bottomNavigationBar: hideNav
            ? null
            : _FloatingNavBar(
                currentIndex: currentIndex,
                count: count,
                onTap: (i) => _onTap(context, i),
                iconKeys: _navKeys,
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

  Rect? _targetRect(int index) {
    if (index < 0 || index >= _navKeys.length) return null;
    final ctx = _navKeys[index].currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final offset = box.localToGlobal(Offset.zero);
    return offset & box.size;
  }

  Future<void> _finishTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('nav_tutorial_shown', true);
    if (!mounted) return;
    setState(() {
      _showTutorial = false;
      _tutorialIndex = 0;
    });
  }
}


class _FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final int count;
  final ValueChanged<int> onTap;
  final List<GlobalKey> iconKeys;

  const _FloatingNavBar({
    required this.currentIndex,
    required this.count,
    required this.onTap,
    required this.iconKeys,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final items = const [
      _NavItemData(
        label: 'Shop',
        icon: Icons.storefront_outlined,
        activeIcon: Icons.storefront,
      ),
      _NavItemData(
        label: 'Review',
        icon: Icons.star_border,
        activeIcon: Icons.star,
      ),
      _NavItemData(
        label: 'Shorts',
        icon: Icons.smart_display_outlined,
        activeIcon: Icons.smart_display,
      ),
      _NavItemData(
        label: 'Scan',
        icon: Icons.qr_code_scanner,
        activeIcon: Icons.qr_code_scanner,
      ),
      _NavItemData(
        label: 'Newsfeed',
        icon: Icons.feed_outlined,
        activeIcon: Icons.feed,
      ),
      _NavItemData(
        label: 'Profile',
        icon: Icons.person_outline,
        activeIcon: Icons.person,
      ),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outline),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SafeArea(
          top: false,
          left: false,
          right: false,
          minimum: const EdgeInsets.only(bottom: 2),
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: _NavItem(
                      data: items[i],
                      selected: i == currentIndex,
                      badgeCount: i == 0 ? count : 0,
                      onTap: () => onTap(i),
                      labelStyle: theme.textTheme.labelSmall,
                      iconKey: iconKeys[i],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

class _NavItemData {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _NavItemData({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

class _NavItem extends StatefulWidget {
  final _NavItemData data;
  final bool selected;
  final int badgeCount;
  final VoidCallback onTap;
  final TextStyle? labelStyle;
  final GlobalKey? iconKey;

  const _NavItem({
    required this.data,
    required this.selected,
    required this.badgeCount,
    required this.onTap,
    required this.labelStyle,
    required this.iconKey,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;
  late final AnimationController _badgeController;
  late final Animation<double> _badgeScale;
  int _lastBadgeCount = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _pulseScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.12), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.12, end: 1.0), weight: 45),
    ]).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOutCubic));

    _badgeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _badgeScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.16), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.16, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _badgeController, curve: Curves.easeOutCubic));
    _lastBadgeCount = widget.badgeCount;
  }

  @override
  void didUpdateWidget(covariant _NavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !oldWidget.selected) {
      _pulseController.forward(from: 0);
    }
    if (widget.badgeCount != _lastBadgeCount && widget.badgeCount > 0) {
      _badgeController.forward(from: 0);
    }
    _lastBadgeCount = widget.badgeCount;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _badgeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final activeColor = scheme.primary;
    final inactiveColor = scheme.onSurfaceVariant.withAlpha(150);
    final iconColor = widget.selected ? activeColor : inactiveColor;
    return Semantics(
      selected: widget.selected,
      button: true,
      label: widget.data.label,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        splashColor: activeColor.withAlpha(30),
        highlightColor: activeColor.withAlpha(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSlide(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                offset: widget.selected ? const Offset(0, -0.06) : Offset.zero,
                child: AnimatedBuilder(
                  animation: _pulseScale,
                  builder: (context, child) => Transform.scale(scale: _pulseScale.value, child: child),
                  child: SizedBox(
                    width: 36,
                    height: 28,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        height: 28,
                        width: 36,
                        decoration: BoxDecoration(
                          color: widget.selected ? activeColor.withAlpha(28) : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        ),
                        Icon(
                          widget.selected ? widget.data.activeIcon : widget.data.icon,
                          color: iconColor,
                          size: 22,
                          key: widget.iconKey,
                        ),
                        if (widget.badgeCount > 0)
                          Positioned(
                            right: -6,
                            top: -6,
                            child: AnimatedBuilder(
                              animation: _badgeScale,
                              builder: (context, child) =>
                                  Transform.scale(scale: _badgeScale.value, child: child),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                constraints: const BoxConstraints(minWidth: 16),
                                child: Text(
                                  '${widget.badgeCount}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              AnimatedSlide(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                offset: widget.selected ? const Offset(0, -0.03) : Offset.zero,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  opacity: widget.selected ? 1.0 : 0.6,
                  child: Text(
                    widget.data.label,
                    style: widget.labelStyle?.copyWith(
                      color: iconColor,
                      fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                height: 3.5,
                width: widget.selected ? 24 : 6,
                decoration: BoxDecoration(
                  color: widget.selected ? activeColor.withAlpha(180) : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

AuthState? routerAuthState;
final ValueNotifier<int> routerAuthRefresh = ValueNotifier<int>(0);

class _TutorialStep {
  final String title;
  final String description;
  final String cta;

  const _TutorialStep({
    required this.title,
    required this.description,
    required this.cta,
  });
}

const _tutorialSteps = [
  _TutorialStep(
    title: 'Shop',
    description: 'Temukan skincare, makeup, dan promo terbaik di GWEN Beauty.',
    cta: 'NEXT',
  ),
  _TutorialStep(
    title: 'Review',
    description: 'Baca ulasan terpercaya dan share pengalamanmu.',
    cta: 'NEXT',
  ),
  _TutorialStep(
    title: 'Beauty Shorts',
    description: 'Scroll video singkat untuk inspirasi dan rekomendasi produk.',
    cta: 'NEXT',
  ),
  _TutorialStep(
    title: 'Scan',
    description: 'Scan barcode/QR untuk info produk dan promo instan.',
    cta: 'NEXT',
  ),
  _TutorialStep(
    title: 'Newsfeed',
    description: 'Ikuti trend, tips, dan inspirasi beauty terbaru.',
    cta: 'NEXT',
  ),
  _TutorialStep(
    title: 'My Profile',
    description: 'Atur akun, pesanan, dan preferensi beauty kamu.',
    cta: 'DONE',
  ),
];

class _BottomNavTutorialOverlay extends StatefulWidget {
  final Rect? target;
  final _TutorialStep step;
  final int index;
  final int total;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final bool fullScreenStyle;

  const _BottomNavTutorialOverlay({
    required this.target,
    required this.step,
    required this.index,
    required this.total,
    required this.onNext,
    required this.onSkip,
    this.fullScreenStyle = false,
  });

  @override
  State<_BottomNavTutorialOverlay> createState() => _BottomNavTutorialOverlayState();
}

class _BottomNavTutorialOverlayState extends State<_BottomNavTutorialOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;
  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;
  Rect? _lastTarget;
  Timer? _autoNextTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _cardFade = CurvedAnimation(parent: _pulseController, curve: const Interval(0.0, 0.2));
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _autoNextTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _BottomNavTutorialOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.target != null) {
      _lastTarget = widget.target;
      _autoNextTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (widget.fullScreenStyle) {
      return Positioned.fill(
        child: GestureDetector(
          onTap: widget.onNext,
          behavior: HitTestBehavior.opaque,
          child: Container(
            color: Colors.black.withAlpha(160),
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: FadeTransition(
                  opacity: _cardFade,
                  child: SlideTransition(
                    position: _cardSlide,
                    child: AnimatedBuilder(
                      animation: _pulse,
                      builder: (context, child) => Transform.scale(
                        scale: _pulse.value,
                        child: child,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
                            decoration: BoxDecoration(
                              color: scheme.primary.withAlpha(235),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: Colors.white.withAlpha(40)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(70),
                                  blurRadius: 28,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      widget.step.title,
                                      style: TextStyle(
                                        color: scheme.onPrimary,
                                        fontSize: 19,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withAlpha(30),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${widget.index + 1}/${widget.total}',
                                        style: TextStyle(color: scheme.onPrimary.withAlpha(220)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  widget.step.description,
                                  style: TextStyle(color: scheme.onPrimary.withAlpha(230), height: 1.4),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    TextButton(
                                      onPressed: widget.onSkip,
                                      child: Text('SKIP', style: TextStyle(color: scheme.onPrimary.withAlpha(220))),
                                    ),
                                    const Spacer(),
                                    TextButton(
                                      onPressed: widget.onNext,
                                      child: Text(widget.step.cta, style: TextStyle(color: scheme.onPrimary)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    if (widget.target != null) {
      _lastTarget = widget.target;
    }
    final target = widget.target ?? _lastTarget;
    if (target == null) {
      _autoNextTimer?.cancel();
      _autoNextTimer = Timer(const Duration(milliseconds: 650), () {
        if (!mounted) return;
        widget.onNext();
      });
      return Positioned.fill(
        child: Container(
          color: Colors.black.withAlpha(120),
          alignment: Alignment.bottomCenter,
          padding: const EdgeInsets.only(bottom: 120),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'Menyiapkan tutorial...',
              style: TextStyle(color: scheme.onPrimary, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      );
    }
    final center = target.center;
    final radius = math.max(target.width, target.height) * 1.1;

    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final bubbleWidth = math.min(320.0, width - 32);
          final bubbleLeft = (center.dx - bubbleWidth / 2).clamp(16.0, width - bubbleWidth - 16.0);
          final bubbleAbove = target.top - 190 > 80;
          final bubbleTop = bubbleAbove ? (target.top - 180) : (target.bottom + 14);
          final arrowX = center.dx.clamp(bubbleLeft + 16, bubbleLeft + bubbleWidth - 16);
          final arrowY = bubbleAbove ? bubbleTop + 150 : bubbleTop - 10;

          return Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTap: widget.onNext,
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedBuilder(
                      animation: _pulse,
                      builder: (context, _) => CustomPaint(
                        painter: _SpotlightPainter(
                          center: center,
                          radius: radius * _pulse.value,
                          dimColor: Colors.black.withAlpha(150),
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: center.dx - radius,
                top: center.dy - radius,
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, child) => Transform.scale(
                    scale: _pulse.value,
                    child: child,
                  ),
                  child: Container(
                    width: radius * 2,
                    height: radius * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: scheme.primary.withAlpha(220), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.primary.withAlpha(140),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: arrowX - 8,
                top: arrowY,
                child: CustomPaint(
                  size: const Size(16, 10),
                  painter: _ArrowPainter(color: scheme.primary, pointDown: bubbleAbove),
                ),
              ),
              Positioned(
                left: bubbleLeft,
                top: bubbleTop,
                child: SizedBox(
                  width: bubbleWidth,
                  child: FadeTransition(
                    opacity: _cardFade,
                    child: SlideTransition(
                      position: _cardSlide,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 240),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: Container(
                          key: ValueKey(widget.step.title),
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(25),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    widget.step.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${widget.index + 1}/${widget.total}',
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.step.description,
                                style: const TextStyle(color: Colors.white70, height: 1.4),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  TextButton(
                                    onPressed: widget.onSkip,
                                    child: const Text('SKIP', style: TextStyle(color: Colors.white70)),
                                  ),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: widget.onNext,
                                    child: Text(
                                      widget.step.cta,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Offset center;
  final double radius;
  final Color dimColor;

  _SpotlightPainter({
    required this.center,
    required this.radius,
    required this.dimColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final layerPaint = Paint();
    canvas.saveLayer(rect, layerPaint);
    canvas.drawRect(rect, Paint()..color = dimColor);
    final clearPaint = Paint()..blendMode = BlendMode.clear;
    canvas.drawCircle(center, radius, clearPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.center != center || oldDelegate.radius != radius || oldDelegate.dimColor != dimColor;
  }
}

class _ArrowPainter extends CustomPainter {
  final Color color;
  final bool pointDown;

  _ArrowPainter({required this.color, required this.pointDown});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    if (pointDown) {
      path
        ..moveTo(size.width / 2, size.height)
        ..lineTo(0, 0)
        ..lineTo(size.width, 0)
        ..close();
    } else {
      path
        ..moveTo(size.width / 2, 0)
        ..lineTo(0, size.height)
        ..lineTo(size.width, size.height)
        ..close();
    }
    canvas.drawShadow(path, Colors.black.withAlpha(60), 3, false);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.pointDown != pointDown;
}
