import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import 'package:go_router/go_router.dart';
import 'banner_slider.dart';
import 'flash_sale_section.dart';
import 'best_seller_section.dart';
import 'new_arrivals_section.dart';
import 'exclusive_products_section.dart';
import 'category_grid.dart';
import 'brand_carousel.dart';
import 'search_bar_widget.dart';
import 'home_providers.dart';
import 'home_shimmer.dart';
import '../../../shared/widgets/cart_badge_button.dart';
import '../../notification/presentation/notification_providers.dart';
import '../../profile/presentation/dev_tools_settings_provider.dart';
import '../../profile/presentation/beauty_profile_provider.dart';
import '../../auth/presentation/auth_state_provider.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../product/presentation/recent_viewed_provider.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../shared/widgets/shimmer_loader.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/price_widget.dart';
import '../../../shared/models/product.dart';
import '../../../core/utils/formatter.dart';
import 'home_mood_provider.dart';
import '../../cart/presentation/cart_providers.dart';
import '../../product/presentation/product_compare_provider.dart';
import '../../wishlist/presentation/wishlist_providers.dart';
import '../../wishlist/presentation/wishlist_price_history_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  _HomeTab _tab = _HomeTab.flash;
  _HomeQuickFilter _quickFilter = _HomeQuickFilter.none;
  final _scrollController = ScrollController();
  final _allQueryController = TextEditingController();
  static const _scrollKeyPrefix = 'home_all_scroll_';
  Timer? _scrollSaveTimer;
  bool _prefetched = false;
  final _categoryKey = GlobalKey();
  final _brandKey = GlobalKey();
  final _exclusiveKey = GlobalKey();
  bool _showCategory = false;
  bool _showPersonalized = false;
  bool _showBrand = false;
  bool _showExclusive = false;
  bool _showBackToTop = false;
  late final AnimationController _filterFadeController;
  late final Animation<double> _filterFade;
  bool _guestBannerDismissed = false;
  bool _showPriceDropChip = false;

  @override
  void initState() {
    super.initState();
    _filterFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _filterFade = CurvedAnimation(parent: _filterFadeController, curve: Curves.easeOutCubic);
    _filterFadeController.value = 1;
    _scrollController.addListener(_handleScroll);
    _restoreScroll();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _allQueryController.dispose();
    _scrollSaveTimer?.cancel();
    _saveScrollImmediate();
    _filterFadeController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    final offset = _scrollController.offset;
    if (!_showCategory && offset > 220) setState(() => _showCategory = true);
    if (!_showPersonalized && offset > 380) setState(() => _showPersonalized = true);
    if (!_showBrand && offset > 520) setState(() => _showBrand = true);
    if (!_showExclusive && offset > 680) setState(() => _showExclusive = true);
    if (!_showBackToTop && offset > 900) setState(() => _showBackToTop = true);
    if (_showBackToTop && offset < 600) setState(() => _showBackToTop = false);
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.maxScrollExtent - position.pixels < 360) {
      ref.read(homeInfiniteProductsProvider.notifier).loadMore();
    }
    _scrollSaveTimer?.cancel();
    _scrollSaveTimer = Timer(const Duration(milliseconds: 400), _saveScrollImmediate);
  }

  Future<void> _restoreScroll() async {
    final prefs = await SharedPreferences.getInstance();
    final filter = ref.read(homeAllProductsFilterProvider).filter;
    final saved = prefs.getDouble(_scrollKeyFor(filter));
    if (saved == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(saved);
    });
  }

  Future<void> _saveScrollImmediate() async {
    if (!_scrollController.hasClients) return;
    final prefs = await SharedPreferences.getInstance();
    final filter = ref.read(homeAllProductsFilterProvider).filter;
    await prefs.setDouble(_scrollKeyFor(filter), _scrollController.offset);
  }

  String _scrollKeyFor(HomeAllProductsFilter filter) => '$_scrollKeyPrefix${filter.name}';

  Future<void> _jumpToKey(GlobalKey key) async {
    final ctx = key.currentContext;
    if (ctx == null) {
      setState(() {
        _showCategory = true;
        _showBrand = true;
        _showExclusive = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final nextCtx = key.currentContext;
        if (nextCtx == null) return;
        Scrollable.ensureVisible(
          nextCtx,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      });
      return;
    }
    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<HomeData>>(homeLoadProvider, (prev, next) {
      next.whenData((data) {
        if (_prefetched || !mounted) return;
        _prefetched = true;
        for (final url in data.bannerImages) {
          precacheImage(NetworkImage(url), context);
        }
        for (final p in data.allProducts.take(6)) {
          precacheImage(NetworkImage(p.image), context);
        }
      });
    });
    ref.listen<HomeAllProductsFilterState>(homeAllProductsFilterProvider, (prev, next) {
      if (_allQueryController.text != next.query) {
        _allQueryController.text = next.query;
      }
      if (prev?.filter != next.filter) {
        _restoreScroll();
      }
    });

    final asyncData = ref.watch(homeLoadProvider);
    final unread = ref.watch(unreadNotificationCountProvider);
    final devSettings = ref.watch(devToolsSettingsProvider);
    final reduceMotion = devSettings.reduceMotion;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: asyncData.when(
        loading: () => const HomeShimmer(),
        error: (error, stack) => ErrorBanner(
          message: 'Failed to load home data.',
          onRetry: () => ref.refresh(homeLoadProvider),
        ),
        data: (data) {
          final infiniteState = ref.watch(homeInfiniteProductsProvider);
          final filterState = ref.watch(homeAllProductsFilterProvider);
          final allFilter = filterState.filter;
          final allQuery = filterState.query;
          final auth = ref.watch(authProvider);
          final beautyProfile = ref.watch(beautyProfileProvider);
          final compareItems = ref.watch(productCompareProvider);
          final filteredItems = _applyFilter(infiniteState.items, allFilter, allQuery, _quickFilter);
          final sortedFilteredItems = _sortByStock(filteredItems);
          final showEmpty = filteredItems.isEmpty && !infiniteState.isLoading;
          final wishlistItems = ref.watch(wishlistProvider);
          final priceHistory = ref.watch(wishlistPriceHistoryProvider);
          final priceDropItems = _buildPriceDropItems(wishlistItems, priceHistory);
          if (!_showPriceDropChip && priceDropItems.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _showPriceDropChip = true);
            });
          }
          return Stack(
            children: [
              RefreshIndicator(
          onRefresh: () async => ref.refresh(homeLoadProvider),
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 150,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                surfaceTintColor: Colors.transparent,
                title: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/logos/gwen_logo.png',
                        height: 28,
                        width: 28,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text('Shop'),
                    if (priceDropItems.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      AnimatedScale(
                        scale: _showPriceDropChip ? 1 : 0.9,
                        duration: const Duration(milliseconds: 420),
                        curve: Curves.easeOutBack,
                        child: AnimatedOpacity(
                          opacity: _showPriceDropChip ? 1 : 0,
                          duration: const Duration(milliseconds: 260),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.secondary.withValues(alpha: 0.9),
                                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.9),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.12),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.trending_down, size: 12, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  'Price drops',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(32),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      'Curated picks for your glow routine',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    onPressed: () => context.go('/global-search'),
                    icon: const Icon(Icons.manage_search),
                  ),
                  IconButton(
                    onPressed: () => context.go('/notifications'),
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.notifications_none),
                        if (unread > 0)
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
                                '$unread',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const CartBadgeButton(),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: Container(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.surface,
                              Theme.of(context).colorScheme.primaryContainer,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Theme.of(context).colorScheme.outline),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(10),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.primary.withAlpha(24),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.waving_hand_rounded,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Halo, Gwen',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Selamat datang di GWEN Cosmetic',
                                  style: TextStyle(
                                    color: Colors.black87.withAlpha(130),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
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
              SliverPersistentHeader(
                pinned: true,
                delegate: _SearchBarHeaderDelegate(
                  child: Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: const SearchBarWidget(),
                  ),
                ),
              ),
              if (!auth.isLoggedIn && !_guestBannerDismissed)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).colorScheme.outline),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lock_outline, size: 18),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Login untuk menyimpan wishlist & riwayat pesanan.',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go('/login'),
                            child: const Text('Login'),
                          ),
                          TextButton(
                            onPressed: () => context.go('/register'),
                            child: const Text('Register'),
                          ),
                          IconButton(
                            onPressed: () => setState(() => _guestBannerDismissed = true),
                            icon: const Icon(Icons.close, size: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: _SectionReveal(
                  delay: 60,
                  enabled: devSettings.homeAnimations && !reduceMotion,
                  child: BannerSlider(images: data.bannerImages),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              const SliverToBoxAdapter(
                child: _SectionReveal(
                  delay: 90,
                  enabled: true,
                  child: _HeroPromoCard(),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              SliverToBoxAdapter(
                child: _SectionReveal(
                  delay: 100,
                  enabled: devSettings.homeAnimations && !reduceMotion,
                  child: const _PromoGrid(),
                ),
              ),
              SliverToBoxAdapter(
                child: _SectionReveal(
                  delay: 110,
                  enabled: devSettings.homeAnimations && !reduceMotion,
                  child: _DealOfTheDayCard(data: data),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              const SliverToBoxAdapter(child: _MissionCard()),
              if (priceDropItems.isNotEmpty) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 10)),
                SliverToBoxAdapter(
                  child: _SectionReveal(
                    delay: 115,
                    enabled: devSettings.homeAnimations && !reduceMotion,
                    child: _PriceDropQuickSection(items: priceDropItems),
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverToBoxAdapter(
                child: _SectionReveal(
                  delay: 120,
                  enabled: devSettings.homeAnimations && !reduceMotion,
                  child: FlashSaleSection(
                    products: data.flashSale,
                    onSeeAll: () => context.go('/promo'),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: () => _jumpToKey(_categoryKey),
                        child: const Text('Categories'),
                      ),
                      TextButton(
                        onPressed: () => _jumpToKey(_brandKey),
                        child: const Text('Brands'),
                      ),
                      TextButton(
                        onPressed: () => _jumpToKey(_exclusiveKey),
                        child: const Text('Exclusive'),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              SliverToBoxAdapter(
                child: _SectionReveal(
                  delay: 150,
                  enabled: devSettings.homeAnimations && !reduceMotion,
                  child: _HomeSectionTabs(
                    selected: _tab,
                    onSelect: (t) => setState(() => _tab = t),
                    ),
                  ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 4)),
              SliverToBoxAdapter(
                child: _SectionReveal(
                  delay: 180,
                  enabled: devSettings.homeAnimations && !reduceMotion,
                  child: _tab == _HomeTab.flash
                      ? FlashSaleSection(
                          products: data.flashSale,
                          onSeeAll: () => context.go('/promo'),
                        )
                      : _tab == _HomeTab.best
                          ? BestSellerSection(
                              products: data.bestSeller,
                              onSeeAll: () => context.go('/best-seller'),
                            )
                          : NewArrivalsSection(
                              products: data.newArrivals,
                              onSeeAll: () => context.go('/new-arrivals'),
                            ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              if (_showCategory)
                SliverToBoxAdapter(
                  child: _SectionReveal(
                    delay: 240,
                    enabled: devSettings.homeAnimations && !reduceMotion,
                    child: KeyedSubtree(
                      key: _categoryKey,
                      child: CategoryGrid(categories: data.categories),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              if (_showPersonalized)
                SliverToBoxAdapter(
                  child: _SectionReveal(
                    delay: 250,
                    enabled: devSettings.homeAnimations && !reduceMotion,
                    child: const _MoodChips(),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              if (_showPersonalized)
                SliverToBoxAdapter(
                  child: _SectionReveal(
                    delay: 270,
                    enabled: devSettings.homeAnimations && !reduceMotion,
                    child: _PersonalizedBlocks(data: data, altLayout: devSettings.homeAltLayout),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              if (_showBrand)
                SliverToBoxAdapter(
                  child: _SectionReveal(
                    delay: 300,
                    enabled: devSettings.homeAnimations && !reduceMotion,
                    child: KeyedSubtree(
                      key: _brandKey,
                      child: BrandCarousel(brands: data.brands),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              if (_showExclusive)
                SliverToBoxAdapter(
                  child: _SectionReveal(
                    delay: 420,
                    enabled: devSettings.homeAnimations && !reduceMotion,
                    child: KeyedSubtree(
                      key: _exclusiveKey,
                      child: ExclusiveProductsSection(products: data.exclusive),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverPersistentHeader(
                pinned: true,
                delegate: _QuickFilterHeaderDelegate(
                  selected: allFilter,
                  onTap: (type) {
                    ref.read(homeAllProductsFilterProvider.notifier).setFilter(type);
                    _filterFadeController.forward(from: 0);
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Text('All Products', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(width: 8),
                      _FilterBadge(label: _filterLabel(allFilter)),
                      const SizedBox(width: 8),
                      Text(
                        '${filteredItems.length} items',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const Spacer(),
                      if (allFilter != HomeAllProductsFilter.all ||
                          allQuery.trim().isNotEmpty ||
                          _quickFilter != _HomeQuickFilter.none)
                        TextButton(
                          onPressed: () {
                            ref.read(homeAllProductsFilterProvider.notifier).reset();
                            _allQueryController.clear();
                            setState(() => _quickFilter = _HomeQuickFilter.none);
                            _filterFadeController.forward(from: 0);
                          },
                          child: const Text('Clear'),
                        )
                      else
                        const Text('Infinite', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
                  child: Text(
                    'Filter: ${_filterLabel(allFilter)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                  child: _QuickMiniFilters(
                    selected: _quickFilter,
                    onSelect: (f) {
                      setState(() => _quickFilter = f);
                      _filterFadeController.forward(from: 0);
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: TextField(
                    controller: _allQueryController,
                    decoration: InputDecoration(
                      hintText: 'Search in all products...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: allQuery.trim().isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _allQueryController.clear();
                                ref.read(homeAllProductsFilterProvider.notifier).setQuery('');
                                _filterFadeController.forward(from: 0);
                              },
                            ),
                    ),
                    onChanged: (v) {
                      ref.read(homeAllProductsFilterProvider.notifier).setQuery(v);
                      _filterFadeController.forward(from: 0);
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: allQuery.trim().isNotEmpty && sortedFilteredItems.isNotEmpty
                        ? TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) => Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 8 * (1 - value)),
                                child: child,
                              ),
                            ),
                            child: _SearchPeekCard(
                              key: ValueKey(sortedFilteredItems.first.id),
                              product: sortedFilteredItems.first,
                              onTap: () => context.go('/product/${sortedFilteredItems.first.id}'),
                              onSeeAll: () => _scrollController.animateTo(
                                _scrollController.offset + 300,
                                duration: const Duration(milliseconds: 280),
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              if (showEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        EmptyState(
                          icon: Icons.search_off,
                          title: 'No products found',
                          subtitle:
                              'We could not find matches for ${beautyProfile.skinType.toLowerCase()} skin. Try a different filter.',
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: data.categories
                              .take(4)
                              .map(
                                (c) => Chip(
                                  label: Text(c.name),
                                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () {
                            ref.read(homeAllProductsFilterProvider.notifier).reset();
                            _allQueryController.clear();
                            _filterFadeController.forward(from: 0);
                          },
                          child: const Text('Reset filter'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverFadeTransition(
                  opacity: _filterFade,
                  sliver: SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: _InfiniteProductsGrid(
                      filter: allFilter,
                      items: sortedFilteredItems,
                      isLoading: infiniteState.isLoading,
                      lastBatchIds: infiniteState.lastBatchIds,
                    ),
                  ),
                ),
              if (infiniteState.isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 8, bottom: 12),
                    child: _LoadingMoreRow(),
                  ),
                ),
              if (!infiniteState.isLoading && !infiniteState.hasMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 8, bottom: 12),
                    child: _EndOfListRow(),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
              Positioned(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).padding.bottom + 86,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: compareItems.isNotEmpty
                      ? TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) => Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 10 * (1 - value)),
                              child: child,
                            ),
                          ),
                          child: _CompareBar(
                            key: ValueKey(compareItems.length),
                            count: compareItems.length,
                            enabled: compareItems.length >= 2,
                            onTap: () => context.go('/compare'),
                            onClear: () => ref.read(productCompareProvider.notifier).clear(),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          );
      },
    ),
      floatingActionButton: _showBackToTop
          ? Padding(
              padding: const EdgeInsets.only(bottom: 68),
              child: Semantics(
                label: 'Back to top',
                button: true,
                child: FloatingActionButton(
                  heroTag: 'home_back_to_top',
                  mini: true,
                  onPressed: () {
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 380),
                      curve: Curves.easeOutCubic,
                    );
                  },
                  child: const Icon(Icons.keyboard_arrow_up),
                ),
              ),
            )
          : null,
    );
  }
}

class _QuickFilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final ValueChanged<HomeAllProductsFilter> onTap;
  final HomeAllProductsFilter selected;

  _QuickFilterHeaderDelegate({required this.onTap, required this.selected});

  @override
  double get minExtent => 72;

  @override
  double get maxExtent => 72;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final blur = overlapsContent ? 10.0 : 0.0;
    final background = Theme.of(context).scaffoldBackgroundColor;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: overlapsContent ? background.withAlpha(235) : background,
            boxShadow: overlapsContent
                ? [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 12, offset: const Offset(0, 6))]
                : null,
          ),
          child: SizedBox(
            height: 72,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
              child: _QuickFilterBar(onTap: onTap, selected: selected),
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _QuickFilterHeaderDelegate oldDelegate) {
    return oldDelegate.onTap != onTap || oldDelegate.selected != selected;
  }
}

class _SearchBarHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SearchBarHeaderDelegate({required this.child});

  @override
  double get minExtent => 72;

  @override
  double get maxExtent => 72;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      elevation: overlapsContent ? 1 : 0,
      child: SizedBox(
        height: 72,
        child: child,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SearchBarHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}

enum _HomeQuickFilter { none, priceLow, topRated, sensitive }

class _QuickMiniFilters extends StatelessWidget {
  final _HomeQuickFilter selected;
  final ValueChanged<_HomeQuickFilter> onSelect;

  const _QuickMiniFilters({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _QuickMiniChip(
          label: 'All',
          selected: selected == _HomeQuickFilter.none,
          onTap: () => onSelect(_HomeQuickFilter.none),
        ),
        _QuickMiniChip(
          label: 'Price low',
          selected: selected == _HomeQuickFilter.priceLow,
          onTap: () => onSelect(_HomeQuickFilter.priceLow),
        ),
        _QuickMiniChip(
          label: 'Top rated',
          selected: selected == _HomeQuickFilter.topRated,
          onTap: () => onSelect(_HomeQuickFilter.topRated),
        ),
        _QuickMiniChip(
          label: 'Sensitive-safe',
          selected: selected == _HomeQuickFilter.sensitive,
          onTap: () => onSelect(_HomeQuickFilter.sensitive),
        ),
      ],
    );
  }
}

class _PriceDropItem {
  final Product product;
  final double drop;

  const _PriceDropItem({required this.product, required this.drop});
}

List<_PriceDropItem> _buildPriceDropItems(
  List<Product> wishlist,
  Map<int, List<double>> priceHistory,
) {
  final items = <_PriceDropItem>[];
  for (final product in wishlist) {
    final history = priceHistory[product.id];
    if (history == null || history.length < 2) continue;
    final drop = (history.first - history.last).clamp(0, double.infinity).toDouble();
    if (drop <= 0) continue;
    items.add(_PriceDropItem(product: product, drop: drop));
  }
  items.sort((a, b) => b.drop.compareTo(a.drop));
  return items.take(6).toList();
}

class _QuickMiniChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _QuickMiniChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: selected
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected
              ? Theme.of(context).colorScheme.outline
              : Theme.of(context).colorScheme.outline.withAlpha(120),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? Theme.of(context).colorScheme.primary : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompareBar extends StatelessWidget {
  final int count;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _CompareBar({
    super.key,
    required this.count,
    required this.enabled,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 5,
      borderRadius: BorderRadius.circular(14),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.compare_arrows, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$count selected for compare',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              onPressed: onClear,
              child: const Text('Clear'),
            ),
            ElevatedButton(
              onPressed: enabled ? onTap : null,
              child: const Text('Compare'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchPeekCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onSeeAll;

  const _SearchPeekCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 1,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  product.image,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Top match', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    PriceWidget(price: product.discountPrice),
                  ],
                ),
              ),
              TextButton(onPressed: onSeeAll, child: const Text('See all')),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.emoji_events_outlined, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Mission: Save 3 products to wishlist to earn bonus points',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
              ),
            ),
            TextButton(onPressed: () {}, child: const Text('Start')),
          ],
        ),
      ),
    );
  }
}

class _InfiniteProductsGrid extends ConsumerWidget {
  final HomeAllProductsFilter filter;
  final List<Product> items;
  final bool isLoading;
  final Set<int> lastBatchIds;

  const _InfiniteProductsGrid({
    required this.filter,
    required this.items,
    required this.isLoading,
    required this.lastBatchIds,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loadingCount = isLoading ? 4 : 0;
    final compareItems = ref.watch(productCompareProvider);
    final beautyProfile = ref.watch(beautyProfileProvider);
    return SliverGrid(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index >= items.length) {
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: const _ProductSkeletonCard(key: ValueKey('skeleton')),
            );
          }
          final product = items[index];
          final shouldStagger = lastBatchIds.contains(product.id);
          final isCompared = compareItems.any((e) => e.id == product.id);
          final matchScore = _calcMatchScore(product, beautyProfile.skinType);
          final card = AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: ProductCard(
              key: ValueKey('${filter.name}_${product.id}'),
              product: product,
              onTap: () => context.go('/product/${product.id}'),
              onAdd: () => ref.read(cartProvider.notifier).add(product),
              onCompare: () => ref.read(productCompareProvider.notifier).toggle(product),
              isCompared: isCompared,
              matchScore: matchScore,
            ),
          );
          if (shouldStagger) {
            return _StaggeredFadeIn(index: index, child: card);
          }
          return card;
        },
        childCount: items.length + loadingCount,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 320,
      ),
    );
  }
}

class _SectionReveal extends StatefulWidget {
  final Widget child;
  final int delay;
  final bool enabled;

  const _SectionReveal({required this.child, this.delay = 0, this.enabled = true});

  @override
  State<_SectionReveal> createState() => _SectionRevealState();
}

class _SectionRevealState extends State<_SectionReveal> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    if (!widget.enabled) {
      _visible = true;
      return;
    }
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (!mounted) return;
      setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      opacity: _visible ? 1 : 0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
        offset: _visible ? Offset.zero : const Offset(0, 0.02),
        child: widget.child,
      ),
    );
  }
}

enum _HomeTab { flash, best, newArrivals }

class _HomeSectionTabs extends StatelessWidget {
  final _HomeTab selected;
  final ValueChanged<_HomeTab> onSelect;

  const _HomeSectionTabs({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        children: [
          ChoiceChip(
            label: const Text('Flash'),
            selected: selected == _HomeTab.flash,
            onSelected: (_) => onSelect(_HomeTab.flash),
          ),
          ChoiceChip(
            label: const Text('Best'),
            selected: selected == _HomeTab.best,
            onSelected: (_) => onSelect(_HomeTab.best),
          ),
          ChoiceChip(
            label: const Text('New'),
            selected: selected == _HomeTab.newArrivals,
            onSelected: (_) => onSelect(_HomeTab.newArrivals),
          ),
        ],
      ),
    );
  }
}

class _QuickFilterBar extends StatelessWidget {
  final ValueChanged<HomeAllProductsFilter> onTap;
  final HomeAllProductsFilter selected;

  const _QuickFilterBar({required this.onTap, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          _QuickFilterChip(
            label: 'All',
            icon: Icons.apps,
            selected: selected == HomeAllProductsFilter.all,
            onTap: () => onTap(HomeAllProductsFilter.all),
          ),
          _QuickFilterChip(
            label: 'Promo',
            icon: Icons.local_offer_outlined,
            selected: selected == HomeAllProductsFilter.promo,
            onTap: () => onTap(HomeAllProductsFilter.promo),
          ),
          _QuickFilterChip(
            label: 'Best',
            icon: Icons.star_border,
            selected: selected == HomeAllProductsFilter.best,
            onTap: () => onTap(HomeAllProductsFilter.best),
          ),
          _QuickFilterChip(
            label: 'New',
            icon: Icons.new_releases_outlined,
            selected: selected == HomeAllProductsFilter.newest,
            onTap: () => onTap(HomeAllProductsFilter.newest),
          ),
        ],
      ),
    );
  }
}

class _QuickFilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _QuickFilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? Theme.of(context).colorScheme.primary : null),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: selected ? Theme.of(context).colorScheme.primary : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<Product> _applyFilter(
  List<Product> items,
  HomeAllProductsFilter filter,
  String query,
  _HomeQuickFilter quickFilter,
) {
  var filtered = items;
  final q = query.trim().toLowerCase();
  if (q.isNotEmpty) {
    filtered = filtered.where((p) => p.name.toLowerCase().contains(q)).toList();
  }
  if (filter == HomeAllProductsFilter.all) return filtered;
  if (filter == HomeAllProductsFilter.promo) {
    return filtered.where((p) => ((p.price - p.discountPrice) / p.price) >= 0.15).toList();
  }
  if (filter == HomeAllProductsFilter.best) {
    filtered = filtered.where((p) => p.rating >= 4.6).toList();
  } else if (filter == HomeAllProductsFilter.newest) {
    filtered = filtered.where((p) => (p.id >= 300 && p.id < 400) || p.id % 5 == 0).toList();
  }

  switch (quickFilter) {
    case _HomeQuickFilter.none:
      return filtered;
    case _HomeQuickFilter.priceLow:
      final list = [...filtered];
      list.sort((a, b) => a.discountPrice.compareTo(b.discountPrice));
      return list;
    case _HomeQuickFilter.topRated:
      return filtered.where((p) => p.rating >= 4.7).toList();
    case _HomeQuickFilter.sensitive:
      return filtered.where((p) => p.id % 2 == 0).toList();
  }
}

String _filterLabel(HomeAllProductsFilter filter) {
  switch (filter) {
    case HomeAllProductsFilter.all:
      return 'All products';
    case HomeAllProductsFilter.promo:
      return 'Promo deals';
    case HomeAllProductsFilter.best:
      return 'Best rated';
    case HomeAllProductsFilter.newest:
      return 'New arrivals';
  }
}

int _calcMatchScore(Product product, String skinType) {
  var score = (product.rating * 18).round(); // up to ~90
  score += (product.reviewCount ~/ 40).clamp(0, 8);
  final discountPct = ((product.price - product.discountPrice) / product.price).clamp(0.0, 0.6);
  score += (discountPct * 12).round();
  if (product.stock <= 3) score -= 2;
  if (skinType.toLowerCase() == 'sensitive') {
    score += product.id.isEven ? 4 : 0;
  } else if (skinType.toLowerCase() == 'oily') {
    score += product.id % 3 == 0 ? 3 : 0;
  } else if (skinType.toLowerCase() == 'dry') {
    score += product.id % 5 == 0 ? 3 : 0;
  }
  if (score > 98) score = 98;
  if (score < 70) score = 70;
  return score;
}

List<Product> _sortByStock(List<Product> items) {
  final inStock = items.where((p) => p.stock > 0).toList();
  final outOfStock = items.where((p) => p.stock <= 0).toList();
  return [...inStock, ...outOfStock];
}

class _ProductSkeletonCard extends StatelessWidget {
  const _ProductSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Expanded(
              child: ShimmerLoader(height: double.infinity, width: double.infinity),
            ),
            SizedBox(height: 10),
            ShimmerLoader(height: 12, width: 120),
            SizedBox(height: 6),
            ShimmerLoader(height: 10, width: 80),
            SizedBox(height: 8),
            ShimmerLoader(height: 12, width: 60),
          ],
        ),
      ),
    );
  }
}

class _StaggeredFadeIn extends StatefulWidget {
  final Widget child;
  final int index;

  const _StaggeredFadeIn({required this.child, required this.index});

  @override
  State<_StaggeredFadeIn> createState() => _StaggeredFadeInState();
}

class _StaggeredFadeInState extends State<_StaggeredFadeIn> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    final delay = Duration(milliseconds: 40 * (widget.index % 10));
    Future.delayed(delay, () {
      if (!mounted) return;
      setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      opacity: _visible ? 1 : 0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        offset: _visible ? Offset.zero : const Offset(0, 0.02),
        child: widget.child,
      ),
    );
  }
}

class _FilterBadge extends StatelessWidget {
  final String label;

  const _FilterBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Container(
        key: ValueKey(label),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class _LoadingMoreRow extends StatelessWidget {
  const _LoadingMoreRow();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text('Loading more...', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _EndOfListRow extends StatelessWidget {
  const _EndOfListRow();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('You have reached the end', style: TextStyle(color: Colors.grey)),
    );
  }
}

class _HeroPromoCard extends StatefulWidget {
  const _HeroPromoCard();

  @override
  State<_HeroPromoCard> createState() => _HeroPromoCardState();
}

class _PromoGrid extends StatelessWidget {
  const _PromoGrid();

  @override
  Widget build(BuildContext context) {
    final promos = const [
      ('Skincare Sets', 'Up to 30%', '/promo'),
      ('Makeup Minis', 'Bundle deals', '/best-seller'),
      ('Haircare', 'New drops', '/new-arrivals'),
      ('Fragrance', 'Limited', '/promo'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.6,
        ),
        itemCount: promos.length,
        itemBuilder: (context, index) {
          final item = promos[index];
          return Semantics(
            label: '${item.$1}, ${item.$2}',
            button: true,
            child: InkWell(
              onTap: () => context.go(item.$3),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 8, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.local_offer_outlined,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(item.$1, style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(item.$2, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PriceDropQuickSection extends StatefulWidget {
  final List<_PriceDropItem> items;

  const _PriceDropQuickSection({required this.items});

  @override
  State<_PriceDropQuickSection> createState() => _PriceDropQuickSectionState();
}

class _PriceDropQuickSectionState extends State<_PriceDropQuickSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sparkle;

  @override
  void initState() {
    super.initState();
    _sparkle = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _sparkle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Price drops for you', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text('Wishlist', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.go('/wishlist'),
                    child: const Text('See all'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 150,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.items.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final item = widget.items[index];
                    return GestureDetector(
                      onTap: () => context.go('/product/${item.product.id}'),
                      child: Container(
                        width: 220,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
                          boxShadow: [
                            BoxShadow(
                              color: scheme.shadow.withValues(alpha: 0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                item.product.image,
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  const Spacer(),
                                  Row(
                                    children: [
                                      const Icon(Icons.trending_down, size: 14, color: Colors.green),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Drop ${Formatter.currency(item.drop)}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  PriceWidget(price: item.product.discountPrice),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          Positioned(
            right: 8,
            top: 6,
            child: AnimatedBuilder(
              animation: _sparkle,
              builder: (context, _) {
                final t = _sparkle.value;
                final opacity = 0.35 + (t * 0.5);
                final scale = 0.9 + (t * 0.25);
                return Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    child: Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: scheme.secondary.withValues(alpha: 0.9),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            right: 30,
            top: 24,
            child: AnimatedBuilder(
              animation: _sparkle,
              builder: (context, _) {
                final t = _sparkle.value;
                final opacity = 0.2 + (t * 0.4);
                final scale = 0.8 + (t * 0.2);
                return Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    child: Icon(
                      Icons.auto_awesome,
                      size: 10,
                      color: scheme.primary.withValues(alpha: 0.8),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DealOfTheDayCard extends StatelessWidget {
  final HomeData data;

  const _DealOfTheDayCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final product = data.flashSale.isNotEmpty ? data.flashSale.first : data.bestSeller.first;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(product.image, width: 72, height: 72, fit: BoxFit.cover),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Deal of the day', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    PriceWidget(price: product.discountPrice),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => context.go('/product/${product.id}'),
                child: const Text('Shop'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroPromoCardState extends State<_HeroPromoCard> {
  late Duration _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = const Duration(hours: 4, minutes: 12, seconds: 18);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_remaining.inSeconds > 0) {
          _remaining -= const Duration(seconds: 1);
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _timeText {
    final h = _remaining.inHours.toString().padLeft(2, '0');
    final m = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [scheme.primaryContainer, scheme.secondaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Weekend Glow Sale', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 4),
                Text('Ends in $_timeText', style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 8),
                const Text('Up to 40% off bestsellers'),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => context.go('/promo'),
            child: const Text('Shop now'),
          ),
        ],
      ),
    );
  }
}

class _MoodChips extends ConsumerWidget {
  const _MoodChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(homeMoodProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: HomeMood.values
            .map(
              (mood) => ChoiceChip(
                label: Text(moodLabel(mood)),
                selected: selected == mood,
                labelStyle: TextStyle(
                  fontWeight: selected == mood ? FontWeight.w700 : FontWeight.w500,
                ),
                selectedColor: Theme.of(context).colorScheme.primaryContainer,
                side: BorderSide(color: Theme.of(context).colorScheme.outline),
                onSelected: (_) {
                  final next = selected == mood ? null : mood;
                  ref.read(homeMoodProvider.notifier).setMood(next);
                  if (next != null) {
                    context.go('/section/mood/${mood.name}');
                  }
                },
              ),
            )
            .toList(),
      ),
    );
  }
}

class _PersonalizedBlocks extends ConsumerWidget {
  final HomeData data;
  final bool altLayout;

  const _PersonalizedBlocks({required this.data, required this.altLayout});

  List<Product> _pickForProfile(List<Product> all, String skinType, Set<String> concerns) {
    final normalized = skinType.toLowerCase();
    final seed = normalized.hashCode.abs() % 5;
    var result = all.where((p) => p.id % 5 == seed).toList();
    if (result.isEmpty) {
      result = all.toList();
    }
    if (concerns.isNotEmpty) {
      final keyword = concerns.first.toLowerCase();
      final matches = all.where((p) => p.name.toLowerCase().contains(keyword)).toList();
      if (matches.isNotEmpty) {
        result = matches;
      }
    }
    return result.take(6).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentViewedProvider);
    final beautyProfile = ref.watch(beautyProfileProvider);
    final forYou = data.bestSeller.take(6).toList();
    final likedCategoryId = recent.isNotEmpty ? recent.first.categoryId : data.categories.first.id;
    final becauseLiked = data.allProducts
        .where((p) => p.categoryId == likedCategoryId)
        .where((p) => recent.isEmpty || p.id != recent.first.id)
        .take(6)
        .toList();
    final personalized = _pickForProfile(data.allProducts, beautyProfile.skinType, beautyProfile.concerns);

    if (altLayout) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AltSectionCard(
            title: 'For You',
            subtitle: 'Curated picks based on trends',
            products: forYou,
          ),
          if (recent.isNotEmpty)
            _AltSectionCard(
              title: 'Recently Viewed',
              subtitle: 'Pick up where you left off',
              products: recent,
            ),
          _AltSectionCard(
            title: 'Because you liked ${data.categories.firstWhere((c) => c.id == likedCategoryId).name}',
            subtitle: 'Similar picks you may love',
            products: becauseLiked,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (personalized.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('Picks for ${beautyProfile.skinType}', style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                if (beautyProfile.concerns.isNotEmpty)
                  Text(
                    beautyProfile.concerns.join(', '),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _HorizontalProductList(products: personalized),
          const SizedBox(height: 12),
        ],
        if (forYou.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('For You', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 8),
          _HorizontalProductList(products: forYou),
          const SizedBox(height: 12),
        ],
        if (recent.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text('Recently Viewed', style: TextStyle(fontWeight: FontWeight.w700)),
                const Spacer(),
                TextButton(
                  onPressed: () => ref.read(recentViewedProvider.notifier).clear(),
                  child: const Text('Clear'),
                ),
              ],
            ),
          ),
          _HorizontalProductList(products: recent),
          const SizedBox(height: 12),
        ],
        if (becauseLiked.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Because you liked ${data.categories.firstWhere((c) => c.id == likedCategoryId).name}'),
          ),
          const SizedBox(height: 8),
          _HorizontalProductList(products: becauseLiked),
        ],
      ],
    );
  }
}

class _HorizontalProductList extends StatelessWidget {
  final List<Product> products;

  const _HorizontalProductList({required this.products});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final product = products[index];
          return SizedBox(
            width: 160,
            child: ProductCard(
              product: product,
              onTap: () => context.go('/product/${product.id}'),
            ),
          );
        },
      ),
    );
  }
}

class _AltSectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Product> products;

  const _AltSectionCard({
    required this.title,
    required this.subtitle,
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final product = products[index];
                  return SizedBox(
                    width: 150,
                    child: ProductCard(
                      product: product,
                      onTap: () => context.go('/product/${product.id}'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
