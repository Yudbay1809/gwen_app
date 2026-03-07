import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/order_item.dart';

final ordersProvider = Provider<List<OrderItem>>((ref) {
  return const [
    OrderItem(id: 1, code: 'ORD-1021', date: 'Mar 7, 2026', total: 420000, status: 'Processing'),
    OrderItem(id: 2, code: 'ORD-1012', date: 'Mar 1, 2026', total: 260000, status: 'Shipped'),
    OrderItem(id: 3, code: 'ORD-1004', date: 'Feb 20, 2026', total: 780000, status: 'Delivered'),
  ];
});
