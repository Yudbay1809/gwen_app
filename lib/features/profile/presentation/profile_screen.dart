import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../wishlist/presentation/wishlist_entry_button.dart';
import 'profile_menu_tile.dart';
import 'profile_avatar_provider.dart';
import '../../auth/presentation/auth_state_provider.dart';
import 'loyalty_provider.dart';
import '../../wishlist/presentation/wishlist_providers.dart';
import '../../../core/theme/theme_provider.dart';
import 'profile_achievements_provider.dart';
import 'settings_storage_provider.dart';
import '../../orders/presentation/orders_providers.dart';
import 'profile_privacy_provider.dart';
import 'beauty_profile_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: const [WishlistEntryButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: ref.watch(profileAvatarProvider) == null
                        ? null
                        : NetworkImage(ref.watch(profileAvatarProvider)!),
                    child: ref.watch(profileAvatarProvider) == null
                        ? const Icon(Icons.person, size: 28)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Consumer(
                      builder: (context, ref, _) {
                        final loyalty = ref.watch(loyaltyProvider);
                        final prefs = ref.watch(appPreferencesProvider);
                        final mode = prefs.isDarkMode ? 'Dark' : 'Light';
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('GWEN Beauty Member',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text('${loyalty.tier} • ${loyalty.points} pts',
                                style: const TextStyle(color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(
                              '${prefs.language} • ${prefs.currency} • $mode mode',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/profile/edit'),
                    child: const Text('Edit'),
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Referral', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  const Text('Invite friends and get rewards'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.pinkAccent.withAlpha(18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('GWEN-LOVE', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          Clipboard.setData(const ClipboardData(text: 'GWEN-LOVE'));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Referral code copied')),
                          );
                        },
                        child: const Text('Copy'),
                      ),
                      TextButton(
                        onPressed: () {
                          Clipboard.setData(const ClipboardData(text: 'Join GWEN Beauty with code GWEN-LOVE'));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Share text copied')),
                          );
                        },
                        child: const Text('Share'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Consumer(
                builder: (context, ref, _) {
                  final profile = ref.watch(beautyProfileProvider);
                  final profileNotifier = ref.read(beautyProfileProvider.notifier);
                  const skinTypes = ['Normal', 'Dry', 'Oily', 'Combination', 'Sensitive'];
                  const concerns = ['Glow', 'Acne', 'Pores', 'Redness', 'Brightening', 'Hydration'];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Beauty Profile', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      const Text('Skin Type', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: skinTypes
                            .map(
                              (s) => ChoiceChip(
                                label: Text(s),
                                selected: profile.skinType == s,
                                onSelected: (_) => profileNotifier.setSkinType(s),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 10),
                      const Text('Concerns', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: concerns
                            .map(
                              (c) => FilterChip(
                                label: Text(c),
                                selected: profile.concerns.contains(c),
                                onSelected: (_) => profileNotifier.toggleConcern(c),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Consumer(
                builder: (context, ref, _) {
                  final wishlist = ref.watch(wishlistProvider);
                  final orders = ref.watch(ordersProvider);
                  final lastOrder = orders.isNotEmpty ? orders.first : null;
                  return Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Orders', style: TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text('${orders.length} total'),
                            const SizedBox(height: 8),
                            if (lastOrder != null)
                              Text('Last purchase: ${lastOrder.date}', style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Wishlist', style: TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text('${wishlist.length} items'),
                            const SizedBox(height: 8),
                            Text(
                              wishlist.isEmpty ? 'No favorites yet' : 'Keep track of what you love',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Consumer(
                builder: (context, ref, _) {
                  final orders = ref.watch(ordersProvider);
                  final formatter = DateFormat('MMM d, yyyy');
                  final now = DateTime.now();
                  var monthCount = 0;
                  var yearCount = 0;
                  var monthTotal = 0.0;
                  var yearTotal = 0.0;
                  for (final o in orders) {
                    DateTime? date;
                    try {
                      date = formatter.parse(o.date);
                    } catch (_) {
                      date = null;
                    }
                    if (date == null) continue;
                    if (date.year == now.year) {
                      yearCount += 1;
                      yearTotal += o.total;
                      if (date.month == now.month) {
                        monthCount += 1;
                        monthTotal += o.total;
                      }
                    }
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Order Stats', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: Text('This month: $monthCount orders')),
                          Text('Rp ${monthTotal.toStringAsFixed(0)}'),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(child: Text('This year: $yearCount orders')),
                          Text('Rp ${yearTotal.toStringAsFixed(0)}'),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Consumer(
                builder: (context, ref, _) {
                  final loyalty = ref.watch(loyaltyProvider);
                  final history = ref.watch(loyaltyHistoryProvider);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Loyalty ${loyalty.tier}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text('${loyalty.points} points'),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: loyalty.progress),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _TierChip(label: 'Bronze', active: loyalty.tier == 'Bronze'),
                          const SizedBox(width: 6),
                          _TierChip(label: 'Silver', active: loyalty.tier == 'Silver'),
                          const SizedBox(width: 6),
                          _TierChip(label: 'Gold', active: loyalty.tier == 'Gold'),
                        ],
                      ),
                      if (history.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text('Loyalty History', style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        ...history.map(
                          (h) => Row(
                            children: [
                              Expanded(child: Text(h.title)),
                              Text('+${h.points}', style: const TextStyle(color: Colors.green)),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      const Text('Activity Log', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      const Text('Last login: Mar 8, 2026 14:21', style: TextStyle(color: Colors.grey)),
                      const Text('Profile updated: Mar 7, 2026 09:12', style: TextStyle(color: Colors.grey)),
                    ],
                  );
                },
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Security Audit', style: TextStyle(fontWeight: FontWeight.w700)),
                  SizedBox(height: 8),
                  _SecurityItem(label: 'Phone verified', done: true),
                  _SecurityItem(label: 'Email verified', done: false),
                  _SecurityItem(label: 'Two-factor enabled', done: false),
                  _SecurityItem(label: 'Login alerts', done: true),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Consumer(
                builder: (context, ref, _) {
                  final achievements = ref.watch(achievementsProvider);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Achievements', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      ...achievements.map(
                        (a) => Row(
                          children: [
                            Icon(a.unlocked ? Icons.emoji_events : Icons.lock, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(a.title)),
                            Text(
                              a.unlocked ? 'Unlocked' : 'Locked',
                              style: TextStyle(
                                color: a.unlocked ? Colors.green : Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Consumer(
                builder: (context, ref, _) {
                  final privacy = ref.watch(profilePrivacyProvider);
                  final notifier = ref.read(profilePrivacyProvider.notifier);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Privacy & Consent', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Marketing emails'),
                        value: privacy.marketingEmails,
                        onChanged: notifier.setMarketingEmails,
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('App notifications'),
                        value: privacy.appNotifications,
                        onChanged: notifier.setAppNotifications,
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Data sharing'),
                        value: privacy.dataSharing,
                        onChanged: notifier.setDataSharing,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundImage: ref.watch(profileAvatarProvider) == null
                      ? null
                      : NetworkImage(ref.watch(profileAvatarProvider)!),
                  child: ref.watch(profileAvatarProvider) == null
                      ? const Icon(Icons.person, size: 36)
                      : null,
                ),
                if (ref.watch(profileAvatarProvider) != null)
                  Positioned(
                    left: 0,
                    bottom: 0,
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _confirmRemoveAvatar(context, ref),
                    ),
                  ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt),
                    onPressed: () async {
                      final picker = ImagePicker();
                      final file = await picker.pickImage(source: ImageSource.gallery);
                      if (!context.mounted) return;
                      if (file != null) {
                        final approved = await _showCropDialog(context, file.path);
                        if (!context.mounted) return;
                        if (approved) {
                          ref.read(profileAvatarProvider.notifier).set(file.path);
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Center(child: Text('Guest User', style: TextStyle(fontWeight: FontWeight.w700))),
          const SizedBox(height: 24),
          ProfileMenuTile(
            icon: Icons.favorite_border,
            title: 'Wishlist',
            onTap: () => context.go('/wishlist'),
          ),
          ProfileMenuTile(
            icon: Icons.receipt_long,
            title: 'Orders',
            onTap: () => context.go('/orders'),
          ),
          ProfileMenuTile(
            icon: Icons.confirmation_number_outlined,
            title: 'Coupons Center',
            onTap: () => context.go('/coupons'),
          ),
          ProfileMenuTile(
            icon: Icons.notifications_none,
            title: 'Notifications',
            onTap: () => context.go('/notifications'),
          ),
          ProfileMenuTile(
            icon: Icons.tune,
            title: 'Notification Settings',
            onTap: () => context.go('/notifications/settings'),
          ),
          ProfileMenuTile(
            icon: Icons.settings,
            title: 'Preferences',
            onTap: () => context.go('/profile/preferences'),
          ),
          ProfileMenuTile(
            icon: Icons.person_outline,
            title: 'Edit Profile',
            onTap: () => context.go('/profile/edit'),
          ),
          ProfileMenuTile(
            icon: Icons.lock_outline,
            title: 'Security',
            onTap: () => context.go('/profile/security'),
          ),
          ProfileMenuTile(
            icon: Icons.location_on_outlined,
            title: 'Address Book',
            onTap: () => context.go('/profile/addresses'),
          ),
          ProfileMenuTile(
            icon: Icons.credit_card,
            title: 'Payment Methods',
            onTap: () => context.go('/profile/payments'),
          ),
          ProfileMenuTile(
            icon: Icons.store_mall_directory_outlined,
            title: 'Store Locator',
            onTap: () => context.go('/stores'),
          ),
          ProfileMenuTile(
            icon: Icons.manage_search,
            title: 'Global Search',
            onTap: () => context.go('/global-search'),
          ),
          ProfileMenuTile(
            icon: Icons.developer_mode,
            title: 'Dev Tools',
            onTap: () => context.go('/dev'),
          ),
          ProfileMenuTile(
            icon: Icons.file_download_outlined,
            title: 'Export My Data',
            onTap: () => _exportData(context, ref),
          ),
          ProfileMenuTile(
            icon: Icons.cloud_upload_outlined,
            title: 'Backup Settings',
            onTap: () => _backupSettings(context, ref),
          ),
          ProfileMenuTile(
            icon: Icons.logout,
            title: 'Logout',
            onTap: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
          ),
          ProfileMenuTile(
            icon: Icons.delete_forever,
            title: 'Delete Account',
            onTap: () => _confirmDeleteAccount(context, ref),
          ),
        ],
      ),
    );
  }
}

Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Delete account'),
      content: const Text('This will remove local data and log you out. Continue?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
      ],
    ),
  );
  if (result != true) return;
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  await ref.read(authProvider.notifier).logout();
  if (context.mounted) {
    context.go('/login');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Account deleted')),
    );
  }
}

Future<void> _exportData(BuildContext context, WidgetRef ref) async {
  final prefs = ref.read(appPreferencesProvider);
  final wishlist = ref.read(wishlistProvider);
  final loyalty = ref.read(loyaltyProvider);
  final payload = {
    'exportedAt': DateTime.now().toIso8601String(),
    'preferences': {
      'darkMode': prefs.isDarkMode,
      'language': prefs.language,
      'currency': prefs.currency,
    },
    'wishlistCount': wishlist.length,
    'loyalty': {
      'tier': loyalty.tier,
      'points': loyalty.points,
    },
  };

  final jsonText = const JsonEncoder.withIndent('  ').convert(payload);
  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Export Data'),
      content: SingleChildScrollView(
        child: SelectableText(jsonText, style: const TextStyle(fontSize: 12)),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ElevatedButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: jsonText));
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Data copied to clipboard')),
            );
          },
          child: const Text('Copy'),
        ),
      ],
    ),
  );
}

Future<void> _backupSettings(BuildContext context, WidgetRef ref) async {
  final prefs = ref.read(appPreferencesProvider);
  final storage = ref.read(storageUsageProvider);
  final payload = {
    'backupAt': DateTime.now().toIso8601String(),
    'preferences': {
      'darkMode': prefs.isDarkMode,
      'language': prefs.language,
      'currency': prefs.currency,
    },
    'storage': {
      'usedMb': storage.usedMb,
      'totalMb': storage.totalMb,
    },
    'notes': 'Dummy backup payload for local settings',
  };

  final jsonText = const JsonEncoder.withIndent('  ').convert(payload);
  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Backup Settings'),
      content: SingleChildScrollView(
        child: SelectableText(jsonText, style: const TextStyle(fontSize: 12)),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ElevatedButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: jsonText));
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Backup copied to clipboard')),
            );
          },
          child: const Text('Copy'),
        ),
      ],
    ),
  );
}

Future<bool> _showCropDialog(BuildContext context, String path) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Crop photo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade200,
              border: Border.all(color: Colors.grey.shade300),
            ),
            clipBehavior: Clip.antiAlias,
            child: kIsWeb
                ? const Center(child: Text('Preview unavailable on web', textAlign: TextAlign.center))
                : Image.file(File(path), fit: BoxFit.cover),
          ),
          const SizedBox(height: 12),
          const Text('Preview crop area (dummy).'),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Use photo')),
      ],
    ),
  );
  return result ?? false;
}

Future<void> _confirmRemoveAvatar(BuildContext context, WidgetRef ref) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Remove avatar'),
      content: const Text('Do you want to remove your profile photo?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
      ],
    ),
  );
  if (result == true) {
    ref.read(profileAvatarProvider.notifier).set(null);
  }
}

class _SecurityItem extends StatelessWidget {
  final String label;
  final bool done;

  const _SecurityItem({required this.label, required this.done});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(done ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 16, color: done ? Colors.green : Colors.grey),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

class _TierChip extends StatelessWidget {
  final String label;
  final bool active;

  const _TierChip({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active ? Colors.pinkAccent.withAlpha(24) : Colors.grey.withAlpha(16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: active ? Colors.pinkAccent : Colors.grey.withAlpha(60)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: active ? Colors.pinkAccent : Colors.grey,
        ),
      ),
    );
  }
}
