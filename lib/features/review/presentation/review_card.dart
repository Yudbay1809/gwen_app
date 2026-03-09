import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/rating_stars.dart';
import 'review_providers.dart';
import 'review_like_provider.dart';

class ReviewCard extends ConsumerWidget {
  final ReviewItem review;

  const ReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatter = DateFormat('dd MMM, HH:mm');
    final helpfulCount = ref.watch(reviewHelpfulProvider)[review.id] ?? 0;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => context.go('/review/${review.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: NetworkImage(review.userAvatar),
                    backgroundColor: Colors.grey.shade200,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(review.userName, style: const TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(width: 6),
                            if (review.verifiedPurchase)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blueGrey.withAlpha(20),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text('Verified purchase', style: TextStyle(fontSize: 10)),
                              ),
                            if (review.id % 3 == 0)
                              Container(
                                margin: const EdgeInsets.only(left: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withAlpha(30),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text('Top Reviewer', style: TextStyle(fontSize: 10)),
                              ),
                          ],
                        ),
                        Text(
                          formatter.format(review.createdAt),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  RatingStars(rating: review.rating),
                ],
              ),
              const SizedBox(height: 8),
              Text(review.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(review.content),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _sentimentTags(review)
                    .map(
                      (tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.pinkAccent.withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(tag, style: const TextStyle(fontSize: 11)),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.favorite, size: 16, color: Colors.pink.shade300),
                  const SizedBox(width: 4),
                  Text('${review.likes} likes', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  if (review.hasMedia) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.withAlpha(31),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('Media', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ],
                  const Spacer(),
                  TextButton(
                    onPressed: () => ref.read(reviewHelpfulProvider.notifier).toggleHelpful(review.id),
                    child: Text('Helpful ($helpfulCount)'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<String> _sentimentTags(ReviewItem review) {
  final tags = <String>[];
  if (review.rating >= 4.5) tags.add('Hydrating');
  if (review.rating >= 4.0) tags.add('Non-sticky');
  if (review.content.toLowerCase().contains('wangi')) tags.add('Fragrance');
  if (review.content.toLowerCase().contains('sensitif')) tags.add('Sensitive-safe');
  if (review.hasMedia) tags.add('With media');
  if (tags.isEmpty) tags.add('Comfortable');
  return tags.take(4).toList();
}
