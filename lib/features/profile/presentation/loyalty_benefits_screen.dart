import 'package:flutter/material.dart';
import 'dart:ui';

class LoyaltyBenefitsScreen extends StatefulWidget {
  const LoyaltyBenefitsScreen({super.key});

  @override
  State<LoyaltyBenefitsScreen> createState() => _LoyaltyBenefitsScreenState();
}

class _LoyaltyBenefitsScreenState extends State<LoyaltyBenefitsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loyalty Benefits'),
      ),
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        children: [
          _CinematicHeroBanner(scheme: scheme, scrollController: _scrollController),
          const SizedBox(height: 16),
          const _SectionTitle('Tier perks'),
          const SizedBox(height: 8),
          const _TierPerkCard(
            title: 'Bronze',
            subtitle: 'Starter perks for every member',
            perks: ['Point cashback', 'Basic vouchers', 'Standard support'],
          ),
          const SizedBox(height: 10),
          const _TierPerkCard(
            title: 'Silver',
            subtitle: 'More rewards, more priority',
            perks: ['Free shipping min. spend', 'Monthly vouchers', 'Priority support'],
          ),
          const SizedBox(height: 10),
          const _TierPerkCard(
            title: 'Gold',
            subtitle: 'Premium access & exclusive gifts',
            perks: ['Free shipping', 'Exclusive drops', 'Birthday gift box'],
          ),
          const SizedBox(height: 16),
          const _SectionTitle('How to earn points'),
          const SizedBox(height: 8),
          const _EarnRow(icon: Icons.shopping_bag_outlined, title: 'Shop', value: '1 point / Rp 1.000'),
          const _EarnRow(icon: Icons.rate_review_outlined, title: 'Review', value: '+40 points'),
          const _EarnRow(icon: Icons.auto_awesome, title: 'Daily check-in', value: '+12 ~ +24 points'),
          const SizedBox(height: 16),
          const _SectionTitle('Redeem rewards'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Use points for', style: TextStyle(fontWeight: FontWeight.w700)),
                SizedBox(height: 6),
                Text('• Voucher discounts'),
                Text('• Limited freebies'),
                Text('• Shipping credits'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _SectionTitle('FAQ'),
          const SizedBox(height: 8),
          const _FaqTile(
            title: 'When do points expire?',
            body: 'Points expire in 12 months if there is no activity.',
          ),
          const _FaqTile(
            title: 'How do I keep my tier?',
            body: 'Maintain your tier by collecting points each year.',
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16));
  }
}

class _CinematicHeroBanner extends StatefulWidget {
  final ColorScheme scheme;
  final ScrollController scrollController;

  const _CinematicHeroBanner({required this.scheme, required this.scrollController});

  @override
  State<_CinematicHeroBanner> createState() => _CinematicHeroBannerState();
}

class _CinematicHeroBannerState extends State<_CinematicHeroBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glow;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = widget.scheme;
    final controller = widget.scrollController;
    return Stack(
      children: [
        SizedBox(
          height: 210,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                final offset = controller.hasClients ? controller.offset : 0.0;
                final parallax = (offset / 240).clamp(-0.25, 0.25);
                final blur = (offset / 100).clamp(0.0, 6.0);
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Align(
                      alignment: Alignment(0, -0.2 + parallax),
                      child: Image.network(
                        'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=1200&q=80',
                        fit: BoxFit.cover,
                      ),
                    ),
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                      child: Container(color: Colors.transparent),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.45),
                  scheme.primary.withValues(alpha: 0.55),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.45),
                  scheme.primary.withValues(alpha: 0.55),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        Positioned(
          right: 22,
          top: 22,
          child: AnimatedBuilder(
            animation: _glow,
            builder: (context, _) {
              final t = _glow.value;
              final glowAlpha = 0.3 + (t * 0.4);
              return Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      scheme.secondary.withValues(alpha: 0.9),
                      scheme.primary.withValues(alpha: 0.9),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.secondary.withValues(alpha: glowAlpha),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.workspace_premium_outlined, color: Colors.white, size: 28),
              );
            },
          ),
        ),
        Positioned(
          left: 18,
          bottom: 16,
          right: 18,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Gwen Rewards',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: scheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: scheme.secondary.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Premium',
                        style: TextStyle(
                          color: scheme.secondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Earn points for every order and unlock exclusive perks.',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 10),
                Row(
                  children: const [
                    _BenefitCard(icon: Icons.local_shipping_outlined, label: 'Free shipping'),
                    SizedBox(width: 8),
                    _BenefitCard(icon: Icons.card_giftcard, label: 'Birthday gift'),
                    SizedBox(width: 8),
                    _BenefitCard(icon: Icons.lock_open, label: 'Early access'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BenefitCard extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BenefitCard({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            Icon(icon, color: scheme.primary, size: 20),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _TierPerkCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<String> perks;

  const _TierPerkCard({required this.title, required this.subtitle, required this.perks});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          ...perks.map((p) => Text('• $p')),
        ],
      ),
    );
  }
}

class _EarnRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _EarnRow({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700))),
          Text(value, style: TextStyle(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String title;
  final String body;

  const _FaqTile({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(body, style: TextStyle(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
