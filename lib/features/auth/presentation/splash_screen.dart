import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'auth_state_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  bool _navigated = false;
  bool _visible = false;
  bool _authReady = false;
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

  void _tryNavigate() {
    if (_navigated || !_authReady || !_progressController.isCompleted) return;
    _navigated = true;
    if (!mounted) return;
    context.go(_targetRoute);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.isLoading) return;
      if (prev?.isLoading == next.isLoading && prev?.isLoggedIn == next.isLoggedIn) return;
      if (!mounted) return;
      _authReady = true;
      _targetRoute = next.isLoggedIn ? '/shop' : '/onboarding';
      _tryNavigate();
    });
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF1E9), Color(0xFFFDE7F1)],
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
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 20, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: const Icon(Icons.spa_outlined, size: 36, color: Colors.pinkAccent),
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
                        color: Colors.pinkAccent,
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
