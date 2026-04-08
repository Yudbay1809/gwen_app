import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gwen_app/core/storage/local_storage.dart';
import 'package:gwen_app/core/storage/secure_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('local storage reads and writes typed values', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage();

    await storage.writeString('s', 'value');
    await storage.writeBool('b', true);
    await storage.writeDouble('d', 12.5);

    expect(await storage.readString('s'), 'value');
    expect(await storage.readBool('b'), true);
    expect(await storage.readDouble('d'), 12.5);

    await storage.remove('s');
    expect(await storage.readString('s'), isNull);
  });

  test('secure storage encodes and decodes string payload', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = SecureStorage();

    await storage.write('token', 'abc123');
    expect(await storage.read('token'), 'abc123');

    await storage.remove('token');
    expect(await storage.read('token'), isNull);
  });
}
