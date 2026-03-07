import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerScreen extends StatelessWidget {
  const BarcodeScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan')),
      body: MobileScanner(
        onDetect: (capture) {
          final barcode = capture.barcodes.isNotEmpty ? capture.barcodes.first : null;
          final code = barcode?.rawValue;
          if (code != null) {
            debugPrint(code);
          }
        },
      ),
    );
  }
}
