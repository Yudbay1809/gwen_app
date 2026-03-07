import 'package:flutter/material.dart';
import '../../../shared/widgets/rating_stars.dart';
import 'review_providers.dart';

class ReviewCard extends StatelessWidget {
  final ReviewItem review;

  const ReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      Text(review.userName, style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(review.createdAt, style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.favorite, size: 16, color: Colors.pink.shade300),
                const SizedBox(width: 4),
                Text('${review.likes} likes', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const Spacer(),
                TextButton(onPressed: () {}, child: const Text('Reply')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
