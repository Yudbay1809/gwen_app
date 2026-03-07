import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/price_widget.dart';
import 'cart_providers.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _promoController = TextEditingController();

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  void _applyPromo() {
    final code = _promoController.text.trim().toUpperCase();
    if (code == 'BEAUTY10') {
      ref.read(promoProvider.notifier).state = const PromoState(code: 'BEAUTY10', discountPct: 0.10);
    } else if (code == 'GLOW20') {
      ref.read(promoProvider.notifier).state = const PromoState(code: 'GLOW20', discountPct: 0.20);
    } else {
      ref.read(promoProvider.notifier).state = const PromoState(code: '', discountPct: 0);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid promo code')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(cartProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    final discount = ref.watch(cartDiscountProvider);
    final total = ref.watch(cartTotalProvider);
    final promo = ref.watch(promoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: items.isEmpty
          ? const Center(child: Text('Cart is empty'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...items.map(
                  (item) => Card(
                    child: ListTile(
                      leading: Image.network(item.product.image, width: 56, height: 56, fit: BoxFit.cover),
                      title: Text(item.product.name),
                      subtitle: PriceWidget(price: item.product.discountPrice),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () => ref.read(cartProvider.notifier).updateQty(item.product, item.quantity - 1),
                          ),
                          Text('${item.quantity}'),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () => ref.read(cartProvider.notifier).updateQty(item.product, item.quantity + 1),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => ref.read(cartProvider.notifier).remove(item.product),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _promoController,
                  decoration: InputDecoration(
                    hintText: 'Promo code (BEAUTY10 / GLOW20)',
                    suffixIcon: TextButton(
                      onPressed: _applyPromo,
                      child: const Text('Apply'),
                    ),
                  ),
                ),
                if (promo.isActive)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('Promo applied: ${promo.code}'),
                  ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal'),
                    PriceWidget(price: subtotal),
                  ],
                ),
                if (discount > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Discount'),
                      Text('- Rp ${discount.toStringAsFixed(0)}'),
                    ],
                  ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total', style: TextStyle(fontWeight: FontWeight.w700)),
                    PriceWidget(price: total),
                  ],
                ),
              ],
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)]),
        child: Row(
          children: [
            Expanded(child: PriceWidget(price: total)),
            ElevatedButton(
              onPressed: items.isEmpty ? null : () => context.go('/checkout'),
              child: const Text('Checkout'),
            ),
          ],
        ),
      ),
    );
  }
}
