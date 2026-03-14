import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<String> saveReceiptPngImpl(Uint8List bytes) async {
  final dir = await getApplicationDocumentsDirectory();
  final fileName = 'gwen-receipt-${DateTime.now().millisecondsSinceEpoch}.png';
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

Future<void> shareReceiptPngImpl(Uint8List bytes, {String fileName = 'gwen-receipt'}) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$fileName.png');
  await file.writeAsBytes(bytes, flush: true);
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path)],
      text: 'GWEN Beauty - Payment Receipt',
    ),
  );
}
