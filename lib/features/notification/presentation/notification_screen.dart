import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'notification_providers.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  NotificationType? _filterType;
  int _lastCount = 0;
  late final ProviderSubscription<List<NotificationItem>> _notifSub;

  @override
  void initState() {
    super.initState();
    _notifSub = ref.listenManual<List<NotificationItem>>(notificationProvider, (prev, next) {
      if (!mounted) return;
      final prevCount = prev?.length ?? _lastCount;
      if (next.length > prevCount) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New notification received')),
        );
      }
      _lastCount = next.length;
    });
  }

  @override
  void dispose() {
    _notifSub.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(sortedNotificationProvider);
    final pinned = ref.watch(pinnedNotificationsProvider);

    var filtered = _filterType == null ? items : items.where((n) => n.type == _filterType).toList();
    final unreadOrders = items.where((n) => n.type == NotificationType.orders && !n.isRead).length;
    final unreadPromo = items.where((n) => n.type == NotificationType.promo && !n.isRead).length;
    final unreadNews = items.where((n) => n.type == NotificationType.news && !n.isRead).length;
    final unreadPriceDrops = items.where((n) => n.type == NotificationType.priceDrop && !n.isRead).length;
    final unreadRewards = items.where((n) => n.type == NotificationType.rewards && !n.isRead).length;
    final totalUnread = items.where((n) => !n.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go('/notifications/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Theme.of(context).colorScheme.outline),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 12, offset: const Offset(0, 6)),
                ],
              ),
              child: SizedBox(
                height: 86,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _CategoryItem(
                      icon: Icons.shopping_bag_outlined,
                      label: 'Pesanan',
                      selected: _filterType == NotificationType.orders,
                      badge: unreadOrders,
                      onTap: () => setState(() => _filterType = NotificationType.orders),
                    ),
                    const _CategoryDivider(),
                    _CategoryItem(
                      icon: Icons.percent,
                      label: 'Promo',
                      selected: _filterType == NotificationType.promo,
                      badge: unreadPromo,
                      onTap: () => setState(() => _filterType = NotificationType.promo),
                    ),
                    const _CategoryDivider(),
                    _CategoryItem(
                      icon: Icons.trending_down,
                      label: 'Price drop',
                      selected: _filterType == NotificationType.priceDrop,
                      badge: unreadPriceDrops,
                      onTap: () => setState(() => _filterType = NotificationType.priceDrop),
                    ),
                    const _CategoryDivider(),
                    _CategoryItem(
                      icon: Icons.auto_awesome,
                      label: 'Rewards',
                      selected: _filterType == NotificationType.rewards,
                      badge: unreadRewards,
                      onTap: () => setState(() => _filterType = NotificationType.rewards),
                    ),
                    const _CategoryDivider(),
                    _CategoryItem(
                      icon: Icons.event_outlined,
                      label: 'Event',
                      selected: _filterType == NotificationType.news,
                      badge: unreadNews,
                      onTap: () => setState(() => _filterType = NotificationType.news),
                    ),
                    const _CategoryDivider(),
                    _CategoryItem(
                      icon: Icons.info_outline,
                      label: 'Info',
                      selected: _filterType == null,
                      badge: totalUnread,
                      onTap: () => setState(() => _filterType = null),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text('Semua Notifikasi', style: TextStyle(fontWeight: FontWeight.w700)),
                const Spacer(),
                TextButton(
                  onPressed: () => ref.read(notificationProvider.notifier).markAllRead(),
                  child: const Text('Tandai sudah dibaca'),
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const _NotificationEmpty()
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: _buildGroupedList(filtered, pinned),
                  ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGroupedList(List<NotificationItem> list, Set<int> pinned) {
    final groups = <String, List<NotificationItem>>{};
    for (final n in list) {
      final key = _groupKey(n.time);
      groups.putIfAbsent(key, () => []).add(n);
    }
    final widgets = <Widget>[];
    for (final entry in groups.entries) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      );
      for (final n in entry.value) {
        final tileColor = n.isRead
            ? Theme.of(context).colorScheme.surface
            : Theme.of(context).colorScheme.primaryContainer;
        widgets.add(
          InkWell(
            onTap: () {
              ref.read(notificationProvider.notifier).markRead(n.id);
              context.go('/notifications/${n.id}');
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: tileColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).colorScheme.outline),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TypeBubble(type: n.type),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(n.message, style: const TextStyle(color: Colors.black54)),
                        const SizedBox(height: 8),
                        Text(n.time, style: const TextStyle(color: Colors.black45, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(pinned.contains(n.id) ? Icons.push_pin : Icons.push_pin_outlined, size: 18),
                    onPressed: () => ref.read(pinnedNotificationsProvider.notifier).toggle(n.id),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }
    return widgets;
  }

  String _groupKey(String time) {
    final t = time.toLowerCase();
    if (t.contains('just') || t.contains('h')) return 'Today';
    if (t.contains('1d')) return 'Yesterday';
    return 'Earlier';
  }
}

class _CategoryDivider extends StatelessWidget {
  const _CategoryDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: Theme.of(context).colorScheme.outline.withAlpha(120),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final int badge;
  final VoidCallback onTap;

  const _CategoryItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.primary : scheme.primary.withAlpha(160);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withAlpha(80)),
                ),
                child: Icon(icon, color: color),
              ),
              if (badge > 0)
                Positioned(
                  right: -2,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$badge',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }
}

class _TypeBubble extends StatelessWidget {
  final NotificationType type;

  const _TypeBubble({required this.type});

  @override
  Widget build(BuildContext context) {
    final icon = switch (type) {
      NotificationType.orders => Icons.shopping_bag_outlined,
      NotificationType.promo => Icons.percent,
      NotificationType.news => Icons.info_outline,
      NotificationType.priceDrop => Icons.trending_down,
      NotificationType.rewards => Icons.auto_awesome,
      NotificationType.restock => Icons.inventory_2_outlined,
    };
    final scheme = Theme.of(context).colorScheme;
    final color = switch (type) {
      NotificationType.orders => scheme.primary,
      NotificationType.promo => scheme.secondary,
      NotificationType.news => scheme.tertiary,
      NotificationType.priceDrop => Colors.green,
      NotificationType.rewards => scheme.secondaryContainer,
      NotificationType.restock => scheme.primaryContainer,
    };
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }
}

class _NotificationEmpty extends StatelessWidget {
  const _NotificationEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(context).colorScheme.outline),
              ),
              child: Icon(
                Icons.notifications_none,
                size: 44,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Belum ada notifikasi untuk kamu',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Nantikan informasi menarik dari GWEN Beauty di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
