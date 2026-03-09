import 'package:flutter_test/flutter_test.dart';
import 'package:gwen_app/features/cart/presentation/cart_providers.dart';
import 'package:gwen_app/shared/models/cart_item.dart';
import 'package:gwen_app/shared/models/product.dart';

Product _product(int id, int categoryId) {
  return Product(
    id: id,
    name: 'P$id',
    image: 'x',
    price: 100,
    discountPrice: 90,
    rating: 4.0,
    reviewCount: 10,
    categoryId: categoryId,
    brandId: 1,
    stock: 5,
  );
}

void main() {
  test('suggestBundle requires at least two categories', () {
    final itemsSameCategory = [
      CartItem(product: _product(1, 1), quantity: 1, note: ''),
      CartItem(product: _product(2, 1), quantity: 1, note: ''),
    ];
    final itemsDifferentCategory = [
      CartItem(product: _product(1, 1), quantity: 1, note: ''),
      CartItem(product: _product(2, 2), quantity: 1, note: ''),
    ];

    expect(suggestBundle(itemsSameCategory), isNull);
    expect(suggestBundle(itemsDifferentCategory), isNotNull);
  });
}
