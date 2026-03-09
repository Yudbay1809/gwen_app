import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../../newsfeed/presentation/article_comments_provider.dart';
import '../../newsfeed/presentation/article_reaction_provider.dart';
import '../../newsfeed/presentation/article_bookmark_provider.dart';
import '../../review/presentation/review_like_provider.dart';
import '../../review/presentation/review_replies_provider.dart';
import '../../../core/theme/theme_provider.dart';
import 'settings_storage_provider.dart';
import '../../wishlist/presentation/wishlist_price_alert_provider.dart';
import '../../newsfeed/presentation/article_metrics_provider.dart';
import 'dev_tools_settings_provider.dart';

class DevToolsScreen extends ConsumerStatefulWidget {
  const DevToolsScreen({super.key});

  @override
  ConsumerState<DevToolsScreen> createState() => _DevToolsScreenState();
}

class _DevToolsScreenState extends ConsumerState<DevToolsScreen> {
  bool _busy = false;

  Future<void> _resetSeeds() async {
    setState(() => _busy = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('article_comments');
    await prefs.remove('article_comments_seeded');
    await prefs.remove('article_reactions');
    await prefs.remove('article_reactions_seeded');
    await prefs.remove('review_likes');
    await prefs.remove('review_likes_seeded');
    await prefs.remove('review_helpful');
    await prefs.remove('review_helpful_seeded');
    await prefs.remove('review_replies');
    await prefs.remove('review_replies_seeded');
    await prefs.remove('article_bookmarks');
    await prefs.remove('article_bookmarks_seeded');
    await prefs.remove('wishlist_price_alerts');
    await prefs.remove('wishlist_price_alerts_seeded');
    await prefs.remove('article_metrics');
    await prefs.remove('article_metrics_seeded');

    ref.invalidate(articleCommentsProvider);
    ref.invalidate(articleReactionProvider);
    ref.invalidate(articleBookmarkProvider);
    ref.invalidate(reviewLikeProvider);
    ref.invalidate(reviewHelpfulProvider);
    ref.invalidate(reviewRepliesProvider);
    ref.invalidate(wishlistPriceAlertProvider);
    ref.invalidate(articleMetricsProvider);

    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Seed data reset')),
    );
  }

  Future<void> _resetCache() async {
    setState(() => _busy = true);
    ref.read(storageUsageProvider.notifier).clearCache();
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cache cleared')),
    );
  }

  Future<void> _resetPreferences() async {
    setState(() => _busy = true);
    await ref.read(appPreferencesProvider.notifier).reset();
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preferences reset')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final devSettings = ref.watch(devToolsSettingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Dev Tools')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Seed Utilities', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.restart_alt),
            title: const Text('Reset seed data'),
            subtitle: const Text('Clear persisted seed data and re-apply defaults'),
            trailing: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator()) : null,
            onTap: _busy ? null : _resetSeeds,
          ),
          const SizedBox(height: 12),
          const Text('UI Experiments', style: TextStyle(fontWeight: FontWeight.w700)),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Home animations'),
            subtitle: const Text('Enable section reveal animations'),
            value: devSettings.homeAnimations,
            onChanged: (v) => ref.read(devToolsSettingsProvider.notifier).setHomeAnimations(v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Reduce motion'),
            subtitle: const Text('Minimize animations globally'),
            value: devSettings.reduceMotion,
            onChanged: (v) => ref.read(devToolsSettingsProvider.notifier).setReduceMotion(v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Home A/B layout'),
            subtitle: const Text('Toggle alternate home layout experiment'),
            value: devSettings.homeAltLayout,
            onChanged: (v) => ref.read(devToolsSettingsProvider.notifier).setHomeAltLayout(v),
          ),
          const SizedBox(height: 8),
          const Text('Scroll-Spy Tuning', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Top threshold ${devSettings.scrollSpyTop.toStringAsFixed(2)}'),
          Slider(
            value: devSettings.scrollSpyTop,
            min: 0.05,
            max: 0.35,
            divisions: 6,
            label: devSettings.scrollSpyTop.toStringAsFixed(2),
            onChanged: (v) => ref.read(devToolsSettingsProvider.notifier).setScrollSpyTop(v),
          ),
          Text('Bottom threshold ${devSettings.scrollSpyBottom.toStringAsFixed(2)}'),
          Slider(
            value: devSettings.scrollSpyBottom,
            min: 0.05,
            max: 0.35,
            divisions: 6,
            label: devSettings.scrollSpyBottom.toStringAsFixed(2),
            onChanged: (v) => ref.read(devToolsSettingsProvider.notifier).setScrollSpyBottom(v),
          ),
          const Divider(),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Analytics events'),
            subtitle: const Text('Enable debug analytics logs'),
            value: devSettings.analyticsEnabled,
            onChanged: (v) => ref.read(devToolsSettingsProvider.notifier).setAnalyticsEnabled(v),
          ),
          ListTile(
            leading: const Icon(Icons.analytics_outlined),
            title: const Text('View analytics logs'),
            subtitle: const Text('See recent events'),
            onTap: () => context.go('/analytics/logs'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.cleaning_services_outlined),
            title: const Text('Reset cache'),
            subtitle: const Text('Clear cached data for testing'),
            trailing: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator()) : null,
            onTap: _busy ? null : _resetCache,
          ),
          ListTile(
            leading: const Icon(Icons.settings_backup_restore),
            title: const Text('Reset preferences'),
            subtitle: const Text('Reset theme, language, and currency'),
            trailing: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator()) : null,
            onTap: _busy ? null : _resetPreferences,
          ),
        ],
      ),
    );
  }
}
