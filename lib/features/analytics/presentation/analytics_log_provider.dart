import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../profile/presentation/dev_tools_settings_provider.dart';

class AnalyticsLogNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [];

  void log(String message) {
    final enabled = ref.read(devToolsSettingsProvider).analyticsEnabled;
    if (!enabled) return;
    final next = [message, ...state];
    state = next.take(50).toList();
  }

  void clear() => state = [];
}

final analyticsLogProvider =
    NotifierProvider<AnalyticsLogNotifier, List<String>>(AnalyticsLogNotifier.new);
