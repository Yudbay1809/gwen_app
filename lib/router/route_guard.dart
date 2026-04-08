import 'package:gwen_app/features/auth/presentation/auth_state_provider.dart';

String? resolveRedirect({
  required AuthState? authState,
  required String path,
  required bool justLoggedIn,
}) {
  final isLoading = authState?.isLoading ?? true;
  final isLoggedIn = authState?.isLoggedIn ?? false;
  final isAuthRoute =
      path.startsWith('/login') ||
      path.startsWith('/register') ||
      path.startsWith('/forgot-password') ||
      path.startsWith('/login-otp') ||
      path.startsWith('/otp') ||
      path.startsWith('/complete-profile') ||
      path.startsWith('/onboarding') ||
      path.startsWith('/splash');

  if (isLoading) {
    return path == '/splash' ? null : '/splash';
  }
  if (justLoggedIn && isLoggedIn && path != '/shop') {
    return '/shop';
  }
  if (!isLoggedIn && !isAuthRoute) {
    return '/login';
  }
  if (isLoggedIn && (path == '/login' || path == '/onboarding')) {
    return '/shop';
  }
  return null;
}
