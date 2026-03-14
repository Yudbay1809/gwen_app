import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../home/presentation/home_providers.dart';
import '../../wishlist/presentation/wishlist_price_alert_provider.dart';
import '../../wishlist/presentation/wishlist_price_alert_settings_provider.dart';
import '../../wishlist/presentation/wishlist_price_history_provider.dart';
import 'notification_settings_provider.dart';

enum NotificationType { promo, orders, news, priceDrop, rewards, restock }

class NotificationItem {
  final int id;
  final String title;
  final String message;
  final String time;
  final NotificationType type;
  final bool isRead;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    required this.isRead,
  });

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      title: title,
      message: message,
      time: time,
      type: type,
      isRead: isRead ?? this.isRead,
    );
  }
}

class NotificationNotifier extends Notifier<List<NotificationItem>> {
  Timer? _timer;
  int _counter = 100;
  bool _seededPersonalized = false;

  @override
  List<NotificationItem> build() {
    final base = <NotificationItem>[
      NotificationItem(
        id: 1,
        title: 'Promo 20% Off',
        message: 'Use code GLOW20 before it expires.',
        time: '2h ago',
        type: NotificationType.promo,
        isRead: false,
      ),
      NotificationItem(
        id: 2,
        title: 'Order Shipped',
        message: 'Your order ORD-1012 has been shipped.',
        time: '1d ago',
        type: NotificationType.orders,
        isRead: true,
      ),
      NotificationItem(
        id: 3,
        title: 'Back in stock',
        message: 'Your saved serum is ready to order again.',
        time: '2d ago',
        type: NotificationType.restock,
        isRead: true,
      ),
    ];

    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      _counter += 1;
      final next = NotificationItem(
        id: _counter,
        title: 'New drop available',
        message: 'Check the latest products in Shop.',
        time: 'just now',
        type: NotificationType.news,
        isRead: false,
      );
      state = [next, ...state];
    });

    ref.onDispose(() => _timer?.cancel());
    if (!_seededPersonalized) {
      _seededPersonalized = true;
      Future.microtask(_seedPersonalizedNotifications);
    }
    return base;
  }

  void markRead(int id) {
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(isRead: true) else n,
    ];
  }

  void markAllRead() {
    state = [for (final n in state) n.copyWith(isRead: true)];
  }

  void markReadIds(Set<int> ids) {
    state = [
      for (final n in state)
        if (ids.contains(n.id)) n.copyWith(isRead: true) else n,
    ];
  }

  void deleteIds(Set<int> ids) {
    state = state.where((n) => !ids.contains(n.id)).toList();
  }

  void addNotification(NotificationItem item) {
    state = [item, ...state];
  }

  void _seedPersonalizedNotifications() {
    final alerts = ref.read(wishlistPriceAlertProvider);
    final settings = ref.read(wishlistPriceAlertSettingsProvider);
    final history = ref.read(wishlistPriceHistoryProvider);
    final products = ref.read(homeDataProvider).allProducts;
    final productsById = {for (final p in products) p.id: p};
    final generated = <NotificationItem>[];

    for (final id in alerts) {
      final product = productsById[id];
      final hist = history[id];
      if (product == null || hist == null || hist.length < 2) continue;
      final oldPrice = hist[hist.length - 2];
      final newPrice = hist.last;
      final drop = oldPrice - newPrice;
      if (drop <= 0) continue;
      final target = settings[id]?.targetPrice;
      final title = target != null && newPrice <= target ? 'Target price hit!' : 'Price drop alert';
      final message = target != null && newPrice <= target
          ? '${product.name} now Rp ${newPrice.toStringAsFixed(0)}.'
          : '${product.name} down Rp ${drop.toStringAsFixed(0)}.';
      generated.add(
        NotificationItem(
          id: 900000 + id,
          title: title,
          message: message,
          time: 'Today',
          type: NotificationType.priceDrop,
          isRead: false,
        ),
      );
    }

    if (generated.isNotEmpty) {
      state = [...generated, ...state];
    }
  }
}

final notificationProvider = NotifierProvider<NotificationNotifier, List<NotificationItem>>(
  NotificationNotifier.new,
);

class PinnedNotificationsNotifier extends Notifier<Set<int>> {
  static const _storageKey = 'notification_pins';

  @override
  Set<int> build() {
    _load();
    return <int>{};
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? [];
    state = raw.map(int.parse).toSet();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, state.map((e) => e.toString()).toList());
  }

  void toggle(int id) {
    final next = Set<int>.from(state);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    state = next;
    _save();
  }

  void toggleMany(Set<int> ids, {required bool pin}) {
    final next = Set<int>.from(state);
    if (pin) {
      next.addAll(ids);
    } else {
      next.removeAll(ids);
    }
    state = next;
    _save();
  }
}

final pinnedNotificationsProvider =
    NotifierProvider<PinnedNotificationsNotifier, Set<int>>(PinnedNotificationsNotifier.new);

final sortedNotificationProvider = Provider<List<NotificationItem>>((ref) {
  final list = ref.watch(personalizedNotificationProvider);
  final pinned = ref.watch(pinnedNotificationsProvider);
  final priority = {
    NotificationType.orders: 0,
    NotificationType.priceDrop: 1,
    NotificationType.rewards: 2,
    NotificationType.promo: 3,
    NotificationType.restock: 4,
    NotificationType.news: 5,
  };
  final sorted = [...list];
  sorted.sort((a, b) {
    final aPinned = pinned.contains(a.id) ? 0 : 1;
    final bPinned = pinned.contains(b.id) ? 0 : 1;
    if (aPinned != bPinned) return aPinned.compareTo(bPinned);
    final pa = priority[a.type] ?? 99;
    final pb = priority[b.type] ?? 99;
    if (pa != pb) return pa.compareTo(pb);
    return b.id.compareTo(a.id);
  });
  return sorted;
});

final personalizedNotificationProvider = Provider<List<NotificationItem>>((ref) {
  final list = ref.watch(notificationProvider);
  final settings = ref.watch(notificationSettingsProvider);
  return list
      .where((n) {
        switch (n.type) {
          case NotificationType.promo:
            return settings.promo;
          case NotificationType.orders:
            return settings.orders;
          case NotificationType.news:
            return settings.news;
          case NotificationType.priceDrop:
            return settings.priceDrops;
          case NotificationType.rewards:
            return settings.rewards;
          case NotificationType.restock:
            return settings.restock;
        }
      })
      .toList();
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final list = ref.watch(personalizedNotificationProvider);
  return list.where((e) => !e.isRead).length;
});
