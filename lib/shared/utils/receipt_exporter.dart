import 'dart:typed_data';

import 'receipt_exporter_stub.dart'
    if (dart.library.io) 'receipt_exporter_io.dart'
    if (dart.library.html) 'receipt_exporter_web.dart';

Future<String> saveReceiptPng(Uint8List bytes) => saveReceiptPngImpl(bytes);

Future<void> shareReceiptPng(Uint8List bytes, {String fileName = 'gwen-receipt'}) =>
    shareReceiptPngImpl(bytes, fileName: fileName);
