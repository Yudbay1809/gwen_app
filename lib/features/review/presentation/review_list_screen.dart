import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'review_providers.dart';
import 'review_card.dart';
import 'review_shimmer.dart';
import '../../wishlist/presentation/wishlist_entry_button.dart';
import 'review_like_provider.dart';

class ReviewListScreen extends ConsumerStatefulWidget {
  const ReviewListScreen({super.key});

  @override
  ConsumerState<ReviewListScreen> createState() => _ReviewListScreenState();
}

class _ReviewListScreenState extends ConsumerState<ReviewListScreen> {
  int _page = 1;
  static const int _pageSize = 4;

  @override
  Widget build(BuildContext context) {
    final asyncReviews = ref.watch(reviewLoadProvider);
    final filter = ref.watch(reviewFilterProvider);
    final filterNotifier = ref.read(reviewFilterProvider.notifier);
    final helpfulMap = ref.watch(reviewHelpfulProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review'),
        actions: [
          IconButton(
            onPressed: () => context.go('/orders'),
            icon: const Icon(Icons.receipt_long),
          ),
          IconButton(
            onPressed: () => context.go('/review/media'),
            icon: const Icon(Icons.photo_library_outlined),
          ),
          const WishlistEntryButton(),
        ],
      ),
      body: asyncReviews.when(
        loading: () => const ReviewShimmer(),
        error: (error, stack) => const Center(child: Text('Failed to load')),
        data: (reviews) {
          var filtered = reviews;
          if (filter.withMedia) {
            filtered = filtered.where((r) => r.hasMedia).toList();
          } else {
            filtered = [...filtered];
          }
          if (filter.verifiedOnly) {
            filtered = filtered.where((r) => r.verifiedPurchase).toList();
          }
          filtered.sort((a, b) {
            switch (filter.sort) {
              case ReviewSort.rating:
                return b.rating.compareTo(a.rating);
              case ReviewSort.newest:
                return b.createdAt.compareTo(a.createdAt);
              case ReviewSort.helpful:
                final ah = helpfulMap[a.id] ?? 0;
                final bh = helpfulMap[b.id] ?? 0;
                return bh.compareTo(ah);
            }
          });

          final visible = filtered.take(_page * _pageSize).toList();
          final hasMore = visible.length < filtered.length;

          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _page = 1);
              ref.invalidate(reviewLoadProvider);
            },
            child: ListView(
              padding: const EdgeInsets.only(bottom: 80),
              children: [
                _FilterBar(
                  filter: filter,
                  onSortChanged: filterNotifier.setSort,
                  onMediaChanged: filterNotifier.setWithMedia,
                  onVerifiedChanged: filterNotifier.setVerifiedOnly,
                ),
                const SizedBox(height: 8),
                if (visible.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 32),
                    child: Center(child: Text('No reviews found')),
                  )
                else
                  ...visible.map((review) => ReviewCard(review: review)),
                if (hasMore)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: OutlinedButton(
                      onPressed: () => setState(() => _page += 1),
                      child: const Text('Load more'),
                    ),
                  ),
              ],
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

class _FilterBar extends StatelessWidget {
  final ReviewFilter filter;
  final ValueChanged<ReviewSort> onSortChanged;
  final ValueChanged<bool> onMediaChanged;
  final ValueChanged<bool> onVerifiedChanged;

  const _FilterBar({
    required this.filter,
    required this.onSortChanged,
    required this.onMediaChanged,
    required this.onVerifiedChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sort by', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Newest'),
                selected: filter.sort == ReviewSort.newest,
                onSelected: (_) => onSortChanged(ReviewSort.newest),
              ),
              ChoiceChip(
                label: const Text('Rating'),
                selected: filter.sort == ReviewSort.rating,
                onSelected: (_) => onSortChanged(ReviewSort.rating),
              ),
              ChoiceChip(
                label: const Text('Helpful'),
                selected: filter.sort == ReviewSort.helpful,
                onSelected: (_) => onSortChanged(ReviewSort.helpful),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('With media'),
            value: filter.withMedia,
            onChanged: onMediaChanged,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Verified purchase only'),
            value: filter.verifiedOnly,
            onChanged: onVerifiedChanged,
          ),
        ],
      ),
    );
  }
}
