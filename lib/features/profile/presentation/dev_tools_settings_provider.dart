import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DevToolsSettingsState {
  final bool homeAnimations;
  final bool reduceMotion;
  final bool homeAltLayout;
  final double scrollSpyTop;
  final double scrollSpyBottom;
  final bool analyticsEnabled;

  const DevToolsSettingsState({
    required this.homeAnimations,
    required this.reduceMotion,
    required this.homeAltLayout,
    required this.scrollSpyTop,
    required this.scrollSpyBottom,
    required this.analyticsEnabled,
  });

  DevToolsSettingsState copyWith({
    bool? homeAnimations,
    bool? reduceMotion,
    bool? homeAltLayout,
    double? scrollSpyTop,
    double? scrollSpyBottom,
    bool? analyticsEnabled,
  }) {
    return DevToolsSettingsState(
      homeAnimations: homeAnimations ?? this.homeAnimations,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      homeAltLayout: homeAltLayout ?? this.homeAltLayout,
      scrollSpyTop: scrollSpyTop ?? this.scrollSpyTop,
      scrollSpyBottom: scrollSpyBottom ?? this.scrollSpyBottom,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
    );
  }
}

class DevToolsSettingsNotifier extends Notifier<DevToolsSettingsState> {
  static const _homeAnimKey = 'dev_home_animations';
  static const _reduceMotionKey = 'dev_reduce_motion';
  static const _homeAltLayoutKey = 'dev_home_alt_layout';
  static const _scrollSpyTopKey = 'dev_scroll_spy_top';
  static const _scrollSpyBottomKey = 'dev_scroll_spy_bottom';
  static const _analyticsKey = 'dev_analytics_enabled';

  @override
  DevToolsSettingsState build() {
    _load();
    return const DevToolsSettingsState(
      homeAnimations: true,
      reduceMotion: false,
      homeAltLayout: false,
      scrollSpyTop: 0.18,
      scrollSpyBottom: 0.12,
      analyticsEnabled: true,
    );
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_homeAnimKey) ?? true;
    final reduce = prefs.getBool(_reduceMotionKey) ?? false;
    final alt = prefs.getBool(_homeAltLayoutKey) ?? false;
    final top = prefs.getDouble(_scrollSpyTopKey) ?? state.scrollSpyTop;
    final bottom = prefs.getDouble(_scrollSpyBottomKey) ?? state.scrollSpyBottom;
    final analytics = prefs.getBool(_analyticsKey) ?? true;
    state = state.copyWith(
      homeAnimations: enabled,
      reduceMotion: reduce,
      homeAltLayout: alt,
      scrollSpyTop: top,
      scrollSpyBottom: bottom,
      analyticsEnabled: analytics,
    );
  }

  Future<void> setHomeAnimations(bool value) async {
    state = state.copyWith(homeAnimations: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_homeAnimKey, value);
  }

  Future<void> setReduceMotion(bool value) async {
    state = state.copyWith(reduceMotion: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reduceMotionKey, value);
  }

  Future<void> setHomeAltLayout(bool value) async {
    state = state.copyWith(homeAltLayout: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_homeAltLayoutKey, value);
  }

  Future<void> setScrollSpyTop(double value) async {
    state = state.copyWith(scrollSpyTop: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_scrollSpyTopKey, value);
  }

  Future<void> setScrollSpyBottom(double value) async {
    state = state.copyWith(scrollSpyBottom: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_scrollSpyBottomKey, value);
  }

  Future<void> setAnalyticsEnabled(bool value) async {
    state = state.copyWith(analyticsEnabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_analyticsKey, value);
  }
}

final devToolsSettingsProvider =
    NotifierProvider<DevToolsSettingsNotifier, DevToolsSettingsState>(DevToolsSettingsNotifier.new);
