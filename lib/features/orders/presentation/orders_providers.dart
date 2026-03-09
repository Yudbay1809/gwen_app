import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/order_item.dart';
import '../../../shared/models/order_line.dart';

class OrderDetail {
  final OrderItem order;
  final String address;
  final String paymentMethod;
  final List<OrderLine> items;

  const OrderDetail({
    required this.order,
    required this.address,
    required this.paymentMethod,
    required this.items,
  });
}

final ordersProvider = Provider<List<OrderItem>>((ref) {
  return const [
    OrderItem(id: 1, code: 'ORD-1021', date: 'Mar 7, 2026', total: 420000, status: 'Processing'),
    OrderItem(id: 2, code: 'ORD-1012', date: 'Mar 1, 2026', total: 260000, status: 'Shipped'),
    OrderItem(id: 3, code: 'ORD-1004', date: 'Feb 20, 2026', total: 780000, status: 'Delivered'),
  ];
});

final orderDetailProvider = Provider.family<OrderDetail, int>((ref, id) {
  final order = ref.read(ordersProvider).firstWhere((o) => o.id == id);
  return OrderDetail(
    order: order,
    address: 'Jl. Merdeka No. 12, Jakarta Selatan',
    paymentMethod: 'Virtual Account',
    items: const [
      OrderLine(name: 'Glow Serum', quantity: 1, price: 180000, status: 'Processing'),
      OrderLine(name: 'Velvet Matte Lip', quantity: 2, price: 120000, status: 'Shipped'),
    ],
  );
});

class OrderRatingNotifier extends Notifier<Map<int, double>> {
  @override
  Map<int, double> build() => {};

  void setRating(int orderId, double rating) {
    state = {...state, orderId: rating};
  }
}

final orderRatingProvider =
    NotifierProvider<OrderRatingNotifier, Map<int, double>>(OrderRatingNotifier.new);
