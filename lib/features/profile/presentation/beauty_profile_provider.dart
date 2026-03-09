import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BeautyProfile {
  final String skinType;
  final Set<String> concerns;

  const BeautyProfile({required this.skinType, required this.concerns});

  BeautyProfile copyWith({String? skinType, Set<String>? concerns}) {
    return BeautyProfile(
      skinType: skinType ?? this.skinType,
      concerns: concerns ?? this.concerns,
    );
  }
}

class BeautyProfileNotifier extends Notifier<BeautyProfile> {
  static const _skinKey = 'beauty_profile_skin_type';
  static const _concernsKey = 'beauty_profile_concerns';

  @override
  BeautyProfile build() {
    _load();
    return const BeautyProfile(skinType: 'Normal', concerns: {'Glow'});
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final skin = prefs.getString(_skinKey) ?? 'Normal';
    final concerns = prefs.getStringList(_concernsKey) ?? <String>['Glow'];
    state = BeautyProfile(skinType: skin, concerns: concerns.toSet());
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_skinKey, state.skinType);
    await prefs.setStringList(_concernsKey, state.concerns.toList());
  }

  void setSkinType(String value) {
    state = state.copyWith(skinType: value);
    _save();
  }

  void toggleConcern(String value) {
    final next = Set<String>.from(state.concerns);
    if (next.contains(value)) {
      next.remove(value);
    } else {
      next.add(value);
    }
    state = state.copyWith(concerns: next);
    _save();
  }
}

final beautyProfileProvider = NotifierProvider<BeautyProfileNotifier, BeautyProfile>(
  BeautyProfileNotifier.new,
);
