import 'package:flutter/material.dart';
import '../../../shared/widgets/price_widget.dart';

class OrderSuccessArgs {
  final double total;
  final int itemCount;
  final String addressLabel;
  final String paymentMethod;

  const OrderSuccessArgs({
    required this.total,
    required this.itemCount,
    required this.addressLabel,
    required this.paymentMethod,
  });
}

class OrderSuccessScreen extends StatelessWidget {
  final OrderSuccessArgs? args;

  const OrderSuccessScreen({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    final data = args;
    return Scaffold(
      appBar: AppBar(title: const Text('Order Success')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: data == null
            ? const Center(child: Text('No order summary available'))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 64),
                  const SizedBox(height: 12),
                  const Text('Thank you for your order!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  const Text('Summary', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Items'),
                      Text('${data.itemCount}'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total'),
                      PriceWidget(price: data.total),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Shipping', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(data.addressLabel),
                  const SizedBox(height: 12),
                  const Text('Payment', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(data.paymentMethod),
                ],
              ),
      ),
    );
  }
}
