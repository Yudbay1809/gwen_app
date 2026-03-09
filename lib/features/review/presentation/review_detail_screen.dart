import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'review_providers.dart';
import 'review_like_provider.dart';
import 'review_replies_provider.dart';

class ReviewDetailScreen extends ConsumerStatefulWidget {
  final int id;

  const ReviewDetailScreen({super.key, required this.id});

  @override
  ConsumerState<ReviewDetailScreen> createState() => _ReviewDetailScreenState();
}

class _ReviewDetailScreenState extends ConsumerState<ReviewDetailScreen> {
  final _replyController = TextEditingController();
  int? _replyToId;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final review = ref.watch(reviewFeedProvider).where((r) => r.id == widget.id).firstOrNull;
    if (review == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Review')),
        body: const Center(child: Text('Review not found')),
      );
    }
    final liked = ref.watch(reviewLikeProvider).contains(review.id);
    final likeCount = review.likes + (liked ? 1 : 0);
    final replies = ref.watch(reviewRepliesProvider)[review.id] ?? const <ReviewReply>[];
    final replyCount = ref.read(reviewRepliesProvider.notifier).countFor(review.id);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/review');
            }
          },
        ),
        title: const Text('Review Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _editReview(review),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(review.id),
          ),
          IconButton(
            icon: const Icon(Icons.report_outlined),
            onPressed: () => _report(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(review.productName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 6),
          if (review.verifiedPurchase)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blueGrey.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('Verified purchase', style: TextStyle(fontSize: 11)),
            ),
          const SizedBox(height: 8),
          Text(review.content),
          const SizedBox(height: 12),
          _AiSummaryCard(review: review),
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
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                icon: Icon(liked ? Icons.favorite : Icons.favorite_border, color: Colors.pink),
                onPressed: () => ref.read(reviewLikeProvider.notifier).toggle(review.id),
              ),
              Text('$likeCount likes'),
              const Spacer(),
              if (review.hasMedia)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.withAlpha(31),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Media', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Media', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: review.media.isEmpty ? 1 : review.media.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                if (review.media.isEmpty) {
                  return GestureDetector(
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Upload photo (dummy)')),
                    ),
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Center(
                        child: Icon(Icons.add_a_photo_outlined, color: Colors.black54),
                      ),
                    ),
                  );
                }
                return GestureDetector(
                  onTap: () => _openLightbox(context, review.media, index),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(review.media[index], width: 120, height: 120, fit: BoxFit.cover),
                  ),
                );
              },
            ),
          ),
          if (review.media.isNotEmpty) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => context.go('/review/media'),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('View all media'),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text('Replies ($replyCount)', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (replies.isEmpty) const Text('No replies yet.'),
          ..._buildReplies(replies, onReply: (id) => setState(() => _replyToId = id)),
          const SizedBox(height: 8),
          if (_replyToId != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.reply, size: 16),
                  const SizedBox(width: 6),
                  Text('Replying to #$_replyToId'),
                  const Spacer(),
                  TextButton(onPressed: () => setState(() => _replyToId = null), child: const Text('Cancel')),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _replyController,
                  decoration: const InputDecoration(hintText: 'Write a reply...'),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final text = _replyController.text.trim();
                  if (text.isEmpty) return;
                  ref.read(reviewRepliesProvider.notifier).addReply(
                        review.id,
                        text,
                        parentId: _replyToId,
                      );
                  _replyController.clear();
                  setState(() => _replyToId = null);
                },
                child: const Text('Post'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _editReview(ReviewItem review) async {
    final controller = TextEditingController(text: review.content);
    double rating = review.rating;
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Review'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Review'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Rating'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Slider(
                        value: rating,
                        min: 1,
                        max: 5,
                        divisions: 8,
                        label: rating.toStringAsFixed(1),
                        onChanged: (v) => setDialogState(() => rating = v),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );

    if (!mounted) return;
    if (result == true) {
      final content = controller.text.trim();
      if (content.isEmpty) return;
      ref.read(reviewFeedProvider.notifier).updateReview(
            id: review.id,
            rating: rating,
            content: content,
          );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review updated')));
    }
  }

  Future<void> _confirmDelete(int id) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete review'),
        content: const Text('Are you sure you want to delete this review?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (!mounted) return;
    if (result == true) {
      ref.read(reviewFeedProvider.notifier).deleteReview(id);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review deleted')));
      Navigator.pop(context);
    }
  }

  void _report(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Report Review'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Spam'),
              onTap: () => _submitReport(context, 'Spam'),
            ),
            ListTile(
              title: const Text('Abusive'),
              onTap: () => _submitReport(context, 'Abusive'),
            ),
            ListTile(
              title: const Text('Off-topic'),
              onTap: () => _submitReport(context, 'Off-topic'),
            ),
          ],
        ),
      ),
    );
  }

  void _submitReport(BuildContext context, String reason) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reported as $reason')),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

List<Widget> _buildReplies(List<ReviewReply> replies, {required ValueChanged<int> onReply}) {
  final parents = replies.where((r) => r.parentId == null).toList();
  final children = <int, List<ReviewReply>>{};
  for (final r in replies.where((r) => r.parentId != null)) {
    children.putIfAbsent(r.parentId!, () => []).add(r);
  }
  final widgets = <Widget>[];
  for (final parent in parents) {
    widgets.add(_ReplyTile(reply: parent, indent: 0, onReply: onReply));
    final kids = children[parent.id] ?? const [];
    for (final child in kids) {
      widgets.add(_ReplyTile(reply: child, indent: 18, onReply: onReply));
    }
  }
  return widgets;
}

class _ReplyTile extends StatelessWidget {
  final ReviewReply reply;
  final double indent;
  final ValueChanged<int> onReply;

  const _ReplyTile({required this.reply, required this.indent, required this.onReply});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: indent),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const CircleAvatar(child: Icon(Icons.person, size: 16)),
        title: Text(reply.text),
        subtitle: Text('Reply #${reply.id}'),
        trailing: TextButton(
          onPressed: () => onReply(reply.id),
          child: const Text('Reply'),
        ),
      ),
    );
  }
}

class _AiSummaryCard extends StatelessWidget {
  final ReviewItem review;

  const _AiSummaryCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final pros = <String>[
      if (review.rating >= 4.5) 'Hydrating feel',
      if (review.rating >= 4) 'Fast absorption',
      if (review.hasMedia) 'Visible texture in media',
    ];
    final cons = <String>[
      if (review.rating < 4) 'Longevity could improve',
      if (review.content.length < 60) 'Review is short',
    ];
    if (pros.isEmpty) pros.add('Gentle on skin');
    if (cons.isEmpty) cons.add('No major downsides reported');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.auto_awesome, size: 18),
                SizedBox(width: 6),
                Text('AI Summary (dummy)', style: TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Pros', style: TextStyle(fontWeight: FontWeight.w600)),
            ...pros.map((p) => Text('• $p')),
            const SizedBox(height: 6),
            const Text('Cons', style: TextStyle(fontWeight: FontWeight.w600)),
            ...cons.map((c) => Text('• $c')),
          ],
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
