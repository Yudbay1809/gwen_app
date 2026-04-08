import 'package:flutter_test/flutter_test.dart';
import 'package:gwen_app/features/product/data/product_repository_impl.dart';
import 'package:gwen_app/shared/models/product.dart';

Product _p(int id, String name) {
  return Product(
    id: id,
    name: name,
    image: 'img',
    price: 100,
    discountPrice: 90,
    rating: 4,
    reviewCount: 10,
    categoryId: 1,
    brandId: 1,
    stock: 3,
  );
}

void main() {
  test('product repository supports getById and search', () async {
    final repo = ProductRepositoryImpl(
      loadProducts: () async => [_p(1, 'Glow Serum'), _p(2, 'Sunscreen Ultra')],
    );

    expect((await repo.getById(2))?.name, 'Sunscreen Ultra');
    expect(await repo.getById(9), isNull);

    final result = await repo.search('glow');
    expect(result.length, 1);
    expect(result.first.id, 1);
  });
}
