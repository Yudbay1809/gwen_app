import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/price_widget.dart';
import 'package:intl/intl.dart';
import '../../../shared/models/cart_item.dart';
import 'cart_providers.dart';
import '../../home/presentation/home_providers.dart';
import '../../../shared/widgets/empty_state.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _promoController = TextEditingController();
  bool _autoApplied = false;

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  void _applyPromo() {
    final code = _promoController.text.trim().toUpperCase();
    if (code.isEmpty) return;
    final subtotal = ref.read(cartSubtotalProvider);
    final rules = ref.read(availablePromosProvider);
    final message = ref.read(appliedPromosProvider.notifier).apply(
          code: code,
          subtotal: subtotal,
          rules: rules,
        );
    if (message.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Promo applied')));
    }
  }

  void _openVoucherScan(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Scan Result', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Simulated QR: BEAUTY10'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _promoController.text = 'BEAUTY10';
                  _applyPromo();
                  Navigator.pop(context);
                },
                child: const Text('Apply BEAUTY10'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editNote(CartItem item) {
    final controller = TextEditingController(text: item.note);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Item Note'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Add a note (e.g., gift wrap)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              ref.read(cartProvider.notifier).updateNote(item.product, controller.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _removeWithUndo(CartItem item) {
    final notifier = ref.read(cartProvider.notifier);
    notifier.remove(item.product);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        content: Text('Removed ${item.product.name}'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => notifier.add(item.product),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(cartProvider);
    final saved = ref.watch(savedForLaterProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    final discount = ref.watch(cartDiscountProvider);
    final total = ref.watch(cartTotalProvider);
    final shipping = subtotal >= 250000 ? 0.0 : 20000.0;
    final appliedPromos = ref.watch(appliedPromosProvider);
    final availablePromos = ref.watch(availablePromosProvider);
    final recommended = ref.watch(homeDataProvider).bestSeller.take(6).toList();
    final warehouseStock = _warehouseStockMap(items.map((e) => e.product.id).toList());
    final smartBundle = suggestBundle(items);
    final itemCount = items.fold<int>(0, (sum, item) => sum + item.quantity);
    final savedAnalytics = ref.watch(savedForLaterAnalyticsProvider);
    final savings = items.fold<double>(
      0,
      (sum, item) => sum + ((item.product.price - item.product.discountPrice).clamp(0, item.product.price) * item.quantity),
    );
    const giftThreshold = 350000.0;
    final giftRemaining = (giftThreshold - subtotal).clamp(0, giftThreshold);
    final giftUnlocked = subtotal >= giftThreshold;
    final bestPromo = _pickBestPromo(
      subtotal: subtotal,
      rules: availablePromos,
      applied: appliedPromos,
    );

    if (!_autoApplied && items.isNotEmpty && appliedPromos.isEmpty && bestPromo != null) {
      _autoApplied = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final message = ref.read(appliedPromosProvider.notifier).apply(
              code: bestPromo.code,
              subtotal: subtotal,
              rules: availablePromos,
            );
        if (message.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Auto applied ${bestPromo.code}')),
          );
        }
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: items.isEmpty && saved.isEmpty
          ? const EmptyState(
              icon: Icons.shopping_bag_outlined,
              title: 'Cart is empty',
              message: 'Add items to your cart to continue checkout.',
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (items.isNotEmpty) ...[
                  const Text('In Cart', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          await ref.read(cartProvider.notifier).saveSnapshot();
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Cart snapshot saved')),
                          );
                        },
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Save cart'),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () async {
                          await ref.read(cartProvider.notifier).restoreSnapshot();
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Cart snapshot restored')),
                          );
                        },
                        icon: const Icon(Icons.restore),
                        label: const Text('Restore cart'),
                      ),
                    ],
                  ),
                  ...items.map(
                    (item) => Card(
                      child: ListTile(
                        leading: Image.network(item.product.image, width: 56, height: 56, fit: BoxFit.cover),
                        title: Text(item.product.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PriceWidget(price: item.product.discountPrice),
                            if (item.note.isNotEmpty)
                              Text('Note: ${item.note}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            if (warehouseStock[item.product.id] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Wrap(
                                  spacing: 6,
                                  children: warehouseStock[item.product.id]!
                                      .map(
                                        (w) => Chip(
                                          label: Text(w, style: const TextStyle(fontSize: 11)),
                                          backgroundColor: Colors.blueGrey.withAlpha(20),
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                _estimateShipping(item.product.id),
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () => ref.read(cartProvider.notifier).updateQty(item.product, item.quantity - 1),
                              onLongPress: () => ref
                                  .read(cartProvider.notifier)
                                  .updateQty(item.product, item.quantity - 3),
                            ),
                            Text('${item.quantity}'),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => ref.read(cartProvider.notifier).updateQty(item.product, item.quantity + 1),
                              onLongPress: () => ref
                                  .read(cartProvider.notifier)
                                  .updateQty(item.product, item.quantity + 3),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'note') {
                                  _editNote(item);
                                } else if (value == 'save') {
                                  ref.read(cartProvider.notifier).remove(item.product);
                                  ref.read(savedForLaterProvider.notifier).add(item);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Saved for later')),
                                  );
                                } else if (value == 'remove') {
                                  _removeWithUndo(item);
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(value: 'note', child: Text('Add note')),
                                PopupMenuItem(value: 'save', child: Text('Save for later')),
                                PopupMenuItem(value: 'remove', child: Text('Remove')),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                if (saved.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Saved for later', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    'Moved ${savedAnalytics.moveCount} times'
                    '${savedAnalytics.lastMovedAt == null ? '' : ' • last ${_formatDate(savedAnalytics.lastMovedAt!)}'}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  ...saved.map(
                    (item) => Card(
                      child: ListTile(
                        leading: Image.network(item.product.image, width: 56, height: 56, fit: BoxFit.cover),
                        title: Text(item.product.name),
                        subtitle: PriceWidget(price: item.product.discountPrice),
                        trailing: TextButton(
                          onPressed: () {
                            ref.read(savedForLaterProvider.notifier).remove(item);
                            ref.read(cartProvider.notifier).add(item.product);
                          },
                          child: const Text('Move to cart'),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.card_giftcard),
                    title: Text(giftUnlocked ? 'Free gift unlocked' : 'Free gift progress'),
                    subtitle: giftUnlocked
                        ? const Text('You can claim a mini travel kit')
                        : Text('Spend Rp ${giftRemaining.toStringAsFixed(0)} more to unlock'),
                    trailing: giftUnlocked
                        ? ElevatedButton(
                            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Free gift claimed (dummy)')),
                            ),
                            child: const Text('Claim'),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Promotions', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => context.go('/coupons'),
                    icon: const Icon(Icons.confirmation_number_outlined),
                    label: const Text('Open Coupons Center'),
                  ),
                ),
                if (smartBundle != null) ...[
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.all_inbox_outlined),
                      title: Text('Bundle: ${smartBundle.name}'),
                      subtitle: Text('Save ${smartBundle.discountPct}% when bought together'),
                      trailing: ElevatedButton(
                        onPressed: () {
                          final promoRules = [
                            ...availablePromos,
                            PromoRule(
                              code: smartBundle.code,
                              discountPct: smartBundle.discountPct / 100,
                              minSubtotal: 0,
                              stackable: true,
                            ),
                          ];
                          final message = ref.read(appliedPromosProvider.notifier).apply(
                                code: smartBundle.code,
                                subtotal: subtotal,
                                rules: promoRules,
                              );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(message.isEmpty ? '${smartBundle.code} applied' : message),
                            ),
                          );
                        },
                        child: const Text('Apply'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (bestPromo != null) ...[
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.auto_awesome),
                      title: Text('Best promo: ${bestPromo.code}'),
                      subtitle: Text(
                        'Save Rp ${(subtotal * bestPromo.discountPct).toStringAsFixed(0)}',
                      ),
                      trailing: TextButton(
                        onPressed: () {
                          final message = ref.read(appliedPromosProvider.notifier).apply(
                                code: bestPromo.code,
                                subtotal: subtotal,
                                rules: availablePromos,
                              );
                          if (message.isNotEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${bestPromo.code} applied')),
                            );
                          }
                        },
                        child: const Text('Apply'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Wrap(
                  spacing: 8,
                  children: availablePromos
                      .map(
                        (p) => ActionChip(
                          label: Text('${p.code} - ${(p.discountPct * 100).toInt()}%'),
                          onPressed: () {
                            _promoController.text = p.code;
                            _applyPromo();
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _promoController,
                  decoration: InputDecoration(
                    hintText: 'Promo code',
                    suffixIcon: TextButton(
                      onPressed: _applyPromo,
                      child: const Text('Apply'),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _openVoucherScan(context),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan voucher'),
                ),
                if (appliedPromos.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Applied Promos', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  ...appliedPromos.map(
                    (p) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(p.code),
                      subtitle: Text('${(p.discountPct * 100).toInt()}% off'),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => ref.read(appliedPromosProvider.notifier).remove(p.code),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (recommended.isNotEmpty) ...[
                  const Text('Recommended add-ons', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: recommended.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final product = recommended[index];
                        return Container(
                          width: 180,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(product.image, width: 56, height: 56, fit: BoxFit.cover),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    PriceWidget(price: product.discountPrice),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () {
                                  ref.read(cartProvider.notifier).add(product);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Added to cart')),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal'),
                    PriceWidget(price: subtotal),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Shipping'),
                    Text(shipping == 0 ? 'Free' : 'Rp ${shipping.toStringAsFixed(0)}'),
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
                if (savings > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('You save'),
                      Text('Rp ${savings.toStringAsFixed(0)}'),
                    ],
                  ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total', style: TextStyle(fontWeight: FontWeight.w700)),
                    Row(
                      children: [
                        PriceWidget(price: total),
                        IconButton(
                          icon: const Icon(Icons.info_outline, size: 18),
                          onPressed: () => _showBreakdown(context, items, appliedPromos, subtotal, discount),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tip: compare prices before checkout',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)]),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$itemCount items', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  PriceWidget(price: total),
                  if (appliedPromos.isEmpty)
                    const Text(
                      'Use a promo to save more',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
            ),
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

Map<int, List<String>> _warehouseStockMap(List<int> productIds) {
  final map = <int, List<String>>{};
  for (final id in productIds) {
    if (id % 3 == 0) {
      map[id] = const ['Jakarta: Low', 'Bandung: In stock'];
    } else if (id % 2 == 0) {
      map[id] = const ['Jakarta: In stock', 'Surabaya: In stock'];
    } else {
      map[id] = const ['Jakarta: In stock'];
    }
  }
  return map;
}

PromoRule? _pickBestPromo({
  required double subtotal,
  required List<PromoRule> rules,
  required List<AppliedPromo> applied,
}) {
  if (subtotal <= 0) return null;
  final candidates = rules.where((r) => subtotal >= r.minSubtotal).toList();
  if (candidates.isEmpty) return null;
  candidates.sort(
    (a, b) => (subtotal * b.discountPct).compareTo(subtotal * a.discountPct),
  );
  final best = candidates.first;
  if (applied.any((p) => p.code == best.code)) return null;
  if (!best.stackable && applied.isNotEmpty) return null;
  if (applied.any((p) => p.stackable == false)) return null;
  if (applied.length >= 2) return null;
  return best;
}

void _showBreakdown(
  BuildContext context,
  List<CartItem> items,
  List<AppliedPromo> promos,
  double subtotal,
  double discount,
) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Price breakdown'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            ...items.map(
              (item) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(item.product.name),
                trailing: Text('Rp ${(item.product.discountPrice * item.quantity).toStringAsFixed(0)}'),
              ),
            ),
            const Divider(),
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('Subtotal'),
              trailing: Text('Rp ${subtotal.toStringAsFixed(0)}'),
            ),
            if (promos.isNotEmpty) ...[
              const SizedBox(height: 6),
              const Text('Promos', style: TextStyle(fontWeight: FontWeight.w700)),
              ...promos.map(
                (p) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(p.code),
                  trailing: Text('- ${(p.discountPct * 100).toInt()}%'),
                ),
              ),
            ],
            if (discount > 0)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text('Discount'),
                trailing: Text('- Rp ${discount.toStringAsFixed(0)}'),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    ),
  );
}

String _estimateShipping(int productId) {
  if (productId % 3 == 0) return 'ETA 2-3 days · multi-warehouse';
  if (productId % 2 == 0) return 'ETA 1-2 days';
  return 'ETA 3-4 days';
}

String _formatDate(DateTime date) {
  return DateFormat('dd MMM, HH:mm').format(date);
}
