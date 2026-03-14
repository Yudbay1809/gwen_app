import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  final _pages = const [
    _OnboardPage(
      title: 'BACA REVIEW\nTERPERCAYA',
      subtitle: 'dari REAL USERS & EXPERTS\nsesuai beauty profile-mu',
      image:
          'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=800&q=80',
      badgeLeft: 'Expert Review',
      badgeRight: 'Shopper Review',
    ),
    _OnboardPage(
      title: 'BELANJA CANTIK\nSEMUA PASTI ASLI!',
      subtitle: 'Checkout dan kirim ke rumah atau\nPICK-UP di store terdekatmu.',
      image:
          'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=800&q=80',
      badgeLeft: '100% BPOM',
      badgeRight: 'Pick-up',
    ),
    _OnboardPage(
      title: 'BANYAK\nREWARDS-NYA!',
      subtitle: 'Tukarkan points jadi DISKON\natau freebies eksklusif.',
      image:
          'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=800&q=80',
      badgeLeft: 'SOC0 Points',
      badgeRight: 'XChange',
    ),
    _OnboardPage(
      title: 'WELCOME, BESTIE!',
      subtitle: 'Solusi all-in-one untuk\nkebutuhan beauties-mu!',
      image:
          'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=800&q=80',
      badgeLeft: 'Community',
      badgeRight: 'Tips',
    ),
    _OnboardPage(
      title: 'BREAK FREE\nBersama GWEN',
      subtitle: 'Freebies, voucher, dan promo\napp exclusive menunggumu.',
      image:
          'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=800&q=80',
      badgeLeft: 'FREEBIES',
      badgeRight: '20% OFF',
    ),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
    if (!mounted) return;
    context.go('/login');
  }

  void _next() {
    if (_index == _pages.length - 1) {
      _finish();
      return;
    }
    _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _index = i),
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              final page = _pages[index];
              final pageValue = _controller.hasClients
                  ? (_controller.page ?? _index.toDouble())
                  : _index.toDouble();
              final delta = (pageValue - index).abs().clamp(0.0, 1.0);
              // Smooth easing for fade/slide
              final t = Curves.easeOutCubic.transform(1 - delta);
              return Container(
                color: scheme.primary,
                child: SafeArea(
                  child: Stack(
                    children: [
                      Positioned(
                        top: 40,
                        right: 20,
                        child: _StarRow(),
                      ),
                      Positioned(
                        bottom: 140,
                        left: 0,
                        right: 0,
                        child: Opacity(
                          opacity: t,
                          child: Transform.translate(
                            offset: Offset(0, (1 - t) * 18),
                            child: Image.network(page.image, height: 360, fit: BoxFit.contain),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Opacity(
                              opacity: t,
                              child: Transform.translate(
                                offset: Offset(0, (1 - t) * 10),
                                child: Text(
                                  page.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    height: 1.1,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Opacity(
                              opacity: t,
                              child: Transform.translate(
                                offset: Offset(0, (1 - t) * 8),
                                child: Text(
                                  page.subtitle,
                                  style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.3),
                                ),
                              ),
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                _Badge(text: page.badgeLeft),
                                const SizedBox(width: 8),
                                _Badge(text: page.badgeRight, filled: false),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        _pages.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 340),
                          curve: Curves.easeOutCubic,
                          margin: const EdgeInsets.only(right: 6),
                          width: _index == i ? 18 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _index == i ? Colors.white : Colors.white54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _finish,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.w700),
                      ),
                      child: const Text('SKIP'),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 12, offset: const Offset(0, 6)),
                        ],
                      ),
                      child: IconButton(
                        onPressed: _next,
                        icon: Icon(
                          _index == _pages.length - 1 ? Icons.check : Icons.arrow_forward,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardPage {
  final String title;
  final String subtitle;
  final String image;
  final String badgeLeft;
  final String badgeRight;

  const _OnboardPage({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.badgeLeft,
    required this.badgeRight,
  });
}

class _Badge extends StatelessWidget {
  final String text;
  final bool filled;

  const _Badge({required this.text, this.filled = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: filled ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: filled ? null : Border.all(color: Colors.white70),
      ),
      child: Text(
        text,
        style: TextStyle(color: filled ? Colors.white : Colors.white70, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Icon(Icons.star, color: Colors.white70, size: 14),
        SizedBox(width: 8),
        Icon(Icons.star, color: Colors.white54, size: 10),
        SizedBox(width: 6),
        Icon(Icons.star, color: Colors.white70, size: 12),
      ],
    );
  }
}
