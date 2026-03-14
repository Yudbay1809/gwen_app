import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/price_widget.dart';
import '../../../shared/widgets/motion.dart';
import 'cart_providers.dart';
import 'checkout_providers.dart';
import 'order_success_screen.dart';

enum _PayGroup { wallet, va, card, cod }

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  _PayGroup _group = _PayGroup.wallet;
  String _method = 'GoPay';
  final _promoController = TextEditingController();

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final subtotal = ref.watch(cartSubtotalProvider);
    final discount = ref.watch(cartDiscountProvider);
    final total = ref.watch(cartTotalProvider);
    final addresses = ref.watch(addressesProvider);
    final selectedAddress = ref.watch(selectedAddressProvider);
    final selected = addresses.firstWhere(
      (a) => a.id == selectedAddress,
      orElse: () => addresses.first,
    );
    final items = ref.watch(cartProvider);
    final itemCount = ref.watch(cartItemCountProvider);
    final itemLines = items
        .map((e) => '${e.product.name} x${e.quantity}')
        .toList(growable: false);
    final fee = _estimateFee(_method);
    final grandTotal = (total - discount) + fee;

    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          MotionFadeSlide(
            beginOffset: const Offset(0, 0.08),
            child: _PaymentHeroSummary(
              itemCount: itemCount,
              total: grandTotal,
              addressLabel: '${selected.label} • ${selected.detail}',
            ),
          ),
          const SizedBox(height: 16),
          _PaymentSection(
            title: 'Order summary',
            subtitle: 'Double-check your payment and delivery totals.',
            icon: Icons.receipt_long_outlined,
            child: _SummaryCard(
              subtotal: subtotal,
              discount: discount,
              fee: fee,
              total: grandTotal,
            ),
          ),
          const SizedBox(height: 16),
          _PaymentSection(
            title: 'Payment methods',
            subtitle: 'Select your preferred payment method to continue.',
            icon: Icons.account_balance_wallet_outlined,
            child: Column(
              children: [
                _MethodGroup(
                  title: 'E-Wallet',
                  selected: _group == _PayGroup.wallet,
                  children: [
                    _MethodTile(
                      label: 'GoPay',
                      leading: _logoAsset('assets/logos/gopay.svg', label: 'GoPay'),
                      selected: _method == 'GoPay',
                      onTap: () => setState(() {
                        _group = _PayGroup.wallet;
                        _method = 'GoPay';
                      }),
                    ),
                    _MethodTile(
                      label: 'OVO',
                      leading: _logoBadge('OVO', const Color(0xFF5A2D82)),
                      selected: _method == 'OVO',
                      onTap: () => setState(() {
                        _group = _PayGroup.wallet;
                        _method = 'OVO';
                      }),
                    ),
                    _MethodTile(
                      label: 'DANA',
                      leading: _logoBadge('DANA', const Color(0xFF108EE9)),
                      selected: _method == 'DANA',
                      onTap: () => setState(() {
                        _group = _PayGroup.wallet;
                        _method = 'DANA';
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _MethodGroup(
                  title: 'Virtual Account',
                  selected: _group == _PayGroup.va,
                  children: [
                    _MethodTile(
                      label: 'BCA VA',
                      leading: _logoAsset('assets/logos/bca.svg', label: 'BCA'),
                      selected: _method == 'BCA VA',
                      onTap: () => setState(() {
                        _group = _PayGroup.va;
                        _method = 'BCA VA';
                      }),
                    ),
                    _MethodTile(
                      label: 'Mandiri VA',
                      leading: _logoAsset('assets/logos/mandiri.svg', label: 'Mandiri'),
                      selected: _method == 'Mandiri VA',
                      onTap: () => setState(() {
                        _group = _PayGroup.va;
                        _method = 'Mandiri VA';
                      }),
                    ),
                    _MethodTile(
                      label: 'BNI VA',
                      leading: _logoAsset('assets/logos/bni.svg', label: 'BNI'),
                      selected: _method == 'BNI VA',
                      onTap: () => setState(() {
                        _group = _PayGroup.va;
                        _method = 'BNI VA';
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _MethodGroup(
                  title: 'Card',
                  selected: _group == _PayGroup.card,
                  children: [
                    _MethodTile(
                      label: 'Credit / Debit',
                      leading: _cardLogos(),
                      selected: _method == 'Card',
                      onTap: () => setState(() {
                        _group = _PayGroup.card;
                        _method = 'Card';
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _MethodGroup(
                  title: 'COD',
                  selected: _group == _PayGroup.cod,
                  children: [
                    _MethodTile(
                      label: 'Cash on Delivery',
                      leading: _logoBadge('COD', const Color(0xFF8D6E63)),
                      selected: _method == 'COD',
                      onTap: () => setState(() {
                        _group = _PayGroup.cod;
                        _method = 'COD';
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _MethodDetail(method: _method, group: _group),
          const SizedBox(height: 16),
          _PaymentSection(
            title: 'Promo',
            subtitle: 'Apply additional savings before you pay.',
            icon: Icons.local_offer_outlined,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promoController,
                    decoration: _inputDecoration(context, 'Enter promo code'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Apply'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: MotionFadeSlide(
          beginOffset: const Offset(0, 0.2),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.45)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Grand total',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      PriceWidget(price: grandTotal),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => context.go(
                    '/order-success',
                    extra: OrderSuccessArgs(
                      total: grandTotal,
                      itemCount: itemCount,
                      addressLabel: '${selected.label} • ${selected.detail}',
                      paymentMethod: _method,
                      itemLines: itemLines,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(120, 48),
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Pay Now', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

double _estimateFee(String method) {
  if (method.contains('VA')) return 2500;
  if (method == 'COD') return 8000;
  return 0;
}

class _PaymentHeroSummary extends StatelessWidget {
  final int itemCount;
  final double total;
  final String addressLabel;

  const _PaymentHeroSummary({
    required this.itemCount,
    required this.total,
    required this.addressLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primaryContainer.withValues(alpha: 0.92),
            scheme.surfaceContainerHighest,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ready to pay',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            '$itemCount items • $addressLabel',
            style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Total',
                style: theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(width: 8),
              PriceWidget(price: total),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  const _PaymentSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double subtotal;
  final double discount;
  final double fee;
  final double total;

  const _SummaryCard({
    required this.subtotal,
    required this.discount,
    required this.fee,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _row('Subtotal', subtotal, scheme.onSurfaceVariant),
          _row('Discount', -discount, scheme.onSurfaceVariant),
          _row('Payment fee', fee, scheme.onSurfaceVariant),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontWeight: FontWeight.w700)),
              PriceWidget(price: total),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: color)),
          Text('Rp ${value.toStringAsFixed(0)}'),
        ],
      ),
    );
  }
}

class _MethodGroup extends StatelessWidget {
  final String title;
  final bool selected;
  final List<Widget> children;

  const _MethodGroup({required this.title, required this.selected, required this.children});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: selected ? scheme.primaryContainer.withValues(alpha: 0.28) : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected
              ? scheme.primary.withValues(alpha: 0.7)
              : scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? scheme.primary : scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;

  const _MethodTile({
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer.withValues(alpha: 0.45) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _logoBadge(String text, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: color.withAlpha(20),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withAlpha(80)),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w700,
        color: color,
        fontSize: 12,
        letterSpacing: 0.2,
      ),
    ),
  );
}

Widget _logoAsset(String asset, {required String label}) {
  return SizedBox(
    width: 56,
    height: 24,
    child: SvgPicture.asset(
      asset,
      fit: BoxFit.contain,
      semanticsLabel: label,
    ),
  );
}

Widget _cardLogos() {
  return SizedBox(
    width: 64,
    height: 24,
    child: Row(
      children: [
        Expanded(child: SvgPicture.asset('assets/logos/visa.svg', fit: BoxFit.contain)),
        const SizedBox(width: 4),
        Expanded(child: SvgPicture.asset('assets/logos/mastercard.svg', fit: BoxFit.contain)),
      ],
    ),
  );
}

class _MethodDetail extends StatelessWidget {
  final String method;
  final _PayGroup group;

  const _MethodDetail({required this.method, required this.group});

  @override
  Widget build(BuildContext context) {
    if (group == _PayGroup.va) {
      return _DetailCard(
        title: 'Virtual Account',
        content: Row(
          children: [
            const Expanded(child: Text('1234 5678 9012 3456')),
            IconButton(
              onPressed: () {
                Clipboard.setData(const ClipboardData(text: '1234567890123456'));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('VA copied')),
                );
              },
              icon: const Icon(Icons.copy),
            ),
          ],
        ),
      );
    }
    if (group == _PayGroup.card) {
      return _DetailCard(
        title: 'Card Details',
        content: Column(
          children: [
            TextField(decoration: _inputDecoration(context, 'Card number')),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: TextField(decoration: _inputDecoration(context, 'MM/YY'))),
                const SizedBox(width: 8),
                Expanded(child: TextField(decoration: _inputDecoration(context, 'CVV'))),
              ],
            ),
          ],
        ),
      );
    }
    if (group == _PayGroup.cod) {
      return const _DetailCard(
        title: 'Cash on Delivery',
        content: Text('Pay when your order arrives.'),
      );
    }
    return _DetailCard(
      title: method,
      content: const Text('You will be redirected to complete payment.'),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String title;
  final Widget content;

  const _DetailCard({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          content,
        ],
      ),
    );
  }
}

InputDecoration _inputDecoration(BuildContext context, String hint) {
  final scheme = Theme.of(context).colorScheme;
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: scheme.surfaceContainerLow,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: scheme.outlineVariant),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: scheme.outlineVariant),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: scheme.primary),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );
}

