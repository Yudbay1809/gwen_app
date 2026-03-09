import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Coupon {
  final String code;
  final String title;
  final String description;
  final double discountPct;
  final double minSubtotal;
  final String expiry;

  const Coupon({
    required this.code,
    required this.title,
    required this.description,
    required this.discountPct,
    required this.minSubtotal,
    required this.expiry,
  });
}

class ClaimedCouponsNotifier extends Notifier<Set<String>> {
  static const _storageKey = 'claimed_coupons';

  @override
  Set<String> build() {
    _load();
    return <String>{};
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey);
    if (raw != null) {
      state = raw.toSet();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, state.toList());
  }

  void claim(String code) {
    state = {...state, code};
    _save();
  }

  void unclaim(String code) {
    state = state.where((e) => e != code).toSet();
    _save();
  }
}

final claimedCouponsProvider =
    NotifierProvider<ClaimedCouponsNotifier, Set<String>>(ClaimedCouponsNotifier.new);

final couponsProvider = Provider<List<Coupon>>((ref) {
  return const [
    Coupon(
      code: 'BEAUTY10',
      title: '10% off skincare',
      description: 'Valid for skincare category only.',
      discountPct: 0.10,
      minSubtotal: 100000,
      expiry: 'Mar 20, 2026',
    ),
    Coupon(
      code: 'GLOW20',
      title: '20% off orders 300K+',
      description: 'Best for big hauls.',
      discountPct: 0.20,
      minSubtotal: 300000,
      expiry: 'Apr 1, 2026',
    ),
    Coupon(
      code: 'SKIN5',
      title: '5% off any order',
      description: 'Stackable with some promos.',
      discountPct: 0.05,
      minSubtotal: 0,
      expiry: 'Mar 31, 2026',
    ),
  ];
});
