// ignore_for_file: deprecated_member_use
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

Future<String> saveReceiptPngImpl(Uint8List bytes) async {
  final fileName = 'gwen-receipt-${DateTime.now().millisecondsSinceEpoch}.png';
  final blob = html.Blob([bytes], 'image/png');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..download = fileName
    ..click();
  html.Url.revokeObjectUrl(url);
  return 'Downloaded $fileName';
}

Future<void> shareReceiptPngImpl(Uint8List bytes, {String fileName = 'gwen-receipt'}) async {
  final blob = html.Blob([bytes], 'image/png');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..download = '$fileName.png'
    ..click();
  html.Url.revokeObjectUrl(url);
}
