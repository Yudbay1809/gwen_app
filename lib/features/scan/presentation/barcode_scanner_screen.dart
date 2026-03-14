import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import '../../home/presentation/home_providers.dart';

class BarcodeScannerScreen extends ConsumerStatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  ConsumerState<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends ConsumerState<BarcodeScannerScreen> with TickerProviderStateMixin {
  late final AnimationController _scanController;
  late final Animation<double> _scanPosition;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _scanPosition = CurvedAnimation(parent: _scanController, curve: Curves.easeInOutCubic);
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(homeDataProvider).allProducts;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Scan')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Scan for Pretty benefits',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Scan Barcode produk untuk review terlengkap atau\n'
                'Scan QR Code di GWEN Store untuk dapatkan\n'
                'rekomendasi & promo cantik yang tersedia!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              _ScannerFrame(
                scanPosition: _scanPosition,
                onDetect: (capture) {
                  final barcode = capture.barcodes.isNotEmpty ? capture.barcodes.first : null;
                  final code = barcode?.rawValue;
                  if (code == null) return;
                  final id = int.tryParse(code);
                  final matched = id == null ? null : products.where((p) => p.id == id).firstOrNull;
                  if (matched != null) {
                    context.go('/product/${matched.id}');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Product not found for code: $code')),
                    );
                  }
                },
              ),
              const SizedBox(height: 14),
              Text(
                'scanning will start automatically',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScannerFrame extends StatelessWidget {
  final Animation<double> scanPosition;
  final void Function(BarcodeCapture capture) onDetect;

  const _ScannerFrame({required this.scanPosition, required this.onDetect});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 340,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.black,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            MobileScanner(onDetect: onDetect),
            Positioned.fill(
              child: AnimatedBuilder(
                animation: scanPosition,
                builder: (context, child) {
                  return Align(
                    alignment: Alignment(0, (scanPosition.value * 2) - 1),
                    child: child,
                  );
                },
                child: Container(
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF00FF7A),
                        Color(0xFF00D66E),
                        Color(0xFF00FF7A),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00FF7A).withAlpha(120),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white.withAlpha(40)),
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
