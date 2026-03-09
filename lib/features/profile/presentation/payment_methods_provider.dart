import 'package:flutter_riverpod/flutter_riverpod.dart';

class PaymentMethod {
  final String name;
  final String detail;

  const PaymentMethod({required this.name, required this.detail});
}

class PaymentMethodsNotifier extends Notifier<List<PaymentMethod>> {
  @override
  List<PaymentMethod> build() => const [
        PaymentMethod(name: 'Visa', detail: '**** 4242'),
      ];

  void add(String name, String detail) {
    if (name.trim().isEmpty || detail.trim().isEmpty) return;
    state = [...state, PaymentMethod(name: name, detail: detail)];
  }

  void remove(PaymentMethod item) {
    state = state.where((e) => e != item).toList();
  }
}

final paymentMethodsProvider =
    NotifierProvider<PaymentMethodsNotifier, List<PaymentMethod>>(PaymentMethodsNotifier.new);
