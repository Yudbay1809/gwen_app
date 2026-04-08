import 'package:flutter_test/flutter_test.dart';
import 'package:gwen_app/features/home/presentation/home_providers.dart';
import 'package:gwen_app/features/home/presentation/home_screen_logic.dart';
import 'package:gwen_app/shared/models/product.dart';

Product _product({
  required int id,
  required String name,
  required double price,
  required double discount,
  required double rating,
  int stock = 5,
}) {
  return Product(
    id: id,
    name: name,
    image: 'x',
    price: price,
    discountPrice: discount,
    rating: rating,
    reviewCount: 120,
    categoryId: 1,
    brandId: 1,
    stock: stock,
  );
}

void main() {
  test('applyHomeFilter supports query and quick filter sorting', () {
    final items = [
      _product(
        id: 100,
        name: 'Glow Serum',
        price: 200,
        discount: 150,
        rating: 4.8,
      ),
      _product(
        id: 101,
        name: 'Sunscreen',
        price: 300,
        discount: 290,
        rating: 4.5,
      ),
    ];

    final result = applyHomeFilter(
      items,
      HomeAllProductsFilter.all,
      'serum',
      HomeQuickFilter.none,
    );

    expect(result.length, 1);
    expect(result.first.name, 'Glow Serum');

    final sorted = applyHomeFilter(
      items,
      HomeAllProductsFilter.all,
      '',
      HomeQuickFilter.priceLow,
    );
    expect(sorted.first.discountPrice <= sorted.last.discountPrice, true);
  });

  test('sortProductsByStock keeps in-stock before out-of-stock', () {
    final sorted = sortProductsByStock([
      _product(
        id: 1,
        name: 'A',
        price: 100,
        discount: 90,
        rating: 4.5,
        stock: 0,
      ),
      _product(
        id: 2,
        name: 'B',
        price: 120,
        discount: 100,
        rating: 4.6,
        stock: 3,
      ),
    ]);
    expect(sorted.first.id, 2);
    expect(sorted.last.id, 1);
  });
}
