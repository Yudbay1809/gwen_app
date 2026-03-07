import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../home/presentation/home_providers.dart';
import '../../../shared/models/product.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../shared/widgets/cart_badge_button.dart';
import 'product_filter_sheet.dart';
import 'product_grid_shimmer.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  late ProductFilter _filter;
  bool _initialized = false;
  bool _loading = true;
  int _visibleCount = 8;
  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _filter = const ProductFilter(
      sort: ProductSort.recommended,
      priceRange: RangeValues(0, 1000000),
    );
    _controller = ScrollController()..addListener(_onScroll);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final queryParams = GoRouterState.of(context).uri.queryParameters;
      final categoryId = int.tryParse(queryParams['categoryId'] ?? '');
      if (categoryId != null) {
        _filter = _filter.copyWith(categoryId: categoryId);
      }
      _initialized = true;
    }
  }

  void _onScroll() {
    if (_controller.position.pixels >= _controller.position.maxScrollExtent - 240) {
      setState(() => _visibleCount += 6);
    }
  }

  Future<void> _onRefresh() async {
    setState(() {
      _loading = true;
      _visibleCount = 8;
    });
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(homeDataProvider);

    final all = data.allProducts;
    final minPrice = all.map((p) => p.discountPrice).reduce((a, b) => a < b ? a : b);
    final maxPrice = all.map((p) => p.discountPrice).reduce((a, b) => a > b ? a : b);

    final filtered = _applyFilter(products: all, filter: _filter);
    final visible = filtered.take(_visibleCount).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _openFilterSheet(context, data, minPrice, maxPrice),
          ),
          const CartBadgeButton(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: _loading
            ? const ProductGridShimmer()
            : GridView.builder(
                controller: _controller,
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.62,
                ),
                itemCount: visible.length,
                itemBuilder: (context, index) {
                  final product = visible[index];
                  return ProductCard(
                    product: product,
                    onTap: () => context.go('/product/${product.id}'),
                  );
                },
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
