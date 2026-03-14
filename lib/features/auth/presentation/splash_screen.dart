import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'auth_state_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  bool _navigated = false;
  bool _visible = false;
  bool _authReady = false;
  bool _prefsReady = false;
  bool _onboardingSeen = false;
  String _targetRoute = '/onboarding';
  late final AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _tryNavigate();
        }
      });
    _progressController.forward();
    _loadPrefs();
    Future.delayed(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      setState(() => _visible = true);
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _onboardingSeen = prefs.getBool('onboarding_seen') ?? false;
    _prefsReady = true;
    _tryNavigate();
  }

  void _tryNavigate() {
    if (_navigated || !_authReady || !_prefsReady || !_progressController.isCompleted) return;
    _navigated = true;
    if (!mounted) return;
    context.go(_targetRoute);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.isLoading) return;
      if (prev?.isLoading == next.isLoading && prev?.isLoggedIn == next.isLoggedIn) return;
      if (!mounted) return;
      _authReady = true;
      _targetRoute = next.isLoggedIn ? '/shop' : (_onboardingSeen ? '/login' : '/onboarding');
      _tryNavigate();
    });
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [scheme.surface, scheme.primaryContainer],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            opacity: _visible ? 1 : 0,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              scale: _visible ? 1 : 0.96,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 24, offset: const Offset(0, 10)),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/logos/gwen_logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('GWEN Beauty', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  const Text('Glow made effortless', style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: 180,
                    child: AnimatedBuilder(
                      animation: _progressController,
                      builder: (context, _) => LinearProgressIndicator(
                        value: _progressController.value,
                        minHeight: 4,
                        backgroundColor: Colors.black.withAlpha(15),
                        color: scheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
