import 'package:riverpod/riverpod.dart';
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

final homeLoadProvider = FutureProvider<HomeData>((ref) async {
  await Future.delayed(const Duration(milliseconds: 600));
  return ref.read(homeDataProvider);
});

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

final searchResultsProvider = Provider<List<Product>>((ref) {
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final data = ref.watch(homeDataProvider);
  if (query.isEmpty) return data.allProducts;
  return data.allProducts.where((p) => p.name.toLowerCase().contains(query)).toList();
});

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
    );
  });
}
