import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gwen_app/features/newsfeed/presentation/newsfeed_streak_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('reading streak increments on consecutive days', () async {
    SharedPreferences.setMockInitialValues({});
    var now = DateTime(2026, 3, 8, 10, 0);

    final container = ProviderContainer(
      overrides: [
        nowProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(readingStreakProvider.notifier);
    notifier.registerRead();
    expect(container.read(readingStreakProvider).streak, 1);

    notifier.registerRead();
    expect(container.read(readingStreakProvider).streak, 1);

    now = DateTime(2026, 3, 9, 9, 0);
    notifier.registerRead();
    expect(container.read(readingStreakProvider).streak, 2);

    now = DateTime(2026, 3, 12, 9, 0);
    notifier.registerRead();
    expect(container.read(readingStreakProvider).streak, 1);
  });
}
