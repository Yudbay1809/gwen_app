import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/product.dart';
import '../../home/presentation/home_providers.dart';
import '../data/product_repository_impl.dart';
import '../domain/product_repository.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepositoryImpl(
    loadProducts: () async => ref.read(homeDataProvider).allProducts,
  );
});

final productByIdProvider = FutureProvider.family<Product?, int>((ref, id) {
  return ref.read(productRepositoryProvider).getById(id);
});

final productSearchProvider = FutureProvider.family<List<Product>, String>((
  ref,
  query,
) {
  return ref.read(productRepositoryProvider).search(query);
});
