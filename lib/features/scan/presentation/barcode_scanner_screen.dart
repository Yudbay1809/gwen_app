import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import '../../home/presentation/home_providers.dart';

class BarcodeScannerScreen extends ConsumerWidget {
  const BarcodeScannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(homeDataProvider).allProducts;

    return Scaffold(
      appBar: AppBar(title: const Text('Scan')),
      body: MobileScanner(
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
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
