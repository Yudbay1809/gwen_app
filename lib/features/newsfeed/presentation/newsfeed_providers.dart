import 'package:flutter_riverpod/flutter_riverpod.dart';

class ArticleItem {
  final int id;
  final String title;
  final String excerpt;
  final String image;
  final String createdAt;
  final String category;
  final String author;

  const ArticleItem({
    required this.id,
    required this.title,
    required this.excerpt,
    required this.image,
    required this.createdAt,
    required this.category,
    required this.author,
  });
}

class AuthorProfile {
  final String name;
  final String bio;
  final int followers;
  final String avatar;
  final bool verified;

  const AuthorProfile({
    required this.name,
    required this.bio,
    required this.followers,
    required this.avatar,
    required this.verified,
  });
}

final newsfeedAuthorsProvider = Provider<List<String>>((ref) {
  final articles = ref.watch(newsfeedProvider);
  return {for (final a in articles) a.author}.toList();
});

final newsfeedProvider = Provider<List<ArticleItem>>((ref) {
  return const [
    ArticleItem(
      id: 1,
      title: '5 Steps Night Routine for Glowing Skin',
      excerpt: 'Build a calming routine to repair and hydrate your skin overnight.',
      image: 'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=800&q=80',
      createdAt: 'Today',
      category: 'Skincare',
      author: 'Dr. Maya S.',
    ),
    ArticleItem(
      id: 2,
      title: 'Choosing the Right Sunscreen',
      excerpt: 'Understand SPF, PA, and how to pick sunscreen for your skin type.',
      image: 'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?w=800&q=80',
      createdAt: 'Yesterday',
      category: 'Skincare',
      author: 'GWEN Beauty',
    ),
    ArticleItem(
      id: 3,
      title: 'Makeup Tips for Dewy Look',
      excerpt: 'Achieve a natural dewy finish with these simple steps.',
      image: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=800&q=80',
      createdAt: '2d ago',
      category: 'Makeup',
      author: 'Rani Putri',
    ),
    ArticleItem(
      id: 4,
      title: 'Haircare Routine for Soft Volume',
      excerpt: 'Focus on scalp health and lightweight conditioners.',
      image: 'https://images.unsplash.com/photo-1515377905703-c4788e51af15?w=800&q=80',
      createdAt: '3d ago',
      category: 'Haircare',
      author: 'Studio Hair Lab',
    ),
    ArticleItem(
      id: 5,
      title: 'Body Care: Exfoliate the Right Way',
      excerpt: 'Gentle exfoliation improves tone and texture.',
      image: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=800&q=80',
      createdAt: '4d ago',
      category: 'Body',
      author: 'Dr. Maya S.',
    ),
    ArticleItem(
      id: 6,
      title: 'How to Layer Skincare',
      excerpt: 'Learn the correct order for maximum absorption.',
      image: 'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?w=800&q=80',
      createdAt: '5d ago',
      category: 'Skincare',
      author: 'GWEN Beauty',
    ),
    ArticleItem(
      id: 7,
      title: 'Makeup Tools You Actually Need',
      excerpt: 'Keep your kit minimal but effective.',
      image: 'https://images.unsplash.com/photo-1522336572468-97b06e8ef143?w=800&q=80',
      createdAt: '1w ago',
      category: 'Makeup',
      author: 'Rani Putri',
    ),
  ];
});

final authorProfilesProvider = Provider<Map<String, AuthorProfile>>((ref) {
  return const {
    'Dr. Maya S.': AuthorProfile(
      name: 'Dr. Maya S.',
      bio: 'Dermatologist • Skin health educator.',
      followers: 12480,
      avatar: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=200&q=80',
      verified: true,
    ),
    'GWEN Beauty': AuthorProfile(
      name: 'GWEN Beauty',
      bio: 'Official GWEN Beauty editorials and tips.',
      followers: 48200,
      avatar: 'https://images.unsplash.com/photo-1522336572468-97b06e8ef143?w=200&q=80',
      verified: true,
    ),
    'Rani Putri': AuthorProfile(
      name: 'Rani Putri',
      bio: 'Makeup artist • Glow enthusiast.',
      followers: 8920,
      avatar: 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=200&q=80',
      verified: false,
    ),
    'Studio Hair Lab': AuthorProfile(
      name: 'Studio Hair Lab',
      bio: 'Haircare tips from professional stylists.',
      followers: 6400,
      avatar: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=200&q=80',
      verified: false,
    ),
  };
});

final newsfeedLoadProvider = FutureProvider<List<ArticleItem>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 500));
  return ref.read(newsfeedProvider);
});
