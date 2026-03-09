import 'package:equatable/equatable.dart';
import 'product.dart';

class CartItem extends Equatable {
  final Product product;
  final int quantity;
  final String note;

  const CartItem({required this.product, required this.quantity, required this.note});

  CartItem copyWith({int? quantity, String? note}) {
    return CartItem(
      product: product,
      quantity: quantity ?? this.quantity,
      note: note ?? this.note,
    );
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      quantity: json['quantity'] as int,
      note: json['note'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'quantity': quantity,
      'note': note,
    };
  }

  @override
  List<Object?> get props => [product, quantity, note];
}
