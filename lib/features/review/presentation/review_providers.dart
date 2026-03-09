import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReviewItem {
  final int id;
  final String userName;
  final String userAvatar;
  final String productName;
  final double rating;
  final String content;
  final DateTime createdAt;
  final int likes;
  final bool hasMedia;
  final List<String> media;
  final bool verifiedPurchase;

  const ReviewItem({
    required this.id,
    required this.userName,
    required this.userAvatar,
    required this.productName,
    required this.rating,
    required this.content,
    required this.createdAt,
    required this.likes,
    required this.hasMedia,
    required this.media,
    this.verifiedPurchase = false,
  });

  ReviewItem copyWith({
    double? rating,
    String? content,
    bool? hasMedia,
    List<String>? media,
    int? likes,
    bool? verifiedPurchase,
  }) {
    return ReviewItem(
      id: id,
      userName: userName,
      userAvatar: userAvatar,
      productName: productName,
      rating: rating ?? this.rating,
      content: content ?? this.content,
      createdAt: createdAt,
      likes: likes ?? this.likes,
      hasMedia: hasMedia ?? this.hasMedia,
      media: media ?? this.media,
      verifiedPurchase: verifiedPurchase ?? this.verifiedPurchase,
    );
  }
}

enum ReviewSort { newest, rating, helpful }

class ReviewFilter {
  final ReviewSort sort;
  final bool withMedia;
  final bool verifiedOnly;

  const ReviewFilter({required this.sort, required this.withMedia, required this.verifiedOnly});

  ReviewFilter copyWith({ReviewSort? sort, bool? withMedia, bool? verifiedOnly}) {
    return ReviewFilter(
      sort: sort ?? this.sort,
      withMedia: withMedia ?? this.withMedia,
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
    );
  }
}

class ReviewFilterNotifier extends Notifier<ReviewFilter> {
  static const _storageKey = 'review_filter_sort';
  static const _mediaKey = 'review_filter_media';
  static const _verifiedKey = 'review_filter_verified';

  @override
  ReviewFilter build() {
    _load();
    return const ReviewFilter(sort: ReviewSort.helpful, withMedia: false, verifiedOnly: false);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    final media = prefs.getBool(_mediaKey);
    final verified = prefs.getBool(_verifiedKey);
    final sort = ReviewSort.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => ReviewSort.helpful,
    );
    state = state.copyWith(sort: sort, withMedia: media ?? false, verifiedOnly: verified ?? false);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, state.sort.name);
    await prefs.setBool(_mediaKey, state.withMedia);
    await prefs.setBool(_verifiedKey, state.verifiedOnly);
  }

  void setSort(ReviewSort sort) {
    state = state.copyWith(sort: sort);
    _save();
  }

  void setWithMedia(bool value) {
    state = state.copyWith(withMedia: value);
    _save();
  }

  void setVerifiedOnly(bool value) {
    state = state.copyWith(verifiedOnly: value);
    _save();
  }
}

final reviewFilterProvider = NotifierProvider<ReviewFilterNotifier, ReviewFilter>(ReviewFilterNotifier.new);

class ReviewFeedNotifier extends Notifier<List<ReviewItem>> {
  @override
  List<ReviewItem> build() {
    return [
    ReviewItem(
      id: 1,
      userName: 'Alya S.',
      userAvatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&q=80',
      productName: 'Glow Serum',
      rating: 4.6,
      content: 'Teksturnya ringan, cepat meresap, dan bikin kulit terlihat lebih glowing.',
      createdAt: DateTime(2026, 3, 8, 9, 30),
      likes: 18,
      hasMedia: true,
      media: [
        'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=400&q=80',
        'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=400&q=80',
      ],
      verifiedPurchase: true,
    ),
    ReviewItem(
      id: 2,
      userName: 'Nadia P.',
      userAvatar: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=200&q=80',
      productName: 'Velvet Matte Lip',
      rating: 4.2,
      content: 'Warnanya pigmented, tapi tidak bikin bibir kering.',
      createdAt: DateTime(2026, 3, 8, 6, 45),
      likes: 9,
      hasMedia: true,
      media: const [
        'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?w=400&q=80',
      ],
      verifiedPurchase: false,
    ),
      ReviewItem(
        id: 3,
        userName: 'Raka T.',
        userAvatar: 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=200&q=80',
        productName: 'Hydra Cleanser',
        rating: 4.8,
        content: 'Cocok untuk kulit sensitif. After feel lembut dan tidak ketarik.',
        createdAt: DateTime(2026, 3, 7, 20, 10),
        likes: 25,
        hasMedia: true,
        media: [
          'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?w=400&q=80',
        ],
        verifiedPurchase: true,
      ),
    ReviewItem(
      id: 4,
      userName: 'Citra M.',
      userAvatar: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=200&q=80',
      productName: 'Soft Toner',
      rating: 4.3,
      content: 'Wangi lembut dan tidak perih di kulit sensitif.',
      createdAt: DateTime(2026, 3, 6, 18, 0),
      likes: 7,
      hasMedia: true,
      media: const [
        'https://images.unsplash.com/photo-1522336572468-97b06e8ef143?w=400&q=80',
      ],
    ),
      ReviewItem(
        id: 5,
        userName: 'Dian R.',
        userAvatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&q=80',
        productName: 'Sun Shield',
        rating: 4.7,
        content: 'Tidak lengket, cocok untuk dipakai daily.',
        createdAt: DateTime(2026, 3, 5, 14, 20),
        likes: 14,
        hasMedia: true,
        media: [
          'https://images.unsplash.com/photo-1522336572468-97b06e8ef143?w=400&q=80',
        ],
      ),
    ReviewItem(
      id: 6,
      userName: 'Fira L.',
      userAvatar: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=200&q=80',
      productName: 'Glow Mist',
      rating: 4.1,
      content: 'Bikin makeup lebih nyatu dan fresh.',
      createdAt: DateTime(2026, 3, 4, 9, 15),
      likes: 6,
      hasMedia: true,
      media: const [
        'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=400&q=80',
      ],
    ),
    ];
  }

  void updateReview({required int id, required double rating, required String content}) {
    final index = state.indexWhere((r) => r.id == id);
    if (index == -1) return;
    final updated = state[index].copyWith(rating: rating, content: content);
    final next = [...state];
    next[index] = updated;
    state = next;
  }

  void deleteReview(int id) {
    state = state.where((r) => r.id != id).toList();
  }
}

final reviewFeedProvider =
    NotifierProvider<ReviewFeedNotifier, List<ReviewItem>>(ReviewFeedNotifier.new);

final reviewLoadProvider = FutureProvider<List<ReviewItem>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 500));
  return ref.read(reviewFeedProvider);
});
