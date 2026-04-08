import 'package:flutter_test/flutter_test.dart';
import 'package:gwen_app/features/product/data/dto/product_dto.dart';
import 'package:gwen_app/features/product/data/mappers/product_mapper.dart';

void main() {
  test('product dto mapper converts both directions', () {
    const dto = ProductDto(
      id: 10,
      name: 'Hydra Serum',
      image: 'image-url',
      price: 220000,
      discountPrice: 180000,
      rating: 4.8,
      reviewCount: 456,
      categoryId: 2,
      brandId: 3,
      stock: 12,
    );

    final domain = mapProductDtoToDomain(dto);
    expect(domain.id, 10);
    expect(domain.name, 'Hydra Serum');

    final backDto = mapProductDomainToDto(domain);
    expect(backDto.toJson(), dto.toJson());
  });
}
