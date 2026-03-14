import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'newsfeed_providers.dart';
import 'newsfeed_shimmer.dart';
import 'article_bookmark_provider.dart';
import 'article_comments_provider.dart';
import 'newsfeed_preferences_provider.dart';
import 'article_reaction_provider.dart';
import 'article_follow_provider.dart';
import 'article_metrics_provider.dart';
import 'newsfeed_streak_provider.dart';
import 'article_saved_provider.dart';
import '../../../shared/widgets/motion.dart';

class NewsfeedScreen extends ConsumerStatefulWidget {
  const NewsfeedScreen({super.key});

  @override
  ConsumerState<NewsfeedScreen> createState() => _NewsfeedScreenState();
}

class _NewsfeedScreenState extends ConsumerState<NewsfeedScreen> {
  int _visibleCount = 4;
  late final ScrollController _controller;
  String _category = 'All';
  bool _onlyBookmarked = false;
  int _feedTab = 0;
  bool _onlySaved = false;
  String _query = '';
  bool _onlyFollowedTopics = false;
  int _timeFilter = 0;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_controller.position.pixels >= _controller.position.maxScrollExtent - 200) {
      setState(() => _visibleCount += 3);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final asyncArticles = ref.watch(newsfeedLoadProvider);
    final bookmarks = ref.watch(articleBookmarkProvider);
    final progress = ref.watch(articleReadProgressProvider);
    final prefs = ref.watch(newsfeedPreferencesProvider);
    final reactions = ref.watch(articleReactionProvider);
    final comments = ref.watch(articleCommentsProvider);
    final followed = ref.watch(articleFollowProvider);
    final metrics = ref.watch(articleMetricsProvider);
    final saved = ref.watch(articleSavedProvider);
    final streak = ref.watch(readingStreakProvider);
    final authorProfiles = ref.watch(authorProfilesProvider);
    final followedTopics = ref.watch(newsfeedFollowTopicsProvider);
    final digestEnabled = ref.watch(newsfeedDigestProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Newsfeed'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmarks_outlined),
            onPressed: () => context.go('/newsfeed/saved'),
          ),
          IconButton(
            icon: const Icon(Icons.people_outline),
            onPressed: () => context.go('/newsfeed/authors'),
          ),
        ],
      ),
      body: asyncArticles.when(
        loading: () => const NewsfeedShimmer(),
        error: (error, stack) => const Center(child: Text('Failed to load')),
        data: (articles) {
          final onlyFollowing = _feedTab == 1;
          final categories = ['All', ...{for (final a in articles) a.category}];
          var filtered = articles;
          if (_category != 'All') {
            filtered = filtered.where((a) => a.category == _category).toList();
          }
          if (prefs.isNotEmpty) {
            filtered = filtered.where((a) => !prefs.contains(a.category)).toList();
          }
          if (_onlyBookmarked) {
            filtered = filtered.where((a) => bookmarks.contains(a.id)).toList();
          }
          if (onlyFollowing) {
            filtered = filtered.where((a) => followed.contains(a.author)).toList();
          }
          if (_onlySaved) {
            filtered = filtered.where((a) => saved.contains(a.id)).toList();
          }
          if (_onlyFollowedTopics && followedTopics.isNotEmpty) {
            filtered = filtered.where((a) => followedTopics.contains(a.category)).toList();
          }
          if (_timeFilter != 0) {
            filtered = filtered.where((a) {
              final mins = _readingTime(a.excerpt);
              if (_timeFilter == 1) return mins <= 3;
              if (_timeFilter == 2) return mins >= 4 && mins <= 6;
              return mins >= 7;
            }).toList();
          }
          if (_query.trim().isNotEmpty) {
            final q = _query.toLowerCase();
            filtered = filtered
                .where((a) => a.title.toLowerCase().contains(q) || a.excerpt.toLowerCase().contains(q))
                .toList();
          }

          final visible = filtered.take(_visibleCount).toList();
          if (_onlyBookmarked && _category != 'All') {
            filtered = filtered.where((a) => a.category == _category).toList();
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _visibleCount = 4);
              ref.invalidate(newsfeedLoadProvider);
            },
            child: ListView(
              controller: _controller,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _NewsfeedHeroCard(
                  streak: streak.streak,
                  digestEnabled: digestEnabled,
                  onToggleDigest: (value) =>
                      ref.read(newsfeedDigestProvider.notifier).setEnabled(value),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search articles...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                if (followedTopics.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Following topics: ${followedTopics.take(4).join(', ')}',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    TextButton.icon(
                      onPressed: () => _openPreferences(context, categories, prefs),
                      icon: const Icon(Icons.notifications_active_outlined),
                      label: const Text('Muted topics'),
                    ),
                    TextButton.icon(
                      onPressed: () => context.go('/newsfeed/saved'),
                      icon: const Icon(Icons.bookmark_border),
                      label: const Text('Read later'),
                    ),
                    Chip(
                      label: Text('Streak ${streak.streak} days'),
                      avatar: const Icon(Icons.local_fire_department, size: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    ChoiceChip(
                      label: const Text('For you'),
                      selected: _feedTab == 0,
                      onSelected: (_) => setState(() => _feedTab = 0),
                    ),
                    ChoiceChip(
                      label: const Text('Following'),
                      selected: _feedTab == 1,
                      onSelected: (_) => setState(() => _feedTab = 1),
                    ),
                    if (onlyFollowing)
                      TextButton(
                        onPressed: () => context.go('/newsfeed/authors'),
                        child: const Text('Manage'),
                      ),
                  ],
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ...categories.map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(c),
                            selected: _category == c,
                            onSelected: (_) => setState(() => _category = c),
                          ),
                        ),
                      ),
                      FilterChip(
                        label: const Text('Bookmarked'),
                        selected: _onlyBookmarked,
                        onSelected: (v) => setState(() => _onlyBookmarked = v),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Saved'),
                        selected: _onlySaved,
                        onSelected: (v) => setState(() => _onlySaved = v),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Followed topics'),
                        selected: _onlyFollowedTopics,
                        onSelected: (v) => setState(() => _onlyFollowedTopics = v),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Short'),
                        selected: _timeFilter == 1,
                        onSelected: (_) => setState(() => _timeFilter = _timeFilter == 1 ? 0 : 1),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Medium'),
                        selected: _timeFilter == 2,
                        onSelected: (_) => setState(() => _timeFilter = _timeFilter == 2 ? 0 : 2),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Long'),
                        selected: _timeFilter == 3,
                        onSelected: (_) => setState(() => _timeFilter = _timeFilter == 3 ? 0 : 3),
                      ),
                      if (_onlyBookmarked) ...[
                        const SizedBox(width: 8),
                        ...{for (final a in filtered) a.category}.map(
                          (c) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InputChip(
                              label: Text('In $c'),
                              onPressed: () => setState(() => _category = c),
                              onDeleted: () => setState(() => _category = 'All'),
                            ),
                          ),
                        ),
                      ],
                      if (prefs.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        ...prefs.map(
                          (c) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InputChip(
                              label: Text('Muted: $c'),
                              onDeleted: () => ref.read(newsfeedPreferencesProvider.notifier).toggle(c),
                            ),
                          ),
                        ),
                      ],
                      if (followedTopics.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        ...followedTopics.map(
                          (c) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InputChip(
                              label: Text('Following: $c'),
                              onDeleted: () => ref.read(newsfeedFollowTopicsProvider.notifier).toggle(c),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (!digestEnabled)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Digest off: you may miss curated updates.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                if (visible.isEmpty)
                  const Center(child: Padding(padding: EdgeInsets.only(top: 24), child: Text('No articles found')))
                else if (_onlyBookmarked)
                  ..._buildGroupedByCategory(
                    visible,
                    context,
                    ref,
                    _query,
                    bookmarks,
                    reactions,
                    comments,
                    followed,
                    authorProfiles,
                  )
                else
                  ...visible.map((article) {
                    final isBookmarked = bookmarks.contains(article.id);
                    final reaction = reactions[article.id] ?? const ArticleReactionState(likes: 0, liked: false);
                    final commentCount = comments[article.id]?.length ?? 0;
                    final metric = metrics[article.id] ?? const ArticleMetrics(views: 0, shares: 0);
                    final isSaved = saved.contains(article.id);
                    return _EditorialArticleCard(
                      article: article,
                      query: _query,
                      isSaved: isSaved,
                      isBookmarked: isBookmarked,
                      isFeatured: article.id == visible.first.id,
                      reaction: reaction,
                      commentCount: commentCount,
                      metric: metric,
                      progress: progress[article.id] ?? 0,
                      followed: followed.contains(article.author),
                      authorProfile: authorProfiles[article.author],
                      onToggleFollow: () =>
                          ref.read(articleFollowProvider.notifier).toggle(article.author),
                      onToggleBookmark: () =>
                          ref.read(articleBookmarkProvider.notifier).toggle(article.id),
                      onToggleSaved: () =>
                          ref.read(articleSavedProvider.notifier).toggle(article.id),
                      onShare: () => _openShareSheet(context, article),
                      onOpenAuthor: () =>
                          context.go('/newsfeed/author/${Uri.encodeComponent(article.author)}'),
                      onReact: () =>
                          ref.read(articleReactionProvider.notifier).toggleLike(article.id),
                      onTap: () => context.go('/article/${article.id}'),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildGroupedByCategory(
    List<ArticleItem> list,
    BuildContext context,
    WidgetRef ref,
    String query,
    Set<int> bookmarks,
    Map<int, ArticleReactionState> reactions,
    Map<int, List<String>> comments,
    Set<String> followed,
    Map<String, AuthorProfile> authorProfiles,
  ) {
    final groups = <String, List<ArticleItem>>{};
    for (final a in list) {
      groups.putIfAbsent(a.category, () => []).add(a);
    }
    final widgets = <Widget>[];
    for (final entry in groups.entries) {
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w700)),
      ));
      widgets.addAll(entry.value.map((article) {
        final isBookmarked = bookmarks.contains(article.id);
        final reaction = reactions[article.id] ?? const ArticleReactionState(likes: 0, liked: false);
        final commentCount = comments[article.id]?.length ?? 0;
        return _EditorialArticleCard(
          article: article,
          query: query,
          isSaved: false,
          isBookmarked: isBookmarked,
          isFeatured: false,
          reaction: reaction,
          commentCount: commentCount,
          metric: const ArticleMetrics(views: 0, shares: 0),
          progress: 0,
          followed: followed.contains(article.author),
          authorProfile: authorProfiles[article.author],
          onToggleFollow: () => ref.read(articleFollowProvider.notifier).toggle(article.author),
          onToggleBookmark: () => ref.read(articleBookmarkProvider.notifier).toggle(article.id),
          onToggleSaved: null,
          onShare: null,
          onOpenAuthor: () =>
              context.go('/newsfeed/author/${Uri.encodeComponent(article.author)}'),
          onReact: () => ref.read(articleReactionProvider.notifier).toggleLike(article.id),
          onTap: () => context.go('/article/${article.id}'),
        );
      }));
    }
    return widgets;
  }

  void _openShareSheet(BuildContext context, ArticleItem article) {
    final link = 'https://soc0.app/article/${article.id}';
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(article.title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Share this article'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(article.image, width: 64, height: 64, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          article.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          link,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy link'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: link));
                ref.read(articleMetricsProvider.notifier).addShare(article.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copied')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.text_snippet_outlined),
              title: const Text('Copy preview'),
              onTap: () {
                final preview = '${article.title}\n$link';
                Clipboard.setData(ClipboardData(text: preview));
                ref.read(articleMetricsProvider.notifier).addShare(article.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Preview copied')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: const Text('Share to chat'),
              onTap: () {
                ref.read(articleMetricsProvider.notifier).addShare(article.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Shared to chat')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('More options'),
              onTap: () {
                ref.read(articleMetricsProvider.notifier).addShare(article.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening share options')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NewsfeedHeroCard extends StatelessWidget {
  final int streak;
  final bool digestEnabled;
  final ValueChanged<bool> onToggleDigest;

  const _NewsfeedHeroCard({
    required this.streak,
    required this.digestEnabled,
    required this.onToggleDigest,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primaryContainer.withValues(alpha: 0.9),
            scheme.surfaceContainerHighest,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today’s reads',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Keep your streak going with curated beauty insights.',
            style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department, size: 16),
                    const SizedBox(width: 6),
                    Text('$streak day streak', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('Daily digest', style: theme.textTheme.bodySmall),
                    Switch(
                      value: digestEnabled,
                      onChanged: onToggleDigest,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EditorialArticleCard extends StatelessWidget {
  final ArticleItem article;
  final String query;
  final bool isSaved;
  final bool isBookmarked;
  final bool isFeatured;
  final ArticleReactionState reaction;
  final int commentCount;
  final ArticleMetrics metric;
  final double progress;
  final bool followed;
  final AuthorProfile? authorProfile;
  final VoidCallback onToggleFollow;
  final VoidCallback onToggleBookmark;
  final VoidCallback? onToggleSaved;
  final VoidCallback? onShare;
  final VoidCallback onOpenAuthor;
  final VoidCallback onReact;
  final VoidCallback onTap;

  const _EditorialArticleCard({
    required this.article,
    required this.query,
    required this.isSaved,
    required this.isBookmarked,
    required this.isFeatured,
    required this.reaction,
    required this.commentCount,
    required this.metric,
    required this.progress,
    required this.followed,
    required this.authorProfile,
    required this.onToggleFollow,
    required this.onToggleBookmark,
    required this.onToggleSaved,
    required this.onShare,
    required this.onOpenAuthor,
    required this.onReact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return MotionFadeSlide(
      beginOffset: const Offset(0, 0.08),
      child: MotionPressScale(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 10),
          elevation: 1.2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Stack(
                  children: [
                    Hero(
                      tag: 'article-hero-${article.id}',
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Image.network(
                          article.image,
                          key: ValueKey(article.image),
                          height: 190,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.0),
                              Colors.black.withValues(alpha: 0.55),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      bottom: 12,
                      right: 12,
                      child: Text(
                        article.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      top: 12,
                      child: Row(
                        children: [
                          if (isFeatured)
                            _EditorialBadge(
                              label: 'Featured',
                              color: scheme.secondaryContainer,
                              textColor: scheme.onSecondaryContainer,
                            ),
                          if (isSaved)
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: _EditorialBadge(
                                label: 'Saved',
                                color: Colors.green.withValues(alpha: 0.2),
                                textColor: Colors.green.shade700,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  GestureDetector(
                    onTap: onOpenAuthor,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundImage: authorProfile == null ? null : NetworkImage(authorProfile!.avatar),
                          child: authorProfile == null
                              ? Text(article.author[0], style: const TextStyle(fontSize: 10))
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            article.author,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (authorProfile?.verified == true) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, size: 14, color: Colors.blue),
                        ],
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: onToggleFollow,
                          child: Text(followed ? 'Following' : 'Follow'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _highlight(article.excerpt, query),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _EditorialBadge(
                        label: article.category,
                        color: scheme.surfaceContainerLow,
                        textColor: scheme.onSurfaceVariant,
                      ),
                      const Spacer(),
                      Text(article.createdAt, style: TextStyle(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text('${_readingTime(article.excerpt)} min read',
                          style: TextStyle(color: scheme.onSurfaceVariant)),
                      const SizedBox(width: 10),
                      Text('${metric.views} views • ${metric.shares} shares',
                          style: TextStyle(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: onReact,
                        icon: Icon(
                          reaction.liked ? Icons.favorite : Icons.favorite_border,
                          color: reaction.liked ? scheme.primary : null,
                        ),
                        label: Text('${reaction.likes}'),
                      ),
                      const SizedBox(width: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.comment, size: 18, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('$commentCount', style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border),
                        onPressed: onToggleBookmark,
                      ),
                      if (onToggleSaved != null)
                        IconButton(
                          icon: Icon(isSaved ? Icons.save : Icons.save_outlined),
                          onPressed: onToggleSaved,
                        ),
                      if (onShare != null)
                        IconButton(
                          icon: const Icon(Icons.share_outlined),
                          onPressed: onShare,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: scheme.surfaceContainerHigh,
                      minHeight: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditorialBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _EditorialBadge({
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textColor),
      ),
    );
  }
}

Widget _highlight(String text, String query) {
  if (query.trim().isEmpty) return Text(text);
  final lower = text.toLowerCase();
  final q = query.toLowerCase();
  final index = lower.indexOf(q);
  if (index == -1) return Text(text);
  final before = text.substring(0, index);
  final match = text.substring(index, index + q.length);
  final after = text.substring(index + q.length);
  return RichText(
    text: TextSpan(
      style: const TextStyle(color: Colors.black87),
      children: [
        TextSpan(text: before),
        TextSpan(
          text: match,
          style: const TextStyle(fontWeight: FontWeight.w700, backgroundColor: Color(0x33FFC107)),
        ),
        TextSpan(text: after),
      ],
    ),
  );
}

int _readingTime(String text) {
  final words = text.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).length;
  final minutes = (words / 200).ceil();
  return minutes < 1 ? 1 : minutes;
}

void _openPreferences(BuildContext context, List<String> categories, Set<String> selected) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return Consumer(
        builder: (context, ref, _) {
          final prefs = ref.watch(newsfeedPreferencesProvider);
          final followedTopics = ref.watch(newsfeedFollowTopicsProvider);
          final digestEnabled = ref.watch(newsfeedDigestProvider);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Muted Topics', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ...categories.map(
                (c) => SwitchListTile(
                  title: Text(c),
                  value: prefs.contains(c),
                  onChanged: (_) => ref.read(newsfeedPreferencesProvider.notifier).toggle(c),
                  subtitle: prefs.contains(c) ? const Text('Hidden from feed') : null,
                ),
              ),
              const SizedBox(height: 12),
              const Text('Follow Topics', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ...categories.where((c) => c != 'All').map(
                    (c) => CheckboxListTile(
                      value: followedTopics.contains(c),
                      onChanged: (_) => ref.read(newsfeedFollowTopicsProvider.notifier).toggle(c),
                      title: Text(c),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Weekly digest'),
                value: digestEnabled,
                onChanged: (v) => ref.read(newsfeedDigestProvider.notifier).setEnabled(v),
                subtitle: const Text('Get curated weekly highlights'),
              ),
            ],
          );
        },
      );
    },
  );
}
