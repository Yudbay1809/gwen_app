import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/models/product.dart';
import '../../../shared/models/category.dart';
import '../../../shared/models/brand.dart';

class HomeData {
  final List<String> bannerImages;
  final List<Category> categories;
  final List<Brand> brands;
  final List<Product> flashSale;
  final List<Product> bestSeller;
  final List<Product> newArrivals;
  final List<Product> exclusive;

  const HomeData({
    required this.bannerImages,
    required this.categories,
    required this.brands,
    required this.flashSale,
    required this.bestSeller,
    required this.newArrivals,
    required this.exclusive,
  });

  List<Product> get allProducts => [
        ...flashSale,
        ...bestSeller,
        ...newArrivals,
        ...exclusive,
      ];

  Map<String, dynamic> toJson() {
    return {
      'bannerImages': bannerImages,
      'categories': categories.map((e) => e.toJson()).toList(),
      'brands': brands.map((e) => e.toJson()).toList(),
      'flashSale': flashSale.map((e) => e.toJson()).toList(),
      'bestSeller': bestSeller.map((e) => e.toJson()).toList(),
      'newArrivals': newArrivals.map((e) => e.toJson()).toList(),
      'exclusive': exclusive.map((e) => e.toJson()).toList(),
    };
  }

  factory HomeData.fromJson(Map<String, dynamic> json) {
    return HomeData(
      bannerImages: List<String>.from(json['bannerImages'] as List),
      categories: (json['categories'] as List)
          .map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList(),
      brands: (json['brands'] as List).map((e) => Brand.fromJson(e as Map<String, dynamic>)).toList(),
      flashSale: (json['flashSale'] as List)
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList(),
      bestSeller: (json['bestSeller'] as List)
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList(),
      newArrivals: (json['newArrivals'] as List)
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList(),
      exclusive: (json['exclusive'] as List)
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

final homeDataProvider = Provider<HomeData>((ref) {
  final banners = [
    'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=1200&q=80',
    'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=1200&q=80',
    'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?w=1200&q=80',
  ];

  final categories = [
    const Category(id: 1, name: 'Skincare'),
    const Category(id: 2, name: 'Makeup'),
    const Category(id: 3, name: 'Haircare'),
    const Category(id: 4, name: 'Body'),
    const Category(id: 5, name: 'Fragrance'),
    const Category(id: 6, name: 'Tools'),
  ];

  final brands = [
    const Brand(id: 1, name: 'Aurora', logo: 'https://images.unsplash.com/photo-1522336572468-97b06e8ef143?w=200&q=80'),
    const Brand(id: 2, name: 'Velvet', logo: 'https://images.unsplash.com/photo-1515377905703-c4788e51af15?w=200&q=80'),
    const Brand(id: 3, name: 'Luma', logo: 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=200&q=80'),
    const Brand(id: 4, name: 'Bloom', logo: 'https://images.unsplash.com/photo-1512436991641-6745cdb1723f?w=200&q=80'),
    const Brand(id: 5, name: 'Elys', logo: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=200&q=80'),
  ];

  final flashSale = _dummyProducts(
    10,
    startId: 100,
    categoryCount: categories.length,
    brandCount: brands.length,
    priceBase: 180000,
    discountPct: 0.35,
  );
  final bestSeller = _dummyProducts(
    8,
    startId: 200,
    categoryCount: categories.length,
    brandCount: brands.length,
    priceBase: 220000,
    discountPct: 0.2,
  );
  final newArrivals = _dummyProducts(
    8,
    startId: 300,
    categoryCount: categories.length,
    brandCount: brands.length,
    priceBase: 200000,
    discountPct: 0.1,
  );
  final exclusive = _dummyProducts(
    6,
    startId: 400,
    categoryCount: categories.length,
    brandCount: brands.length,
    priceBase: 280000,
    discountPct: 0.15,
  );

  return HomeData(
    bannerImages: banners,
    categories: categories,
    brands: brands,
    flashSale: flashSale,
    bestSeller: bestSeller,
    newArrivals: newArrivals,
    exclusive: exclusive,
  );
});

class _HomeCache {
  static const _key = 'home_cache_v1';

  static Future<HomeData?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      final jsonMap = jsonDecode(raw) as Map<String, dynamic>;
      return HomeData.fromJson(jsonMap);
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(HomeData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(data.toJson()));
  }
}

final homeLoadProvider = FutureProvider<HomeData>((ref) async {
  final cached = await _HomeCache.load();
  if (cached != null) return cached;
  await Future.delayed(const Duration(milliseconds: 600));
  final data = ref.read(homeDataProvider);
  await _HomeCache.save(data);
  return data;
});

enum HomeAllProductsFilter { all, promo, best, newest }

class HomeAllProductsFilterState {
  final HomeAllProductsFilter filter;
  final String query;

  const HomeAllProductsFilterState({required this.filter, required this.query});

  HomeAllProductsFilterState copyWith({HomeAllProductsFilter? filter, String? query}) {
    return HomeAllProductsFilterState(
      filter: filter ?? this.filter,
      query: query ?? this.query,
    );
  }
}

class HomeAllProductsFilterNotifier extends Notifier<HomeAllProductsFilterState> {
  static const keyFilter = 'home_all_filter';
  static const keyQuery = 'home_all_query';

  @override
  HomeAllProductsFilterState build() {
    _load();
    return const HomeAllProductsFilterState(filter: HomeAllProductsFilter.all, query: '');
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final rawFilter = prefs.getString(keyFilter);
    final rawQuery = prefs.getString(keyQuery) ?? '';
    final filter = HomeAllProductsFilter.values.firstWhere(
      (e) => e.name == rawFilter,
      orElse: () => HomeAllProductsFilter.all,
    );
    state = state.copyWith(filter: filter, query: rawQuery);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyFilter, state.filter.name);
    await prefs.setString(keyQuery, state.query);
  }

  void setFilter(HomeAllProductsFilter filter) {
    state = state.copyWith(filter: filter);
    _save();
  }

  void setQuery(String query) {
    state = state.copyWith(query: query);
    _save();
  }

  void reset() {
    state = const HomeAllProductsFilterState(filter: HomeAllProductsFilter.all, query: '');
    _save();
  }
}

final homeAllProductsFilterProvider =
    NotifierProvider<HomeAllProductsFilterNotifier, HomeAllProductsFilterState>(
  HomeAllProductsFilterNotifier.new,
);

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String value) => state = value;
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

final searchResultsProvider = Provider<List<Product>>((ref) {
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final data = ref.watch(homeDataProvider);
  if (query.isEmpty) return data.allProducts;
  return data.allProducts.where((p) => p.name.toLowerCase().contains(query)).toList();
});

class HomeInfiniteProductsState {
  final List<Product> items;
  final bool isLoading;
  final int nextStartId;
  final int page;
  final bool hasMore;
  final Set<int> lastBatchIds;

  const HomeInfiniteProductsState({
    required this.items,
    required this.isLoading,
    required this.nextStartId,
    required this.page,
    required this.hasMore,
    required this.lastBatchIds,
  });

  HomeInfiniteProductsState copyWith({
    List<Product>? items,
    bool? isLoading,
    int? nextStartId,
    int? page,
    bool? hasMore,
    Set<int>? lastBatchIds,
  }) {
    return HomeInfiniteProductsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      nextStartId: nextStartId ?? this.nextStartId,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      lastBatchIds: lastBatchIds ?? this.lastBatchIds,
    );
  }
}

class HomeInfiniteProductsNotifier extends Notifier<HomeInfiniteProductsState> {
  static const int _pageSize = 10;
  static const int _maxPages = 5;

  @override
  HomeInfiniteProductsState build() {
    final base = ref.read(homeDataProvider).allProducts;
    return HomeInfiniteProductsState(
      items: base,
      isLoading: false,
      nextStartId: 1000,
      page: 1,
      hasMore: true,
      lastBatchIds: const {},
    );
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    if (state.page >= _maxPages) {
      state = state.copyWith(hasMore: false);
      return;
    }
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 350));
    final data = ref.read(homeDataProvider);
    final next = _dummyProducts(
      _pageSize,
      startId: state.nextStartId,
      categoryCount: data.categories.length,
      brandCount: data.brands.length,
      priceBase: 160000 + (state.nextStartId % 5) * 15000,
      discountPct: 0.1 + (state.nextStartId % 3) * 0.05,
    );
    final nextHasMore = next.isNotEmpty;
    state = state.copyWith(
      items: [...state.items, ...next],
      isLoading: false,
      nextStartId: state.nextStartId + next.length,
      page: state.page + 1,
      hasMore: nextHasMore,
      lastBatchIds: next.map((e) => e.id).toSet(),
    );
  }
}

final homeInfiniteProductsProvider =
    NotifierProvider<HomeInfiniteProductsNotifier, HomeInfiniteProductsState>(
  HomeInfiniteProductsNotifier.new,
);

List<Product> _dummyProducts(
  int count, {
  required int startId,
  required int categoryCount,
  required int brandCount,
  required double priceBase,
  double discountPct = 0,
}) {
  return List.generate(count, (i) {
    final price = priceBase + (i * 25000);
    final discountPrice = price * (1 - discountPct);
    final categoryId = (i % categoryCount) + 1;
    final brandId = (i % brandCount) + 1;
    return Product(
      id: startId + i,
      name: 'Beauty Product ${startId + i}',
      image: 'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=800&q=80&sig=${startId + i}',
      price: price,
      discountPrice: discountPrice,
      rating: 4.2 - (i % 3) * 0.3,
      reviewCount: 120 + i * 3,
      categoryId: categoryId,
      brandId: brandId,
      stock: (i % 4 == 0) ? 0 : (10 - (i % 5)),
    );
  });
}
