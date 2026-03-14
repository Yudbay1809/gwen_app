import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'router/app_router.dart';
import 'features/auth/presentation/auth_state_provider.dart';
import 'shared/widgets/back_swipe_wrapper.dart';

void main() {
  runApp(const ProviderScope(child: GwenBeautyApp()));
}

class GwenBeautyApp extends ConsumerWidget {
  const GwenBeautyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    routerAuthState = ref.read(authProvider);
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (prev != null && !prev.isLoggedIn && next.isLoggedIn) {
        routerJustLoggedIn = true;
      }
      routerAuthState = next;
      routerAuthRefresh.value++;
    });
    final prefs = ref.watch(appPreferencesProvider);
    return MaterialApp.router(
      title: 'GWEN Beauty',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: prefs.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        final mq = MediaQuery.of(context);
        final insets = mq.viewInsets;
        final clampedInsets = EdgeInsets.fromLTRB(
          math.max(0, insets.left),
          math.max(0, insets.top),
          math.max(0, insets.right),
          math.max(0, insets.bottom),
        );
        return MediaQuery(
          data: mq.copyWith(viewInsets: clampedInsets),
          child: BackSwipeWrapper(child: child),
        );
      },
    );
  }
}
