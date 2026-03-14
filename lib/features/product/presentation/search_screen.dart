import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../home/presentation/home_providers.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../shared/widgets/cart_badge_button.dart';
import '../../../shared/models/product.dart';
import 'product_filter_sheet.dart';
import 'product_grid_shimmer.dart';
import 'search_history_provider.dart';
import 'search_suggestion_provider.dart';
import 'recent_viewed_provider.dart';
import '../../cart/presentation/cart_providers.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _controller;
  late ProductFilter _filter;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(searchQueryProvider));
    _filter = const ProductFilter(
      sort: ProductSort.recommended,
      priceRange: RangeValues(0, 1000000),
      minRating: 0,
      minReviews: 0,
      inStockOnly: false,
      discountRange: RangeValues(0, 70),
    );
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(homeDataProvider);
    final baseResults = ref.watch(searchResultsProvider);
    final history = ref.watch(searchHistoryProvider);
    final pinned = ref.watch(searchPinnedProvider);
    final trending = ref.watch(trendingSearchProvider);
    final query = ref.watch(searchQueryProvider);
    final suggestions = ref.watch(searchSuggestionProvider);
    final recentViewed = ref.watch(recentViewedProvider);

    final minPrice = data.allProducts.map((p) => p.discountPrice).reduce((a, b) => a < b ? a : b);
    final maxPrice = data.allProducts.map((p) => p.discountPrice).reduce((a, b) => a > b ? a : b);

    final results = _applyFilter(products: baseResults, filter: _filter);
    final suggestList = [
      ...pinned,
      ...history,
      ...trending,
      ...suggestions,
      ...data.categories.map((c) => c.name),
      ...data.brands.map((b) => b.name),
    ].map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final pool = [
      ...data.allProducts.map((p) => p.name),
      ...data.categories.map((c) => c.name),
      ...data.brands.map((b) => b.name),
    ];
    final rankedSuggestions = <String>[];
    for (final item in suggestList) {
      if (!rankedSuggestions.contains(item)) {
        rankedSuggestions.add(item);
      }
    }

    final selectedCategory = _filter.categoryId == null
        ? null
        : data.categories.firstWhere((c) => c.id == _filter.categoryId).name;
    final selectedBrand = _filter.brandId == null
        ? null
        : data.brands.firstWhere((b) => b.id == _filter.brandId).name;

    final didYouMean = _closestSuggestion(query.trim(), pool);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        actions: const [CartBadgeButton()],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onChanged: (value) {
                        ref.read(searchQueryProvider.notifier).setQuery(value);
                        final q = value.trim().toLowerCase();
                        if (q.isEmpty) {
                          ref.read(searchSuggestionProvider.notifier).setSuggestions([]);
                          return;
                        }
                        final suggestions = _fuzzySuggestions(pool, q);
                        ref.read(searchSuggestionProvider.notifier).setSuggestions(suggestions);
                      },
                      onSubmitted: (value) {
                        ref.read(searchHistoryProvider.notifier).add(value);
                        ref.read(searchSuggestionProvider.notifier).setSuggestions(
                              [value, ...suggestList.where((e) => e != value)].take(10).toList(),
                            );
                      },
                      decoration: InputDecoration(
                        hintText: 'Search products...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: () => _openFilterSheet(context, data, minPrice, maxPrice),
                  ),
                  IconButton(
                    icon: const Icon(Icons.mic_none),
                    onPressed: () => _openVoiceSheet(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text('Sort:', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    _SortChip(
                      label: 'Recommended',
                      selected: _filter.sort == ProductSort.recommended,
                      onTap: () => setState(() => _filter = _filter.copyWith(sort: ProductSort.recommended)),
                    ),
                    _SortChip(
                      label: 'Best Deal',
                      selected: _filter.sort == ProductSort.bestDeal,
                      onTap: () => setState(() => _filter = _filter.copyWith(sort: ProductSort.bestDeal)),
                    ),
                    _SortChip(
                      label: 'Newest',
                      selected: _filter.sort == ProductSort.newest,
                      onTap: () => setState(() => _filter = _filter.copyWith(sort: ProductSort.newest)),
                    ),
                    _SortChip(
                      label: 'Price Low',
                      selected: _filter.sort == ProductSort.priceLow,
                      onTap: () => setState(() => _filter = _filter.copyWith(sort: ProductSort.priceLow)),
                    ),
                    _SortChip(
                      label: 'Price High',
                      selected: _filter.sort == ProductSort.priceHigh,
                      onTap: () => setState(() => _filter = _filter.copyWith(sort: ProductSort.priceHigh)),
                    ),
                    _SortChip(
                      label: 'Rating',
                      selected: _filter.sort == ProductSort.rating,
                      onTap: () => setState(() => _filter = _filter.copyWith(sort: ProductSort.rating)),
                    ),
                    _SortChip(
                      label: 'Reviews',
                      selected: _filter.sort == ProductSort.reviews,
                      onTap: () => setState(() => _filter = _filter.copyWith(sort: ProductSort.reviews)),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: FilterChip(
                        label: Text('Min ${_filter.minRating.toStringAsFixed(1)} rating'),
                        selected: _filter.minRating > 0,
                        onSelected: (_) => setState(() => _filter = _filter.copyWith(minRating: 0)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: FilterChip(
                        label: Text('Min ${_filter.minReviews} reviews'),
                        selected: _filter.minReviews > 0,
                        onSelected: (_) => setState(() => _filter = _filter.copyWith(minReviews: 0)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: FilterChip(
                        label: const Text('In stock only'),
                        selected: _filter.inStockOnly,
                        onSelected: (v) => setState(() => _filter = _filter.copyWith(inStockOnly: v)),
                      ),
                    ),
                    if (selectedCategory != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: FilterChip(
                          label: Text(selectedCategory),
                          selected: true,
                          onSelected: (_) =>
                              setState(() => _filter = _filter.copyWith(clearCategory: true)),
                        ),
                      ),
                    if (selectedBrand != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: FilterChip(
                          label: Text(selectedBrand),
                          selected: true,
                          onSelected: (_) => setState(() => _filter = _filter.copyWith(clearBrand: true)),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text('Smart:', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    ActionChip(
                      label: const Text('Best deal'),
                      onPressed: () => setState(() => _filter = _filter.copyWith(sort: ProductSort.bestDeal)),
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      label: const Text('Top rated'),
                      onPressed: () => setState(() => _filter = _filter.copyWith(minRating: 4.5)),
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      label: const Text('Most reviewed'),
                      onPressed: () => setState(() => _filter = _filter.copyWith(minReviews: 100)),
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      label: const Text('Under 100K'),
                      onPressed: () => setState(() {
                        _filter = _filter.copyWith(priceRange: const RangeValues(0, 100000));
                      }),
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      label: const Text('In stock'),
                      onPressed: () => setState(() => _filter = _filter.copyWith(inStockOnly: true)),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Min rating', style: TextStyle(fontWeight: FontWeight.w700)),
                  Slider(
                    value: _filter.minRating,
                    min: 0,
                    max: 5,
                    divisions: 10,
                    label: _filter.minRating.toStringAsFixed(1),
                    onChanged: (v) => setState(() => _filter = _filter.copyWith(minRating: v)),
                  ),
                  const Text('Min reviews', style: TextStyle(fontWeight: FontWeight.w700)),
                  Slider(
                    value: _filter.minReviews.toDouble(),
                    min: 0,
                    max: 300,
                    divisions: 6,
                    label: _filter.minReviews.toString(),
                    onChanged: (v) => setState(() => _filter = _filter.copyWith(minReviews: v.round())),
                  ),
                    const Text('Price range', style: TextStyle(fontWeight: FontWeight.w700)),
                    Builder(builder: (context) {
                      final start = _filter.priceRange.start.clamp(minPrice, maxPrice);
                      final end = _filter.priceRange.end.clamp(minPrice, maxPrice);
                      final values = RangeValues(math.min(start, end), math.max(start, end));
                      return RangeSlider(
                        values: values,
                        min: minPrice,
                        max: maxPrice,
                        divisions: 6,
                        labels: RangeLabels(
                          values.start.toStringAsFixed(0),
                          values.end.toStringAsFixed(0),
                        ),
                        onChanged: (v) => setState(() {
                          final s = v.start.clamp(minPrice, maxPrice);
                          final e = v.end.clamp(minPrice, maxPrice);
                          _filter = _filter.copyWith(priceRange: RangeValues(math.min(s, e), math.max(s, e)));
                        }),
                      );
                    }),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('In stock only'),
                    value: _filter.inStockOnly,
                    onChanged: (v) => setState(() => _filter = _filter.copyWith(inStockOnly: v)),
                  ),
                ],
              ),
            ),
            if (query.trim().isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (recentViewed.isNotEmpty) ...[
                      Row(
                        children: [
                          const Text('Recently viewed', style: TextStyle(fontWeight: FontWeight.w700)),
                          const Spacer(),
                          TextButton(
                            onPressed: () => ref.read(recentViewedProvider.notifier).clear(),
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 220,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: recentViewed.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final product = recentViewed[index];
                            return SizedBox(
                              width: 160,
                              child: ProductCard(
                                product: product,
                                onTap: () => context.go('/product/${product.id}'),
                                onAdd: () => ref.read(cartProvider.notifier).add(product),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    const Text('Recommended', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 220,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: data.bestSeller.take(6).length,
                        separatorBuilder: (context, index) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                            final product = data.bestSeller[index];
                            return SizedBox(
                              width: 160,
                              child: ProductCard(
                                product: product,
                                onTap: () => context.go('/product/${product.id}'),
                                onAdd: () => ref.read(cartProvider.notifier).add(product),
                              ),
                            );
                          },
                        ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    if (pinned.isNotEmpty) ...[
                      Row(
                        children: [
                          const Text('Pinned', style: TextStyle(fontWeight: FontWeight.w700)),
                          const Spacer(),
                          TextButton(
                            onPressed: () => ref.read(searchPinnedProvider.notifier).remove(pinned.first),
                            child: const Text('Clear one'),
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 8,
                        children: pinned
                            .map(
                              (q) => InputChip(
                                label: Text(q),
                                avatar: const Icon(Icons.push_pin, size: 16),
                                onPressed: () {
                                  ref.read(searchQueryProvider.notifier).setQuery(q);
                                  _controller.text = q;
                                },
                                onDeleted: () => ref.read(searchPinnedProvider.notifier).remove(q),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                    ],
                    const Text('Trending', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: trending
                          .map(
                            (q) => ActionChip(
                              label: Text(q),
                              onPressed: () {
                                ref.read(searchQueryProvider.notifier).setQuery(q);
                                _controller.text = q;
                              },
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    const Text('Suggestions', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: rankedSuggestions
                          .take(12)
                          .map(
                            (q) => InputChip(
                              label: Text(q),
                              avatar: pinned.contains(q) ? const Icon(Icons.push_pin, size: 16) : null,
                              onPressed: () {
                                ref.read(searchQueryProvider.notifier).setQuery(q);
                                _controller.text = q;
                              },
                              onDeleted: () => ref.read(searchPinnedProvider.notifier).toggle(q),
                              deleteIcon: Icon(
                                pinned.contains(q) ? Icons.push_pin : Icons.push_pin_outlined,
                                size: 16,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    if (history.isNotEmpty)
                      Row(
                        children: [
                          const Text('Recent searches', style: TextStyle(fontWeight: FontWeight.w700)),
                          const Spacer(),
                          TextButton(
                            onPressed: () => ref.read(searchHistoryProvider.notifier).clear(),
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    Wrap(
                      spacing: 8,
                      children: history
                          .map(
                            (q) => InputChip(
                              label: Text(q),
                              selected: pinned.contains(q),
                              onPressed: () {
                                ref.read(searchQueryProvider.notifier).setQuery(q);
                                _controller.text = q;
                              },
                              onDeleted: () => ref.read(searchHistoryProvider.notifier).remove(q),
                              deleteIcon: Icon(
                                pinned.contains(q) ? Icons.push_pin : Icons.close,
                                size: 16,
                              ),
                              onSelected: (_) => ref.read(searchPinnedProvider.notifier).toggle(q),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _loading
                  ? const ProductGridShimmer()
                  : results.isEmpty
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('No results found'),
                            if (didYouMean != null) ...[
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('Did you mean'),
                                  const SizedBox(width: 6),
                                  ActionChip(
                                    label: Text(didYouMean),
                                    onPressed: () {
                                      ref.read(searchQueryProvider.notifier).setQuery(didYouMean);
                                      _controller.text = didYouMean;
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ],
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.62,
                          ),
                          itemCount: results.length,
                          itemBuilder: (context, index) {
                            final product = results[index];
                            return ProductCard(
                              product: product,
                              onTap: () => context.go('/product/${product.id}'),
                              onAdd: () => ref.read(cartProvider.notifier).add(product),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFilterSheet(BuildContext context, HomeData data, double minPrice, double maxPrice) {
    final normalized = _filter.priceRange.start == 0 && _filter.priceRange.end == 1000000
        ? RangeValues(minPrice, maxPrice)
        : _filter.priceRange;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => ProductFilterSheet(
        initial: _filter.copyWith(priceRange: normalized),
        minPrice: minPrice,
        maxPrice: maxPrice,
        categories: data.categories,
        brands: data.brands,
        onApply: (filter) {
          setState(() => _filter = filter);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _openVoiceSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => const _VoiceSheet(),
    );
  }
}

class _VoiceSheet extends ConsumerStatefulWidget {
  const _VoiceSheet();

  @override
  ConsumerState<_VoiceSheet> createState() => _VoiceSheetState();
}

class _VoiceSheetState extends ConsumerState<_VoiceSheet> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final scale = 0.9 + (_controller.value * 0.2);
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scheme.primaryContainer,
                      ),
                    ),
                  );
                },
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primary.withAlpha(40),
                ),
                child: const Icon(Icons.mic, size: 40),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Listening...'),
          const SizedBox(height: 8),
          _VoiceWave(controller: _controller),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              const detected = 'glow serum';
              ref.read(searchQueryProvider.notifier).setQuery(detected);
              Navigator.pop(context);
            },
            child: const Text('Use "glow serum"'),
          ),
        ],
      ),
    );
  }
}

class _VoiceWave extends StatelessWidget {
  final AnimationController controller;

  const _VoiceWave({required this.controller});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final base = 10.0;
        final values = List.generate(5, (index) {
          final phase = (controller.value * 2 * math.pi) + (index * 0.7);
          return base + (math.sin(phase).abs() * 16);
        });
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: values
              .map(
                (h) => Container(
                  width: 6,
                  height: h,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: scheme.primary.withAlpha(160),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SortChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

List<Product> _applyFilter({required List<Product> products, required ProductFilter filter}) {
  var result = products
      .where(
        (p) => p.discountPrice >= filter.priceRange.start && p.discountPrice <= filter.priceRange.end,
      )
      .toList();

  if (filter.minRating > 0) {
    result = result.where((p) => p.rating >= filter.minRating).toList();
  }
  if (filter.minReviews > 0) {
    result = result.where((p) => p.reviewCount >= filter.minReviews).toList();
  }
  if (filter.categoryId != null) {
    result = result.where((p) => p.categoryId == filter.categoryId).toList();
  }
  if (filter.brandId != null) {
    result = result.where((p) => p.brandId == filter.brandId).toList();
  }
  if (filter.inStockOnly) {
    result = result.where((p) => p.stock > 0).toList();
  }
  if (filter.discountRange.start > 0 || filter.discountRange.end < 70) {
    result = result.where((p) {
      if (p.price <= 0) return false;
      final pct = ((p.price - p.discountPrice) / p.price) * 100;
      return pct >= filter.discountRange.start && pct <= filter.discountRange.end;
    }).toList();
  }

  switch (filter.sort) {
    case ProductSort.bestDeal:
      result.sort((a, b) {
        final aPct = a.price <= 0 ? 0 : (a.price - a.discountPrice) / a.price;
        final bPct = b.price <= 0 ? 0 : (b.price - b.discountPrice) / b.price;
        final byDeal = bPct.compareTo(aPct);
        if (byDeal != 0) return byDeal;
        return b.rating.compareTo(a.rating);
      });
      break;
    case ProductSort.priceLow:
      result.sort((a, b) => a.discountPrice.compareTo(b.discountPrice));
      break;
    case ProductSort.priceHigh:
      result.sort((a, b) => b.discountPrice.compareTo(a.discountPrice));
      break;
    case ProductSort.rating:
      result.sort((a, b) => b.rating.compareTo(a.rating));
      break;
    case ProductSort.reviews:
      result.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
      break;
    case ProductSort.newest:
      result.sort((a, b) => b.id.compareTo(a.id));
      break;
    case ProductSort.recommended:
      break;
  }

  return result;
}


List<String> _fuzzySuggestions(List<String> pool, String query) {
  final q = query.toLowerCase();
  final direct = pool.where((e) => e.toLowerCase().contains(q)).toSet().toList();
  if (direct.length >= 8) return direct.take(8).toList();
  final scored = <MapEntry<String, int>>[];
  for (final item in pool.toSet()) {
    final d = _levenshtein(item.toLowerCase(), q);
    if (d <= 2) scored.add(MapEntry(item, d));
  }
  scored.sort((a, b) => a.value.compareTo(b.value));
  final fuzzy = scored.map((e) => e.key).where((e) => !direct.contains(e)).toList();
  return [...direct, ...fuzzy].take(8).toList();
}

String? _closestSuggestion(String query, List<String> pool) {
  if (query.isEmpty) return null;
  final q = query.toLowerCase();
  var best = '';
  var bestScore = 3;
  for (final item in pool.toSet()) {
    final d = _levenshtein(item.toLowerCase(), q);
    if (d < bestScore) {
      bestScore = d;
      best = item;
    }
  }
  return bestScore <= 2 ? best : null;
}

int _levenshtein(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  final m = List.generate(a.length + 1, (_) => List<int>.filled(b.length + 1, 0));
  for (var i = 0; i <= a.length; i++) {
    m[i][0] = i;
  }
  for (var j = 0; j <= b.length; j++) {
    m[0][j] = j;
  }
  for (var i = 1; i <= a.length; i++) {
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      m[i][j] = [
        m[i - 1][j] + 1,
        m[i][j - 1] + 1,
        m[i - 1][j - 1] + cost,
      ].reduce((v, e) => v < e ? v : e);
    }
  }
  return m[a.length][b.length];
}
