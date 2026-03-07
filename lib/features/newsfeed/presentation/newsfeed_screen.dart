import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'newsfeed_providers.dart';
import 'newsfeed_shimmer.dart';

class NewsfeedScreen extends ConsumerStatefulWidget {
  const NewsfeedScreen({super.key});

  @override
  ConsumerState<NewsfeedScreen> createState() => _NewsfeedScreenState();
}

class _NewsfeedScreenState extends ConsumerState<NewsfeedScreen> {
  int _visibleCount = 4;
  late final ScrollController _controller;

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

    return Scaffold(
      appBar: AppBar(title: const Text('Newsfeed')),
      body: asyncArticles.when(
        loading: () => const NewsfeedShimmer(),
        error: (_, __) => const Center(child: Text('Failed to load')),
        data: (articles) {
          final visible = articles.take(_visibleCount).toList();
          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _visibleCount = 4);
              await ref.refresh(newsfeedLoadProvider);
            },
            child: ListView.builder(
              controller: _controller,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: visible.length,
              itemBuilder: (context, index) {
                final article = visible[index];
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
                              Text(article.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              Text(article.excerpt),
                              const SizedBox(height: 6),
                              Text(article.createdAt, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
