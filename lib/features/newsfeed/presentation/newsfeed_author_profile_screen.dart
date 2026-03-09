import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'newsfeed_providers.dart';
import 'article_follow_provider.dart';
import 'article_bookmark_provider.dart';

class NewsfeedAuthorProfileScreen extends ConsumerWidget {
  final String author;

  const NewsfeedAuthorProfileScreen({super.key, required this.author});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articles = ref.watch(newsfeedProvider).where((a) => a.author == author).toList();
    final followed = ref.watch(articleFollowProvider).contains(author);
    final bookmarks = ref.watch(articleBookmarkProvider);
    final profile = ref.watch(authorProfilesProvider)[author];

    return Scaffold(
      appBar: AppBar(title: Text(author)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: profile == null ? null : NetworkImage(profile.avatar),
                    backgroundColor: Colors.pinkAccent.withAlpha(40),
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
                          style: const TextStyle(color: Colors.grey),
                        ),
                        if (profile != null) ...[
                          const SizedBox(height: 4),
                          Text(profile.bio, style: const TextStyle(color: Colors.black54)),
                          const SizedBox(height: 4),
                          if (profile.verified)
                            Row(
                              children: const [
                                Icon(Icons.verified, size: 16, color: Colors.blue),
                                SizedBox(width: 4),
                                Text('Verified author', style: TextStyle(color: Colors.blue)),
                              ],
                            ),
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
            ...articles.map(
              (a) => Card(
                child: ListTile(
                  leading: Image.network(a.image, width: 52, height: 52, fit: BoxFit.cover),
                  title: Text(a.title),
                  subtitle: Text(a.excerpt, maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    icon: Icon(bookmarks.contains(a.id) ? Icons.bookmark : Icons.bookmark_border),
                    onPressed: () => ref.read(articleBookmarkProvider.notifier).toggle(a.id),
                  ),
                  onTap: () => context.go('/article/${a.id}'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
