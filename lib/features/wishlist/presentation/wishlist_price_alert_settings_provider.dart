import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PriceAlertSetting {
  final int productId;
  final double targetPrice;
  final String remindAt;

  const PriceAlertSetting({
    required this.productId,
    required this.targetPrice,
    required this.remindAt,
  });

  PriceAlertSetting copyWith({double? targetPrice, String? remindAt}) {
    return PriceAlertSetting(
      productId: productId,
      targetPrice: targetPrice ?? this.targetPrice,
      remindAt: remindAt ?? this.remindAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'targetPrice': targetPrice,
      'remindAt': remindAt,
    };
  }

  factory PriceAlertSetting.fromJson(Map<String, dynamic> json) {
    return PriceAlertSetting(
      productId: json['productId'] as int,
      targetPrice: (json['targetPrice'] as num).toDouble(),
      remindAt: json['remindAt'] as String,
    );
  }
}

class WishlistPriceAlertSettingsNotifier extends Notifier<Map<int, PriceAlertSetting>> {
  static const _storageKey = 'wishlist_price_alert_settings';

  @override
  Map<int, PriceAlertSetting> build() {
    _load();
    return {};
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? const <String>[];
    final map = <int, PriceAlertSetting>{};
    for (final item in raw) {
      try {
        final jsonMap = jsonDecode(item) as Map<String, dynamic>;
        final setting = PriceAlertSetting.fromJson(jsonMap);
        map[setting.productId] = setting;
      } catch (_) {}
    }
    state = map;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = state.values.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_storageKey, raw);
  }

  void setSetting(PriceAlertSetting setting) {
    state = {...state, setting.productId: setting};
    _save();
  }

  void remove(int productId) {
    final next = {...state}..remove(productId);
    state = next;
    _save();
  }
}

final wishlistPriceAlertSettingsProvider =
    NotifierProvider<WishlistPriceAlertSettingsNotifier, Map<int, PriceAlertSetting>>(
  WishlistPriceAlertSettingsNotifier.new,
);
