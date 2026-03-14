import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoyaltyState {
  final int points;

  const LoyaltyState({required this.points});

  String get tier {
    if (points >= 1000) return 'Gold';
    if (points >= 500) return 'Silver';
    return 'Bronze';
  }

  double get progress {
    if (tier == 'Gold') return 1;
    if (tier == 'Silver') return (points - 500) / 500;
    return points / 500;
  }
}

class LoyaltyNotifier extends Notifier<LoyaltyState> {
  static const _storageKey = 'loyalty_points';

  @override
  LoyaltyState build() {
    _load();
    return const LoyaltyState(points: 320);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_storageKey);
    if (saved == null) return;
    state = LoyaltyState(points: saved);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_storageKey, state.points);
  }

  void addPoints(int delta) {
    final next = (state.points + delta).clamp(0, 99999);
    state = LoyaltyState(points: next);
    _save();
  }
}

final loyaltyProvider = NotifierProvider<LoyaltyNotifier, LoyaltyState>(LoyaltyNotifier.new);

class LoyaltyHistoryItem {
  final String title;
  final String date;
  final int points;

  const LoyaltyHistoryItem({required this.title, required this.date, required this.points});

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'date': date,
      'points': points,
    };
  }

  factory LoyaltyHistoryItem.fromJson(Map<String, dynamic> json) {
    return LoyaltyHistoryItem(
      title: json['title'] as String,
      date: json['date'] as String,
      points: (json['points'] as num).toInt(),
    );
  }
}

class LoyaltyHistoryNotifier extends Notifier<List<LoyaltyHistoryItem>> {
  static const _storageKey = 'loyalty_history';

  @override
  List<LoyaltyHistoryItem> build() {
    _load();
    return _seed();
  }

  List<LoyaltyHistoryItem> _seed() {
    return const [
      LoyaltyHistoryItem(title: 'Order ORD-1021', date: 'Mar 7, 2026', points: 120),
      LoyaltyHistoryItem(title: 'Review reward', date: 'Mar 5, 2026', points: 40),
      LoyaltyHistoryItem(title: 'Order ORD-1004', date: 'Feb 20, 2026', points: 160),
    ];
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey);
    if (raw == null || raw.isEmpty) {
      await _save(_seed());
      return;
    }
    final list = <LoyaltyHistoryItem>[];
    for (final entry in raw) {
      try {
        list.add(LoyaltyHistoryItem.fromJson(jsonDecode(entry) as Map<String, dynamic>));
      } catch (_) {}
    }
    if (list.isNotEmpty) state = list;
  }

  Future<void> _save(List<LoyaltyHistoryItem> value) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = value.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_storageKey, raw);
  }

  void add(LoyaltyHistoryItem item) {
    state = [item, ...state].take(6).toList();
    _save(state);
  }
}

final loyaltyHistoryProvider =
    NotifierProvider<LoyaltyHistoryNotifier, List<LoyaltyHistoryItem>>(LoyaltyHistoryNotifier.new);
