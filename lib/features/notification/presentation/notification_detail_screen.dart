import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'notification_providers.dart';

class NotificationDetailScreen extends ConsumerWidget {
  final String id;

  const NotificationDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nid = int.tryParse(id);
    final item = nid == null
        ? null
        : ref.watch(personalizedNotificationProvider).where((e) => e.id == nid).firstOrNull;

    if (item == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notification'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                if (context.canPop()) context.pop();
              } else {
                context.go('/notifications');
              }
            },
          ),
        ),
        body: const Center(child: Text('Notification not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(item.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              if (context.canPop()) context.pop();
            } else {
              context.go('/notifications');
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(item.time, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            Text(item.message),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Open'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
