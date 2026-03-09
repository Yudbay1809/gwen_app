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
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _openPreferences(context, categories, prefs),
                      icon: const Icon(Icons.notifications_active_outlined),
                      label: const Text('Muted topics'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => context.go('/newsfeed/saved'),
                      icon: const Icon(Icons.bookmark_border),
                      label: const Text('Read later'),
                    ),
                    const Spacer(),
                    Chip(
                      label: Text('Streak ${streak.streak} days'),
                      avatar: const Icon(Icons.local_fire_department, size: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('For you'),
                      selected: _feedTab == 0,
                      onSelected: (_) => setState(() => _feedTab = 0),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Following'),
                      selected: _feedTab == 1,
                      onSelected: (_) => setState(() => _feedTab = 1),
                    ),
                    const Spacer(),
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
                    return GestureDetector(
                      onTap: () => context.go('/article/${article.id}'),
                      child: Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                              child: Image.network(article.image, height: 160, width: double.infinity, fit: BoxFit.cover),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _highlight(article.title, _query),
                                      ),
                                      if (isSaved)
                                        Container(
                                          margin: const EdgeInsets.only(right: 6),
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withAlpha(25),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Text('Saved', style: TextStyle(fontSize: 10)),
                                        ),
                                      if (article.id == visible.first.id)
                                        Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.pinkAccent.withAlpha(30),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text('Featured', style: TextStyle(fontSize: 10)),
                                    ),
                                  TextButton(
                                    onPressed: () => ref
                                        .read(articleFollowProvider.notifier)
                                        .toggle(article.author),
                                        child: Text(
                                          followed.contains(article.author) ? 'Following' : 'Follow',
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border),
                                        onPressed: () => ref.read(articleBookmarkProvider.notifier).toggle(article.id),
                                      ),
                                      IconButton(
                                        icon: Icon(isSaved ? Icons.save : Icons.save_outlined),
                                        onPressed: () => ref.read(articleSavedProvider.notifier).toggle(article.id),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.share_outlined),
                                        onPressed: () => _openShareSheet(context, article),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  GestureDetector(
                                    onTap: () => context.go('/newsfeed/author/${Uri.encodeComponent(article.author)}'),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 10,
                                          backgroundImage: authorProfiles[article.author] == null
                                              ? null
                                              : NetworkImage(authorProfiles[article.author]!.avatar),
                                          child: authorProfiles[article.author] == null
                                              ? Text(article.author[0], style: const TextStyle(fontSize: 10))
                                              : null,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          article.author,
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                        if (authorProfiles[article.author]?.verified == true) ...[
                                          const SizedBox(width: 4),
                                          const Icon(Icons.verified, size: 14, color: Colors.blue),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  _highlight(article.excerpt, _query),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_readingTime(article.excerpt)} min read',
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${metric.views} views - ${metric.shares} shares',
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
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
                                      const Spacer(),
                                      Text(article.createdAt, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      TextButton.icon(
                                        onPressed: () => ref
                                            .read(articleReactionProvider.notifier)
                                            .toggleLike(article.id),
                                        icon: Icon(
                                          reaction.liked ? Icons.favorite : Icons.favorite_border,
                                          color: reaction.liked ? Colors.pink : null,
                                        ),
                                        label: Text('${reaction.likes}'),
                                      ),
                                      const SizedBox(width: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.comment, size: 18, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text('$commentCount', style: const TextStyle(color: Colors.grey)),
                                        ],
                                      ),
                                    ],
                                  ),
                                  LinearProgressIndicator(
                                    value: progress[article.id] ?? 0,
                                    backgroundColor: Colors.grey.shade200,
                                    minHeight: 4,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
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
        return GestureDetector(
          onTap: () => context.go('/article/${article.id}'),
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: _highlight(article.title, query)),
                      TextButton(
                        onPressed: () => ref.read(articleFollowProvider.notifier).toggle(article.author),
                        child: Text(followed.contains(article.author) ? 'Following' : 'Follow'),
                      ),
                      IconButton(
                        icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border),
                        onPressed: () => ref.read(articleBookmarkProvider.notifier).toggle(article.id),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => context.go('/newsfeed/author/${Uri.encodeComponent(article.author)}'),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundImage: authorProfiles[article.author] == null
                              ? null
                              : NetworkImage(authorProfiles[article.author]!.avatar),
                          child: authorProfiles[article.author] == null
                              ? Text(article.author[0], style: const TextStyle(fontSize: 10))
                              : null,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          article.author,
                          style: const TextStyle(color: Colors.grey, decoration: TextDecoration.underline),
                        ),
                        if (authorProfiles[article.author]?.verified == true) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, size: 14, color: Colors.blue),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  _highlight(article.excerpt, query),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => ref.read(articleReactionProvider.notifier).toggleLike(article.id),
                        icon: Icon(
                          reaction.liked ? Icons.favorite : Icons.favorite_border,
                          color: reaction.liked ? Colors.pink : null,
                        ),
                        label: Text('${reaction.likes}'),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          const Icon(Icons.comment, size: 18, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('$commentCount', style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
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
