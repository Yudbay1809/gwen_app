import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReviewReply {
  final int id;
  final int? parentId;
  final String text;
  final DateTime createdAt;

  const ReviewReply({
    required this.id,
    required this.parentId,
    required this.text,
    required this.createdAt,
  });
}

class ReviewRepliesNotifier extends Notifier<Map<int, List<ReviewReply>>> {
  static const _storageKey = 'review_replies';
  static const _seedKey = 'review_replies_seeded';
  int _counter = 0;

  @override
  Map<int, List<ReviewReply>> build() {
    _load();
    return {};
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) {
      await _seed(prefs);
      return;
    }
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final mapped = <int, List<ReviewReply>>{};
    var maxId = 0;
    decoded.forEach((key, value) {
      final list = (value as List)
          .map(
            (e) {
              final data = e as Map<String, dynamic>;
              final id = (data['id'] as num?)?.toInt() ?? 0;
              if (id > maxId) maxId = id;
              return ReviewReply(
                id: id,
                parentId: data['parentId'] == null ? null : (data['parentId'] as num).toInt(),
                text: data['text'] as String? ?? '',
                createdAt: DateTime.parse(data['createdAt'] as String),
              );
            },
          )
          .toList();
      mapped[int.parse(key)] = list;
    });
    _counter = maxId;
    state = mapped;
  }

  Future<void> _seed(SharedPreferences prefs) async {
    if (prefs.getBool(_seedKey) == true) return;
    final now = DateTime.now();
    state = {
      1: [
        ReviewReply(id: 1, parentId: null, text: 'Totally agree!', createdAt: now),
        ReviewReply(id: 2, parentId: 1, text: 'Same here, love it.', createdAt: now),
        ReviewReply(id: 3, parentId: null, text: 'Works well for sensitive skin.', createdAt: now),
      ],
      2: [
        ReviewReply(id: 4, parentId: null, text: 'Color payoff is amazing.', createdAt: now),
      ],
      3: [
        ReviewReply(id: 5, parentId: null, text: 'Thanks for the review.', createdAt: now),
        ReviewReply(id: 6, parentId: 5, text: 'I was looking for this.', createdAt: now),
      ],
      4: [
        ReviewReply(id: 7, parentId: null, text: 'Nice scent and gentle.', createdAt: now),
      ],
      5: [
        ReviewReply(id: 8, parentId: null, text: 'Great for daily use.', createdAt: now),
        ReviewReply(id: 9, parentId: 8, text: 'Agree, not sticky.', createdAt: now),
      ],
    };
    _counter = 9;
    await _save();
    await prefs.setBool(_seedKey, true);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = state.map(
      (key, list) => MapEntry(
        key.toString(),
        list
            .map(
              (r) => {
                'id': r.id,
                'parentId': r.parentId,
                'text': r.text,
                'createdAt': r.createdAt.toIso8601String(),
              },
            )
            .toList(),
      ),
    );
    await prefs.setString(_storageKey, jsonEncode(encoded));
  }

  void addReply(int reviewId, String text, {int? parentId}) {
    final t = text.trim();
    if (t.isEmpty) return;
    final list = [...(state[reviewId] ?? const <ReviewReply>[])];
    list.insert(
      0,
      ReviewReply(
        id: ++_counter,
        parentId: parentId,
        text: t,
        createdAt: DateTime.now(),
      ),
    );
    state = {...state, reviewId: list};
    _save();
  }

  int countFor(int reviewId) => (state[reviewId] ?? const <ReviewReply>[]).length;
}

final reviewRepliesProvider =
    NotifierProvider<ReviewRepliesNotifier, Map<int, List<ReviewReply>>>(ReviewRepliesNotifier.new);
