import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final nowProvider = Provider<DateTime Function()>((ref) => DateTime.now);

class ReadingStreakState {
  final int streak;
  final DateTime? lastRead;

  const ReadingStreakState({required this.streak, required this.lastRead});
}

class ReadingStreakNotifier extends Notifier<ReadingStreakState> {
  static const _storageKey = 'newsfeed_streak';
  static const _lastReadKey = 'newsfeed_last_read';

  @override
  ReadingStreakState build() {
    _load();
    return const ReadingStreakState(streak: 0, lastRead: null);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final streak = prefs.getInt(_storageKey) ?? 0;
    final lastRaw = prefs.getString(_lastReadKey);
    final last = lastRaw == null ? null : DateTime.tryParse(lastRaw);
    state = ReadingStreakState(streak: streak, lastRead: last);
  }

  Future<void> _save(ReadingStreakState value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_storageKey, value.streak);
    await prefs.setString(_lastReadKey, value.lastRead?.toIso8601String() ?? '');
  }

  void registerRead() {
    final now = ref.read(nowProvider).call();
    final last = state.lastRead;
    if (last == null) {
      final next = ReadingStreakState(streak: 1, lastRead: now);
      state = next;
      _save(next);
      return;
    }
    final days = now.difference(DateTime(last.year, last.month, last.day)).inDays;
    if (days == 0) return;
    if (days == 1) {
      final next = ReadingStreakState(streak: state.streak + 1, lastRead: now);
      state = next;
      _save(next);
    } else {
      final next = ReadingStreakState(streak: 1, lastRead: now);
      state = next;
      _save(next);
    }
  }
}

final readingStreakProvider =
    NotifierProvider<ReadingStreakNotifier, ReadingStreakState>(ReadingStreakNotifier.new);
