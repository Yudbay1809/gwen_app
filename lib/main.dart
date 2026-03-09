import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'router/app_router.dart';
import 'features/auth/presentation/auth_state_provider.dart';

void main() {
  runApp(const ProviderScope(child: GwenBeautyApp()));
}

class GwenBeautyApp extends ConsumerWidget {
  const GwenBeautyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    routerAuthState = ref.read(authProvider);
    ref.listen<AuthState>(authProvider, (_, next) {
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
    );
  }
}
