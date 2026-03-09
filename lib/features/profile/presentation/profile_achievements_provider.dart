import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../wishlist/presentation/wishlist_providers.dart';
import '../../orders/presentation/orders_providers.dart';
import '../../review/presentation/review_providers.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final bool unlocked;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.unlocked,
  });
}

class EarnedAchievementsNotifier extends Notifier<Set<String>> {
  static const _storageKey = 'earned_achievements';

  @override
  Set<String> build() {
    _load();
    return <String>{};
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey);
    if (!ref.mounted) return;
    if (raw != null) {
      state = raw.toSet();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, state.toList());
  }

  Future<void> mark(String id) async {
    if (state.contains(id)) return;
    state = {...state, id};
    await _save();
  }
}

final earnedAchievementsProvider =
    NotifierProvider<EarnedAchievementsNotifier, Set<String>>(EarnedAchievementsNotifier.new);

final achievementsProvider = Provider<List<Achievement>>((ref) {
  final wishlistCount = ref.watch(wishlistProvider).length;
  final ordersCount = ref.watch(ordersProvider).length;
  final reviewCount = ref.watch(reviewFeedProvider).length;
  final earned = ref.watch(earnedAchievementsProvider);

  final defs = [
    _AchievementDef(id: 'wishlist_1', title: 'First Wishlist', description: 'Save your first product', target: 1),
    _AchievementDef(id: 'wishlist_5', title: 'Collector', description: 'Save 5 products', target: 5),
    _AchievementDef(id: 'orders_1', title: 'First Order', description: 'Complete 1 order', target: 1),
    _AchievementDef(id: 'review_3', title: 'Review Star', description: 'Write 3 reviews', target: 3),
  ];

  return defs.map((def) {
    final count = switch (def.id) {
      'wishlist_1' || 'wishlist_5' => wishlistCount,
      'orders_1' => ordersCount,
      'review_3' => reviewCount,
      _ => 0,
    };
    final unlocked = earned.contains(def.id) || count >= def.target;
    if (count >= def.target) {
      ref.read(earnedAchievementsProvider.notifier).mark(def.id);
    }
    return Achievement(
      id: def.id,
      title: def.title,
      description: def.description,
      unlocked: unlocked,
    );
  }).toList();
});

class _AchievementDef {
  final String id;
  final String title;
  final String description;
  final int target;

  const _AchievementDef({
    required this.id,
    required this.title,
    required this.description,
    required this.target,
  });
}
