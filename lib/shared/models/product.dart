import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final int id;
  final String name;
  final String image;
  final double price;
  final double discountPrice;
  final double rating;
  final int reviewCount;
  final int categoryId;
  final int brandId;

  const Product({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    required this.discountPrice,
    required this.rating,
    required this.reviewCount,
    required this.categoryId,
    required this.brandId,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      image: json['image'] as String,
      price: (json['price'] as num).toDouble(),
      discountPrice: (json['discountPrice'] as num).toDouble(),
      rating: (json['rating'] as num).toDouble(),
      reviewCount: json['reviewCount'] as int,
      categoryId: json['categoryId'] as int,
      brandId: json['brandId'] as int,
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
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        image,
        price,
        discountPrice,
        rating,
        reviewCount,
        categoryId,
        brandId,
      ];
}
