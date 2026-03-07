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
    final query = ref.watch(searchQueryProvider);
    final suggestions = ref.watch(searchSuggestionProvider);

    final minPrice = data.allProducts.map((p) => p.discountPrice).reduce((a, b) => a < b ? a : b);
    final maxPrice = data.allProducts.map((p) => p.discountPrice).reduce((a, b) => a > b ? a : b);

    final results = _applyFilter(products: baseResults, filter: _filter);
    final suggestList = suggestions.isEmpty
        ? data.categories.map((c) => c.name).toList()
        : suggestions;

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
                      onChanged: (value) => ref.read(searchQueryProvider.notifier).state = value,
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
                ],
              ),
            ),
            if (query.trim().isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Suggestions', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: suggestList
                          .map(
                            (q) => ActionChip(
                              label: Text(q),
                              onPressed: () {
                                ref.read(searchQueryProvider.notifier).state = q;
                                _controller.text = q;
                              },
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
                            (q) => ActionChip(
                              label: Text(q),
                              onPressed: () {
                                ref.read(searchQueryProvider.notifier).state = q;
                                _controller.text = q;
                              },
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            Expanded(
              child: _loading
                  ? const ProductGridShimmer()
                  : results.isEmpty
                      ? const Center(child: Text('No results found'))
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
}

List<Product> _applyFilter({required List<Product> products, required ProductFilter filter}) {
  var result = products
      .where(
        (p) => p.discountPrice >= filter.priceRange.start && p.discountPrice <= filter.priceRange.end,
      )
      .toList();

  if (filter.categoryId != null) {
    result = result.where((p) => p.categoryId == filter.categoryId).toList();
  }
  if (filter.brandId != null) {
    result = result.where((p) => p.brandId == filter.brandId).toList();
  }

  switch (filter.sort) {
    case ProductSort.priceLow:
      result.sort((a, b) => a.discountPrice.compareTo(b.discountPrice));
      break;
    case ProductSort.priceHigh:
      result.sort((a, b) => b.discountPrice.compareTo(a.discountPrice));
      break;
    case ProductSort.rating:
      result.sort((a, b) => b.rating.compareTo(a.rating));
      break;
    case ProductSort.recommended:
      break;
  }

  return result;
}
