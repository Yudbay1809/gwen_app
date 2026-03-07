import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'review_providers.dart';
import 'review_card.dart';
import 'review_shimmer.dart';
import '../../wishlist/presentation/wishlist_entry_button.dart';
import '../../orders/presentation/orders_screen.dart';

class ReviewListScreen extends ConsumerStatefulWidget {
  const ReviewListScreen({super.key});

  @override
  ConsumerState<ReviewListScreen> createState() => _ReviewListScreenState();
}

class _ReviewListScreenState extends ConsumerState<ReviewListScreen> {
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
      setState(() => _visibleCount += 2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncReviews = ref.watch(reviewLoadProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review'),
        actions: [
          IconButton(
            onPressed: () => context.go('/orders'),
            icon: const Icon(Icons.receipt_long),
          ),
          const WishlistEntryButton(),
        ],
      ),
      body: asyncReviews.when(
        loading: () => const ReviewShimmer(),
        error: (_, __) => const Center(child: Text('Failed to load')),
        data: (reviews) {
          final visible = reviews.take(_visibleCount).toList();
          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _visibleCount = 4);
              await ref.refresh(reviewLoadProvider);
            },
            child: ListView.builder(
              controller: _controller,
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: visible.length,
              itemBuilder: (context, index) => ReviewCard(review: visible[index]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/review/create'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
