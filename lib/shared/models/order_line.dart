import 'package:equatable/equatable.dart';

class OrderLine extends Equatable {
  final String name;
  final int quantity;
  final double price;
  final String status;

  const OrderLine({
    required this.name,
    required this.quantity,
    required this.price,
    required this.status,
  });

  @override
  List<Object?> get props => [name, quantity, price, status];
}
