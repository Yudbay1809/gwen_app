import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SecureStorage {
  static const _prefix = 'secure_';

  String _key(String key) => '$_prefix$key';

  Future<void> write(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = base64Encode(utf8.encode(value));
    await prefs.setString(_key(key), encoded);
  }

  Future<String?> read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_key(key));
    if (encoded == null || encoded.isEmpty) return null;
    try {
      return utf8.decode(base64Decode(encoded));
    } catch (_) {
      return null;
    }
  }

  Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(key));
  }
}
