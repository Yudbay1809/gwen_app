import '../../../../shared/models/product.dart';
import '../dto/product_dto.dart';

Product mapProductDtoToDomain(ProductDto dto) {
  return Product(
    id: dto.id,
    name: dto.name,
    image: dto.image,
    price: dto.price,
    discountPrice: dto.discountPrice,
    rating: dto.rating,
    reviewCount: dto.reviewCount,
    categoryId: dto.categoryId,
    brandId: dto.brandId,
    stock: dto.stock,
  );
}

ProductDto mapProductDomainToDto(Product product) {
  return ProductDto(
    id: product.id,
    name: product.name,
    image: product.image,
    price: product.price,
    discountPrice: product.discountPrice,
    rating: product.rating,
    reviewCount: product.reviewCount,
    categoryId: product.categoryId,
    brandId: product.brandId,
    stock: product.stock,
  );
}
