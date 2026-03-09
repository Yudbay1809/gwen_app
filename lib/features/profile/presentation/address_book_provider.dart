import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddressItem {
  final int id;
  final String name;
  final String detail;
  final String phone;

  const AddressItem({
    required this.id,
    required this.name,
    required this.detail,
    required this.phone,
  });

  AddressItem copyWith({String? name, String? detail, String? phone}) {
    return AddressItem(
      id: id,
      name: name ?? this.name,
      detail: detail ?? this.detail,
      phone: phone ?? this.phone,
    );
  }
}

class AddressBookNotifier extends Notifier<List<AddressItem>> {
  @override
  List<AddressItem> build() => const [
        AddressItem(
          id: 1,
          name: 'Home',
          detail: 'Jl. Merdeka No. 12, Jakarta Selatan',
          phone: '+62 812 3456 7890',
        ),
      ];

  void add(String name, String detail, String phone) {
    if (name.trim().isEmpty || detail.trim().isEmpty) return;
    final nextId = (state.map((e) => e.id).toList()..sort()).isEmpty ? 1 : state.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
    state = [...state, AddressItem(id: nextId, name: name, detail: detail, phone: phone)];
  }

  void update(int id, String name, String detail, String phone) {
    state = state
        .map((e) => e.id == id ? e.copyWith(name: name, detail: detail, phone: phone) : e)
        .toList();
  }

  void remove(int id) {
    state = state.where((e) => e.id != id).toList();
  }
}

final addressBookProvider =
    NotifierProvider<AddressBookNotifier, List<AddressItem>>(AddressBookNotifier.new);
