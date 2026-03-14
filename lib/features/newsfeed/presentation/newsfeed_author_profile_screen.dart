import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'newsfeed_providers.dart';
import 'article_follow_provider.dart';
import 'article_bookmark_provider.dart';
import '../../../shared/widgets/motion.dart';

class NewsfeedAuthorProfileScreen extends ConsumerWidget {
  final String author;

  const NewsfeedAuthorProfileScreen({super.key, required this.author});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final articles = ref.watch(newsfeedProvider).where((a) => a.author == author).toList();
    final followed = ref.watch(articleFollowProvider).contains(author);
    final bookmarks = ref.watch(articleBookmarkProvider);
    final profile = ref.watch(authorProfilesProvider)[author];

    return Scaffold(
      appBar: AppBar(title: Text(author)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          MotionFadeSlide(
            beginOffset: const Offset(0, 0.08),
            child: Container(
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
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: profile == null ? null : NetworkImage(profile.avatar),
                    backgroundColor: scheme.primaryContainer,
                    child: profile == null
                        ? Text(
                            author.isNotEmpty ? author[0] : '?',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(author, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(
                          '${articles.length} articles • ${profile?.followers ?? 0} followers',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                        if (profile != null) ...[
                          const SizedBox(height: 6),
                          Text(profile.bio, style: TextStyle(color: scheme.onSurfaceVariant)),
                          if (profile.verified) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: const [
                                Icon(Icons.verified, size: 16, color: Colors.blue),
                                SizedBox(width: 4),
                                Text('Verified author', style: TextStyle(color: Colors.blue)),
                              ],
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => ref.read(articleFollowProvider.notifier).toggle(author),
                    child: Text(followed ? 'Following' : 'Follow'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Latest from this author', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (articles.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No articles found')))
          else
            ...articles.asMap().entries.map(
              (entry) => MotionFadeSlide(
                delay: Duration(milliseconds: 60 * (entry.key % 6)),
                beginOffset: const Offset(0, 0.06),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0.8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(entry.value.image, width: 64, height: 64, fit: BoxFit.cover),
                    ),
                    title: Text(entry.value.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Text(entry.value.excerpt, maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: IconButton(
                      icon: Icon(
                        bookmarks.contains(entry.value.id) ? Icons.bookmark : Icons.bookmark_border,
                      ),
                      onPressed: () =>
                          ref.read(articleBookmarkProvider.notifier).toggle(entry.value.id),
                    ),
                    onTap: () => context.go('/article/${entry.value.id}'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

