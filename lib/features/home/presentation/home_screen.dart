import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(homeLoadProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        actions: const [CartBadgeButton()],
      ),
      body: asyncData.when(
        loading: () => const HomeShimmer(),
        error: (_, __) => const Center(child: Text('Failed to load')),
        data: (data) => RefreshIndicator(
          onRefresh: () async => ref.refresh(homeLoadProvider),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SearchBarWidget(),
                BannerSlider(images: data.bannerImages),
                FlashSaleSection(
                  products: data.flashSale,
                  onSeeAll: () => context.go('/promo'),
                ),
                BestSellerSection(
                  products: data.bestSeller,
                  onSeeAll: () => context.go('/best-seller'),
                ),
                CategoryGrid(categories: data.categories),
                BrandCarousel(brands: data.brands),
                NewArrivalsSection(
                  products: data.newArrivals,
                  onSeeAll: () => context.go('/new-arrivals'),
                ),
                ExclusiveProductsSection(products: data.exclusive),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
