import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gwen_app/features/profile/presentation/profile_achievements_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('earned achievements persist', () async {
    SharedPreferences.setMockInitialValues({
      'earned_achievements': ['wishlist_1'],
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final completer = Completer<void>();
    container.listen<Set<String>>(earnedAchievementsProvider, (prev, next) {
      if (next.contains('wishlist_1') && !completer.isCompleted) {
        completer.complete();
      }
    });

    await completer.future.timeout(const Duration(seconds: 1));
    final earned = container.read(earnedAchievementsProvider);
    expect(earned.contains('wishlist_1'), true);
  });
}
