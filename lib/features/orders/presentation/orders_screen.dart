import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/order_item.dart';
import 'orders_providers.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return Card(
            child: ListTile(
              title: Text(order.code),
              subtitle: Text(order.date),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Rp ${order.total.toStringAsFixed(0)}'),
                  const SizedBox(height: 4),
                  _StatusChip(status: order.status),
                ],
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
              ),
            ),
          );
        },
      ),
    );
  }
}

class OrderDetailScreen extends StatelessWidget {
  final OrderItem order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final steps = const ['Processing', 'Shipped', 'Delivered'];
    final currentIndex = steps.indexOf(order.status);

    return Scaffold(
      appBar: AppBar(title: Text(order.code)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order Date: ${order.date}'),
            const SizedBox(height: 8),
            Text('Total: Rp ${order.total.toStringAsFixed(0)}'),
            const SizedBox(height: 24),
            const Text('Tracking', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Stepper(
              currentStep: currentIndex < 0 ? 0 : currentIndex,
              controlsBuilder: (_, __) => const SizedBox.shrink(),
              steps: steps
                  .map(
                    (s) => Step(
                      title: Text(s),
                      content: const SizedBox.shrink(),
                      isActive: steps.indexOf(s) <= currentIndex,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  Color get _color {
    switch (status) {
      case 'Delivered':
        return Colors.green;
      case 'Shipped':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(fontSize: 11, color: _color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
