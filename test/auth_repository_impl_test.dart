import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gwen_app/features/auth/data/auth_repository_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('auth repository stores login state and clears session keys', () async {
    SharedPreferences.setMockInitialValues({
      'home_all_filter': 'promo',
      'home_all_query': 'serum',
      'home_all_scroll_best': 120.5,
    });
    final repo = AuthRepositoryImpl();

    expect(await repo.isLoggedIn(), false);

    await repo.setLoggedIn(true);
    expect(await repo.isLoggedIn(), true);

    await repo.clearSessionScopedState();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('home_all_filter'), isNull);
    expect(prefs.getString('home_all_query'), isNull);
    expect(prefs.getDouble('home_all_scroll_best'), isNull);
  });
}
