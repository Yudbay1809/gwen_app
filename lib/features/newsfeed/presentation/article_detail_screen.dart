import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'newsfeed_providers.dart';
import 'article_bookmark_provider.dart';

class ArticleDetailScreen extends ConsumerWidget {
  final String id;

  const ArticleDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(newsfeedProvider);
    final articleId = int.tryParse(id);
    final article = articleId == null ? null : data.where((a) => a.id == articleId).firstOrNull;

    if (article == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Article')),
        body: const Center(child: Text('Article not found')),
      );
    }

    final isBookmarked = ref.watch(articleBookmarkProvider).contains(article.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(article.title),
        actions: [
          IconButton(
            icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border),
            onPressed: () => ref.read(articleBookmarkProvider.notifier).toggle(article.id),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share link copied')), 
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(article.image, height: 240, width: double.infinity, fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(article.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(article.createdAt, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  const Text(
                    'This article explains step-by-step routines and best practices to keep your skin healthy and glowing. '
                    'Start with gentle cleansing, follow with hydration, and always finish with sun protection. '
                    'Consistency is key for visible results.',
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

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
