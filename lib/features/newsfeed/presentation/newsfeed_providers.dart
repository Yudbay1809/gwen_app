import 'package:flutter_riverpod/flutter_riverpod.dart';

class ArticleItem {
  final int id;
  final String title;
  final String excerpt;
  final String image;
  final String createdAt;

  const ArticleItem({
    required this.id,
    required this.title,
    required this.excerpt,
    required this.image,
    required this.createdAt,
  });
}

final newsfeedProvider = Provider<List<ArticleItem>>((ref) {
  return const [
    ArticleItem(
      id: 1,
      title: '5 Steps Night Routine for Glowing Skin',
      excerpt: 'Build a calming routine to repair and hydrate your skin overnight.',
      image: 'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=800&q=80',
      createdAt: 'Today',
    ),
    ArticleItem(
      id: 2,
      title: 'Choosing the Right Sunscreen',
      excerpt: 'Understand SPF, PA, and how to pick sunscreen for your skin type.',
      image: 'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?w=800&q=80',
      createdAt: 'Yesterday',
    ),
    ArticleItem(
      id: 3,
      title: 'Makeup Tips for Dewy Look',
      excerpt: 'Achieve a natural dewy finish with these simple steps.',
      image: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=800&q=80',
      createdAt: '2d ago',
    ),
    ArticleItem(
      id: 4,
      title: 'Haircare Routine for Soft Volume',
      excerpt: 'Focus on scalp health and lightweight conditioners.',
      image: 'https://images.unsplash.com/photo-1515377905703-c4788e51af15?w=800&q=80',
      createdAt: '3d ago',
    ),
    ArticleItem(
      id: 5,
      title: 'Body Care: Exfoliate the Right Way',
      excerpt: 'Gentle exfoliation improves tone and texture.',
      image: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=800&q=80',
      createdAt: '4d ago',
    ),
    ArticleItem(
      id: 6,
      title: 'How to Layer Skincare',
      excerpt: 'Learn the correct order for maximum absorption.',
      image: 'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?w=800&q=80',
      createdAt: '5d ago',
    ),
    ArticleItem(
      id: 7,
      title: 'Makeup Tools You Actually Need',
      excerpt: 'Keep your kit minimal but effective.',
      image: 'https://images.unsplash.com/photo-1522336572468-97b06e8ef143?w=800&q=80',
      createdAt: '1w ago',
    ),
  ];
});

final newsfeedLoadProvider = FutureProvider<List<ArticleItem>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 500));
  return ref.read(newsfeedProvider);
});
