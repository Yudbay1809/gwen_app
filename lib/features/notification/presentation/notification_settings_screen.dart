import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notification_settings_provider.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notification Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Channels', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Promo updates'),
            value: settings.promo,
            onChanged: (v) => ref.read(notificationSettingsProvider.notifier).togglePromo(v),
          ),
          SwitchListTile(
            title: const Text('Order updates'),
            value: settings.orders,
            onChanged: (v) => ref.read(notificationSettingsProvider.notifier).toggleOrders(v),
          ),
          SwitchListTile(
            title: const Text('Newsfeed updates'),
            value: settings.news,
            onChanged: (v) => ref.read(notificationSettingsProvider.notifier).toggleNews(v),
          ),
          const Divider(),
          const Text('Personalization', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Price drop alerts'),
            subtitle: const Text('Get notified when wishlist items drop in price'),
            value: settings.priceDrops,
            onChanged: (v) => ref.read(notificationSettingsProvider.notifier).togglePriceDrops(v),
          ),
          SwitchListTile(
            title: const Text('Back in stock'),
            subtitle: const Text('Restock updates for items you saved'),
            value: settings.restock,
            onChanged: (v) => ref.read(notificationSettingsProvider.notifier).toggleRestock(v),
          ),
          SwitchListTile(
            title: const Text('Rewards & check-in'),
            subtitle: const Text('Daily streaks, bonus points, and missions'),
            value: settings.rewards,
            onChanged: (v) => ref.read(notificationSettingsProvider.notifier).toggleRewards(v),
          ),
          const Divider(),
          const Text('Behavior', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Sound'),
            value: settings.sound,
            onChanged: (v) => ref.read(notificationSettingsProvider.notifier).toggleSound(v),
          ),
          SwitchListTile(
            title: const Text('Vibrate'),
            value: settings.vibrate,
            onChanged: (v) => ref.read(notificationSettingsProvider.notifier).toggleVibrate(v),
          ),
          const Divider(),
          const Text('Quiet Hours', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Enable quiet hours'),
            subtitle: const Text('Mute notifications during this time'),
            value: settings.quietHours,
            onChanged: (v) => ref.read(notificationSettingsProvider.notifier).toggleQuietHours(v),
          ),
          ListTile(
            title: const Text('Start time'),
            subtitle: Text(_formatTime(context, settings.quietStart)),
            trailing: const Icon(Icons.schedule),
            onTap: settings.quietHours
                ? () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: settings.quietStart,
                    );
                    if (picked != null) {
                      ref.read(notificationSettingsProvider.notifier).setQuietStart(picked);
                    }
                  }
                : null,
          ),
          ListTile(
            title: const Text('End time'),
            subtitle: Text(_formatTime(context, settings.quietEnd)),
            trailing: const Icon(Icons.schedule),
            onTap: settings.quietHours
                ? () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: settings.quietEnd,
                    );
                    if (picked != null) {
                      ref.read(notificationSettingsProvider.notifier).setQuietEnd(picked);
                    }
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

String _formatTime(BuildContext context, TimeOfDay time) {
  return time.format(context);
}
