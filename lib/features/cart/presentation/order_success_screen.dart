import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/price_widget.dart';
import '../../../shared/utils/receipt_exporter.dart';
import '../../../shared/widgets/motion.dart';

class OrderSuccessArgs {
  final double total;
  final int itemCount;
  final String addressLabel;
  final String paymentMethod;
  final List<String> itemLines;

  const OrderSuccessArgs({
    required this.total,
    required this.itemCount,
    required this.addressLabel,
    required this.paymentMethod,
    required this.itemLines,
  });
}

class OrderSuccessScreen extends StatefulWidget {
  final OrderSuccessArgs? args;

  const OrderSuccessScreen({super.key, required this.args});

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen> with SingleTickerProviderStateMixin {
  final GlobalKey _receiptKey = GlobalKey();
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  late final String _transactionId;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _transactionId = 'GW${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<Uint8List?> _capturePng() async {
    final boundary = _receiptKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  }

  Future<void> _saveReceipt() async {
    if (_busy) return;
    setState(() => _busy = true);
    final bytes = await _capturePng();
    if (bytes == null) {
      _showSnack('Receipt not ready');
      setState(() => _busy = false);
      return;
    }
    final path = await saveReceiptPng(bytes);
    _showSnack('Saved receipt: $path');
    setState(() => _busy = false);
    await _backHome();
  }

  Future<void> _shareReceipt() async {
    if (_busy) return;
    setState(() => _busy = true);
    final bytes = await _capturePng();
    if (bytes == null) {
      _showSnack('Receipt not ready');
      setState(() => _busy = false);
      return;
    }
    await shareReceiptPng(bytes, fileName: 'gwen-receipt');
    _showSnack('Sharing receipt...');
    setState(() => _busy = false);
    await _backHome();
  }

  Future<void> _backHome() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    context.go('/shop');
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.args;
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Success')),
      body: data == null
          ? const Center(child: Text('No order summary available'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _SuccessHero(
                  fade: _fade,
                  scale: _scale,
                  transactionId: _transactionId,
                  total: data.total,
                ),
                const SizedBox(height: 16),
                MotionFadeSlide(
                  delay: const Duration(milliseconds: 120),
                  beginOffset: const Offset(0, 0.08),
                  child: RepaintBoundary(
                    key: _receiptKey,
                    child: _ReceiptCard(
                      transactionId: _transactionId,
                      total: data.total,
                      itemCount: data.itemCount,
                      addressLabel: data.addressLabel,
                      paymentMethod: data.paymentMethod,
                      itemLines: data.itemLines,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                MotionFadeSlide(
                  delay: const Duration(milliseconds: 180),
                  beginOffset: const Offset(0, 0.06),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy ? null : _saveReceipt,
                          icon: const Icon(Icons.download),
                          label: const Text('Save Receipt'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _busy ? null : _shareReceipt,
                          icon: const Icon(Icons.send),
                          label: const Text('Send Proof'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                MotionFadeSlide(
                  delay: const Duration(milliseconds: 220),
                  beginOffset: const Offset(0, 0.04),
                  child: TextButton(
                    onPressed: _busy ? null : _backHome,
                    child: const Text('Continue shopping'),
                  ),
                ),
              ],
            ),
    );
  }
}

class _SuccessHero extends StatelessWidget {
  final Animation<double> fade;
  final Animation<double> scale;
  final String transactionId;
  final double total;

  const _SuccessHero({
    required this.fade,
    required this.scale,
    required this.transactionId,
    required this.total,
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
            scheme.primaryContainer.withValues(alpha: 0.9),
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
          Align(
            alignment: Alignment.center,
            child: FadeTransition(
              opacity: fade,
              child: ScaleTransition(
                scale: scale,
                child: MotionPulseGlow(
                  glowColor: scheme.primary,
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      shape: BoxShape.circle,
                      border: Border.all(color: scheme.primary.withValues(alpha: 0.35)),
                    ),
                    child: Icon(Icons.check_circle, color: scheme.primary, size: 64),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Payment Successful',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Your transaction is complete.',
              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Transaction ID', style: theme.textTheme.labelMedium),
              Text(
                transactionId,
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total paid', style: theme.textTheme.labelMedium),
              PriceWidget(price: total),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  final String transactionId;
  final double total;
  final int itemCount;
  final String addressLabel;
  final String paymentMethod;
  final List<String> itemLines;

  const _ReceiptCard({
    required this.transactionId,
    required this.total,
    required this.itemCount,
    required this.addressLabel,
    required this.paymentMethod,
    required this.itemLines,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('GWEN Beauty', style: TextStyle(fontWeight: FontWeight.w700, color: scheme.primary)),
          const SizedBox(height: 4),
          Text('Transaction ID: $transactionId', style: TextStyle(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontWeight: FontWeight.w700)),
              PriceWidget(price: total),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Items'),
              Text('$itemCount'),
            ],
          ),
          if (itemLines.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...itemLines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(line, style: const TextStyle(color: Colors.black54)),
              ),
            ),
          ],
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          const Text('Shipping', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(addressLabel),
          const SizedBox(height: 8),
          const Text('Payment', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(paymentMethod),
        ],
      ),
    );
  }
}
