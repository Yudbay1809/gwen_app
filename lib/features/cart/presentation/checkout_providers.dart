import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddressItem {
  final int id;
  final String label;
  final String name;
  final String phone;
  final String detail;

  const AddressItem({
    required this.id,
    required this.label,
    required this.name,
    required this.phone,
    required this.detail,
  });
}

class PaymentMethodItem {
  final int id;
  final String name;
  final String detail;

  const PaymentMethodItem({
    required this.id,
    required this.name,
    required this.detail,
  });
}

final addressesProvider = Provider<List<AddressItem>>((ref) {
  return const [
    AddressItem(
      id: 1,
      label: 'Home',
      name: 'GWEN Beauty',
      phone: '+62 812 3456 7890',
      detail: 'Jl. Merdeka No. 12, Jakarta Selatan',
    ),
    AddressItem(
      id: 2,
      label: 'Office',
      name: 'GWEN Beauty',
      phone: '+62 811 2222 3333',
      detail: 'Jl. Sudirman No. 8, Jakarta Pusat',
    ),
  ];
});

final paymentMethodsProvider = Provider<List<PaymentMethodItem>>((ref) {
  return const [
    PaymentMethodItem(id: 1, name: 'Virtual Account', detail: 'BCA / Mandiri / BNI'),
    PaymentMethodItem(id: 2, name: 'E-Wallet', detail: 'OVO / GoPay / DANA'),
    PaymentMethodItem(id: 3, name: 'Credit Card', detail: 'Visa / MasterCard'),
  ];
});

final deliverySlotsProvider = Provider<List<String>>((ref) {
  return const [
    'Today 12:00 - 14:00',
    'Today 16:00 - 18:00',
    'Tomorrow 10:00 - 12:00',
    'Tomorrow 14:00 - 16:00',
  ];
});

final deliverySlotsByAddressProvider = Provider<Map<int, List<String>>>((ref) {
  return const {
    1: [
      'Today 12:00 - 14:00',
      'Today 16:00 - 18:00',
      'Tomorrow 10:00 - 12:00',
    ],
    2: [
      'Today 14:00 - 16:00',
      'Tomorrow 10:00 - 12:00',
      'Tomorrow 16:00 - 18:00',
    ],
  };
});

class SelectedAddressNotifier extends Notifier<int> {
  static const _storageKey = 'checkout_selected_address';

  @override
  int build() {
    _load();
    return 1;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_storageKey);
    if (saved != null) {
      state = saved;
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_storageKey, state);
  }

  void select(int id) {
    state = id;
    _save();
  }
}

class SelectedPaymentNotifier extends Notifier<int> {
  @override
  int build() => 1;

  void select(int id) => state = id;
}

class SelectedDeliverySlotNotifier extends Notifier<Map<int, String>> {
  static const _storageKey = 'delivery_slots_selected';

  @override
  Map<int, String> build() {
    _load();
    return {};
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? [];
    final mapped = <int, String>{};
    for (final entry in raw) {
      final parts = entry.split('|');
      if (parts.length != 2) continue;
      final id = int.tryParse(parts[0]);
      if (id == null) continue;
      mapped[id] = parts[1];
    }
    state = mapped;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = state.entries.map((e) => '${e.key}|${e.value}').toList();
    await prefs.setStringList(_storageKey, raw);
  }

  void select(int addressId, String slot) {
    state = {...state, addressId: slot};
    _save();
  }

  void reset(int addressId, String slot) {
    state = {...state, addressId: slot};
    _save();
  }
}

class DeliveryNoteNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setNote(String value) => state = value;
  void clear() => state = '';
}

class AddressNotesNotifier extends Notifier<Map<int, String>> {
  @override
  Map<int, String> build() => {};

  void setNote(int addressId, String note) {
    state = {...state, addressId: note};
  }
}

final selectedAddressProvider =
    NotifierProvider<SelectedAddressNotifier, int>(SelectedAddressNotifier.new);
final selectedPaymentProvider =
    NotifierProvider<SelectedPaymentNotifier, int>(SelectedPaymentNotifier.new);
final selectedDeliverySlotProvider =
    NotifierProvider<SelectedDeliverySlotNotifier, Map<int, String>>(SelectedDeliverySlotNotifier.new);
final deliveryNoteProvider = NotifierProvider<DeliveryNoteNotifier, String>(DeliveryNoteNotifier.new);
final addressNotesProvider =
    NotifierProvider<AddressNotesNotifier, Map<int, String>>(AddressNotesNotifier.new);
