import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'coupons_provider.dart';
import '../../cart/presentation/cart_providers.dart';

class CouponsScreen extends ConsumerWidget {
  const CouponsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coupons = ref.watch(couponsProvider);
    final claimed = ref.watch(claimedCouponsProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    final promoRules = ref.watch(availablePromosProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Coupons Center')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Available coupons', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...coupons.map(
            (c) {
              final isClaimed = claimed.contains(c.code);
              final eligible = subtotal >= c.minSubtotal;
              return Card(
                child: ListTile(
                  title: Text(c.title),
                  subtitle: Text('${c.description}\nMin Rp ${c.minSubtotal.toStringAsFixed(0)} · Exp ${c.expiry}'),
                  isThreeLine: true,
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(c.code, style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      ElevatedButton(
                        onPressed: !eligible
                            ? null
                            : () {
                                ref.read(claimedCouponsProvider.notifier).claim(c.code);
                                final message = ref.read(appliedPromosProvider.notifier).apply(
                                      code: c.code,
                                      subtotal: subtotal,
                                      rules: promoRules,
                                    );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(message.isEmpty ? '${c.code} applied' : message),
                                  ),
                                );
                              },
                        child: Text(isClaimed ? 'Applied' : 'Apply'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
