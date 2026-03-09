import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CreateReviewScreen extends StatefulWidget {
  const CreateReviewScreen({super.key});

  @override
  State<CreateReviewScreen> createState() => _CreateReviewScreenState();
}

class _CreateReviewScreenState extends State<CreateReviewScreen> {
  double _rating = 4.0;
  final _productController = TextEditingController();
  final _contentController = TextEditingController();
  final List<String> _media = [];
  final List<String> _mediaPool = const [
    'https://images.unsplash.com/photo-1522336572468-97b06e8ef143?w=400&q=80',
    'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=400&q=80',
    'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?w=400&q=80',
  ];

  @override
  void dispose() {
    _productController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Review')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _productController,
              decoration: const InputDecoration(labelText: 'Product name'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Rating'),
                const SizedBox(width: 12),
                Expanded(
                  child: Slider(
                    value: _rating,
                    min: 1,
                    max: 5,
                    divisions: 8,
                    label: _rating.toStringAsFixed(1),
                    onChanged: (v) => setState(() => _rating = v),
                  ),
                ),
              ],
            ),
            TextField(
              controller: _contentController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Review'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Photos', style: TextStyle(fontWeight: FontWeight.w700)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    final next = _mediaPool[_media.length % _mediaPool.length];
                    setState(() => _media.add(next));
                  },
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: const Text('Add'),
                ),
              ],
            ),
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _media.length + 1,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == _media.length) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _media.add(
                            'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?w=400&q=80',
                          );
                        });
                      },
                      child: Container(
                        width: 96,
                        height: 96,
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
                  final url = _media[index];
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(url, width: 96, height: 96, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () => setState(() => _media.removeAt(index)),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.all(2),
                            child: const Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Review submitted')),
                  );
                  context.go('/review');
                },
                child: const Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
