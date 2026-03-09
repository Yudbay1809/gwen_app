import 'dart:io';

Future<bool> checkOnline() async {
  try {
    final result = await InternetAddress.lookup('example.com');
    return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
  } catch (_) {
    return false;
  }
}
