import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/product.dart';
import '../../../shared/widgets/product_card.dart';
import 'section_header.dart';
import '../../cart/presentation/cart_providers.dart';

class FlashSaleSection extends ConsumerWidget {
  final List<Product> products;
  final VoidCallback? onSeeAll;

  const FlashSaleSection({super.key, required this.products, this.onSeeAll});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Flash Sale',
          onSeeAll: onSeeAll,
          trailing: const _FlashCountdown(),
        ),
        SizedBox(
          height: 248,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final product = products[index];
              return SizedBox(
                width: 180,
                child: ProductCard(
                  product: product,
                  onTap: () => context.go('/product/${product.id}'),
                  onAdd: () => ref.read(cartProvider.notifier).add(product),
                ),
              );
            },
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemCount: products.length,
          ),
        ),
      ],
    ),
    );
  }
}

class _FlashCountdown extends StatefulWidget {
  const _FlashCountdown();

  @override
  State<_FlashCountdown> createState() => _FlashCountdownState();
}

class _FlashCountdownState extends State<_FlashCountdown> {
  late Duration _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = const Duration(hours: 2, minutes: 18, seconds: 45);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        final next = _remaining - const Duration(seconds: 1);
        _remaining = next.isNegative ? Duration.zero : next;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = _remaining.inHours.toString().padLeft(2, '0');
    final m = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline.withAlpha(120)),
      ),
      child: Text(
        '$h:$m:$s',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}
