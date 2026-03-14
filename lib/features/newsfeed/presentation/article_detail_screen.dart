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
import '../../../shared/widgets/motion.dart';

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
                if (context.canPop()) context.pop();
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
          padding: EdgeInsets.zero,
          children: [
            Stack(
              children: [
                Hero(
                  tag: 'article-hero-${article.id}',
                  child: Image.network(
                    article.image,
                    height: 320,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.25),
                          Colors.black.withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () {
                            if (context.canPop()) {
                              if (context.canPop()) context.pop();
                            } else {
                              context.go('/newsfeed');
                            }
                          },
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border, color: Colors.white),
                          onPressed: () => ref.read(articleBookmarkProvider.notifier).toggle(article.id),
                        ),
                        IconButton(
                          icon: Icon(saved ? Icons.save : Icons.save_outlined, color: Colors.white),
                          onPressed: () => ref.read(articleSavedProvider.notifier).toggle(article.id),
                        ),
                        IconButton(
                          icon: const Icon(Icons.share_outlined, color: Colors.white),
                          onPressed: () {
                            ref.read(articleMetricsProvider.notifier).addShare(article.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Share link copied')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 18,
                  child: MotionFadeSlide(
                    beginOffset: const Offset(0, 0.12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                          ),
                          child: Text(
                            article.category,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          article.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              article.createdAt,
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${_readingTime(article.excerpt)} min read',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            MotionFadeSlide(
              delay: const Duration(milliseconds: 120),
              beginOffset: const Offset(0, 0.08),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => ref.read(articleReactionProvider.notifier).toggleLike(article.id),
                          icon: Icon(
                            reaction.liked ? Icons.favorite : Icons.favorite_border,
                            color: reaction.liked ? Theme.of(context).colorScheme.primary : null,
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
