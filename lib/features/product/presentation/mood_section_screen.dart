import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../home/presentation/home_mood_provider.dart';
import '../../home/presentation/home_providers.dart';
import '../../../shared/widgets/product_card.dart';

class MoodSectionScreen extends ConsumerWidget {
  final String mood;

  const MoodSectionScreen({super.key, required this.mood});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(homeDataProvider);
    final moodEnum = HomeMood.values.where((e) => e.name == mood).firstOrNull;
    final title = moodEnum == null ? 'Mood' : moodLabel(moodEnum);
    final filtered = data.allProducts.where((p) => _matchMood(p.id, moodEnum)).toList();

    return Scaffold(
      appBar: AppBar(title: Text('$title Picks')),
      body: filtered.isEmpty
          ? const Center(child: Text('No products found'))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.62,
              ),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final product = filtered[index];
                return ProductCard(
                  product: product,
                  onTap: () => context.go('/product/${product.id}'),
                );
              },
            ),
    );
  }
}

bool _matchMood(int id, HomeMood? mood) {
  if (mood == null) return true;
  switch (mood) {
    case HomeMood.hydrating:
      return id % 2 == 0;
    case HomeMood.brightening:
      return id % 3 == 0;
    case HomeMood.acne:
      return id % 4 == 0;
    case HomeMood.calming:
      return id % 5 == 0;
    case HomeMood.antiAging:
      return id % 6 == 0;
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
