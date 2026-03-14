import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationSettings {
  final bool promo;
  final bool orders;
  final bool news;
  final bool priceDrops;
  final bool restock;
  final bool rewards;
  final bool sound;
  final bool vibrate;
  final bool quietHours;
  final TimeOfDay quietStart;
  final TimeOfDay quietEnd;

  const NotificationSettings({
    required this.promo,
    required this.orders,
    required this.news,
    required this.priceDrops,
    required this.restock,
    required this.rewards,
    required this.sound,
    required this.vibrate,
    required this.quietHours,
    required this.quietStart,
    required this.quietEnd,
  });

  NotificationSettings copyWith({
    bool? promo,
    bool? orders,
    bool? news,
    bool? priceDrops,
    bool? restock,
    bool? rewards,
    bool? sound,
    bool? vibrate,
    bool? quietHours,
    TimeOfDay? quietStart,
    TimeOfDay? quietEnd,
  }) {
    return NotificationSettings(
      promo: promo ?? this.promo,
      orders: orders ?? this.orders,
      news: news ?? this.news,
      priceDrops: priceDrops ?? this.priceDrops,
      restock: restock ?? this.restock,
      rewards: rewards ?? this.rewards,
      sound: sound ?? this.sound,
      vibrate: vibrate ?? this.vibrate,
      quietHours: quietHours ?? this.quietHours,
      quietStart: quietStart ?? this.quietStart,
      quietEnd: quietEnd ?? this.quietEnd,
    );
  }
}

class NotificationSettingsNotifier extends Notifier<NotificationSettings> {
  @override
  NotificationSettings build() {
    return const NotificationSettings(
      promo: true,
      orders: true,
      news: true,
      priceDrops: true,
      restock: true,
      rewards: true,
      sound: true,
      vibrate: true,
      quietHours: false,
      quietStart: TimeOfDay(hour: 22, minute: 0),
      quietEnd: TimeOfDay(hour: 7, minute: 0),
    );
  }

  void togglePromo(bool v) => state = state.copyWith(promo: v);
  void toggleOrders(bool v) => state = state.copyWith(orders: v);
  void toggleNews(bool v) => state = state.copyWith(news: v);
  void togglePriceDrops(bool v) => state = state.copyWith(priceDrops: v);
  void toggleRestock(bool v) => state = state.copyWith(restock: v);
  void toggleRewards(bool v) => state = state.copyWith(rewards: v);
  void toggleSound(bool v) => state = state.copyWith(sound: v);
  void toggleVibrate(bool v) => state = state.copyWith(vibrate: v);
  void toggleQuietHours(bool v) => state = state.copyWith(quietHours: v);
  void setQuietStart(TimeOfDay value) => state = state.copyWith(quietStart: value);
  void setQuietEnd(TimeOfDay value) => state = state.copyWith(quietEnd: value);
}

final notificationSettingsProvider =
    NotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
  NotificationSettingsNotifier.new,
);
