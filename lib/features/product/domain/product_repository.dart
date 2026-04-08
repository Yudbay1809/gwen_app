import '../../../shared/models/product.dart';

abstract class ProductRepository {
  Future<List<Product>> getAll();

  Future<Product?> getById(int id);

  Future<List<Product>> search(String query);
}
