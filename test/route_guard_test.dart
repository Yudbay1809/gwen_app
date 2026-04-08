import 'package:flutter_test/flutter_test.dart';
import 'package:gwen_app/features/auth/presentation/auth_state_provider.dart';
import 'package:gwen_app/router/route_guard.dart';

void main() {
  test('loading state always redirects to splash except splash path', () {
    const loading = AuthState(isLoggedIn: false, isLoading: true);
    expect(
      resolveRedirect(authState: loading, path: '/shop', justLoggedIn: false),
      '/splash',
    );
    expect(
      resolveRedirect(authState: loading, path: '/splash', justLoggedIn: false),
      isNull,
    );
  });

  test('guest user is redirected to login for protected route', () {
    const guest = AuthState(isLoggedIn: false, isLoading: false);
    expect(
      resolveRedirect(authState: guest, path: '/orders', justLoggedIn: false),
      '/login',
    );
    expect(
      resolveRedirect(authState: guest, path: '/login', justLoggedIn: false),
      isNull,
    );
  });

  test(
    'logged user lands on shop for onboarding/login and just-login state',
    () {
      const logged = AuthState(isLoggedIn: true, isLoading: false);
      expect(
        resolveRedirect(
          authState: logged,
          path: '/onboarding',
          justLoggedIn: false,
        ),
        '/shop',
      );
      expect(
        resolveRedirect(
          authState: logged,
          path: '/profile',
          justLoggedIn: true,
        ),
        '/shop',
      );
    },
  );
}
