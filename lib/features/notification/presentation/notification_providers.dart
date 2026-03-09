import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum NotificationType { promo, orders, news }

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

  @override
  List<NotificationItem> build() {
    state = const [
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
    return state;
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
  final list = ref.watch(notificationProvider);
  final pinned = ref.watch(pinnedNotificationsProvider);
  final priority = {
    NotificationType.orders: 0,
    NotificationType.promo: 1,
    NotificationType.news: 2,
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

final unreadNotificationCountProvider = Provider<int>((ref) {
  final list = ref.watch(notificationProvider);
  return list.where((e) => !e.isRead).length;
});
