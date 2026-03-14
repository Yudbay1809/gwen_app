import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../home/presentation/home_providers.dart';
import '../../../shared/widgets/product_card.dart';
import '../../cart/presentation/cart_providers.dart';
import '../../../shared/models/product.dart';

enum SectionType { promo, bestSeller, newArrivals, giftCard }

class SectionListScreen extends ConsumerWidget {
  final SectionType type;

  const SectionListScreen({super.key, required this.type});

  String get _title {
    switch (type) {
      case SectionType.promo:
        return 'Promotion';
      case SectionType.bestSeller:
        return 'Best Seller';
      case SectionType.newArrivals:
        return 'New Arrivals';
      case SectionType.giftCard:
        return 'E-Gift Card';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(homeDataProvider);
    final products = switch (type) {
      SectionType.promo => data.flashSale,
      SectionType.bestSeller => data.bestSeller,
      SectionType.newArrivals => data.newArrivals,
      SectionType.giftCard => data.newArrivals,
    };
    final displayProducts = _sortByStock(products);

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.go('/search'),
          ),
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined),
            onPressed: () => context.go('/cart'),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _SectionHeaderContent(
              type: type,
              banners: data.bannerImages,
              productCount: products.length,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: type == SectionType.bestSeller ? 0.68 : 0.62,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final product = displayProducts[index];
                  if (type == SectionType.bestSeller) {
                    return _BestSellerCard(
                      product: product,
                      onTap: () => context.go('/product/${product.id}'),
                      onAdd: () => ref.read(cartProvider.notifier).add(product),
                    );
                  }
                  return ProductCard(
                    product: product,
                    onTap: () => context.go('/product/${product.id}'),
                    onAdd: () => ref.read(cartProvider.notifier).add(product),
                  );
                },
                childCount: displayProducts.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<Product> _sortByStock(List<Product> items) {
  if (items.isEmpty) return items;
  final inStock = items.where((p) => p.stock > 0).toList();
  final outOfStock = items.where((p) => p.stock <= 0).toList();
  return [...inStock, ...outOfStock];
}

class _SectionHeaderContent extends StatelessWidget {
  final SectionType type;
  final List<String> banners;
  final int productCount;

  const _SectionHeaderContent({
    required this.type,
    required this.banners,
    required this.productCount,
  });

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case SectionType.newArrivals:
        return _NewArrivalsHeader(banners: banners);
      case SectionType.promo:
        return _PromoHeader(banners: banners);
      case SectionType.giftCard:
        return _GiftCardHeader(banners: banners, productCount: productCount);
      case SectionType.bestSeller:
        return const _BestSellerHeader();
    }
  }
}

class _BestSellerHeader extends StatelessWidget {
  const _BestSellerHeader();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [scheme.primaryContainer, scheme.secondaryContainer],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scheme.outline),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(12),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_florist, color: scheme.primary, size: 16),
                const SizedBox(width: 8),
                Text(
                  "ALL TIME BESTIE'S PICKS",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: scheme.onPrimaryContainer,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.local_florist, color: scheme.primary, size: 16),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _NewArrivalsHeader extends StatelessWidget {
  final List<String> banners;

  const _NewArrivalsHeader({required this.banners});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cards = [
      _HeroBannerData(
        title: 'SKINTIFIC',
        subtitle: 'Masker buat kulit cerah & terhidrasi maksimal',
        image: banners.isNotEmpty ? banners[0] : null,
        gradient: [scheme.primaryContainer, scheme.secondaryContainer],
      ),
      _HeroBannerData(
        title: 'AEPURA',
        subtitle: 'Rambut halus & berkilau dengan shampoo ini',
        image: banners.length > 1 ? banners[1] : null,
        gradient: [scheme.tertiaryContainer, scheme.primaryContainer],
      ),
      _HeroBannerData(
        title: 'ESPOIR',
        subtitle: 'Lip balm & lip pencil untuk hasil smooth',
        image: banners.length > 2 ? banners[2] : null,
        gradient: [scheme.secondaryContainer, scheme.tertiaryContainer],
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PremiumTag(text: 'Latest drops in GWEN Beauty'),
          const SizedBox(height: 14),
          ...cards.map((c) => _HeroBannerCard(data: c)),
        ],
      ),
    );
  }
}

class _PromoHeader extends StatelessWidget {
  final List<String> banners;

  const _PromoHeader({required this.banners});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Enjoy Daily Treats',
            subtitle: 'Voucher spesial yang ready dipakai hari ini',
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 132,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: banners.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) => _PromoTile(
                image: banners[index],
                label: 'Voucher ${index + 1}',
              ),
            ),
          ),
          const SizedBox(height: 18),
          const _SectionTitle(
            title: 'Partners Promotion',
            subtitle: 'Cicilan & rewards dari partner pilihan',
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 190,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: banners.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) => _PartnerPromoCard(
                title: 'Partner ${index + 1}',
                image: banners[index],
                subtitle: 'Promo terbatas bulan ini',
              ),
            ),
          ),
          const SizedBox(height: 18),
          const _SectionTitle(
            title: 'Featured Promotions',
            subtitle: 'Highlight pilihan tim GWEN Beauty',
          ),
          const SizedBox(height: 10),
          _FeaturedPromoCard(image: banners.isNotEmpty ? banners.first : null),
        ],
      ),
    );
  }
}

class _GiftCardHeader extends StatefulWidget {
  final List<String> banners;
  final int productCount;

  const _GiftCardHeader({required this.banners, required this.productCount});

  @override
  State<_GiftCardHeader> createState() => _GiftCardHeaderState();
}

class _GiftCardHeaderState extends State<_GiftCardHeader> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.86);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chips = ['Terlaris', 'Terbaru', 'Harga: Tinggi - Rendah'];
    final pageCount = widget.banners.isEmpty ? 1 : widget.banners.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('All Product', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('${widget.productCount} Products', style: TextStyle(color: scheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: scheme.outline),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(chips[index], style: TextStyle(color: scheme.onSurface)),
              ),
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemCount: chips.length,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 178,
            child: PageView.builder(
              controller: _pageController,
              itemCount: pageCount,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) {
                final image = widget.banners.isNotEmpty ? widget.banners[index] : null;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _GiftCardHero(image: image),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                pageCount,
                (i) => AnimatedScale(
                  duration: const Duration(milliseconds: 240),
                  scale: i == _currentPage ? 1.2 : 1.0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    width: i == _currentPage ? 20 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: i == _currentPage ? scheme.primary : scheme.outline.withAlpha(120),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: i == _currentPage
                          ? [
                              BoxShadow(
                                color: scheme.primary.withAlpha(80),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBannerData {
  final String title;
  final String subtitle;
  final String? image;
  final List<Color> gradient;

  const _HeroBannerData({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.gradient,
  });
}

class _BestSellerCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  const _BestSellerCard({
    required this.product,
    required this.onTap,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: scheme.surface,
          border: Border.all(color: scheme.outline),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                      child: Image.network(product.image, fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [scheme.primary, scheme.secondaryContainer],
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'BESTSELLER',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Rp ${product.discountPrice.toStringAsFixed(0)}',
                    style: TextStyle(fontWeight: FontWeight.w700, color: scheme.primary),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: onAdd,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        side: BorderSide(color: scheme.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Shop Now'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumTag extends StatelessWidget {
  final String text;

  const _PremiumTag({required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primaryContainer, scheme.secondaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(14),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onPrimaryContainer),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(color: scheme.onSurfaceVariant)),
      ],
    );
  }
}

class _HeroBannerCard extends StatelessWidget {
  final _HeroBannerData data;

  const _HeroBannerCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: data.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.surface.withAlpha(60),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data.subtitle,
                        style: TextStyle(color: scheme.onPrimaryContainer.withAlpha(200)),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: scheme.surface.withAlpha(200),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Shop now',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: scheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(22)),
                child: data.image == null
                    ? Container(
                        color: scheme.surfaceContainerHighest,
                        width: 130,
                        height: 130,
                      )
                    : Image.network(
                        data.image!,
                        width: 130,
                        height: 130,
                        fit: BoxFit.cover,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PromoTile extends StatelessWidget {
  final String image;
  final String label;

  const _PromoTile({required this.image, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(image, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withAlpha(10), Colors.black.withAlpha(120)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              left: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: scheme.surface.withAlpha(230),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  label,
                  style: TextStyle(fontWeight: FontWeight.w700, color: scheme.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PartnerPromoCard extends StatelessWidget {
  final String title;
  final String image;
  final String subtitle;

  const _PartnerPromoCard({
    required this.title,
    required this.image,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 176,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(image, width: double.infinity, height: 96, fit: BoxFit.cover),
          ),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
        ],
      ),
    );
  }
}

class _FeaturedPromoCard extends StatelessWidget {
  final String? image;

  const _FeaturedPromoCard({required this.image});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: image == null
                ? Container(height: 160, color: scheme.surfaceContainerHighest)
                : Image.network(image!, width: double.infinity, height: 160, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('LASH BOSS', style: TextStyle(fontWeight: FontWeight.w800, color: scheme.primary)),
                const SizedBox(height: 6),
                const Text('Disc up to 35% + Extra Vouchers!'),
                const SizedBox(height: 4),
                Text('Berlaku hingga 08 Maret 2026', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GiftCardHero extends StatelessWidget {
  final String? image;

  const _GiftCardHero({required this.image});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (image == null)
              Container(color: scheme.surfaceContainerHighest)
            else
              Image.network(image!, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withAlpha(10), Colors.black.withAlpha(140)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              left: 14,
              bottom: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: scheme.surface.withAlpha(230),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('New Gift Card', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
