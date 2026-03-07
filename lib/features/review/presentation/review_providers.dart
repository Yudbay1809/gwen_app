import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReviewItem {
  final int id;
  final String userName;
  final String userAvatar;
  final String productName;
  final double rating;
  final String content;
  final String createdAt;
  final int likes;

  const ReviewItem({
    required this.id,
    required this.userName,
    required this.userAvatar,
    required this.productName,
    required this.rating,
    required this.content,
    required this.createdAt,
    required this.likes,
  });
}

final reviewFeedProvider = Provider<List<ReviewItem>>((ref) {
  return const [
    ReviewItem(
      id: 1,
      userName: 'Alya S.',
      userAvatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&q=80',
      productName: 'Glow Serum',
      rating: 4.6,
      content: 'Teksturnya ringan, cepat meresap, dan bikin kulit terlihat lebih glowing.',
      createdAt: '2h ago',
      likes: 18,
    ),
    ReviewItem(
      id: 2,
      userName: 'Nadia P.',
      userAvatar: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=200&q=80',
      productName: 'Velvet Matte Lip',
      rating: 4.2,
      content: 'Warnanya pigmented, tapi tidak bikin bibir kering.',
      createdAt: '6h ago',
      likes: 9,
    ),
    ReviewItem(
      id: 3,
      userName: 'Raka T.',
      userAvatar: 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=200&q=80',
      productName: 'Hydra Cleanser',
      rating: 4.8,
      content: 'Cocok untuk kulit sensitif. After feel lembut dan tidak ketarik.',
      createdAt: '1d ago',
      likes: 25,
    ),
    ReviewItem(
      id: 4,
      userName: 'Citra M.',
      userAvatar: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=200&q=80',
      productName: 'Soft Toner',
      rating: 4.3,
      content: 'Wangi lembut dan tidak perih di kulit sensitif.',
      createdAt: '2d ago',
      likes: 7,
    ),
    ReviewItem(
      id: 5,
      userName: 'Dian R.',
      userAvatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&q=80',
      productName: 'Sun Shield',
      rating: 4.7,
      content: 'Tidak lengket, cocok untuk dipakai daily.',
      createdAt: '3d ago',
      likes: 14,
    ),
    ReviewItem(
      id: 6,
      userName: 'Fira L.',
      userAvatar: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=200&q=80',
      productName: 'Glow Mist',
      rating: 4.1,
      content: 'Bikin makeup lebih nyatu dan fresh.',
      createdAt: '4d ago',
      likes: 6,
    ),
  ];
});

final reviewLoadProvider = FutureProvider<List<ReviewItem>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 500));
  return ref.read(reviewFeedProvider);
});
