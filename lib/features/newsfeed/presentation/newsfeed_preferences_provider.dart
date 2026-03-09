import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NewsfeedPreferencesNotifier extends Notifier<Set<String>> {
  static const _storageKey = 'newsfeed_muted_topics';

  @override
  Set<String> build() {
    _load();
    return <String>{};
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_storageKey) ?? <String>[];
    state = list.toSet();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, state.toList());
  }

  void toggle(String category) {
    final next = Set<String>.from(state);
    if (next.contains(category)) {
      next.remove(category);
    } else {
      next.add(category);
    }
    state = next;
    _save();
  }
}

final newsfeedPreferencesProvider =
    NotifierProvider<NewsfeedPreferencesNotifier, Set<String>>(NewsfeedPreferencesNotifier.new);

class NewsfeedFollowTopicsNotifier extends Notifier<Set<String>> {
  static const _storageKey = 'newsfeed_follow_topics';

  @override
  Set<String> build() {
    _load();
    return <String>{};
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_storageKey) ?? <String>[];
    state = list.toSet();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, state.toList());
  }

  void toggle(String category) {
    final next = Set<String>.from(state);
    if (next.contains(category)) {
      next.remove(category);
    } else {
      next.add(category);
    }
    state = next;
    _save();
  }
}

final newsfeedFollowTopicsProvider =
    NotifierProvider<NewsfeedFollowTopicsNotifier, Set<String>>(NewsfeedFollowTopicsNotifier.new);

class NewsfeedDigestNotifier extends Notifier<bool> {
  static const _storageKey = 'newsfeed_digest_enabled';

  @override
  bool build() {
    _load();
    return true;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool(_storageKey);
    if (value != null) {
      state = value;
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_storageKey, state);
  }

  void setEnabled(bool value) {
    state = value;
    _save();
  }
}

final newsfeedDigestProvider =
    NotifierProvider<NewsfeedDigestNotifier, bool>(NewsfeedDigestNotifier.new);
