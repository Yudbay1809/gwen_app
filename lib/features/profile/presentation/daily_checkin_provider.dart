import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'loyalty_provider.dart';
import '../../notification/presentation/notification_providers.dart';

class DailyCheckInState {
  final int streak;
  final DateTime? lastCheckIn;
  final bool checkedInToday;
  final int todayReward;

  const DailyCheckInState({
    required this.streak,
    required this.lastCheckIn,
    required this.checkedInToday,
    required this.todayReward,
  });
}

class DailyCheckInNotifier extends Notifier<DailyCheckInState> {
  static const _keyLast = 'daily_checkin_last';
  static const _keyStreak = 'daily_checkin_streak';

  @override
  DailyCheckInState build() {
    _load();
    return const DailyCheckInState(
      streak: 0,
      lastCheckIn: null,
      checkedInToday: false,
      todayReward: 12,
    );
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final rawDate = prefs.getString(_keyLast);
    final streak = prefs.getInt(_keyStreak) ?? 0;
    DateTime? last;
    if (rawDate != null) {
      last = DateTime.tryParse(rawDate);
    }
    final checkedInToday = last != null && _isSameDay(last, DateTime.now());
    final reward = _rewardForStreak(checkedInToday ? streak : _nextStreak(streak, last));
    state = DailyCheckInState(
      streak: streak,
      lastCheckIn: last,
      checkedInToday: checkedInToday,
      todayReward: reward,
    );
  }

  int _nextStreak(int current, DateTime? last) {
    if (last == null) return 1;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    if (_isSameDay(last, yesterday)) return current + 1;
    return 1;
  }

  int _rewardForStreak(int streak) {
    final bonus = (streak.clamp(1, 7) - 1) * 2;
    return 12 + bonus;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> checkIn() async {
    if (state.checkedInToday) return;
    final now = DateTime.now();
    final nextStreak = _nextStreak(state.streak, state.lastCheckIn);
    final reward = _rewardForStreak(nextStreak);
    state = DailyCheckInState(
      streak: nextStreak,
      lastCheckIn: now,
      checkedInToday: true,
      todayReward: reward,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLast, now.toIso8601String());
    await prefs.setInt(_keyStreak, nextStreak);

    ref.read(loyaltyProvider.notifier).addPoints(reward);
    ref.read(loyaltyHistoryProvider.notifier).add(
          LoyaltyHistoryItem(
            title: 'Daily check-in',
            date: DateFormat('MMM d, yyyy').format(now),
            points: reward,
          ),
        );

    ref.read(notificationProvider.notifier).addNotification(
          NotificationItem(
            id: DateTime.now().millisecondsSinceEpoch,
            title: 'Daily check-in complete',
            message: 'You earned +$reward points. Streak $nextStreak hari!',
            time: 'just now',
            type: NotificationType.rewards,
            isRead: false,
          ),
        );
  }
}

final dailyCheckInProvider =
    NotifierProvider<DailyCheckInNotifier, DailyCheckInState>(DailyCheckInNotifier.new);
