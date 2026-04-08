import '../../../shared/models/product.dart';
import 'dto/product_dto.dart';
import 'mappers/product_mapper.dart';
import '../domain/product_repository.dart';

typedef ProductLoader = Future<List<Product>> Function();

class ProductRepositoryImpl implements ProductRepository {
  final ProductLoader _loadProducts;

  ProductRepositoryImpl({required ProductLoader loadProducts})
    : _loadProducts = loadProducts;

  @override
  Future<List<Product>> getAll() async {
    return _loadProducts();
  }

  Future<List<Product>> getAllFromJsonList(
    List<Map<String, dynamic>> rawList,
  ) async {
    final dtos = rawList.map(ProductDto.fromJson).toList();
    return dtos.map(mapProductDtoToDomain).toList();
  }

  @override
  Future<Product?> getById(int id) async {
    final products = await _loadProducts();
    for (final product in products) {
      if (product.id == id) return product;
    }
    return null;
  }

  @override
  Future<List<Product>> search(String query) async {
    final products = await _loadProducts();
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return products;
    return products
        .where(
          (product) => product.name.toLowerCase().contains(normalizedQuery),
        )
        .toList();
  }
}
