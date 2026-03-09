import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/price_widget.dart';
import 'cart_providers.dart';
import 'checkout_providers.dart';
import 'order_success_screen.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: ref.read(deliveryNoteProvider));
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = ref.watch(cartSubtotalProvider);
    final discount = ref.watch(cartDiscountProvider);
    final total = ref.watch(cartTotalProvider);
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
    final bestPromo = _pickBestPromoCheckout(subtotal: subtotal, rules: promoRules, applied: appliedPromos);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Shipping Address', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (addressWarning != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(addressWarning)),
                  ],
                ),
              ),
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
                      (a) => Card(
                        child: RadioListTile<int>(
                          value: a.id,
                          title: Text('${a.label} • ${a.name}'),
                        subtitle: Text('${a.detail}\n${_formatPhone(a.phone)}'),
                          isThreeLine: true,
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
            const SizedBox(height: 12),
            const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (!hasPayment)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.warning_amber_rounded, size: 18),
                    SizedBox(width: 8),
                    Expanded(child: Text('Please select a payment method')),
                  ],
                ),
              ),
            RadioGroup<int>(
              groupValue: selectedPayment,
              onChanged: (v) => ref.read(selectedPaymentProvider.notifier).select(v ?? selectedPayment),
              child: Column(
                children: payments
                    .map(
                      (p) => Card(
                        child: RadioListTile<int>(
                          value: p.id,
                          title: Text(p.name),
                          subtitle: Text(p.detail),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            if (bestPromo != null) ...[
              const SizedBox(height: 12),
              const Text('Recommended Promo', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.auto_awesome),
                  title: Text(bestPromo.code),
                  subtitle: Text('Save ${(bestPromo.discountPct * 100).toInt()}%'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      final message = ref.read(appliedPromosProvider.notifier).apply(
                            code: bestPromo.code,
                            subtotal: subtotal,
                            rules: promoRules,
                          );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(message.isEmpty ? 'Promo applied' : message)),
                      );
                    },
                    child: const Text('Apply'),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Text('Delivery Notes', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'e.g., call me when arrive, leave at lobby',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => ref.read(deliveryNoteProvider.notifier).setNote(v),
              controller: _noteController,
            ),
            const SizedBox(height: 8),
            const Text('Recipient Note', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'e.g., leave with security',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => ref.read(addressNotesProvider.notifier).setNote(selectedAddress, v),
              controller: TextEditingController(text: addressNotes[selectedAddress] ?? ''),
            ),
            if (notePreview.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.sticky_note_2_outlined),
                  title: const Text('Notes preview'),
                  subtitle: Text(notePreview),
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Text('Delivery Slot', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (slots.isEmpty)
              const Text('No slots available', style: TextStyle(color: Colors.grey))
            else
              Wrap(
                spacing: 8,
                children: slots
                    .map(
                    (s) => ChoiceChip(
                      label: Text(s),
                      selected: selectedSlot == s,
                      onSelected: (_) =>
                          ref.read(selectedDeliverySlotProvider.notifier).select(selectedAddress, s),
                    ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 12),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Order Summary', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('Total Rp ${total.toStringAsFixed(0)}'),
              childrenPadding: const EdgeInsets.only(bottom: 8),
              children: [
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Delivery fee'),
                    Text('Rp ${deliveryFee.toStringAsFixed(0)}'),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('  Base'),
                    Text('Rp ${fee.base.toStringAsFixed(0)}', style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('  Distance'),
                    Text('Rp ${fee.distance.toStringAsFixed(0)}', style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                if (fee.slot > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('  Slot'),
                      Text('Rp ${fee.slot.toStringAsFixed(0)}', style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                if (appliedPromos.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('Promo Breakdown', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  ...appliedPromos.map(
                    (p) => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(p.code),
                        Text('- Rp ${(subtotal * p.discountPct).toStringAsFixed(0)}'),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total', style: TextStyle(fontWeight: FontWeight.w700)),
                    PriceWidget(price: total + deliveryFee),
                  ],
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (!hasPayment) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Select a payment method')),
                        );
                        return;
                      }
                  final itemCount = ref.read(cartProvider).fold<int>(0, (sum, item) => sum + item.quantity);
                  final address = addresses.firstWhere((a) => a.id == selectedAddress);
                  final payment = payments.firstWhere((p) => p.id == selectedPayment);
                  final args = OrderSuccessArgs(
                    total: total,
                    itemCount: itemCount,
                    addressLabel: '${address.label} - ${address.detail}',
                    paymentMethod: payment.name,
                  );
                  ref.read(cartProvider.notifier).clear();
                  ref.read(appliedPromosProvider.notifier).clear();
                  ref.read(deliveryNoteProvider.notifier).clear();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Order placed')),
                  );
                      context.go('/order-success', extra: args);
                    },
                    child: const Text('Place Order'),
                  ),
                ],
              ),
            ),
          ],
        ),
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
            ...promos.map((p) => Align(
                  alignment: Alignment.centerLeft,
                  child: Text('${p.code} ${(p.discountPct * 100).toInt()}%'),
                )),
          ],
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontWeight: FontWeight.w700)),
              Text('Rp ${(total + fee.total).toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
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
