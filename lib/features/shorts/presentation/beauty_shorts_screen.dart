import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/full_screen_shimmer.dart';
import '../../../shared/widgets/price_widget.dart';
import '../../../shared/widgets/rating_stars.dart';
import '../../../shared/models/product.dart';
import '../../home/presentation/home_providers.dart';
import '../../cart/presentation/cart_providers.dart';
import '../../wishlist/presentation/wishlist_providers.dart';

class BeautyShortsScreen extends ConsumerStatefulWidget {
  const BeautyShortsScreen({super.key});

  @override
  ConsumerState<BeautyShortsScreen> createState() => _BeautyShortsScreenState();
}

class _BeautyShortsScreenState extends ConsumerState<BeautyShortsScreen>
    with TickerProviderStateMixin {
  final PageController _controller = PageController();
  late final AnimationController _progressController;
  bool _muted = true;
  bool _isPaused = false;
  int _currentIndex = 0;
  int _itemCount = 0;
  String _filter = 'All';
  String _feedTab = 'For You';
  final Set<int> _hiddenIds = {};
  final Set<int> _likedIds = {};
  final Map<int, VideoPlayerController> _videoControllers = {};
  bool _showLikeBurst = false;
  Timer? _likeBurstTimer;
  List<Product> _visibleItems = const [];
  int _refreshNonce = 0;
  bool _isRefreshing = false;
  double _pullOffset = 0;
  late final AnimationController _pullController;
  Animation<double>? _pullAnimation;
  int _resumeIndex = 0;
  bool _resumeApplied = false;
  final Map<int, int> _categoryBias = {};
  final Map<int, int> _brandBias = {};
  bool _showProgressBar = true;
  Timer? _progressHideTimer;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
    _pullController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() {
        if (_pullAnimation == null) return;
        setState(() => _pullOffset = _pullAnimation!.value);
      });
    _progressController.addStatusListener(_onProgressStatus);
    _loadMutePref();
    _loadResumeIndex();
    _progressController.forward(from: 0);
    _showProgressBarTemporarily();
  }

  @override
  void dispose() {
    _saveResumeIndex();
    _progressController.removeStatusListener(_onProgressStatus);
    _progressController.dispose();
    _controller.dispose();
    _pullController.dispose();
    _progressHideTimer?.cancel();
    if (!kIsWeb) {
      for (final c in _videoControllers.values) {
        c.dispose();
      }
    }
    _likeBurstTimer?.cancel();
    super.dispose();
  }

  void _onProgressStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    if (!_controller.hasClients) return;
    final next = _currentIndex + 1;
    if (_itemCount == 0) return;
    if (next >= _itemCount) {
      _controller.jumpToPage(0);
      _currentIndex = 0;
      _resetProgress();
      return;
    }
    _controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _resetProgress() {
    if (_isPaused) {
      _progressController.value = 0;
      return;
    }
    _progressController.forward(from: 0);
    _showProgressBarTemporarily();
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    _saveMutePref();
    if (kIsWeb) return;
    for (final controller in _videoControllers.values) {
      controller.setVolume(_muted ? 0 : 1);
    }
  }

  void _togglePause() {
    setState(() => _isPaused = !_isPaused);
    if (_isPaused) {
      _progressController.stop();
      setState(() => _showProgressBar = true);
    } else {
      _progressController.forward();
      _showProgressBarTemporarily();
    }
    if (_visibleItems.isNotEmpty) {
      _updatePlaybackFor(_visibleItems, _currentIndex.clamp(0, _visibleItems.length - 1));
    }
  }

  Future<void> _loadMutePref() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _muted = prefs.getBool('shorts_muted') ?? true);
  }

  Future<void> _saveMutePref() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('shorts_muted', _muted);
  }

  Future<void> _loadResumeIndex() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _resumeIndex = prefs.getInt('shorts_last_index') ?? 0);
  }

  Future<void> _saveResumeIndex() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('shorts_last_index', _currentIndex);
  }

  Future<void> _ensureControllersFor(List<Product> items, int index) async {
    if (kIsWeb) return;
    if (items.isEmpty) return;
    final indices = <int>{
      index,
      if (index > 0) index - 1,
      if (index < items.length - 1) index + 1,
    };
    final idsToKeep = indices.map((i) => items[i].id).toSet();
    final toRemove = _videoControllers.keys.where((id) => !idsToKeep.contains(id)).toList();
    for (final id in toRemove) {
      await _videoControllers[id]?.dispose();
      _videoControllers.remove(id);
    }
    for (final i in indices) {
      final product = items[i];
      if (_videoControllers.containsKey(product.id)) continue;
      final url = _videoUrlFor(product);
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      _videoControllers[product.id] = controller;
      await controller.initialize();
      controller.setLooping(true);
      controller.setVolume(_muted ? 0 : 1);
      if (i == index && !_isPaused) {
        controller.play();
      } else {
        controller.pause();
      }
    }
  }

  void _updatePlaybackFor(List<Product> items, int index) {
    if (kIsWeb) return;
    for (final entry in _videoControllers.entries) {
      final isCurrent = items[index].id == entry.key;
      if (isCurrent && !_isPaused) {
        entry.value.setVolume(_muted ? 0 : 1);
        entry.value.play();
        _showProgressBarTemporarily();
      } else {
        entry.value.pause();
      }
    }
  }

  void _showProgressBarTemporarily() {
    if (!mounted) return;
    setState(() => _showProgressBar = true);
    _progressHideTimer?.cancel();
    _progressHideTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted || _isPaused) return;
      setState(() => _showProgressBar = false);
    });
  }

  void _likeWithBurst(int productId) {
    setState(() {
      if (_likedIds.contains(productId)) {
        _likedIds.remove(productId);
      } else {
        _likedIds.add(productId);
      }
      _showLikeBurst = true;
    });
    HapticFeedback.lightImpact();
    _likeBurstTimer?.cancel();
    _likeBurstTimer = Timer(const Duration(milliseconds: 520), () {
      if (!mounted) return;
      setState(() => _showLikeBurst = false);
    });
  }

  void _triggerRefresh() {
    if (_isRefreshing) return;
    _isRefreshing = true;
    _animatePullTo(60);
    setState(() {
      _refreshNonce += 1;
      _currentIndex = 0;
    });
    _controller.jumpToPage(0);
    _resetProgress();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Refreshing Shorts')),
      );
    }
    Future.delayed(const Duration(milliseconds: 600), () {
      _isRefreshing = false;
      _animatePullTo(0);
    });
  }

  void _animatePullTo(double target) {
    _pullController.stop();
    _pullAnimation = Tween<double>(begin: _pullOffset, end: target).animate(
      CurvedAnimation(parent: _pullController, curve: Curves.easeOutBack),
    );
    _pullController.forward(from: 0);
  }

  void _updatePull(double delta) {
    final next = (_pullOffset + delta).clamp(0, 80);
    setState(() => _pullOffset = next.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: ref.watch(homeLoadProvider).when(
            loading: () => const FullScreenShimmer(),
            error: (e, _) => ErrorState(
              title: 'Failed to load shorts',
              message: e.toString(),
              onRetry: () => ref.refresh(homeLoadProvider),
            ),
            data: (data) {
              final wishlist = ref.watch(wishlistProvider);
              final rawItems = _buildShorts(
                data.allProducts,
                wishlist,
                _likedIds,
                _feedTab,
                _refreshNonce,
                _categoryBias,
                _brandBias,
              );
              final items = _applyShortsFilters(rawItems, _filter, _hiddenIds);
              _visibleItems = items;
              _itemCount = items.length;
              if (!_resumeApplied && items.isNotEmpty) {
                final target = _resumeIndex.clamp(0, items.length - 1);
                _currentIndex = target;
                _resumeApplied = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!_controller.hasClients) return;
                  _controller.jumpToPage(target);
                  _ensureControllersFor(items, target);
                  _updatePlaybackFor(items, target);
                });
              }
              _ensureControllersFor(items, _currentIndex);
              if (items.isEmpty) {
                return EmptyState(
                  title: 'No Shorts yet',
                  subtitle: 'Coba refresh atau ganti filter untuk melihat shorts baru.',
                  icon: Icons.play_circle_outline,
                  actionLabel: 'Reset filters',
                  onAction: () => setState(() {
                    _filter = 'All';
                    _hiddenIds.clear();
                  }),
                );
              }
              return Stack(
                children: [
                  NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification is ScrollStartNotification) {
                        if (!_isPaused) {
                          _progressController.stop();
                        }
                        _pullController.stop();
                      } else if (notification is ScrollEndNotification) {
                        if (!_isPaused) {
                          _progressController.forward();
                        }
                        if (_pullOffset > 48 && _currentIndex == 0 && !_isRefreshing) {
                          _triggerRefresh();
                        } else if (_pullOffset > 0 && !_isRefreshing) {
                          _animatePullTo(0);
                        }
                      } else if (notification is OverscrollNotification) {
                        if (_currentIndex == 0 && notification.overscroll < 0) {
                          _updatePull(-notification.overscroll * 0.6);
                        }
                      }
                      return false;
                    },
                    child: Transform.translate(
                      offset: Offset(0, _pullOffset),
                      child: PageView.builder(
                        controller: _controller,
                        scrollDirection: Axis.vertical,
                        itemCount: items.length,
                        onPageChanged: (index) {
                          setState(() => _currentIndex = index);
                          _resetProgress();
                          _ensureControllersFor(items, index);
                          _updatePlaybackFor(items, index);
                        },
                        itemBuilder: (context, index) {
                      final product = items[index];
                      final outOfStock = product.stock <= 0;
                      final controller = _videoControllers[product.id];
                      return GestureDetector(
                        onTap: _togglePause,
                        onDoubleTap: () => _likeWithBurst(product.id),
                        onHorizontalDragEnd: (details) {
                          final v = details.primaryVelocity ?? 0;
                          if (v < -800) {
                            HapticFeedback.mediumImpact();
                            context.go('/shop');
                          } else if (v > 800) {
                            HapticFeedback.mediumImpact();
                            _openCreatorProfile(context, product);
                          }
                        },
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                              _ShortsBackground(
                                imageUrl: product.image,
                                outOfStock: outOfStock,
                                controller: controller,
                              ),
                              _ShortsGradientOverlay(),
                              _ShortsTagHotspots(
                                onTap: (label) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Tag: $label')),
                                  );
                                },
                              ),
                              _ShortsTopBar(
                                onBack: () {
                                  if (context.canPop()) {
                                    context.pop();
                                  } else {
                                    context.go('/shop');
                                  }
                                },
                                muted: _muted,
                                onToggleMute: _toggleMute,
                                isPaused: _isPaused,
                              ),
                              _ShortsFeedTabs(
                              selected: _feedTab,
                              onSelect: (value) => setState(() {
                                _feedTab = value;
                                _currentIndex = 0;
                                _resumeApplied = true;
                              }),
                              ),
                              _ShortsProgressBar(
                                visible: _showProgressBar || _isPaused,
                                progress: _progressController,
                                onScrub: (value) {
                                  _progressController.value = value;
                                  _showProgressBarTemporarily();
                                },
                              ),
                              _ShortsContent(
                                product: product,
                                outOfStock: outOfStock,
                                onAdd: outOfStock
                                    ? null
                                    : () {
                                        ref.read(cartProvider.notifier).add(product);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Added ${product.name}')),
                                        );
                                      },
                                onBuyNow: outOfStock
                                    ? null
                                    : () {
                                        ref.read(cartProvider.notifier).add(product);
                                        context.go('/checkout');
                                      },
                              onViewDetail: () => context.push('/product/${product.id}'),
                                onQuickDetail: () => _openQuickDetail(context, product),
                              ),
                            _ShortsActions(
                              isLiked: _likedIds.contains(product.id),
                              isSaved: ref.watch(wishlistProvider).any((e) => e.id == product.id),
                              onLike: () => _likeWithBurst(product.id),
                              onSave: () {
                                HapticFeedback.selectionClick();
                                ref.read(wishlistProvider.notifier).toggle(product);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Saved ${product.name}')),
                                );
                              },
                              onShare: () => ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Share link copied')),
                              ),
                              onComment: () => _openComments(context),
                              onCart: () => context.go('/cart'),
                              onHide: () {
                                _categoryBias[product.categoryId] =
                                    (_categoryBias[product.categoryId] ?? 0) - 1;
                                _brandBias[product.brandId] = (_brandBias[product.brandId] ?? 0) - 1;
                                HapticFeedback.lightImpact();
                                setState(() => _hiddenIds.add(product.id));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Hidden from Shorts')),
                                );
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (!_controller.hasClients) return;
                                  final newCount = (items.length - 1).clamp(0, items.length);
                                  final maxIndex = (newCount - 1).clamp(0, newCount);
                                  final nextIndex = _currentIndex > maxIndex ? maxIndex : _currentIndex;
                                  _controller.jumpToPage(nextIndex);
                                  _currentIndex = nextIndex;
                                  _resetProgress();
                                });
                              },
                            ),
                            const _SwipeHintArrows(),
                            if (_isPaused) const _PausedOverlay(),
                            if (_showLikeBurst)
                              const _LikeBurstOverlay(),
                          ],
                        ),
                      );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: Text(
                      '${_currentIndex + 1}/${items.length}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: AnimatedOpacity(
                        opacity: (_pullOffset > 2 || _isRefreshing) ? 1 : 0,
                        duration: const Duration(milliseconds: 160),
                        child: Column(
                          children: [
                            Transform.translate(
                              offset: Offset(0, _pullOffset * 0.4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        value: _isRefreshing ? null : (_pullOffset / 80).clamp(0, 1),
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isRefreshing ? 'Refreshing...' : 'Pull to refresh',
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
    );
  }
}

List<Product> _buildShorts(
  List<Product> products,
  List<Product> wishlist,
  Set<int> likedIds,
  String feedTab,
  int refreshNonce,
  Map<int, int> categoryBias,
  Map<int, int> brandBias,
) {
  final unique = <int, Product>{};
  for (final p in products) {
    unique[p.id] = p;
  }
  final list = unique.values.toList();
  if (feedTab == 'Following') {
    final following = list.where((p) => likedIds.contains(p.id) || wishlist.any((w) => w.id == p.id)).toList();
    if (following.isNotEmpty) return following;
  }
  final favCategories = <int, int>{};
  for (final w in wishlist) {
    favCategories[w.categoryId] = (favCategories[w.categoryId] ?? 0) + 1;
  }
  list.sort((a, b) {
    final scoreA = _forYouScore(a, wishlist, likedIds, favCategories, categoryBias, brandBias);
    final scoreB = _forYouScore(b, wishlist, likedIds, favCategories, categoryBias, brandBias);
    return scoreB.compareTo(scoreA);
  });
  final seeded = List<Product>.from(list);
  seeded.shuffle(Random(refreshNonce));
  return seeded;
}

double _forYouScore(
  Product p,
  List<Product> wishlist,
  Set<int> likedIds,
  Map<int, int> favCategories,
  Map<int, int> categoryBias,
  Map<int, int> brandBias,
) {
  var score = p.rating * 2 + (p.reviewCount / 1000);
  if (p.discountPrice < p.price) score += 1.5;
  if (likedIds.contains(p.id)) score += 2.5;
  if (wishlist.any((w) => w.id == p.id)) score += 4.0;
  score += (favCategories[p.categoryId] ?? 0) * 0.6;
  score += (categoryBias[p.categoryId] ?? 0) * 0.4;
  score += (brandBias[p.brandId] ?? 0) * 0.4;
  return score;
}

List<Product> _applyShortsFilters(List<Product> products, String filter, Set<int> hiddenIds) {
  final visible = products.where((p) => !hiddenIds.contains(p.id)).toList();
  if (filter == 'All') return visible;
  final mapped = visible.where((p) => _categoryLabel(p.categoryId) == filter).toList();
  return mapped.isEmpty ? visible : mapped;
}

String _categoryLabel(int categoryId) {
  final map = ['Skincare', 'Makeup', 'Fragrance', 'Hair'];
  return map[categoryId % map.length];
}

String _videoUrlFor(Product product) {
  const urls = [
    'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
    'https://sample-videos.com/video321/mp4/720/big_buck_bunny_720p_1mb.mp4',
    'https://sample-videos.com/video321/mp4/720/big_buck_bunny_720p_2mb.mp4',
  ];
  return urls[product.categoryId % urls.length];
}

void _openQuickDetail(BuildContext context, Product product) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(product.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          PriceWidget(price: product.discountPrice),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    ),
  );
}

void _openComments(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, controller) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Comments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                controller: controller,
                children: const [
                  _CommentTile(text: 'Glow-nya dapet banget!', author: '@bella'),
                  _CommentTile(text: 'Tekstur ringan, jadi suka', author: '@rani'),
                  _CommentTile(text: 'Worth it buat daily use', author: '@tania'),
                  _CommentTile(text: 'Kulit jadi lebih halus.', author: '@nia'),
                  _CommentTile(text: 'Cepat meresap, no sticky.', author: '@rhea'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: 'Add a comment…',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.chat_bubble_outline),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void _openCreatorProfile(BuildContext context, Product product) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 24, child: Icon(Icons.person)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('@creator_${product.id % 30}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text('Brand: ${_brandName(product.brandId)}'),
                ],
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Bio singkat: Beauty creator yang suka share tips glow & skincare routine.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          Row(
            children: const [
              _ProfileStat(label: 'Posts', value: '128'),
              SizedBox(width: 12),
              _ProfileStat(label: 'Followers', value: '42k'),
              SizedBox(width: 12),
              _ProfileStat(label: 'Likes', value: '210k'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              child: const Text('Follow'),
            ),
          ),
        ],
      ),
    ),
  );
}

String _brandName(int brandId) {
  const names = ['Aepura', 'Skintific', 'Euphy', 'Luvia', 'Aerisia'];
  return names[brandId % names.length];
}

class _ProfileStat extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final String text;
  final String author;

  const _CommentTile({required this.text, required this.author});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: const CircleAvatar(radius: 14, child: Icon(Icons.person, size: 14)),
      title: Text(text),
      subtitle: Text(author),
    );
  }
}

class _ShortsBackground extends StatelessWidget {
  final String imageUrl;
  final bool outOfStock;
  final VideoPlayerController? controller;

  const _ShortsBackground({
    required this.imageUrl,
    required this.outOfStock,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final video = controller;
    final content = video != null && video.value.isInitialized
        ? FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: video.value.size.width,
              height: video.value.size.height,
              child: VideoPlayer(video),
            ),
          )
        : Image.network(imageUrl, fit: BoxFit.cover);
    return ColorFiltered(
      colorFilter: outOfStock
          ? const ColorFilter.matrix(<double>[
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0, 0, 0, 1, 0,
            ])
          : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
      child: content,
    );
  }
}

class _ShortsGradientOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black54,
            Colors.transparent,
            Colors.black87,
          ],
        ),
      ),
    );
  }
}

class _ShortsTagHotspots extends StatelessWidget {
  final ValueChanged<String> onTap;

  const _ShortsTagHotspots({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 24,
          top: 180,
          child: _TagChip(label: 'Glow Serum', onTap: () => onTap('Glow Serum')),
        ),
        Positioned(
          right: 24,
          top: 260,
          child: _TagChip(label: 'Shade 02', onTap: () => onTap('Shade 02')),
        ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _TagChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ),
    );
  }
}

class _ShortsTopBar extends StatelessWidget {
  final VoidCallback onBack;
  final bool muted;
  final VoidCallback onToggleMute;
  final bool isPaused;

  const _ShortsTopBar({
    required this.onBack,
    required this.muted,
    required this.onToggleMute,
    required this.isPaused,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const Spacer(),
                const Text('Beauty Shorts', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                  onPressed: onToggleMute,
                  icon: Icon(muted ? Icons.volume_off : Icons.volume_up, color: Colors.white),
                ),
              ],
            ),
            if (isPaused)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('Paused', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }
}

class _ShortsFeedTabs extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _ShortsFeedTabs({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      top: 6,
      child: SafeArea(
        bottom: false,
        child: _MinimalPill(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: _FeedTab(
                  label: 'For You',
                  selected: selected == 'For You',
                  onTap: () => onSelect('For You'),
                  stretch: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FeedTab(
                  label: 'Following',
                  selected: selected == 'Following',
                  onTap: () => onSelect('Following'),
                  stretch: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool stretch;

  const _FeedTab({
    required this.label,
    required this.selected,
    required this.onTap,
    this.stretch = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withValues(alpha: 0.92) : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: selected ? 0.5 : 0.18)),
        ),
        child: SizedBox(
          width: stretch ? double.infinity : null,
          child: Text(
            label,
            textAlign: stretch ? TextAlign.center : TextAlign.start,
            style: TextStyle(
              color: selected ? Colors.black : scheme.onInverseSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _ShortsProgressBar extends StatelessWidget {
  final bool visible;
  final Animation<double> progress;
  final ValueChanged<double> onScrub;

  const _ShortsProgressBar({
    required this.visible,
    required this.progress,
    required this.onScrub,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 10,
      child: SafeArea(
        top: false,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 220),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                final box = context.findRenderObject() as RenderBox?;
                if (box == null) return;
                final dx = details.localPosition.dx.clamp(0, box.size.width);
                onScrub(dx / box.size.width);
              },
              child: AnimatedBuilder(
                animation: progress,
                builder: (context, _) => LinearProgressIndicator(
                  value: progress.value,
                  minHeight: 3,
                  backgroundColor: Colors.white24,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MinimalPill extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _MinimalPill({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black.withValues(alpha: 0.42),
              Colors.black.withValues(alpha: 0.26),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _ShortsContent extends StatelessWidget {
  final Product product;
  final bool outOfStock;
  final VoidCallback? onAdd;
  final VoidCallback? onBuyNow;
  final VoidCallback onViewDetail;
  final VoidCallback onQuickDetail;

  const _ShortsContent({
    required this.product,
    required this.outOfStock,
    required this.onAdd,
    required this.onBuyNow,
    required this.onViewDetail,
    required this.onQuickDetail,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Positioned.fill(
      child: Align(
        alignment: Alignment.bottomLeft,
        child: SafeArea(
          top: false,
          left: false,
          right: false,
          minimum: const EdgeInsets.only(left: 16, right: 90, bottom: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.55,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CreatorRow(productId: product.id),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: outOfStock ? Colors.redAccent.withValues(alpha: 0.9) : Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      outOfStock ? 'Out of stock' : 'Trending pick',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      RatingStars(rating: product.rating),
                      const SizedBox(width: 6),
                      Text('(${product.reviewCount})', style: TextStyle(color: scheme.onInverseSurface)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _reviewSnippet(product.rating),
                    style: TextStyle(color: scheme.onInverseSurface.withValues(alpha: 0.85), height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  DefaultTextStyle(
                    style: const TextStyle(color: Colors.white),
                    child: PriceWidget(price: product.discountPrice),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: onAdd,
                        icon: const Icon(Icons.add),
                        label: Text(outOfStock ? 'Unavailable' : 'Add to cart'),
                      ),
                      ElevatedButton(
                        onPressed: onBuyNow,
                        child: const Text('Buy now'),
                      ),
                      OutlinedButton(
                        onPressed: onViewDetail,
                        child: const Text('View details'),
                      ),
                      TextButton(
                        onPressed: onQuickDetail,
                        child: const Text('Quick detail'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onVerticalDragEnd: (details) {
                      if (details.primaryVelocity != null && details.primaryVelocity! < -900) {
                        onViewDetail();
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.keyboard_arrow_up, color: scheme.onInverseSurface),
                        const SizedBox(width: 4),
                        Text('Swipe up for details', style: TextStyle(color: scheme.onInverseSurface)),
                      ],
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

class _CreatorRow extends StatefulWidget {
  final int productId;

  const _CreatorRow({required this.productId});

  @override
  State<_CreatorRow> createState() => _CreatorRowState();
}

class _CreatorRowState extends State<_CreatorRow> {
  bool _following = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: Colors.white.withValues(alpha: 0.2),
          child: const Icon(Icons.person, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 8),
        Text(
          '@creator_${widget.productId % 30}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () => setState(() => _following = !_following),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: _following ? Colors.white24 : Colors.white.withValues(alpha: 0.15),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: Text(_following ? 'Following' : 'Follow'),
        ),
      ],
    );
  }
}

class _ShortsActions extends StatelessWidget {
  final VoidCallback onLike;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final VoidCallback onComment;
  final VoidCallback onCart;
  final VoidCallback onHide;
  final bool isLiked;
  final bool isSaved;

  const _ShortsActions({
    required this.onLike,
    required this.onSave,
    required this.onShare,
    required this.onComment,
    required this.onCart,
    required this.onHide,
    required this.isLiked,
    required this.isSaved,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 12,
      bottom: 110,
      child: Column(
        children: [
          _ShortsActionButton(
            icon: isLiked ? Icons.favorite : Icons.favorite_border,
            label: 'Like',
            onTap: onLike,
            active: isLiked,
          ),
          const SizedBox(height: 12),
          _ShortsActionButton(
            icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
            label: 'Save',
            onTap: onSave,
            active: isSaved,
          ),
          const SizedBox(height: 12),
          _ShortsActionButton(icon: Icons.share, label: 'Share', onTap: onShare),
          const SizedBox(height: 12),
          _ShortsActionButton(icon: Icons.chat_bubble_outline, label: 'Comment', onTap: onComment),
          const SizedBox(height: 12),
          _ShortsActionButton(icon: Icons.shopping_bag_outlined, label: 'Cart', onTap: onCart),
          const SizedBox(height: 12),
          _ShortsActionButton(icon: Icons.not_interested, label: 'Hide', onTap: onHide),
        ],
      ),
    );
  }
}

class _ShortsActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  const _ShortsActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: active ? Colors.white : Colors.black.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: active ? Colors.black : Colors.white),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }
}

class _PausedOverlay extends StatelessWidget {
  const _PausedOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          color: Colors.black.withAlpha(30),
          alignment: Alignment.center,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.pause, color: Colors.white, size: 30),
          ),
        ),
      ),
    );
  }
}

class _LikeBurstOverlay extends StatelessWidget {
  const _LikeBurstOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: AnimatedScale(
            scale: 1.2,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            child: Icon(Icons.favorite, color: Colors.white.withValues(alpha: 0.85), size: 84),
          ),
        ),
      ),
    );
  }
}

class _SwipeHintArrows extends StatefulWidget {
  const _SwipeHintArrows();

  @override
  State<_SwipeHintArrows> createState() => _SwipeHintArrowsState();
}

class _SwipeHintArrowsState extends State<_SwipeHintArrows> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _slide;
  Timer? _hideTimer;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _hideTimer = Timer(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      _controller.stop();
      setState(() => _visible = false);
    });
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _slide = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final opacity = 0.18 + 0.12 * _fade.value;
            return Stack(
              children: [
                Positioned(
                  left: 10 + _slide.value,
                  top: MediaQuery.of(context).size.height * 0.48,
                  child: Opacity(
                    opacity: opacity,
                    child: Row(
                      children: const [
                        Icon(Icons.chevron_left, color: Colors.white, size: 18),
                        Icon(Icons.chevron_left, color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 10 + _slide.value,
                  top: MediaQuery.of(context).size.height * 0.48,
                  child: Opacity(
                    opacity: opacity,
                    child: Row(
                      children: const [
                        Icon(Icons.chevron_right, color: Colors.white, size: 18),
                        Icon(Icons.chevron_right, color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

String _reviewSnippet(double rating) {
  if (rating >= 4.6) return 'Super ringan dan bikin kulit glowing seharian.';
  if (rating >= 4.2) return 'Teksturnya enak, cepat meresap, hasilnya halus.';
  return 'Worth it, nyaman dipakai harian dan nggak lengket.';
}
