import 'package:equatable/equatable.dart';

class OrderItem extends Equatable {
  final int id;
  final String code;
  final String date;
  final double total;
  final String status;

  const OrderItem({
    required this.id,
    required this.code,
    required this.date,
    required this.total,
    required this.status,
  });

  @override
  List<Object?> get props => [id, code, date, total, status];
}
