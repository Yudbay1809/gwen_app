import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CheckoutAddress {
  final String id;
  final String name;
  final String phone;
  final String address;

  const CheckoutAddress({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
  });
}

class CheckoutAddressNotifier extends Notifier<String> {
  static const _storageKey = 'checkout_default_address';

  @override
  String build() {
    _load();
    return 'home';
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_storageKey);
    if (value != null) {
      state = value;
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, state);
  }

  void setDefault(String id) {
    state = id;
    _save();
  }
}

final checkoutAddressProvider = Provider<List<CheckoutAddress>>((ref) {
  return const [
    CheckoutAddress(
      id: 'home',
      name: 'Home',
      phone: '0812 8888 1234',
      address: 'Jl. Kemang Raya No. 12, Jakarta Selatan',
    ),
    CheckoutAddress(
      id: 'office',
      name: 'Office',
      phone: '0813 7777 9876',
      address: 'Menara Sudirman Lt. 8, Jakarta',
    ),
  ];
});

final checkoutDefaultAddressProvider =
    NotifierProvider<CheckoutAddressNotifier, String>(CheckoutAddressNotifier.new);
