import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'review_providers.dart';

class ReviewMediaScreen extends ConsumerWidget {
  const ReviewMediaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(reviewFeedProvider);
    final media = reviews.expand((r) => r.media).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Review Media')),
      body: media.isEmpty
          ? const Center(child: Text('No media available'))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: media.length,
              itemBuilder: (context, index) {
                final url = media[index];
                return GestureDetector(
                  onTap: () => _openLightbox(context, media, index),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(url, fit: BoxFit.cover),
                  ),
                );
              },
            ),
    );
  }
}

void _openLightbox(BuildContext context, List<String> media, int initial) {
  showDialog(
    context: context,
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.all(12),
      child: AspectRatio(
        aspectRatio: 1,
        child: PageView.builder(
          controller: PageController(initialPage: initial),
          itemCount: media.length,
          itemBuilder: (context, index) => InteractiveViewer(
            child: Image.network(media[index], fit: BoxFit.contain),
          ),
        ),
      ),
    ),
  );
}
