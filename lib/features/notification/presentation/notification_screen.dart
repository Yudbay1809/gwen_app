import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'notification_providers.dart';
import '../../../shared/widgets/empty_state.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  NotificationType? _filterType;
  bool _onlyUnread = false;
  bool _selectMode = false;
  final Set<int> _selected = {};
  int _lastCount = 0;
  bool _digestMode = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    ref.listen<List<NotificationItem>>(notificationProvider, (prev, next) {
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

  void _toggleSelection(int id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(sortedNotificationProvider);
    final pinned = ref.watch(pinnedNotificationsProvider);

    var filtered = _filterType == null ? items : items.where((n) => n.type == _filterType).toList();
    if (_onlyUnread) {
      filtered = filtered.where((n) => !n.isRead).toList();
    }
    if (_query.trim().isNotEmpty) {
      final q = _query.toLowerCase();
      filtered = filtered
          .where((n) => n.title.toLowerCase().contains(q) || n.message.toLowerCase().contains(q))
          .toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectMode = !_selectMode;
                if (!_selectMode) _selected.clear();
              });
            },
            child: Text(_selectMode ? 'Cancel' : 'Select', style: const TextStyle(color: Colors.black87)),
          ),
          TextButton(
            onPressed: () => ref.read(notificationProvider.notifier).markAllRead(),
            child: const Text('Mark all', style: TextStyle(color: Colors.black87)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search notifications...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const SizedBox(width: 16),
                ChoiceChip(
                  label: const Text('All'),
                  selected: _filterType == null,
                  onSelected: (_) => setState(() => _filterType = null),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Promo'),
                  selected: _filterType == NotificationType.promo,
                  onSelected: (_) => setState(() => _filterType = NotificationType.promo),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Orders'),
                  selected: _filterType == NotificationType.orders,
                  onSelected: (_) => setState(() => _filterType = NotificationType.orders),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('News'),
                  selected: _filterType == NotificationType.news,
                  onSelected: (_) => setState(() => _filterType = NotificationType.news),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Unread'),
                  selected: _onlyUnread,
                  onSelected: (v) => setState(() => _onlyUnread = v),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Digest'),
                  selected: _digestMode,
                  onSelected: (v) => setState(() => _digestMode = v),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
          if (_selectMode)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text('${_selected.length} selected'),
                  const Spacer(),
                  TextButton(
                    onPressed: _selected.isEmpty
                        ? null
                        : () {
                            ref.read(notificationProvider.notifier).markReadIds(_selected);
                            setState(() => _selected.clear());
                          },
                    child: const Text('Mark read'),
                  ),
                  TextButton(
                    onPressed: _selected.isEmpty
                        ? null
                        : () {
                            ref.read(pinnedNotificationsProvider.notifier).toggleMany(_selected, pin: true);
                            setState(() => _selected.clear());
                          },
                    child: const Text('Pin'),
                  ),
                  TextButton(
                    onPressed: _selected.isEmpty
                        ? null
                        : () {
                            ref.read(pinnedNotificationsProvider.notifier).toggleMany(_selected, pin: false);
                            setState(() => _selected.clear());
                          },
                    child: const Text('Unpin'),
                  ),
                  TextButton(
                    onPressed: _selected.isEmpty
                        ? null
                        : () {
                            ref.read(notificationProvider.notifier).deleteIds(_selected);
                            setState(() => _selected.clear());
                          },
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: filtered.isEmpty
                ? const EmptyState(
                    icon: Icons.notifications_none,
                    title: 'No notifications',
                    message: 'You are all caught up.',
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children:
                        _digestMode ? _buildDigestList(filtered, pinned) : _buildGroupedList(filtered, pinned),
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
        final tileColor = n.isRead ? null : Colors.pink.shade50;
        if (_selectMode) {
          widgets.add(
            CheckboxListTile(
              value: _selected.contains(n.id),
              onChanged: (_) => _toggleSelection(n.id),
              title: Text(n.title),
              subtitle: Text(n.message),
              secondary: Text(n.time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              tileColor: tileColor,
            ),
          );
        } else {
          widgets.add(
            ListTile(
              title: Text(n.title),
              subtitle: Text(n.message),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(pinned.contains(n.id) ? Icons.push_pin : Icons.push_pin_outlined, size: 18),
                    onPressed: () => ref.read(pinnedNotificationsProvider.notifier).toggle(n.id),
                  ),
                  Text(n.time, style: const TextStyle(color: Colors.grey)),
                ],
              ),
              tileColor: tileColor,
              onTap: () {
                ref.read(notificationProvider.notifier).markRead(n.id);
                context.go('/notifications/${n.id}');
              },
            ),
          );
        }
      }
    }
    return widgets;
  }

  List<Widget> _buildDigestList(List<NotificationItem> list, Set<int> pinned) {
    final groups = <String, List<NotificationItem>>{};
    for (final n in list) {
      final key = _groupKey(n.time);
      groups.putIfAbsent(key, () => []).add(n);
    }
    final widgets = <Widget>[];
    for (final entry in groups.entries) {
      final items = entry.value;
      final pinnedCount = items.where((e) => pinned.contains(e.id)).length;
      final titles = items.take(2).map((e) => e.title).join(' • ');
      widgets.add(
        Card(
          child: ListTile(
            leading: const Icon(Icons.summarize_outlined),
            title: Text(
              '${entry.key} · ${items.length} notifications${pinnedCount > 0 ? ' · $pinnedCount pinned' : ''}',
            ),
            subtitle: Text(titles),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => setState(() => _digestMode = false),
          ),
        ),
      );
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
