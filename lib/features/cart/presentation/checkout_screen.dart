import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/models/cart_item.dart';
import '../../../shared/widgets/price_widget.dart';
import '../../../shared/widgets/motion.dart';
import 'cart_providers.dart';
import 'checkout_providers.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  late final TextEditingController _noteController;
  late final TextEditingController _promoController;
  late final TextEditingController _recipientNoteController;
  String? _promoMessage;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: ref.read(deliveryNoteProvider));
    _promoController = TextEditingController();
    final selectedAddress = ref.read(selectedAddressProvider);
    final notes = ref.read(addressNotesProvider);
    _recipientNoteController = TextEditingController(text: notes[selectedAddress] ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    _promoController.dispose();
    _recipientNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final subtotal = ref.watch(cartSubtotalProvider);
    final discount = ref.watch(cartDiscountProvider);
    final total = ref.watch(cartTotalProvider);
    final cartItems = ref.watch(cartProvider);
    final appliedPromos = ref.watch(appliedPromosProvider);
    final promoRules = ref.watch(availablePromosProvider);
    final addresses = ref.watch(addressesProvider);
    final payments = ref.watch(paymentMethodsProvider);
    final slotsByAddress = ref.watch(deliverySlotsByAddressProvider);
    final selectedAddress = ref.watch(selectedAddressProvider);
    final selectedPayment = ref.watch(selectedPaymentProvider);
    final selectedSlots = ref.watch(selectedDeliverySlotProvider);
    final slots = slotsByAddress[selectedAddress] ?? const <String>[];
    final selectedSlot = selectedSlots[selectedAddress] ?? (slots.isNotEmpty ? slots.first : '');
    final notePreview = ref.watch(deliveryNoteProvider);
    final addressNotes = ref.watch(addressNotesProvider);
    final hasPayment = payments.any((p) => p.id == selectedPayment);
    final address = addresses.firstWhere((a) => a.id == selectedAddress);
    final addressWarning = _validateAddress(address);

    final fee = _estimateDeliveryFee(selectedAddress, selectedSlot);
    final deliveryFee = fee.total;
    final grandTotal = total + deliveryFee;
    final itemCount = cartItems.fold<int>(0, (sum, item) => sum + item.quantity);
    final bestPromo = _pickBestPromoCheckout(
      subtotal: subtotal,
      rules: promoRules,
      applied: appliedPromos,
    );

    final recipientNote = addressNotes[selectedAddress] ?? '';
    if (_recipientNoteController.text != recipientNote) {
      _recipientNoteController.value = TextEditingValue(
        text: recipientNote,
        selection: TextSelection.collapsed(offset: recipientNote.length),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        actions: [
          TextButton(
            onPressed: () => _showReceiptPreview(
              context,
              subtotal,
              discount,
              total,
              appliedPromos,
              fee,
            ),
            child: const Text('Receipt'),
          ),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (cartItems.isNotEmpty) ...[
                  MotionFadeSlide(
                    delay: const Duration(milliseconds: 120),
                    beginOffset: const Offset(0, 0.08),
                    child: _MiniItemsStrip(items: cartItems, totalItems: itemCount),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Grand total',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          PriceWidget(price: grandTotal),
                        ],
                      ),
                    ),
                    if (selectedSlot.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _estimateEta(selectedSlot),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
              ElevatedButton(
                onPressed: () {
                  if (addressWarning != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(addressWarning)),
                    );
                    return;
                  }
                  if (selectedSlot.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Select a delivery slot')),
                    );
                    return;
                  }
                  if (!hasPayment) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Select a payment method')),
                    );
                    return;
                    }
                    context.go('/payment');
                  },
                  child: const Text('Continue to Payment'),
                ),
              ],
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const _CheckoutSteps(currentStep: 2),
          const SizedBox(height: 16),
          MotionFadeSlide(
            beginOffset: const Offset(0, 0.08),
            child: _CheckoutHeroSummary(
              subtotal: subtotal,
              total: grandTotal,
              appliedPromos: appliedPromos.length,
              addressLabel: address.label,
            ),
          ),
          const SizedBox(height: 16),
          _CheckoutSection(
            title: 'Promo code',
            subtitle: bestPromo == null
                ? 'Apply vouchers or beauty promos before paying.'
                : 'Best available: ${bestPromo.code} • ${(bestPromo.discountPct * 100).toInt()}% off',
            icon: Icons.local_offer_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _promoController,
                  decoration: const InputDecoration(
                    hintText: 'Enter promo code',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: bestPromo == null
                            ? null
                            : () {
                                final message = ref.read(appliedPromosProvider.notifier).apply(
                                      code: bestPromo.code,
                                      subtotal: subtotal,
                                      rules: promoRules,
                                    );
                                setState(() => _promoMessage = message.isEmpty ? 'Promo applied' : message);
                              },
                        child: const Text('Use best promo'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final code = _promoController.text.trim();
                          if (code.isEmpty) {
                            setState(() => _promoMessage = 'Please enter a promo code.');
                            return;
                          }
                          final message = ref.read(appliedPromosProvider.notifier).apply(
                                code: code,
                                subtotal: subtotal,
                                rules: promoRules,
                              );
                          setState(() => _promoMessage = message.isEmpty ? 'Promo applied' : message);
                          if (message.isEmpty) {
                            _promoController.clear();
                          }
                        },
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                ),
                if (_promoMessage != null) ...[
                  const SizedBox(height: 10),
                  _InfoBanner(
                    icon: _promoMessage == 'Promo applied'
                        ? Icons.check_circle_outline
                        : Icons.info_outline,
                    tone: _promoMessage == 'Promo applied' ? _BannerTone.success : _BannerTone.info,
                    message: _promoMessage!,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _CheckoutSection(
            title: 'Shipping address',
            subtitle: 'Choose where your beauty order should be delivered.',
            icon: Icons.location_on_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (addressWarning != null) ...[
                  _InfoBanner(
                    icon: Icons.warning_amber_rounded,
                    tone: _BannerTone.warning,
                    message: addressWarning,
                  ),
                  const SizedBox(height: 10),
                ],
                RadioGroup<int>(
                  groupValue: selectedAddress,
                  onChanged: (v) {
                    final next = v ?? selectedAddress;
                    ref.read(selectedAddressProvider.notifier).select(next);
                    final nextSlots = slotsByAddress[next] ?? const <String>[];
                    if (nextSlots.isNotEmpty && !nextSlots.contains(selectedSlot)) {
                      ref.read(selectedDeliverySlotProvider.notifier).reset(next, nextSlots.first);
                    }
                  },
                  child: Column(
                    children: addresses
                        .map(
                          (a) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ChoiceCard(
                              selected: a.id == selectedAddress,
                              child: RadioListTile<int>(
                                value: a.id,
                                title: Text('${a.label} • ${a.name}'),
                                subtitle: Text('${a.detail}\n${_formatPhone(a.phone)}'),
                                isThreeLine: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Add address (dummy)')),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Add new address'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _CheckoutSection(
            title: 'Payment method',
            subtitle: 'Pick how you want to pay for this order.',
            icon: Icons.account_balance_wallet_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!hasPayment) ...[
                  const _InfoBanner(
                    icon: Icons.warning_amber_rounded,
                    tone: _BannerTone.warning,
                    message: 'Please select a payment method',
                  ),
                  const SizedBox(height: 10),
                ],
                RadioGroup<int>(
                  groupValue: selectedPayment,
                  onChanged: (v) => ref.read(selectedPaymentProvider.notifier).select(v ?? selectedPayment),
                  child: Column(
                    children: payments
                        .map(
                          (p) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ChoiceCard(
                              selected: p.id == selectedPayment,
                              child: RadioListTile<int>(
                                value: p.id,
                                title: Text(p.name),
                                subtitle: Text(p.detail),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          if (bestPromo != null) ...[
            const SizedBox(height: 16),
            _CheckoutSection(
              title: 'Recommended promo',
              subtitle: 'This saves the most based on your current cart.',
              icon: Icons.auto_awesome,
              child: _RecommendedPromoCard(
                promo: bestPromo,
                onApply: () {
                  final message = ref.read(appliedPromosProvider.notifier).apply(
                        code: bestPromo.code,
                        subtotal: subtotal,
                        rules: promoRules,
                      );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(message.isEmpty ? 'Promo applied' : message)),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 16),
          _CheckoutSection(
            title: 'Delivery details',
            subtitle: 'Leave notes and choose the most convenient delivery slot.',
            icon: Icons.local_shipping_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  maxLines: 2,
                  controller: _noteController,
                  onChanged: (v) => ref.read(deliveryNoteProvider.notifier).setNote(v),
                  decoration: const InputDecoration(
                    hintText: 'e.g., call me when arrive, leave at lobby',
                    border: OutlineInputBorder(),
                    labelText: 'Delivery notes',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  maxLines: 2,
                  controller: _recipientNoteController,
                  onChanged: (v) => ref.read(addressNotesProvider.notifier).setNote(selectedAddress, v),
                  decoration: const InputDecoration(
                    hintText: 'e.g., leave with security',
                    border: OutlineInputBorder(),
                    labelText: 'Recipient note',
                  ),
                ),
                if (notePreview.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _InfoBanner(
                    icon: Icons.sticky_note_2_outlined,
                    tone: _BannerTone.info,
                    message: notePreview,
                  ),
                ],
                const SizedBox(height: 14),
                Text(
                  'Delivery slot',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                if (slots.isEmpty)
                  Text(
                    'No slots available',
                    style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: slots
                        .map(
                          (s) => ChoiceChip(
                            label: Text(s),
                            selected: selectedSlot == s,
                            onSelected: (_) => ref
                                .read(selectedDeliverySlotProvider.notifier)
                                .select(selectedAddress, s),
                          ),
                        )
                        .toList(),
                  ),
                if (slots.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Estimated arrival: ${_estimateEta(selectedSlot)}',
                    style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _CheckoutSection(
            title: 'Order summary',
            subtitle: 'Review everything before we take you to payment.',
            icon: Icons.receipt_long_outlined,
            child: Column(
              children: [
                _SummaryRow(label: 'Subtotal', trailing: PriceWidget(price: subtotal)),
                if (discount > 0)
                  _SummaryRow(
                    label: 'Discount',
                    trailing: Text('- Rp ${discount.toStringAsFixed(0)}'),
                  ),
                _SummaryRow(
                  label: 'Delivery fee',
                  trailing: Text('Rp ${deliveryFee.toStringAsFixed(0)}'),
                ),
                _SummaryRow(
                  label: 'Base',
                  muted: true,
                  trailing: Text('Rp ${fee.base.toStringAsFixed(0)}'),
                ),
                _SummaryRow(
                  label: 'Distance',
                  muted: true,
                  trailing: Text('Rp ${fee.distance.toStringAsFixed(0)}'),
                ),
                if (fee.slot > 0)
                  _SummaryRow(
                    label: 'Slot',
                    muted: true,
                    trailing: Text('Rp ${fee.slot.toStringAsFixed(0)}'),
                  ),
                if (appliedPromos.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Promo breakdown',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...appliedPromos.map(
                    (p) => _SummaryRow(
                      label: p.code,
                      trailing: Text('- Rp ${(subtotal * p.discountPct).toStringAsFixed(0)}'),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                const Divider(),
                const SizedBox(height: 10),
                _SummaryRow(
                  label: 'Total',
                  emphasized: true,
                  trailing: PriceWidget(price: grandTotal),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _showReceiptPreview(
              context,
              subtotal,
              discount,
              total,
              appliedPromos,
              fee,
            ),
            icon: const Icon(Icons.receipt_long),
            label: const Text('Preview receipt'),
          ),
        ],
      ),
    );
  }
}

String? _validateAddress(AddressItem address) {
  if (address.detail.trim().length < 8) return 'Address detail looks too short.';
  if (address.phone.trim().length < 8) return 'Please add a valid phone number.';
  return null;
}

PromoRule? _pickBestPromoCheckout({
  required double subtotal,
  required List<PromoRule> rules,
  required List<AppliedPromo> applied,
}) {
  if (rules.isEmpty) return null;
  final appliedCodes = applied.map((e) => e.code).toSet();
  final candidates = rules.where((r) => subtotal >= r.minSubtotal && !appliedCodes.contains(r.code)).toList();
  if (candidates.isEmpty) return null;
  candidates.sort((a, b) => b.discountPct.compareTo(a.discountPct));
  return candidates.first;
}
void _showReceiptPreview(
  BuildContext context,
  double subtotal,
  double discount,
  double total,
  List<AppliedPromo> promos,
  DeliveryFeeBreakdown fee,
) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Receipt Preview'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal'),
              Text('Rp ${subtotal.toStringAsFixed(0)}'),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Delivery fee'),
              Text('Rp ${fee.total.toStringAsFixed(0)}'),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('  Base'),
              Text('Rp ${fee.base.toStringAsFixed(0)}'),
            ],
          ),
          if (promos.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Promos', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            ...promos.map(
              (p) => Align(
                alignment: Alignment.centerLeft,
                child: Text('${p.code} ${(p.discountPct * 100).toInt()}%'),
              ),
            ),
          ],
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontWeight: FontWeight.w700)),
              Text(
                'Rp ${(total + fee.total).toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    ),
  );
}

class DeliveryFeeBreakdown {
  final double base;
  final double distance;
  final double slot;

  const DeliveryFeeBreakdown({required this.base, required this.distance, required this.slot});

  double get total => base + distance + slot;
}

DeliveryFeeBreakdown _estimateDeliveryFee(int addressId, String slot) {
  final base = 12000.0;
  final distance = addressId == 1 ? 3000.0 : addressId == 2 ? 6000.0 : 8000.0;
  var slotFee = 0.0;
  final s = slot.toLowerCase();
  if (s.contains('evening') || s.contains('night')) slotFee = 5000.0;
  if (s.contains('same') || s.contains('express')) slotFee = 7000.0;
  return DeliveryFeeBreakdown(base: base, distance: distance, slot: slotFee);
}

String _estimateEta(String slot) {
  final s = slot.toLowerCase();
  if (s.contains('same') || s.contains('express')) return 'Today • 2-3 hours';
  if (s.contains('evening') || s.contains('night')) return 'Today • 18:00-21:00';
  if (s.contains('morning')) return 'Tomorrow • 09:00-12:00';
  return 'Tomorrow • 10:00-17:00';
}

String _formatPhone(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 8) return phone;
  if (digits.startsWith('62')) {
    final rest = digits.substring(2);
    return '+62 ${_groupPhone(rest)}';
  }
  if (digits.startsWith('0')) {
    final rest = digits.substring(1);
    return '+62 ${_groupPhone(rest)}';
  }
  return phone;
}

String _groupPhone(String digits) {
  if (digits.length <= 4) return digits;
  if (digits.length <= 8) {
    return '${digits.substring(0, 4)} ${digits.substring(4)}';
  }
  return '${digits.substring(0, 4)} ${digits.substring(4, 8)} ${digits.substring(8)}';
}

class _CheckoutSteps extends StatelessWidget {
  final int currentStep;

  const _CheckoutSteps({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    const labels = ['Cart', 'Address', 'Payment', 'Success'];
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: List.generate(labels.length, (i) {
        final active = i <= currentStep - 1;
        return Expanded(
          child: Column(
            children: [
              Container(
                height: 6,
                margin: EdgeInsets.only(right: i == labels.length - 1 ? 0 : 6),
                decoration: BoxDecoration(
                  color: active ? scheme.primary : scheme.outline.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                labels[i],
                style: TextStyle(
                  fontSize: 11,
                  color: active ? scheme.primary : scheme.onSurfaceVariant,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
class _CheckoutHeroSummary extends StatelessWidget {
  final double subtotal;
  final double total;
  final int appliedPromos;
  final String addressLabel;

  const _CheckoutHeroSummary({
    required this.subtotal,
    required this.total,
    required this.appliedPromos,
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
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Almost done',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Review shipping, payment, and promo details before placing your order.',
            style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: 'Subtotal',
                  value: 'Rp ${subtotal.toStringAsFixed(0)}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroMetric(
                  label: 'Promos',
                  value: '$appliedPromos applied',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Delivering to $addressLabel',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              PriceWidget(price: total),
            ],
          ),
        ],
      ),
    );
  }
}

class _CheckoutSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  const _CheckoutSection({
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

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String message;
  final _BannerTone tone;

  const _InfoBanner({
    required this.icon,
    required this.message,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (tone) {
      _BannerTone.warning => Colors.orange,
      _BannerTone.success => Colors.green,
      _BannerTone.info => scheme.primary,
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

enum _BannerTone { warning, success, info }
class _ChoiceCard extends StatelessWidget {
  final bool selected;
  final Widget child;

  const _ChoiceCard({
    required this.selected,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: selected ? scheme.primaryContainer.withValues(alpha: 0.42) : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected
              ? scheme.primary.withValues(alpha: 0.75)
              : scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: child,
    );
  }
}

class _RecommendedPromoCard extends StatelessWidget {
  final PromoRule promo;
  final VoidCallback onApply;

  const _RecommendedPromoCard({
    required this.promo,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.auto_awesome, color: scheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  promo.code,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  'Save ${(promo.discountPct * 100).toInt()}% when your subtotal reaches Rp ${promo.minSubtotal.toStringAsFixed(0)}',
                  style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onApply,
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}

class _MiniItemsStrip extends StatelessWidget {
  final List<CartItem> items;
  final int totalItems;

  const _MiniItemsStrip({
    required this.items,
    required this.totalItems,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final preview = items.take(4).toList(growable: false);
    final overflow = (totalItems - preview.length).clamp(0, totalItems);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36 + (preview.length * 18),
            height: 36,
            child: Stack(
              children: [
                for (var i = 0; i < preview.length; i++)
                  Positioned(
                    left: i * 18.0,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: scheme.surface, width: 2),
                        image: DecorationImage(
                          image: NetworkImage(preview[i].product.image),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                if (overflow > 0)
                  Positioned(
                    left: preview.length * 18.0,
                    child: Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scheme.primaryContainer,
                        border: Border.all(color: scheme.surface, width: 2),
                      ),
                      child: Text(
                        '+$overflow',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$totalItems items ready',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Swipe down for details',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final Widget trailing;
  final bool muted;
  final bool emphasized;

  const _SummaryRow({
    required this.label,
    required this.trailing,
    this.muted = false,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = emphasized
        ? scheme.onSurface
        : muted
            ? scheme.onSurfaceVariant
            : scheme.onSurface;
    final fontWeight = emphasized ? FontWeight.w800 : muted ? FontWeight.w500 : FontWeight.w600;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: color, fontWeight: fontWeight)),
          DefaultTextStyle.merge(
            style: TextStyle(color: color, fontWeight: fontWeight),
            child: trailing,
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;

  const _HeroMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

