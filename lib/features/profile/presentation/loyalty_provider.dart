import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  @override
  LoyaltyState build() => const LoyaltyState(points: 320);
}

final loyaltyProvider = NotifierProvider<LoyaltyNotifier, LoyaltyState>(LoyaltyNotifier.new);

class LoyaltyHistoryItem {
  final String title;
  final String date;
  final int points;

  const LoyaltyHistoryItem({required this.title, required this.date, required this.points});
}

final loyaltyHistoryProvider = Provider<List<LoyaltyHistoryItem>>((ref) {
  return const [
    LoyaltyHistoryItem(title: 'Order ORD-1021', date: 'Mar 7, 2026', points: 120),
    LoyaltyHistoryItem(title: 'Review reward', date: 'Mar 5, 2026', points: 40),
    LoyaltyHistoryItem(title: 'Order ORD-1004', date: 'Feb 20, 2026', points: 160),
  ];
});
