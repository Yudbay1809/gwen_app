import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../wishlist/presentation/wishlist_entry_button.dart';
import 'profile_menu_tile.dart';
import 'profile_avatar_provider.dart';
import '../../auth/presentation/auth_state_provider.dart';
import 'loyalty_provider.dart';
import 'daily_checkin_provider.dart';
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
    final scheme = Theme.of(context).colorScheme;
    final auth = ref.watch(authProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: const [WishlistEntryButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          _ProfileHeroCard(
            scheme: scheme,
            isLoggedIn: auth.isLoggedIn,
            onEdit: () => context.go('/profile/edit'),
            onVerify: () => context.go('/login-otp'),
          ),
          const SizedBox(height: 12),
          _ProfileQuickActionGrid(
            actions: [
              _QuickActionData(icon: Icons.receipt_long, label: 'Orders', onTap: () => context.go('/orders')),
              _QuickActionData(icon: Icons.favorite_border, label: 'Wishlist', onTap: () => context.go('/wishlist')),
              _QuickActionData(icon: Icons.confirmation_number_outlined, label: 'Coupons', onTap: () => context.go('/coupons')),
              _QuickActionData(icon: Icons.support_agent, label: 'Support', onTap: () => _showSupportSnack(context)),
            ],
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.redeem_outlined, size: 18, color: scheme.primary),
                      const SizedBox(width: 8),
                      const Text('Referral', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text('Invite friends and get rewards'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: scheme.primary.withValues(alpha: 0.14)),
                        ),
                        child: Text(
                          'GWEN-LOVE',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
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
              padding: const EdgeInsets.all(14),
              child: Consumer(
                builder: (context, ref, _) {
                  final profile = ref.watch(beautyProfileProvider);
                  final profileNotifier = ref.read(beautyProfileProvider.notifier);
                  const skinTypes = ['Normal', 'Dry', 'Oily', 'Combination', 'Sensitive'];
                  const concerns = ['Glow', 'Acne', 'Pores', 'Redness', 'Brightening', 'Hydration'];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome_outlined, size: 18, color: scheme.primary),
                          const SizedBox(width: 8),
                          const Text('Beauty Profile', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Skin Type', style: TextStyle(color: scheme.onSurfaceVariant)),
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
                      Text('Concerns', style: TextStyle(color: scheme.onSurfaceVariant)),
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
            child: const _DailyCheckInCard(),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
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
                            const Text('Orders', style: TextStyle(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text('${orders.length} total'),
                            const SizedBox(height: 8),
                            if (lastOrder != null)
                              Text('Last purchase: ${lastOrder.date}', style: TextStyle(color: scheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Wishlist', style: TextStyle(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text('${wishlist.length} items'),
                            const SizedBox(height: 8),
                            Text(
                              wishlist.isEmpty ? 'No favorites yet' : 'Keep track of what you love',
                              style: TextStyle(color: scheme.onSurfaceVariant),
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
              padding: const EdgeInsets.all(14),
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
                      Row(
                        children: [
                          Icon(Icons.query_stats_outlined, size: 18, color: scheme.primary),
                          const SizedBox(width: 8),
                          const Text('Order Stats', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        ],
                      ),
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
              padding: const EdgeInsets.all(14),
              child: Consumer(
                builder: (context, ref, _) {
                  final loyalty = ref.watch(loyaltyProvider);
                  final history = ref.watch(loyaltyHistoryProvider);
                  final nextTier = loyalty.tier == 'Bronze'
                      ? 'Silver'
                      : (loyalty.tier == 'Silver' ? 'Gold' : 'Gold');
                  final nextTarget = loyalty.tier == 'Bronze'
                      ? 500
                      : (loyalty.tier == 'Silver' ? 1000 : 1000);
                  final remaining = (nextTarget - loyalty.points).clamp(0, nextTarget);

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          scheme.primaryContainer.withValues(alpha: 0.9),
                          scheme.surfaceContainerHighest,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Loyalty ${loyalty.tier}',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: scheme.surface.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.stars, size: 14),
                                  const SizedBox(width: 4),
                                  Text('${loyalty.points} pts', style: const TextStyle(fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          remaining > 0 ? '$remaining points to $nextTier tier' : 'Max tier unlocked',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: loyalty.progress,
                            minHeight: 8,
                            backgroundColor: scheme.surface.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _TierChip(label: 'Bronze', active: loyalty.tier == 'Bronze'),
                            const SizedBox(width: 6),
                            _TierChip(label: 'Silver', active: loyalty.tier == 'Silver'),
                            const SizedBox(width: 6),
                            _TierChip(label: 'Gold', active: loyalty.tier == 'Gold'),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: const [
                            _BenefitPill(icon: Icons.local_shipping_outlined, label: 'Free ship'),
                            SizedBox(width: 8),
                            _BenefitPill(icon: Icons.card_giftcard, label: 'Birthday gift'),
                            SizedBox(width: 8),
                            _BenefitPill(icon: Icons.lock_open, label: 'Early access'),
                          ],
                        ),
                        if (history.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Text('Recent rewards', style: TextStyle(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          ...history.take(2).map(
                                (h) => Row(
                                  children: [
                                    Expanded(child: Text(h.title)),
                                    Text('+${h.points}', style: TextStyle(color: scheme.tertiary)),
                                  ],
                                ),
                              ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                context.go('/loyalty/benefits');
                              },
                              child: const Text('View benefits'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.security_outlined, size: 18, color: scheme.primary),
                      const SizedBox(width: 8),
                      const Text('Security Audit', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const _SecurityItem(label: 'Phone verified', done: true),
                  const _SecurityItem(label: 'Email verified', done: false),
                  const _SecurityItem(label: 'Two-factor enabled', done: false),
                  const _SecurityItem(label: 'Login alerts', done: true),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Consumer(
                builder: (context, ref, _) {
                  final achievements = ref.watch(achievementsProvider);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.emoji_events_outlined, size: 18, color: scheme.primary),
                          const SizedBox(width: 8),
                          const Text('Achievements', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        ],
                      ),
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
                                color: a.unlocked ? scheme.tertiary : scheme.onSurfaceVariant,
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
              padding: const EdgeInsets.all(14),
              child: Consumer(
                builder: (context, ref, _) {
                  final privacy = ref.watch(profilePrivacyProvider);
                  final notifier = ref.read(profilePrivacyProvider.notifier);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.shield_outlined, size: 18, color: scheme.primary),
                          const SizedBox(width: 8),
                          const Text('Privacy & Consent', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        ],
                      ),
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
          const SizedBox(height: 10),
          const _MenuSectionTitle(title: 'Account'),
          Card(
            child: Column(
              children: [
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
                  icon: Icons.person_outline,
                  title: 'Edit Profile',
                  onTap: () => context.go('/profile/edit'),
                ),
                ProfileMenuTile(
                  icon: Icons.lock_outline,
                  title: 'Security',
                  onTap: () => context.go('/profile/security'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const _MenuSectionTitle(title: 'Preferences'),
          Card(
            child: Column(
              children: [
                ProfileMenuTile(
                  icon: Icons.settings,
                  title: 'Preferences',
                  onTap: () => context.go('/profile/preferences'),
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
              ],
            ),
          ),
          const SizedBox(height: 12),
          const _MenuSectionTitle(title: 'System'),
          Card(
            child: Column(
              children: [
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
          ),
        ],
      ),
    );
  }
}

class _ProfileHeroCard extends ConsumerWidget {
  final ColorScheme scheme;
  final bool isLoggedIn;
  final VoidCallback onEdit;
  final VoidCallback onVerify;

  const _ProfileHeroCard({
    required this.scheme,
    required this.isLoggedIn,
    required this.onEdit,
    required this.onVerify,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarUrl = ref.watch(profileAvatarProvider);
    final loyalty = ref.watch(loyaltyProvider);
    final prefs = ref.watch(appPreferencesProvider);
    final profile = ref.watch(beautyProfileProvider);
    final mode = prefs.isDarkMode ? 'Dark' : 'Light';

    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              colors: [
                scheme.primaryContainer,
                Color.lerp(scheme.primaryContainer, scheme.surface, 0.45) ?? scheme.surface,
                scheme.surfaceContainerHighest,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.34)),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          scheme.primary.withValues(alpha: 0.85),
                          scheme.tertiary.withValues(alpha: 0.72),
                        ],
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 31,
                      backgroundColor: scheme.surface,
                      backgroundImage: avatarUrl == null ? null : NetworkImage(avatarUrl),
                      child: avatarUrl == null ? const Icon(Icons.person, size: 30) : null,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isLoggedIn ? 'GWEN Beauty Member' : 'Guest User',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isLoggedIn
                              ? '${loyalty.tier} tier • ${loyalty.points} points'
                              : 'Login to unlock rewards and personalized beauty picks',
                          style: TextStyle(color: scheme.onSurfaceVariant, height: 1.3),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _HeroPill(label: '${prefs.language} • ${prefs.currency}', icon: Icons.language_outlined),
                            _HeroPill(label: '$mode mode', icon: Icons.tune),
                            _HeroPill(
                              label: profile.skinType.isEmpty ? 'Beauty profile pending' : profile.skinType,
                              icon: Icons.auto_awesome_outlined,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: onEdit,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(isLoggedIn ? 'Edit' : 'Login'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _HeroMetric(
                      title: 'Tier',
                      value: isLoggedIn ? loyalty.tier : 'Guest',
                      icon: Icons.workspace_premium_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _HeroMetric(
                      title: 'Points',
                      value: isLoggedIn ? '${loyalty.points}' : '0',
                      icon: Icons.stars_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _HeroMetric(
                      title: 'Focus',
                      value: profile.concerns.isEmpty ? 'Basic' : '${profile.concerns.length} care',
                      icon: Icons.spa_outlined,
                    ),
                  ),
                ],
              ),
              if (isLoggedIn) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: onVerify,
                    icon: const Icon(Icons.verified_outlined, size: 16),
                    label: const Text('Verify account'),
                  ),
                ),
              ],
            ],
          ),
        ),
        const Positioned(
          right: 18,
          top: 16,
          child: _HeroSparkle(),
        ),
        const Positioned(
          right: 52,
          top: 64,
          child: _HeroSparkle(size: 10, delay: 900),
        ),
      ],
    );
  }
}

class _QuickActionData {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionData({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class _ProfileQuickActionGrid extends StatelessWidget {
  final List<_QuickActionData> actions;

  const _ProfileQuickActionGrid({required this.actions});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final itemWidth = (width - 52) / 2;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: actions
          .map(
            (action) => SizedBox(
              width: itemWidth,
              child: InkWell(
                onTap: action.onTap,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.shadow.withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(action.icon, size: 18, color: scheme.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          action.label,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ),
                      Icon(Icons.chevron_right, color: scheme.onSurfaceVariant, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final String label;
  final IconData icon;

  const _HeroPill({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.primary),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _HeroMetric({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontWeight: FontWeight.w800, color: scheme.onSurface)),
          const SizedBox(height: 2),
          Text(title, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _MenuSectionTitle extends StatelessWidget {
  final String title;

  const _MenuSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: scheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        ],
      ),
    );
  }
}

class _DailyCheckInCard extends ConsumerStatefulWidget {
  const _DailyCheckInCard();

  @override
  ConsumerState<_DailyCheckInCard> createState() => _DailyCheckInCardState();
}

class _DailyCheckInCardState extends ConsumerState<_DailyCheckInCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;
  late int _fromStreak;
  late int _toStreak;
  Key _streakKey = UniqueKey();
  late final ProviderSubscription<DailyCheckInState> _checkInSub;

  @override
  void initState() {
    super.initState();
    final initial = ref.read(dailyCheckInProvider);
    _fromStreak = initial.streak;
    _toStreak = initial.streak;
    _checkInSub = ref.listenManual<DailyCheckInState>(dailyCheckInProvider, (prev, next) {
      final prevStreak = prev?.streak ?? next.streak;
      if (prevStreak == next.streak) return;
      setState(() {
        _fromStreak = prevStreak;
        _toStreak = next.streak;
        _streakKey = UniqueKey();
      });
    });
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _checkInSub.close();
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final checkIn = ref.watch(dailyCheckInProvider);
    final checkInNotifier = ref.read(dailyCheckInProvider.notifier);
    final streakLabel = checkIn.streak == 0 ? 'Start your streak' : 'day streak';

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 18, color: scheme.primary),
                    const SizedBox(width: 8),
                    const Text('Daily Check-in', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        '+${checkIn.todayReward} pts',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  checkIn.checkedInToday ? 'You have checked in today.' : 'Check in daily to earn more points.',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          AnimatedBuilder(
                            animation: _shimmer,
                            builder: (context, _) {
                              final alpha = 0.12 + (_shimmer.value * 0.18);
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: alpha),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: TweenAnimationBuilder<int>(
                                  key: _streakKey,
                                  tween: IntTween(begin: _fromStreak, end: _toStreak),
                                  duration: const Duration(milliseconds: 520),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, value, _) => Text(
                                    '$value',
                                    style: const TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                ),
                              );
                            },
                          ),
                          Text(streakLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: checkIn.checkedInToday
                          ? null
                          : () async {
                              await checkInNotifier.checkIn();
                              if (!context.mounted) return;
                              _showCheckInCelebration(context);
                            },
                      child: Text(checkIn.checkedInToday ? 'Come back tomorrow' : 'Check-in'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!checkIn.checkedInToday)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _shimmer,
                  builder: (context, _) {
                    final dx = (_shimmer.value * 2) - 1.0;
                    return FractionalTranslation(
                      translation: Offset(dx, 0),
                      child: Transform.rotate(
                        angle: -0.2,
                        child: Container(
                          width: 140,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                scheme.primary.withValues(alpha: 0.12),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

void _showSupportSnack(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Support is coming soon')),
  );
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

class _SecurityItem extends StatelessWidget {
  final String label;
  final bool done;

  const _SecurityItem({required this.label, required this.done});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(done ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 16, color: done ? scheme.tertiary : scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: scheme.onSurface)),
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
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active ? scheme.primaryContainer : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: active ? scheme.primary : scheme.outlineVariant),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: active ? scheme.primary : scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _BenefitPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BenefitPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: scheme.primary),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _HeroSparkle extends StatefulWidget {
  final double size;
  final int delay;

  const _HeroSparkle({this.size = 14, this.delay = 0});

  @override
  State<_HeroSparkle> createState() => _HeroSparkleState();
}

class _HeroSparkleState extends State<_HeroSparkle> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final scale = 0.9 + (t * 0.25);
        final opacity = 0.4 + (t * 0.5);
        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Icon(
              Icons.auto_awesome,
              size: widget.size,
              color: scheme.tertiary.withValues(alpha: 0.9),
            ),
          ),
        );
      },
    );
  }
}

Future<void> _showCheckInCelebration(BuildContext context) async {
  final scheme = Theme.of(context).colorScheme;
  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.2),
    barrierDismissible: false,
    builder: (_) => Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.9, end: 1),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutBack,
        builder: (context, value, child) => Transform.scale(scale: value, child: child),
        child: Material(
          color: Colors.transparent,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 180,
                height: 180,
                child: CustomPaint(painter: _ConfettiPainter(color: scheme.primary)),
              ),
              Container(
                width: 190,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.shadow.withValues(alpha: 0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, color: scheme.primary, size: 28),
                    const SizedBox(height: 6),
                    const Text('Check-in Success', style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('Points added to your wallet', style: TextStyle(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  await Future.delayed(const Duration(milliseconds: 1100));
  if (context.mounted) Navigator.pop(context);
}

class _ConfettiPainter extends CustomPainter {
  final Color color;

  _ConfettiPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    for (var i = 0; i < 14; i++) {
      final angle = (i / 14) * 6.28318;
      final radius = 60 + (i % 4) * 6;
      final offset = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      paint.color = color.withValues(alpha: 0.75 - (i % 3) * 0.12);
      canvas.drawCircle(offset, 4, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
