import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/price_widget.dart';
import '../../../shared/widgets/rating_stars.dart';
import '../../../shared/widgets/discount_badge.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/cart_badge_button.dart';
import '../../home/presentation/home_providers.dart';
import '../../cart/presentation/cart_providers.dart';
import '../../wishlist/presentation/wishlist_providers.dart';
import '../../review/presentation/review_providers.dart';
import 'recent_viewed_provider.dart';
import 'product_qa_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../shared/models/product.dart';
import 'product_bundle_provider.dart';
import 'product_compare_provider.dart';
import '../../profile/presentation/dev_tools_settings_provider.dart';
import '../../../core/utils/scroll_spy.dart';
import '../../profile/presentation/beauty_profile_provider.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String id;

  const ProductDetailScreen({super.key, required this.id});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  bool _tracked = false;
  final _qaController = TextEditingController();
  final _scrollController = ScrollController();
  final _overviewKey = GlobalKey();
  final _ingredientsKey = GlobalKey();
  final _reviewsKey = GlobalKey();
  final _qaKey = GlobalKey();
  _DetailTab _selectedTab = _DetailTab.overview;
  String _selectedSize = '30ml';
  String _selectedShade = 'Natural';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _qaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(homeDataProvider);
    final productId = int.tryParse(widget.id);
    final product =
        productId == null ? null : data.allProducts.where((p) => p.id == productId).firstOrNull;

    if (product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product')),
        body: const Center(child: Text('Product not found')),
      );
    }

    if (!_tracked) {
      _tracked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(recentViewedProvider.notifier).add(product);
      });
    }

    final hasDiscount = product.discountPrice < product.price;
    final outOfStock = product.stock <= 0;
    final isWishlisted = ref.watch(wishlistProvider).any((e) => e.id == product.id);
    final reviews = ref.watch(reviewFeedProvider).take(3).toList();
    final qaList = ref.watch(productQAProvider)[product.id] ?? const [];
    final qaSorted = [...qaList]..sort((a, b) => b.votes.compareTo(a.votes));
    final recommendations = data.allProducts
        .where((p) => p.categoryId == product.categoryId && p.id != product.id)
        .take(6)
        .toList();
    final bundles = ref.watch(productBundlesProvider);
    final compare = ref.watch(productCompareProvider);
    final isCompared = compare.any((e) => e.id == product.id);
    final beautyProfile = ref.watch(beautyProfileProvider);
    final imageCandidates = [
      product.image,
      '${product.image}&v=2',
      '${product.image}&v=3',
    ];
    final images = imageCandidates.where((e) => e.trim().isNotEmpty).toList();
    if (images.isEmpty) {
      images.add('https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=800&q=80');
    }
    final ingredients = const [
      'Hyaluronic Acid',
      'Niacinamide',
      'Centella Extract',
      'Vitamin E',
    ];
    final warnings = const ['Alcohol', 'Fragrance'];
    final howToUse = const [
      'Apply to clean, dry skin.',
      'Use 2-3 drops and gently pat.',
      'Follow with moisturizer and SPF.',
    ];
    final sizes = const ['15ml', '30ml', '50ml'];
    final shades = const ['Natural', 'Warm', 'Cool'];
    final skinTypes = const ['Normal', 'Dry', 'Combination', 'Sensitive'];
    final faqs = const [
      {'q': 'Is it safe for sensitive skin?', 'a': 'Yes, it is formulated for sensitive skin.'},
      {'q': 'Can I use it daily?', 'a': 'Yes, recommended for daily use.'},
      {'q': 'When should I apply it?', 'a': 'Apply after cleansing and before moisturizer.'},
    ];
    final hasAlcohol = warnings.contains('Alcohol');
    final hasFragrance = warnings.contains('Fragrance');
    final sensitiveSkin = beautyProfile.skinType == 'Sensitive';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              if (context.canPop()) context.pop();
            } else {
              context.go('/shop');
            }
          },
        ),
        title: Text(product.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              _openShareSheet(context, product);
            },
          ),
          IconButton(
            icon: Icon(isCompared ? Icons.check_circle : Icons.compare_arrows),
            onPressed: () {
              ref.read(productCompareProvider.notifier).toggle(product);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(isCompared ? 'Removed from compare' : 'Added to compare')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.table_chart_outlined),
            onPressed: compare.length < 2 ? null : () => context.go('/compare'),
          ),
          IconButton(
            icon: Icon(isWishlisted ? Icons.favorite : Icons.favorite_border),
            onPressed: () {
              ref.read(wishlistProvider.notifier).toggle(product);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(isWishlisted ? 'Removed from wishlist' : 'Added to wishlist')),
              );
            },
          ),
          const CartBadgeButton(),
        ],
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyHeaderDelegate(
              child: _StickyTabs(
                selected: _selectedTab,
                onSelected: (tab) => _scrollTo(tab),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Stack(
              children: [
                if (images.length <= 1)
                  GestureDetector(
                    onTap: () => _openImageGallery(context, images, 0),
                    child: Image.network(
                      images.first,
                      height: 320,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  CarouselSlider(
                    items: images
                        .asMap()
                        .entries
                        .map(
                          (entry) => GestureDetector(
                            onTap: () => _openImageGallery(context, images, entry.key),
                            child: Image.network(
                              entry.value,
                              height: 320,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                        .toList(),
                    options: CarouselOptions(height: 320, viewportFraction: 1),
                  ),
                if (hasDiscount)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: DiscountBadge(
                      text: '-${(((product.price - product.discountPrice) / product.price) * 100).round()}%',
                    ),
                  ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              key: _overviewKey,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  RatingStars(rating: product.rating),
                  const SizedBox(height: 12),
                  PriceWidget(price: product.discountPrice),
                  if (hasDiscount)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Rp ${product.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  const Text('Variant', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: sizes
                        .map(
                          (s) => ChoiceChip(
                            label: Text(s),
                            selected: _selectedSize == s,
                            onSelected: (_) => setState(() => _selectedSize = s),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: shades
                        .map(
                          (s) => ChoiceChip(
                            label: Text(s),
                            selected: _selectedShade == s,
                            onSelected: (_) => setState(() => _selectedShade = s),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Description',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'A lightweight, hydrating formula designed to keep your skin fresh and radiant. '
                    'Suitable for daily use and all skin types.',
                  ),
                  const SizedBox(height: 16),
                  const Text('Skin Type', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: skinTypes
                          .map(
                            (t) => Chip(
                              label: Text(t),
                              backgroundColor: Colors.blueGrey.withAlpha(20),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).colorScheme.outline),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Ingredient Safety', style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _SafetyChip(
                                label: sensitiveSkin ? 'Sensitive: check' : 'Sensitive-friendly',
                                good: !hasAlcohol,
                              ),
                              _SafetyChip(label: 'Alcohol-free', good: !hasAlcohol),
                              _SafetyChip(label: 'Fragrance-free', good: !hasFragrance),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (warnings.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('Ingredient Warnings', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: warnings
                            .map(
                              (w) => Chip(
                                label: Text(w),
                                backgroundColor: Colors.redAccent.withAlpha(20),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  const SizedBox(height: 16),
                  ExpansionTile(
                    key: _ingredientsKey,
                    tilePadding: EdgeInsets.zero,
                    title: const Text('Ingredients', style: TextStyle(fontWeight: FontWeight.w700)),
                    children: ingredients
                        .map(
                          (i) => Padding(
                            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 6),
                            child: Text('- $i'),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: const Text('Ingredients Glossary', style: TextStyle(fontWeight: FontWeight.w700)),
                    children: const [
                      _GlossaryRow(term: 'Hyaluronic Acid', desc: 'Hydration + plumping'),
                      _GlossaryRow(term: 'Niacinamide', desc: 'Brightening + barrier support'),
                      _GlossaryRow(term: 'Centella', desc: 'Soothing + calming'),
                      _GlossaryRow(term: 'Vitamin E', desc: 'Antioxidant protection'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: const Text('Size Guide', style: TextStyle(fontWeight: FontWeight.w700)),
                    children: sizes
                        .map(
                          (s) => Padding(
                            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 6),
                            child: Row(
                              children: [
                                Expanded(child: Text(s)),
                                Text(s == '15ml' ? 'Travel' : s == '30ml' ? 'Standard' : 'Value'),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: const Text('How to Use', style: TextStyle(fontWeight: FontWeight.w700)),
                    children: howToUse
                        .map(
                          (s) => Padding(
                            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 6),
                            child: Text('- '),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  const Text('FAQ', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  ...faqs.map(
                    (f) => ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: Text(f['q']!),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 8, right: 8, bottom: 6),
                          child: Text(f['a']!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    key: _reviewsKey,
                    children: [
                      const Text('Reviews', style: TextStyle(fontWeight: FontWeight.w700)),
                      const Spacer(),
                      TextButton(
                        onPressed: () => context.go('/review/create'),
                        child: const Text('Write review'),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: const [
                      _ReviewHighlightChip(label: 'Hydrating'),
                      _ReviewHighlightChip(label: 'Lightweight'),
                      _ReviewHighlightChip(label: 'Non-sticky'),
                      _ReviewHighlightChip(label: 'Sensitive-safe'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _ReviewSummaryCard(reviews: reviews),
                  const SizedBox(height: 8),
                  _ReviewHeatmap(reviews: reviews),
                  const SizedBox(height: 8),
                  ...reviews.map(
                    (r) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(backgroundImage: NetworkImage(r.userAvatar)),
                      title: Row(
                        children: [
                          Expanded(child: Text(r.userName)),
                          if (r.verifiedPurchase)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified,
                                    size: 12,
                                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Verified',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(r.content),
                      trailing: SizedBox(
                        width: 90,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: RatingStars(rating: r.rating),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    key: _qaKey,
                    child: const Text('Q&A', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 8),
                  if (qaSorted.isEmpty) const Text('No questions yet.'),
                  ...qaSorted.map(
                    (q) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Row(
                        children: [
                          Expanded(child: Text(q.question)),
                          if (qaSorted.isNotEmpty && q == qaSorted.first)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blueGrey.withAlpha(20),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text('Top', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                            ),
                        ],
                      ),
                      subtitle: q.answer == null ? const Text('Awaiting answer') : Text(q.answer!),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${q.votes}'),
                          IconButton(
                            icon: const Icon(Icons.thumb_up_outlined, size: 18),
                            onPressed: () => ref.read(productQAProvider.notifier).upvote(product.id, q.question),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _qaController,
                          decoration: const InputDecoration(hintText: 'Ask a question...'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(productQAProvider.notifier).addQuestion(product.id, _qaController.text);
                          _qaController.clear();
                        },
                        child: const Text('Send'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (bundles.isNotEmpty) ...[
                    const Text('Bundles', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    ...bundles.map(
                      (b) => Card(
                        child: ListTile(
                          title: Text(b.name),
                          subtitle: Text('Save ${(b.discountPct * 100).toInt()}% on ${b.items.length} items'),
                          trailing: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Rp ${b.bundleTotal.toStringAsFixed(0)}'),
                              const SizedBox(height: 4),
                              OutlinedButton(
                                onPressed: () {
                                  for (final item in b.items) {
                                    ref.read(cartProvider.notifier).add(item);
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('${b.name} added to cart')),
                                  );
                                },
                                child: const Text('Add bundle'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (recommendations.isNotEmpty) ...[
                    const Text('You may also like', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 260,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: recommendations.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final rec = recommendations[index];
                          return SizedBox(
                            width: 180,
                            child: ProductCard(
                              product: rec,
                              onTap: () => context.go('/product/${rec.id}'),
                              onAdd: () => ref.read(cartProvider.notifier).add(rec),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PriceWidget(price: product.discountPrice),
                    if (hasDiscount)
                      Text(
                        'Rp ${product.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 44,
                child: AppButton(
                  label: outOfStock ? 'Out of Stock' : 'Add to Cart',
                  onPressed: outOfStock
                      ? null
                      : () {
                          ref.read(cartProvider.notifier).add(product);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Added to cart')),
                          );
                        },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _scrollTo(_DetailTab tab) {
    final key = switch (tab) {
      _DetailTab.overview => _overviewKey,
      _DetailTab.ingredients => _ingredientsKey,
      _DetailTab.reviews => _reviewsKey,
      _DetailTab.qa => _qaKey,
    };
    setState(() => _selectedTab = tab);
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      alignment: 0.1,
    );
  }

  void _handleScroll() {
    final devSettings = ref.read(devToolsSettingsProvider);
    final scores = _sectionVisibility(devSettings);
    if (scores.isEmpty) return;
    final next = _mapSection(pickBestSection(_mapToSections(scores)));
    if (next != _selectedTab) {
      setState(() => _selectedTab = next);
    }
  }

  Map<_DetailTab, double> _sectionVisibility(DevToolsSettingsState devSettings) {
    final map = <_DetailTab, double>{};
    final height = MediaQuery.of(context).size.height;
    final topInset = height * devSettings.scrollSpyTop + MediaQuery.of(context).padding.top;
    final bottomInset = height * devSettings.scrollSpyBottom + MediaQuery.of(context).padding.bottom;
    final viewportTop = topInset;
    final viewportBottom = height - bottomInset;
    if (viewportBottom <= viewportTop) return map;
    for (final entry in {
      _DetailTab.overview: _overviewKey,
      _DetailTab.ingredients: _ingredientsKey,
      _DetailTab.reviews: _reviewsKey,
      _DetailTab.qa: _qaKey,
    }.entries) {
      final ctx = entry.value.currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject();
      if (box is! RenderBox || !box.hasSize) continue;
      final top = box.localToGlobal(Offset.zero).dy;
      final bottom = top + box.size.height;
      final visibleTop = top.clamp(viewportTop, viewportBottom);
      final visibleBottom = bottom.clamp(viewportTop, viewportBottom);
      final visible = (visibleBottom - visibleTop).clamp(0, box.size.height);
      final ratio = visible / box.size.height;
      map[entry.key] = ratio;
    }
    return map;
  }

  Map<ScrollSection, double> _mapToSections(Map<_DetailTab, double> input) {
    return {
      if (input.containsKey(_DetailTab.overview))
        ScrollSection.overview: input[_DetailTab.overview]!,
      if (input.containsKey(_DetailTab.ingredients))
        ScrollSection.ingredients: input[_DetailTab.ingredients]!,
      if (input.containsKey(_DetailTab.reviews))
        ScrollSection.reviews: input[_DetailTab.reviews]!,
      if (input.containsKey(_DetailTab.qa)) ScrollSection.qa: input[_DetailTab.qa]!,
    };
  }

  _DetailTab _mapSection(ScrollSection section) {
    switch (section) {
      case ScrollSection.overview:
        return _DetailTab.overview;
      case ScrollSection.ingredients:
        return _DetailTab.ingredients;
      case ScrollSection.reviews:
        return _DetailTab.reviews;
      case ScrollSection.qa:
        return _DetailTab.qa;
    }
  }
}

enum _DetailTab { overview, ingredients, reviews, qa }

class _ReviewHighlightChip extends StatelessWidget {
  final String label;

  const _ReviewHighlightChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outline),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ReviewHeatmap extends StatelessWidget {
  final List<ReviewItem> reviews;

  const _ReviewHeatmap({required this.reviews});

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return const SizedBox.shrink();
    }
    final scheme = Theme.of(context).colorScheme;
    final counts = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in reviews) {
      final key = r.rating.round().clamp(1, 5);
      counts[key] = (counts[key] ?? 0) + 1;
    }
    final max = counts.values.reduce((a, b) => a > b ? a : b).toDouble();
    return Column(
      children: counts.entries.map((e) {
        final pct = max == 0 ? 0.0 : e.value / max;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              SizedBox(width: 18, child: Text('${e.key}★', style: const TextStyle(fontSize: 11))),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade200,
                    color: scheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${e.value}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ReviewSummaryCard extends StatelessWidget {
  final List<ReviewItem> reviews;

  const _ReviewSummaryCard({required this.reviews});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (reviews.isEmpty) return const SizedBox.shrink();
    final total = reviews.length;
    final avg = reviews.fold<double>(0, (sum, r) => sum + r.rating) / total;
    final verified = reviews.where((r) => r.verifiedPurchase).length;
    final media = reviews.where((r) => r.hasMedia).length;
    final verifiedPct = total == 0 ? 0 : (verified / total * 100).round();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(avg.toStringAsFixed(1), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              RatingStars(rating: avg),
              const SizedBox(height: 4),
              Text('$total reviews', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: scheme.secondary.withValues(alpha: 0.35)),
                ),
                child: Text(
                  '$verifiedPct% verified',
                  style: TextStyle(fontSize: 11, color: scheme.onSecondaryContainer, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 6),
              Text('Media $media', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SafetyChip extends StatelessWidget {
  final String label;
  final bool good;

  const _SafetyChip({required this.label, required this.good});

  @override
  Widget build(BuildContext context) {
    final color = good ? Colors.green : Colors.orange;
    return Chip(
      label: Text(label),
      avatar: Icon(good ? Icons.check_circle : Icons.error_outline, size: 16, color: color),
      backgroundColor: color.withAlpha(18),
      side: BorderSide(color: color.withAlpha(40)),
      labelStyle: TextStyle(color: color),
    );
  }
}

class _GlossaryRow extends StatelessWidget {
  final String term;
  final String desc;

  const _GlossaryRow({required this.term, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(term)),
          Text(desc, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _StickyTabs extends StatelessWidget {
  final _DetailTab selected;
  final ValueChanged<_DetailTab> onSelected;

  const _StickyTabs({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            _TabButton(
              label: 'Overview',
              selected: selected == _DetailTab.overview,
              onTap: () => onSelected(_DetailTab.overview),
            ),
            _TabButton(
              label: 'Ingredients',
              selected: selected == _DetailTab.ingredients,
              onTap: () => onSelected(_DetailTab.ingredients),
            ),
            _TabButton(
              label: 'Reviews',
              selected: selected == _DetailTab.reviews,
              onTap: () => onSelected(_DetailTab.reviews),
            ),
            _TabButton(
              label: 'Q&A',
              selected: selected == _DetailTab.qa,
              onTap: () => onSelected(_DetailTab.qa),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TextButton(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: selected ? Colors.white : Colors.transparent,
          foregroundColor: selected ? Colors.black87 : Colors.black54,
        ),
        onPressed: onTap,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyHeaderDelegate({required this.child});

  @override
  double get minExtent => 56;

  @override
  double get maxExtent => 56;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      elevation: overlapsContent ? 1 : 0,
      color: Colors.white,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}

void _openImageGallery(BuildContext context, List<String> images, int initialIndex) {
  final controller = PageController(initialPage: initialIndex);
  final pageIndex = ValueNotifier<int>(initialIndex);
  showDialog(
    context: context,
    builder: (_) => Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: controller,
              itemCount: images.length,
              onPageChanged: (i) => pageIndex.value = i,
              itemBuilder: (context, index) {
                final url = images[index];
                return InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Center(
                    child: Image.network(url, fit: BoxFit.contain),
                  ),
                );
              },
            ),
            Positioned(
              top: 12,
              left: 12,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: ValueListenableBuilder<int>(
                valueListenable: pageIndex,
                builder: (context, value, _) {
                  return Text(
                    '${value + 1} / ${images.length}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void _openShareSheet(BuildContext context, Product product) {
  final link = 'https://soc0.app/product/${product.id}';
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (_) => SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(product.name, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(link, style: const TextStyle(color: Colors.blueGrey)),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.copy),
            title: const Text('Copy link'),
            onTap: () {
              Clipboard.setData(ClipboardData(text: link));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Product link copied')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.chat_bubble_outline),
            title: const Text('Share to chat'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Shared to chat')),
              );
            },
          ),
        ],
      ),
    ),
  );
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}


