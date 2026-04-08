class ProductDto {
  final int id;
  final String name;
  final String image;
  final double price;
  final double discountPrice;
  final double rating;
  final int reviewCount;
  final int categoryId;
  final int brandId;
  final int stock;

  const ProductDto({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    required this.discountPrice,
    required this.rating,
    required this.reviewCount,
    required this.categoryId,
    required this.brandId,
    required this.stock,
  });

  factory ProductDto.fromJson(Map<String, dynamic> json) {
    return ProductDto(
      id: json['id'] as int,
      name: json['name'] as String,
      image: json['image'] as String,
      price: (json['price'] as num).toDouble(),
      discountPrice: (json['discountPrice'] as num).toDouble(),
      rating: (json['rating'] as num).toDouble(),
      reviewCount: json['reviewCount'] as int,
      categoryId: json['categoryId'] as int,
      brandId: json['brandId'] as int,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'price': price,
      'discountPrice': discountPrice,
      'rating': rating,
      'reviewCount': reviewCount,
      'categoryId': categoryId,
      'brandId': brandId,
      'stock': stock,
    };
  }
}
