import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'newsfeed_providers.dart';
import 'article_bookmark_provider.dart';
import 'article_comments_provider.dart';
import 'article_reaction_provider.dart';
import 'article_follow_provider.dart';
import 'article_metrics_provider.dart';
import 'newsfeed_streak_provider.dart';
import 'article_saved_provider.dart';

class ArticleDetailScreen extends ConsumerStatefulWidget {
  final String id;

  const ArticleDetailScreen({super.key, required this.id});

  @override
  ConsumerState<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends ConsumerState<ArticleDetailScreen> {
  final _controller = TextEditingController();
  double _progress = 0;
  bool _viewTracked = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(newsfeedProvider);
    final articleId = int.tryParse(widget.id);
    final article = articleId == null ? null : data.where((a) => a.id == articleId).firstOrNull;

    if (article == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Article'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/newsfeed');
              }
            },
          ),
        ),
        body: const Center(child: Text('Article not found')),
      );
    }

    final isBookmarked = ref.watch(articleBookmarkProvider).contains(article.id);
    final comments = ref.watch(articleCommentsProvider)[article.id] ?? const <String>[];
    final reaction = ref.watch(articleReactionProvider)[article.id] ??
        const ArticleReactionState(likes: 0, liked: false);
    final followed = ref.watch(articleFollowProvider).contains(article.author);
    final metrics = ref.watch(articleMetricsProvider)[article.id] ?? const ArticleMetrics(views: 0, shares: 0);
    final saved = ref.watch(articleSavedProvider).contains(article.id);

    if (!_viewTracked) {
      _viewTracked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(articleMetricsProvider.notifier).addView(article.id);
        ref.read(readingStreakProvider.notifier).registerRead();
      });
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/newsfeed');
            }
          },
        ),
        title: Text(article.title),
        actions: [
          IconButton(
            icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border),
            onPressed: () => ref.read(articleBookmarkProvider.notifier).toggle(article.id),
          ),
          IconButton(
            icon: Icon(saved ? Icons.save : Icons.save_outlined),
            onPressed: () => ref.read(articleSavedProvider.notifier).toggle(article.id),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ref.read(articleMetricsProvider.notifier).addShare(article.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share link copied')),
              );
            },
          ),
        ],
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.maxScrollExtent <= 0) return false;
          final value = (n.metrics.pixels / n.metrics.maxScrollExtent).clamp(0, 1).toDouble();
          if ((value - _progress).abs() > 0.05) {
            setState(() => _progress = value);
            ref.read(articleReadProgressProvider.notifier).setProgress(article.id, value);
          }
          return false;
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
          Image.network(article.image, height: 240, width: double.infinity, fit: BoxFit.cover),
          const SizedBox(height: 12),
          Text(article.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withAlpha(31),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(article.category, style: const TextStyle(fontSize: 11)),
              ),
              const SizedBox(width: 8),
              Text(article.createdAt, style: const TextStyle(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('By ${article.author}', style: const TextStyle(color: Colors.grey)),
              const Spacer(),
              TextButton(
                onPressed: () => ref.read(articleFollowProvider.notifier).toggle(article.author),
                child: Text(followed ? 'Following' : 'Follow'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('${_readingTime(article.excerpt)} min read', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => ref.read(articleReactionProvider.notifier).toggleLike(article.id),
                icon: Icon(
                  reaction.liked ? Icons.favorite : Icons.favorite_border,
                  color: reaction.liked ? Colors.pink : null,
                ),
                label: Text('${reaction.likes} likes'),
              ),
              const SizedBox(width: 12),
              Row(
                children: [
                  const Icon(Icons.comment, size: 18, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${comments.length} comments', style: const TextStyle(color: Colors.grey)),
                ],
              ),
              const SizedBox(width: 12),
              Text('${metrics.views} views', style: const TextStyle(color: Colors.grey)),
              const SizedBox(width: 12),
              Text('${metrics.shares} shares', style: const TextStyle(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'This article explains step-by-step routines and best practices to keep your skin healthy and glowing. '
            'Start with gentle cleansing, follow with hydration, and always finish with sun protection. '
            'Consistency is key for visible results.',
          ),
          const SizedBox(height: 24),
          const Text('Comments', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (comments.isEmpty) const Text('No comments yet.'),
          ...comments.map(
            (c) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(child: Icon(Icons.person, size: 16)),
              title: Text(c),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(hintText: 'Write a comment...'),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  ref.read(articleCommentsProvider.notifier).addComment(article.id, _controller.text);
                  _controller.clear();
                },
                child: const Text('Post'),
              ),
            ],
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

int _readingTime(String text) {
  final words = text.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).length;
  final minutes = (words / 200).ceil();
  return minutes < 1 ? 1 : minutes;
}
